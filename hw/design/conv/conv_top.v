`include "conv_constants.v"

`define START_CREDS 6

module conv_top (
	input clk,
	input rst,
	
	output reg [15:0] arid_m,
	output reg [63:0] araddr_m,
	output reg [7:0]  arlen_m,
	output reg [2:0]  arsize_m,
	output reg        arvalid_m,
	input             arready_m,
	
	input [15:0]  rid_m,
	input [511:0] rdata_m,
	input [1:0]   rresp_m,
	input         rlast_m,
	input         rvalid_m,
	output reg    rready_m,
	
	output reg [15:0] awid_m,
	output reg [63:0] awaddr_m,
	output reg [7:0]  awlen_m,
	output reg [2:0]  awsize_m,
	output reg        awvalid_m,
	input             awready_m,
	
	output reg [15:0]  wid_m,
	output reg [511:0] wdata_m,
	output reg [63:0]  wstrb_m,
	output reg         wlast_m,
	output reg         wvalid_m,
	input              wready_m,
	
	input [15:0] bid_m,
	input [1:0]  bresp_m,
	input        bvalid_m,
	output reg   bready_m,
	
	input        softreg_req_valid,
	input        softreg_req_isWrite,
	input [31:0] softreg_req_addr,
	input [63:0] softreg_req_data,
	
	output        softreg_resp_valid,
	output [63:0] softreg_resp_data
);

localparam TRANS_SIZE = 512; // bits

