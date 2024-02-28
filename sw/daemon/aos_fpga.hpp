#ifndef AOS_FPGA_
#define AOS_FPGA_
#include <unistd.h>

// FPGA specific includes
#include <fpga_pci.h>
#include <fpga_mgmt.h>
#include <utils/lcd.h>
#include <utils/sh_dpi_tasks.h>
#undef swap
#undef min
#undef max

class aos_fpga {
	const bool pcis = false;

public:
	aos_fpga(int slot) {
		int rc, fd;
		char xdma_str[19];
		
		slot_id = slot;
		
		// Init FPGA library
		rc = fpga_mgmt_init();
		if (rc) {
			printf("Unable to initialize the fpga_mgmt library\n");
			exit(EXIT_FAILURE);
		}
		
		// Attach PCIe BARs
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR0, 0, &app_bar_handle);
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR1, 0, &sys_bar_handle);
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR4, BURST_CAPABLE, &mem_bar_handle);
		if (rc) {
			printf("Unable to attach PCIe BAR(s)\n");
			exit(EXIT_FAILURE);
		}
		
		// Allocate huge pages
		fd = open("/proc/sys/vm/nr_hugepages", O_WRONLY);
		pwrite(fd, "64\n", 3, 0);
		close(fd);
		
		// Open XDMA device files
		for (int i = 0; pcis && (i < 4); ++i) {
			snprintf(xdma_str, 19, "/dev/xdma%d_c2h_%d", slot, i);
			dth_fd[i] = open(xdma_str, O_RDONLY);
			snprintf(xdma_str, 19, "/dev/xdma%d_h2c_%d", slot, i);
			htd_fd[i] = open(xdma_str, O_WRONLY);
			
			if ((dth_fd[i] == -1) || (htd_fd[i] == -1)) {
				printf("Unable to open XDMA device\n");
				exit(EXIT_FAILURE);
			}
		}
		
		// Load PCIe addresses
		const char * pcie_strs[] = {
			"/sys/bus/pci/devices/0000:00:0f.0/resource",
			"/sys/bus/pci/devices/0000:00:11.0/resource",
			"/sys/bus/pci/devices/0000:00:13.0/resource",
			"/sys/bus/pci/devices/0000:00:15.0/resource",
			"/sys/bus/pci/devices/0000:00:17.0/resource",
			"/sys/bus/pci/devices/0000:00:19.0/resource",
			"/sys/bus/pci/devices/0000:00:1b.0/resource",
			"/sys/bus/pci/devices/0000:00:1d.0/resource"
		};
		uint64_t pcie_idx = 0;
		if (access(pcie_strs[0], F_OK) == 0) {
			// f1.16xlarge
			pcie_idx = 0;
		} else if (access(pcie_strs[6], F_OK) == 0) {
			// f1.4xlarge
			pcie_idx = 6;
		} else if (access(pcie_strs[7], F_OK) == 0) {
			// f1.2xlarge
			pcie_idx = 7;
		} else {
			printf("Could not find FPGA PCIe device\n");
			exit(EXIT_FAILURE);
		}
		uint64_t *pcie_addr_p = pcie_addr;
		for (; pcie_idx < 8; ++pcie_idx) {
			FILE *fp = fopen(pcie_strs[pcie_idx], "r");
			for (uint64_t bar = 0; bar <= 4; ++bar) {
				uint64_t addr_last = 0;
				uint64_t flags = 0;
				int n = fscanf(fp, "0x%lx 0x%lx 0x%lx\n", pcie_addr_p, &addr_last, &flags);
				
				if (bar == 4 && n != 3) {
					printf("Could not read PCIe bar address\n");
					exit(EXIT_FAILURE);
				}
				if (bar == 4) {
					//printf("Found PCIe device at 0x%lx\n", *pcie_addr_p);
				}
			}
			++pcie_addr_p;
		}
		
		// Set up app streams
		for (uint64_t app_id = 0; app_id < 4; ++app_id) {
			const uint64_t src = 4*slot_id + app_id;
			for (uint64_t dst = 0; dst < 32; ++dst) {
				const uint64_t sm4 = src % 4;
				const uint64_t dm4 = dst % 4;
				
				// Local addrs
				uint64_t cntrl_addr = (dm4<<34) + (1<<18) + (src<<6);
				uint64_t data_addr = (dm4<<34) + (src<<13);
				if (slot_id != dst/4) {
					// Use pcie addr
					const uint64_t pa = pcie_addr[dst/4];
					cntrl_addr += pa;
					cntrl_addr += uint64_t{1}<<48;
					data_addr += pa;
					data_addr += uint64_t{1}<<48;
				}
				
				// Host FIFO
				if (src == dst) {
					cntrl_addr = (uint64_t{1}<<36) + (1<<15) + (sm4<<6);
					data_addr = (uint64_t{1}<<36) + (sm4<<13);
				}
				
				// Stream enable on data addr write
				data_addr += (uint64_t{1}<<49);
				
				uint64_t cfg_addr = 8 * dst;
				write_sys_reg(app_id, cfg_addr, cntrl_addr);
				cfg_addr += (1 << 8);
				write_sys_reg(app_id, cfg_addr, data_addr);
			}
		}
		
		// TODO: Enable PCIM?
		
		return;
	}
	
	int read_app_reg(uint64_t app_id, uint64_t addr, uint64_t &value) {
		return reg_access(app_bar_handle, app_id, addr, value, false, true);
	}
	
	int write_app_reg(uint64_t app_id, uint64_t addr, uint64_t value) {
		return reg_access(app_bar_handle, app_id, addr, value, true, true);
	}
	
	int read_sys_reg(uint64_t app_id, uint64_t addr, uint64_t &value) {
		return reg_access(sys_bar_handle, app_id, addr, value, false, true);
	}
	
	int write_sys_reg(uint64_t app_id, uint64_t addr, uint64_t value) {
		return reg_access(sys_bar_handle, app_id, addr, value, true, true);
	}
	
	int read_mem_reg(uint64_t addr, uint64_t &value) {
		return reg_access(mem_bar_handle, 0, addr, value, false, false);
	}
	
	int write_mem_reg(uint64_t addr, uint64_t value) {
		return reg_access(mem_bar_handle, 0, addr, value, true, false);
	}
	
	int dma_read(uint64_t app_id, void* buf, uint64_t addr, uint64_t bytes) {
		assert(pcis);
		
		uint64_t nbytes = pread(dth_fd[app_id], buf, bytes, addr);
		if (nbytes != bytes) {
			printf("XDMA read failed with error \"%s\"\n", strerror(errno));
			return 1;
		}
		return 0;
	}
	
	int dma_write(uint64_t app_id, void* buf, uint64_t addr, uint64_t bytes) {
		assert(pcis);
		
		uint64_t nbytes = pwrite(htd_fd[app_id], buf, bytes, addr);
		if (nbytes != bytes) {
			printf("XDMA write failed with error \"%s\"\n", strerror(errno));
			return 1;
		}
		return 0;
	}
	
	uint64_t get_slot_id() {
		return slot_id;
	}
	
	uint64_t get_pcie_addr(uint64_t idx) {
		return pcie_addr[idx];
	}
	
