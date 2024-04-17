// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================
#ifndef XMYPROJECT_H
#define XMYPROJECT_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#ifndef __linux__
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"
#else
#include <stdint.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stddef.h>
#endif
#include "xmyproject_hw.h"

/**************************** Type Definitions ******************************/
#ifdef __linux__
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
#else
typedef struct {
    u16 DeviceId;
    u32 Control_BaseAddress;
} XMyproject_Config;
#endif

typedef struct {
    u64 Control_BaseAddress;
    u32 IsReady;
} XMyproject;

typedef u32 word_type;

/***************** Macros (Inline Functions) Definitions *********************/
#ifndef __linux__
#define XMyproject_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XMyproject_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))
#else
#define XMyproject_WriteReg(BaseAddress, RegOffset, Data) \
    *(volatile u32*)((BaseAddress) + (RegOffset)) = (u32)(Data)
#define XMyproject_ReadReg(BaseAddress, RegOffset) \
    *(volatile u32*)((BaseAddress) + (RegOffset))

#define Xil_AssertVoid(expr)    assert(expr)
#define Xil_AssertNonvoid(expr) assert(expr)

#define XST_SUCCESS             0
#define XST_DEVICE_NOT_FOUND    2
#define XST_OPEN_DEVICE_FAILED  3
#define XIL_COMPONENT_IS_READY  1
#endif

/************************** Function Prototypes *****************************/
#ifndef __linux__
int XMyproject_Initialize(XMyproject *InstancePtr, u16 DeviceId);
XMyproject_Config* XMyproject_LookupConfig(u16 DeviceId);
int XMyproject_CfgInitialize(XMyproject *InstancePtr, XMyproject_Config *ConfigPtr);
#else
int XMyproject_Initialize(XMyproject *InstancePtr, const char* InstanceName);
int XMyproject_Release(XMyproject *InstancePtr);
#endif

void XMyproject_Start(XMyproject *InstancePtr);
u32 XMyproject_IsDone(XMyproject *InstancePtr);
u32 XMyproject_IsIdle(XMyproject *InstancePtr);
u32 XMyproject_IsReady(XMyproject *InstancePtr);
void XMyproject_EnableAutoRestart(XMyproject *InstancePtr);
void XMyproject_DisableAutoRestart(XMyproject *InstancePtr);

void XMyproject_Set_nimages(XMyproject *InstancePtr, u64 Data);
u64 XMyproject_Get_nimages(XMyproject *InstancePtr);
void XMyproject_Set_dest(XMyproject *InstancePtr, u64 Data);
u64 XMyproject_Get_dest(XMyproject *InstancePtr);

void XMyproject_InterruptGlobalEnable(XMyproject *InstancePtr);
void XMyproject_InterruptGlobalDisable(XMyproject *InstancePtr);
void XMyproject_InterruptEnable(XMyproject *InstancePtr, u32 Mask);
void XMyproject_InterruptDisable(XMyproject *InstancePtr, u32 Mask);
void XMyproject_InterruptClear(XMyproject *InstancePtr, u32 Mask);
u32 XMyproject_InterruptGetEnabled(XMyproject *InstancePtr);
u32 XMyproject_InterruptGetStatus(XMyproject *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
