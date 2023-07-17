#ifndef AOS_FIO_
#define AOS_FIO_

#include <unistd.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <cstdlib>
#include <vector>
#include <chrono>
#include <thread>
#include <mutex>
#include <unordered_map>

#include "aos_fpga.hpp"

#define MAP_HUGE_SHIFT 26
#define MAP_HUGE_2MB (21 << MAP_HUGE_SHIFT)

const bool file_io = true;
const bool send_data = true;
const bool metrics = true;
const bool tracing = false;
const bool pcim = true;
const uint64_t max_apps = 4;

class AddrPrefetchHelper {
	std::vector<uint64_t> vpns;
	std::vector<uint64_t> lens;
	std::vector<uint64_t> ages;
	uint64_t max_len;
	
public:
	AddrPrefetchHelper (uint64_t entries, uint64_t max_len) {
		vpns.resize(entries, -1);
		lens.resize(entries, 1);
		ages.resize(entries);
		for (uint64_t i = 0; i < entries; ++i) {
			ages[i] = entries - i - 1;
		}
		this->max_len = max_len;
	}
	
	uint64_t get_num_pages(uint64_t vpn) {
		// increment LRU age and find oldest entry
		uint64_t idx = 0;
		for (uint64_t i = 1; i < ages.size(); ++i) {
			if (ages[i] > ages[idx]) idx = i;
			++ages[i];
		}
		// search for match
		for (uint64_t i = 0; i < vpns.size(); ++i) {
			if (vpn == vpns[i]) {
				uint64_t len_limit = max_len - (vpns[i] % max_len);
				uint64_t len = std::min(lens[i], len_limit);
				lens[i] = std::min(2*lens[i], max_len);
				vpns[i] += len;
				ages[i] = 0;
				return len;
			}
		}
		// no match, replace oldest entry
		vpns[idx] = vpn + 1;
		lens[idx] = 1;
		ages[idx] = 0;
		return 1;
	}
};

class CyTLB {
public:
	CyTLB(uint64_t app_id, aos_fpga* fpga) {
		this->app_id = app_id;
		this->fpga = fpga;
		
		for (uint64_t huge = 0; huge < 3; ++huge) {
			uint64_t order2 = 1 << orders[huge];
			uint64_t assoc2 = 1 << assocs[huge];
			vpns_[huge] = new uint64_t[order2*assoc2];
			ages_[huge] = new uint64_t[order2*assoc2];
			valids_[huge] = new bool[order2*assoc2];
		}
	}
	~CyTLB() {
		for (uint64_t huge = 0; huge < 3; ++huge) {
			delete[] vpns_[huge];
			delete[] ages_[huge];
			delete[] valids_[huge];
		}
	}
	
	void init() {
		for (uint64_t huge = 0; huge < 3; ++huge) {
			uint64_t order2 = 1 << orders[huge];
			uint64_t assoc2 = 1 << assocs[huge];
			for (uint64_t i = 0; i < order2; ++i) {
				for (uint64_t j = 0; j < assoc2; ++j) {
					ages(huge, i, j) = j;
					vlds(huge, i, j) = false;
					
					// zero TLB just in case
					write_tlb(huge, i, j, 0);
				}
			}
		}
	}
	
	void add(uint64_t huge, uint64_t vpn, uint64_t ppn) {
		const uint64_t order2 = 1 << orders[huge];
		const uint64_t assoc2 = 1 << assocs[huge];
		const uint64_t mask = order2 - 1;
		uint64_t i = vpn & mask;
		
		uint64_t a = 0;
		for (uint64_t j = 0; j < assoc2; ++j) {
			if (vlds(huge, i, j) && (vpns(huge, i, j) == vpn)) return;
			
			bool older = ages(huge, i, j) > ages(huge, i, a);
			if (vlds(huge, i, j)) {
				if (vlds(huge, i, a) && older) a = j;
			} else {
				if (vlds(huge, i, a) || older) a = j;
			}
		}
		
		for (uint64_t j = 0; j < assoc2; ++j) ++ages(huge, i, j);
		
		vpns(huge, i, a) = vpn;
		ages(huge, i, a) = 0;
		vlds(huge, i, a) = true;
		
		uint64_t tlb_e;
		if (huge == 2) tlb_e = (vpn << 48) | (ppn << 24) | 0x7;
		else if (huge == 1) tlb_e = (vpn << 37) | (ppn << 13) | 0x7;
		else tlb_e = (vpn << 28) | (ppn << 4) | 0x7;
		write_tlb(huge, i, a, tlb_e);
	}
	
