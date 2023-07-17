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
volatile uint64_t *sbar[2];
uint64_t pcie_addr[2];

void sys_reg_access(
	uint64_t slot,
	uint64_t sys_id,
	uint64_t index,
	uint64_t &value,
	bool write
) {
	index = index << 4;
	index = index | sys_id;
	
	if (write) {
		sbar[slot][index] = value;
	} else {
		value = sbar[slot][index];
	}
}

void strm_thread(
	uint64_t app,
	uint64_t len,
	bool towards
) {
	const uint64_t data_addr = (app<<34) + 4096;
	uint64_t words_left = 1 << len;
	
	configs[app].read_creds  = towards ? 0 : 1 << len;
	configs[app].write_creds = towards ? 1 << len : 0;
	configs[app+4].read_creds  = towards ? 1 << len : 0;
	configs[app+4].write_creds = towards ? 0 : 1 << len;
	
	if (towards) {
		aos[app]->aos_cntrlreg_write(0x28, configs[app].write_creds);
		aos[app+4]->aos_cntrlreg_write(0x20, configs[app+4].read_creds);
	} else {
		aos[app]->aos_cntrlreg_write(0x20, configs[app].read_creds);
		aos[app+4]->aos_cntrlreg_write(0x28, configs[app+4].write_creds);
	}
	
	uint64_t read_creds  = 0;
	uint64_t write_creds = 0;
	
	uint64_t dma_count;
	sys_reg_access(!towards, 9, app, dma_count, false);
	
	uint64_t cmd = (uint64_t{1} << 63) | (app << 61) | (app << 39);
	cmd |= ((data_addr >> 12) << 15);
	
	while (true) {
		uint64_t r_creds;
		sys_reg_access(!towards, 10+app, 0, r_creds, false);
		read_creds += r_creds;
		uint64_t w_creds;
		sys_reg_access(towards, 10+app, 1, w_creds, false);
		write_creds += w_creds;
		
		uint64_t min_creds = (read_creds < write_creds) ? read_creds : write_creds;
		uint64_t to_send = (words_left < min_creds) ? words_left : min_creds;
		
		if (to_send) {
			uint64_t final_cmd = cmd | ((to_send-1) << 45);
			sys_reg_access(!towards, 9, 2048/8, final_cmd, true);
			
			uint64_t final_dma_count = dma_count + ((to_send + 63)/64);
			while (dma_count < final_dma_count) {
				sys_reg_access(!towards, 9, app, dma_count, false);
				assert(dma_count <= final_dma_count);
			}
			
			read_creds -= to_send;
			write_creds -= to_send;
			words_left -= to_send;
			if (words_left == 0) break;
		}
	}
}

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
	
	// block until set_mode completes
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t temp;
		aos[app]->aos_cntrlreg_read(0, temp);
		aos[app+4]->aos_cntrlreg_read(0, temp);
	}
	
	int fds[2];
	fds[0] = open("/sys/bus/pci/devices/0000:00:1b.0/resource1", O_RDWR);
	assert(fds[0] >= 0);
	fds[1] = open("/sys/bus/pci/devices/0000:00:1d.0/resource1", O_RDWR);
	assert(fds[1] >= 0);
	
	void *temptr;
	temptr = mmap(NULL, 1<<21, PROT_READ | PROT_WRITE, MAP_SHARED, fds[0], 0);
	assert(temptr != MAP_FAILED);
	sbar[0] = (volatile uint64_t *)temptr;
	temptr = mmap(NULL, 1<<21, PROT_READ | PROT_WRITE, MAP_SHARED, fds[1], 0);
	assert(temptr != MAP_FAILED);
	sbar[1] = (volatile uint64_t *)temptr;
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		uint64_t base_addr = app<<34;
		
		aos[app]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app]->aos_cntrlreg_write(0x08, base_addr + 64);
		aos[app]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app]->aos_cntrlreg_write(0x18, base_addr + 4096);
		
		aos[app+4]->aos_cntrlreg_write(0x00, base_addr + 0);
		aos[app+4]->aos_cntrlreg_write(0x08, base_addr + 64);
		aos[app+4]->aos_cntrlreg_write(0x10, base_addr + 4096);
		aos[app+4]->aos_cntrlreg_write(0x18, base_addr + 4096);
		
		uint64_t temp_addr = pcie_addr[1] + base_addr + 4096;
		sys_reg_access(0, 9, app, temp_addr, true);
		temp_addr = pcie_addr[0] + base_addr + 4096;
		sys_reg_access(1, 9, app, temp_addr, true);
	}
	
	high_resolution_clock::time_point start, end[4];
	std::thread threads[4];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		threads[app] = std::thread(strm_thread, app, length, app >= split);
	}
	
	// end runs
	for (uint64_t app = 0; app < num_apps; ++app) {
		threads[app].join();
		end[app] = high_resolution_clock::now();
	}
	
	// print stats
	uint64_t app_bytes = (uint64_t{64} << length);
	util.print_stats("strm_p2p", app_bytes, start, end);
	
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