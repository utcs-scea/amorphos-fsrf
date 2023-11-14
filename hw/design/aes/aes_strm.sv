import ShellTypes::*;

module AES_Strm (
	// User clock and reset
	input  clk,
	input  rst,
	
	// Soft register interface
	input  SoftRegReq   softreg_req,
	output SoftRegResp  softreg_resp,
	
	// Virtual stream interface
	axi_stream_t.slave  axis_m,
	axi_stream_t.master axis_s
);
wire softreg_read = softreg_req.valid && !softreg_req.isWrite;
wire softreg_write = softreg_req.valid && softreg_req.isWrite;


//// AES stream
// state and signals
reg [33:0] aes_words;
reg [6:0] aes_credit;
reg [30:0] aes_valid;
reg [31:0] aes_seq;
reg [255:0] aes_key;
reg [511:0] aes_out_reg;
wire [511:0] aes_out;
wire aes_consume;

// FIFO signals
wire aef_wrreq = aes_valid[0];
wire [511:0] aef_din = aes_out_reg;
wire aef_full;  // unused
wire aef_rdreq;
wire [511:0] aef_dout;
wire aef_empty;

// logic
always @(posedge clk) begin
	aes_valid <= (aes_valid >> 1);
	if ((aes_words > 0) && (aes_credit > 0)) begin
		aes_words <= aes_words - 1;
		aes_valid[30] <= 1;
		aes_seq <= aes_seq + 1;
	end
	if ((aes_words && aes_credit) && aes_consume) begin
		// do nothing
	end else if (aes_words && aes_credit) begin
		aes_credit <= aes_credit - 1;
	end else if (aes_consume) begin
		aes_credit <= aes_credit + 1;
	end else begin
		// do nothing
	end
	aes_out_reg <= aes_out;
	if (softreg_write) begin
		case (softreg_req.addr[6:0])
			32'h00: aes_key[63:0] <= softreg_req.data;
			32'h08: aes_key[127:64] <= softreg_req.data;
			32'h10: aes_key[191:128] <= softreg_req.data;
			32'h18: aes_key[255:192] <= softreg_req.data;
			32'h20: begin
				aes_words <= softreg_req.data;
				aes_seq <= 0;
			end
			default: begin end
		endcase
	end
	
	if (rst) begin
		aes_words <= 0;
		aes_credit <= 32;
		aes_valid <= 0;
		aes_key <= 0;
	end
end

// instantiations
aes_256 aes0 (
	.clk(clk),
	.state({64'h0000000000000000, 30'h00000000, aes_seq, 2'h0}),
	.key(aes_key),
	.out(aes_out[127:0])
);
aes_256 aes1 (
	.clk(clk),
	.state({64'h0000000000000000, 30'h00000000, aes_seq, 2'h1}),
	.key(aes_key),
	.out(aes_out[255:128])
);
aes_256 aes2 (
	.clk(clk),
	.state({64'h0000000000000000, 30'h00000000, aes_seq, 2'h2}),
	.key(aes_key),
	.out(aes_out[383:256])
);
aes_256 aes3 (
	.clk(clk),
	.state({64'h0000000000000000, 30'h00000000, aes_seq, 2'h3}),
	.key(aes_key),
	.out(aes_out[511:384])
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(512),
	.LOG_DEPTH(5)
) aes_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(aef_wrreq),
	.data(aef_din),
	.full(aef_full),
	.rdreq(aef_rdreq),
	.q(aef_dout),
	.empty(aef_empty)
);


//// Input data stream
reg [33:0] id_words;

// FIFO signals
wire idf_wrreq = axis_s.tvalid;
wire [517:0] idf_din = {axis_s.tdata, axis_s.tid, axis_s.tlast};
wire idf_full;
wire idf_rdreq;
wire [517:0] idf_dout;
wire idf_empty;
assign axis_s.tready = !idf_full;

always @(posedge clk) begin
	if (axis_s.tvalid && axis_s.tready) begin
		id_words <= id_words - 1;
	end
	
	if (softreg_write && (softreg_req.addr[6:0] == 32'h20)) begin
		id_words <= softreg_req.data;
	end
	
	if (rst) begin
		id_words <= 0;
	end
end

// instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(512+5+1),
	.LOG_DEPTH(5)
) input_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(idf_wrreq),
	.data(idf_din),
	.full(idf_full),
	.rdreq(idf_rdreq),
	.q(idf_dout),
	.empty(idf_empty)
);


//// ID map
reg [4:0] id_map [31:0];

always @(posedge clk) begin
	if (softreg_write) begin
		if (softreg_req.addr[8]) begin
			id_map[softreg_req.addr[7:3]] <= softreg_req.data;
		end
	end
end


//// Output data stream
// state
reg [33:0] od_words;

// FIFO signals
wire odf_wrreq = !aef_empty && !idf_empty;
wire [517:0] odf_din;
wire odf_full;
wire odf_rdreq = axis_m.tready;
wire [517:0] odf_dout;
wire odf_empty;

assign odf_din[0] = idf_dout[0];
assign odf_din[5:1] = id_map[idf_dout[5:1]];
assign odf_din[517:6] = aef_dout ^ idf_dout[517:6];

// misc signals
assign aes_consume = !aef_empty && !idf_empty && !odf_full;
assign aef_rdreq = !idf_empty && !odf_full;
assign idf_rdreq = !aef_empty && !odf_full;

// logic
assign axis_m.tlast = odf_dout[0];
assign axis_m.tdest = odf_dout[5:1];
assign axis_m.tdata = odf_dout[517:6];
assign axis_m.tvalid = !odf_empty;

always @(posedge clk) begin
	if (!odf_empty && axis_m.tready) begin
		od_words <= od_words - 1;
	end
	
	if (softreg_write && (softreg_req.addr[6:0] == 32'h20)) begin
		od_words <= softreg_req.data;
	end
	
	if (rst) begin
		od_words <= 0;
	end
end

// instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(512+5+1),
	.LOG_DEPTH(5)
) output_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(odf_wrreq),
	.data(odf_din),
	.full(odf_full),
	.rdreq(odf_rdreq),
	.q(odf_dout),
	.empty(odf_empty)
);


//// SoftReg output
always @(posedge clk) begin
	softreg_resp.valid <= softreg_read;
	softreg_resp.data <= od_words;
	
	if (rst) begin
		softreg_resp.valid <= 0;
		softreg_resp.data <= 0;
	end
end


endmodule
