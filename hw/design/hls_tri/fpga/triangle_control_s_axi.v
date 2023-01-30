// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2020.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================
`timescale 1ns/1ps
module triangle_control_s_axi
#(parameter
    C_S_AXI_ADDR_WIDTH = 8,
    C_S_AXI_DATA_WIDTH = 64
)(
    input  wire                          ACLK,
    input  wire                          ARESET,
    input  wire                          ACLK_EN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR,
    input  wire                          AWVALID,
    output wire                          AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB,
    input  wire                          WVALID,
    output wire                          WREADY,
    output wire [1:0]                    BRESP,
    output wire                          BVALID,
    input  wire                          BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR,
    input  wire                          ARVALID,
    output wire                          ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA,
    output wire [1:0]                    RRESP,
    output wire                          RVALID,
    input  wire                          RREADY,
    output wire                          interrupt,
    output wire                          ap_start,
    input  wire                          ap_done,
    input  wire                          ap_ready,
    output wire                          ap_continue,
    input  wire                          ap_idle,
    input  wire [447:0]                  ap_return,
    output wire [63:0]                   mem1_offset,
    output wire [63:0]                   mem2_offset,
    output wire [63:0]                   mem3_offset,
    output wire [63:0]                   len_in_big_words,
    output wire [63:0]                   outs
);
//------------------------Address Info-------------------
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read)
//        bit 4  - ap_continue (Read/Write/SC)
//        bit 7  - auto_restart (Read/Write)
//        others - reserved
// 0x08 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x10 : IP Interrupt Enable Register (Read/Write)
//        bit 0  - enable ap_done interrupt (Read/Write)
//        bit 1  - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x18 : IP Interrupt Status Register (Read/TOW)
//        bit 0  - ap_done (COR/TOW)
//        bit 1  - ap_ready (COR/TOW)
//        others - reserved
// 0x20 : Data signal of ap_return
//        bit 63~0 - ap_return[63:0] (Read)
// 0x28 : Data signal of ap_return
//        bit 63~0 - ap_return[127:64] (Read)
// 0x30 : Data signal of ap_return
//        bit 63~0 - ap_return[191:128] (Read)
// 0x38 : Data signal of ap_return
//        bit 63~0 - ap_return[255:192] (Read)
// 0x40 : Data signal of ap_return
//        bit 63~0 - ap_return[319:256] (Read)
// 0x48 : Data signal of ap_return
//        bit 63~0 - ap_return[383:320] (Read)
// 0x50 : Data signal of ap_return
//        bit 63~0 - ap_return[447:384] (Read)
// 0x60 : Data signal of mem1_offset
//        bit 63~0 - mem1_offset[63:0] (Read/Write)
// 0x68 : reserved
// 0x70 : Data signal of mem2_offset
//        bit 63~0 - mem2_offset[63:0] (Read/Write)
// 0x78 : reserved
// 0x80 : Data signal of mem3_offset
//        bit 63~0 - mem3_offset[63:0] (Read/Write)
// 0x88 : reserved
// 0x90 : Data signal of len_in_big_words
//        bit 63~0 - len_in_big_words[63:0] (Read/Write)
// 0x98 : reserved
// 0xa0 : Data signal of outs
//        bit 63~0 - outs[63:0] (Read/Write)
// 0xa8 : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_AP_CTRL                 = 8'h00,
    ADDR_GIE                     = 8'h08,
    ADDR_IER                     = 8'h10,
    ADDR_ISR                     = 8'h18,
    ADDR_AP_RETURN_0             = 8'h20,
    ADDR_AP_RETURN_1             = 8'h28,
    ADDR_AP_RETURN_2             = 8'h30,
    ADDR_AP_RETURN_3             = 8'h38,
    ADDR_AP_RETURN_4             = 8'h40,
    ADDR_AP_RETURN_5             = 8'h48,
    ADDR_AP_RETURN_6             = 8'h50,
    ADDR_MEM1_OFFSET_DATA_0      = 8'h60,
    ADDR_MEM1_OFFSET_CTRL        = 8'h68,
    ADDR_MEM2_OFFSET_DATA_0      = 8'h70,
    ADDR_MEM2_OFFSET_CTRL        = 8'h78,
    ADDR_MEM3_OFFSET_DATA_0      = 8'h80,
    ADDR_MEM3_OFFSET_CTRL        = 8'h88,
    ADDR_LEN_IN_BIG_WORDS_DATA_0 = 8'h90,
    ADDR_LEN_IN_BIG_WORDS_CTRL   = 8'h98,
    ADDR_OUTS_DATA_0             = 8'ha0,
    ADDR_OUTS_CTRL               = 8'ha8,
    WRIDLE                       = 2'd0,
    WRDATA                       = 2'd1,
    WRRESP                       = 2'd2,
    WRRESET                      = 2'd3,
    RDIDLE                       = 2'd0,
    RDDATA                       = 2'd1,
    RDRESET                      = 2'd2,
    ADDR_BITS                = 8;

//------------------------Local signal-------------------
    reg  [1:0]                    wstate = WRRESET;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [C_S_AXI_DATA_WIDTH-1:0] wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate = RDRESET;
    reg  [1:0]                    rnext;
    reg  [C_S_AXI_DATA_WIDTH-1:0] rdata;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;
    // internal registers
    reg                           int_ap_idle;
    reg                           int_ap_continue;
    reg                           int_ap_ready;
    wire                          int_ap_done;
    reg                           int_ap_start = 1'b0;
    reg                           int_auto_restart = 1'b0;
    reg                           int_gie = 1'b0;
    reg  [1:0]                    int_ier = 2'b0;
    reg  [1:0]                    int_isr = 2'b0;
    reg  [447:0]                  int_ap_return;
    reg  [63:0]                   int_mem1_offset = 'b0;
    reg  [63:0]                   int_mem2_offset = 'b0;
    reg  [63:0]                   int_mem3_offset = 'b0;
    reg  [63:0]                   int_len_in_big_words = 'b0;
    reg  [63:0]                   int_outs = 'b0;

//------------------------Instantiation------------------


//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
assign wmask   = { {8{WSTRB[7]}}, {8{WSTRB[6]}}, {8{WSTRB[5]}}, {8{WSTRB[4]}}, {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRRESET;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA);
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDRESET;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (ar_hs) begin
            rdata <= 'b0;
            case (raddr)
                ADDR_AP_CTRL: begin
                    rdata[0] <= int_ap_start;
                    rdata[1] <= int_ap_done;
                    rdata[2] <= int_ap_idle;
                    rdata[3] <= int_ap_ready;
                    rdata[4] <= int_ap_continue;
                    rdata[7] <= int_auto_restart;
                end
                ADDR_GIE: begin
                    rdata <= int_gie;
                end
                ADDR_IER: begin
                    rdata <= int_ier;
                end
                ADDR_ISR: begin
                    rdata <= int_isr;
                end
                ADDR_AP_RETURN_0: begin
                    rdata <= int_ap_return[63:0];
                end
                ADDR_AP_RETURN_1: begin
                    rdata <= int_ap_return[127:64];
                end
                ADDR_AP_RETURN_2: begin
                    rdata <= int_ap_return[191:128];
                end
                ADDR_AP_RETURN_3: begin
                    rdata <= int_ap_return[255:192];
                end
                ADDR_AP_RETURN_4: begin
                    rdata <= int_ap_return[319:256];
                end
                ADDR_AP_RETURN_5: begin
                    rdata <= int_ap_return[383:320];
                end
                ADDR_AP_RETURN_6: begin
                    rdata <= int_ap_return[447:384];
                end
                ADDR_MEM1_OFFSET_DATA_0: begin
                    rdata <= int_mem1_offset[63:0];
                end
                ADDR_MEM2_OFFSET_DATA_0: begin
                    rdata <= int_mem2_offset[63:0];
                end
                ADDR_MEM3_OFFSET_DATA_0: begin
                    rdata <= int_mem3_offset[63:0];
                end
                ADDR_LEN_IN_BIG_WORDS_DATA_0: begin
                    rdata <= int_len_in_big_words[63:0];
                end
                ADDR_OUTS_DATA_0: begin
                    rdata <= int_outs[63:0];
                end
            endcase
        end
    end
end


//------------------------Register logic-----------------
assign interrupt        = int_gie & (|int_isr);
assign ap_start         = int_ap_start;
assign int_ap_done      = ap_done;
assign ap_continue      = int_ap_continue;
assign mem1_offset      = int_mem1_offset;
assign mem2_offset      = int_mem2_offset;
assign mem3_offset      = int_mem3_offset;
assign len_in_big_words = int_len_in_big_words;
assign outs             = int_outs;
// int_ap_start
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0] && WDATA[0])
            int_ap_start <= 1'b1;
        else if (ap_ready)
            int_ap_start <= int_auto_restart; // clear on handshake/auto restart
    end
end

// int_ap_idle
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_idle <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_idle <= ap_idle;
    end
end

// int_ap_ready
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_ready <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_ready <= ap_ready;
    end
end

// int_ap_continue
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_continue <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0] && WDATA[4])
            int_ap_continue <= 1'b1;
        else if (ap_done & ~int_ap_continue & int_auto_restart)
            int_ap_continue <= 1'b1; // auto restart
        else
            int_ap_continue <= 1'b0; // self clear
    end
end

// int_auto_restart
always @(posedge ACLK) begin
    if (ARESET)
        int_auto_restart <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0])
            int_auto_restart <=  WDATA[7];
    end
end

// int_gie
always @(posedge ACLK) begin
    if (ARESET)
        int_gie <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_GIE && WSTRB[0])
            int_gie <= WDATA[0];
    end
end

// int_ier
always @(posedge ACLK) begin
    if (ARESET)
        int_ier <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_IER && WSTRB[0])
            int_ier <= WDATA[1:0];
    end
end

// int_isr[0]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[0] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[0] & ap_done)
            int_isr[0] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[0] <= int_isr[0] ^ WDATA[0]; // toggle on write
    end
end

// int_isr[1]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[1] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[1] & ap_ready)
            int_isr[1] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[1] <= int_isr[1] ^ WDATA[1]; // toggle on write
    end
end

// int_ap_return
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_return <= 0;
    else if (ACLK_EN) begin
        if (ap_done)
            int_ap_return <= ap_return;
    end
end

// int_mem1_offset[63:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_mem1_offset[63:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_MEM1_OFFSET_DATA_0)
            int_mem1_offset[63:0] <= (WDATA[63:0] & wmask) | (int_mem1_offset[63:0] & ~wmask);
    end
end

// int_mem2_offset[63:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_mem2_offset[63:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_MEM2_OFFSET_DATA_0)
            int_mem2_offset[63:0] <= (WDATA[63:0] & wmask) | (int_mem2_offset[63:0] & ~wmask);
    end
end

// int_mem3_offset[63:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_mem3_offset[63:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_MEM3_OFFSET_DATA_0)
            int_mem3_offset[63:0] <= (WDATA[63:0] & wmask) | (int_mem3_offset[63:0] & ~wmask);
    end
end

// int_len_in_big_words[63:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_len_in_big_words[63:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_LEN_IN_BIG_WORDS_DATA_0)
            int_len_in_big_words[63:0] <= (WDATA[63:0] & wmask) | (int_len_in_big_words[63:0] & ~wmask);
    end
end

// int_outs[63:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_outs[63:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_OUTS_DATA_0)
            int_outs[63:0] <= (WDATA[63:0] & wmask) | (int_outs[63:0] & ~wmask);
    end
end


//------------------------Memory logic-------------------

endmodule
