// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Version: 2020.2
// Copyright (C) Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module hyperloglog_top_murmur3_0_s (
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
        N_dout,
        N_empty_n,
        N_read,
        N_out_din,
        N_out_full_n,
        N_out_write,
        dataFifo_V_data_V_0_dout,
        dataFifo_V_data_V_0_empty_n,
        dataFifo_V_data_V_0_read,
        dataFifo_V_valid_V_0_dout,
        dataFifo_V_valid_V_0_empty_n,
        dataFifo_V_valid_V_0_read,
        dataFifo_V_last_V_0_dout,
        dataFifo_V_last_V_0_empty_n,
        dataFifo_V_last_V_0_read,
        hashFifo_8_din,
        hashFifo_8_full_n,
        hashFifo_8_write
);

parameter    ap_ST_fsm_state1 = 3'd1;
parameter    ap_ST_fsm_pp0_stage0 = 3'd2;
parameter    ap_ST_fsm_state26 = 3'd4;

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
input  [63:0] N_dout;
input   N_empty_n;
output   N_read;
output  [63:0] N_out_din;
input   N_out_full_n;
output   N_out_write;
input  [31:0] dataFifo_V_data_V_0_dout;
input   dataFifo_V_data_V_0_empty_n;
output   dataFifo_V_data_V_0_read;
input  [0:0] dataFifo_V_valid_V_0_dout;
input   dataFifo_V_valid_V_0_empty_n;
output   dataFifo_V_valid_V_0_read;
input  [0:0] dataFifo_V_last_V_0_dout;
input   dataFifo_V_last_V_0_empty_n;
output   dataFifo_V_last_V_0_read;
output  [63:0] hashFifo_8_din;
input   hashFifo_8_full_n;
output   hashFifo_8_write;

reg ap_done;
reg ap_idle;
reg start_write;
reg N_read;
reg N_out_write;
reg dataFifo_V_data_V_0_read;
reg dataFifo_V_valid_V_0_read;
reg dataFifo_V_last_V_0_read;
reg hashFifo_8_write;

