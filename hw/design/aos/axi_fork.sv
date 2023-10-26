module axi_split #(
	parameter EN_WR = 1,
	parameter EN_RD = 0,
	parameter THE_BIT = 48
) (
	input clk,
	input rst_n,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave axi_m0,
	axi_bus_t.slave axi_m1
);
localparam FIFO_LD = 6;

// TODO: add support for ID != 0

generate if (EN_WR) begin
	// W sel FIFO
	logic wsf_wrreq;
	logic wsf_data;
	logic wsf_full;
	logic wsf_q;
	logic wsf_empty;
	logic wsf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(1),
		.LOG_DEPTH(1)
	) w_sel_fifo (
		.clock(clk),
		.reset_n(rst_n),
		.wrreq(wsf_wrreq),
		.data(wsf_data),
		.full(wsf_full),
		.q(wsf_q),
		.empty(wsf_empty),
		.rdreq(wsf_rdreq)
	);

	// B sel FIFO
	logic bsf_wrreq;
	logic bsf_data;
	logic bsf_full;
	logic bsf_q;
	logic bsf_empty;
	logic bsf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(1),
		.LOG_DEPTH(FIFO_LD)
	) b_sel_fifo (
		.clock(clk),
		.reset_n(rst_n),
		.wrreq(bsf_wrreq),
		.data(bsf_data),
		.full(bsf_full),
		.q(bsf_q),
		.empty(bsf_empty),
		.rdreq(bsf_rdreq)
	);

	logic aw_sel, w_sel, b_sel;
	logic aw_rdy, w_rdy, b_rdy;
	always_comb begin
		aw_sel = axi_s.awaddr[THE_BIT];
		aw_rdy = !wsf_full;
		
		axi_m0.awid = axi_s.awid;
		axi_m0.awaddr = axi_s.awaddr;
		axi_m0.awaddr[THE_BIT] = 0;
		axi_m0.awlen = axi_s.awlen;
		axi_m0.awsize = axi_s.awsize;
		axi_m0.awvalid = aw_sel ? 0 : (axi_s.awvalid && aw_rdy);
		axi_m1.awid = axi_s.awid;
		axi_m1.awaddr = axi_s.awaddr;
		axi_m1.awaddr[THE_BIT] = 0;
		axi_m1.awlen = axi_s.awlen;
		axi_m1.awsize = axi_s.awsize;
		axi_m1.awvalid = aw_sel ? (axi_s.awvalid && aw_rdy) : 0;
		axi_s.awready = (aw_sel ? axi_m1.awready : axi_m0.awready) && aw_rdy;
		
		wsf_data = aw_sel;
		wsf_wrreq = axi_s.awready && axi_s.awvalid;
		
		w_sel = wsf_q;
		w_rdy = !wsf_empty && !bsf_full;
		
		axi_m0.wdata = axi_s.wdata;
		axi_m0.wstrb = axi_s.wstrb;
		axi_m0.wlast = axi_s.wlast;
		axi_m0.wvalid = w_sel ? 0 : (axi_s.wvalid && w_rdy);
		axi_m1.wdata = axi_s.wdata;
		axi_m1.wstrb = axi_s.wstrb;
		axi_m1.wlast = axi_s.wlast;
		axi_m1.wvalid = w_sel ? (axi_s.wvalid && w_rdy) : 0;
		axi_s.wready = (w_sel ? axi_m1.wready : axi_m0.wready) && w_rdy;
		
		bsf_data = wsf_q;
		bsf_wrreq = axi_s.wready && axi_s.wvalid && axi_s.wlast;
		wsf_rdreq = axi_s.wready && axi_s.wvalid && axi_s.wlast;
		
		b_sel = bsf_q;
		b_rdy = !bsf_empty;
		
		axi_s.bid = b_sel ? axi_m1.bid : axi_m0.bid;
		axi_s.bresp = b_sel ? axi_m1.bresp : axi_m0.bresp;
		axi_s.bvalid = (b_sel ? axi_m1.bvalid : axi_m0.bvalid) && b_rdy;
		axi_m0.bready = b_sel ? 0 : (axi_s.bready && b_rdy);
		axi_m1.bready = b_sel ? (axi_s.bready && b_rdy) : 0;
		
		bsf_rdreq = axi_s.bready && axi_s.bvalid;
	end
end endgenerate

generate if (EN_RD) begin
	$error("axi_split read path not implemented");
end endgenerate


endmodule


module axi_merge #(
	parameter EN_WR = 1,
	parameter EN_RD = 0
) (
	input clk,
	input rst_n,
	
	axi_bus_t.master axi_s0,
	axi_bus_t.master axi_s1,
	axi_bus_t.slave axi_m
);
localparam FIFO_LD = 6;

