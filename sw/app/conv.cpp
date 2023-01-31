#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

const uint64_t I_SIZE[4] = {128, 4096, 32768, 131072};
#define sqr(i) (I_SIZE[i]*I_SIZE[i])
const uint64_t I_SIZE2[4] = {sqr(0), sqr(1), sqr(2), sqr(3)};

const uint64_t SLEEP_TIME[4] = {1, 50, 100, 100};

struct config {
    uint64_t img_addr;
    uint64_t img_write_addr;
    uint64_t krnl_lower8;
    uint64_t krnl_shift_upper;
};

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;

	int argi = 1;
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 35);
	++argi;

	uint64_t version = length;

	uint64_t maplength = 2*I_SIZE2[version];
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	//configs[0].num_words = 1 << length;
	configs[0].krnl_lower8 = 0x0201020402010201;
	configs[0].krnl_shift_upper = 0x0401;
	
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
		
		start = high_resolution_clock::now();
		//length = configs[0].num_words * 64;
		aos[app]->aos_mmap(addr, maplength/2, PROT_READ , flags, fd[app], 0);
		configs[app].img_addr = (uint64_t)addr;
		aos[app]->aos_mmap(addr, maplength/2, PROT_WRITE, flags, fd[app], maplength/2);
		end[0] = high_resolution_clock::now();
		configs[app].img_write_addr = (uint64_t)addr;
		configs[app].krnl_lower8 = configs[0].krnl_lower8;
		configs[app].krnl_shift_upper = configs[0].krnl_shift_upper;
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at 0x%lX in %g\n", app,
		       fd[app], configs[app].img_addr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, configs[app].img_addr);
		aos[app]->aos_cntrlreg_write(0x08, configs[app].img_write_addr);
		aos[app]->aos_cntrlreg_write(0x10, I_SIZE[version]);
		usleep(100);
		//aos[app]->aos_cntrlreg_write(0x10, configs[app].krnl_lower8);
		aos[app]->aos_cntrlreg_write(0x18, configs[app].krnl_shift_upper);
		//if (app == 0)
		//getState(aos[0]);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x108, true);
	/*for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
	}*/
	
	// print stats
	uint64_t app_bytes = 2 * I_SIZE2[version];
	util.print_stats("conv", app_bytes, start, end);
	
	//length = configs[0].num_words * 64;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap((void*)configs[app].img_addr, maplength/2);
		aos[app]->aos_munmap((void*)configs[app].img_write_addr, maplength/2);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
