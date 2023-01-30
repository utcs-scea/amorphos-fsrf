// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Version: 2020.2
// Copyright (C) Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module hyperloglog_top_accumulate (
        ap_clk,
        ap_rst,
        ap_start,
        ap_done,
        ap_continue,
        ap_idle,
        ap_ready,
        numzeros_out_dout,
        numzeros_out_empty_n,
        numzeros_out_read,
        accm_din,
        accm_full_n,
        accm_write
);

parameter    ap_ST_fsm_state1 = 7'd1;
parameter    ap_ST_fsm_pp0_stage0 = 7'd2;
parameter    ap_ST_fsm_state5 = 7'd4;
parameter    ap_ST_fsm_state6 = 7'd8;
parameter    ap_ST_fsm_state7 = 7'd16;
parameter    ap_ST_fsm_state8 = 7'd32;
parameter    ap_ST_fsm_state9 = 7'd64;
parameter    ap_const_lv33_0 = 33'd0;

input   ap_clk;
input   ap_rst;
input   ap_start;
output   ap_done;
input   ap_continue;
output   ap_idle;
output   ap_ready;
input  [4:0] numzeros_out_dout;
input   numzeros_out_empty_n;
output   numzeros_out_read;
output  [31:0] accm_din;
input   accm_full_n;
output   accm_write;

reg ap_done;
reg ap_idle;
reg ap_ready;
reg numzeros_out_read;
reg accm_write;