	void remove(uint64_t huge, uint64_t vpn) {
		const uint64_t order2 = 1 << orders[huge];
		const uint64_t assoc2 = 1 << assocs[huge];
		const uint64_t mask = order2 - 1;
		uint64_t i = vpn & mask;
		
		for (uint64_t j = 0; j < assoc2; ++j) {
			if (vlds(huge, i, j) && (vpns(huge, i, j) == vpn)) {
				vlds(huge, i, j) = false;
				write_tlb(huge, i, j, 0);
				break;
			}
		}
	}
private:
	const uint64_t orders[3] = {10, 6, 2};
	const uint64_t page_bits[3] = {12, 21, 32};
	const uint64_t assocs[3] = {2, 1, 2};
	
	uint64_t app_id;
	aos_fpga *fpga;
	
	uint64_t *vpns_[3];
	uint64_t *ages_[3];
	bool *valids_[3];
	
	uint64_t idx(uint64_t huge, uint64_t vpi, uint64_t way) {
		const uint64_t shift = assocs[huge];
		return (vpi << shift) | way;
	}
	uint64_t &vpns(uint64_t huge, uint64_t vpi, uint64_t way) {
		return vpns_[huge][idx(huge, vpi, way)];
	}
	uint64_t &ages(uint64_t huge, uint64_t vpi, uint64_t way) {
		return ages_[huge][idx(huge, vpi, way)];
	}
	bool &vlds(uint64_t huge, uint64_t vpi, uint64_t way) {
		return valids_[huge][idx(huge, vpi, way)];
	}
	
	void write_tlb(uint64_t huge, uint64_t vpi, uint64_t way, uint64_t entry) {
		uint64_t tlb_addr;
		if (huge == 2) tlb_addr = (vpi << 11) | (way << 9) | (1 << 13);
		else if (huge == 1) tlb_addr = (vpi << 8) | (way << 7) | (1 << 14);
		else tlb_addr = (vpi << 5) | (way << 3) | (1 << 15);
		fpga->write_sys_reg(app_id+4, tlb_addr, entry);
	}
};

