#include <chrono>
#include <thread>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t r_cred_addr;
	uint64_t w_cred_addr;
	uint64_t r_data_addr;
	uint64_t w_data_addr;
	uint64_t read_creds;
	uint64_t write_creds;
	uint64_t read_comps;
	uint64_t write_comps;
	uint64_t read_cycles;
	uint64_t write_cycles;
	uint64_t ar_cred;
	uint64_t aw_cred;
	uint64_t r_creds;
	uint64_t w_creds;
	uint64_t b_creds;
};

config configs[4];
aos_client *aos[4];
void *dmem[4];
int dth_fd[4];
int htd_fd[4];

void strm_thread(
	uint64_t app,
	uint64_t len,
	bool hread,
	bool hwrite
) {
	volatile uint64_t *dmem64 = (uint64_t*)dmem[app];
	char *read_buf  = (char*)aligned_alloc(1<<12, 1<<20);
	char *write_buf = (char*)aligned_alloc(1<<12, 1<<20);
	const uint64_t data_addr = (app<<34) + 4096;
	
	configs[app].read_creds  = hread  ? 0 : 1 << len;
	configs[app].write_creds = hwrite ? 0 : 1 << len;
	
	uint64_t hread_comps  = hread  ? 1 << len : 0;
	uint64_t hwrite_comps = hwrite ? 1 << len : 0;
	
	aos[app]->aos_cntrlreg_write(0x20, configs[app].read_creds);
	aos[app]->aos_cntrlreg_write(0x28, configs[app].write_creds);
	
	uint64_t hread_creds  = dmem64[16];
	uint64_t hwrite_creds = dmem64[24];
	
	//volatile uint64_t waste;
	//if (hread)  waste = dmem64[0];
	//if (hwrite) waste = dmem64[8];
	if (hwrite) while (dmem64[8]) {}
	
	bool reading = true;
	bool writing = true;
	while (reading || writing) {
		if (writing) {
			if (hwrite) {
				uint64_t w_creds = dmem64[8];
				hwrite_creds += w_creds;
				uint64_t wr_bytes = (hwrite_comps < hwrite_creds) ? hwrite_comps*64 : hwrite_creds*64;
				
				if (wr_bytes) {
					uint64_t pw_bytes = pwrite(htd_fd[app], write_buf, wr_bytes, data_addr);
					assert(pw_bytes == wr_bytes);
					
					hwrite_creds -= wr_bytes/64;
					hwrite_comps -= wr_bytes/64;
					if (hwrite_comps == 0) writing = false;
				}
			} else {
				uint64_t write_comps;
				aos[app]->aos_cntrlreg_read(0x38, write_comps);
				if (write_comps == 0) writing = false;
			}
		}
		if (reading) {
			if (hread) {
				uint64_t r_creds = dmem64[0];
				hread_creds += r_creds;
				uint64_t rd_bytes = (hread_comps < hread_creds) ? hread_comps*64 : hread_creds*64;
				
				if (rd_bytes) {
					uint64_t pr_bytes = pread(dth_fd[app], read_buf, rd_bytes, data_addr);
					assert(pr_bytes == rd_bytes);
					
					hread_creds -= rd_bytes/64;
					hread_comps -= rd_bytes/64;
					if (hread_comps == 0) reading = false;
				}
			} else {
				uint64_t read_comps;
				aos[app]->aos_cntrlreg_read(0x30, read_comps);
				if (read_comps == 0) reading = false;
			}
		}
	}
	
	free(read_buf);
	free(write_buf);
}

int main(int argc, char *argv[]) {
	utils util;
	
	int argi = 1;
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	bool hread = 0;
	if (argi < argc) hread = atoi(argv[argi]);
	++argi;
	
	bool hwrite = 0;
	if (argi < argc) hwrite = atoi(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	util.setup_aos_client(aos);
	
	int fd = open("/sys/bus/pci/devices/0000:00:1d.0/resource4", O_RDWR);
	assert(fd >= 0);
	
	char xdma_str[19];
	for (uint64_t app = 0; app < num_apps; ++app) {
		snprintf(xdma_str, 19, "/dev/xdma%d_c2h_%lu", 0, app);
		dth_fd[app] = open(xdma_str, O_RDONLY);
		assert(dth_fd[app] >= 0);
		
		snprintf(xdma_str, 19, "/dev/xdma%d_h2c_%lu", 0, app);
		htd_fd[app] = open(xdma_str, O_WRONLY);
		assert(htd_fd[app] >= 0);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t base_addr = app<<34;
		
		dmem[app] = mmap(NULL, 1<<21, PROT_READ | PROT_WRITE, MAP_SHARED, fd, base_addr);
		assert(dmem[app] != MAP_FAILED);
		
		aos[app]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app]->aos_cntrlreg_write(0x08, base_addr + 64);
		aos[app]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app]->aos_cntrlreg_write(0x18, base_addr + 4096);
	}
	
	high_resolution_clock::time_point start, end[4];
	std::thread threads[4];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		threads[app] = std::thread(strm_thread, app, length, hread, hwrite);
	}
	
	// end runs
	for (uint64_t app = 0; app < num_apps; ++app) {
		threads[app].join();
		end[app] = high_resolution_clock::now();
	}
	
	// print stats
	uint64_t app_bytes = (uint64_t{128} << length);
	util.print_stats("strm_host", app_bytes, start, end);
	
	// print more stats
	uint64_t total_bytes = num_apps * app_bytes;
	printf("%lu %s cyc %lu ", num_apps, "strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_read(0x40, configs[app].read_cycles);
		aos[app]->aos_cntrlreg_read(0x48, configs[app].write_cycles);
		sum_cycles += configs[app].read_cycles;
		sum_cycles += configs[app].write_cycles;
		max_cycles = std::max(max_cycles, configs[app].read_cycles);
		max_cycles = std::max(max_cycles, configs[app].write_cycles);
		printf("%lu %lu ", configs[app].read_cycles, configs[app].write_cycles);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / num_apps / 2;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<20);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<20);
	printf("%g %g\n", avg_tput, min_tput);
	
	/*
	for (uint64_t i = 0; i < 1; ++i) {
		uint64_t temp;
		for (uint64_t addr = 0x00; addr <= 0x70; addr += 0x8) {
			aos[0]->aos_cntrlreg_read(addr, temp);
			printf("%lu ", temp);
		}
		printf("\n");
	}*/
	
	return 0;
}