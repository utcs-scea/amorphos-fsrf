// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Version: 2020.2
// Copyright (C) Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

(* CORE_GENERATION_INFO="optical_flow_optical_flow,hls_ip_2020_2,{HLS_INPUT_TYPE=cxx,HLS_INPUT_FLOAT=0,HLS_INPUT_FIXED=0,HLS_INPUT_PART=xcvu9p-flgb2104-2-i,HLS_INPUT_CLOCK=3.000000,HLS_INPUT_ARCH=others,HLS_SYN_CLOCK=2.190000,HLS_SYN_LAT=-1,HLS_SYN_TPT=none,HLS_SYN_MEM=114,HLS_SYN_DSP=0,HLS_SYN_FF=160265,HLS_SYN_LUT=83572,HLS_VERSION=2020_2}" *)

module optical_flow (
        s_axi_control_AWVALID,
        s_axi_control_AWREADY,
        s_axi_control_AWADDR,
        s_axi_control_WVALID,
        s_axi_control_WREADY,
        s_axi_control_WDATA,
        s_axi_control_WSTRB,
        s_axi_control_ARVALID,
        s_axi_control_ARREADY,
        s_axi_control_ARADDR,
        s_axi_control_RVALID,
        s_axi_control_RREADY,
        s_axi_control_RDATA,
        s_axi_control_RRESP,
        s_axi_control_BVALID,
        s_axi_control_BREADY,
        s_axi_control_BRESP,
        ap_clk,
        ap_rst_n,
        interrupt,
        m_axi_gmem_AWVALID,
        m_axi_gmem_AWREADY,
        m_axi_gmem_AWADDR,
        m_axi_gmem_AWID,
        m_axi_gmem_AWLEN,
        m_axi_gmem_AWSIZE,
        m_axi_gmem_AWBURST,
        m_axi_gmem_AWLOCK,
        m_axi_gmem_AWCACHE,
        m_axi_gmem_AWPROT,
        m_axi_gmem_AWQOS,
        m_axi_gmem_AWREGION,
        m_axi_gmem_AWUSER,
        m_axi_gmem_WVALID,
        m_axi_gmem_WREADY,
        m_axi_gmem_WDATA,
        m_axi_gmem_WSTRB,
        m_axi_gmem_WLAST,
        m_axi_gmem_WID,
        m_axi_gmem_WUSER,
        m_axi_gmem_ARVALID,
        m_axi_gmem_ARREADY,
        m_axi_gmem_ARADDR,
        m_axi_gmem_ARID,
        m_axi_gmem_ARLEN,
        m_axi_gmem_ARSIZE,
        m_axi_gmem_ARBURST,
        m_axi_gmem_ARLOCK,
        m_axi_gmem_ARCACHE,
        m_axi_gmem_ARPROT,
        m_axi_gmem_ARQOS,
        m_axi_gmem_ARREGION,
        m_axi_gmem_ARUSER,
        m_axi_gmem_RVALID,
        m_axi_gmem_RREADY,
        m_axi_gmem_RDATA,
        m_axi_gmem_RLAST,
        m_axi_gmem_RID,
        m_axi_gmem_RUSER,
        m_axi_gmem_RRESP,
        m_axi_gmem_BVALID,
        m_axi_gmem_BREADY,
        m_axi_gmem_BRESP,
        m_axi_gmem_BID,
        m_axi_gmem_BUSER
);

parameter    C_S_AXI_CONTROL_DATA_WIDTH = 64;
parameter    C_S_AXI_CONTROL_ADDR_WIDTH = 7;
parameter    C_S_AXI_DATA_WIDTH = 64;
parameter    C_S_AXI_ADDR_WIDTH = 32;
parameter    C_M_AXI_GMEM_ID_WIDTH = 1;
parameter    C_M_AXI_GMEM_ADDR_WIDTH = 64;
parameter    C_M_AXI_GMEM_DATA_WIDTH = 512;
parameter    C_M_AXI_GMEM_AWUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_ARUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_WUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_RUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_BUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_USER_VALUE = 0;
parameter    C_M_AXI_GMEM_PROT_VALUE = 0;
parameter    C_M_AXI_GMEM_CACHE_VALUE = 3;
parameter    C_M_AXI_ID_WIDTH = 1;
parameter    C_M_AXI_ADDR_WIDTH = 64;
parameter    C_M_AXI_DATA_WIDTH = 32;
parameter    C_M_AXI_AWUSER_WIDTH = 1;
parameter    C_M_AXI_ARUSER_WIDTH = 1;
parameter    C_M_AXI_WUSER_WIDTH = 1;
parameter    C_M_AXI_RUSER_WIDTH = 1;
parameter    C_M_AXI_BUSER_WIDTH = 1;

