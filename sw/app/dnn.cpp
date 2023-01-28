#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t start_addr;
};

int main(int argc, char *argv[]) {
	const uint64_t range = 358<<12;
	
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t kernels = 1;
	if (argi < argc) kernels = atol(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);

	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file0.bin", "/mnt/nvme0/file1.bin",
	                         "/mnt/nvme0/file2.bin", "/mnt/nvme0/file3.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_file_open(fnames[app], fd[app]);
		//printf("App %lu opened file %d\n", app, fd[app]);
	}
	
	high_resolution_clock::time_point start, end;
	duration<double> diff;
	double seconds;
	
	void *addrs[4];
	for (uint64_t app = 0; app < num_apps; ++app) {
		int flags = populate ? MAP_POPULATE : 0;

		start = high_resolution_clock::now();
		aos[app]->aos_mmap(addrs[app], kernels*range, PROT_READ | PROT_WRITE, flags, fd[app], 0);
		configs[app].start_addr = (uint64_t)addrs[app];
		end = high_resolution_clock::now();
		
		diff = end - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at 0x%lX in %g\n", app, fd[app],
		       configs[app].start_addr, seconds);
	}
	
	start = high_resolution_clock::now();
	uint64_t sum_cycles[4] = {0, 0, 0, 0};
	uint64_t total_max_cycles = 0;
	for (uint64_t k = 0; k < kernels; ++k) {
		// start runs
		for (uint64_t app = 0; app < num_apps; ++app) {
			if (k == 0) configs[app].start_addr = (uint64_t)addrs[app];
			aos[app]->aos_cntrlreg_write(0x0, configs[app].start_addr);
			configs[app].start_addr += range;
		}
		
		// end runs
		uint64_t max_cycles = 0;
		for (uint64_t app = 0; app < num_apps; ++app) {
			uint64_t cycles = 0, last_cycles;
			do {
				usleep(100);
				last_cycles = cycles;
				aos[app]->aos_cntrlreg_read(0x0, cycles);
			} while (cycles != last_cycles);
			sum_cycles[app] += cycles;
			if (cycles > max_cycles) max_cycles = cycles;
		}
		total_max_cycles += max_cycles;
	}
	end = high_resolution_clock::now();
	
	// print stats
	uint64_t total_bytes = num_apps * kernels * (20292 + 697) * 64;
	diff = end - start;
	seconds = diff.count();
	double throughput = ((double)total_bytes)/seconds/(1<<20);
	printf("%lu dnn e2e %lu %g %g\n", num_apps, total_bytes, seconds, throughput);
	
	printf("%lu dnn cyc %lu ", num_apps, total_bytes);
	uint64_t total_sum_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		seconds = ((double)sum_cycles[app])/250000000;
		printf("%g ", seconds);
		total_sum_cycles += sum_cycles[app];
	}
	seconds = ((double)total_sum_cycles)/4/250000000;
	throughput = ((double)total_bytes)/seconds/(1<<20);
	printf("%g ", throughput);
	seconds = ((double)total_max_cycles)/250000000;
	throughput = ((double)total_bytes)/seconds/(1<<20);
	printf("%g\n", throughput);

	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(addrs[app], kernels*range);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
