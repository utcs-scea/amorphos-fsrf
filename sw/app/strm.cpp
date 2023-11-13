#include <pthread.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <numeric>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t to_write;
	uint64_t to_read;
	uint64_t dest_write;
	uint64_t packet_len;
	uint64_t read_id;
	uint64_t read_last;
	uint64_t curr_len;
	uint64_t write_cyc;
	uint64_t read_cyc;
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
			do {
				void *read_buf;
				aos[tc.app]->aos_stream_read(read_buf, bytes, end);
				(void)read_buf;
				read_left -= bytes;
				aos[tc.app]->aos_stream_free(bytes);
			} while (bytes != 0);
		}
		if (write_left) {
			//do {
				void *write_buf;
				bytes = std::min(write_bytes, write_left);
				aos[tc.app]->aos_stream_alloc(write_buf, bytes);
				(void)write_buf;
				end = bytes == write_left;
				aos[tc.app]->aos_stream_write(bytes, end);
				write_left -= bytes;
			//} while (bytes == write_bytes);
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
	
	uint64_t pckt_len = 63;
	if (argi < argc) pckt_len = atol(argv[argi]);
	++argi;
	
	uint64_t rw = 3;
	if (argi < argc) rw = atol(argv[argi]);
	++argi;
	
	uint64_t send_size = 1024;
	if (argi < argc) send_size = atol(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	util.setup_aos_client(aos);
	
	// configuration
	uint64_t dests[8];
	bool reading[8];
	bool writing[8];
	int sd[8];
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		dests[app] = app;
		reading[app] = rw & 0x1;
		writing[app] = rw & 0x2;
		// host writes when FPGA reads and vice versa
		aos[app]->aos_stream_open(writing[app], reading[app], sd[app]);
	}
	
	// prepare for writes
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (writing[app]) {
			aos[app]->aos_cntrlreg_write(0x10, dests[app]);
			aos[app]->aos_cntrlreg_write(0x18, pckt_len);
		}
	}
	
	high_resolution_clock::time_point start, end[8];
	std::thread threads[8];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		thread_config tc;
		tc.app = app;
		tc.length = length;
		tc.send_size = send_size;
		tc.read = writing[app];
		tc.write = reading[app];
		threads[app] = std::thread(host_thread, tc);
		if (reading[app]) {
			aos[app]->aos_cntrlreg_write(0x08, uint64_t{1}<<length);
		}
		if (writing[app]) {
			aos[app]->aos_cntrlreg_write(0x00, uint64_t{1}<<length);
		}
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		threads[app].join();
	}
	
	// end runs
	std::vector<bool> done(num_apps, false);
	uint64_t done_count = 0;
	while (done_count < num_apps) {
		for (uint64_t app = 0; app < num_apps; ++app) {
			if (done[app]) continue;
			
			uint64_t to_write, to_read;
			aos[app]->aos_cntrlreg_read(0x00, to_write);
			aos[app]->aos_cntrlreg_read(0x08, to_read);
			
			if (to_write + to_read == 0) {
				done[app] = true;
				++done_count;
				end[app] = high_resolution_clock::now();
			}
		}
	}
	
	// print stats
	uint64_t total_bytes = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (writing[app]) total_bytes += uint64_t{64} << length;
		if (reading[app]) total_bytes += uint64_t{64} << length;
	}
	uint64_t app_bytes = total_bytes / num_apps;
	util.print_stats("strm", app_bytes, start, end);
	
	// print cycle-based stats
	printf("%lu %s cyc %lu ", num_apps, "strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0, num_active_apps = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t app_cyc = 0;
		if (writing[app]) {
			aos[app]->aos_cntrlreg_read(0x38, configs[app].write_cyc);
			app_cyc = std::max(app_cyc, configs[app].write_cyc);
		}
		if (reading[app]) {
			aos[app]->aos_cntrlreg_read(0x88, configs[app].read_cyc);
			app_cyc = std::max(app_cyc, configs[app].read_cyc);
		}
		if (writing[app] || reading[app]) {
			sum_cycles += app_cyc;
			max_cycles = std::max(max_cycles, app_cyc);
			++num_active_apps;
		}
		printf("%lu/%lu ", configs[app].write_cyc, configs[app].read_cyc);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / num_active_apps;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<20);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<20);
	printf("%g %g\n", avg_tput, min_tput);
	
	return 0;
}