parameter C_S_AXI_CONTROL_WSTRB_WIDTH = (64 / 8);
parameter C_S_AXI_WSTRB_WIDTH = (64 / 8);
parameter C_M_AXI_GMEM_WSTRB_WIDTH = (512 / 8);
parameter C_M_AXI_WSTRB_WIDTH = (32 / 8);

input   s_axi_control_AWVALID;
output   s_axi_control_AWREADY;
input  [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] s_axi_control_AWADDR;
input   s_axi_control_WVALID;
output   s_axi_control_WREADY;
input  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0] s_axi_control_WDATA;
input  [C_S_AXI_CONTROL_WSTRB_WIDTH - 1:0] s_axi_control_WSTRB;
input   s_axi_control_ARVALID;
output   s_axi_control_ARREADY;
input  [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] s_axi_control_ARADDR;
output   s_axi_control_RVALID;
input   s_axi_control_RREADY;
output  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0] s_axi_control_RDATA;
output  [1:0] s_axi_control_RRESP;
output   s_axi_control_BVALID;
input   s_axi_control_BREADY;
output  [1:0] s_axi_control_BRESP;
input   ap_clk;
input   ap_rst_n;
output   interrupt;
output   m_axi_gmem_AWVALID;
input   m_axi_gmem_AWREADY;
output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_gmem_AWADDR;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_AWID;
output  [7:0] m_axi_gmem_AWLEN;
output  [2:0] m_axi_gmem_AWSIZE;
output  [1:0] m_axi_gmem_AWBURST;
output  [1:0] m_axi_gmem_AWLOCK;
output  [3:0] m_axi_gmem_AWCACHE;
output  [2:0] m_axi_gmem_AWPROT;
output  [3:0] m_axi_gmem_AWQOS;
output  [3:0] m_axi_gmem_AWREGION;
output  [C_M_AXI_GMEM_AWUSER_WIDTH - 1:0] m_axi_gmem_AWUSER;
output   m_axi_gmem_WVALID;
input   m_axi_gmem_WREADY;
output  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_gmem_WDATA;
output  [C_M_AXI_GMEM_WSTRB_WIDTH - 1:0] m_axi_gmem_WSTRB;
output   m_axi_gmem_WLAST;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_WID;
output  [C_M_AXI_GMEM_WUSER_WIDTH - 1:0] m_axi_gmem_WUSER;
output   m_axi_gmem_ARVALID;
input   m_axi_gmem_ARREADY;
output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_gmem_ARADDR;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_ARID;
output  [7:0] m_axi_gmem_ARLEN;
output  [2:0] m_axi_gmem_ARSIZE;
output  [1:0] m_axi_gmem_ARBURST;
output  [1:0] m_axi_gmem_ARLOCK;
output  [3:0] m_axi_gmem_ARCACHE;
output  [2:0] m_axi_gmem_ARPROT;
output  [3:0] m_axi_gmem_ARQOS;
output  [3:0] m_axi_gmem_ARREGION;
output  [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_gmem_ARUSER;
input   m_axi_gmem_RVALID;
output   m_axi_gmem_RREADY;
input  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_gmem_RDATA;
input   m_axi_gmem_RLAST;
input  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_RID;
input  [C_M_AXI_GMEM_RUSER_WIDTH - 1:0] m_axi_gmem_RUSER;
input  [1:0] m_axi_gmem_RRESP;
input   m_axi_gmem_BVALID;
output   m_axi_gmem_BREADY;
input  [1:0] m_axi_gmem_BRESP;
input  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_BID;
input  [C_M_AXI_GMEM_BUSER_WIDTH - 1:0] m_axi_gmem_BUSER;

(* shreg_extract = "no" *) reg    ap_rst_reg_2;
(* shreg_extract = "no" *) reg    ap_rst_reg_1;
(* shreg_extract = "no" *) reg    ap_rst_n_inv;
wire   [63:0] frames;
wire   [63:0] outputs;
wire   [63:0] n;
wire    ap_start;
reg    ap_ready;
reg    ap_done;
reg    ap_idle;
wire    gmem_AWREADY;
wire    gmem_WREADY;
wire    gmem_ARREADY;
wire    gmem_RVALID;
wire   [511:0] gmem_RDATA;
wire    gmem_RLAST;
wire   [0:0] gmem_RID;
wire   [0:0] gmem_RUSER;
wire   [1:0] gmem_RRESP;
wire    gmem_BVALID;
wire   [1:0] gmem_BRESP;
wire   [0:0] gmem_BID;
wire   [0:0] gmem_BUSER;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWVALID;
wire   [63:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWADDR;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWID;
wire   [31:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLEN;
wire   [2:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWSIZE;
wire   [1:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWBURST;
wire   [1:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLOCK;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWCACHE;
wire   [2:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWPROT;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWQOS;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWREGION;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWUSER;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WVALID;
wire   [511:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WDATA;
wire   [63:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WSTRB;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WLAST;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WID;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WUSER;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARVALID;
wire   [63:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARADDR;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARID;
wire   [31:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLEN;
wire   [2:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARSIZE;
wire   [1:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARBURST;
wire   [1:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLOCK;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARCACHE;
wire   [2:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARPROT;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARQOS;
wire   [3:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARREGION;
wire   [0:0] dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARUSER;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_RREADY;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_BREADY;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_start;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_idle;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_continue;
wire    ap_sync_continue;
wire    ap_sync_done;
wire    ap_sync_ready;
reg   [63:0] loop_dataflow_input_count;
reg   [63:0] loop_dataflow_output_count;
wire   [63:0] bound_minus_1;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_start_full_n;
wire    dataflow_in_loop_VITIS_LOOP_536_1_U0_start_write;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 ap_rst_reg_2 = 1'b1;
#0 ap_rst_reg_1 = 1'b1;
#0 ap_rst_n_inv = 1'b1;
#0 loop_dataflow_input_count = 64'd0;
#0 loop_dataflow_output_count = 64'd0;
end

optical_flow_control_s_axi #(
    .C_S_AXI_ADDR_WIDTH( C_S_AXI_CONTROL_ADDR_WIDTH ),
    .C_S_AXI_DATA_WIDTH( C_S_AXI_CONTROL_DATA_WIDTH ))
control_s_axi_U(
    .AWVALID(s_axi_control_AWVALID),
    .AWREADY(s_axi_control_AWREADY),
    .AWADDR(s_axi_control_AWADDR),
    .WVALID(s_axi_control_WVALID),
    .WREADY(s_axi_control_WREADY),
    .WDATA(s_axi_control_WDATA),
    .WSTRB(s_axi_control_WSTRB),
    .ARVALID(s_axi_control_ARVALID),
    .ARREADY(s_axi_control_ARREADY),
    .ARADDR(s_axi_control_ARADDR),
    .RVALID(s_axi_control_RVALID),
    .RREADY(s_axi_control_RREADY),
    .RDATA(s_axi_control_RDATA),
    .RRESP(s_axi_control_RRESP),
    .BVALID(s_axi_control_BVALID),
    .BREADY(s_axi_control_BREADY),
    .BRESP(s_axi_control_BRESP),
    .ACLK(ap_clk),
    .ARESET(ap_rst_n_inv),
    .ACLK_EN(1'b1),
    .frames(frames),
    .outputs(outputs),
    .n(n),
    .ap_start(ap_start),
    .interrupt(interrupt),
    .ap_ready(ap_ready),
    .ap_done(ap_done),
    .ap_idle(ap_idle)
);

optical_flow_gmem_m_axi #(
    .CONSERVATIVE( 0 ),
    .USER_DW( 512 ),
    .USER_AW( 64 ),
    .USER_MAXREQS( 69 ),
    .NUM_READ_OUTSTANDING( 8 ),
    .NUM_WRITE_OUTSTANDING( 8 ),
    .MAX_READ_BURST_LENGTH( 64 ),
    .MAX_WRITE_BURST_LENGTH( 64 ),
    .C_M_AXI_ID_WIDTH( C_M_AXI_GMEM_ID_WIDTH ),
    .C_M_AXI_ADDR_WIDTH( C_M_AXI_GMEM_ADDR_WIDTH ),
    .C_M_AXI_DATA_WIDTH( C_M_AXI_GMEM_DATA_WIDTH ),
    .C_M_AXI_AWUSER_WIDTH( C_M_AXI_GMEM_AWUSER_WIDTH ),
    .C_M_AXI_ARUSER_WIDTH( C_M_AXI_GMEM_ARUSER_WIDTH ),
    .C_M_AXI_WUSER_WIDTH( C_M_AXI_GMEM_WUSER_WIDTH ),
    .C_M_AXI_RUSER_WIDTH( C_M_AXI_GMEM_RUSER_WIDTH ),
    .C_M_AXI_BUSER_WIDTH( C_M_AXI_GMEM_BUSER_WIDTH ),
    .C_USER_VALUE( C_M_AXI_GMEM_USER_VALUE ),
    .C_PROT_VALUE( C_M_AXI_GMEM_PROT_VALUE ),
    .C_CACHE_VALUE( C_M_AXI_GMEM_CACHE_VALUE ))
gmem_m_axi_U(
    .AWVALID(m_axi_gmem_AWVALID),
    .AWREADY(m_axi_gmem_AWREADY),
    .AWADDR(m_axi_gmem_AWADDR),
    .AWID(m_axi_gmem_AWID),
    .AWLEN(m_axi_gmem_AWLEN),
    .AWSIZE(m_axi_gmem_AWSIZE),
    .AWBURST(m_axi_gmem_AWBURST),
    .AWLOCK(m_axi_gmem_AWLOCK),
    .AWCACHE(m_axi_gmem_AWCACHE),
    .AWPROT(m_axi_gmem_AWPROT),
    .AWQOS(m_axi_gmem_AWQOS),
    .AWREGION(m_axi_gmem_AWREGION),
    .AWUSER(m_axi_gmem_AWUSER),
    .WVALID(m_axi_gmem_WVALID),
    .WREADY(m_axi_gmem_WREADY),
    .WDATA(m_axi_gmem_WDATA),
    .WSTRB(m_axi_gmem_WSTRB),
    .WLAST(m_axi_gmem_WLAST),
    .WID(m_axi_gmem_WID),
    .WUSER(m_axi_gmem_WUSER),
    .ARVALID(m_axi_gmem_ARVALID),
    .ARREADY(m_axi_gmem_ARREADY),
    .ARADDR(m_axi_gmem_ARADDR),
    .ARID(m_axi_gmem_ARID),
    .ARLEN(m_axi_gmem_ARLEN),
    .ARSIZE(m_axi_gmem_ARSIZE),
    .ARBURST(m_axi_gmem_ARBURST),
    .ARLOCK(m_axi_gmem_ARLOCK),
    .ARCACHE(m_axi_gmem_ARCACHE),
    .ARPROT(m_axi_gmem_ARPROT),
    .ARQOS(m_axi_gmem_ARQOS),
    .ARREGION(m_axi_gmem_ARREGION),
    .ARUSER(m_axi_gmem_ARUSER),
    .RVALID(m_axi_gmem_RVALID),
    .RREADY(m_axi_gmem_RREADY),
    .RDATA(m_axi_gmem_RDATA),
    .RLAST(m_axi_gmem_RLAST),
    .RID(m_axi_gmem_RID),
    .RUSER(m_axi_gmem_RUSER),
    .RRESP(m_axi_gmem_RRESP),
    .BVALID(m_axi_gmem_BVALID),
    .BREADY(m_axi_gmem_BREADY),
    .BRESP(m_axi_gmem_BRESP),
    .BID(m_axi_gmem_BID),
    .BUSER(m_axi_gmem_BUSER),
    .ACLK(ap_clk),
    .ARESET(ap_rst_n_inv),
    .ACLK_EN(1'b1),
    .I_ARVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARVALID),
    .I_ARREADY(gmem_ARREADY),
    .I_ARADDR(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARADDR),
    .I_ARID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARID),
    .I_ARLEN(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLEN),
    .I_ARSIZE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARSIZE),
    .I_ARLOCK(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLOCK),
    .I_ARCACHE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARCACHE),
    .I_ARQOS(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARQOS),
    .I_ARPROT(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARPROT),
    .I_ARUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARUSER),
    .I_ARBURST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARBURST),
    .I_ARREGION(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARREGION),
    .I_RVALID(gmem_RVALID),
    .I_RREADY(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_RREADY),
    .I_RDATA(gmem_RDATA),
    .I_RID(gmem_RID),
    .I_RUSER(gmem_RUSER),
    .I_RRESP(gmem_RRESP),
    .I_RLAST(gmem_RLAST),
    .I_AWVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWVALID),
    .I_AWREADY(gmem_AWREADY),
    .I_AWADDR(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWADDR),
    .I_AWID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWID),
    .I_AWLEN(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLEN),
    .I_AWSIZE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWSIZE),
    .I_AWLOCK(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLOCK),
    .I_AWCACHE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWCACHE),
    .I_AWQOS(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWQOS),
    .I_AWPROT(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWPROT),
    .I_AWUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWUSER),
    .I_AWBURST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWBURST),
    .I_AWREGION(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWREGION),
    .I_WVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WVALID),
    .I_WREADY(gmem_WREADY),
    .I_WDATA(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WDATA),
    .I_WID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WID),
    .I_WUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WUSER),
    .I_WLAST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WLAST),
    .I_WSTRB(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WSTRB),
    .I_BVALID(gmem_BVALID),
    .I_BREADY(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_BREADY),
    .I_BRESP(gmem_BRESP),
    .I_BID(gmem_BID),
    .I_BUSER(gmem_BUSER)
);

