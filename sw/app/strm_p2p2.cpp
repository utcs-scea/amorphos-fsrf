#include <chrono>
#include <thread>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

struct config {
	uint64_t r_cred_addr;
	uint64_t w_cred_addr;
	uint64_t r_data_addr;
	uint64_t w_data_addr;
	uint64_t read_creds;
	uint64_t write_creds;
	uint64_t read_comps;
	uint64_t write_comps;
	uint64_t read_cycles;
	uint64_t write_cycles;
	uint64_t ar_cred;
	uint64_t aw_cred;
	uint64_t r_creds;
	uint64_t w_creds;
	uint64_t b_creds;
};

config configs[8];
aos_client *aos[8];
uint64_t pcie_addr[2];

int main(int argc, char *argv[]) {
	utils util;
	
	int argi = 1;
	if (argi < argc) pcie_addr[0] = strtoull(argv[argi], nullptr, 16);
	++argi;
	if (argi < argc) pcie_addr[1] = strtoull(argv[argi], nullptr, 16);
	++argi;
	
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t split = 0;
	if (argi < argc) split = atol(argv[argi]);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	util.setup_aos_client(aos);
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app+4] = new aos_client();
		aos[app+4]->set_slot_id(1);
		aos[app+4]->set_app_id(app);
		aos[app+4]->connect();
		aos[app+4]->aos_set_mode(2, 0);
		aos[app+4]->aos_set_mode(3, 1 << 9);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		const uint64_t base_addr = app<<34;
		
		aos[app]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app]->aos_cntrlreg_write(0x08, pcie_addr[1] + base_addr + 64);
		aos[app]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app]->aos_cntrlreg_write(0x18, pcie_addr[1] + base_addr + 4096);
		
		aos[app+4]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app+4]->aos_cntrlreg_write(0x08, pcie_addr[0] + base_addr + 64);
		aos[app+4]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app+4]->aos_cntrlreg_write(0x18, pcie_addr[0] + base_addr + 4096);
	}
	
	// block until system ready
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t temp;
		aos[app]->aos_cntrlreg_read(0, temp);
		aos[app+4]->aos_cntrlreg_read(0, temp);
	}
	
	high_resolution_clock::time_point start, end[4];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		const bool towards = app >= split;
		
		configs[app].read_creds  = towards ? 0 : 1 << length;
		configs[app].write_creds = towards ? 1 << length : 0;
		configs[app+4].read_creds  = towards ? 1 << length : 0;
		configs[app+4].write_creds = towards ? 0 : 1 << length;
		
		if (towards) {
			aos[app]->aos_cntrlreg_write(0x28, configs[app].write_creds);
			aos[app+4]->aos_cntrlreg_write(0x20, configs[app+4].read_creds);
		} else {
			aos[app]->aos_cntrlreg_write(0x20, configs[app].read_creds);
			aos[app+4]->aos_cntrlreg_write(0x28, configs[app+4].write_creds);
		}
	}
	
	// end runs
	std::vector<bool> done(num_apps, false);
	uint64_t done_count = 0;
	while (done_count < num_apps) {
		for (uint64_t app = 0; app < num_apps; ++app) {
			const bool towards = app >= split;
			if (done[app]) continue;
			
			uint64_t val;
			if (towards) aos[app+4]->aos_cntrlreg_read(0x30, val);
			else aos[app]->aos_cntrlreg_read(0x30, val);
			
			if (val == 0) {
				done[app] = true;
				++done_count;
				end[app] = high_resolution_clock::now();
			}
		}
	}
	
	// print stats
	uint64_t app_bytes = (uint64_t{64} << length);
	util.print_stats("strm_p2p2", app_bytes, start, end);
	
	/*
	// print more stats
	uint64_t total_bytes = num_apps * app_bytes;
	printf("%lu %s cyc %lu ", num_apps, "strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_read(0x40, configs[app].read_cycles);
		aos[app]->aos_cntrlreg_read(0x48, configs[app].write_cycles);
		sum_cycles += configs[app].read_cycles;
		sum_cycles += configs[app].write_cycles;
		max_cycles = std::max(max_cycles, configs[app].read_cycles);
		max_cycles = std::max(max_cycles, configs[app].write_cycles);
		printf("%lu %lu ", configs[app].read_cycles, configs[app].write_cycles);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / num_apps / 2;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<20);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<20);
	printf("%g %g\n", avg_tput, min_tput);
	*/
	
	return 0;
}