class aos_fio {
public:
	aos_fio(aos_fpga *fpga, uint64_t app_id) {
		this->fpga = fpga;
		this->app_id = app_id;
		
		standard = true;
		coyote = false;
		coyote_huge = false;
		coyote_prefetch = false;
		physical = false;
		aos_seg = false;
		prefetch_size = 1<<9;
		
		phys_base = base_addrs[app_id];
		phys_bound = base_addrs[app_id] + (16<<20)/max_apps;
		//phys_bound = base_addrs[app_id] + ((2048-128)<<10)/max_apps;
		
		//xfer_buf = aligned_alloc(1<<12, 64<<20);
		xfer_buf = ::mmap(NULL, 2<<20, PROT_READ|PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
		if (xfer_buf == MAP_FAILED) {
			perror("xfer_buf allocation error");
			printf("errno: %d\n", errno);
			exit(EXIT_FAILURE);
		}
		if (mlock(xfer_buf, 2<<20)) {
			perror("mlock error");
		}
		phys_buf = virt_to_phys((uint64_t)xfer_buf);
		for (uint64_t i = 0; i < 512; ++i) {
			uint64_t vpn = ((uint64_t)xfer_buf)+4096*i;
			uint64_t tppn = virt_to_phys(vpn);
			uint64_t pppn = phys_buf + 4096*i;
			if (tppn != pppn) {
				printf("DMA buffer not contiguous, vpn %lu -> %lu, ppn %lu -> %lu\n", (uint64_t)xfer_buf, vpn, phys_buf, tppn);
				exit(EXIT_FAILURE);
			}
		}
		printf("xfer_buf phys base: 0x%lX\n", phys_buf);
		
		cTLB = new CyTLB(app_id, fpga);
	}
	
	~aos_fio() {
		munlock(xfer_buf, 2<<20);
		munmap(xfer_buf, 2<<20);
		//free(xfer_buf);
		delete cTLB;
	}
	
	int file_open(const char* file_path) {
		int true_fd = open(file_path, O_RDWR);
		if (true_fd == -1) {
			printf("Unable to open file: %s\n", file_path);
			return -1;
		}
		
		if (fd_map.empty()) start();
		
		fd_map[next_fd] = true_fd;
		return next_fd++;
	}
	
	int file_close(int fd) {
		int rc = 0;
		
		int true_fd = fd_map[fd];
		if (true_fd == 0) {
			printf("Bad fd for close(): %d\n", fd);
			rc = -1;
		} else {
			rc = close(true_fd);
		}
		
		fd_map.erase(fd);
		
		if (fd_map.empty()) stop();
		
		return rc;
	}
	
	void* mmap(void *addr, uint64_t length, int prot, int flags, int fd, uint64_t offset) {
		const uint64_t num_pages = (length + (4<<10)-1) / (4<<10);
		const bool writeable = (prot & PROT_WRITE);
		const bool populating = (flags & MAP_POPULATE) || physical;
		
		int true_fd = fd_map[fd];
		if (true_fd == 0) {
			printf("Bad fd for mmap(): %d\n", fd);
			fd_map.erase(fd);
			return (void*)invalid_vpn;
		}
		
		uint64_t base_vpn = next_vpn;
		uint64_t bound_vpn = (next_vpn += num_pages);
		if (bound_vpn > (uint64_t{1} << 32)) {
			printf("AOS mode currently only supports up to 4GB of mappings\n");
			exit(EXIT_FAILURE);
		}
		
		VME entry;
		entry.ppn = 0;
		entry.fd_pn = offset / (4<<10);
		entry.fd = true_fd;
		entry.present = false;
		entry.writable = writeable;
		
		vm_mutex.lock();
		vm_maps.reserve(vm_maps.size() + num_pages);
		for (uint64_t vpn = base_vpn; vpn < bound_vpn; ++vpn) {
			vm_maps.insert(std::make_pair(vpn, entry));
			entry.fd_pn += 1;
		}
		vm_mutex.unlock();
		
		if (populating && phys_overflow) {
			printf("Memory full, unable to populate any data for region 0x%lX - 0x%lX\n",
			       base_vpn<<12, bound_vpn<<12);
		} else if (populating) {
			fpga_mutex.lock();
			vm_mutex.lock();
			
			uint64_t phys_pages = num_pages;
			if (coyote && coyote_huge) populate_aligned(base_vpn, phys_pages);
			else populate_unaligned(base_vpn, phys_pages);
			if (phys_pages != num_pages) {
				printf("Only able to populate first %lu bytes of region 0x%lX - 0x%lX\n",
				       phys_pages<<12, base_vpn<<12, bound_vpn<<12);
			}
			
			vm_mutex.unlock();
			fpga_mutex.unlock();
		}
		
		return (void*)(base_vpn << 12);
	}
	
	int munmap(void *addr, uint64_t length) {
		uint64_t base_vpn = (uint64_t)addr / (4<<10);
		uint64_t page_len = (length + (4<<10)-1) / (4<<10);
		uint64_t bound_vpn = base_vpn + page_len;
		int rc = 0;
		
		rc = msync(addr, length, true);
		
		vm_mutex.lock();
		for (uint64_t vpn = base_vpn; vpn < bound_vpn; ++vpn) {
			if (vm_maps.erase(vpn) != 1) rc = 1;
		}
		vm_mutex.unlock();
		
		return rc;
	}
	
	int msync(void *addr, uint64_t length, bool invalidate) {
		const bool metrics = false;
		uint64_t base_vpn = (uint64_t)addr / (4<<10);
		uint64_t page_len = (length + (4<<10)-1) / (4<<10);
		uint64_t bound_vpn = base_vpn + page_len;
		int rc = 0;
		
		typedef std::chrono::duration<double> dur;
		typedef std::chrono::high_resolution_clock hrc;
		hrc::time_point start, end;
		if (metrics) start = hrc::now();

		fpga_mutex.lock();
		vm_mutex.lock();
		bool queued_io = false;
		int queued_fd = -1;
		uint64_t queued_ppn = 0, queued_np = 0, queued_po = 0;
		uint64_t current_huge = invalid_vpn;
		for (uint64_t vpn = base_vpn; vpn < bound_vpn; ++vpn) {
			VME entry;
			auto entry_it = vm_maps.find(vpn);
			const bool entry_valid = (entry_it != vm_maps.end());
			if (entry_valid) entry = entry_it->second;
			
			// Skip invalid entries
			if (!entry_valid) {
				rc = 1;
				continue;
			}
			// Invalidate PTE entries
			if (invalidate && entry.present) {
				if (standard && !tracing) {
					uint64_t dram_addr = tlb_addr(app_id, vpn);
					fpga->write_mem_reg(dram_addr, 0);
				} else if (coyote) {
					cTLB->remove(0, vpn);
					if (coyote_huge && current_huge != (vpn >> 9)) {
						current_huge = vpn >> 9;
						cTLB->remove(1, current_huge);
						huge_page[current_huge] = false;
					}
				} else if (aos_seg) {
					cTLB->remove(2, vpn >> 20);
				}
			}
			// Write back dirty pages
			if (entry.present && entry.writable) {
				if (queued_io) {
					if ((queued_fd != entry.fd) || (queued_ppn + queued_np != entry.ppn) || (queued_po + queued_np != entry.fd_pn) || (queued_np == 512)) {
						// Do I/O
						device_to_file(queued_ppn, queued_np, queued_fd, queued_po);
						queued_io = false;
					} else {
						// Extend I/O
						++queued_np;
					}
				}
				if (!queued_io) {
					// New I/O
					queued_io = true;
					queued_fd = entry.fd;
					queued_ppn = entry.ppn;
					queued_np = 1;
					queued_po = entry.fd_pn;
				}
			}
			// Update VM entry
			if (invalidate && entry.present) {
				ppo_to_vpn[entry.ppn - phys_base] = invalid_vpn;
				entry.ppn = 0;
				entry.present = false;
				vm_maps[vpn] = entry;
			}
		}
		
		if (queued_io) device_to_file(queued_ppn, queued_np, queued_fd, queued_po);
		vm_mutex.unlock();
		fpga_mutex.unlock();
		
		if (metrics) {
			end = hrc::now();
			dur d = (end - start);
			double seconds = d.count();
			printf("Msync took %gs\n", seconds);
		}
		
		return rc;
	}
	
	void set_mode(uint64_t mode, uint64_t data) {
		bool aos_str = true;
		
		switch (mode) {
			case 0:
				standard = true;
				coyote = false;
				physical = false;
				aos_seg	= false;
				break;
			case 1:
				standard = false;
				coyote = true;
				physical = false;
				aos_seg	= false;
				
				coyote_huge = data == 1 || data == 2;
				coyote_prefetch = data == 2 || data == 3;
				break;
			case 2:
				standard = false;
				coyote = false;
				physical = true;
				aos_seg	= false;
				break;
			case 3:
				prefetch_size = data;
				assert(prefetch_size <= 512);
				return;
			case 4:
				standard = false;
				coyote = false;
				physical = false;
				aos_seg = true;
				
				aos_str = data != 1;
				break;
			case 5:
				if (data == 1) phys_bound = base_addrs[app_id] + ((2048-128)<<8);
				else if (data == 2) phys_bound = base_addrs[app_id] + (1024<<8);
				else phys_bound = base_addrs[app_id] + (16<<20)/max_apps;
				return;
			default:
				return;
		}
		
		// TLB enable
		fpga->write_sys_reg(app_id, 0x10, physical ? 0x0 : 0x1);
		
		// TLB select
		fpga->write_sys_reg(app_id, 0x18, coyote || aos_seg ? 0x0 : 0x1);
		
		// AOS emulation select
		fpga->write_sys_reg(app_id, 0x20, aos_seg ? 0x0 : 0x1);
		
		// Coyote striping
		bool striping = (coyote && !coyote_prefetch) || (aos_seg && aos_str);
		fpga->write_sys_reg(app_id + 4, 0x10, striping ? 0x1 : 0x0);
		
		// PCIe Coyote striping
		fpga->write_sys_reg(8, 0x18, striping ? 0x1 : 0x0);
		
		// Enable ROB
		//fpga->write_sys_reg(app_id, 0x20, 0x1);
		
		// Enable PCIe ROB
		//fpga->write_sys_reg(0, 0x28, 0x1);
		
		// Reset FIFO credits
		fpga->write_sys_reg(app_id+10, 0x0, 0);
		fpga->write_sys_reg(app_id+10, 0x8, (1<<14));
		
		// Check that FIFO is empty
		uint64_t fw_creds;
		fpga->read_sys_reg(app_id+10, 0x18, fw_creds);
		assert(fw_creds == 1<<14);
	}
	
private:
	// fpga context
	uint64_t app_id;
	aos_fpga* fpga;
	std::recursive_mutex fpga_mutex;
	
	// modes
	bool standard;
	bool coyote;
	bool coyote_huge;
	bool coyote_prefetch;
	bool physical;
	bool aos_seg;
	uint64_t prefetch_size;
	
	// fd management
	int next_fd;
	std::unordered_map<int, int> fd_map;
	
	// physical memory management
	const uint64_t base_addrs[4] = {0, 8<<20, 4<<20, 12<<20};
	uint64_t phys_base, phys_bound, phys_next;
	bool phys_overflow;
	std::vector<uint64_t> ppo_to_vpn;
	const uint64_t invalid_vpn = uint64_t{0}-1;
	
	void phys_alloc_unaligned(uint64_t &num_pages, uint64_t &ppn) {
		uint64_t max_pages = phys_bound - phys_next;
		num_pages = (max_pages < num_pages) ? max_pages : num_pages;
		ppn = (num_pages > 0) ? phys_next : 0;
		
		if (phys_overflow) phys_evict(ppn, num_pages);
		
		phys_next += num_pages;
		if (phys_next == phys_bound) {
			phys_overflow = true;
			phys_next = standard ? phys_base + (32<<10) : phys_base;
		}
	}
	
	void phys_evict(uint64_t ppn, uint64_t num_pages) {
		const uint64_t ppo_bound = ppn + num_pages - phys_base;
		for (uint64_t ppo = ppn - phys_base; ppo < ppo_bound; ) {
			// identify contiguous virtual region
			uint64_t base_vpn = ppo_to_vpn[ppo];
			while (base_vpn == invalid_vpn && ppo < ppo_bound) {
				++ppo;
				base_vpn = ppo_to_vpn[ppo];
			}
			uint64_t bound_vpn = base_vpn;
			do {
				++ppo;
				++bound_vpn;
			} while ((ppo < ppo_bound) && (ppo_to_vpn[ppo] == bound_vpn));
			
			// flush pages
			uint64_t num_vpns = bound_vpn - base_vpn;
			if (num_vpns > 0) msync((void*)(base_vpn<<12), num_vpns<<12, true);
		}
	}
	
	// virtual memory entries
	uint64_t next_vpn;
	class VME {
	public:
		uint64_t ppn;
		uint64_t fd_pn;
		int fd;
		bool present;
		bool writable;
	};
	std::unordered_map<uint64_t, VME> vm_maps;
	std::recursive_mutex vm_mutex;
	
	// Coyote TLB
	CyTLB *cTLB;
	
	// memory management
	std::unordered_map<uint64_t,bool> huge_page;
	void populate_aligned(uint64_t vpn, uint64_t &num_pages) {
		const uint64_t vpn_off = vpn % 512;
		const uint64_t initial_unaligned = vpn_off ? 512 - vpn_off : 0;
		
		// allocate phys pages to align ppn_off with vpn_off
		if (num_pages >= (512 + initial_unaligned)) {
			const uint64_t ppn_off = phys_next % 512;
			
			uint64_t wasted_pages = 0;
			if (vpn_off < ppn_off) {
				wasted_pages = 512 - ppn_off + vpn_off;
			} else if (vpn_off > ppn_off) {
				wasted_pages = vpn_off - ppn_off;
			}
			
			while (wasted_pages > 0) {
				uint64_t wp = wasted_pages;
				uint64_t ppn;
				phys_alloc_unaligned(wp, ppn);
				
				uint64_t ppo = ppn - phys_base;
				uint64_t ppo_bound = ppo + wp;
				for (; ppo < ppo_bound; ++ppo) {
					ppo_to_vpn[ppo] = invalid_vpn;
				}
				
				wasted_pages -= wp;
			}
		}
		
		populate_unaligned(vpn, num_pages);
		uint64_t huge_vpn = vpn + initial_unaligned + 511;
		for (; huge_vpn < vpn + num_pages; huge_vpn += 512) {
			huge_page[huge_vpn >> 9] = true;
		}
	}
	
	void populate_unaligned(uint64_t vpn, uint64_t &num_pages) {
		uint64_t ppn;
		phys_alloc_unaligned(num_pages, ppn);
		VME entry = vm_maps[vpn];
		tlb_populate(vpn, ppn, num_pages);
		file_to_device(entry.fd, entry.fd_pn, num_pages, ppn);
	}
	
	void tlb_populate(uint64_t base_vpn, uint64_t base_ppn, uint64_t num_pages) {
		uint64_t small_limit = 4096;
		uint64_t large_limit = 128;
		uint64_t pip_left = 0;
		for (uint64_t pn_off = 0; pn_off < num_pages; ++pn_off) {
			const uint64_t app = app_id;
			const uint64_t vpn = base_vpn + pn_off;
			const uint64_t ppn = base_ppn + pn_off;
			const uint64_t rw = vm_maps[vpn].writable;
			
			if (standard && !tracing) {
				uint64_t tlb_e = (vpn << 28) | (ppn << 4) | (rw << 2) | 0x3;
				uint64_t dram_addr = tlb_addr(app, vpn);
				fpga->write_mem_reg(dram_addr, tlb_e);
			} else if (coyote) {
				if (coyote_huge) {
					if ((vpn + 512) <= (base_vpn + num_pages)) {
						if ((vpn % 512 == 0) && (ppn % 512 == 0)) {
							if (large_limit != 0) {
								cTLB->add(1, vpn>>9, ppn>>9);
								--large_limit;
							}
							pip_left = 512;
						}
					}
				}
				if (pip_left == 0) {
					if (small_limit != 0) {
						cTLB->add(0, vpn, ppn);
						--small_limit;
					}
				} else {
					--pip_left;
				}
			} else if (aos_seg) {
				cTLB->add(2, vpn>>20, ppn>>20);
			}
			
			vm_maps[vpn].ppn = ppn;
			vm_maps[vpn].present = true;
			
			ppo_to_vpn[ppn - phys_base] = vpn;
		}
	}
	
	// fault handler
	bool handler_running;
	static void fault_handler(aos_fio *t) {
		uint64_t req, resp;
		
		// Create prefetcher
		const bool coyote_huge_mode = t->coyote && t->coyote_huge;
		const uint64_t prefetch_size = t->aos_seg ? 1<<20 : (coyote_huge_mode ? 1<<9 : t->prefetch_size);
		AddrPrefetchHelper aph(8, prefetch_size);
		
		// Metrics
		uint64_t total_hard_faults = 0;
		uint64_t total_soft_faults = 0;
		uint64_t total_pages = 0;
		
		// Trace file
		FILE *trace_fp = nullptr;
		if (tracing) {
			char fname[32];
			snprintf(fname, 32, "/tmp/trace%lu.txt", t->app_id);
			trace_fp = fopen(fname, "w");
			if (trace_fp == nullptr) {
				printf("Could not open trace file\n");
				exit(EXIT_FAILURE);
			}
			printf("Tracing to %s\n", fname);
		}
		
		while (t->handler_running) {
			// Get request
			t->fpga_mutex.lock();
			t->fpga->read_sys_reg(t->app_id + ((t->coyote || t->aos_seg) ? 4 : 0), 0, req);
			const bool req_bad = !~req;
			const bool req_valid = req & 0x1;
			const bool req_read = (req >> 1) & 0x1;
			const uint64_t req_vpn = (req >> 2) & 0xFFFFFFFFFFFFF;
			if (req_bad || !req_valid) {
				t->fpga_mutex.unlock();
				//usleep(20);
				continue;
			}
			
			// Save trace metadata
			if (tracing) {
				const uint64_t req_state = (req >> 54) & 0x7;
				const uint64_t req_credits = (req >> 57) & 0x7F;
				fprintf(trace_fp, "%lu %c %lu %lu\n", req_vpn, req_read ? 'r' : 'w', req_state, req_credits);
				fflush(trace_fp);
			}
			//printf("fault: app %lu, vpn %lu, read %d\n", t->app_id, req_vpn, req_read);
			
			// Look up VME
			t->vm_mutex.lock();
			VME entry;
			auto entry_it = t->vm_maps.find(req_vpn);
			const bool entry_valid = (entry_it != t->vm_maps.end());
			if (entry_valid) entry = entry_it->second;
			else entry = VME{0, 0, 0, false, false};
			
			// Return early if entry invalid, illegal, or present
			resp = 0;
			if ((t->coyote || t->aos_seg) && !entry_valid) {
				printf("TLB cannot handle invalid vpn %lu\n", req_vpn);
				exit(EXIT_FAILURE);
			}
			if (!entry_valid) {
				printf("Skipping invalid request for app %lu: vpn %lu, read %d\n", t->app_id, req_vpn, req_read);
			}
			if (entry_valid && (entry.writable || req_read) && entry.present) {
				resp = (entry.ppn << 1) | 0x1;
				if (t->coyote) {
					if (t->coyote_huge && t->huge_page[req_vpn>>9]) {
						t->cTLB->add(1, req_vpn>>9, entry.ppn>>9);
					} else {
						t->cTLB->add(0, req_vpn, entry.ppn);
					}
				}
				if (t->coyote) t->fpga->write_sys_reg(t->app_id + 4, 0x8, 0x1);
				// shouldn't happen with AOS segmentation
				assert(!t->aos_seg);
			}
			if (!entry_valid || !(entry.writable || req_read) || entry.present) {
				if (t->standard) t->fpga->write_sys_reg(t->app_id, 0, resp);
				
				t->vm_mutex.unlock();
				t->fpga_mutex.unlock();
				
				++total_soft_faults;
				continue;
			}
			
			// Determine access size
			uint64_t base_vpn, bound_vpn;
			if ((t->standard && !t->phys_overflow) ||
				(t->coyote && t->coyote_prefetch && !t->phys_overflow) ||
				(t->coyote && !t->coyote_prefetch && t->coyote_huge) ||
				t->aos_seg) {
				base_vpn = req_vpn / prefetch_size * prefetch_size;
				bound_vpn = base_vpn + prefetch_size;
			} else {
				bool no_prefetch = t->coyote && !t->coyote_prefetch;
				uint64_t num_pages = no_prefetch ? 1 : aph.get_num_pages(req_vpn);
				base_vpn = req_vpn;
				bound_vpn = req_vpn + num_pages;
			}
			
			uint64_t num_pages = 0;
			if (t->standard || t->coyote) {
				t->get_virt_contig(base_vpn, req_vpn, bound_vpn);
				num_pages = bound_vpn - base_vpn;
				
				// Populate data and TLB entries
				uint64_t total_pop_pages = 0;
				while (total_pop_pages < num_pages) {
					const uint64_t vpn = base_vpn + total_pop_pages;
					uint64_t pop_pages = num_pages - total_pop_pages;
					
					if (t->coyote && t->coyote_huge) t->populate_aligned(vpn, pop_pages);
					else t->populate_unaligned(vpn, pop_pages);
					total_pop_pages += pop_pages;
				}
			} else if (t->aos_seg) {
				// Populate entire segment
				// TODO: handle holes in address space
				while (base_vpn < bound_vpn) {
					if (t->vm_maps.find(base_vpn) == t->vm_maps.end()) break;
					
					uint64_t bound_vpn_ = bound_vpn;
					t->get_virt_contig(base_vpn, base_vpn, bound_vpn_);
					
					uint64_t pop_pages = bound_vpn_ - base_vpn;
					t->populate_unaligned(base_vpn, pop_pages);
					
					base_vpn += pop_pages;
					num_pages += pop_pages;
				}
			}
			
			if (metrics) {
				++total_hard_faults;
				total_pages += num_pages;
			}
			
			// Send response
			if (t->standard) {
				resp = (t->vm_maps[req_vpn].ppn << 1) | 0x1;
				t->fpga->write_sys_reg(t->app_id, 0x0, resp);
			} else if (t->coyote || t->aos_seg) {
				t->fpga->write_sys_reg(t->app_id + 4, 0x8, 0x1);
			}
			t->vm_mutex.unlock();
			t->fpga_mutex.unlock();
		}
		
		if (metrics) {
			printf("Hard faults: %lu, pages transferred: %lu, soft faults: %lu\n",
			       total_hard_faults, total_pages, total_soft_faults);
		}
		
		if (tracing) fclose(trace_fp);
	}
	
	// thread management
	std::thread fault_thread;

	void start() {
		next_fd = 3;
		next_vpn = physical ? phys_base : 0;
		
		std::unordered_map<uint64_t,VME>().swap(vm_maps);
		std::unordered_map<uint64_t,bool>().swap(huge_page);
		
		phys_overflow = false;
		ppo_to_vpn.clear();
		ppo_to_vpn.resize(phys_bound - phys_base, -1);
		phys_next = standard ? phys_base + (32<<10) : phys_base;
		
		fpga->read_sys_reg(9, app_id*8, pages_xfered);
		
		if (standard) {
			memset(xfer_buf, 0, 2<<20);
			
			for (uint64_t i = 0; i < 64; ++i) {
				dma_wrapper(0, 512, phys_base+(i*512));
			}
		}
		
		if (coyote || aos_seg) {
			cTLB->init();
		}
		
		handler_running = true;
		fault_thread = std::thread(fault_handler, this);
	}
	
	void stop() {
		handler_running = false;
		fault_thread.join();
	}
	
	// data management
	void *xfer_buf;
	uint64_t phys_buf;
	uint64_t pages_xfered;
	
	void dma_wrapper(bool from_device, uint64_t num_pages, uint64_t ppn) {
		assert(num_pages <= 512);
		
		if (send_data) {
			if (pcim) {
				uint64_t pcie_addr = phys_buf >> 12;
				uint64_t fpga_addr = ppn;
				uint64_t count = num_pages-1;
				uint64_t channel = app_id;
				uint64_t fpga_read = from_device;
				
				uint64_t command = pcie_addr | (fpga_addr << 28) | (count << 52) | (channel << 61) | (fpga_read << 63);
				//printf("pcim %lu: %lu %lu %lu %lu %lu -> %lu\n", app_id, pcie_addr, fpga_addr, count, channel, fpga_read, command);
				fpga->write_sys_reg(9, 0, command);
				
				uint64_t pages_done = pages_xfered + num_pages;
				do {
					fpga->read_sys_reg(9, app_id*8, pages_xfered);
					//printf("pcim %lu: %lu pages xfered / %lu pages done, %lu pages left\n", app_id, pages_xfered, pages_done, pages_done - pages_xfered);
					if (pages_xfered > pages_done) {
						printf("pcim accounting error\n");
						exit(EXIT_FAILURE);
					}
					//usleep(1000000);
				} while (pages_xfered < pages_done);
			} else {
				if (from_device) {
					if (fpga->dma_read(app_id, xfer_buf, ppn<<12, num_pages<<12)) {
						printf("Transfer metadata: app %lu, buf %p, ppn %lu, pages %lu\n",
						       app_id, xfer_buf, ppn, num_pages);
						exit(EXIT_FAILURE);
					}
				} else {
					if (fpga->dma_write(app_id, xfer_buf, ppn<<12, num_pages<<12)) {
						printf("Transfer metadata: app %lu, buf %p, ppn %lu, pages %lu\n",
						       app_id, xfer_buf, ppn, num_pages);
						exit(EXIT_FAILURE);
					}
				}
			}
		}
	}
	
	void file_to_device(int fd, uint64_t fd_pn, uint64_t num_pages, uint64_t ppn) {
		const uint64_t buf_pages = pcim ? 512 : 512;
		
		for (uint64_t pages_done = 0; pages_done < num_pages; pages_done += buf_pages) {
			uint64_t np = std::min(num_pages - pages_done, buf_pages);
			if (file_io) {
				uint64_t nbytes = pread(fd, xfer_buf, np<<12, fd_pn<<12);
				if (nbytes != (np<<12)) {
					printf("File read failed with error \"%s\"\n", strerror(errno));
					printf("Metadata: fd %d, offset %lu, pages %lu, nbytes %lu\n",
					       fd, fd_pn<<12, np, nbytes);
					exit(EXIT_FAILURE);
				}
			}
			
			dma_wrapper(0, np, ppn);
			
			fd_pn += np;
			ppn += np;
		}
	}
	
	void device_to_file(uint64_t ppn, uint64_t num_pages, int fd, uint64_t fd_pn) {
		assert((num_pages <= 512) || !pcim);
		
		dma_wrapper(1, num_pages, ppn);
		
		if (file_io) {
			uint64_t nbytes = pwrite(fd, xfer_buf, num_pages<<12, fd_pn<<12);
			if (nbytes != (num_pages<<12)) {
				printf("File write failed with error \"%s\"\n", strerror(errno));
				printf("Metadata: fd %d, offset %lu, pages %lu, nbytes %lu\n",
				       fd, fd_pn<<12, num_pages, nbytes);
				exit(EXIT_FAILURE);
			}
		}
	}
	
	// tlb addressing
	static uint64_t tlb_addr(uint64_t app_id, uint64_t vpn) {
		const uint64_t app_offsets[4] = {0, 32ull<<30, 16ull<<30, 48ull<<30};
		const uint64_t tlb_bits = 21;
		uint64_t vpn_index = vpn & ((1 << tlb_bits) - 1);
		uint64_t vpn_offset = (vpn >> tlb_bits) & 0x7;
		uint64_t dram_addr = vpn_index*64 + app_offsets[app_id] + vpn_offset*8;
		return dram_addr;
	}
	
	bool get_virt_contig(uint64_t &base_vpn, uint64_t req_vpn, uint64_t &bound_vpn) {
		VME entry = vm_maps[req_vpn];
		bool ret = true;
		
		for (int64_t vpn = req_vpn-1; vpn >= (int64_t)base_vpn; --vpn) {
			VME entry2;
			auto entry2_it = vm_maps.find(vpn);
			const bool entry2_valid = (entry2_it != vm_maps.end());
			if (entry2_valid) entry2 = entry2_it->second;
			
			if (!entry2_valid || (entry2.fd != entry.fd) || 
			    entry2.present || (entry2.writable != entry.writable) ||
			    ((entry.fd_pn - entry2.fd_pn) != (req_vpn - vpn))) {
				ret = false;
				base_vpn = vpn+1;
				break;
			}
		}
		for (uint64_t vpn = req_vpn+1; vpn < bound_vpn; ++vpn) {
			VME entry2;
			auto entry2_it = vm_maps.find(vpn);
			const bool entry2_valid = (entry2_it != vm_maps.end());
			if (entry2_valid) entry2 = entry2_it->second;
			
			if (!entry2_valid || (entry2.fd != entry.fd) ||
			    entry2.present || (entry2.writable != entry.writable) ||
			    ((entry2.fd_pn - entry.fd_pn) != (vpn - req_vpn))) {
				ret = false;
				bound_vpn = vpn;
				break;
			}
		}
		return ret;
	}
	
	uint64_t virt_to_phys(uint64_t virt_addr) {
		int fd = open("/proc/self/pagemap", O_RDONLY);
		if (fd == -1) {
			perror("pagemap open error");
			exit(EXIT_FAILURE);
		}
		uint64_t pfn = 0;
		uint64_t offset = virt_addr / getpagesize() * 8;
		if (pread(fd, &pfn, 8, offset) != 8) {
			perror("virt_to_phys error");
			exit(EXIT_FAILURE);
		}
		close(fd);
		pfn &= 0x7FFFFFFFFFFFFF;
		return (pfn << 12);
	}
};

#endif  // AOS_FIO_
