#include <chrono>
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

int main(int argc, char *argv[]) {
	config configs[4];
	utils util;
	
	int argi = 1;
	uint64_t read_length = 25;
	if (argi < argc) read_length = atol(argv[argi]);
	assert(read_length <= 34);
	++argi;
	
	uint64_t write_length = 25;
	if (argi < argc) write_length = atol(argv[argi]);
	assert(write_length <= 34);
	++argi;
	
	uint64_t num_apps;
	bool populate;
	util.parse_std_args(argc, argv, argi, num_apps, populate);
	
	configs[0].read_creds = 1 << read_length;
	configs[0].write_creds = 1 << write_length;
	
	high_resolution_clock::time_point start, end[4];
	
	aos_client *aos[4];
	util.setup_aos_client(aos);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t base_addr = app<<34;
		aos[app]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app]->aos_cntrlreg_write(0x08, base_addr + 64);
		aos[app]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app]->aos_cntrlreg_write(0x18, base_addr + 4096);
	}
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_cntrlreg_write(0x20, configs[0].read_creds);
		aos[app]->aos_cntrlreg_write(0x28, configs[0].write_creds);
	}
	
	// end runs
	util.finish_runs(aos, end, 0x30, true);
	
	// print stats
	uint64_t app_bytes = (configs[0].read_creds + configs[0].write_creds) * 64;
	util.print_stats("strm", app_bytes, start, end);
	
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
	
	/*
	for (uint64_t i = 0; i < 1; ++i) {
		uint64_t temp;
		for (uint64_t addr = 0x00; addr <= 0x70; addr += 0x8) {
			aos[0]->aos_cntrlreg_read(addr, temp);
			printf("%lu ", temp);
		}
		printf("\n");
	}*/
	
	return 0;
}