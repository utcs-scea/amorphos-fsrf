#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	void *addr;
	uint64_t num_words;
	uint64_t cardinality;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].num_words = 1 << length;
	
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
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		configs[app].addr = nullptr;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		length = configs[0].num_words * 64;
		aos[app]->aos_mmap(configs[app].addr, length, PROT_READ, flags, fd[app], 0);
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at %p in %g\n", app,
		       fd[app], configs[app].addr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x30, (uint64_t)configs[app].addr);
		aos[app]->aos_cntrlreg_write(0x40, configs[0].num_words);
		aos[app]->aos_cntrlreg_write(0x00, 0x1);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);

	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
		aos[app]->aos_cntrlreg_read(0x20, configs[app].cardinality);
		printf("%u ", (uint32_t)configs[app].cardinality);
	}
	printf("\n");
	
	// print stats
	uint64_t app_bytes = configs[0].num_words * 64;
	util.print_stats("hls_hll", app_bytes, start, end);
	
	length = configs[0].num_words * 64;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(configs[app].addr, length);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