optical_flow_dataflow_in_loop_VITIS_LOOP_536_1 dataflow_in_loop_VITIS_LOOP_536_1_U0(
    .m_axi_gmem_AWVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWVALID),
    .m_axi_gmem_AWREADY(gmem_AWREADY),
    .m_axi_gmem_AWADDR(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWADDR),
    .m_axi_gmem_AWID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWID),
    .m_axi_gmem_AWLEN(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLEN),
    .m_axi_gmem_AWSIZE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWSIZE),
    .m_axi_gmem_AWBURST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWBURST),
    .m_axi_gmem_AWLOCK(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWLOCK),
    .m_axi_gmem_AWCACHE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWCACHE),
    .m_axi_gmem_AWPROT(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWPROT),
    .m_axi_gmem_AWQOS(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWQOS),
    .m_axi_gmem_AWREGION(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWREGION),
    .m_axi_gmem_AWUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_AWUSER),
    .m_axi_gmem_WVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WVALID),
    .m_axi_gmem_WREADY(gmem_WREADY),
    .m_axi_gmem_WDATA(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WDATA),
    .m_axi_gmem_WSTRB(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WSTRB),
    .m_axi_gmem_WLAST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WLAST),
    .m_axi_gmem_WID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WID),
    .m_axi_gmem_WUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_WUSER),
    .m_axi_gmem_ARVALID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARVALID),
    .m_axi_gmem_ARREADY(gmem_ARREADY),
    .m_axi_gmem_ARADDR(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARADDR),
    .m_axi_gmem_ARID(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARID),
    .m_axi_gmem_ARLEN(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLEN),
    .m_axi_gmem_ARSIZE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARSIZE),
    .m_axi_gmem_ARBURST(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARBURST),
    .m_axi_gmem_ARLOCK(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARLOCK),
    .m_axi_gmem_ARCACHE(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARCACHE),
    .m_axi_gmem_ARPROT(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARPROT),
    .m_axi_gmem_ARQOS(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARQOS),
    .m_axi_gmem_ARREGION(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARREGION),
    .m_axi_gmem_ARUSER(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_ARUSER),
    .m_axi_gmem_RVALID(gmem_RVALID),
    .m_axi_gmem_RREADY(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_RREADY),
    .m_axi_gmem_RDATA(gmem_RDATA),
    .m_axi_gmem_RLAST(gmem_RLAST),
    .m_axi_gmem_RID(gmem_RID),
    .m_axi_gmem_RUSER(gmem_RUSER),
    .m_axi_gmem_RRESP(gmem_RRESP),
    .m_axi_gmem_BVALID(gmem_BVALID),
    .m_axi_gmem_BREADY(dataflow_in_loop_VITIS_LOOP_536_1_U0_m_axi_gmem_BREADY),
    .m_axi_gmem_BRESP(gmem_BRESP),
    .m_axi_gmem_BID(gmem_BID),
    .m_axi_gmem_BUSER(gmem_BUSER),
    .i(loop_dataflow_input_count),
    .frames(frames),
    .outputs(outputs),
    .ap_clk(ap_clk),
    .ap_rst(ap_rst_n_inv),
    .i_ap_vld(1'b0),
    .frames_ap_vld(1'b1),
    .outputs_ap_vld(1'b1),
    .ap_start(dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_start),
    .ap_done(dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done),
    .ap_ready(dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready),
    .ap_idle(dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_idle),
    .ap_continue(dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_continue)
);

always @ (posedge ap_clk) begin
    ap_rst_n_inv <= ap_rst_reg_1;
end

always @ (posedge ap_clk) begin
    ap_rst_reg_1 <= ap_rst_reg_2;
end

always @ (posedge ap_clk) begin
    ap_rst_reg_2 <= ~ap_rst_n;
end

always @ (posedge ap_clk) begin
    if ((~(loop_dataflow_input_count == bound_minus_1) & (ap_start == 1'b1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready == 1'b1))) begin
        loop_dataflow_input_count <= (loop_dataflow_input_count + 64'd1);
    end else if (((ap_start == 1'b1) & (loop_dataflow_input_count == bound_minus_1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready == 1'b1))) begin
        loop_dataflow_input_count <= 64'd0;
    end
end

always @ (posedge ap_clk) begin
    if ((~(loop_dataflow_output_count == bound_minus_1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_continue == 1'b1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done == 1'b1))) begin
        loop_dataflow_output_count <= (loop_dataflow_output_count + 64'd1);
    end else if (((loop_dataflow_output_count == bound_minus_1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_continue == 1'b1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done == 1'b1))) begin
        loop_dataflow_output_count <= 64'd0;
    end
end

always @ (*) begin
    if (((loop_dataflow_output_count == bound_minus_1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done == 1'b1))) begin
        ap_done = 1'b1;
    end else begin
        ap_done = 1'b0;
    end
end

always @ (*) begin
    if (((ap_start == 1'b0) & (loop_dataflow_output_count == 64'd0) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_idle == 1'b1))) begin
        ap_idle = 1'b1;
    end else begin
        ap_idle = 1'b0;
    end
end

always @ (*) begin
    if (((ap_start == 1'b1) & (loop_dataflow_input_count == bound_minus_1) & (dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready == 1'b1))) begin
        ap_ready = 1'b1;
    end else begin
        ap_ready = 1'b0;
    end
end

assign dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_continue = 1'b1;

assign ap_sync_continue = 1'b1;

assign ap_sync_done = dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_done;

assign ap_sync_ready = dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_ready;

assign bound_minus_1 = (n - 64'd1);

assign dataflow_in_loop_VITIS_LOOP_536_1_U0_ap_start = ap_start;

assign dataflow_in_loop_VITIS_LOOP_536_1_U0_start_full_n = 1'b1;

assign dataflow_in_loop_VITIS_LOOP_536_1_U0_start_write = 1'b0;

endmodule //optical_flow