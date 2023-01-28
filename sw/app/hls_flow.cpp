#include <chrono>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	void *frame_ptr;
	void *velocity_ptr;
	uint64_t n;
};

int main(int argc, char *argv[]) {
	const uint64_t img_size = 512*1024*8;
	
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t length = 8;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 17);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].n = 1 << length;
	
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
		configs[app].frame_ptr = nullptr;
		configs[app].velocity_ptr = nullptr;
		
		int flags = populate ? MAP_POPULATE : 0;
		uint64_t offset = 0;
		
		start = high_resolution_clock::now();
		aos[app]->aos_mmap(configs[app].frame_ptr, img_size*configs[0].n, PROT_READ, flags, fd[app], offset);
		offset += img_size*configs[0].n;
		aos[app]->aos_mmap(configs[app].velocity_ptr, img_size*configs[0].n, PROT_WRITE, flags, fd[app], offset);
		end[0] = high_resolution_clock::now();
		
		diff = end[0] - start;
		seconds = diff.count();
		printf("App %lu mmaped file %d at %p %p in %g\n", app, fd[app],
		       configs[app].frame_ptr, configs[app].velocity_ptr, seconds);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x20, (uint64_t)configs[app].frame_ptr);
		aos[app]->aos_cntrlreg_write(0x30, (uint64_t)configs[app].velocity_ptr);
		aos[app]->aos_cntrlreg_write(0x40, configs[0].n);
		aos[app]->aos_cntrlreg_write(0x00, 0x1);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
	}
	
	// print stats
	uint64_t app_bytes = img_size * 2 * configs[0].n;
	util.print_stats("hls_flow", app_bytes, start, end);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_munmap(configs[app].frame_ptr, img_size*configs[0].n);
		aos[app]->aos_munmap(configs[app].velocity_ptr, img_size*configs[0].n);
		aos[app]->aos_file_close(fd[app]);
	}
	
	return 0;
}
