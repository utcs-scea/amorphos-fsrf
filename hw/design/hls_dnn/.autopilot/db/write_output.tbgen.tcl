set moduleName write_output
set isTopModule 0
set isCombinational 0
set isDatapathOnly 0
set isPipelined 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set C_modelName {write_output}
set C_modelType { void 0 }
set C_modelArgList {
	{ layer7_out_0 int 16 regular {pointer 0}  }
	{ axis_out_V_data_V int 512 regular {axi_s 1 volatile  { axis_out Data } }  }
	{ axis_out_V_keep_V int 64 regular {axi_s 1 volatile  { axis_out Keep } }  }
	{ axis_out_V_strb_V int 64 regular {axi_s 1 volatile  { axis_out Strb } }  }
	{ axis_out_V_last_V int 1 regular {axi_s 1 volatile  { axis_out Last } }  }
	{ axis_out_V_id_V int 5 regular {axi_s 1 volatile  { axis_out ID } }  }
	{ axis_out_V_dest_V int 5 regular {axi_s 1 volatile  { axis_out Dest } }  }
	{ dest int 5 regular {fifo 0}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "layer7_out_0", "interface" : "wire", "bitwidth" : 16, "direction" : "READONLY"} , 
 	{ "Name" : "axis_out_V_data_V", "interface" : "axis", "bitwidth" : 512, "direction" : "WRITEONLY"} , 
 	{ "Name" : "axis_out_V_keep_V", "interface" : "axis", "bitwidth" : 64, "direction" : "WRITEONLY"} , 
 	{ "Name" : "axis_out_V_strb_V", "interface" : "axis", "bitwidth" : 64, "direction" : "WRITEONLY"} , 
 	{ "Name" : "axis_out_V_last_V", "interface" : "axis", "bitwidth" : 1, "direction" : "WRITEONLY"} , 
 	{ "Name" : "axis_out_V_id_V", "interface" : "axis", "bitwidth" : 5, "direction" : "WRITEONLY"} , 
 	{ "Name" : "axis_out_V_dest_V", "interface" : "axis", "bitwidth" : 5, "direction" : "WRITEONLY"} , 
 	{ "Name" : "dest", "interface" : "fifo", "bitwidth" : 5, "direction" : "READONLY"} ]}
# RTL Port declarations: 
set portNum 19
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_continue sc_in sc_logic 1 continue -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ layer7_out_0 sc_in sc_lv 16 signal 0 } 
	{ axis_out_TDATA sc_out sc_lv 512 signal 1 } 
	{ axis_out_TVALID sc_out sc_logic 1 outvld 6 } 
	{ axis_out_TREADY sc_in sc_logic 1 outacc 1 } 
	{ axis_out_TKEEP sc_out sc_lv 64 signal 2 } 
	{ axis_out_TSTRB sc_out sc_lv 64 signal 3 } 
	{ axis_out_TLAST sc_out sc_lv 1 signal 4 } 
	{ axis_out_TID sc_out sc_lv 5 signal 5 } 
	{ axis_out_TDEST sc_out sc_lv 5 signal 6 } 
	{ dest_dout sc_in sc_lv 5 signal 7 } 
	{ dest_empty_n sc_in sc_logic 1 signal 7 } 
	{ dest_read sc_out sc_logic 1 signal 7 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_continue", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "continue", "bundle":{"name": "ap_continue", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "layer7_out_0", "direction": "in", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "layer7_out_0", "role": "default" }} , 
 	{ "name": "axis_out_TDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":512, "type": "signal", "bundle":{"name": "axis_out_V_data_V", "role": "default" }} , 
 	{ "name": "axis_out_TVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "axis_out_V_dest_V", "role": "default" }} , 
 	{ "name": "axis_out_TREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "outacc", "bundle":{"name": "axis_out_V_data_V", "role": "default" }} , 
 	{ "name": "axis_out_TKEEP", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "axis_out_V_keep_V", "role": "default" }} , 
 	{ "name": "axis_out_TSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "axis_out_V_strb_V", "role": "default" }} , 
 	{ "name": "axis_out_TLAST", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "axis_out_V_last_V", "role": "default" }} , 
 	{ "name": "axis_out_TID", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "axis_out_V_id_V", "role": "default" }} , 
 	{ "name": "axis_out_TDEST", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "axis_out_V_dest_V", "role": "default" }} , 
 	{ "name": "dest_dout", "direction": "in", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "dest", "role": "dout" }} , 
 	{ "name": "dest_empty_n", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "dest", "role": "empty_n" }} , 
 	{ "name": "dest_read", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "dest", "role": "read" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "",
		"CDFG" : "write_output",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "1", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "4", "EstimateLatencyMax" : "4",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "1",
		"HasNonBlockingOperation" : "0",
		"Port" : [
			{"Name" : "layer7_out_0", "Type" : "None", "Direction" : "I"},
			{"Name" : "axis_out_V_data_V", "Type" : "Axis", "Direction" : "O",
				"BlockSignal" : [
					{"Name" : "axis_out_TDATA_blk_n", "Type" : "RtlSignal"}]},
			{"Name" : "axis_out_V_keep_V", "Type" : "Axis", "Direction" : "O"},
			{"Name" : "axis_out_V_strb_V", "Type" : "Axis", "Direction" : "O"},
			{"Name" : "axis_out_V_last_V", "Type" : "Axis", "Direction" : "O"},
			{"Name" : "axis_out_V_id_V", "Type" : "Axis", "Direction" : "O"},
			{"Name" : "axis_out_V_dest_V", "Type" : "Axis", "Direction" : "O"},
			{"Name" : "dest", "Type" : "Fifo", "Direction" : "I", "DependentProc" : "0", "DependentChan" : "0", "DependentChanDepth" : "3", "DependentChanType" : "2",
				"BlockSignal" : [
					{"Name" : "dest_blk_n", "Type" : "RtlSignal"}]}]}]}


set ArgLastReadFirstWriteLatency {
	write_output {
		layer7_out_0 {Type I LastRead 0 FirstWrite -1}
		axis_out_V_data_V {Type O LastRead -1 FirstWrite 3}
		axis_out_V_keep_V {Type O LastRead -1 FirstWrite 3}
		axis_out_V_strb_V {Type O LastRead -1 FirstWrite 3}
		axis_out_V_last_V {Type O LastRead -1 FirstWrite 3}
		axis_out_V_id_V {Type O LastRead -1 FirstWrite 3}
		axis_out_V_dest_V {Type O LastRead -1 FirstWrite 3}
		dest {Type I LastRead 3 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "4", "Max" : "4"}
	, {"Name" : "Interval", "Min" : "4", "Max" : "4"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	layer7_out_0 { ap_none {  { layer7_out_0 in_data 0 16 } } }
	axis_out_V_data_V { axis {  { axis_out_TDATA out_data 1 512 }  { axis_out_TREADY out_acc 0 1 } } }
	axis_out_V_keep_V { axis {  { axis_out_TKEEP out_data 1 64 } } }
	axis_out_V_strb_V { axis {  { axis_out_TSTRB out_data 1 64 } } }
	axis_out_V_last_V { axis {  { axis_out_TLAST out_data 1 1 } } }
	axis_out_V_id_V { axis {  { axis_out_TID out_data 1 5 } } }
	axis_out_V_dest_V { axis {  { axis_out_TVALID out_vld 1 1 }  { axis_out_TDEST out_data 1 5 } } }
	dest { ap_fifo {  { dest_dout fifo_data 0 5 }  { dest_empty_n fifo_status 0 1 }  { dest_read fifo_update 1 1 } } }
}
