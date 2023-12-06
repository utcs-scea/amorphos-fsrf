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
			end = false;
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
	enum cfg_dist_t {C_LOCAL = 0, C_REMOTE, C_HOST};
	//enum cfg_num_t {C_ONE = 1, C_TWO, C_THREE, C_FOUR};
	enum cfg_rw_t {C_RD = 1, C_WR, C_RDWR};
	
	cfg_arch_t cfg_arch = C_LOOP;
	if (argi < argc) cfg_arch = (cfg_arch_t)atol(argv[argi]);
	assert(cfg_arch <= 1);
	++argi;
	
	cfg_dist_t cfg_dist = C_LOCAL;
	if (argi < argc) cfg_dist = (cfg_dist_t)atol(argv[argi]);
	assert(cfg_arch <= 2);
	++argi;
	
	uint64_t cfg_num = 1;
	if (argi < argc) cfg_num = atol(argv[argi]);
	assert((cfg_num >= 1) && (cfg_num <= 8));
	++argi;
	
	cfg_rw_t cfg_rw = C_RDWR;
	if (argi < argc) cfg_rw = (cfg_rw_t)atol(argv[argi]);
	assert((cfg_rw >= 1) && (cfg_rw <= 3));
	++argi;
	
	uint64_t length = 25;
	if (argi < argc) length = atol(argv[argi]);
	assert(length <= 34);
	++argi;
	
	uint64_t pckt_len = 63;
	if (argi < argc) pckt_len = atol(argv[argi]);
	++argi;
	
	uint64_t send_size = 2048;
	if (argi < argc) send_size = atol(argv[argi]);
	++argi;
	
	// configuration
	uint64_t num_apps;
	uint64_t dests[8];
	bool active[8];
	bool accl_rd[8];
	bool accl_wr[8];
	bool host_rd[8];
	bool host_wr[8];
	int sd[8];
	
	num_apps = cfg_num;
	if (cfg_arch == C_LOOP) {
		if (cfg_dist == C_LOCAL) {
			num_apps = 2 * cfg_num;
			assert((cfg_num >= 1) && (cfg_num <= 4));
		} else if (cfg_dist == C_REMOTE) {
			num_apps = 4 + cfg_num;
			assert((cfg_num >= 1) && (cfg_num <= 4));
		} else if (cfg_dist == C_HOST) {
			num_apps = cfg_num;
			assert((cfg_num >= 1) && (cfg_num <= 8));
		}
	} else if (cfg_arch == C_PIPE) {
		num_apps = cfg_num;
		if (cfg_dist == C_LOCAL) {
			assert((cfg_num >= 2) && (cfg_num <= 4));
		} else if (cfg_dist == C_REMOTE) {
			assert((cfg_num >= 5) && (cfg_num <= 8));
		} else if (cfg_dist == C_HOST) {
			assert((cfg_num >= 1) && (cfg_num <= 8));
		}
	}
	
	util.num_apps = num_apps;
	util.setup_aos_client(aos);
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_open(true, true, sd[app]);
	}
	
	for (uint64_t app = 0; app < num_apps; ++app) {
		active[app] = true;
		host_rd[app] = false;
		host_wr[app] = false;
		if (cfg_arch == C_LOOP) {
			if (cfg_dist == C_LOCAL) {
				dests[app] = (app % 2 == 0) ? app + 1 : app - 1;
			} else if (cfg_dist == C_REMOTE) {
				dests[app] = (app / 4 == 0) ? app + 4 : app - 4;
				active[app] = (app % 4) < cfg_num;
			} else if (cfg_dist == C_HOST) {
				dests[app] = app;
				host_rd[app] = true;
				host_wr[app] = true;
			}
		} else if (cfg_arch == C_PIPE) {
			if (cfg_dist == C_LOCAL) {
				dests[app] = (app + 1) % num_apps;
			} else if (cfg_dist == C_REMOTE) {
				dests[app] = (app + 1) % num_apps;
			} else if (cfg_dist == C_HOST) {
				dests[app] = (app == (num_apps - 1)) ? app : app + 1;
				host_rd[app] = app == (num_apps - 1);
				host_wr[app] = app == 0;
			}
		}
		accl_rd[app] = active[app] && ((cfg_rw == C_RD) || (cfg_rw == C_RDWR));
		accl_wr[app] = active[app] && ((cfg_rw == C_WR) || (cfg_rw == C_RDWR));
	}
	
	// prepare for runs
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (!active[app]) continue;
		aos[app]->aos_cntrlreg_write(0x10, dests[app]);
		aos[app]->aos_cntrlreg_write(0x18, pckt_len);
	}
	
	high_resolution_clock::time_point start, end[8];
	std::thread threads[8];
	
	// start runs
	start = high_resolution_clock::now();
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (accl_rd[app]) {
			aos[app]->aos_cntrlreg_write(0x08, uint64_t{1}<<length);
		}
		if (accl_wr[app]) {
			aos[app]->aos_cntrlreg_write(0x00, uint64_t{1}<<length);
		}
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
	std::vector<bool> done(num_apps, false);
	uint64_t done_count = 0;
	while (done_count < num_apps) {
		for (uint64_t app = 0; app < num_apps; ++app) {
			if (done[app]) continue;
			
			uint64_t to_write, to_read;
			aos[app]->aos_cntrlreg_read(0x00, to_write);
			aos[app]->aos_cntrlreg_read(0x08, to_read);
			
			if (!active[app] || (to_write + to_read == 0)) {
				done[app] = true;
				++done_count;
				end[app] = high_resolution_clock::now();
			}
		}
	}
	
	// stats
	uint64_t total_bytes = 0;
	uint64_t active_apps = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (!active[app]) continue;
		++active_apps;
		
		if (accl_rd[app]) total_bytes += uint64_t{64} << length;
		if (accl_wr[app]) total_bytes += uint64_t{64} << length;
		if (host_rd[app]) total_bytes += uint64_t{64} << length;
		if (host_wr[app]) total_bytes += uint64_t{64} << length;
	}
	total_bytes = total_bytes / 2;
	//if (cfg_arch == C_PIPE) total_bytes = uint64_t{64} << length;
	
	// print stats
	{
	printf("%lu %s e2e %lu ", active_apps, "strm", total_bytes);
	
	double sum_sec = 0, max_sec = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (!active[app]) continue;
		
		duration<double> diff = end[app] - start;
		double seconds = diff.count();
		printf("%g ", seconds);
		
		sum_sec += seconds;
		if (seconds > max_sec) max_sec = seconds;
	}
	
	const double avg_sec = sum_sec / active_apps;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<30);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<30);
	printf("%g %g\n", avg_tput, min_tput);
	}
	
	// print cycle-based stats
	printf("%lu %s cyc %lu ", active_apps, "strm", total_bytes);
	
	uint64_t sum_cycles = 0, max_cycles = 0;
	for (uint64_t app = 0; app < num_apps; ++app) {
		if (!active[app]) continue;
		
		uint64_t app_cyc = 0;
		if (accl_wr[app]) {
			aos[app]->aos_cntrlreg_read(0x38, configs[app].write_cyc);
			app_cyc = std::max(app_cyc, configs[app].write_cyc);
		}
		if (accl_rd[app]) {
			aos[app]->aos_cntrlreg_read(0x88, configs[app].read_cyc);
			app_cyc = std::max(app_cyc, configs[app].read_cyc);
		}
		sum_cycles += app_cyc;
		max_cycles = std::max(max_cycles, app_cyc);
		
		printf("%lu/%lu ", configs[app].read_cyc, configs[app].write_cyc);
	}
	
	const double max_sec = (double)max_cycles / 250000000;
	const double avg_sec = (double)sum_cycles / 250000000 / active_apps;
	const double avg_tput = ((double)total_bytes)/avg_sec/(1<<30);
	const double min_tput = ((double)total_bytes)/max_sec/(1<<30);
	printf("%g %g\n", avg_tput, min_tput);
	
	// clean up
	for (uint64_t app = 0; app < num_apps; ++app) {
		aos[app]->aos_stream_close(sd[app]);
	}
	
	return 0;
}