reg    real_start;
reg    start_once_reg;
reg    ap_done_reg;
(* fsm_encoding = "none" *) reg   [2:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
reg    internal_ap_ready;
reg    N_blk_n;
reg    N_out_blk_n;
reg    dataFifo_V_data_V_0_blk_n;
wire    ap_CS_fsm_pp0_stage0;
reg    ap_enable_reg_pp0_iter1;
wire    ap_block_pp0_stage0;
reg   [0:0] icmp_ln51_reg_359;
reg    dataFifo_V_valid_V_0_blk_n;
reg    dataFifo_V_last_V_0_blk_n;
reg    hashFifo_8_blk_n;
reg    ap_enable_reg_pp0_iter23;
reg   [0:0] icmp_ln51_reg_359_pp0_iter22_reg;
reg   [63:0] i_reg_127;
reg   [63:0] N_read_reg_349;
wire   [63:0] i_16_fu_138_p2;
reg    ap_enable_reg_pp0_iter0;
wire    ap_block_state2_pp0_stage0_iter0;
wire    io_acc_block_signal_op49;
reg    ap_block_state3_pp0_stage0_iter1;
wire    ap_block_state4_pp0_stage0_iter2;
wire    ap_block_state5_pp0_stage0_iter3;
wire    ap_block_state6_pp0_stage0_iter4;
wire    ap_block_state7_pp0_stage0_iter5;
wire    ap_block_state8_pp0_stage0_iter6;
wire    ap_block_state9_pp0_stage0_iter7;
wire    ap_block_state10_pp0_stage0_iter8;
wire    ap_block_state11_pp0_stage0_iter9;
wire    ap_block_state12_pp0_stage0_iter10;
wire    ap_block_state13_pp0_stage0_iter11;
wire    ap_block_state14_pp0_stage0_iter12;
wire    ap_block_state15_pp0_stage0_iter13;
wire    ap_block_state16_pp0_stage0_iter14;
wire    ap_block_state17_pp0_stage0_iter15;
wire    ap_block_state18_pp0_stage0_iter16;
wire    ap_block_state19_pp0_stage0_iter17;
wire    ap_block_state20_pp0_stage0_iter18;
wire    ap_block_state21_pp0_stage0_iter19;
wire    ap_block_state22_pp0_stage0_iter20;
wire    ap_block_state23_pp0_stage0_iter21;
wire    ap_block_state24_pp0_stage0_iter22;
reg    ap_block_state25_pp0_stage0_iter23;
reg    ap_block_pp0_stage0_11001;
wire   [0:0] icmp_ln51_fu_144_p2;
reg   [0:0] icmp_ln51_reg_359_pp0_iter1_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter2_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter3_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter4_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter5_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter6_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter7_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter8_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter9_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter10_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter11_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter12_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter13_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter14_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter15_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter16_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter17_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter18_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter19_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter20_reg;
reg   [0:0] icmp_ln51_reg_359_pp0_iter21_reg;
reg  signed [31:0] tmp_data_V_reg_363;
reg   [0:0] p_1_i_i_reg_369;
reg   [0:0] p_1_i_i_reg_369_pp0_iter2_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter3_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter4_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter5_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter6_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter7_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter8_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter9_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter10_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter11_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter12_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter13_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter14_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter15_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter16_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter17_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter18_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter19_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter20_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter21_reg;
reg   [0:0] p_1_i_i_reg_369_pp0_iter22_reg;
reg   [0:0] p_2_i_i_reg_374;
reg   [0:0] p_2_i_i_reg_374_pp0_iter2_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter3_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter4_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter5_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter6_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter7_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter8_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter9_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter10_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter11_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter12_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter13_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter14_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter15_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter16_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter17_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter18_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter19_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter20_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter21_reg;
reg   [0:0] p_2_i_i_reg_374_pp0_iter22_reg;
reg   [14:0] r_s_reg_379;
reg   [16:0] tmp_s_reg_384;
wire  signed [31:0] ret_fu_191_p3;
reg   [12:0] r_34_reg_395;
reg   [18:0] tmp_14_reg_400;
wire  signed [31:0] h1_V_108_fu_279_p2;
reg  signed [31:0] h1_V_108_reg_405;
wire  signed [31:0] h1_V_110_fu_304_p2;
reg  signed [31:0] h1_V_110_reg_410;
wire   [31:0] h1_V_112_fu_329_p2;
reg   [31:0] h1_V_112_reg_415;
reg    ap_block_state1;
reg    ap_block_pp0_stage0_subdone;
reg    ap_condition_pp0_exit_iter0_state2;
reg    ap_enable_reg_pp0_iter2;
reg    ap_enable_reg_pp0_iter3;
reg    ap_enable_reg_pp0_iter4;
reg    ap_enable_reg_pp0_iter5;
reg    ap_enable_reg_pp0_iter6;
reg    ap_enable_reg_pp0_iter7;
reg    ap_enable_reg_pp0_iter8;
reg    ap_enable_reg_pp0_iter9;
reg    ap_enable_reg_pp0_iter10;
reg    ap_enable_reg_pp0_iter11;
reg    ap_enable_reg_pp0_iter12;
reg    ap_enable_reg_pp0_iter13;
reg    ap_enable_reg_pp0_iter14;
reg    ap_enable_reg_pp0_iter15;
reg    ap_enable_reg_pp0_iter16;
reg    ap_enable_reg_pp0_iter17;
reg    ap_enable_reg_pp0_iter18;
reg    ap_enable_reg_pp0_iter19;
reg    ap_enable_reg_pp0_iter20;
reg    ap_enable_reg_pp0_iter21;
reg    ap_enable_reg_pp0_iter22;
reg    ap_block_pp0_stage0_01001;
wire  signed [30:0] grp_fu_161_p1;
wire   [29:0] grp_fu_166_p1;
wire   [31:0] grp_fu_161_p2;
wire   [31:0] grp_fu_166_p2;
wire   [29:0] grp_fu_197_p1;
wire  signed [29:0] grp_fu_203_p1;
wire   [31:0] grp_fu_197_p2;
wire   [31:0] grp_fu_203_p2;
wire   [31:0] or_ln_fu_229_p3;
wire   [31:0] ret_16_fu_235_p2;
wire   [31:0] add_ln213_fu_247_p2;
wire   [31:0] shl_ln213_fu_241_p2;
wire   [31:0] h1_V_106_fu_253_p2;
wire   [31:0] h1_V_107_fu_259_p2;
wire   [15:0] r_fu_265_p4;
wire   [31:0] zext_ln1497_fu_275_p1;
wire   [31:0] grp_fu_285_p2;
wire   [18:0] r_35_fu_290_p4;
wire   [31:0] zext_ln1497_31_fu_300_p1;
wire  signed [30:0] grp_fu_310_p1;
wire   [31:0] grp_fu_310_p2;
wire   [15:0] r_36_fu_315_p4;
wire   [31:0] zext_ln1497_32_fu_325_p1;
wire   [40:0] tmp_fu_335_p5;
reg    grp_fu_161_ce;
reg    grp_fu_166_ce;
reg    grp_fu_197_ce;
reg    grp_fu_203_ce;
reg    grp_fu_285_ce;
reg    grp_fu_310_ce;
wire    ap_CS_fsm_state26;
reg   [2:0] ap_NS_fsm;
reg    ap_idle_pp0;
wire    ap_enable_pp0;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 start_once_reg = 1'b0;
#0 ap_done_reg = 1'b0;
#0 ap_CS_fsm = 3'd1;
#0 ap_enable_reg_pp0_iter1 = 1'b0;
#0 ap_enable_reg_pp0_iter23 = 1'b0;
#0 ap_enable_reg_pp0_iter0 = 1'b0;
#0 ap_enable_reg_pp0_iter2 = 1'b0;
#0 ap_enable_reg_pp0_iter3 = 1'b0;
#0 ap_enable_reg_pp0_iter4 = 1'b0;
#0 ap_enable_reg_pp0_iter5 = 1'b0;
#0 ap_enable_reg_pp0_iter6 = 1'b0;
#0 ap_enable_reg_pp0_iter7 = 1'b0;
#0 ap_enable_reg_pp0_iter8 = 1'b0;
#0 ap_enable_reg_pp0_iter9 = 1'b0;
#0 ap_enable_reg_pp0_iter10 = 1'b0;
#0 ap_enable_reg_pp0_iter11 = 1'b0;
#0 ap_enable_reg_pp0_iter12 = 1'b0;
#0 ap_enable_reg_pp0_iter13 = 1'b0;
#0 ap_enable_reg_pp0_iter14 = 1'b0;
#0 ap_enable_reg_pp0_iter15 = 1'b0;
#0 ap_enable_reg_pp0_iter16 = 1'b0;
#0 ap_enable_reg_pp0_iter17 = 1'b0;
#0 ap_enable_reg_pp0_iter18 = 1'b0;
#0 ap_enable_reg_pp0_iter19 = 1'b0;
#0 ap_enable_reg_pp0_iter20 = 1'b0;
#0 ap_enable_reg_pp0_iter21 = 1'b0;
#0 ap_enable_reg_pp0_iter22 = 1'b0;
end

hyperloglog_top_mul_32s_31s_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 31 ),
    .dout_WIDTH( 32 ))