private:
	uint64_t slot_id;
	
	// PCIe IDs
	const static uint16_t pci_vendor_id = 0x1D0F; /* PCI Vendor ID */
	const static uint16_t pci_device_id = 0xF001; /* PCI Device ID */
	
	// BARs
	pci_bar_handle_t app_bar_handle;
	pci_bar_handle_t sys_bar_handle;
	pci_bar_handle_t mem_bar_handle;
	
	// XDMA fds
	int dth_fd[4];
	int htd_fd[4];
	
	// FPGA PCIe addresses
	uint64_t pcie_addr[8];
	
	int reg_access(pci_bar_handle_t &bar_handle, uint64_t app_id, uint64_t addr,
			       uint64_t &value, bool write, bool mask) {
		int rc;
		
		// Check the address is 64-bit aligned
		fail_on((addr % 8), out, "Addr is not correctly aligned\n");
		
		// Update addr with mask
		if (mask) {
			addr = (addr >> 3) << 7;
			app_id = app_id << 3;
			addr = addr | app_id;
		}
		
		// Do access
		if (write) {
			rc = fpga_pci_poke64(bar_handle, addr, value);
		} else {
			rc = fpga_pci_peek64(bar_handle, addr, &value);
		}
		fail_on(rc, out, "Unable to access bar");
		
		return rc;
	out:
		return 1;
	}
};

#endif  // AOS_FPGA_
	
