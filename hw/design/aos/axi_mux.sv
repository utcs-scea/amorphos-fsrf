module axi_mux_2m #(
	parameter SR_ADDR = 'h10
) (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	
	axi_bus_t.master axi_m0,
	axi_bus_t.master axi_m1,
	axi_bus_t.slave axi_s
);

reg mux = 1;
reg mux_next = 1;
always @(posedge clk) begin
	mux <= mux_next;
	if (sr_req.valid && sr_req.isWrite && (sr_req.addr == SR_ADDR))
		mux_next <= sr_req.data[0];
end

always_comb begin
	axi_s.arid = mux ? axi_m1.arid : axi_m0.arid;
	axi_s.araddr = mux ? axi_m1.araddr : axi_m0.araddr;
	axi_s.arlen = mux ? axi_m1.arlen : axi_m0.arlen;
	axi_s.arsize = mux ? axi_m1.arsize : axi_m0.arsize;
	axi_s.arvalid = mux ? axi_m1.arvalid : axi_m0.arvalid;
	axi_m0.arready = mux ? 0 : axi_s.arready;
	axi_m1.arready = mux ? axi_s.arready : 0;
	
	axi_m0.rid = mux ? 0 : axi_s.rid;
	axi_m0.rdata = mux ? 0 : axi_s.rdata;
	axi_m0.rresp = mux ? 0 : axi_s.rresp;
	axi_m0.rlast = mux ? 0 : axi_s.rlast;
	axi_m0.rvalid = mux ? 0 : axi_s.rvalid;
	axi_m1.rid = mux ? axi_s.rid : 0;
	axi_m1.rdata = mux ? axi_s.rdata : 0;
	axi_m1.rresp = mux ? axi_s.rresp : 0;
	axi_m1.rlast = mux ? axi_s.rlast : 0;
	axi_m1.rvalid = mux ? axi_s.rvalid : 0;
	axi_s.rready = mux ? axi_m1.rready : axi_m0.rready;
	
	axi_s.awid = mux ? axi_m1.awid : axi_m0.awid;
	axi_s.awaddr = mux ? axi_m1.awaddr : axi_m0.awaddr;
	axi_s.awlen = mux ? axi_m1.awlen : axi_m0.awlen;
	axi_s.awsize = mux ? axi_m1.awsize : axi_m0.awsize;
	axi_s.awvalid = mux ? axi_m1.awvalid : axi_m0.awvalid;
	axi_m0.awready = mux ? 0 : axi_s.awready;
	axi_m1.awready = mux ? axi_s.awready : 0;
	
	axi_s.wdata = mux ? axi_m1.wdata : axi_m0.wdata;
	axi_s.wstrb = mux ? axi_m1.wstrb : axi_m0.wstrb;
	axi_s.wlast = mux ? axi_m1.wlast : axi_m0.wlast;
	axi_s.wvalid = mux ? axi_m1.wvalid : axi_m0.wvalid;
	axi_m0.wready = mux ? 0 : axi_s.wready;
	axi_m1.wready = mux ? axi_s.wready : 0;
	
	axi_m0.bid = mux ? 0 : axi_s.bid;
	axi_m0.bresp = mux ? 0 : axi_s.bresp;
	axi_m0.bvalid = mux ? 0 : axi_s.bvalid;
	axi_m1.bid = mux ? axi_s.bid : 0;
	axi_m1.bresp = mux ? axi_s.bresp : 0;
	axi_m1.bvalid = mux ? axi_s.bvalid : 0;
	axi_s.bready = mux ? axi_m1.bready : axi_m0.bready;
end

endmodule


module axi_mux_2s #(
	parameter SR_ADDR = 'h10
) (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	
	axi_bus_t.master axi_m,
	axi_bus_t.slave axi_s0,
	axi_bus_t.slave axi_s1
);

reg mux = 1;
reg mux_next = 1;
always @(posedge clk) begin
	mux <= mux_next;
	if (sr_req.valid && sr_req.isWrite && (sr_req.addr == SR_ADDR))
		mux_next <= sr_req.data[0];
end

always_comb begin
	axi_s0.arid = mux ? 0 : axi_m.arid;
	axi_s0.araddr = mux ? 0 : axi_m.araddr;
	axi_s0.arlen = mux ? 0 : axi_m.arlen;
	axi_s0.arsize = mux ? 0 : axi_m.arsize;
	axi_s0.arvalid = mux ? 0 : axi_m.arvalid;
	axi_s1.arid = mux ? axi_m.arid : 0;
	axi_s1.araddr = mux ? axi_m.araddr : 0;
	axi_s1.arlen = mux ? axi_m.arlen : 0;
	axi_s1.arsize = mux ? axi_m.arsize : 0;
	axi_s1.arvalid = mux ? axi_m.arvalid : 0;
	axi_m.arready = mux ? axi_s1.arready : axi_s0.arready;
	
	axi_m.rid = mux ? axi_s1.rid : axi_s0.rid;
	axi_m.rdata = mux ? axi_s1.rdata : axi_s0.rdata;
	axi_m.rresp = mux ? axi_s1.rresp : axi_s0.rresp;
	axi_m.rlast = mux ? axi_s1.rlast : axi_s0.rlast;
	axi_m.rvalid = mux ? axi_s1.rvalid : axi_s0.rvalid;
	axi_s0.rready = mux ? 0 : axi_m.rready;
	axi_s1.rready = mux ? axi_m.rready : 0;
	
	axi_s0.awid = mux ? 0 : axi_m.awid;
	axi_s0.awaddr = mux ? 0 : axi_m.awaddr;
	axi_s0.awlen = mux ? 0 : axi_m.awlen;
	axi_s0.awsize = mux ? 0 : axi_m.awsize;
	axi_s0.awvalid = mux ? 0 : axi_m.awvalid;
	axi_s1.awid = mux ? axi_m.awid : 0;
	axi_s1.awaddr = mux ? axi_m.awaddr : 0;
	axi_s1.awlen = mux ? axi_m.awlen : 0;
	axi_s1.awsize = mux ? axi_m.awsize : 0;
	axi_s1.awvalid = mux ? axi_m.awvalid : 0;
	axi_m.awready = mux ? axi_s1.awready : axi_s0.awready;
	
	axi_s0.wdata = mux ? 0 : axi_m.wdata;
	axi_s0.wstrb = mux ? 0 : axi_m.wstrb;
	axi_s0.wlast = mux ? 0 : axi_m.wlast;
	axi_s0.wvalid = mux ? 0 : axi_m.wvalid;
	axi_s1.wdata = mux ? axi_m.wdata : 0;
	axi_s1.wstrb = mux ? axi_m.wstrb : 0;
	axi_s1.wlast = mux ? axi_m.wlast : 0;
	axi_s1.wvalid = mux ? axi_m.wvalid : 0;
	axi_m.wready = mux ? axi_s1.wready : axi_s0.wready;
	
	axi_m.bid = mux ? axi_s1.bid : axi_s0.bid;
	axi_m.bresp = mux ? axi_s1.bresp : axi_s0.bresp;
	axi_m.bvalid = mux ? axi_s1.bvalid : axi_s0.bvalid;
	axi_s0.bready = mux ? 0 : axi_m.bready;
	axi_s1.bready = mux ? axi_m.bready : 0;
end

endmodule