// TODO: add support for ID != 0

generate if (EN_WR) begin
	// W sel FIFO
	logic wsf_wrreq;
	logic wsf_data;
	logic wsf_full;
	logic wsf_q;
	logic wsf_empty;
	logic wsf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(1),
		.LOG_DEPTH(1)
	) w_sel_fifo (
		.clock(clk),
		.reset_n(rst_n),
		.wrreq(wsf_wrreq),
		.data(wsf_data),
		.full(wsf_full),
		.q(wsf_q),
		.empty(wsf_empty),
		.rdreq(wsf_rdreq)
	);

	// B sel FIFO
	logic bsf_wrreq;
	logic bsf_data;
	logic bsf_full;
	logic bsf_q;
	logic bsf_empty;
	logic bsf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(1),
		.LOG_DEPTH(FIFO_LD)
	) b_sel_fifo (
		.clock(clk),
		.reset_n(rst_n),
		.wrreq(bsf_wrreq),
		.data(bsf_data),
		.full(bsf_full),
		.q(bsf_q),
		.empty(bsf_empty),
		.rdreq(bsf_rdreq)
	);
	
	reg sel;
	always_ff @(posedge clk) sel <= sel + 1;
	
	logic aw_sel, w_sel, b_sel;
	logic aw_rdy, w_rdy, b_rdy;
	always_comb begin
		aw_sel = sel ? axi_s1.awvalid : !axi_s0.awvalid;
		aw_rdy = !wsf_full;
		
		axi_m.awid = aw_sel ? axi_s1.awid : axi_s0.awid;
		axi_m.awaddr = aw_sel ? axi_s1.awaddr : axi_s0.awaddr;
		axi_m.awlen = aw_sel ? axi_s1.awlen : axi_s0.awlen;
		axi_m.awsize = aw_sel ? axi_s1.awsize : axi_s0.awsize;
		axi_m.awvalid = (aw_sel ? axi_s1.awvalid : axi_s0.awvalid) && aw_rdy;
		axi_s0.awready = aw_sel ? 0 : (axi_m.awready && aw_rdy);
		axi_s1.awready = aw_sel ? (axi_m.awready && aw_rdy) : 0;
		
		wsf_data = aw_sel;
		wsf_wrreq = axi_m.awready && axi_m.awvalid;
		
		w_sel = wsf_q;
		w_rdy = !wsf_empty && !bsf_full;
		
		axi_m.wdata = w_sel ? axi_s1.wdata : axi_s0.wdata;
		axi_m.wstrb = w_sel ? axi_s1.wstrb : axi_s0.wstrb;
		axi_m.wlast = w_sel ? axi_s1.wlast : axi_s0.wlast;
		axi_m.wvalid = (w_sel ? axi_s1.wvalid : axi_s0.wvalid) && w_rdy;
		axi_s0.wready = w_sel ? 0 : (axi_m.wready && w_rdy);
		axi_s1.wready = w_sel ? (axi_m.wready && w_rdy) : 0;
		
		bsf_data = wsf_q;
		bsf_wrreq = axi_m.wready && axi_m.wvalid && axi_m.wlast;
		wsf_rdreq = axi_m.wready && axi_m.wvalid && axi_m.wlast;
		
		b_sel = bsf_q;
		b_rdy = !bsf_empty;
		
		axi_s0.bid = axi_m.bid;
		axi_s0.bresp = axi_m.bresp;
		axi_s0.bvalid = b_sel ? 0 : (axi_m.bvalid && b_rdy);
		axi_s1.bid = axi_m.bid;
		axi_s1.bresp = axi_m.bresp;
		axi_s1.bvalid = b_sel ? (axi_m.bvalid && b_rdy) : 0;
		axi_m.bready = (b_sel ? axi_s1.bready : axi_s0.bready) && b_rdy;
		
		bsf_rdreq = axi_m.bready && axi_m.bvalid;
	end
end endgenerate


generate if (EN_RD) begin
	// pass through s1 to m
	always_comb begin
		axi_m.arid = axi_s1.arid;
		axi_m.araddr = axi_s1.araddr;
		axi_m.arlen = axi_s1.arlen;
		axi_m.arsize = axi_s1.arsize;
		axi_m.arvalid = axi_s1.arvalid;
		axi_s1.arready = axi_m.arready;
		
		axi_s1.rid = axi_m.rid;
		axi_s1.rdata = axi_m.rdata;
		axi_s1.rresp = axi_m.rresp;
		axi_s1.rlast = axi_m.rlast;
		axi_s1.rvalid = axi_m.rvalid;
		axi_m.rready = axi_s1.rready;
	end
end endgenerate


endmodule
