#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t num_verts;
	uint64_t num_edges;
	uint64_t vert_ptr;
	uint64_t edge_ptr;
	uint64_t input_ptr;
	uint64_t output_ptr;
	void *read_ptr;
	void *write_ptr;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	
	configs[0].num_verts = 4;
	if (argi < argc) configs[0].num_verts = atol(argv[argi]);
	// hardware limitation check
	assert(configs[0].num_verts % 4 == 0);
	++argi;

	configs[0].num_edges = 8;
	if (argi < argc) configs[0].num_edges = atol(argv[argi]);
	// hardware limitation check
	assert(configs[0].num_edges % 8 == 0);
	++argi;
	
	uint64_t fname_sel = 0;
	if (argi < argc) fname_sel = atol(argv[argi]);
	assert(fname_sel <= 3);
	++argi;
	
	uint64_t read_length, write_length;
	read_length = configs[0].num_verts*(16+8) + configs[0].num_edges*8;
	write_length = configs[0].num_verts*8;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	high_resolution_clock::time_point start, end[4];
	duration<double> diff;
	double seconds;
	
	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file%lu.bin", "/mnt/nvme0/small%lu.bin",
	                         "/mnt/nvme0/medium%lu.bin", "/mnt/nvme0/large%lu.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		char fname[32];
		snprintf(fname, 32, fnames[fname_sel], app);
		aos[app]->aos_file_open(fname, fd[app]);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		configs[app].read_ptr = nullptr;
		configs[app].write_ptr = nullptr;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		aos[app]->aos_mmap(configs[app].read_ptr, read_length, PROT_READ, flags, fd[app], 0);
		aos[app]->aos_mmap(configs[app].write_ptr, write_length, PROT_WRITE, flags, fd[app], read_length);
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at %p and %p in %g\n", app,
		       fd[app], configs[app].read_ptr, configs[app].write_ptr, seconds);
		
		configs[app].vert_ptr = (uint64_t)configs[app].read_ptr;
		configs[app].edge_ptr = configs[app].vert_ptr + configs[0].num_verts*16;
		configs[app].input_ptr = configs[app].edge_ptr + configs[0].num_edges*8;
		configs[app].output_ptr = (uint64_t)configs[app].write_ptr;
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x20, configs[0].num_verts);
		aos[app]->aos_cntrlreg_write(0x30, configs[0].num_edges);
		aos[app]->aos_cntrlreg_write(0x40, configs[app].vert_ptr);
		aos[app]->aos_cntrlreg_write(0x50, configs[app].edge_ptr);
		aos[app]->aos_cntrlreg_write(0x60, configs[app].input_ptr);
		aos[app]->aos_cntrlreg_write(0x70, configs[app].output_ptr);
		aos[app]->aos_cntrlreg_write(0x00, 0x1);
	}
	// end runs
	util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
	}
	
	// print stats
	uint64_t app_bytes = (configs[0].num_verts*(16+8) + configs[0].num_edges*(8+8));
	util.print_stats("hls_pgrnk", app_bytes, start, end);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(configs[app].read_ptr, read_length);
		aos[app]->aos_munmap(configs[app].write_ptr, write_length);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
