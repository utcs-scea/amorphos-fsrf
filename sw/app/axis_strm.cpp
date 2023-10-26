#include <atomic>
#include <chrono>
#include <thread>
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
uint64_t pcie_addr[2];

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
	
	bool reading[] = {1,1,1,1,0,0,0,0};
	bool writing[] = {0,0,0,0,1,1,1,1};
	uint64_t dests[] = {0,1,2,3,4,5,6,7};
	
	// configure daemon
	for (uint64_t app = 0; app < num_apps; ++app) {
		reading[app] = rw & 0x1;
		writing[app] = rw & 0x2;
		aos[app]->aos_set_mode(11, rw);
		aos[app]->aos_set_mode(10, send_size);
		aos[app]->aos_set_mode(7, 0);
	}
	
	// block until system ready
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t temp;
		aos[app]->aos_cntrlreg_read(0, temp);
	}
	
	// prepare for writes
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (writing[app]) {
			aos[app]->aos_cntrlreg_write(0x10, dests[app]);
			aos[app]->aos_cntrlreg_write(0x18, pckt_len);
		}
	}
	
	high_resolution_clock::time_point start, end[4];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (reading[app]) {
			aos[app]->aos_cntrlreg_write(0x08, uint64_t{1}<<length);
		}
		if (writing[app]) {
			aos[app]->aos_cntrlreg_write(0x00, uint64_t{1}<<length);
		}
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
	util.print_stats("axis_strm", app_bytes, start, end);
	
	// print cycle-based stats
	printf("%lu %s cyc %lu ", num_apps, "axis_strm", total_bytes);
	
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