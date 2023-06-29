module cy_stripe #(
	parameter INIT_MODE = 0,
	parameter SR_ADDR = 'h30
) (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	
	axi_bus_t.master phys_m,
	axi_bus_t.slave  phys_s
);

// state
reg [1:0] mode = INIT_MODE;

reg [63:0] ra, wa;
reg [63:0] raddr, waddr;
always_comb begin
	ra = phys_m.araddr;
	wa = phys_m.awaddr;
	
	raddr = ra;
	case (mode)
		1: raddr = {28'h0, ra[20:19], ra[35:21], ra[18:0]};
		2: raddr = {28'h0, ra[21:20], ra[35:22], ra[19:0]};
	endcase
	
	waddr = wa;
	case (mode)
		1: waddr = {28'h0, wa[20:19], wa[35:21], wa[18:0]};
		2: waddr = {28'h0, wa[21:20], wa[35:22], wa[19:0]};
	endcase
	
	phys_s.arid = phys_m.arid;
	phys_s.araddr = raddr;
	phys_s.arlen = phys_m.arlen;
	phys_s.arsize = phys_m.arsize;
	phys_s.arvalid = phys_m.arvalid;
	phys_m.arready = phys_s.arready;
	
	phys_m.rid = phys_s.rid;
	phys_m.rdata = phys_s.rdata;
	phys_m.rresp = phys_s.rresp;
	phys_m.rlast = phys_s.rlast;
	phys_m.ruser = phys_s.ruser;
	phys_m.rvalid = phys_s.rvalid;
	phys_s.rready = phys_m.rready;
	
	phys_s.awid = phys_m.awid;
	phys_s.awaddr = waddr;
	phys_s.awlen = phys_m.awlen;
	phys_s.awsize = phys_m.awsize;
	phys_s.awvalid = phys_m.awvalid;
	phys_m.awready = phys_s.awready;
	
	phys_s.wdata = phys_m.wdata;
	phys_s.wstrb = phys_m.wstrb;
	phys_s.wlast = phys_m.wlast;
	phys_s.wuser = phys_m.wuser;
	phys_s.wvalid = phys_m.wvalid;
	phys_m.wready = phys_s.wready;
	
	phys_m.bid = phys_s.bid;
	phys_m.bresp = phys_s.bresp;
	phys_m.bvalid = phys_s.bvalid;
	phys_s.bready = phys_m.bready;
end

always @(posedge clk) begin
	if (sr_req.valid && sr_req.isWrite && (sr_req.addr == SR_ADDR))
		mode <= sr_req.data;
end

endmodule
