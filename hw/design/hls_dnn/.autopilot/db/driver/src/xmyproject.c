// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================
/***************************** Include Files *********************************/
#include "xmyproject.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XMyproject_CfgInitialize(XMyproject *InstancePtr, XMyproject_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Control_BaseAddress = ConfigPtr->Control_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XMyproject_Start(XMyproject *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL) & 0x80;
    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL, Data | 0x01);
}

u32 XMyproject_IsDone(XMyproject *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XMyproject_IsIdle(XMyproject *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XMyproject_IsReady(XMyproject *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XMyproject_EnableAutoRestart(XMyproject *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL, 0x80);
}

void XMyproject_DisableAutoRestart(XMyproject *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_AP_CTRL, 0);
}

void XMyproject_Set_nimages(XMyproject *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_NIMAGES_DATA, (u32)(Data));
    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_NIMAGES_DATA + 4, (u32)(Data >> 32));
}

u64 XMyproject_Get_nimages(XMyproject *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_NIMAGES_DATA);
    Data += (u64)XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_NIMAGES_DATA + 4) << 32;
    return Data;
}

void XMyproject_Set_dest(XMyproject *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_DEST_DATA, (u32)(Data));
    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_DEST_DATA + 4, (u32)(Data >> 32));
}

u64 XMyproject_Get_dest(XMyproject *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_DEST_DATA);
    Data += (u64)XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_DEST_DATA + 4) << 32;
    return Data;
}

void XMyproject_InterruptGlobalEnable(XMyproject *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_GIE, 1);
}

void XMyproject_InterruptGlobalDisable(XMyproject *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_GIE, 0);
}

void XMyproject_InterruptEnable(XMyproject *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_IER);
    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_IER, Register | Mask);
}

void XMyproject_InterruptDisable(XMyproject *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_IER);
    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_IER, Register & (~Mask));
}

void XMyproject_InterruptClear(XMyproject *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMyproject_WriteReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_ISR, Mask);
}

u32 XMyproject_InterruptGetEnabled(XMyproject *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_IER);
}

u32 XMyproject_InterruptGetStatus(XMyproject *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XMyproject_ReadReg(InstancePtr->Control_BaseAddress, XMYPROJECT_CONTROL_ADDR_ISR);
}

