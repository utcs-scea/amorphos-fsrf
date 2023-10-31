#ifndef AOS_STREAM_
#define AOS_STREAM_

#include <unistd.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <pthread.h>
#include <cstdlib>
#include <atomic>
#include <chrono>
#include <mutex>
#include <thread>
#include <vector>
#include <unordered_map>

#include "aos_fpga.hpp"

#define MAP_HUGE_SHIFT 26
#define MAP_HUGE_2MB (21 << MAP_HUGE_SHIFT)

class aos_stream {
public:
	aos_stream(aos_fpga *fpga, uint64_t app_id) {
		this->fpga = fpga;
		this->app_id = app_id;
		global_app_id = 4*fpga->get_slot_id() + app_id;
		
		// Reserve host buffers
		send_addr = ::mmap(NULL, 2<<20, PROT_READ|PROT_WRITE,
			MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
		if (send_addr == MAP_FAILED) {
			perror("send_addr allocation error");
			printf("errno: %d\n", errno);
			exit(EXIT_FAILURE);
		}
		if (mlock(send_addr, 2<<20)) {
			perror("mlock error");
		}
		send_phys = virt_to_phys((uint64_t)send_addr);
		printf("send_phys: 0x%lx\n", send_phys);
		
		recv_addr = ::mmap(NULL, 2<<20, PROT_READ|PROT_WRITE,
			MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
		if (recv_addr == MAP_FAILED) {
			perror("recv_addr allocation error");
			printf("errno: %d\n", errno);
			exit(EXIT_FAILURE);
		}
		if (mlock(recv_addr, 2<<20)) {
			perror("mlock error");
		}
		recv_phys = virt_to_phys((uint64_t)recv_addr);
		printf("recv_phys: 0x%lx\n", recv_phys);
		
		meta_addr = aligned_alloc(4<<10, 4<<10);
		if (meta_addr == MAP_FAILED) {
			perror("meta_addr allocation error");
			printf("errno: %d\n", errno);
			exit(EXIT_FAILURE);
		}
		if (mlock(meta_addr, 4<<10)) {
			perror("mlock error");
		}
		meta_phys = virt_to_phys((uint64_t)meta_addr);
		printf("meta_phys: 0x%lx\n", meta_phys);
		
		thread_writing = true;
		thread_reading = true;
		send_size = 1024;
	}
	
	~aos_stream() {
		munlock(send_addr, 2<<20);
		munmap(send_addr, 2<<20);
		munlock(recv_addr, 2<<20);
		munmap(recv_addr, 2<<20);
		munlock(meta_addr, 4<<10);
		free(meta_addr);
	}
	
	int file_open(const char* file_path) {
		int true_fd = open(file_path, O_RDWR);
		if (true_fd == -1) {
			printf("Unable to open file: %s\n", file_path);
			return -1;
		}
		
		if (!thread_running) start();
		
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
	
	int sread(int fd, uint64_t length, uint64_t offset) {
		int true_fd = fd_map[fd];
		if (true_fd == 0) {
			printf("Bad fd: %d\n", fd);
			fd_map.erase(fd);
			return -1;
		}
		
		// TODO: add request
		// TODO: P2P support
		
		return global_app_id;
	}
	
	int swrite(int fd, uint64_t length, uint64_t offset) {
		int true_fd = fd_map[fd];
		if (true_fd == 0) {
			printf("Bad fd: %d\n", fd);
			fd_map.erase(fd);
			return -1;
		}
		
		// TODO: add request
		// TODO: P2P support
		
		return global_app_id;
	}
	
	void set_mode(uint64_t mode, uint64_t data) {
		switch (mode) {
			case 6:
				fpga_mutex.lock();
				for (uint64_t addr = 0x00; addr <= 0x38; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x100; addr <= 0x138; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x200; addr <= 0x260; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n\n");
				fpga_mutex.unlock();
				return;
			case 7:
				if (!thread_running) start();
				return;
			case 8:
				if (thread_running) stop();
				return;
			case 9:
				fpga_mutex.lock();
				for (uint64_t addr = 0x00; addr <= 0x38; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(4+app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x40; addr <= 0x68; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(4+app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x70; addr <= 0x98; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(4+app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x100; addr <= 0x138; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(4+app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				for (uint64_t addr = 0x140; addr <= 0x180; addr += 0x8) {
					uint64_t reg;
					fpga->read_sys_reg(4+app_id, addr, reg);
					printf("0x%lx ", reg);
				}
				printf("\n");
				printf("%lu %lu", recv_metric, recv_data_metric);
				printf("\n\n");
				fpga_mutex.unlock();
				return;
			case 10:
				send_size = data;
				return;
			case 11:
				thread_writing = data & 0x1;
				thread_reading = data & 0x2;
				return;
			default:
				return;
		}
	}
	
private:
	// fpga context
	uint64_t app_id;
	uint64_t global_app_id;
	aos_fpga* fpga;
	std::recursive_mutex fpga_mutex;
	std::recursive_mutex stream_mutex;
	
	// fd management
	int next_fd;
	std::unordered_map<int, int> fd_map;
	
	// fault handler
	bool thread_running;
	bool thread_reading;
	bool thread_writing;
	uint64_t send_size;
	uint64_t recv_metric;
	uint64_t recv_data_metric;
	static void stream_handler(aos_stream *t) {
		if (t->fpga->get_slot_id() == 0) {
			cpu_set_t cpu_set;
			CPU_ZERO(&cpu_set);
			const uint64_t tid[] = {0, 1, 4, 5};
			CPU_SET(tid[t->app_id], &cpu_set);
			pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpu_set);
		}
		
		volatile uint8_t *begin_send_addr, *curr_send_addr, *end_send_addr;
		volatile uint8_t *begin_recv_addr, *curr_recv_addr, *end_recv_addr;
		volatile uint8_t *begin_meta_addr, *curr_meta_addr, *end_meta_addr;
		uint64_t send_size, recv_size, meta_size;
		
		send_size = 2<<20;
		begin_send_addr = (volatile uint8_t *)t->send_addr;
		curr_send_addr = begin_send_addr;
		end_send_addr = curr_send_addr + send_size;
		
		recv_size = 2<<20;
		begin_recv_addr = (volatile uint8_t *)t->recv_addr;
		curr_recv_addr = begin_recv_addr;
		end_recv_addr = curr_recv_addr + recv_size;
		
		meta_size = 4<<10;
		begin_meta_addr = (volatile uint8_t *)t->meta_addr;
		curr_meta_addr = begin_meta_addr;
		end_meta_addr = curr_meta_addr + meta_size;
		
		uint64_t meta_valid = 1;
		
		uint64_t send_creds = 32;
		uint64_t send_data_creds = send_size/64;
		uint64_t recv_creds = meta_size/4;
		uint64_t recv_data_creds = recv_size/64;
		
		while (t->thread_running) {
			t->fpga_mutex.lock();
			
			// HtD path
			if (t->thread_writing) {
				uint64_t val;
				t->fpga->read_sys_reg(4+t->app_id, 0x18, val);
				uint64_t data_creds = val & 0xFFFF;
				uint64_t meta_creds = val >> 16;
				
				send_data_creds += data_creds;
				send_creds += meta_creds;
				
				const uint64_t send_size = t->send_size;
				while (send_creds && (send_data_creds >= send_size)) {
					t->fpga->write_sys_reg(4+t->app_id, 0x18, (send_size-1)<<1);
					
					send_data_creds -= send_size;
					send_creds -= 1;
				}
			}
			
			// DtH path
			if (t->thread_reading) {
				//std::atomic_thread_fence(std::memory_order_seq_cst);
				uint64_t val = *curr_meta_addr;
				while (((val >> 7) & 0x1) == meta_valid) {
					//const uint64_t last = val & 0x1;
					const uint64_t len = ((val >> 1) & 0x3F) + 1;
					
					curr_meta_addr += 4;
					if (curr_meta_addr >= end_meta_addr) {
						curr_meta_addr -= meta_size;
						meta_valid ^= 0x1;
					}
					
					curr_recv_addr += 64*len;
					if (curr_recv_addr >= end_recv_addr) {
						curr_recv_addr -= recv_size;
					}
					
					recv_creds += 1;
					recv_data_creds += len;
					
					t->recv_metric += 1;
					t->recv_data_metric += len;
					
					val = *curr_meta_addr;
				}
				
				if (recv_creds >= 512) {
					uint64_t msg = (recv_creds << 16) | recv_data_creds;
					t->fpga->write_sys_reg(4+t->app_id, 0x30, msg);
					recv_creds = 0;
					recv_data_creds = 0;
				}
			}
			
			t->fpga_mutex.unlock();
		}
	}
	
	// stream management
	void *send_addr;
	void *recv_addr;
	void *meta_addr;
	uint64_t send_phys;
	uint64_t recv_phys;
	uint64_t meta_phys;
	
	// thread management
	std::thread the_thread;

	void start() {
		next_fd = 3;
		// TODO: reset next stream ID
		
		const uint64_t src = global_app_id;
		const uint64_t dm4 = app_id;
		const uint64_t cntrl_addr = (dm4<<34) + (1<<18) + (src<<6);
		const uint64_t data_addr = (dm4<<34) + (src<<13);
		
		fpga->write_sys_reg(4+app_id, 0x00, cntrl_addr);
		fpga->write_sys_reg(4+app_id, 0x08, data_addr);
		fpga->write_sys_reg(4+app_id, 0x10, send_phys);
		fpga->write_sys_reg(4+app_id, 0x20, recv_phys);
		fpga->write_sys_reg(4+app_id, 0x28, meta_phys);
		
		thread_running = true;
		the_thread = std::thread(stream_handler, this);
	}
	
	void stop() {
		thread_running = false;
		the_thread.join();
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

#endif  // AOS_STREAM_
