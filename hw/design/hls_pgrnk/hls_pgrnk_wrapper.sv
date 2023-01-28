module HLSPgRnkWrapper
(
	// User clock and reset
	input  clk,
	input  rst,
	
	// Virtual memory interface
	axi_bus_t.slave axi_m,
	
	// Soft register interface
	input  SoftRegReq   softreg_req,
	output SoftRegResp  softreg_resp
);

// Buffer AW control channel
wire awf_wrreq = softreg_req.valid && softreg_req.isWrite;
wire [31:0] awf_data = softreg_req.addr;
wire awf_full;
wire [31:0] awf_q;
wire awf_empty;
wire awf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(32),
	.LOG_DEPTH(2)
) aw_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(awf_wrreq),
	.data(awf_data),
	.full(awf_full),
	.q(awf_q),
	.empty(awf_empty),
	.rdreq(awf_rdreq)
);

// Buffer W control channel
wire wf_wrreq = softreg_req.valid && softreg_req.isWrite;
wire [63:0] wf_data = softreg_req.data;
wire wf_full;
wire [63:0] wf_q;
wire wf_empty;
wire wf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(2)
) w_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wf_wrreq),
	.data(wf_data),
	.full(wf_full),
	.q(wf_q),
	.empty(wf_empty),
	.rdreq(wf_rdreq)
);

// Buffer AR control channel
wire arf_wrreq = softreg_req.valid && !softreg_req.isWrite;
wire [31:0] arf_data = softreg_req.addr;
wire arf_full;
wire [31:0] arf_q;
wire arf_empty;
wire arf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(32),
	.LOG_DEPTH(2)
) ar_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(arf_wrreq),
	.data(arf_data),
	.full(arf_full),
	.q(arf_q),
	.empty(arf_empty),
	.rdreq(arf_rdreq)
);

// AXI channel mux logic
reg [1:0]  arsel;

reg        arvalid [2:0];
reg [63:0] araddr  [2:0];
reg [15:0] arid    [2:0];
reg [7:0]  arlen   [2:0];
reg [2:0]  arsize  [2:0];

reg        rready  [2:0];

always_comb begin
	if (arvalid[0]) begin
		arsel = 0;
	end else if (arvalid[1]) begin
		arsel = 1;
	end else begin
		arsel = 2;
	end

	axi_m.arvalid = arvalid[arsel];
	axi_m.araddr = araddr[arsel];
	axi_m.arid = {arid[arsel][15:2], arsel};
	axi_m.arlen = arlen[arsel];
	axi_m.arsize = arsize[arsel];
	
	axi_m.rready = rready[axi_m.rid[1:0]];
end

