#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	void* src_addr;
	uint64_t num_words;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34 || length == 41);
    bool large = length == 41;
    if (large) length = 31;

	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
    uint64_t reallength = 1lu << length;
	configs[0].num_words = reallength / 64;
	
	high_resolution_clock::time_point start, end[4];
	duration<double> diff;
	double seconds;
	
	aos_client *aos[4];
	util.setup_aos_client(aos);

    for (int i = 0; i < 4; i++) {
        aos[i]->aos_set_mode(5, large ? 1 : 0);
    }
	
	int fd[4];
	char fnames[4][24] = {"/mnt/nvme0/graph0.binxx", "/mnt/nvme0/graph1.binxx",
	                         "/mnt/nvme0/graph2.binxx", "/mnt/nvme0/graph3.binxx"};
	for (uint64_t app = 0; app < num_apps; ++app) {
        fnames[app][21] = large ? '3' : argv[1][0];
        fnames[app][22] = argv[1][1];
		aos[app]->aos_file_open(fnames[app], fd[app]);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		configs[app].src_addr = nullptr;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		length = configs[0].num_words * 64;
		aos[app]->aos_mmap(configs[app].src_addr, length, PROT_READ, flags, fd[app], 0);
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at %p in %g\n", app,
		       fd[app], configs[app].src_addr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x60, (uint64_t)configs[app].src_addr);
		aos[app]->aos_cntrlreg_write(0x70, (uint64_t)configs[app].src_addr);
		aos[app]->aos_cntrlreg_write(0x80, (uint64_t)configs[app].src_addr);
		aos[app]->aos_cntrlreg_write(0x90, configs[0].num_words);
		aos[app]->aos_cntrlreg_write(0x00, 0x1);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);

    uint64_t output;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
		aos[app]->aos_cntrlreg_read(0x50, output);
		printf("%lu ", output);
	}
	printf("\n");
    uint64_t nbytes_big = 0;
    uint64_t nbytes_small = 0;

    aos[0]->aos_cntrlreg_read(0x20, output);
    nbytes_big += output;
    aos[0]->aos_cntrlreg_read(0x28, output);
    nbytes_big += output;
    aos[0]->aos_cntrlreg_read(0x30, output);
    nbytes_big += output;
    aos[0]->aos_cntrlreg_read(0x38, output);
    nbytes_small += output;
    aos[0]->aos_cntrlreg_read(0x40, output);
    nbytes_small += output;
    aos[0]->aos_cntrlreg_read(0x48, output);
    nbytes_small += output;
    nbytes_big *= 64;
    nbytes_small *= 8;
	
	// print stats
	util.print_stats("hls_tri", nbytes_small, start, end);
	
	length = configs[0].num_words * 64;
	for (uint64_t app = 0; app < num_apps; ++app) {
        aos[app]->aos_set_mode(5, 0);
		aos[app]->aos_munmap(configs[app].src_addr, length);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
