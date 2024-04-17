// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================
// control
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read)
//        bit 7  - auto_restart (Read/Write)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0  - enable ap_done interrupt (Read/Write)
//        bit 1  - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0  - ap_done (COR/TOW)
//        bit 1  - ap_ready (COR/TOW)
//        others - reserved
// 0x10 : Data signal of nimages
//        bit 31~0 - nimages[31:0] (Read/Write)
// 0x14 : Data signal of nimages
//        bit 31~0 - nimages[63:32] (Read/Write)
// 0x18 : reserved
// 0x1c : Data signal of dest
//        bit 31~0 - dest[31:0] (Read/Write)
// 0x20 : Data signal of dest
//        bit 31~0 - dest[63:32] (Read/Write)
// 0x24 : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

#define XMYPROJECT_CONTROL_ADDR_AP_CTRL      0x00
#define XMYPROJECT_CONTROL_ADDR_GIE          0x04
#define XMYPROJECT_CONTROL_ADDR_IER          0x08
#define XMYPROJECT_CONTROL_ADDR_ISR          0x0c
#define XMYPROJECT_CONTROL_ADDR_NIMAGES_DATA 0x10
#define XMYPROJECT_CONTROL_BITS_NIMAGES_DATA 64
#define XMYPROJECT_CONTROL_ADDR_DEST_DATA    0x1c
#define XMYPROJECT_CONTROL_BITS_DEST_DATA    64