pgrnk pr (
	.ap_clk(clk),
	.ap_rst_n(~rst),
	
	.m_axi_gmem0_AWVALID(),
	.m_axi_gmem0_AWREADY(0),
	.m_axi_gmem0_AWADDR(),
	.m_axi_gmem0_AWID(),
	.m_axi_gmem0_AWLEN(),
	.m_axi_gmem0_AWSIZE(),
	.m_axi_gmem0_AWBURST(),
	.m_axi_gmem0_AWLOCK(),
	.m_axi_gmem0_AWCACHE(),
	.m_axi_gmem0_AWPROT(),
	.m_axi_gmem0_AWQOS(),
	.m_axi_gmem0_AWREGION(),
	.m_axi_gmem0_AWUSER(),
	
	.m_axi_gmem0_WVALID(),
	.m_axi_gmem0_WREADY(0),
	.m_axi_gmem0_WDATA(),
	.m_axi_gmem0_WSTRB(),
	.m_axi_gmem0_WLAST(),
	.m_axi_gmem0_WID(),
	.m_axi_gmem0_WUSER(),
	
	.m_axi_gmem0_ARVALID(arvalid[0]),
	.m_axi_gmem0_ARREADY(axi_m.arready && (arsel == 0)),
	.m_axi_gmem0_ARADDR(araddr[0]),
	.m_axi_gmem0_ARID(arid[0]),
	.m_axi_gmem0_ARLEN(arlen[0]),
	.m_axi_gmem0_ARSIZE(arsize[0]),
	.m_axi_gmem0_ARBURST(),
	.m_axi_gmem0_ARLOCK(),
	.m_axi_gmem0_ARCACHE(),
	.m_axi_gmem0_ARPROT(),
	.m_axi_gmem0_ARQOS(),
	.m_axi_gmem0_ARREGION(),
	.m_axi_gmem0_ARUSER(),
	
	.m_axi_gmem0_RVALID(axi_m.rvalid && (axi_m.rid[1:0] == 0)),
	.m_axi_gmem0_RREADY(rready[0]),
	.m_axi_gmem0_RDATA(axi_m.rdata),
	.m_axi_gmem0_RLAST(axi_m.rlast),
	.m_axi_gmem0_RID({2'b00, axi_m.rid[15:2]}),
	.m_axi_gmem0_RUSER(0),
	.m_axi_gmem0_RRESP(axi_m.rresp),
	
	.m_axi_gmem0_BVALID(0),
	.m_axi_gmem0_BREADY(),
	.m_axi_gmem0_BRESP(0),
	.m_axi_gmem0_BID(0),
	.m_axi_gmem0_BUSER(0),

	.m_axi_gmem1_AWVALID(),
	.m_axi_gmem1_AWREADY(0),
	.m_axi_gmem1_AWADDR(),
	.m_axi_gmem1_AWID(),
	.m_axi_gmem1_AWLEN(),
	.m_axi_gmem1_AWSIZE(),
	.m_axi_gmem1_AWBURST(),
	.m_axi_gmem1_AWLOCK(),
	.m_axi_gmem1_AWCACHE(),
	.m_axi_gmem1_AWPROT(),
	.m_axi_gmem1_AWQOS(),
	.m_axi_gmem1_AWREGION(),
	.m_axi_gmem1_AWUSER(),
	
	.m_axi_gmem1_WVALID(),
	.m_axi_gmem1_WREADY(0),
	.m_axi_gmem1_WDATA(),
	.m_axi_gmem1_WSTRB(),
	.m_axi_gmem1_WLAST(),
	.m_axi_gmem1_WID(),
	.m_axi_gmem1_WUSER(),
	
	.m_axi_gmem1_ARVALID(arvalid[1]),
	.m_axi_gmem1_ARREADY(axi_m.arready && (arsel == 1)),
	.m_axi_gmem1_ARADDR(araddr[1]),
	.m_axi_gmem1_ARID(arid[1]),
	.m_axi_gmem1_ARLEN(arlen[1]),
	.m_axi_gmem1_ARSIZE(arsize[1]),
	.m_axi_gmem1_ARBURST(),
	.m_axi_gmem1_ARLOCK(),
	.m_axi_gmem1_ARCACHE(),
	.m_axi_gmem1_ARPROT(),
	.m_axi_gmem1_ARQOS(),
	.m_axi_gmem1_ARREGION(),
	.m_axi_gmem1_ARUSER(),
	
	.m_axi_gmem1_RVALID(axi_m.rvalid && (axi_m.rid[1:0] == 1)),
	.m_axi_gmem1_RREADY(rready[1]),
	.m_axi_gmem1_RDATA(axi_m.rdata),
	.m_axi_gmem1_RLAST(axi_m.rlast),
	.m_axi_gmem1_RID({2'b00, axi_m.rid[15:2]}),
	.m_axi_gmem1_RUSER(0),
	.m_axi_gmem1_RRESP(axi_m.rresp),
	
	.m_axi_gmem1_BVALID(0),
	.m_axi_gmem1_BREADY(),
	.m_axi_gmem1_BRESP(0),
	.m_axi_gmem1_BID(0),
	.m_axi_gmem1_BUSER(0),

	.m_axi_gmem2_AWVALID(),
	.m_axi_gmem2_AWREADY(0),
	.m_axi_gmem2_AWADDR(),
	.m_axi_gmem2_AWID(),
	.m_axi_gmem2_AWLEN(),
	.m_axi_gmem2_AWSIZE(),
	.m_axi_gmem2_AWBURST(),
	.m_axi_gmem2_AWLOCK(),
	.m_axi_gmem2_AWCACHE(),
	.m_axi_gmem2_AWPROT(),
	.m_axi_gmem2_AWQOS(),
	.m_axi_gmem2_AWREGION(),
	.m_axi_gmem2_AWUSER(),
	
	.m_axi_gmem2_WVALID(),
	.m_axi_gmem2_WREADY(0),
	.m_axi_gmem2_WDATA(),
	.m_axi_gmem2_WSTRB(),
	.m_axi_gmem2_WLAST(),
	.m_axi_gmem2_WID(),
	.m_axi_gmem2_WUSER(),
	
	.m_axi_gmem2_ARVALID(arvalid[2]),
	.m_axi_gmem2_ARREADY(axi_m.arready && (arsel == 2)),
	.m_axi_gmem2_ARADDR(araddr[2]),
	.m_axi_gmem2_ARID(arid[2]),
	.m_axi_gmem2_ARLEN(arlen[2]),
	.m_axi_gmem2_ARSIZE(arsize[2]),
	.m_axi_gmem2_ARBURST(),
	.m_axi_gmem2_ARLOCK(),
	.m_axi_gmem2_ARCACHE(),
	.m_axi_gmem2_ARPROT(),
	.m_axi_gmem2_ARQOS(),
	.m_axi_gmem2_ARREGION(),
	.m_axi_gmem2_ARUSER(),
	
	.m_axi_gmem2_RVALID(axi_m.rvalid && (axi_m.rid[1:0] == 2)),
	.m_axi_gmem2_RREADY(rready[2]),
	.m_axi_gmem2_RDATA(axi_m.rdata),
	.m_axi_gmem2_RLAST(axi_m.rlast),
	.m_axi_gmem2_RID({2'b00, axi_m.rid[15:2]}),
	.m_axi_gmem2_RUSER(0),
	.m_axi_gmem2_RRESP(axi_m.rresp),
	
	.m_axi_gmem2_BVALID(0),
	.m_axi_gmem2_BREADY(),
	.m_axi_gmem2_BRESP(0),
	.m_axi_gmem2_BID(0),
	.m_axi_gmem2_BUSER(0),

	.m_axi_gmem3_AWVALID(axi_m.awvalid),
	.m_axi_gmem3_AWREADY(axi_m.awready),
	.m_axi_gmem3_AWADDR(axi_m.awaddr),
	.m_axi_gmem3_AWID(axi_m.awid),
	.m_axi_gmem3_AWLEN(axi_m.awlen),
	.m_axi_gmem3_AWSIZE(axi_m.awsize),
	.m_axi_gmem3_AWBURST(),
	.m_axi_gmem3_AWLOCK(),
	.m_axi_gmem3_AWCACHE(),
	.m_axi_gmem3_AWPROT(),
	.m_axi_gmem3_AWQOS(),
	.m_axi_gmem3_AWREGION(),
	.m_axi_gmem3_AWUSER(),
	
	.m_axi_gmem3_WVALID(axi_m.wvalid),
	.m_axi_gmem3_WREADY(axi_m.wready),
	.m_axi_gmem3_WDATA(axi_m.wdata),
	.m_axi_gmem3_WSTRB(axi_m.wstrb),
	.m_axi_gmem3_WLAST(axi_m.wlast),
	.m_axi_gmem3_WID(),
	.m_axi_gmem3_WUSER(),
	
	.m_axi_gmem3_ARVALID(),
	.m_axi_gmem3_ARREADY(0),
	.m_axi_gmem3_ARADDR(),
	.m_axi_gmem3_ARID(),
	.m_axi_gmem3_ARLEN(),
	.m_axi_gmem3_ARSIZE(),
	.m_axi_gmem3_ARBURST(),
	.m_axi_gmem3_ARLOCK(),
	.m_axi_gmem3_ARCACHE(),
	.m_axi_gmem3_ARPROT(),
	.m_axi_gmem3_ARQOS(),
	.m_axi_gmem3_ARREGION(),
	.m_axi_gmem3_ARUSER(),
	
	.m_axi_gmem3_RVALID(0),
	.m_axi_gmem3_RREADY(),
	.m_axi_gmem3_RDATA(0),
	.m_axi_gmem3_RLAST(0),
	.m_axi_gmem3_RID(0),
	.m_axi_gmem3_RUSER(0),
	.m_axi_gmem3_RRESP(0),
	
	.m_axi_gmem3_BVALID(axi_m.bvalid),
	.m_axi_gmem3_BREADY(axi_m.bready),
	.m_axi_gmem3_BRESP(axi_m.bresp),
	.m_axi_gmem3_BID(axi_m.bid),
	.m_axi_gmem3_BUSER(0),

	.s_axi_control_AWVALID(!awf_empty),
	.s_axi_control_AWREADY(awf_rdreq),
	.s_axi_control_AWADDR(awf_q),
	
	.s_axi_control_WVALID(!wf_empty),
	.s_axi_control_WREADY(wf_rdreq),
	.s_axi_control_WDATA(wf_q),
	.s_axi_control_WSTRB(8'hFF),
	
	.s_axi_control_ARVALID(!arf_empty),
	.s_axi_control_ARREADY(arf_rdreq),
	.s_axi_control_ARADDR(arf_q),
	
	.s_axi_control_RVALID(softreg_resp.valid),
	.s_axi_control_RREADY(1),
	.s_axi_control_RDATA(softreg_resp.data),
	.s_axi_control_RRESP(),
	
	.s_axi_control_BVALID(),
	.s_axi_control_BREADY(1),
	.s_axi_control_BRESP(),
	
	.interrupt()
);

endmodule

