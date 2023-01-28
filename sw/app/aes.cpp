#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t key[4];
	uint64_t src_addr;
	uint64_t dst_addr;
	uint64_t num_words;
	uint64_t rd_credits;
	uint64_t wr_credits;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length = 24;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 33);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].key[0] = 1;
	configs[0].key[1] = 2;
	configs[0].key[2] = 3;
	configs[0].key[3] = 4;
	configs[0].num_words = 1 << length;
	configs[0].rd_credits = 8;
	configs[0].wr_credits = 8;
	
	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	int fd[4];
	const char *fnames[4] = {"/mnt/nvme0/file0.bin", "/mnt/nvme0/file1.bin",
	                         "/mnt/nvme0/file2.bin", "/mnt/nvme0/file3.bin"};
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_file_open(fnames[app], fd[app]);
	}
	
	high_resolution_clock::time_point start, end[4];
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		void *addr = nullptr;
		uint64_t offset = 0;
		int flags = populate ? MAP_POPULATE : 0;
		
		start = high_resolution_clock::now();
		length = configs[0].num_words * 64;
		aos[app]->aos_mmap(addr, length, PROT_READ, flags, fd[app], offset);
		configs[app].src_addr = (uint64_t)addr;
		offset += length;
		aos[app]->aos_mmap(addr, length, PROT_WRITE, flags, fd[app], offset);
		configs[app].dst_addr = (uint64_t)addr;
		end[0] = high_resolution_clock::now();
		
		duration<double> diff = end[0] - start;
		double seconds = diff.count();
		printf("App %lu mmaped file %d at 0x%lX 0x%lX in %g\n", app, fd[app],
		       configs[app].src_addr, configs[app].dst_addr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, configs[0].key[0]);
		aos[app]->aos_cntrlreg_write(0x08, configs[0].key[1]);
		aos[app]->aos_cntrlreg_write(0x10, configs[0].key[2]);
		aos[app]->aos_cntrlreg_write(0x18, configs[0].key[3]);
		aos[app]->aos_cntrlreg_write(0x20, configs[app].src_addr);
		aos[app]->aos_cntrlreg_write(0x28, configs[app].dst_addr);
		//aos[app]->aos_cntrlreg_write(0x30, configs[0].num_words);
		aos[app]->aos_cntrlreg_write(0x38, configs[0].rd_credits);
		aos[app]->aos_cntrlreg_write(0x40, configs[0].wr_credits);
		aos[app]->aos_cntrlreg_write(0x30, configs[0].num_words);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x38, true, 0);
	
	// print stats
	uint64_t app_bytes = configs[0].num_words * 2 * 64;
	util.print_stats("aes", app_bytes, start, end);

	for (uint64_t app = 0; app < num_apps; ++app) {
		length = configs[0].num_words * 64;
		aos[app]->aos_munmap((void*)configs[app].src_addr, length);
		length = configs[0].num_words * 64;
		aos[app]->aos_munmap((void*)configs[app].dst_addr, length);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
