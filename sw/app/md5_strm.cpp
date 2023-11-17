#include <pthread.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <numeric>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint32_t md5[4];
	uint64_t out_words;
	uint64_t in_words;
	uint64_t md5_words;
	uint64_t reserved;
	uint64_t out_cyc;
	uint64_t in_cyc;
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
	
	if (tc.app < 4) {
		cpu_set_t cpu_set;
		CPU_ZERO(&cpu_set);
		const uint64_t tid[] = {2, 3, 6, 7};
		CPU_SET(tid[tc.app], &cpu_set);
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
	
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t send_size = 1024;
	if (argi < argc) send_size = atol(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	util.setup_aos_client(aos);
	
	// configuration
	bool reading[8];
	bool writing[8];
	int sd[8];
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		reading[app] = app == 0;
		writing[app] = app == (num_apps - 1);
		// host writes when FPGA reads and vice versa
		if (!(reading[app] || writing[app])) continue;
		aos[app]->aos_stream_open(writing[app], reading[app], sd[app]);
	}
	
	// prepare for writes
	for (uint64_t app = 0; app < num_apps; ++app) {
		const uint64_t src = (app == 0) ? sd[app] : app - 1;
		const uint64_t addr = 0x100 + 0x8 * src;
		// use manual calculation for now, need API in future
		const bool host = app == (num_apps - 1);
		const uint64_t dest = host ? sd[app] : app + 1;
		aos[app]->aos_cntrlreg_write(addr, dest);
		aos[app]->aos_cntrlreg_write(0x30, 0x1);
	}
	
	high_resolution_clock::time_point start, end[8];
	std::thread threads[8];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<length);
		
		if (!(reading[app] || writing[app])) continue;
		
		thread_config tc;
		tc.app = app;
		tc.length = length;
		tc.send_size = send_size;
		tc.read = writing[app];
		tc.write = reading[app];
		threads[app] = std::thread(host_thread, tc);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (!(reading[app] || writing[app])) continue;
		
		threads[app].join();
	}
		
	// end runs
	util.finish_runs(aos, end, 0x20, true, 0);
	
	// print stats
	uint64_t app_bytes = 2 * (uint64_t{64} << length) / num_apps;
	util.print_stats("md5_strm", app_bytes, start, end);
	
	// print cycle-based stats
	const uint64_t total_bytes = num_apps * app_bytes;
	printf("%lu %s cyc %lu ", num_apps, "md5_strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t app_cyc = 0;
		
		aos[app]->aos_cntrlreg_read(0x48, configs[app].in_cyc);
		aos[app]->aos_cntrlreg_read(0x40, configs[app].out_cyc);
		app_cyc = std::max(configs[app].in_cyc, configs[app].out_cyc);
		
		sum_cycles += app_cyc;
		max_cycles = std::max(max_cycles, app_cyc);
		
		printf("%lu/%lu ", configs[app].in_cyc, configs[app].out_cyc);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / num_apps;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<20);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<20);
	printf("%g %g\n", avg_tput, min_tput);
	
	// clean up
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_close(sd[app]);
	}
	
	return 0;
}