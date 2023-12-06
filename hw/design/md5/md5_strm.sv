import ShellTypes::*;

module MD5_Strm (
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


//// Input data stream
// state
reg [33:0] id_words;
reg [47:0] id_cyc;
reg [47:0] id_rnv;
reg [47:0] id_vnr;

// FIFO signals
wire idf_wrreq = axis_s.tvalid && (id_words > 0);
wire [517:0] idf_din = {axis_s.tdata, axis_s.tid, axis_s.tlast};
wire idf_full;
wire idf_rdreq;
wire [517:0] idf_dout;
wire idf_empty;
assign axis_s.tready = !idf_full && (id_words > 0);

// logic
always @(posedge clk) begin
	if (axis_s.tready && axis_s.tvalid) begin
		id_words <= id_words - 1;
	end
	
	if (id_words > 0) begin
		id_cyc <= id_cyc + 1;
	end
	
	if (axis_s.tready && !axis_s.tvalid) begin
		id_rnv <= id_rnv + 1;
	end
	
	if (axis_s.tvalid && !axis_s.tready) begin
		id_vnr <= id_vnr + 1;
	end
	
	if (softreg_write && (softreg_req.addr == 32'h20)) begin
		id_words <= softreg_req.data;
		id_cyc <= 0;
		id_rnv <= 0;
		id_vnr <= 0;
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
reg [47:0] od_cyc;
reg [47:0] od_rnv;
reg [47:0] od_vnr;
reg passthru;

// FIFO signals
wire odf_wrreq;
wire [517:0] odf_din;
wire odf_full;
wire odf_rdreq;
wire [517:0] odf_dout;
wire odf_empty;

assign idf_rdreq = !odf_full;
assign odf_din[0] = idf_dout[0];
assign odf_din[5:1] = id_map[idf_dout[5:1]];
assign odf_din[517:6] = idf_dout[517:6];
assign odf_wrreq = passthru && !idf_empty;

// logic
assign odf_rdreq = axis_m.tready;
assign axis_m.tlast = odf_dout[0];
assign axis_m.tdest = odf_dout[5:1];
assign axis_m.tdata = odf_dout[517:6];
assign axis_m.tvalid = !odf_empty;

always @(posedge clk) begin
	if (axis_m.tready && axis_m.tvalid) begin
		od_words <= od_words - 1;
	end
	
	if (od_words > 0) begin
		od_cyc <= od_cyc + 1;
	end
	
	if (axis_m.tready && !axis_m.tvalid) begin
		od_rnv <= od_rnv + 1;
	end
	
	if (axis_m.tvalid && !axis_m.tready) begin
		od_vnr <= od_vnr + 1;
	end
	
	if (softreg_write && (softreg_req.addr == 32'h20)) begin
		if (passthru) begin
			od_words <= softreg_req.data;
			od_cyc <= 0;
			od_rnv <= 0;
			od_vnr <= 0;
		end
	end
	
	if (softreg_write && (softreg_req.addr == 32'h30)) begin
		passthru <= softreg_req.data;
	end
	
	if (rst) begin
		od_words <= 0;
		passthru <= 1;
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


//// MD5 core
// state and signals
reg [63:0] md5_valid;
reg [63:0] md5_words;
wire md5_in_valid = !idf_empty && !odf_full;
wire md5_out_valid = md5_valid[63];

reg [31:0] md5_a_reg;
reg [31:0] md5_b_reg;
reg [31:0] md5_c_reg;
reg [31:0] md5_d_reg;
wire [31:0] md5_a;
wire [31:0] md5_b;
wire [31:0] md5_c;
wire [31:0] md5_d;
wire [511:0] md5_chunk = idf_dout[517:6];

// logic
always @(posedge clk) begin
	md5_valid <= {md5_valid[62:0], md5_in_valid};
	
	if (md5_out_valid) begin
		md5_a_reg <= md5_a_reg + md5_a;
		md5_b_reg <= md5_b_reg + md5_b;
		md5_c_reg <= md5_c_reg + md5_c;
		md5_d_reg <= md5_d_reg + md5_d;
		md5_words <= md5_words + 1;
	end
	
	if (softreg_write && (softreg_req.addr == 32'h20)) begin
		md5_a_reg <= 0;
		md5_b_reg <= 0;
		md5_c_reg <= 0;
		md5_d_reg <= 0;
		md5_words <= 0;
	end
	
	if (rst) begin
		md5_valid <= 0;
	end
end

// instantiation
Md5Core m (
	.clk(clk),
	.wb(md5_chunk),
	.a0('h67452301),
	.b0('hefcdab89),
	.c0('h98badcfe),
	.d0('h10325476),
	.a64(md5_a),
	.b64(md5_b),
	.c64(md5_c),
	.d64(md5_d)
);


//// SoftReg output
always @(posedge clk) begin
	softreg_resp.valid <= softreg_read;
	case (softreg_req.addr)
		32'h00: softreg_resp.data <= {md5_b_reg, md5_a_reg};
		32'h08: softreg_resp.data <= {md5_d_reg, md5_c_reg};
		32'h10: softreg_resp.data <= md5_words;
		// 32'h18: passthru?
		32'h20: softreg_resp.data <= od_words;
		32'h28: softreg_resp.data <= id_words;
		32'h30: softreg_resp.data <= od_cyc;
		32'h38: softreg_resp.data <= id_cyc;
		32'h40: softreg_resp.data <= od_rnv;
		32'h48: softreg_resp.data <= id_rnv;
		32'h50: softreg_resp.data <= od_vnr;
		32'h58: softreg_resp.data <= id_vnr;
		default: begin end
	endcase
	
	if (rst) begin
		softreg_resp.valid <= 0;
		softreg_resp.data <= 0;
	end
end

endmodule
