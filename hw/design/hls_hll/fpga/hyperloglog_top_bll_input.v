// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Version: 2020.2
// Copyright (C) Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module hyperloglog_top_bll_input (
        ap_clk,
        ap_rst,
        ap_start,
        start_full_n,
        ap_done,
        ap_continue,
        ap_idle,
        ap_ready,
        start_out,
        start_write,
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
        m_axi_gmem_BUSER,
        s_axis_input_tuple_din,
        s_axis_input_tuple_full_n,
        s_axis_input_tuple_write,
        input_s,
        N_s,
        N_out_din,
        N_out_full_n,
        N_out_write
);

parameter    ap_ST_fsm_state1 = 73'd1;
parameter    ap_ST_fsm_state2 = 73'd2;
parameter    ap_ST_fsm_state3 = 73'd4;
parameter    ap_ST_fsm_state4 = 73'd8;
parameter    ap_ST_fsm_state5 = 73'd16;
parameter    ap_ST_fsm_state6 = 73'd32;
parameter    ap_ST_fsm_state7 = 73'd64;
parameter    ap_ST_fsm_state8 = 73'd128;
parameter    ap_ST_fsm_state9 = 73'd256;
parameter    ap_ST_fsm_state10 = 73'd512;
parameter    ap_ST_fsm_state11 = 73'd1024;
parameter    ap_ST_fsm_state12 = 73'd2048;
parameter    ap_ST_fsm_state13 = 73'd4096;
parameter    ap_ST_fsm_state14 = 73'd8192;
parameter    ap_ST_fsm_state15 = 73'd16384;
parameter    ap_ST_fsm_state16 = 73'd32768;
parameter    ap_ST_fsm_state17 = 73'd65536;
parameter    ap_ST_fsm_state18 = 73'd131072;
parameter    ap_ST_fsm_state19 = 73'd262144;
parameter    ap_ST_fsm_state20 = 73'd524288;
parameter    ap_ST_fsm_state21 = 73'd1048576;
parameter    ap_ST_fsm_state22 = 73'd2097152;
parameter    ap_ST_fsm_state23 = 73'd4194304;
parameter    ap_ST_fsm_state24 = 73'd8388608;
parameter    ap_ST_fsm_state25 = 73'd16777216;
parameter    ap_ST_fsm_state26 = 73'd33554432;
parameter    ap_ST_fsm_state27 = 73'd67108864;
parameter    ap_ST_fsm_state28 = 73'd134217728;
parameter    ap_ST_fsm_state29 = 73'd268435456;
parameter    ap_ST_fsm_state30 = 73'd536870912;
parameter    ap_ST_fsm_state31 = 73'd1073741824;
parameter    ap_ST_fsm_state32 = 73'd2147483648;
parameter    ap_ST_fsm_state33 = 73'd4294967296;
parameter    ap_ST_fsm_state34 = 73'd8589934592;
parameter    ap_ST_fsm_state35 = 73'd17179869184;
parameter    ap_ST_fsm_state36 = 73'd34359738368;
parameter    ap_ST_fsm_state37 = 73'd68719476736;
parameter    ap_ST_fsm_state38 = 73'd137438953472;
parameter    ap_ST_fsm_state39 = 73'd274877906944;
parameter    ap_ST_fsm_state40 = 73'd549755813888;
parameter    ap_ST_fsm_state41 = 73'd1099511627776;
parameter    ap_ST_fsm_state42 = 73'd2199023255552;
parameter    ap_ST_fsm_state43 = 73'd4398046511104;
parameter    ap_ST_fsm_state44 = 73'd8796093022208;
parameter    ap_ST_fsm_state45 = 73'd17592186044416;
parameter    ap_ST_fsm_state46 = 73'd35184372088832;
parameter    ap_ST_fsm_state47 = 73'd70368744177664;
parameter    ap_ST_fsm_state48 = 73'd140737488355328;
parameter    ap_ST_fsm_state49 = 73'd281474976710656;
parameter    ap_ST_fsm_state50 = 73'd562949953421312;
parameter    ap_ST_fsm_state51 = 73'd1125899906842624;
parameter    ap_ST_fsm_state52 = 73'd2251799813685248;
parameter    ap_ST_fsm_state53 = 73'd4503599627370496;
parameter    ap_ST_fsm_state54 = 73'd9007199254740992;
parameter    ap_ST_fsm_state55 = 73'd18014398509481984;
parameter    ap_ST_fsm_state56 = 73'd36028797018963968;
parameter    ap_ST_fsm_state57 = 73'd72057594037927936;
parameter    ap_ST_fsm_state58 = 73'd144115188075855872;
parameter    ap_ST_fsm_state59 = 73'd288230376151711744;
parameter    ap_ST_fsm_state60 = 73'd576460752303423488;
parameter    ap_ST_fsm_state61 = 73'd1152921504606846976;
parameter    ap_ST_fsm_state62 = 73'd2305843009213693952;
parameter    ap_ST_fsm_state63 = 73'd4611686018427387904;
parameter    ap_ST_fsm_state64 = 73'd9223372036854775808;
parameter    ap_ST_fsm_state65 = 73'd18446744073709551616;
parameter    ap_ST_fsm_state66 = 73'd36893488147419103232;
parameter    ap_ST_fsm_state67 = 73'd73786976294838206464;
parameter    ap_ST_fsm_state68 = 73'd147573952589676412928;
parameter    ap_ST_fsm_state69 = 73'd295147905179352825856;
parameter    ap_ST_fsm_state70 = 73'd590295810358705651712;
parameter    ap_ST_fsm_state71 = 73'd1180591620717411303424;
parameter    ap_ST_fsm_pp0_stage0 = 73'd2361183241434822606848;
parameter    ap_ST_fsm_state75 = 73'd4722366482869645213696;

