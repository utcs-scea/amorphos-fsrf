#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
    uint64_t s0_addr;
    uint64_t s0_words;
    uint64_t s1_addr;
    uint64_t s1_words;
    uint64_t s1_credit;
    uint64_t sc_count;
    uint64_t sc_addr;
    uint64_t sc_words;
    uint64_t scd_addr;
    uint64_t scd_words;
};

int main(int argc, char *argv[]) {
	const uint64_t s_ratio = 512/128;
	const uint64_t sc_ratio = 512/8;
	
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length0 = 10;
	if (argi < argc) length0 = atol(argv[argi]);
	assert(length0 <= 20);
	++argi;

	uint64_t length1 = length0;
	if (argi < argc) length1 = atol(argv[argi]);
	assert(length1 <= 20);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].s0_words = 1 << length0;
	configs[0].s1_words = 1 << length1;
	configs[0].s1_credit = 256;
	configs[0].sc_count = (configs[0].s0_words*s_ratio) * (configs[0].s1_words*s_ratio);
	configs[0].sc_words = (configs[0].sc_count+sc_ratio-1) / sc_ratio;
	
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
		void *addr = nullptr;
		int flags = populate ? MAP_POPULATE : 0;
		uint64_t offset = 0;
		
		start = high_resolution_clock::now();
		length0 = configs[0].s0_words * 64;
		aos[app]->aos_mmap(addr, length0, PROT_READ, flags, fd[app], offset);
		configs[app].s0_addr = (uint64_t)addr;
		offset += length0;
		length1 = configs[0].s1_words * 64;
		aos[app]->aos_mmap(addr, length1, PROT_READ, flags, fd[app], offset);
		configs[app].s1_addr = (uint64_t)addr;
		offset += length1;
		length1 = configs[0].sc_words * 64;
		aos[app]->aos_mmap(addr, length1, PROT_WRITE, flags, fd[app], offset);
		configs[app].sc_addr = (uint64_t)addr;
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at 0x%lX 0x%lX 0x%lX in %g\n", app, fd[app],
		       configs[app].s0_addr, configs[app].s1_addr, configs[app].sc_addr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, configs[app].s0_addr);
		aos[app]->aos_cntrlreg_write(0x08, configs[0].s0_words);
		aos[app]->aos_cntrlreg_write(0x10, configs[app].s1_addr);
		aos[app]->aos_cntrlreg_write(0x18, configs[0].s1_words);
		aos[app]->aos_cntrlreg_write(0x20, configs[0].s1_credit);
		aos[app]->aos_cntrlreg_write(0x28, configs[0].sc_count);
		aos[app]->aos_cntrlreg_write(0x30, configs[app].sc_addr);
		aos[app]->aos_cntrlreg_write(0x38, configs[0].sc_words);
		//aos[app]->aos_cntrlreg_write(0x40, configs[0].scd_addr);
		//aos[app]->aos_cntrlreg_write(0x48, configs[0].scd_words);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x48, true, 0);
	
	// print stats
	uint64_t app_bytes = (configs[0].s0_words + configs[0].s0_words * configs[0].s1_words * s_ratio + configs[0].sc_words) * 64;
	util.print_stats("nw", app_bytes, start, end);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		length0 = configs[0].s0_words * 64;
		aos[app]->aos_munmap((void*)configs[app].s0_addr, length0);
		length1 = configs[0].s1_words * 64;
		aos[app]->aos_munmap((void*)configs[app].s1_addr, length1);
		length1 = configs[0].sc_words * 64;
		aos[app]->aos_munmap((void*)configs[app].sc_addr, length1);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
