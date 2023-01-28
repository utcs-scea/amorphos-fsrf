#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct test_config {
	uint64_t base_addr;
	uint64_t size_shift;
} test_config;

int main(int argc, char *argv[]) {
	utils util;
	
	int argi = 1;
	bool reading = true, writing = false;
	uint64_t rw = 1;
	if (argi < argc) rw = atol(argv[argi]);
	assert(1 <= rw && rw <= 3);
	reading = rw & 0x1;
	writing = rw & 0x2;
	++argi;

	test_config.size_shift = 6;
	if (argi < argc) test_config.size_shift = atol(argv[argi]);
	assert(test_config.size_shift <= 15);
	++argi;
	
	uint64_t linear = false;
	if (argi < argc) linear = (bool)atol(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	high_resolution_clock::time_point start, end[4];
	duration<double> diff;
	double seconds;
	
	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file0.bin", "/mnt/nvme0/file1.bin",
	                         "/mnt/nvme0/file2.bin", "/mnt/nvme0/file3.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_file_open(fnames[app], fd[app]);
	}
	
	void *addr[4];
	uint64_t length = uint64_t{1} << (19 + 6 + test_config.size_shift);
	for (uint64_t app = 0; app < num_apps; ++app) {
		addr[app] = nullptr;
		int prot = 0;
		if (reading) prot |= PROT_READ;
		if (writing) prot |= PROT_WRITE;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		aos[app]->aos_mmap(addr[app], length, prot, flags, fd[app], 0);
		end[0] = high_resolution_clock::now();
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at 0x%lX in %g\n", app, fd[app], (uint64_t)addr[app], seconds);
	}
	
	if (reading && writing) {
		printf("Warning: only writing runtimes will be measured\n");
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		test_config.base_addr = (uint64_t)addr[app];
		uint64_t value = test_config.base_addr | (test_config.size_shift << 48) | (linear << 52);
		if (reading) aos[app]->aos_cntrlreg_write(0, value);
		if (writing) aos[app]->aos_cntrlreg_write(0x20, value);
	}
	
	// end runs
	const uint64_t reg_addr = writing ? 0x20 : 0x00;
	util.finish_runs(aos, end, reg_addr, false);
	
	uint64_t sum_cycles = 0;
	uint64_t max_cycles = 0;
	uint64_t cyc_counts[4] = {0, 0, 0, 0};
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t cycles = 0;
		aos[app]->aos_cntrlreg_read(reg_addr, cycles);
		
		sum_cycles += cycles;
		if (cycles > max_cycles) max_cycles = cycles;
		cyc_counts[app] = cycles;
	}
	
	// print stats
	uint64_t num_modes = reading + writing;
	uint64_t app_bytes = num_modes * (1 << test_config.size_shift) * (1 << 19) * 64;
	util.print_stats("rng", app_bytes, start, end);
	
	seconds = ((double)sum_cycles)/num_apps/250000000;
	double throughput = ((double)(app_bytes*num_apps))/seconds/(1<<20);
	printf("%lu rng cyc %lu %g", num_apps, app_bytes*num_apps, seconds);
	seconds = ((double)max_cycles)/250000000;
	printf(" %g %g", seconds, throughput);
	throughput = ((double)(app_bytes*num_apps))/seconds/(1<<20);
	printf(" %g\n", throughput);
	
	printf("%lu rng raw %lu %lu %lu %lu\n", num_apps, cyc_counts[0], cyc_counts[1], cyc_counts[2], cyc_counts[3]);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(addr[app], length);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
