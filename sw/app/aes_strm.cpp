#include <pthread.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <numeric>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t key[4];
	uint64_t out_words;
	uint64_t in_words;
	uint64_t out_cyc;
	uint64_t in_cyc;
	uint64_t out_rnv;
	uint64_t in_rnv;
	uint64_t out_vnr;
	uint64_t in_vnr;
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
	uint64_t srcs[8];
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
			srcs[app] = sd[app];
			dests[app] = sd[app];
			host_rd[app] = true;
			host_wr[app] = true;
		} else if (cfg_arch == C_PIPE) {
			srcs[app] = (app == 0) ? sd[app] : app - 1;
			dests[app] = (app == (num_apps - 1)) ? sd[app] : app + 1;
			host_rd[app] = app == (num_apps - 1);
			host_wr[app] = app == 0;
		}
	}
	
	// prepare for runs
	for (uint64_t app = 0; app < num_apps; ++app) {
		const uint64_t addr = 0x100 + 0x8 * srcs[app];
		aos[app]->aos_cntrlreg_write(addr, dests[app]);
	}
	
	high_resolution_clock::time_point start, end[8];
	std::thread threads[8];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<length);
		
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
	}
		
	// end runs
	util.finish_runs(aos, end, 0x20, true, 0);
	
	// print stats
	const uint64_t accl_bytes = (uint64_t{64} << length);
	const uint64_t total_accl_bytes = num_apps * accl_bytes;
	const uint64_t host_bytes = (cfg_arch == C_LOOP) ? total_accl_bytes : accl_bytes;
	const uint64_t total_bytes = total_accl_bytes + host_bytes;
	const uint64_t app_bytes = total_bytes / num_apps;
	util.print_stats("aes_strm", app_bytes, start, end);
	
	// print cycle-based stats
	printf("%lu %s cyc %lu ", num_apps, "aes_strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t app_cyc = 0;
		
		aos[app]->aos_cntrlreg_read(0x30, configs[app].out_cyc);
		aos[app]->aos_cntrlreg_read(0x38, configs[app].in_cyc);
		aos[app]->aos_cntrlreg_read(0x40, configs[app].out_rnv);
		aos[app]->aos_cntrlreg_read(0x48, configs[app].in_rnv);
		aos[app]->aos_cntrlreg_read(0x50, configs[app].out_vnr);
		aos[app]->aos_cntrlreg_read(0x58, configs[app].in_vnr);
		app_cyc = std::max(configs[app].out_cyc, configs[app].in_cyc);
		
		sum_cycles += app_cyc;
		max_cycles = std::max(max_cycles, app_cyc);
		
		double in_eff = (double)configs[app].in_rnv/configs[app].in_cyc*100;
		double out_eff = (double)configs[app].out_vnr/configs[app].out_cyc*100;
		printf("%lu/%0.0f%%/%0.0f%%/%lu ", configs[app].in_cyc, in_eff,
			out_eff, configs[app].out_cyc);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / num_apps;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<30);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<30);
	printf("%g %g\n", avg_tput, min_tput);
	
	// clean up
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_close(sd[app]);
	}
	
	return 0;
}