reg [$clog2(`I_SIZE_MAX)+1:0] vI_SIZE;

//localparam I_SIZE = `IMAGE_SIZE; // must be multiple of TRANS_SIZE/8
//localparam unsigned I_SIZE2 = I_SIZE*I_SIZE;

reg[31:0] vBURSTS_IMG;
localparam BURSTS_PER_PAGE = 4096 / (TRANS_SIZE / 8);
reg[31:0] vPAGES;
reg[31:0] vLEFTOVER_SIZE_;
reg[31:0] vLEFTOVER_SIZE;

always @(posedge clk) begin
	vBURSTS_IMG <= (vI_SIZE / (TRANS_SIZE / 8)) * vI_SIZE;
	vPAGES <= (vBURSTS_IMG-1) / BURSTS_PER_PAGE + 1;
	vLEFTOVER_SIZE_ <= vBURSTS_IMG % BURSTS_PER_PAGE;
	vLEFTOVER_SIZE <= (vLEFTOVER_SIZE_ == 0) ? BURSTS_PER_PAGE : vLEFTOVER_SIZE_;
end
localparam BW_IMG = 32;// $clog2(vBURSTS_IMG+1); // +1 for "all"
localparam BW_IMG_REQ = 32;// $clog2(vPAGES+1); // +1 for "all"

initial $display("its %d", vBURSTS_IMG);
initial $display("its %d", `SIMUL);

// state
reg [7:0] state; // 0 = waiting for softreg img_addr, 1 = waiting for softreg img_write_addr, 2 = waiting for softreg krnl_part1, 3 = waiting for softreg krnl_part2, 4 = running

reg [63:0]image_addr; // assumes that the img addr is 4KB aligned
reg [63:0]image_write_addr; // assumes that the img addr is 4KB aligned

reg liveMode;
`define SR 15
reg [63:0] stallReasons[`SR-1:0];

// axi wire
reg [31:0] cnt = 0;
wire rready_m_ = state == 4 && dut_ready_out;// && cnt != 28;

// input, output into conv

reg [TRANS_SIZE-1:0] rdata_m_buf;
reg [63:0]rvalid_count;
reg [63:0]rvalid_in_bpp;
always @(posedge clk) begin
    if (rst) begin
        rvalid_count <= 0;
	rvalid_in_bpp <= 0;
        liveMode <= 0;
    end else if (state == 4 && done_) begin
	rvalid_count <= 0;
	rvalid_in_bpp <= 0;
        liveMode <= 0;
    end else if (rvalid_m && rready_m_) begin
        rvalid_count <= rvalid_count + 1;
        rvalid_in_bpp <= (rvalid_in_bpp == BURSTS_PER_PAGE - 1 ? 0 : rvalid_in_bpp + 1);
        liveMode <= 1;
    end
end
integer abc;
integer abcd;
always @(posedge clk) begin
    if (rst) begin
	for (abcd = 0; abcd < `SR; abcd = abcd + 1) begin
		stallReasons[abcd] <= 0;
	end
    end else if (state == 1) begin
	for (abc = 0; abc < `SR; abc = abc + 1) begin
		stallReasons[abc] <= 0;
	end
    end else if (liveMode) begin
	if (!rvalid_m) stallReasons[0] <= stallReasons[0] + 1;
	if (!rready_m_) stallReasons[1] <= stallReasons[1] + 1;
	if (!wvalid_m) stallReasons[2] <= stallReasons[2] + 1;
	if (!wready_m) stallReasons[3] <= stallReasons[3] + 1;
	if (!dut_ready_out) stallReasons[4] <= stallReasons[4] + 1;
	if (!(out_buf_size < 2)) stallReasons[5] <= stallReasons[5] + 1;
	if (out_buf_empty) stallReasons[6] <= stallReasons[6] + 1;
	if (!rvalid_m && read_creds == 0) stallReasons[7] <= stallReasons[7] + 1;
	if (!wready_m && write_creds == 0) stallReasons[8] <= stallReasons[8] + 1;
	if (!valid_in) stallReasons[9] <= stallReasons[9] + 1;
	if (!rvalid_m && rready_m_) stallReasons[10] <= stallReasons[10] + 1;
	if (rvalid_m && !rready_m_) stallReasons[11] <= stallReasons[11] + 1;
	if (wvalid_m && !wready_m) stallReasons[12] <= stallReasons[12] + 1;
	if (!wvalid_m && wready_m) stallReasons[13] <= stallReasons[13] + 1;
	stallReasons[14] <= stallReasons[14] + 1;
    end
end
reg rvalid_m_buf;
always @(posedge clk) begin
    if (rst) begin
        rvalid_m_buf <= 0;
    end else if (state == 4 && done_) begin
	rdata_m_buf <= 0;
        rvalid_m_buf <= 0;
    end else if (dut_ready_out) begin
        rdata_m_buf <= rdata_m;
        rvalid_m_buf <= rvalid_m;
    end
end
wire valid_in = rvalid_m_buf && rready_m_;
wire [TRANS_SIZE-1:0] image = rdata_m_buf;
reg [63:0] valid_ins;

// Outputs
wire valid_out;
wire [TRANS_SIZE-1:0] image_out;

// output buffer
wire out_buf_wrreq;
wire [TRANS_SIZE-1:0] out_buf_data;
wire out_buf_full;
	
wire out_buf_rdreq;
wire [TRANS_SIZE-1:0] out_buf_q;
wire out_buf_empty;

HullFIFO #(
    .WIDTH(TRANS_SIZE),
    .LOG_DEPTH($clog2(`PIPELINE_SIZE)+1)
) out_buf (
    .clock(clk),
    .reset_n(!rst),
    .wrreq(out_buf_wrreq),
    .data(out_buf_data),
    .full(out_buf_full),
    .rdreq(out_buf_rdreq),
    .q(out_buf_q),
    .empty(out_buf_empty)
);

wire done_ = valid_outs == vBURSTS_IMG;
reg[31:0] vBURSTS_WHEN_DONE;
reg[31:0] vo_when_done;

reg [$clog2(`PIPELINE_SIZE)+1:0] out_buf_size;
reg dut_ready_out;
always @(posedge clk) begin
    if (rst) begin
        dut_ready_out <= 0;
        out_buf_size <= 0;
    end else begin
        //$display("on cycle %d. axi gave %d: %h, and i'm inputting to dut: %d, %d: %h.", cnt, rvalid_m, rdata_m[511:480], valid_in, dut_ready_out, image[511:480]);
        //$display("   dut output: %d: %h, and fifo size %d outputs %h to a ready = %d axi (%d) at cnt %h", valid_out, image_out[511:480], out_buf_size, out_buf_q[511:480], wready_m, wvalid_m, valid_outs);
	if (state == 4 && done_) begin
	    dut_ready_out <= 0;
            out_buf_size <= 0;
        end else begin
            dut_ready_out <= wready_m && out_buf_size < 2;

            if (out_buf_full) $display("PANICCCCCCCCCCCCCCCCCCCCCCCCCC");
            if (out_buf_rdreq && out_buf_wrreq) begin
            end else if (out_buf_rdreq) begin
                out_buf_size <= out_buf_size - 1;
            end else if (out_buf_wrreq) begin
                out_buf_size <= out_buf_size + 1;
            end
        end
    end
end
assign out_buf_rdreq = wready_m && !out_buf_empty;
assign out_buf_data = image_out;
assign out_buf_wrreq = valid_out;

ConvGrid #(
    .TRANS_SIZE(TRANS_SIZE)
) dut (
    .clk(clk),
    .rst(rst),

    .valid_in(valid_in),
    .image(image),
    .krnl_loaded(state == 4),

    .ready_out(dut_ready_out),
    .valid_out(valid_out),
    .image_out(image_out),
    .done(done_),
    .vI_SIZE(vI_SIZE)
);

reg [BW_IMG_REQ-1:0] img_reqs;
reg [BW_IMG_REQ-1:0] img_writes;
reg [7:0] read_creds;
reg [7:0] write_creds;
wire img_reqs_done = img_reqs == vPAGES;
wire img_writes_done = img_writes == vPAGES;

reg [BW_IMG-1:0] valid_outs;
reg [BW_IMG-1:0] valid_outs_inv; // counts from all to 0
reg [BW_IMG-1:0] valid_outs_from_dut;
//reg [$clog2(BURSTS_PER_PAGE)-1:0] outs_mod_bpp;
//wire [$clog2(BURSTS_PER_PAGE)-1:0] outs_mod_bpp_ = (wready_m && !out_buf_empty) ? (outs_mod_bpp == BURSTS_PER_PAGE - 1 ? 0 : outs_mod_bpp + 1) : outs_mod_bpp;
reg [31:0] outs_mod_bpp;
wire [31:0] outs_mod_bpp_ = (wready_m && !out_buf_empty) ? (outs_mod_bpp == BURSTS_PER_PAGE - 1 ? 0 : outs_mod_bpp + 1) : outs_mod_bpp;
reg [31:0] outs_done;

wire softreg_req_validW = softreg_req_valid && softreg_req_isWrite;
wire softreg_req_validR = softreg_req_valid && !softreg_req_isWrite;

reg debugc = 0;

reg doneWasTripped;

always @(posedge clk) begin
    cnt <= cnt + 1;
    //$display(" on %d %d its %d %d", rst, cnt, valid_in, valid_out);
    if (rst) begin
        state <= 0;
        img_reqs <= 0;
        img_writes <= 0;
	read_creds <= `START_CREDS;
	write_creds <= `START_CREDS;
        valid_outs <= 0;
        valid_outs_inv <= 0;
        valid_outs_from_dut <= 0;
        outs_mod_bpp <= 0;
        outs_done <= 0;
	doneWasTripped <= 0;
	valid_ins <= 0;
    end else if (state == 0) begin
        if (softreg_req_validW && softreg_req_addr == 0) begin
            state <= 1;
            image_addr <= softreg_req_data;
        end
    end else if (state == 1) begin
        if (softreg_req_validW && softreg_req_addr == 32'h8) begin
            state <= 2;
            image_write_addr <= softreg_req_data;
$display("writing to %h", softreg_req_data);
        end
    end else if (state == 2) begin
        if (softreg_req_validW && softreg_req_addr == 32'h10) begin
            state <= 3;
            vI_SIZE <= softreg_req_data;
        end
    end else if (state == 3) begin
        if (softreg_req_validW && softreg_req_addr == 32'h18) begin
            state <= 4;
            // reset state that depends on vI_SIZE
            valid_outs_inv <= vBURSTS_IMG;
            //$display("moving on. %d", valid_outs);
        end
    end else if (state == 4) begin
            //$display("moving on2. %d", valid_outs);
            //$display("moving on2.. %d", valid_out);
        if (debugc == 0) begin
            debugc <= 1;
            //$display("krnl: %h %d", kernel, valid_outs);
            $display("mem00: %h", rdata_m[7:0]);
        end
        if (valid_out) begin
            //$display("got valid out %d: %h", valid_outs, image_out);
            //$display("writing back %h: %d", out_buf_q, !out_buf_empty);
        end
        //else $display("got invalid out");
        if (done_) begin
            state <= 0;
            img_reqs <= 0;
            img_writes <= 0;
	    read_creds <= `START_CREDS;
	    write_creds <= `START_CREDS;
            valid_outs <= 0;
            valid_outs_from_dut <= 0;
            outs_mod_bpp <= 0;
            outs_done <= 0;
	    doneWasTripped <= 1;
	    valid_ins <= 0;
            vBURSTS_WHEN_DONE <= vBURSTS_IMG;
            vo_when_done <= valid_outs;
            $display("finished!");
        end
        else begin
            valid_outs_from_dut <= valid_outs_from_dut + (valid_out ? 1 : 0);
            valid_outs <= valid_outs + (wready_m && !out_buf_empty ? 1 : 0);
            valid_outs_inv <= valid_outs_inv - (wready_m && !out_buf_empty ? 1 : 0);
            outs_mod_bpp <=  outs_mod_bpp_;
            outs_done <= outs_done + ((wready_m && !out_buf_empty) && outs_mod_bpp == BURSTS_PER_PAGE - 1 ? 1 : 0);
//$display("%d and %d", read_creds, write_creds);
	    if (valid_in) begin
		valid_ins <= valid_ins + 1;
		
		//$display("valid in %d", valid_ins+1);
	    end

	    if (arready_m && arvalid_m_ && (rvalid_in_bpp == BURSTS_PER_PAGE - 1 && rvalid_m && rready_m_)) begin
                img_reqs <= img_reqs + 1;
            end else if (arready_m && arvalid_m_) begin
		read_creds <= read_creds - 1;
                img_reqs <= img_reqs + 1;
            end else if (rvalid_in_bpp == BURSTS_PER_PAGE - 1 && rvalid_m && rready_m_) begin
		read_creds <= read_creds + 1;
	    end

            if (awready_m && awvalid_m_ && (outs_mod_bpp == BURSTS_PER_PAGE - 1 && outs_mod_bpp_ == 0)) begin
                img_writes <= img_writes + 1;
            end else if (awready_m && awvalid_m_) begin
		write_creds <= write_creds - 1;
                img_writes <= img_writes + 1;
            end else if (outs_mod_bpp == BURSTS_PER_PAGE - 1 && outs_mod_bpp_ == 0) begin
		write_creds <= write_creds + 1;
	    end
        end
    end 
    //$display("on clk %d, state %d", clk, state);
end

reg [63:0]softreg_resp_data_buf;
reg softreg_resp_valid_buf;

always @(posedge clk) begin
    softreg_resp_data_buf <= 
	    softreg_req_addr == 32'h20 ?araddr_m:
	    softreg_req_addr == 32'h28 ?arlen_m:
	    softreg_req_addr == 32'h30 ?arvalid_m:
	    softreg_req_addr == 32'h38 ?arready_m:
	    
	    softreg_req_addr == 32'h40 ?rdata_m:
	    softreg_req_addr == 32'h48 ?rresp_m:
	    softreg_req_addr == 32'h50 ?rlast_m:
	    softreg_req_addr == 32'h58 ?rvalid_m:
	    softreg_req_addr == 32'h60 ?rready_m:
	    
	    softreg_req_addr == 32'h68 ?awaddr_m:
	    softreg_req_addr == 32'h70 ?awlen_m:
	    softreg_req_addr == 32'h78 ?awvalid_m:
	    softreg_req_addr == 32'h80 ?awready_m:
	    
	    softreg_req_addr == 32'h88 ?wdata_m:
	    softreg_req_addr == 32'h90 ?wlast_m:
	    softreg_req_addr == 32'h98 ?wvalid_m:
	    softreg_req_addr == 32'ha0 ?wready_m:
	    
	    softreg_req_addr == 32'ha8 ?bresp_m:
	    softreg_req_addr == 32'hb0 ?bvalid_m:
	    softreg_req_addr == 32'hb8 ?bready_m:


	    softreg_req_addr == 32'hc0 ? state :
	    softreg_req_addr == 32'hc8 ? image_addr :
	    softreg_req_addr == 32'hd0 ? image_write_addr :
            softreg_req_addr == 32'hd8 ? rvalid_count :
            softreg_req_addr == 32'he0 ? out_buf_size :
            softreg_req_addr == 32'he8 ? dut_ready_out :
            softreg_req_addr == 32'hf0 ? img_reqs :
            softreg_req_addr == 32'hf8 ? img_writes :
            softreg_req_addr == 32'h100 ? valid_outs :
            softreg_req_addr == 32'h108 ? valid_outs_inv :
            softreg_req_addr == 32'h110 ? outs_mod_bpp :
            softreg_req_addr == 32'h118 ? outs_done :
            softreg_req_addr == 32'h120 ? valid_out :
            softreg_req_addr == 32'h128 ? out_buf_wrreq :
            softreg_req_addr == 32'h130 ? out_buf_rdreq :
            softreg_req_addr == 32'h138 ? doneWasTripped :
            softreg_req_addr == 32'h140 ? valid_outs_from_dut :
            softreg_req_addr == 32'h148 ? read_creds :
            softreg_req_addr == 32'h150 ? write_creds :
            softreg_req_addr == 32'h158 ? rvalid_in_bpp :
            softreg_req_addr == 32'h160 ? valid_ins :
            softreg_req_addr == 32'h168 ? stallReasons[0] :
            softreg_req_addr == 32'h170 ? stallReasons[1] :
            softreg_req_addr == 32'h178 ? stallReasons[2] :
            softreg_req_addr == 32'h180 ? stallReasons[3] :
            softreg_req_addr == 32'h188 ? stallReasons[4] :
            softreg_req_addr == 32'h190 ? stallReasons[5] :
            softreg_req_addr == 32'h198 ? stallReasons[6] :
            softreg_req_addr == 32'h200 ? stallReasons[7] :
            softreg_req_addr == 32'h208 ? stallReasons[8] :
            softreg_req_addr == 32'h210 ? stallReasons[9] :
            softreg_req_addr == 32'h218 ? stallReasons[10] :
            softreg_req_addr == 32'h220 ? stallReasons[11] :
            softreg_req_addr == 32'h228 ? stallReasons[12] :
            softreg_req_addr == 32'h230 ? stallReasons[13] :
            softreg_req_addr == 32'h238 ? stallReasons[14] :
            softreg_req_addr == 32'h240 ? vI_SIZE :
            softreg_req_addr == 32'h248 ? vBURSTS_IMG :
            softreg_req_addr == 32'h250 ? BURSTS_PER_PAGE :
            softreg_req_addr == 32'h258 ? vPAGES :
            softreg_req_addr == 32'h260 ? vLEFTOVER_SIZE_ :
            softreg_req_addr == 32'h268 ? vLEFTOVER_SIZE :
            softreg_req_addr == 32'h270 ? vBURSTS_WHEN_DONE :
            softreg_req_addr == 32'h278 ? vo_when_done :
	    64'd12345678 + done_;
	
    softreg_resp_valid_buf <= softreg_req_validR && softreg_req_addr >= 32'h20;
end
assign softreg_resp_data = softreg_resp_data_buf;
assign softreg_resp_valid = softreg_resp_valid_buf;

//wire [63:0] img_offset = img_counter * 64;
//wire [63:0] krnl_offset = krnl_counter * 64;

// READ ADDRESS
wire arvalid_m_ = state >= 4 && !img_reqs_done && read_creds != 0;
/*always @(posedge clk) begin
    if (arready_m && arvalid_m_ && !rst && !done_) begin
        img_reqs <= img_reqs + 1;
    end
end*/
always @(*) begin
    arid_m <= 0;
    araddr_m <= image_addr + img_reqs * 4096;
    arlen_m <= (img_reqs == vPAGES - 1 ? vLEFTOVER_SIZE : BURSTS_PER_PAGE) - 1;
    arsize_m <= $clog2(TRANS_SIZE/8);
    arvalid_m <= arvalid_m_;

    if (rvalid_m) begin
        if (rready_m_) begin
            //$write("reading: ");
        end
        //$display("got img part %h", rdata_m);
    end
    if (arvalid_m_) begin
        //$display("sneding req, img_reqs = %d", img_reqs);
    end
end
// READ DATA
always @(*) begin
	rready_m <= rready_m_;
end
// WRITE ADDRESS
wire awvalid_m_ = state >= 4 && !img_writes_done && write_creds != 0;
/*always @(posedge clk) begin
    if (awready_m && awvalid_m_ && !rst && !done_) begin
        img_writes <= img_writes + 1;
    end
end*/
always @(*) begin
    awid_m <= 0;
    awaddr_m <= image_write_addr + img_writes * 4096;
    awlen_m <= (img_writes == vPAGES - 1 ? vLEFTOVER_SIZE : BURSTS_PER_PAGE) - 1;
    awsize_m <= $clog2(TRANS_SIZE/8);
    awvalid_m <= awvalid_m_;
end
// WRITE DATA
always @(*) begin
    wid_m <= 0;
    wdata_m <= out_buf_q;
    wstrb_m <= 64'hFFFFFFFFFFFFFFFF;
    wlast_m <= outs_mod_bpp == (outs_done == vPAGES - 1 ? vLEFTOVER_SIZE : BURSTS_PER_PAGE) - 1;
    wvalid_m <= !out_buf_empty;
end
// WRITE ACK
initial begin
    bready_m <= 1;
end
endmodule

