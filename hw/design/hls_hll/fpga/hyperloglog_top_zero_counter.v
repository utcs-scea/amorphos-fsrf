// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Version: 2020.2
// Copyright (C) Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module hyperloglog_top_zero_counter (
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
        aggr_out_dout,
        aggr_out_empty_n,
        aggr_out_read,
        numzeros_out_din,
        numzeros_out_full_n,
        numzeros_out_write,
        zero_count_din,
        zero_count_full_n,
        zero_count_write
);

parameter    ap_ST_fsm_state1 = 3'd1;
parameter    ap_ST_fsm_pp0_stage0 = 3'd2;
parameter    ap_ST_fsm_state4 = 3'd4;

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
input  [15:0] aggr_out_dout;
input   aggr_out_empty_n;
output   aggr_out_read;
output  [4:0] numzeros_out_din;
input   numzeros_out_full_n;
output   numzeros_out_write;
output  [16:0] zero_count_din;
input   zero_count_full_n;
output   zero_count_write;

reg ap_done;
reg ap_idle;
reg start_write;
reg aggr_out_read;
reg numzeros_out_write;
reg zero_count_write;

reg    real_start;
reg    start_once_reg;
reg    ap_done_reg;
(* fsm_encoding = "none" *) reg   [2:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
reg    internal_ap_ready;
reg    aggr_out_blk_n;
wire    ap_CS_fsm_pp0_stage0;
reg    ap_enable_reg_pp0_iter1;
wire    ap_block_pp0_stage0;
reg   [0:0] icmp_ln39_reg_126;
reg    numzeros_out_blk_n;
reg    zero_count_blk_n;
wire    ap_CS_fsm_state4;
reg   [16:0] zero_count_V_reg_60;
reg   [16:0] i_V_reg_73;
wire   [16:0] i_V_1_fu_84_p2;
reg    ap_enable_reg_pp0_iter0;
wire    ap_block_state2_pp0_stage0_iter0;
reg    ap_block_state3_pp0_stage0_iter1;
reg    ap_block_pp0_stage0_11001;
wire   [0:0] icmp_ln39_fu_90_p2;
wire   [16:0] zero_count_V_2_fu_113_p3;
reg    ap_block_state1;
reg    ap_block_pp0_stage0_subdone;
reg    ap_condition_pp0_exit_iter0_state2;
wire   [4:0] tmp_value_V_fu_96_p1;
reg    ap_block_pp0_stage0_01001;
wire   [0:0] icmp_ln870_fu_101_p2;
wire   [16:0] zero_count_V_1_fu_107_p2;
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
        end else if (((zero_count_full_n == 1'b1) & (1'b1 == ap_CS_fsm_state4))) begin
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
        end else if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter0 <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter1 <= 1'b0;
    end else begin
        if (((1'b0 == ap_block_pp0_stage0_subdone) & (1'b1 == ap_condition_pp0_exit_iter0_state2))) begin
            ap_enable_reg_pp0_iter1 <= (1'b1 ^ ap_condition_pp0_exit_iter0_state2);
        end else if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter1 <= ap_enable_reg_pp0_iter0;
        end else if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter1 <= 1'b0;
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
    if (((icmp_ln39_fu_90_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        i_V_reg_73 <= i_V_1_fu_84_p2;
    end else if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        i_V_reg_73 <= 17'd0;
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln39_reg_126 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        zero_count_V_reg_60 <= zero_count_V_2_fu_113_p3;
    end else if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
        zero_count_V_reg_60 <= 17'd0;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        icmp_ln39_reg_126 <= icmp_ln39_fu_90_p2;
    end
end

always @ (*) begin
    if (((icmp_ln39_reg_126 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        aggr_out_blk_n = aggr_out_empty_n;
    end else begin
        aggr_out_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln39_reg_126 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        aggr_out_read = 1'b1;
    end else begin
        aggr_out_read = 1'b0;
    end
end

always @ (*) begin
    if ((icmp_ln39_fu_90_p2 == 1'd1)) begin
        ap_condition_pp0_exit_iter0_state2 = 1'b1;
    end else begin
        ap_condition_pp0_exit_iter0_state2 = 1'b0;
    end
end

always @ (*) begin
    if (((zero_count_full_n == 1'b1) & (1'b1 == ap_CS_fsm_state4))) begin
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
    if (((ap_enable_reg_pp0_iter0 == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b0))) begin
        ap_idle_pp0 = 1'b1;
    end else begin
        ap_idle_pp0 = 1'b0;
    end
end

always @ (*) begin
    if (((zero_count_full_n == 1'b1) & (1'b1 == ap_CS_fsm_state4))) begin
        internal_ap_ready = 1'b1;
    end else begin
        internal_ap_ready = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln39_reg_126 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        numzeros_out_blk_n = numzeros_out_full_n;
    end else begin
        numzeros_out_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln39_reg_126 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        numzeros_out_write = 1'b1;
    end else begin
        numzeros_out_write = 1'b0;
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
    if ((1'b1 == ap_CS_fsm_state4)) begin
        zero_count_blk_n = zero_count_full_n;
    end else begin
        zero_count_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((zero_count_full_n == 1'b1) & (1'b1 == ap_CS_fsm_state4))) begin
        zero_count_write = 1'b1;
    end else begin
        zero_count_write = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            if ((~((real_start == 1'b0) | (ap_done_reg == 1'b1)) & (1'b1 == ap_CS_fsm_state1))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end
        end
        ap_ST_fsm_pp0_stage0 : begin
            if (~((icmp_ln39_fu_90_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else if (((icmp_ln39_fu_90_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone))) begin
                ap_NS_fsm = ap_ST_fsm_state4;
            end else begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end
        end
        ap_ST_fsm_state4 : begin
            if (((zero_count_full_n == 1'b1) & (1'b1 == ap_CS_fsm_state4))) begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state4;
            end
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign ap_CS_fsm_pp0_stage0 = ap_CS_fsm[32'd1];

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

assign ap_CS_fsm_state4 = ap_CS_fsm[32'd2];

assign ap_block_pp0_stage0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_pp0_stage0_01001 = ((ap_enable_reg_pp0_iter1 == 1'b1) & (((icmp_ln39_reg_126 == 1'd0) & (numzeros_out_full_n == 1'b0)) | ((icmp_ln39_reg_126 == 1'd0) & (1'b0 == aggr_out_empty_n))));
end

always @ (*) begin
    ap_block_pp0_stage0_11001 = ((ap_enable_reg_pp0_iter1 == 1'b1) & (((icmp_ln39_reg_126 == 1'd0) & (numzeros_out_full_n == 1'b0)) | ((icmp_ln39_reg_126 == 1'd0) & (1'b0 == aggr_out_empty_n))));
end

always @ (*) begin
    ap_block_pp0_stage0_subdone = ((ap_enable_reg_pp0_iter1 == 1'b1) & (((icmp_ln39_reg_126 == 1'd0) & (numzeros_out_full_n == 1'b0)) | ((icmp_ln39_reg_126 == 1'd0) & (1'b0 == aggr_out_empty_n))));
end

always @ (*) begin
    ap_block_state1 = ((real_start == 1'b0) | (ap_done_reg == 1'b1));
end

assign ap_block_state2_pp0_stage0_iter0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state3_pp0_stage0_iter1 = (((icmp_ln39_reg_126 == 1'd0) & (numzeros_out_full_n == 1'b0)) | ((icmp_ln39_reg_126 == 1'd0) & (1'b0 == aggr_out_empty_n)));
end

assign ap_enable_pp0 = (ap_idle_pp0 ^ 1'b1);

assign ap_ready = internal_ap_ready;

assign i_V_1_fu_84_p2 = (i_V_reg_73 + 17'd1);

assign icmp_ln39_fu_90_p2 = ((i_V_reg_73 == 17'd65536) ? 1'b1 : 1'b0);

assign icmp_ln870_fu_101_p2 = ((tmp_value_V_fu_96_p1 == 5'd0) ? 1'b1 : 1'b0);

assign numzeros_out_din = tmp_value_V_fu_96_p1;

assign start_out = real_start;

assign tmp_value_V_fu_96_p1 = aggr_out_dout[4:0];

assign zero_count_V_1_fu_107_p2 = (zero_count_V_reg_60 + 17'd1);

assign zero_count_V_2_fu_113_p3 = ((icmp_ln870_fu_101_p2[0:0] == 1'b1) ? zero_count_V_1_fu_107_p2 : zero_count_V_reg_60);

assign zero_count_din = zero_count_V_reg_60;

endmodule //hyperloglog_top_zero_counter
