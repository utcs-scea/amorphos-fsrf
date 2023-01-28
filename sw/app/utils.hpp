#pragma once

#include <assert.h>
#include <vector>
#include <chrono>
#include "aos.hpp"

using namespace std::chrono;

class utils {
private:
	uint64_t num_apps;
	uint64_t fio_mode;
	uint64_t coyote_config;
	uint64_t log_prefetch_size;

public:
	void parse_std_args (
		int argc,
		char *argv[],
		int argi,
		uint64_t &num_apps,
		bool &populate
	) {
		num_apps = 1;
		if (argi < argc) num_apps = atol(argv[argi]);
		assert(1 <= num_apps && num_apps <= 4);
		this->num_apps = num_apps;
		++argi;
		
		populate = false;
		if (argi < argc) populate = atoi(argv[argi]);
		++argi;
		
		fio_mode = 0;
		if (argi < argc) fio_mode = atol(argv[argi]);
		assert(fio_mode <= 2 || fio_mode == 4);
		++argi;
		
		coyote_config = 0;
		if (argi < argc) coyote_config = atol(argv[argi]);
		assert(coyote_config <= 2);
		++argi;
		
		log_prefetch_size = 9;
		if (argi < argc) log_prefetch_size = atol(argv[argi]);
		assert(log_prefetch_size <= 9);
		++argi;
	}
	
	void setup_aos_client (
		aos_client **aos
	) {
		for (uint64_t app = 0; app < num_apps; ++app) {
			aos[app] = new aos_client();
			aos[app]->set_slot_id(0);
			aos[app]->set_app_id(app);
			aos[app]->connect();
			aos[app]->aos_set_mode(fio_mode, coyote_config);
			aos[app]->aos_set_mode(3, 1 << log_prefetch_size);
		}
	}
	
	void finish_runs (
		aos_client **aos,
		high_resolution_clock::time_point *end,
		uint64_t reg_addr,
		bool fixed_val,
		uint64_t done_val = 0,
		uint64_t reg_mask = 0xFFFFFFFFFFFFFFFF
	) {
		std::vector<uint64_t> prev_val(num_apps);
		if (!fixed_val) {
			for (uint64_t app = 0; app < num_apps; ++app) {
				aos[app]->aos_cntrlreg_read(reg_addr, prev_val[app]);
			}
		}
		
		std::vector<bool> done(num_apps, false);
		uint64_t done_count = 0;
		while (done_count < num_apps) {
			for (uint64_t app = 0; app < num_apps; ++app) {
				if (done[app]) continue;
				
				uint64_t val;
				aos[app]->aos_cntrlreg_read(reg_addr, val);
				val &= reg_mask;
				
				const uint64_t comp_val = fixed_val ? done_val : prev_val[app];
				if (val == comp_val) {
					done[app] = true;
					++done_count;
					end[app] = high_resolution_clock::now();
				}
				
				prev_val[app] = val;
			}
		}
	}
	
	void print_stats (
		const char *app_name,
		uint64_t app_bytes,
		high_resolution_clock::time_point start,
		high_resolution_clock::time_point *end
	) {
		uint64_t total_bytes = num_apps * app_bytes;
		printf("%lu %s e2e %lu ", num_apps, app_name, total_bytes);
		
		double sum_sec = 0, max_sec = 0;
		for (uint64_t app = 0; app < num_apps; ++app) {
			duration<double> diff = end[app] - start;
			double seconds = diff.count();
			printf("%g ", seconds);
			
			sum_sec += seconds;
			if (seconds > max_sec) max_sec = seconds;
		}
		
		const double avg_sec = sum_sec / num_apps;
		const double avg_tput = ((double)total_bytes)/avg_sec/(1<<20);
		const double min_tput = ((double)total_bytes)/max_sec/(1<<20);
		printf("%g %g\n", avg_tput, min_tput);
	}
};
