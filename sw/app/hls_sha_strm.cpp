#include <pthread.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <numeric>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint32_t abcdefgh[8];
	uint64_t num_words;
};

config configs[8];
aos_client *aos[8];

struct thread_config {
	uint64_t app;
	uint64_t length;
	uint64_t send_size;
	
	bool read;
	bool write;
};

void host_thread(thread_config tc) {
	const uint64_t words = uint64_t{1} << tc.length;
	
	if (true) {
		cpu_set_t cpu_set;
		CPU_ZERO(&cpu_set);
		const uint64_t tid[] = {2, 3, 6, 7};
		CPU_SET(tid[0], &cpu_set);
		CPU_SET(tid[1], &cpu_set);
		CPU_SET(tid[2], &cpu_set);
		CPU_SET(tid[3], &cpu_set);
		pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpu_set);
	}
	
	uint64_t read_left = tc.read ? (words * 64) : 0;
	uint64_t write_left = tc.write ? (words * 64) : 0;
	uint64_t write_bytes = tc.send_size * 64;
	uint64_t bytes;
	bool end;
	while (read_left || write_left) {
		if (read_left) {
			void *read_buf;
			end = true;
			aos[tc.app]->aos_stream_read(read_buf, bytes, end);
			(void)read_buf;
			read_left -= bytes;
			aos[tc.app]->aos_stream_free(bytes);
		}
		if (write_left) {
			void *write_buf;
			bytes = std::min(write_bytes, write_left);
			aos[tc.app]->aos_stream_alloc(write_buf, bytes);
			(void)write_buf;
			end = bytes == write_left;
			aos[tc.app]->aos_stream_write(bytes, end);
			write_left -= bytes;
		}
	}
}

int main(int argc, char *argv[]) {
	int argi = 1;
	utils util;
	
	enum cfg_arch_t {C_LOOP = 0, C_PIPE};
	
	cfg_arch_t cfg_arch = C_LOOP;
	if (argi < argc) cfg_arch = (cfg_arch_t)atol(argv[argi]);
	assert(cfg_arch <= 1);
	++argi;
	
	uint64_t num_apps = 1;
	if (argi < argc) num_apps = atol(argv[argi]);
	assert((num_apps >= 1) && (num_apps <= 8));
	++argi;
	
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t send_size = 1024;
	if (argi < argc) send_size = atol(argv[argi]);
	++argi;
	
	// configuration
	//uint64_t srcs[8];
	uint64_t dests[8];
	bool host_rd[8];
	bool host_wr[8];
	int sd[8];
	
	util.num_apps = num_apps;
	util.setup_aos_client(aos);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_open(true, true, sd[app]);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (cfg_arch == C_LOOP) {
			//srcs[app] = sd[app];
			dests[app] = sd[app];
			host_rd[app] = true;
			host_wr[app] = true;
		} else if (cfg_arch == C_PIPE) {
			//srcs[app] = (app == 0) ? sd[app] : app - 1;
			dests[app] = (app == (num_apps - 1)) ? sd[app] : app + 1;
			host_rd[app] = app == (num_apps - 1);
			host_wr[app] = app == 0;
		}
	}
	
	high_resolution_clock::time_point start, end[8];
	std::thread threads[8];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x48, uint64_t{1}<<length);
		aos[app]->aos_cntrlreg_write(0x58, dests[app]);
		aos[app]->aos_cntrlreg_write(0x00, 0x1);
		
		if (host_rd[app] || host_wr[app]) {
			thread_config tc;
			tc.app = app;
			tc.length = length;
			tc.send_size = send_size;
			tc.read = host_rd[app];
			tc.write = host_wr[app];
			threads[app] = std::thread(host_thread, tc);
		}
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (host_rd[app] || host_wr[app]) threads[app].join();
		aos[app]->aos_cntrlreg_write(0x00, 0x10);
	}
		
	// end runs
	util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
	
	// print stats
	const uint64_t accl_bytes = (uint64_t{64} << length);
	const uint64_t total_accl_bytes = num_apps * accl_bytes;
	const uint64_t host_bytes = (cfg_arch == C_LOOP) ? total_accl_bytes : accl_bytes;
	const uint64_t total_bytes = total_accl_bytes + host_bytes;
	const uint64_t app_bytes = total_bytes / num_apps;
	util.print_stats("hls_sha_strm", app_bytes, start, end);
	
	// clean up
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_close(sd[app]);
	}
	
	return 0;
}