#ifndef AOS_FPGA_
#define AOS_FPGA_

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
		
		// Init FPGA library
		rc = fpga_mgmt_init();
		fail_on(rc, out, "Unable to initialize the fpga_mgmt library\n");
		
		// Attach PCIe BARs
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR0, 0, &app_bar_handle);
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR1, 0, &sys_bar_handle);
		rc |= fpga_pci_attach(slot, FPGA_APP_PF, APP_PF_BAR4, BURST_CAPABLE, &mem_bar_handle);
		fail_on(rc, out, "Unable to attach PCIe BAR(s)\n");
		
		// Allocate huge pages
		fd = open("/proc/sys/vm/nr_hugepages", O_WRONLY);
		pwrite(fd, "8\n", 3, 0);
		close(fd);
		
		// Open XDMA device files
		for (int i = 0; pcis && (i < 4); ++i) {
			snprintf(xdma_str, 19, "/dev/xdma%d_c2h_%d", slot, i);
			dth_fd[i] = open(xdma_str, O_RDONLY);
			fail_on(dth_fd[i] == -1, out, "Unable to open XDMA device\n");
			
			snprintf(xdma_str, 19, "/dev/xdma%d_h2c_%d", slot, i);
			htd_fd[i] = open(xdma_str, O_WRONLY);
			fail_on(htd_fd[i] == -1, out, "Unable to open XDMA device\n");
		}
		
	out:
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
	
private:
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