mul_32s_31s_32_5_1_U74(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(tmp_data_V_reg_363),
    .din1(grp_fu_161_p1),
    .ce(grp_fu_161_ce),
    .dout(grp_fu_161_p2)
);

hyperloglog_top_mul_32s_30ns_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 30 ),
    .dout_WIDTH( 32 ))
mul_32s_30ns_32_5_1_U75(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(tmp_data_V_reg_363),
    .din1(grp_fu_166_p1),
    .ce(grp_fu_166_ce),
    .dout(grp_fu_166_p2)
);

hyperloglog_top_mul_32s_30ns_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 30 ),
    .dout_WIDTH( 32 ))
mul_32s_30ns_32_5_1_U76(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(ret_fu_191_p3),
    .din1(grp_fu_197_p1),
    .ce(grp_fu_197_ce),
    .dout(grp_fu_197_p2)
);

hyperloglog_top_mul_32s_30s_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 30 ),
    .dout_WIDTH( 32 ))
mul_32s_30s_32_5_1_U77(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(ret_fu_191_p3),
    .din1(grp_fu_203_p1),
    .ce(grp_fu_203_ce),
    .dout(grp_fu_203_p2)
);

hyperloglog_top_mul_32s_32s_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 32 ),
    .dout_WIDTH( 32 ))
mul_32s_32s_32_5_1_U78(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(h1_V_108_reg_405),
    .din1(32'd2246822507),
    .ce(grp_fu_285_ce),
    .dout(grp_fu_285_p2)
);

hyperloglog_top_mul_32s_31s_32_5_1 #(
    .ID( 1 ),
    .NUM_STAGE( 5 ),
    .din0_WIDTH( 32 ),
    .din1_WIDTH( 31 ),
    .dout_WIDTH( 32 ))