input   ap_clk;
input   ap_rst;
input   ap_start;
input   start_full_n;
output   ap_done;
input   ap_continue;
output   ap_idle;
output   ap_ready;
output   start_out;
output   start_write;
output   m_axi_gmem_AWVALID;
input   m_axi_gmem_AWREADY;
output  [63:0] m_axi_gmem_AWADDR;
output  [0:0] m_axi_gmem_AWID;
output  [31:0] m_axi_gmem_AWLEN;
output  [2:0] m_axi_gmem_AWSIZE;
output  [1:0] m_axi_gmem_AWBURST;
output  [1:0] m_axi_gmem_AWLOCK;
output  [3:0] m_axi_gmem_AWCACHE;
output  [2:0] m_axi_gmem_AWPROT;
output  [3:0] m_axi_gmem_AWQOS;
output  [3:0] m_axi_gmem_AWREGION;
output  [0:0] m_axi_gmem_AWUSER;
output   m_axi_gmem_WVALID;
input   m_axi_gmem_WREADY;
output  [511:0] m_axi_gmem_WDATA;
output  [63:0] m_axi_gmem_WSTRB;
output   m_axi_gmem_WLAST;
output  [0:0] m_axi_gmem_WID;
output  [0:0] m_axi_gmem_WUSER;
output   m_axi_gmem_ARVALID;
input   m_axi_gmem_ARREADY;
output  [63:0] m_axi_gmem_ARADDR;
output  [0:0] m_axi_gmem_ARID;
output  [31:0] m_axi_gmem_ARLEN;
output  [2:0] m_axi_gmem_ARSIZE;
output  [1:0] m_axi_gmem_ARBURST;
output  [1:0] m_axi_gmem_ARLOCK;
output  [3:0] m_axi_gmem_ARCACHE;
output  [2:0] m_axi_gmem_ARPROT;
output  [3:0] m_axi_gmem_ARQOS;
output  [3:0] m_axi_gmem_ARREGION;
output  [0:0] m_axi_gmem_ARUSER;
input   m_axi_gmem_RVALID;
output   m_axi_gmem_RREADY;
input  [511:0] m_axi_gmem_RDATA;
input   m_axi_gmem_RLAST;
input  [0:0] m_axi_gmem_RID;
input  [0:0] m_axi_gmem_RUSER;
input  [1:0] m_axi_gmem_RRESP;
input   m_axi_gmem_BVALID;
output   m_axi_gmem_BREADY;
input  [1:0] m_axi_gmem_BRESP;
input  [0:0] m_axi_gmem_BID;
input  [0:0] m_axi_gmem_BUSER;
output  [1023:0] s_axis_input_tuple_din;
input   s_axis_input_tuple_full_n;
output   s_axis_input_tuple_write;
input  [63:0] input_s;
input  [63:0] N_s;
output  [63:0] N_out_din;
input   N_out_full_n;
output   N_out_write;

