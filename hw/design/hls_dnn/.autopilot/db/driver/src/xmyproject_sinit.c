// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#include "xparameters.h"
#include "xmyproject.h"

extern XMyproject_Config XMyproject_ConfigTable[];

XMyproject_Config *XMyproject_LookupConfig(u16 DeviceId) {
	XMyproject_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XMYPROJECT_NUM_INSTANCES; Index++) {
		if (XMyproject_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XMyproject_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XMyproject_Initialize(XMyproject *InstancePtr, u16 DeviceId) {
	XMyproject_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XMyproject_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XMyproject_CfgInitialize(InstancePtr, ConfigPtr);
}

#endif

