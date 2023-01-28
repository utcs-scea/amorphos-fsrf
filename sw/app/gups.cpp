#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	void *data_ptr;
	uint64_t m;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t big = 0;
	if (argi < argc) big = atol(argv[argi]);
	assert(big <= 1);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].m = 1 << length;
	
	high_resolution_clock::time_point start, end[4];
	duration<double> diff;
	double seconds;
	
	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file0.bin", "/mnt/nvme0/file1.bin",
	                         "/mnt/nvme0/file2.bin", "/mnt/nvme0/file3.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (big) aos[app]->aos_set_mode(5, 1);
		aos[app]->aos_file_open(fnames[app], fd[app]);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		configs[app].data_ptr = nullptr;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		length = configs[0].m * 8;
		aos[app]->aos_mmap(configs[app].data_ptr, length, PROT_READ | PROT_WRITE, flags, fd[app], 0);
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at %p in %g\n", app,
		       fd[app], configs[app].data_ptr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, (uint64_t)configs[app].data_ptr);
		aos[app]->aos_cntrlreg_write(0x10, configs[0].m);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x00, false);
	
	uint64_t sum_cycles = 0;
	uint64_t max_cycles = 0;
	uint64_t cyc_counts[4] = {0, 0, 0, 0};
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t cycles = 0;
		aos[app]->aos_cntrlreg_read(0x00, cycles);
		
		sum_cycles += cycles;
		if (cycles > max_cycles) max_cycles = cycles;
		cyc_counts[app] = cycles;
	}
	
	// print stats
	uint64_t app_bytes = configs[0].m * 8 * 4 * 2;
	util.print_stats("gups", app_bytes, start, end);
	
	seconds = ((double)sum_cycles)/num_apps/250000000;
	double throughput = ((double)(app_bytes*num_apps))/seconds/(1<<20);
	printf("%lu gups cyc %lu %g", num_apps, app_bytes*num_apps, seconds);
	seconds = ((double)max_cycles)/250000000;
	printf(" %g %g", seconds, throughput);
	throughput = ((double)(app_bytes*num_apps))/seconds/(1<<20);
	printf(" %g\n", throughput);
	
	printf("%lu gups raw %lu %lu %lu %lu\n", num_apps, cyc_counts[0], cyc_counts[1], cyc_counts[2], cyc_counts[3]);
	
	length = configs[0].m * 8;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(configs[app].data_ptr, length);
		aos[app]->aos_file_close(fd[app]);
		if (big) aos[app]->aos_set_mode(5, 0);
	}
	
	return 0;
}