reg ap_done;
reg ap_idle;
reg start_write;
reg m_axi_gmem_ARVALID;
reg m_axi_gmem_RREADY;
reg s_axis_input_tuple_write;
reg N_out_write;

reg    real_start;
reg    start_once_reg;
reg    ap_done_reg;
(* fsm_encoding = "none" *) reg   [72:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
reg    internal_ap_ready;
reg    gmem_blk_n_AR;
wire    ap_CS_fsm_state2;
reg   [0:0] icmp_ln5_reg_199;
reg    gmem_blk_n_R;
wire    ap_CS_fsm_pp0_stage0;
reg    ap_enable_reg_pp0_iter1;
wire    ap_block_pp0_stage0;
reg   [0:0] icmp_ln5_1_reg_224;
reg    s_axis_input_tuple_blk_n;
reg    ap_enable_reg_pp0_iter2;
reg   [0:0] icmp_ln5_1_reg_224_pp0_iter1_reg;
reg    N_out_blk_n;
reg   [63:0] i_reg_110;
wire   [0:0] icmp_ln5_fu_121_p2;
wire   [63:0] sub_i_fu_127_p2;
reg   [63:0] sub_i_reg_203;
wire   [63:0] i_50_fu_157_p2;
reg    ap_enable_reg_pp0_iter0;
wire    ap_block_state72_pp0_stage0_iter0;
reg    ap_block_state73_pp0_stage0_iter1;
reg    ap_block_state74_pp0_stage0_iter2;
reg    ap_block_pp0_stage0_11001;
wire   [0:0] icmp_ln5_1_fu_163_p2;
wire   [0:0] data_in_last_V_fu_168_p2;
reg   [0:0] data_in_last_V_reg_228;
reg   [0:0] data_in_last_V_reg_228_pp0_iter1_reg;
reg   [511:0] data_sent_V_reg_233;
wire    ap_CS_fsm_state71;
reg    ap_block_pp0_stage0_subdone;
reg    ap_condition_pp0_exit_iter0_state72;
wire  signed [63:0] sext_ln5_fu_142_p1;
reg    ap_block_state2_io;
reg    ap_block_state1;
reg    ap_block_pp0_stage0_01001;
wire   [57:0] trunc_ln5_fu_132_p4;
wire   [576:0] tmp_i_fu_173_p4;
wire   [576:0] or_ln174_fu_181_p2;
wire    ap_CS_fsm_state75;
reg   [72:0] ap_NS_fsm;
reg    ap_idle_pp0;
wire    ap_enable_pp0;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 start_once_reg = 1'b0;
#0 ap_done_reg = 1'b0;
#0 ap_CS_fsm = 73'd1;
#0 ap_enable_reg_pp0_iter1 = 1'b0;
#0 ap_enable_reg_pp0_iter2 = 1'b0;
#0 ap_enable_reg_pp0_iter0 = 1'b0;
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_CS_fsm <= ap_ST_fsm_state1;
    end else begin
        ap_CS_fsm <= ap_NS_fsm;
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_done_reg <= 1'b0;
    end else begin
        if ((ap_continue == 1'b1)) begin
            ap_done_reg <= 1'b0;
        end else if ((1'b1 == ap_CS_fsm_state75)) begin
            ap_done_reg <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter0 <= 1'b0;
    end else begin
        if (((1'b1 == ap_condition_pp0_exit_iter0_state72) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_subdone))) begin
            ap_enable_reg_pp0_iter0 <= 1'b0;
        end else if ((1'b1 == ap_CS_fsm_state71)) begin
            ap_enable_reg_pp0_iter0 <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter1 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            if ((1'b1 == ap_condition_pp0_exit_iter0_state72)) begin
                ap_enable_reg_pp0_iter1 <= (1'b1 ^ ap_condition_pp0_exit_iter0_state72);
            end else if ((1'b1 == 1'b1)) begin
                ap_enable_reg_pp0_iter1 <= ap_enable_reg_pp0_iter0;
            end
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter2 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter2 <= ap_enable_reg_pp0_iter1;
        end else if ((1'b1 == ap_CS_fsm_state71)) begin
            ap_enable_reg_pp0_iter2 <= 1'b0;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        start_once_reg <= 1'b0;
    end else begin
        if (((real_start == 1'b1) & (internal_ap_ready == 1'b0))) begin
            start_once_reg <= 1'b1;
        end else if ((internal_ap_ready == 1'b1)) begin
            start_once_reg <= 1'b0;
        end
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln5_1_fu_163_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        i_reg_110 <= i_50_fu_157_p2;
    end else if ((1'b1 == ap_CS_fsm_state71)) begin
        i_reg_110 <= 64'd0;
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln5_1_fu_163_p2 == 1'd0) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        data_in_last_V_reg_228 <= data_in_last_V_fu_168_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        data_in_last_V_reg_228_pp0_iter1_reg <= data_in_last_V_reg_228;
        icmp_ln5_1_reg_224 <= icmp_ln5_1_fu_163_p2;
        icmp_ln5_1_reg_224_pp0_iter1_reg <= icmp_ln5_1_reg_224;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (icmp_ln5_1_reg_224 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        data_sent_V_reg_233 <= m_axi_gmem_RDATA;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state1)) begin
        icmp_ln5_reg_199 <= icmp_ln5_fu_121_p2;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state2)) begin
        sub_i_reg_203 <= sub_i_fu_127_p2;
    end
end

always @ (*) begin
    if ((~((ap_done_reg == 1'b1) | (real_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_out_blk_n = N_out_full_n;
    end else begin
        N_out_blk_n = 1'b1;
    end
end

always @ (*) begin
    if ((~((ap_done_reg == 1'b1) | (real_start == 1'b0) | (1'b0 == N_out_full_n)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_out_write = 1'b1;
    end else begin
        N_out_write = 1'b0;
    end
end

always @ (*) begin
    if ((icmp_ln5_1_fu_163_p2 == 1'd1)) begin
        ap_condition_pp0_exit_iter0_state72 = 1'b1;
    end else begin
        ap_condition_pp0_exit_iter0_state72 = 1'b0;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state75)) begin
        ap_done = 1'b1;
    end else begin
        ap_done = ap_done_reg;
    end
end

always @ (*) begin
    if (((real_start == 1'b0) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_idle = 1'b1;
    end else begin
        ap_idle = 1'b0;
    end
end

always @ (*) begin
    if (((ap_enable_reg_pp0_iter0 == 1'b0) & (ap_enable_reg_pp0_iter2 == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b0))) begin
        ap_idle_pp0 = 1'b1;
    end else begin
        ap_idle_pp0 = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state2) & (icmp_ln5_reg_199 == 1'd0))) begin
        gmem_blk_n_AR = m_axi_gmem_ARREADY;
    end else begin
        gmem_blk_n_AR = 1'b1;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (icmp_ln5_1_reg_224 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1))) begin
        gmem_blk_n_R = m_axi_gmem_RVALID;
    end else begin
        gmem_blk_n_R = 1'b1;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state75)) begin
        internal_ap_ready = 1'b1;
    end else begin
        internal_ap_ready = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state2) & (1'b0 == ap_block_state2_io) & (icmp_ln5_reg_199 == 1'd0))) begin
        m_axi_gmem_ARVALID = 1'b1;
    end else begin
        m_axi_gmem_ARVALID = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (icmp_ln5_1_reg_224 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1))) begin
        m_axi_gmem_RREADY = 1'b1;
    end else begin
        m_axi_gmem_RREADY = 1'b0;
    end
end

always @ (*) begin
    if (((start_once_reg == 1'b0) & (start_full_n == 1'b0))) begin
        real_start = 1'b0;
    end else begin
        real_start = ap_start;
    end
end

always @ (*) begin
    if (((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0))) begin
        s_axis_input_tuple_blk_n = s_axis_input_tuple_full_n;
    end else begin
        s_axis_input_tuple_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        s_axis_input_tuple_write = 1'b1;
    end else begin
        s_axis_input_tuple_write = 1'b0;
    end
end

always @ (*) begin
    if (((start_once_reg == 1'b0) & (real_start == 1'b1))) begin
        start_write = 1'b1;
    end else begin
        start_write = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            if ((~((ap_done_reg == 1'b1) | (real_start == 1'b0) | (1'b0 == N_out_full_n)) & (1'b1 == ap_CS_fsm_state1))) begin
                ap_NS_fsm = ap_ST_fsm_state2;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end
        end
        ap_ST_fsm_state2 : begin
            if (((1'b1 == ap_CS_fsm_state2) & (1'b0 == ap_block_state2_io) & (icmp_ln5_reg_199 == 1'd1))) begin
                ap_NS_fsm = ap_ST_fsm_state75;
            end else if (((1'b1 == ap_CS_fsm_state2) & (1'b0 == ap_block_state2_io) & (icmp_ln5_reg_199 == 1'd0))) begin
                ap_NS_fsm = ap_ST_fsm_state3;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state2;
            end
        end
        ap_ST_fsm_state3 : begin
            ap_NS_fsm = ap_ST_fsm_state4;
        end
        ap_ST_fsm_state4 : begin
            ap_NS_fsm = ap_ST_fsm_state5;
        end
        ap_ST_fsm_state5 : begin
            ap_NS_fsm = ap_ST_fsm_state6;
        end
        ap_ST_fsm_state6 : begin
            ap_NS_fsm = ap_ST_fsm_state7;
        end
        ap_ST_fsm_state7 : begin
            ap_NS_fsm = ap_ST_fsm_state8;
        end
        ap_ST_fsm_state8 : begin
            ap_NS_fsm = ap_ST_fsm_state9;
        end
        ap_ST_fsm_state9 : begin
            ap_NS_fsm = ap_ST_fsm_state10;
        end
        ap_ST_fsm_state10 : begin
            ap_NS_fsm = ap_ST_fsm_state11;
        end
        ap_ST_fsm_state11 : begin
            ap_NS_fsm = ap_ST_fsm_state12;
        end
        ap_ST_fsm_state12 : begin
            ap_NS_fsm = ap_ST_fsm_state13;
        end
        ap_ST_fsm_state13 : begin
            ap_NS_fsm = ap_ST_fsm_state14;
        end
        ap_ST_fsm_state14 : begin
            ap_NS_fsm = ap_ST_fsm_state15;
        end
        ap_ST_fsm_state15 : begin
            ap_NS_fsm = ap_ST_fsm_state16;
        end
        ap_ST_fsm_state16 : begin
            ap_NS_fsm = ap_ST_fsm_state17;
        end
        ap_ST_fsm_state17 : begin
            ap_NS_fsm = ap_ST_fsm_state18;
        end
        ap_ST_fsm_state18 : begin
            ap_NS_fsm = ap_ST_fsm_state19;
        end
        ap_ST_fsm_state19 : begin
            ap_NS_fsm = ap_ST_fsm_state20;
        end
        ap_ST_fsm_state20 : begin
            ap_NS_fsm = ap_ST_fsm_state21;
        end
        ap_ST_fsm_state21 : begin
            ap_NS_fsm = ap_ST_fsm_state22;
        end
        ap_ST_fsm_state22 : begin
            ap_NS_fsm = ap_ST_fsm_state23;
        end
        ap_ST_fsm_state23 : begin
            ap_NS_fsm = ap_ST_fsm_state24;
        end
        ap_ST_fsm_state24 : begin
            ap_NS_fsm = ap_ST_fsm_state25;
        end
        ap_ST_fsm_state25 : begin
            ap_NS_fsm = ap_ST_fsm_state26;
        end
        ap_ST_fsm_state26 : begin
            ap_NS_fsm = ap_ST_fsm_state27;
        end
        ap_ST_fsm_state27 : begin
            ap_NS_fsm = ap_ST_fsm_state28;
        end
        ap_ST_fsm_state28 : begin
            ap_NS_fsm = ap_ST_fsm_state29;
        end
        ap_ST_fsm_state29 : begin
            ap_NS_fsm = ap_ST_fsm_state30;
        end
        ap_ST_fsm_state30 : begin
            ap_NS_fsm = ap_ST_fsm_state31;
        end
        ap_ST_fsm_state31 : begin
            ap_NS_fsm = ap_ST_fsm_state32;
        end
        ap_ST_fsm_state32 : begin
            ap_NS_fsm = ap_ST_fsm_state33;
        end
        ap_ST_fsm_state33 : begin
            ap_NS_fsm = ap_ST_fsm_state34;
        end
        ap_ST_fsm_state34 : begin
            ap_NS_fsm = ap_ST_fsm_state35;
        end
        ap_ST_fsm_state35 : begin
            ap_NS_fsm = ap_ST_fsm_state36;
        end
        ap_ST_fsm_state36 : begin
            ap_NS_fsm = ap_ST_fsm_state37;
        end
        ap_ST_fsm_state37 : begin
            ap_NS_fsm = ap_ST_fsm_state38;
        end
        ap_ST_fsm_state38 : begin
            ap_NS_fsm = ap_ST_fsm_state39;
        end
        ap_ST_fsm_state39 : begin
            ap_NS_fsm = ap_ST_fsm_state40;
        end
        ap_ST_fsm_state40 : begin
            ap_NS_fsm = ap_ST_fsm_state41;
        end
        ap_ST_fsm_state41 : begin
            ap_NS_fsm = ap_ST_fsm_state42;
        end
        ap_ST_fsm_state42 : begin
            ap_NS_fsm = ap_ST_fsm_state43;
        end
        ap_ST_fsm_state43 : begin
            ap_NS_fsm = ap_ST_fsm_state44;
        end
        ap_ST_fsm_state44 : begin
            ap_NS_fsm = ap_ST_fsm_state45;
        end
        ap_ST_fsm_state45 : begin
            ap_NS_fsm = ap_ST_fsm_state46;
        end
        ap_ST_fsm_state46 : begin
            ap_NS_fsm = ap_ST_fsm_state47;
        end
        ap_ST_fsm_state47 : begin
            ap_NS_fsm = ap_ST_fsm_state48;
        end
        ap_ST_fsm_state48 : begin
            ap_NS_fsm = ap_ST_fsm_state49;
        end
        ap_ST_fsm_state49 : begin
            ap_NS_fsm = ap_ST_fsm_state50;
        end
        ap_ST_fsm_state50 : begin
            ap_NS_fsm = ap_ST_fsm_state51;
        end
        ap_ST_fsm_state51 : begin
            ap_NS_fsm = ap_ST_fsm_state52;
        end
        ap_ST_fsm_state52 : begin
            ap_NS_fsm = ap_ST_fsm_state53;
        end
        ap_ST_fsm_state53 : begin
            ap_NS_fsm = ap_ST_fsm_state54;
        end
        ap_ST_fsm_state54 : begin
            ap_NS_fsm = ap_ST_fsm_state55;
        end
        ap_ST_fsm_state55 : begin
            ap_NS_fsm = ap_ST_fsm_state56;
        end
        ap_ST_fsm_state56 : begin
            ap_NS_fsm = ap_ST_fsm_state57;
        end
        ap_ST_fsm_state57 : begin
            ap_NS_fsm = ap_ST_fsm_state58;
        end
        ap_ST_fsm_state58 : begin
            ap_NS_fsm = ap_ST_fsm_state59;
        end
        ap_ST_fsm_state59 : begin
            ap_NS_fsm = ap_ST_fsm_state60;
        end
        ap_ST_fsm_state60 : begin
            ap_NS_fsm = ap_ST_fsm_state61;
        end
        ap_ST_fsm_state61 : begin
            ap_NS_fsm = ap_ST_fsm_state62;
        end
        ap_ST_fsm_state62 : begin
            ap_NS_fsm = ap_ST_fsm_state63;
        end
        ap_ST_fsm_state63 : begin
            ap_NS_fsm = ap_ST_fsm_state64;
        end
        ap_ST_fsm_state64 : begin
            ap_NS_fsm = ap_ST_fsm_state65;
        end
        ap_ST_fsm_state65 : begin
            ap_NS_fsm = ap_ST_fsm_state66;
        end
        ap_ST_fsm_state66 : begin
            ap_NS_fsm = ap_ST_fsm_state67;
        end
        ap_ST_fsm_state67 : begin
            ap_NS_fsm = ap_ST_fsm_state68;
        end
        ap_ST_fsm_state68 : begin
            ap_NS_fsm = ap_ST_fsm_state69;
        end
        ap_ST_fsm_state69 : begin
            ap_NS_fsm = ap_ST_fsm_state70;
        end
        ap_ST_fsm_state70 : begin
            ap_NS_fsm = ap_ST_fsm_state71;
        end
        ap_ST_fsm_state71 : begin
            ap_NS_fsm = ap_ST_fsm_pp0_stage0;
        end
        ap_ST_fsm_pp0_stage0 : begin
            if ((~((icmp_ln5_1_fu_163_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) & ~((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else if ((((icmp_ln5_1_fu_163_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) | ((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_state75;
            end else begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end
        end
        ap_ST_fsm_state75 : begin
            ap_NS_fsm = ap_ST_fsm_state1;
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign N_out_din = N_s;

assign ap_CS_fsm_pp0_stage0 = ap_CS_fsm[32'd71];

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

assign ap_CS_fsm_state2 = ap_CS_fsm[32'd1];

assign ap_CS_fsm_state71 = ap_CS_fsm[32'd70];

assign ap_CS_fsm_state75 = ap_CS_fsm[32'd72];

assign ap_block_pp0_stage0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_pp0_stage0_01001 = (((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (ap_enable_reg_pp0_iter2 == 1'b1) & (s_axis_input_tuple_full_n == 1'b0)) | ((icmp_ln5_1_reg_224 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (m_axi_gmem_RVALID == 1'b0)));
end

always @ (*) begin
    ap_block_pp0_stage0_11001 = (((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (ap_enable_reg_pp0_iter2 == 1'b1) & (s_axis_input_tuple_full_n == 1'b0)) | ((icmp_ln5_1_reg_224 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (m_axi_gmem_RVALID == 1'b0)));
end

always @ (*) begin
    ap_block_pp0_stage0_subdone = (((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (ap_enable_reg_pp0_iter2 == 1'b1) & (s_axis_input_tuple_full_n == 1'b0)) | ((icmp_ln5_1_reg_224 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (m_axi_gmem_RVALID == 1'b0)));
end

always @ (*) begin
    ap_block_state1 = ((ap_done_reg == 1'b1) | (real_start == 1'b0) | (1'b0 == N_out_full_n));
end

always @ (*) begin
    ap_block_state2_io = ((icmp_ln5_reg_199 == 1'd0) & (m_axi_gmem_ARREADY == 1'b0));
end

assign ap_block_state72_pp0_stage0_iter0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state73_pp0_stage0_iter1 = ((icmp_ln5_1_reg_224 == 1'd0) & (m_axi_gmem_RVALID == 1'b0));
end

always @ (*) begin
    ap_block_state74_pp0_stage0_iter2 = ((icmp_ln5_1_reg_224_pp0_iter1_reg == 1'd0) & (s_axis_input_tuple_full_n == 1'b0));
end

assign ap_enable_pp0 = (ap_idle_pp0 ^ 1'b1);

assign ap_ready = internal_ap_ready;

assign data_in_last_V_fu_168_p2 = ((i_reg_110 == sub_i_reg_203) ? 1'b1 : 1'b0);

assign i_50_fu_157_p2 = (i_reg_110 + 64'd1);

assign icmp_ln5_1_fu_163_p2 = ((i_reg_110 == N_s) ? 1'b1 : 1'b0);

assign icmp_ln5_fu_121_p2 = ((N_s == 64'd0) ? 1'b1 : 1'b0);

assign m_axi_gmem_ARADDR = sext_ln5_fu_142_p1;

assign m_axi_gmem_ARBURST = 2'd0;

assign m_axi_gmem_ARCACHE = 4'd0;

assign m_axi_gmem_ARID = 1'd0;

assign m_axi_gmem_ARLEN = N_s[31:0];

assign m_axi_gmem_ARLOCK = 2'd0;

assign m_axi_gmem_ARPROT = 3'd0;

assign m_axi_gmem_ARQOS = 4'd0;

assign m_axi_gmem_ARREGION = 4'd0;

assign m_axi_gmem_ARSIZE = 3'd0;

assign m_axi_gmem_ARUSER = 1'd0;

assign m_axi_gmem_AWADDR = 64'd0;

assign m_axi_gmem_AWBURST = 2'd0;

assign m_axi_gmem_AWCACHE = 4'd0;

assign m_axi_gmem_AWID = 1'd0;

assign m_axi_gmem_AWLEN = 32'd0;

assign m_axi_gmem_AWLOCK = 2'd0;

assign m_axi_gmem_AWPROT = 3'd0;

assign m_axi_gmem_AWQOS = 4'd0;

assign m_axi_gmem_AWREGION = 4'd0;

assign m_axi_gmem_AWSIZE = 3'd0;

assign m_axi_gmem_AWUSER = 1'd0;

assign m_axi_gmem_AWVALID = 1'b0;

assign m_axi_gmem_BREADY = 1'b0;

assign m_axi_gmem_WDATA = 512'd0;

assign m_axi_gmem_WID = 1'd0;

assign m_axi_gmem_WLAST = 1'b0;

assign m_axi_gmem_WSTRB = 64'd0;

assign m_axi_gmem_WUSER = 1'd0;

assign m_axi_gmem_WVALID = 1'b0;

assign or_ln174_fu_181_p2 = (tmp_i_fu_173_p4 | 577'd247330401473104534047094713089704592935557324103005993786583690272304831728808305726594637031169498012795797127849235911661333176120265159113792272289946597970173123142615040);

assign s_axis_input_tuple_din = or_ln174_fu_181_p2;

assign sext_ln5_fu_142_p1 = $signed(trunc_ln5_fu_132_p4);

assign start_out = real_start;

assign sub_i_fu_127_p2 = ($signed(N_s) + $signed(64'd18446744073709551615));

assign tmp_i_fu_173_p4 = {{{data_in_last_V_reg_228_pp0_iter1_reg}, {64'd0}}, {data_sent_V_reg_233}};

assign trunc_ln5_fu_132_p4 = {{input_s[63:6]}};

endmodule //hyperloglog_top_bll_input
