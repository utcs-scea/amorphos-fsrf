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
		const uint64_t key = 0x0FEE0000;
		meta_shmid = shmget(key+global_app_id*3+0, (1<<12),
			IPC_CREAT | SHM_R | SHM_W);
		assert(meta_shmid != -1);
		meta_addr = shmat(meta_shmid, nullptr, 0);
		assert(meta_addr != (void*)-1);
		if (mlock(meta_addr, 1<<12)) {
			perror("mlock error");
		}
		meta_phys = virt_to_phys((uint64_t)meta_addr);
		//printf("meta: %d 0x%lx\n", meta_shmid, meta_phys);
		
		recv_shmid = shmget(key+global_app_id*3+1, (1<<21),
			SHM_HUGETLB | IPC_CREAT | SHM_R | SHM_W);
		assert(recv_shmid != -1);
		recv_addr = shmat(recv_shmid, nullptr, 0);
		assert(recv_addr != (void*)-1);
		if (mlock(recv_addr, 1<<21)) {
			perror("mlock error");
		}
		recv_phys = virt_to_phys((uint64_t)recv_addr);
		//printf("recv: %d 0x%lx\n", recv_shmid, recv_phys);
		
		send_shmid = shmget(key+global_app_id*3+2, (1<<21),
			SHM_HUGETLB | IPC_CREAT | SHM_R | SHM_W);
		assert(send_shmid != -1);
		send_addr = shmat(send_shmid, nullptr, 0);
		assert(send_addr != (void*)-1);
		if (mlock(send_addr, 1<<21)) {
			perror("mlock error");
		}
		send_phys = virt_to_phys((uint64_t)send_addr);
		//printf("send: %d 0x%lx\n", send_shmid, send_phys);
	}
	
	~aos_stream() {
		munlock(meta_addr, 4<<10);
		shmdt(meta_addr);
		shmctl(meta_shmid, IPC_RMID, NULL);
		
		munlock(recv_addr, 2<<20);
		shmdt(recv_addr);
		shmctl(recv_shmid, IPC_RMID, NULL);
		
		munlock(send_addr, 2<<20);
		shmdt(send_addr);
		shmctl(send_shmid, IPC_RMID, NULL);
	}
	
	int stream_open(int &sd, int &meta_shmid, int &read_shmid, int &write_shmid) {
		const uint64_t src = global_app_id;
		const uint64_t dm4 = app_id;
		const uint64_t cntrl_addr = (dm4<<34) + (1<<18) + (src<<6);
		const uint64_t data_addr = (dm4<<34) + (src<<13);
		
		fpga->write_sys_reg(4+app_id, 0x00, cntrl_addr);
		fpga->write_sys_reg(4+app_id, 0x08, data_addr);
		fpga->write_sys_reg(4+app_id, 0x10, send_phys);
		fpga->write_sys_reg(4+app_id, 0x20, recv_phys);
		fpga->write_sys_reg(4+app_id, 0x28, meta_phys);
		
		memset(meta_addr, 0, (1<<12));
		memset(recv_addr, 0, (1<<21));
		memset(send_addr, 0, (1<<21));
		
		sd = global_app_id;
		meta_shmid = this->meta_shmid;
		read_shmid = this->recv_shmid;
		write_shmid = this->send_shmid;
		
		return 0;
	}
	
	int stream_close(int sd) {
		return 0;
	}
	
	void stream_read(uint64_t meta_credits, uint64_t data_credits) {
		const uint64_t msg = (meta_credits << 16) | data_credits;
		fpga->write_sys_reg(4 + app_id, 0x30, msg);
	}
	
	void stream_write(uint64_t len, bool last, bool req,
	uint64_t &meta_credits, uint64_t &data_credits) {
		assert(len <= ((1<<21) / 64));
		
		if (len) {
			const uint64_t msg = ((len - 1) << 1) | (last ? 0x1 : 0x0);
			fpga->write_sys_reg(4 + app_id, 0x18, msg);
		}
		
		if (req) {
			uint64_t val;
			fpga->read_sys_reg(4 + app_id, 0x18, val);
			meta_credits = val >> 16;
			data_credits = val & 0xFFFF;
		}
	}
	
	void set_mode(uint64_t mode, uint64_t data) {
		switch (mode) {
			case 6:
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
				return;
			case 9:
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
	
	// stream management
	int meta_shmid;
	int recv_shmid;
	int send_shmid;
	void *meta_addr;
	void *recv_addr;
	void *send_addr;
	uint64_t meta_phys;
	uint64_t recv_phys;
	uint64_t send_phys;
	
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
