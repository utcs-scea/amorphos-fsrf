// SystemVerilog implementation of the HPCC RandomAccess benchmark
// By Joshua Landgraf

module RandomAccess (
	// User clock and reset
	input  clk,
	input  rst,
	
	// Virtual memory interface
	axi_bus_t.slave axi_m,
	
	// Soft register interface
	input  SoftRegReq   softreg_req,
	output SoftRegResp  softreg_resp
);

// I/O and control logic
logic [63:0] base_addr;
logic [63:0] m;
logic [63:0] mmo;
logic [63:0] cyc;
logic start;
logic done;

logic softreg_read = softreg_req.valid && !softreg_req.isWrite;
logic softreg_write = softreg_req.valid && softreg_req.isWrite;

always @(posedge clk) begin
	if (!done) cyc <= cyc + 1;
	start <= 0;
	
	if (softreg_write) begin
		case (softreg_req.addr)
			32'h00: base_addr <= softreg_req.data;
			32'h10: begin
				m <= softreg_req.data;
				mmo <= softreg_req.data - 1;
				cyc <= 1;
				start <= 1;
			end
		endcase
	end
	
	softreg_resp.valid <= softreg_read;
	softreg_resp.data <= cyc;
end


// Generate random addresses and data
logic raf_wrreq;
logic [63:0] raf_din;
logic raf_full;
logic raf_rdreq;
logic [63:0] raf_dout;
logic raf_empty;

logic rmf_wrreq;
logic [2:0] rmf_din;
logic rmf_full;
logic rmf_rdreq;
logic [2:0] rmf_dout;
logic rmf_empty;

logic waf_wrreq;
logic [63:0] waf_din;
logic waf_full;
logic waf_rdreq;
logic [63:0] waf_dout;
logic waf_empty;

logic wmf_wrreq;
logic [2:0] wmf_din;
logic wmf_full;
logic wmf_rdreq;
logic [2:0] wmf_dout;
logic wmf_empty;

logic rngf_wrreq;
logic [63:0] rngf_din;
logic rngf_full;
logic rngf_rdreq;
logic [63:0] rngf_dout;
logic rngf_empty;

logic [63:0] mu_rng;
logic [63:0] rng_val;
logic rng_inc;

always @(*) begin
	rng_inc = !raf_full && !rmf_full && !waf_full && !wmf_full && !rngf_full && (mu_rng > 0);
	
	raf_wrreq = rng_inc;
	rmf_wrreq = rng_inc;
	waf_wrreq = rng_inc;
	wmf_wrreq = rng_inc;
	rngf_wrreq = rng_inc;
	
	raf_din = base_addr + ((rng_val & mmo) << 3);
	rmf_din = rng_val & mmo;
	waf_din = base_addr + ((rng_val & mmo) << 3);
	wmf_din = rng_val & mmo;
	rngf_din = rng_val;
end

always @(posedge clk) begin
	reg [63:0] v = rng_val[63] ? 7 : 0;
	reg [63:0] rng_next = (rng_val << 1) ^ v;
	
	if (rng_inc) begin
		mu_rng <= mu_rng - 1;
		rng_val <= rng_next;
	end
	
	if (start) begin
		mu_rng <= 4*m;
		rng_val <= 2;
	end
end

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(5)
) ra_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(raf_wrreq),
	.data(raf_din),
	.full(raf_full),
	.rdreq(raf_rdreq),
	.q(raf_dout),
	.empty(raf_empty)
);

HullFIFO #(
	.TYPE(0),
	.WIDTH(3),
	.LOG_DEPTH(6)
) rm_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rmf_wrreq),
	.data(rmf_din),
	.full(rmf_full),
	.rdreq(rmf_rdreq),
	.q(rmf_dout),
	.empty(rmf_empty)
);

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(6)
) wa_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(waf_wrreq),
	.data(waf_din),
	.full(waf_full),
	.rdreq(waf_rdreq),
	.q(waf_dout),
	.empty(waf_empty)
);

HullFIFO #(
	.TYPE(0),
	.WIDTH(3),
	.LOG_DEPTH(6)
) wm_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wmf_wrreq),
	.data(wmf_din),
	.full(wmf_full),
	.rdreq(wmf_rdreq),
	.q(wmf_dout),
	.empty(wmf_empty)
);

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(6)
) rng_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rngf_wrreq),
	.data(rngf_din),
	.full(rngf_full),
	.rdreq(rngf_rdreq),
	.q(rngf_dout),
	.empty(rngf_empty)
);


// Perform reads, modifies, and writes
logic rdf_wrreq;
logic [63:0] rdf_din;
logic rdf_full;
logic rdf_rdreq;
logic [63:0] rdf_dout;
logic rdf_empty;

logic wdf_wrreq;
logic [63:0] wdf_din;
logic wdf_full;
logic wdf_rdreq;
logic [63:0] wdf_dout;
logic wdf_empty;

always @(*) begin
	axi_m.arid = 0;
	axi_m.araddr = raf_dout;
	axi_m.arlen = 0;
	axi_m.arsize = 3'b011;
	axi_m.arvalid = !raf_empty;
	raf_rdreq = axi_m.arready;
	
	rdf_wrreq = !rmf_empty && axi_m.rvalid;
	rdf_din = axi_m.rdata[rmf_dout*64 +: 64];
	rmf_rdreq = !rdf_full && axi_m.rvalid;
	axi_m.rready = !rmf_empty && !rdf_full;
	
	wdf_wrreq = !rdf_empty && !rngf_empty;
	wdf_din = rdf_dout ^ rngf_dout;
	rdf_rdreq = !wdf_full && !rngf_empty;
	rngf_rdreq = !rdf_empty && !wdf_full;
	
	axi_m.awid = 0;
	axi_m.awaddr = waf_dout;
	axi_m.awlen = 0;
	axi_m.awsize = 3'b011;
	axi_m.awvalid = !waf_empty;
	waf_rdreq = axi_m.awready;
	
	axi_m.wdata = {8{wdf_dout}};
	axi_m.wstrb = 8'hFF << (wmf_dout*8);
	axi_m.wlast = 1;
	axi_m.wvalid = !wdf_empty && !wmf_empty;
	wdf_rdreq = axi_m.wready && !wmf_empty;
	wmf_rdreq = axi_m.wready && !wdf_empty;
end

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(5)
) rd_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_din),
	.full(rdf_full),
	.rdreq(rdf_rdreq),
	.q(rdf_dout),
	.empty(rdf_empty)
);

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(5)
) wd_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_din),
	.full(wdf_full),
	.rdreq(wdf_rdreq),
	.q(wdf_dout),
	.empty(wdf_empty)
);


// Complete writes
logic [63:0] mu_write = 0;

assign done = mu_write == 0;
assign axi_m.bready = 1;

always @(posedge clk) begin
	if (start) mu_write <= 4*m;
	
	if (axi_m.bvalid) mu_write <= mu_write - 1;
end

endmodule