reg    ap_done_reg;
(* fsm_encoding = "none" *) reg   [6:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
reg    numzeros_out_blk_n;
wire    ap_CS_fsm_pp0_stage0;
reg    ap_enable_reg_pp0_iter1;
wire    ap_block_pp0_stage0;
reg   [0:0] icmp_ln51_reg_484;
reg    accm_blk_n;
wire    ap_CS_fsm_state9;
reg   [16:0] i_V_reg_107;
reg   [32:0] summation_V_3_reg_118;
wire   [16:0] i_V_18_fu_130_p2;
reg    ap_enable_reg_pp0_iter0;
wire    ap_block_state2_pp0_stage0_iter0;
reg    ap_block_state3_pp0_stage0_iter1;
wire    ap_block_state4_pp0_stage0_iter2;
reg    ap_block_pp0_stage0_11001;
wire   [0:0] icmp_ln51_fu_136_p2;
reg   [0:0] icmp_ln51_reg_484_pp0_iter1_reg;
reg   [4:0] rank_V_reg_488;
wire   [32:0] summation_V_2_fu_193_p3;
reg    ap_enable_reg_pp0_iter2;
wire   [31:0] sub_ln944_fu_231_p2;
reg   [31:0] sub_ln944_reg_498;
wire    ap_CS_fsm_state5;
wire   [31:0] lsb_index_fu_237_p2;
reg   [31:0] lsb_index_reg_504;
reg   [30:0] tmp_reg_512;
wire   [5:0] sub_ln947_fu_257_p2;
reg   [5:0] sub_ln947_reg_517;
wire   [7:0] trunc_ln943_fu_263_p1;
reg   [7:0] trunc_ln943_reg_522;
wire   [0:0] icmp_ln954_fu_328_p2;
reg   [0:0] icmp_ln954_reg_527;
wire    ap_CS_fsm_state6;
wire   [31:0] sub_ln955_fu_339_p2;
reg   [31:0] sub_ln955_reg_532;
wire   [31:0] add_ln954_fu_352_p2;
reg   [31:0] add_ln954_reg_537;
wire   [0:0] select_ln954_fu_357_p3;
reg   [0:0] select_ln954_reg_542;
wire   [0:0] icmp_ln935_fu_365_p2;
reg   [0:0] icmp_ln935_reg_547;
wire    ap_CS_fsm_state7;
reg   [32:0] m_4_reg_552;
reg   [0:0] p_Result_35_reg_557;
wire   [31:0] select_ln935_fu_472_p3;
reg   [31:0] select_ln935_reg_562;
wire    ap_CS_fsm_state8;
reg    ap_block_state1;
reg    ap_block_pp0_stage0_subdone;
reg    ap_condition_pp0_exit_iter0_state2;
wire   [5:0] zext_ln545_fu_142_p1;
wire   [5:0] sub_ln545_fu_145_p2;
wire  signed [31:0] sext_ln104_fu_151_p1;
reg   [32:0] p_Result_38_fu_155_p4;
wire   [33:0] zext_ln703_1_fu_169_p1;
wire   [33:0] zext_ln703_fu_165_p1;
wire   [33:0] ret_V_fu_173_p2;
wire   [0:0] overflow_fu_185_p3;
wire   [32:0] summation_V_fu_179_p2;
reg   [32:0] p_Result_s_fu_201_p4;
wire   [63:0] p_Result_39_fu_211_p3;
reg   [63:0] tmp_i_fu_219_p3;
wire   [31:0] l_fu_227_p1;
wire   [5:0] trunc_ln947_fu_253_p1;
wire   [32:0] zext_ln947_fu_272_p1;
wire   [32:0] zext_ln949_fu_281_p1;
wire   [32:0] lshr_ln947_fu_275_p2;
wire   [32:0] shl_ln949_fu_284_p2;
wire   [32:0] or_ln949_1_fu_290_p2;
wire   [32:0] and_ln949_fu_296_p2;
wire   [0:0] tmp_22_fu_308_p3;
wire   [0:0] p_Result_40_fu_321_p3;
wire   [0:0] xor_ln949_fu_315_p2;
wire   [0:0] icmp_ln946_fu_267_p2;
wire   [0:0] icmp_ln949_fu_302_p2;
wire   [0:0] select_ln946_fu_344_p3;
wire   [0:0] and_ln949_1_fu_333_p2;
wire   [32:0] zext_ln955_fu_371_p1;
wire   [32:0] zext_ln954_fu_380_p1;
wire   [32:0] lshr_ln954_fu_383_p2;
wire   [32:0] shl_ln955_fu_374_p2;
wire   [32:0] m_fu_389_p3;
wire   [33:0] zext_ln951_fu_396_p1;
wire   [33:0] zext_ln961_fu_400_p1;
wire   [33:0] m_1_fu_403_p2;
wire   [7:0] sub_ln964_fu_437_p2;
wire   [7:0] select_ln943_fu_430_p3;
wire   [7:0] add_ln964_fu_442_p2;
wire   [63:0] zext_ln951_1_fu_427_p1;
wire   [8:0] tmp_4_i_fu_448_p3;
wire   [63:0] p_Result_41_fu_456_p5;
wire   [31:0] LD_fu_468_p1;
reg   [6:0] ap_NS_fsm;
reg    ap_idle_pp0;
wire    ap_enable_pp0;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 ap_done_reg = 1'b0;
#0 ap_CS_fsm = 7'd1;
#0 ap_enable_reg_pp0_iter1 = 1'b0;
#0 ap_enable_reg_pp0_iter0 = 1'b0;
#0 ap_enable_reg_pp0_iter2 = 1'b0;
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
        end else if (((1'b1 == ap_CS_fsm_state9) & (1'b1 == accm_full_n))) begin
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
        end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
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
        ap_enable_reg_pp0_iter2 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter2 <= ap_enable_reg_pp0_iter1;
        end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter2 <= 1'b0;
        end
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln51_fu_136_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        i_V_reg_107 <= i_V_18_fu_130_p2;
    end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        i_V_reg_107 <= 17'd0;
    end
end

always @ (posedge ap_clk) begin
    if (((ap_enable_reg_pp0_iter2 == 1'b1) & (icmp_ln51_reg_484_pp0_iter1_reg == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        summation_V_3_reg_118 <= summation_V_2_fu_193_p3;
    end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        summation_V_3_reg_118 <= 33'd0;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state6)) begin
        add_ln954_reg_537 <= add_ln954_fu_352_p2;
        icmp_ln954_reg_527 <= icmp_ln954_fu_328_p2;
        select_ln954_reg_542 <= select_ln954_fu_357_p3;
        sub_ln955_reg_532 <= sub_ln955_fu_339_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        icmp_ln51_reg_484 <= icmp_ln51_fu_136_p2;
        icmp_ln51_reg_484_pp0_iter1_reg <= icmp_ln51_reg_484;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state7)) begin
        icmp_ln935_reg_547 <= icmp_ln935_fu_365_p2;
        m_4_reg_552 <= {{m_1_fu_403_p2[33:1]}};
        p_Result_35_reg_557 <= m_1_fu_403_p2[32'd25];
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state5)) begin
        lsb_index_reg_504 <= lsb_index_fu_237_p2;
        sub_ln944_reg_498 <= sub_ln944_fu_231_p2;
        sub_ln947_reg_517 <= sub_ln947_fu_257_p2;
        tmp_reg_512 <= {{lsb_index_fu_237_p2[31:1]}};
        trunc_ln943_reg_522 <= trunc_ln943_fu_263_p1;
    end
end

always @ (posedge ap_clk) begin
    if (((icmp_ln51_reg_484 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        rank_V_reg_488 <= numzeros_out_dout;
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_CS_fsm_state8)) begin
        select_ln935_reg_562 <= select_ln935_fu_472_p3;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state9)) begin
        accm_blk_n = accm_full_n;
    end else begin
        accm_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state9) & (1'b1 == accm_full_n))) begin
        accm_write = 1'b1;
    end else begin
        accm_write = 1'b0;
    end
end

always @ (*) begin
    if ((icmp_ln51_fu_136_p2 == 1'd1)) begin
        ap_condition_pp0_exit_iter0_state2 = 1'b1;
    end else begin
        ap_condition_pp0_exit_iter0_state2 = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state9) & (1'b1 == accm_full_n))) begin
        ap_done = 1'b1;
    end else begin
        ap_done = ap_done_reg;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state1) & (ap_start == 1'b0))) begin
        ap_idle = 1'b1;
    end else begin
        ap_idle = 1'b0;
    end
end

always @ (*) begin
    if (((ap_enable_reg_pp0_iter2 == 1'b0) & (ap_enable_reg_pp0_iter0 == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b0))) begin
        ap_idle_pp0 = 1'b1;
    end else begin
        ap_idle_pp0 = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state9) & (1'b1 == accm_full_n))) begin
        ap_ready = 1'b1;
    end else begin
        ap_ready = 1'b0;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_484 == 1'd0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        numzeros_out_blk_n = numzeros_out_empty_n;
    end else begin
        numzeros_out_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((icmp_ln51_reg_484 == 1'd0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0))) begin
        numzeros_out_read = 1'b1;
    end else begin
        numzeros_out_read = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end
        end
        ap_ST_fsm_pp0_stage0 : begin
            if ((~((icmp_ln51_fu_136_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) & ~((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else if ((((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) | ((icmp_ln51_fu_136_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_state5;
            end else begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end
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
            if (((1'b1 == ap_CS_fsm_state9) & (1'b1 == accm_full_n))) begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state9;
            end
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign LD_fu_468_p1 = p_Result_41_fu_456_p5[31:0];

assign accm_din = select_ln935_reg_562;

assign add_ln954_fu_352_p2 = ($signed(sub_ln944_reg_498) + $signed(32'd4294967271));

assign add_ln964_fu_442_p2 = (sub_ln964_fu_437_p2 + select_ln943_fu_430_p3);

assign and_ln949_1_fu_333_p2 = (xor_ln949_fu_315_p2 & p_Result_40_fu_321_p3);

assign and_ln949_fu_296_p2 = (summation_V_3_reg_118 & or_ln949_1_fu_290_p2);

assign ap_CS_fsm_pp0_stage0 = ap_CS_fsm[32'd1];

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

assign ap_CS_fsm_state5 = ap_CS_fsm[32'd2];

assign ap_CS_fsm_state6 = ap_CS_fsm[32'd3];

assign ap_CS_fsm_state7 = ap_CS_fsm[32'd4];

assign ap_CS_fsm_state8 = ap_CS_fsm[32'd5];

assign ap_CS_fsm_state9 = ap_CS_fsm[32'd6];

assign ap_block_pp0_stage0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_pp0_stage0_11001 = ((icmp_ln51_reg_484 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (numzeros_out_empty_n == 1'b0));
end

always @ (*) begin
    ap_block_pp0_stage0_subdone = ((icmp_ln51_reg_484 == 1'd0) & (ap_enable_reg_pp0_iter1 == 1'b1) & (numzeros_out_empty_n == 1'b0));
end

always @ (*) begin
    ap_block_state1 = ((ap_done_reg == 1'b1) | (ap_start == 1'b0));
end

assign ap_block_state2_pp0_stage0_iter0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state3_pp0_stage0_iter1 = ((icmp_ln51_reg_484 == 1'd0) & (numzeros_out_empty_n == 1'b0));
end

assign ap_block_state4_pp0_stage0_iter2 = ~(1'b1 == 1'b1);

assign ap_enable_pp0 = (ap_idle_pp0 ^ 1'b1);

assign i_V_18_fu_130_p2 = (i_V_reg_107 + 17'd1);

assign icmp_ln51_fu_136_p2 = ((i_V_reg_107 == 17'd65536) ? 1'b1 : 1'b0);

assign icmp_ln935_fu_365_p2 = ((summation_V_3_reg_118 == 33'd0) ? 1'b1 : 1'b0);

assign icmp_ln946_fu_267_p2 = (($signed(tmp_reg_512) > $signed(31'd0)) ? 1'b1 : 1'b0);

assign icmp_ln949_fu_302_p2 = ((and_ln949_fu_296_p2 != 33'd0) ? 1'b1 : 1'b0);

assign icmp_ln954_fu_328_p2 = (($signed(lsb_index_reg_504) > $signed(32'd0)) ? 1'b1 : 1'b0);

assign l_fu_227_p1 = tmp_i_fu_219_p3[31:0];

assign lsb_index_fu_237_p2 = ($signed(sub_ln944_fu_231_p2) + $signed(32'd4294967272));

assign lshr_ln947_fu_275_p2 = 33'd8589934591 >> zext_ln947_fu_272_p1;

assign lshr_ln954_fu_383_p2 = summation_V_3_reg_118 >> zext_ln954_fu_380_p1;

assign m_1_fu_403_p2 = (zext_ln951_fu_396_p1 + zext_ln961_fu_400_p1);

assign m_fu_389_p3 = ((icmp_ln954_reg_527[0:0] == 1'b1) ? lshr_ln954_fu_383_p2 : shl_ln955_fu_374_p2);

assign or_ln949_1_fu_290_p2 = (shl_ln949_fu_284_p2 | lshr_ln947_fu_275_p2);

assign overflow_fu_185_p3 = ret_V_fu_173_p2[32'd33];

always @ (*) begin
    p_Result_38_fu_155_p4 = ap_const_lv33_0;
    p_Result_38_fu_155_p4[sext_ln104_fu_151_p1] = |(1'd1);
end

assign p_Result_39_fu_211_p3 = {{31'd2147483647}, {p_Result_s_fu_201_p4}};

assign p_Result_40_fu_321_p3 = summation_V_3_reg_118[lsb_index_reg_504];

assign p_Result_41_fu_456_p5 = {{zext_ln951_1_fu_427_p1[63:32]}, {tmp_4_i_fu_448_p3}, {zext_ln951_1_fu_427_p1[22:0]}};

integer ap_tvar_int_0;

always @ (summation_V_3_reg_118) begin
    for (ap_tvar_int_0 = 33 - 1; ap_tvar_int_0 >= 0; ap_tvar_int_0 = ap_tvar_int_0 - 1) begin
        if (ap_tvar_int_0 > 32 - 0) begin
            p_Result_s_fu_201_p4[ap_tvar_int_0] = 1'b0;
        end else begin
            p_Result_s_fu_201_p4[ap_tvar_int_0] = summation_V_3_reg_118[32 - ap_tvar_int_0];
        end
    end
end

assign ret_V_fu_173_p2 = (zext_ln703_1_fu_169_p1 + zext_ln703_fu_165_p1);

assign select_ln935_fu_472_p3 = ((icmp_ln935_reg_547[0:0] == 1'b1) ? 32'd0 : LD_fu_468_p1);

assign select_ln943_fu_430_p3 = ((p_Result_35_reg_557[0:0] == 1'b1) ? 8'd127 : 8'd126);

assign select_ln946_fu_344_p3 = ((icmp_ln946_fu_267_p2[0:0] == 1'b1) ? icmp_ln949_fu_302_p2 : p_Result_40_fu_321_p3);

assign select_ln954_fu_357_p3 = ((icmp_ln954_fu_328_p2[0:0] == 1'b1) ? select_ln946_fu_344_p3 : and_ln949_1_fu_333_p2);

assign sext_ln104_fu_151_p1 = $signed(sub_ln545_fu_145_p2);

assign shl_ln949_fu_284_p2 = 33'd1 << zext_ln949_fu_281_p1;

assign shl_ln955_fu_374_p2 = summation_V_3_reg_118 << zext_ln955_fu_371_p1;

assign sub_ln545_fu_145_p2 = (6'd17 - zext_ln545_fu_142_p1);

assign sub_ln944_fu_231_p2 = (32'd33 - l_fu_227_p1);

assign sub_ln947_fu_257_p2 = ($signed(6'd58) - $signed(trunc_ln947_fu_253_p1));

assign sub_ln955_fu_339_p2 = (32'd25 - sub_ln944_reg_498);

assign sub_ln964_fu_437_p2 = (8'd16 - trunc_ln943_reg_522);

assign summation_V_2_fu_193_p3 = ((overflow_fu_185_p3[0:0] == 1'b1) ? 33'd8589934591 : summation_V_fu_179_p2);

assign summation_V_fu_179_p2 = (p_Result_38_fu_155_p4 + summation_V_3_reg_118);

assign tmp_22_fu_308_p3 = lsb_index_reg_504[32'd31];

assign tmp_4_i_fu_448_p3 = {{1'd0}, {add_ln964_fu_442_p2}};


always @ (p_Result_39_fu_211_p3) begin
    if (p_Result_39_fu_211_p3[0] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd0;
    end else if (p_Result_39_fu_211_p3[1] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd1;
    end else if (p_Result_39_fu_211_p3[2] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd2;
    end else if (p_Result_39_fu_211_p3[3] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd3;
    end else if (p_Result_39_fu_211_p3[4] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd4;
    end else if (p_Result_39_fu_211_p3[5] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd5;
    end else if (p_Result_39_fu_211_p3[6] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd6;
    end else if (p_Result_39_fu_211_p3[7] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd7;
    end else if (p_Result_39_fu_211_p3[8] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd8;
    end else if (p_Result_39_fu_211_p3[9] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd9;
    end else if (p_Result_39_fu_211_p3[10] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd10;
    end else if (p_Result_39_fu_211_p3[11] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd11;
    end else if (p_Result_39_fu_211_p3[12] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd12;
    end else if (p_Result_39_fu_211_p3[13] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd13;
    end else if (p_Result_39_fu_211_p3[14] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd14;
    end else if (p_Result_39_fu_211_p3[15] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd15;
    end else if (p_Result_39_fu_211_p3[16] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd16;
    end else if (p_Result_39_fu_211_p3[17] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd17;
    end else if (p_Result_39_fu_211_p3[18] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd18;
    end else if (p_Result_39_fu_211_p3[19] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd19;
    end else if (p_Result_39_fu_211_p3[20] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd20;
    end else if (p_Result_39_fu_211_p3[21] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd21;
    end else if (p_Result_39_fu_211_p3[22] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd22;
    end else if (p_Result_39_fu_211_p3[23] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd23;
    end else if (p_Result_39_fu_211_p3[24] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd24;
    end else if (p_Result_39_fu_211_p3[25] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd25;
    end else if (p_Result_39_fu_211_p3[26] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd26;
    end else if (p_Result_39_fu_211_p3[27] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd27;
    end else if (p_Result_39_fu_211_p3[28] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd28;
    end else if (p_Result_39_fu_211_p3[29] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd29;
    end else if (p_Result_39_fu_211_p3[30] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd30;
    end else if (p_Result_39_fu_211_p3[31] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd31;
    end else if (p_Result_39_fu_211_p3[32] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd32;
    end else if (p_Result_39_fu_211_p3[33] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd33;
    end else if (p_Result_39_fu_211_p3[34] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd34;
    end else if (p_Result_39_fu_211_p3[35] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd35;
    end else if (p_Result_39_fu_211_p3[36] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd36;
    end else if (p_Result_39_fu_211_p3[37] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd37;
    end else if (p_Result_39_fu_211_p3[38] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd38;
    end else if (p_Result_39_fu_211_p3[39] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd39;
    end else if (p_Result_39_fu_211_p3[40] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd40;
    end else if (p_Result_39_fu_211_p3[41] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd41;
    end else if (p_Result_39_fu_211_p3[42] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd42;
    end else if (p_Result_39_fu_211_p3[43] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd43;
    end else if (p_Result_39_fu_211_p3[44] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd44;
    end else if (p_Result_39_fu_211_p3[45] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd45;
    end else if (p_Result_39_fu_211_p3[46] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd46;
    end else if (p_Result_39_fu_211_p3[47] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd47;
    end else if (p_Result_39_fu_211_p3[48] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd48;
    end else if (p_Result_39_fu_211_p3[49] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd49;
    end else if (p_Result_39_fu_211_p3[50] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd50;
    end else if (p_Result_39_fu_211_p3[51] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd51;
    end else if (p_Result_39_fu_211_p3[52] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd52;
    end else if (p_Result_39_fu_211_p3[53] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd53;
    end else if (p_Result_39_fu_211_p3[54] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd54;
    end else if (p_Result_39_fu_211_p3[55] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd55;
    end else if (p_Result_39_fu_211_p3[56] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd56;
    end else if (p_Result_39_fu_211_p3[57] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd57;
    end else if (p_Result_39_fu_211_p3[58] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd58;
    end else if (p_Result_39_fu_211_p3[59] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd59;
    end else if (p_Result_39_fu_211_p3[60] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd60;
    end else if (p_Result_39_fu_211_p3[61] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd61;
    end else if (p_Result_39_fu_211_p3[62] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd62;
    end else if (p_Result_39_fu_211_p3[63] == 1'b1) begin
        tmp_i_fu_219_p3 = 64'd63;
    end else begin
        tmp_i_fu_219_p3 = 64'd64;
    end
end

assign trunc_ln943_fu_263_p1 = tmp_i_fu_219_p3[7:0];

assign trunc_ln947_fu_253_p1 = sub_ln944_fu_231_p2[5:0];

assign xor_ln949_fu_315_p2 = (tmp_22_fu_308_p3 ^ 1'd1);

assign zext_ln545_fu_142_p1 = rank_V_reg_488;

assign zext_ln703_1_fu_169_p1 = p_Result_38_fu_155_p4;

assign zext_ln703_fu_165_p1 = summation_V_3_reg_118;

assign zext_ln947_fu_272_p1 = sub_ln947_reg_517;

assign zext_ln949_fu_281_p1 = lsb_index_reg_504;

assign zext_ln951_1_fu_427_p1 = m_4_reg_552;

assign zext_ln951_fu_396_p1 = m_fu_389_p3;

assign zext_ln954_fu_380_p1 = add_ln954_reg_537;

assign zext_ln955_fu_371_p1 = sub_ln955_reg_532;

assign zext_ln961_fu_400_p1 = select_ln954_reg_542;

endmodule //hyperloglog_top_accumulate