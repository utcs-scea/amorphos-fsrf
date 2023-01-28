#include <chrono>
#include "aos.hpp"

using namespace std::chrono;

struct rng_config {
	uint64_t base_addr;
	uint64_t size_shift;
} rng_config;

struct hls_sha_config {
	uint32_t abcdefgh[8];
	uint64_t src_addr;
	uint64_t num_words;
} hls_sha_config;

struct hls_pgrnk_config {
	uint64_t num_verts;
	uint64_t num_edges;
	uint64_t vert_ptr;
	uint64_t edge_ptr;
	uint64_t input_ptr;
	uint64_t output_ptr;
	void *read_ptr;
	void *write_ptr;
} hls_pgrnk_config;

struct aes_config {
	uint64_t key[4];
	uint64_t src_addr;
	uint64_t dst_addr;
	uint64_t num_words;
	uint64_t rd_credits;
	uint64_t wr_credits;
} aes_config;

int main(int argc, char *argv[]) {
	// RNG config
	bool reading = true, writing = false;
	rng_config.size_shift = 6;
	uint64_t linear = false;
	
	// HLS SHA config
	uint64_t hls_sha_length = 25;
	hls_sha_config.num_words = 1 << hls_sha_length;
	
	// HLS PgRnk config
	hls_pgrnk_config.num_verts = 68863488;
	hls_pgrnk_config.num_edges = 143415296;
	uint64_t fname_sel = 2;
	uint64_t pgrnk_read_len, pgrnk_write_len;
	pgrnk_read_len = hls_pgrnk_config.num_verts*(16+8);
	pgrnk_read_len += hls_pgrnk_config.num_edges*8;
	pgrnk_write_len = hls_pgrnk_config.num_verts*8;
	
	// AES config
	uint64_t aes_length = 24;
	aes_config.key[0] = 1;
	aes_config.key[1] = 2;
	aes_config.key[2] = 3;
	aes_config.key[3] = 4;
	aes_config.num_words = 1 << aes_length;
	aes_config.rd_credits = 8;
	aes_config.wr_credits = 8;
	
	int argi = 1;
	uint64_t num_apps = 4;
	bool populate = true;
	
	uint64_t fio_mode = 0;
	if (argi < argc) fio_mode = atol(argv[argi]);
	assert(fio_mode <= 2 || fio_mode == 4);
	++argi;
	
	uint64_t coyote_config = 0;
	if (argi < argc) coyote_config = atol(argv[argi]);
	assert(coyote_config <= 2);
	++argi;
	
	uint64_t log_prefetch_size = 9;
	if (argi < argc) log_prefetch_size = atol(argv[argi]);
	assert(log_prefetch_size <= 9);
	++argi;
	
	high_resolution_clock::time_point start, end[4];
	duration<double> diff;
	double seconds;
	
	aos_client *aos[4];
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app] = new aos_client();
		aos[app]->set_slot_id(0);
		aos[app]->set_app_id(app);
		aos[app]->connect();
		if (fio_mode == 0 && coyote_config == 1) {
			aos[app]->aos_set_mode(app == 0 ? 0 : 1, 2);
		} else aos[app]->aos_set_mode(fio_mode, coyote_config);
		aos[app]->aos_set_mode(3, 1 << log_prefetch_size);
	}
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file%lu.bin", "/mnt/nvme0/small%lu.bin",
	                         "/mnt/nvme0/medium%lu.bin", "/mnt/nvme0/large%lu.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		char fname[32];
		snprintf(fname, 32, fnames[(app == 2) ? fname_sel : 0], app);
		aos[app]->aos_file_open(fname, fd[app]);
	}
	
	void *addr;
	int prot;
	int flags = populate ? MAP_POPULATE : 0;
	uint64_t length;
	
	// MMAP RNG
	length = uint64_t{1} << (19 + 6 + rng_config.size_shift);
	prot = 0;
	if (reading) prot |= PROT_READ;
	if (writing) prot |= PROT_WRITE;
	
	start = high_resolution_clock::now();
	addr = nullptr;
	aos[0]->aos_mmap(addr, length, prot, flags, fd[0], 0);
	rng_config.base_addr = (uint64_t)addr;
	end[0] = high_resolution_clock::now();
	
	diff = end[0] - start;
	seconds = diff.count();
	printf("rng mmaped file %d at 0x%lX in %g\n", fd[0], rng_config.base_addr, seconds);
	
	// MMAP HLS SHA
	length = hls_sha_config.num_words * 64;
	
	start = high_resolution_clock::now();
	addr = nullptr;
	aos[1]->aos_mmap(addr, length, PROT_READ, flags, fd[1], 0);
	hls_sha_config.src_addr = (uint64_t)addr;
	end[0] = high_resolution_clock::now();
	
	diff = end[0] - start;
	seconds = diff.count();
	printf("hls_sha mmaped file %d at 0x%lX in %g\n", fd[1], hls_sha_config.src_addr, seconds);
	
	// MMAP HLS PgRnk
	start = high_resolution_clock::now();
	addr = nullptr;
	aos[2]->aos_mmap(addr, pgrnk_read_len, PROT_READ, flags, fd[2], 0);
	hls_pgrnk_config.read_ptr = addr;
	addr = nullptr;
	aos[2]->aos_mmap(addr, pgrnk_write_len, PROT_WRITE, flags, fd[2], pgrnk_read_len);
	hls_pgrnk_config.write_ptr = addr;
	end[0] = high_resolution_clock::now();
	
	hls_pgrnk_config.vert_ptr = (uint64_t)hls_pgrnk_config.read_ptr;
	hls_pgrnk_config.edge_ptr = hls_pgrnk_config.vert_ptr + hls_pgrnk_config.num_verts*16;
	hls_pgrnk_config.input_ptr = hls_pgrnk_config.edge_ptr + hls_pgrnk_config.num_edges*8;
	hls_pgrnk_config.output_ptr = (uint64_t)hls_pgrnk_config.write_ptr;
	
	diff = end[0] - start;
	seconds = diff.count();
	printf("hls_pgrnk mmaped file %d at %p and %p in %g\n", fd[2],
		hls_pgrnk_config.read_ptr, hls_pgrnk_config.write_ptr, seconds);
	
	// MMAP AES
	length = aes_config.num_words * 64;
	
	start = high_resolution_clock::now();
	addr = nullptr;
	aos[3]->aos_mmap(addr, length, PROT_READ, flags, fd[3], 0);
	aes_config.src_addr = (uint64_t)addr;
	addr = nullptr;
	aos[3]->aos_mmap(addr, length, PROT_WRITE, flags, fd[3], length);
	aes_config.dst_addr = (uint64_t)addr;
	end[0] = high_resolution_clock::now();
	
	diff = end[0] - start;
	seconds = diff.count();
	printf("aes mmaped file %d at 0x%lX 0x%lX in %g\n", fd[3],
		aes_config.src_addr, aes_config.dst_addr, seconds);
	
	// ---------------
	
	// RNG setup
	uint64_t rng_value = rng_config.base_addr | (rng_config.size_shift << 48) | (linear << 52);
	uint64_t rng_prev;
	
	// HLS SHA setup
	aos[1]->aos_cntrlreg_write(0x48, hls_sha_config.src_addr);
	aos[1]->aos_cntrlreg_write(0x58, hls_sha_config.num_words);
	
	// HLS PgRnk setup
	aos[2]->aos_cntrlreg_write(0x20, hls_pgrnk_config.num_verts);
	aos[2]->aos_cntrlreg_write(0x30, hls_pgrnk_config.num_edges);
	aos[2]->aos_cntrlreg_write(0x40, hls_pgrnk_config.vert_ptr);
	aos[2]->aos_cntrlreg_write(0x50, hls_pgrnk_config.edge_ptr);
	aos[2]->aos_cntrlreg_write(0x60, hls_pgrnk_config.input_ptr);
	aos[2]->aos_cntrlreg_write(0x70, hls_pgrnk_config.output_ptr);
	
	// AES setup
	aos[3]->aos_cntrlreg_write(0x00, aes_config.key[0]);
	aos[3]->aos_cntrlreg_write(0x08, aes_config.key[1]);
	aos[3]->aos_cntrlreg_write(0x10, aes_config.key[2]);
	aos[3]->aos_cntrlreg_write(0x18, aes_config.key[3]);
	aos[3]->aos_cntrlreg_write(0x38, aes_config.rd_credits);
	aos[3]->aos_cntrlreg_write(0x40, aes_config.wr_credits);
	
	// do runs
	uint64_t hls_pgrnk_runs_left = 25;
	uint64_t app_runs[4] = {0, 0, 0, 0};
	bool app_done[4] = {true, true, true, true};
	start = high_resolution_clock::now();
	while (true) {
		// start apps
		if (hls_pgrnk_runs_left > 0) {
			if (app_done[1]) {
				aos[1]->aos_cntrlreg_write(0x0, 0x1);
				app_done[1] = false;
				++app_runs[1];
			}
			if (app_done[2]) {
				aos[2]->aos_cntrlreg_write(0x0, 0x1);
				app_done[2] = false;
				++app_runs[2];
			}
			if (app_done[3]) {
				aos[3]->aos_cntrlreg_write(0x20, aes_config.src_addr);
				aos[3]->aos_cntrlreg_write(0x28, aes_config.dst_addr);
				aos[3]->aos_cntrlreg_write(0x30, aes_config.num_words);
				app_done[3] = false;
				++app_runs[3];
			}
			if (app_done[0]) {
				aos[0]->aos_cntrlreg_write(0x0, rng_value);
				app_done[0] = false;
				aos[0]->aos_cntrlreg_read(0x0, rng_prev);
				++app_runs[0];
			}
		}
		
		// check if done
		uint64_t temp;
		if (!app_done[2]) {
			aos[2]->aos_cntrlreg_read(0x0, temp);
			if ((temp & 0x2) == 0x2) {
				aos[2]->aos_cntrlreg_write(0x00, 0x10);
				--hls_pgrnk_runs_left;
				app_done[2] = true;
				if (hls_pgrnk_runs_left == 0) end[2] = high_resolution_clock::now();
			}
		}
		if (!app_done[0]) {
			aos[0]->aos_cntrlreg_read(0x0, temp);
			if (temp == rng_prev) {
				app_done[0] = true;
				if (hls_pgrnk_runs_left == 0) end[0] = high_resolution_clock::now();
			}
			rng_prev = temp;
		}
		if (!app_done[1]) {
			aos[1]->aos_cntrlreg_read(0x0, temp);
			if ((temp & 0x2) == 0x2) {
				aos[1]->aos_cntrlreg_write(0x00, 0x10);
				app_done[1] = true;
				if (hls_pgrnk_runs_left == 0) end[1] = high_resolution_clock::now();
			}
		}
		if (!app_done[3]) {
			aos[3]->aos_cntrlreg_read(0x38, temp);
			if (temp == 0) {
				app_done[3] = true;
				if (hls_pgrnk_runs_left == 0) end[3] = high_resolution_clock::now();
			}
		}
		
		if (!hls_pgrnk_runs_left && app_done[0] && app_done[1] && app_done[2] && app_done[3]) break;
	}
	
	// Print stats
	const char* app_names[4] = {"rng", "hls_sha", "hls_pgrnk", "aes"};
	uint64_t app_bytes[5];
	app_bytes[0] = (uint64_t{1} << rng_config.size_shift) * (1 << 19) * 64;
	app_bytes[1] = hls_sha_config.num_words * 64;
	app_bytes[2] = (hls_pgrnk_config.num_verts*(16+8) + hls_pgrnk_config.num_edges*(8+8));
	app_bytes[3] = aes_config.num_words * 2 * 64;
	app_bytes[4] = 0;
	
	double max_sec = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t total_bytes = app_runs[app] * app_bytes[app];
		app_bytes[4] += total_bytes;
		printf("%s e2e %lu %lu ", app_names[app], app_runs[app], total_bytes);
		
		diff = end[app] - start;
		seconds = diff.count();
		const double avg_tput = ((double)total_bytes)/seconds/(1<<20);
		printf("%g %g\n", seconds, avg_tput);
		
		if (seconds > max_sec) max_sec = seconds;
	}
	
	const double e2e_tput = ((double)app_bytes[4])/max_sec/(1<<20);
	//printf("all e2e %lu %g %g\n", app_bytes[4], max_sec, e2e_tput);
	
	// Clean up RNG
	length = uint64_t{1} << (19 + 6 + rng_config.size_shift);
	aos[0]->aos_munmap((void*)rng_config.base_addr, length);
	
	// Clean up HLS SHA
	length = hls_sha_config.num_words * 64;
	aos[1]->aos_munmap((void*)hls_sha_config.src_addr, length);
	
	// Clean up HLS PgRnk
	aos[2]->aos_munmap(hls_pgrnk_config.read_ptr, pgrnk_read_len);
	aos[2]->aos_munmap(hls_pgrnk_config.write_ptr, pgrnk_write_len);
	
	// Clean up AES
	length = aes_config.num_words * 64;
	aos[3]->aos_munmap((void*)aes_config.src_addr, length);
	aos[3]->aos_munmap((void*)aes_config.dst_addr, length);
	
	// Close files
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