mul_32s_31s_32_5_1_U79(
    .clk(ap_clk),
    .reset(ap_rst),
    .din0(h1_V_110_reg_410),
    .din1(grp_fu_310_p1),
    .ce(grp_fu_310_ce),
    .dout(grp_fu_310_p2)
);

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
        end else if ((1'b1 == ap_CS_fsm_state26)) begin
            ap_done_reg <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter0 <= 1'b0;
    end else begin
        if (((1'b0 == ap_block_pp0_stage0_subdone) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b1 == ap_condition_pp0_exit_iter0_state2))) begin
            ap_enable_reg_pp0_iter0 <= 1'b0;
        end else if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter0 <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter1 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            if ((1'b1 == ap_condition_pp0_exit_iter0_state2)) begin
                ap_enable_reg_pp0_iter1 <= (1'b1 ^ ap_condition_pp0_exit_iter0_state2);
            end else if ((1'b1 == 1'b1)) begin
                ap_enable_reg_pp0_iter1 <= ap_enable_reg_pp0_iter0;
            end
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter10 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter10 <= ap_enable_reg_pp0_iter9;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter11 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter11 <= ap_enable_reg_pp0_iter10;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter12 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter12 <= ap_enable_reg_pp0_iter11;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter13 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter13 <= ap_enable_reg_pp0_iter12;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter14 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter14 <= ap_enable_reg_pp0_iter13;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter15 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter15 <= ap_enable_reg_pp0_iter14;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter16 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter16 <= ap_enable_reg_pp0_iter15;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter17 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter17 <= ap_enable_reg_pp0_iter16;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter18 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter18 <= ap_enable_reg_pp0_iter17;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter19 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter19 <= ap_enable_reg_pp0_iter18;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter2 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter2 <= ap_enable_reg_pp0_iter1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter20 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter20 <= ap_enable_reg_pp0_iter19;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter21 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter21 <= ap_enable_reg_pp0_iter20;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter22 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter22 <= ap_enable_reg_pp0_iter21;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter23 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter23 <= ap_enable_reg_pp0_iter22;
        end else if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter23 <= 1'b0;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter3 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter3 <= ap_enable_reg_pp0_iter2;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter4 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter4 <= ap_enable_reg_pp0_iter3;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter5 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter5 <= ap_enable_reg_pp0_iter4;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter6 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter6 <= ap_enable_reg_pp0_iter5;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter7 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter7 <= ap_enable_reg_pp0_iter6;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter8 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter8 <= ap_enable_reg_pp0_iter7;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter9 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter9 <= ap_enable_reg_pp0_iter8;
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
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0) & (icmp_ln51_fu_144_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1))) begin
        i_reg_127 <= i_16_fu_138_p2;
    end else if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        i_reg_127 <= 64'd0;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state1)) begin
        N_read_reg_349 <= N_dout;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (icmp_ln51_reg_359_pp0_iter11_reg == 1'd0))) begin
        h1_V_108_reg_405 <= h1_V_108_fu_279_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (icmp_ln51_reg_359_pp0_iter16_reg == 1'd0))) begin
        h1_V_110_reg_410 <= h1_V_110_fu_304_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (icmp_ln51_reg_359_pp0_iter21_reg == 1'd0))) begin
        h1_V_112_reg_415 <= h1_V_112_fu_329_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        icmp_ln51_reg_359 <= icmp_ln51_fu_144_p2;
        icmp_ln51_reg_359_pp0_iter1_reg <= icmp_ln51_reg_359;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b0 == ap_block_pp0_stage0_11001)) begin
        icmp_ln51_reg_359_pp0_iter10_reg <= icmp_ln51_reg_359_pp0_iter9_reg;
        icmp_ln51_reg_359_pp0_iter11_reg <= icmp_ln51_reg_359_pp0_iter10_reg;
        icmp_ln51_reg_359_pp0_iter12_reg <= icmp_ln51_reg_359_pp0_iter11_reg;
        icmp_ln51_reg_359_pp0_iter13_reg <= icmp_ln51_reg_359_pp0_iter12_reg;
        icmp_ln51_reg_359_pp0_iter14_reg <= icmp_ln51_reg_359_pp0_iter13_reg;
        icmp_ln51_reg_359_pp0_iter15_reg <= icmp_ln51_reg_359_pp0_iter14_reg;
        icmp_ln51_reg_359_pp0_iter16_reg <= icmp_ln51_reg_359_pp0_iter15_reg;
        icmp_ln51_reg_359_pp0_iter17_reg <= icmp_ln51_reg_359_pp0_iter16_reg;
        icmp_ln51_reg_359_pp0_iter18_reg <= icmp_ln51_reg_359_pp0_iter17_reg;
        icmp_ln51_reg_359_pp0_iter19_reg <= icmp_ln51_reg_359_pp0_iter18_reg;
        icmp_ln51_reg_359_pp0_iter20_reg <= icmp_ln51_reg_359_pp0_iter19_reg;
        icmp_ln51_reg_359_pp0_iter21_reg <= icmp_ln51_reg_359_pp0_iter20_reg;
        icmp_ln51_reg_359_pp0_iter22_reg <= icmp_ln51_reg_359_pp0_iter21_reg;
        icmp_ln51_reg_359_pp0_iter2_reg <= icmp_ln51_reg_359_pp0_iter1_reg;
        icmp_ln51_reg_359_pp0_iter3_reg <= icmp_ln51_reg_359_pp0_iter2_reg;
        icmp_ln51_reg_359_pp0_iter4_reg <= icmp_ln51_reg_359_pp0_iter3_reg;
        icmp_ln51_reg_359_pp0_iter5_reg <= icmp_ln51_reg_359_pp0_iter4_reg;
        icmp_ln51_reg_359_pp0_iter6_reg <= icmp_ln51_reg_359_pp0_iter5_reg;
        icmp_ln51_reg_359_pp0_iter7_reg <= icmp_ln51_reg_359_pp0_iter6_reg;
        icmp_ln51_reg_359_pp0_iter8_reg <= icmp_ln51_reg_359_pp0_iter7_reg;
        icmp_ln51_reg_359_pp0_iter9_reg <= icmp_ln51_reg_359_pp0_iter8_reg;
        p_1_i_i_reg_369_pp0_iter10_reg <= p_1_i_i_reg_369_pp0_iter9_reg;
        p_1_i_i_reg_369_pp0_iter11_reg <= p_1_i_i_reg_369_pp0_iter10_reg;
        p_1_i_i_reg_369_pp0_iter12_reg <= p_1_i_i_reg_369_pp0_iter11_reg;
        p_1_i_i_reg_369_pp0_iter13_reg <= p_1_i_i_reg_369_pp0_iter12_reg;
        p_1_i_i_reg_369_pp0_iter14_reg <= p_1_i_i_reg_369_pp0_iter13_reg;
        p_1_i_i_reg_369_pp0_iter15_reg <= p_1_i_i_reg_369_pp0_iter14_reg;
        p_1_i_i_reg_369_pp0_iter16_reg <= p_1_i_i_reg_369_pp0_iter15_reg;
        p_1_i_i_reg_369_pp0_iter17_reg <= p_1_i_i_reg_369_pp0_iter16_reg;
        p_1_i_i_reg_369_pp0_iter18_reg <= p_1_i_i_reg_369_pp0_iter17_reg;
        p_1_i_i_reg_369_pp0_iter19_reg <= p_1_i_i_reg_369_pp0_iter18_reg;
        p_1_i_i_reg_369_pp0_iter20_reg <= p_1_i_i_reg_369_pp0_iter19_reg;
        p_1_i_i_reg_369_pp0_iter21_reg <= p_1_i_i_reg_369_pp0_iter20_reg;
        p_1_i_i_reg_369_pp0_iter22_reg <= p_1_i_i_reg_369_pp0_iter21_reg;
        p_1_i_i_reg_369_pp0_iter2_reg <= p_1_i_i_reg_369;
        p_1_i_i_reg_369_pp0_iter3_reg <= p_1_i_i_reg_369_pp0_iter2_reg;
        p_1_i_i_reg_369_pp0_iter4_reg <= p_1_i_i_reg_369_pp0_iter3_reg;
        p_1_i_i_reg_369_pp0_iter5_reg <= p_1_i_i_reg_369_pp0_iter4_reg;
        p_1_i_i_reg_369_pp0_iter6_reg <= p_1_i_i_reg_369_pp0_iter5_reg;
        p_1_i_i_reg_369_pp0_iter7_reg <= p_1_i_i_reg_369_pp0_iter6_reg;
        p_1_i_i_reg_369_pp0_iter8_reg <= p_1_i_i_reg_369_pp0_iter7_reg;
        p_1_i_i_reg_369_pp0_iter9_reg <= p_1_i_i_reg_369_pp0_iter8_reg;
        p_2_i_i_reg_374_pp0_iter10_reg <= p_2_i_i_reg_374_pp0_iter9_reg;
        p_2_i_i_reg_374_pp0_iter11_reg <= p_2_i_i_reg_374_pp0_iter10_reg;
        p_2_i_i_reg_374_pp0_iter12_reg <= p_2_i_i_reg_374_pp0_iter11_reg;
        p_2_i_i_reg_374_pp0_iter13_reg <= p_2_i_i_reg_374_pp0_iter12_reg;
        p_2_i_i_reg_374_pp0_iter14_reg <= p_2_i_i_reg_374_pp0_iter13_reg;
        p_2_i_i_reg_374_pp0_iter15_reg <= p_2_i_i_reg_374_pp0_iter14_reg;
        p_2_i_i_reg_374_pp0_iter16_reg <= p_2_i_i_reg_374_pp0_iter15_reg;
        p_2_i_i_reg_374_pp0_iter17_reg <= p_2_i_i_reg_374_pp0_iter16_reg;
        p_2_i_i_reg_374_pp0_iter18_reg <= p_2_i_i_reg_374_pp0_iter17_reg;
        p_2_i_i_reg_374_pp0_iter19_reg <= p_2_i_i_reg_374_pp0_iter18_reg;
        p_2_i_i_reg_374_pp0_iter20_reg <= p_2_i_i_reg_374_pp0_iter19_reg;
        p_2_i_i_reg_374_pp0_iter21_reg <= p_2_i_i_reg_374_pp0_iter20_reg;
        p_2_i_i_reg_374_pp0_iter22_reg <= p_2_i_i_reg_374_pp0_iter21_reg;
        p_2_i_i_reg_374_pp0_iter2_reg <= p_2_i_i_reg_374;
        p_2_i_i_reg_374_pp0_iter3_reg <= p_2_i_i_reg_374_pp0_iter2_reg;
        p_2_i_i_reg_374_pp0_iter4_reg <= p_2_i_i_reg_374_pp0_iter3_reg;
        p_2_i_i_reg_374_pp0_iter5_reg <= p_2_i_i_reg_374_pp0_iter4_reg;
        p_2_i_i_reg_374_pp0_iter6_reg <= p_2_i_i_reg_374_pp0_iter5_reg;
        p_2_i_i_reg_374_pp0_iter7_reg <= p_2_i_i_reg_374_pp0_iter6_reg;
        p_2_i_i_reg_374_pp0_iter8_reg <= p_2_i_i_reg_374_pp0_iter7_reg;
        p_2_i_i_reg_374_pp0_iter9_reg <= p_2_i_i_reg_374_pp0_iter8_reg;
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        p_1_i_i_reg_369 <= dataFifo_V_valid_V_0_dout;
        p_2_i_i_reg_374 <= dataFifo_V_last_V_0_dout;
        tmp_data_V_reg_363 <= dataFifo_V_data_V_0_dout;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (icmp_ln51_reg_359_pp0_iter10_reg == 1'd0))) begin
        r_34_reg_395 <= {{grp_fu_197_p2[31:19]}};
        tmp_14_reg_400 <= {{grp_fu_203_p2[31:13]}};
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (icmp_ln51_reg_359_pp0_iter5_reg == 1'd0))) begin
        r_s_reg_379 <= {{grp_fu_161_p2[31:17]}};
        tmp_s_reg_384 <= {{grp_fu_166_p2[31:15]}};
    end
end

always @ (*) begin
    if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_blk_n = N_empty_n;
    end else begin
        N_blk_n = 1'b1;
    end
end

always @ (*) begin
    if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_out_blk_n = N_out_full_n;
    end else begin
        N_out_blk_n = 1'b1;
    end
end

always @ (*) begin
    if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_out_write = 1'b1;
    end else begin
        N_out_write = 1'b0;
    end
end

always @ (*) begin
    if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        N_read = 1'b1;
    end else begin
        N_read = 1'b0;
    end
end

always @ (*) begin
    if ((icmp_ln51_fu_144_p2 == 1'd1)) begin
        ap_condition_pp0_exit_iter0_state2 = 1'b1;
    end else begin
        ap_condition_pp0_exit_iter0_state2 = 1'b0;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state26)) begin
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
    if (((ap_enable_reg_pp0_iter23 == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b0) & (ap_enable_reg_pp0_iter22 == 1'b0) & (ap_enable_reg_pp0_iter21 == 1'b0) & (ap_enable_reg_pp0_iter20 == 1'b0) & (ap_enable_reg_pp0_iter19 == 1'b0) & (ap_enable_reg_pp0_iter18 == 1'b0) & (ap_enable_reg_pp0_iter17 == 1'b0) & (ap_enable_reg_pp0_iter16 == 1'b0) & (ap_enable_reg_pp0_iter15 == 1'b0) & (ap_enable_reg_pp0_iter14 == 1'b0) & (ap_enable_reg_pp0_iter13 == 1'b0) & (ap_enable_reg_pp0_iter12 == 1'b0) & (ap_enable_reg_pp0_iter11 == 1'b0) & (ap_enable_reg_pp0_iter10 == 1'b0) & (ap_enable_reg_pp0_iter9 == 1'b0) & (ap_enable_reg_pp0_iter8 == 1'b0) & (ap_enable_reg_pp0_iter7 == 1'b0) & (ap_enable_reg_pp0_iter6 == 1'b0) & (ap_enable_reg_pp0_iter5 == 1'b0) & (ap_enable_reg_pp0_iter4 == 1'b0) & (ap_enable_reg_pp0_iter3 == 1'b0) & (ap_enable_reg_pp0_iter2 == 1'b0) & (ap_enable_reg_pp0_iter0 == 1'b0))) begin
        ap_idle_pp0 = 1'b1;
    end else begin
        ap_idle_pp0 = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_data_V_0_blk_n = dataFifo_V_data_V_0_empty_n;
    end else begin
        dataFifo_V_data_V_0_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_data_V_0_read = 1'b1;
    end else begin
        dataFifo_V_data_V_0_read = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_last_V_0_blk_n = dataFifo_V_last_V_0_empty_n;
    end else begin
        dataFifo_V_last_V_0_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_last_V_0_read = 1'b1;
    end else begin
        dataFifo_V_last_V_0_read = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_valid_V_0_blk_n = dataFifo_V_valid_V_0_empty_n;
    end else begin
        dataFifo_V_valid_V_0_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        dataFifo_V_valid_V_0_read = 1'b1;
    end else begin
        dataFifo_V_valid_V_0_read = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_161_ce = 1'b1;
    end else begin
        grp_fu_161_ce = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_166_ce = 1'b1;
    end else begin
        grp_fu_166_ce = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_197_ce = 1'b1;
    end else begin
        grp_fu_197_ce = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_203_ce = 1'b1;
    end else begin
        grp_fu_203_ce = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_285_ce = 1'b1;
    end else begin
        grp_fu_285_ce = 1'b0;
    end
end

always @ (*) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        grp_fu_310_ce = 1'b1;
    end else begin
        grp_fu_310_ce = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (ap_enable_reg_pp0_iter23 == 1'b1) & (1'b0 == ap_block_pp0_stage0))) begin
        hashFifo_8_blk_n = hashFifo_8_full_n;
    end else begin
        hashFifo_8_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (ap_enable_reg_pp0_iter23 == 1'b1) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        hashFifo_8_write = 1'b1;
    end else begin
        hashFifo_8_write = 1'b0;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state26)) begin
        internal_ap_ready = 1'b1;
    end else begin
        internal_ap_ready = 1'b0;
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
    if (((real_start == 1'b1) & (start_once_reg == 1'b0))) begin
        start_write = 1'b1;
    end else begin
        start_write = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            if ((~((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end
        end
        ap_ST_fsm_pp0_stage0 : begin
            if ((~((1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0) & (icmp_ln51_fu_144_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1)) & ~((ap_enable_reg_pp0_iter23 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter22 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else if ((((ap_enable_reg_pp0_iter23 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter22 == 1'b0)) | ((1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0) & (icmp_ln51_fu_144_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1)))) begin
                ap_NS_fsm = ap_ST_fsm_state26;
            end else begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end
        end
        ap_ST_fsm_state26 : begin
            ap_NS_fsm = ap_ST_fsm_state1;
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign N_out_din = N_dout;

assign add_ln213_fu_247_p2 = ($signed(ret_16_fu_235_p2) + $signed(32'd3864292196));

assign ap_CS_fsm_pp0_stage0 = ap_CS_fsm[32'd1];

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

assign ap_CS_fsm_state26 = ap_CS_fsm[32'd2];

assign ap_block_pp0_stage0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_pp0_stage0_01001 = (((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (ap_enable_reg_pp0_iter23 == 1'b1) & (hashFifo_8_full_n == 1'b0)) | ((icmp_ln51_reg_359 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (io_acc_block_signal_op49 == 1'b0)));
end

always @ (*) begin
    ap_block_pp0_stage0_11001 = (((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (ap_enable_reg_pp0_iter23 == 1'b1) & (hashFifo_8_full_n == 1'b0)) | ((icmp_ln51_reg_359 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (io_acc_block_signal_op49 == 1'b0)));
end

always @ (*) begin
    ap_block_pp0_stage0_subdone = (((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (ap_enable_reg_pp0_iter23 == 1'b1) & (hashFifo_8_full_n == 1'b0)) | ((icmp_ln51_reg_359 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (io_acc_block_signal_op49 == 1'b0)));
end

always @ (*) begin
    ap_block_state1 = ((real_start == 1'b0) | (1'b0 == N_out_full_n) | (1'b0 == N_empty_n) | (ap_done_reg == 1'b1));
end

assign ap_block_state10_pp0_stage0_iter8 = ~(1'b1 == 1'b1);

assign ap_block_state11_pp0_stage0_iter9 = ~(1'b1 == 1'b1);

assign ap_block_state12_pp0_stage0_iter10 = ~(1'b1 == 1'b1);

assign ap_block_state13_pp0_stage0_iter11 = ~(1'b1 == 1'b1);

assign ap_block_state14_pp0_stage0_iter12 = ~(1'b1 == 1'b1);

assign ap_block_state15_pp0_stage0_iter13 = ~(1'b1 == 1'b1);

assign ap_block_state16_pp0_stage0_iter14 = ~(1'b1 == 1'b1);

assign ap_block_state17_pp0_stage0_iter15 = ~(1'b1 == 1'b1);

assign ap_block_state18_pp0_stage0_iter16 = ~(1'b1 == 1'b1);

assign ap_block_state19_pp0_stage0_iter17 = ~(1'b1 == 1'b1);

assign ap_block_state20_pp0_stage0_iter18 = ~(1'b1 == 1'b1);

assign ap_block_state21_pp0_stage0_iter19 = ~(1'b1 == 1'b1);

assign ap_block_state22_pp0_stage0_iter20 = ~(1'b1 == 1'b1);

assign ap_block_state23_pp0_stage0_iter21 = ~(1'b1 == 1'b1);

assign ap_block_state24_pp0_stage0_iter22 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state25_pp0_stage0_iter23 = ((icmp_ln51_reg_359_pp0_iter22_reg == 1'd0) & (hashFifo_8_full_n == 1'b0));
end

assign ap_block_state2_pp0_stage0_iter0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state3_pp0_stage0_iter1 = ((icmp_ln51_reg_359 == 1'd0) & (io_acc_block_signal_op49 == 1'b0));
end

assign ap_block_state4_pp0_stage0_iter2 = ~(1'b1 == 1'b1);

assign ap_block_state5_pp0_stage0_iter3 = ~(1'b1 == 1'b1);

assign ap_block_state6_pp0_stage0_iter4 = ~(1'b1 == 1'b1);

assign ap_block_state7_pp0_stage0_iter5 = ~(1'b1 == 1'b1);

assign ap_block_state8_pp0_stage0_iter6 = ~(1'b1 == 1'b1);

assign ap_block_state9_pp0_stage0_iter7 = ~(1'b1 == 1'b1);

assign ap_enable_pp0 = (ap_idle_pp0 ^ 1'b1);

assign ap_ready = internal_ap_ready;

assign grp_fu_161_p1 = 32'd3432918353;

assign grp_fu_166_p1 = 32'd380141568;

assign grp_fu_197_p1 = 32'd461845907;

assign grp_fu_203_p1 = 32'd3870449664;

assign grp_fu_310_p1 = 32'd3266489909;

assign h1_V_106_fu_253_p2 = (add_ln213_fu_247_p2 + shl_ln213_fu_241_p2);

assign h1_V_107_fu_259_p2 = (h1_V_106_fu_253_p2 ^ 32'd4);

assign h1_V_108_fu_279_p2 = (zext_ln1497_fu_275_p1 ^ h1_V_107_fu_259_p2);

assign h1_V_110_fu_304_p2 = (zext_ln1497_31_fu_300_p1 ^ grp_fu_285_p2);

assign h1_V_112_fu_329_p2 = (zext_ln1497_32_fu_325_p1 ^ grp_fu_310_p2);

assign hashFifo_8_din = tmp_fu_335_p5;

assign i_16_fu_138_p2 = (i_reg_127 + 64'd1);

assign icmp_ln51_fu_144_p2 = ((i_reg_127 == N_read_reg_349) ? 1'b1 : 1'b0);

assign io_acc_block_signal_op49 = (dataFifo_V_valid_V_0_empty_n & dataFifo_V_last_V_0_empty_n & dataFifo_V_data_V_0_empty_n);

assign or_ln_fu_229_p3 = {{tmp_14_reg_400}, {r_34_reg_395}};

assign r_35_fu_290_p4 = {{grp_fu_285_p2[31:13]}};

assign r_36_fu_315_p4 = {{grp_fu_310_p2[31:16]}};

assign r_fu_265_p4 = {{h1_V_107_fu_259_p2[31:16]}};

assign ret_16_fu_235_p2 = (or_ln_fu_229_p3 ^ 32'd344064);

assign ret_fu_191_p3 = {{tmp_s_reg_384}, {r_s_reg_379}};

assign shl_ln213_fu_241_p2 = ret_16_fu_235_p2 << 32'd2;

assign start_out = real_start;

assign tmp_fu_335_p5 = {{{{p_2_i_i_reg_374_pp0_iter22_reg}, {7'd0}}, {p_1_i_i_reg_369_pp0_iter22_reg}}, {h1_V_112_reg_415}};

assign zext_ln1497_31_fu_300_p1 = r_35_fu_290_p4;

assign zext_ln1497_32_fu_325_p1 = r_36_fu_315_p4;

assign zext_ln1497_fu_275_p1 = r_fu_265_p4;

endmodule //hyperloglog_top_murmur3_0_s
