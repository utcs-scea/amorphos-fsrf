module HLSHLLWrapper
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

hyperloglog_top hllt (
	.ap_clk(clk),
	.ap_rst_n(~rst),
	
	.m_axi_gmem_AWVALID(axi_m.awvalid),
	.m_axi_gmem_AWREADY(axi_m.awready),
	.m_axi_gmem_AWADDR(axi_m.awaddr),
	.m_axi_gmem_AWID(axi_m.awid),
	.m_axi_gmem_AWLEN(axi_m.awlen),
	.m_axi_gmem_AWSIZE(axi_m.awsize),
	.m_axi_gmem_AWBURST(),
	.m_axi_gmem_AWLOCK(),
	.m_axi_gmem_AWCACHE(),
	.m_axi_gmem_AWPROT(),
	.m_axi_gmem_AWQOS(),
	.m_axi_gmem_AWREGION(),
	.m_axi_gmem_AWUSER(),
	
	.m_axi_gmem_WVALID(axi_m.wvalid),
	.m_axi_gmem_WREADY(axi_m.wready),
	.m_axi_gmem_WDATA(axi_m.wdata),
	.m_axi_gmem_WSTRB(axi_m.wstrb),
	.m_axi_gmem_WLAST(axi_m.wlast),
	.m_axi_gmem_WID(),
	.m_axi_gmem_WUSER(),
	
	.m_axi_gmem_ARVALID(axi_m.arvalid),
	.m_axi_gmem_ARREADY(axi_m.arready),
	.m_axi_gmem_ARADDR(axi_m.araddr),
	.m_axi_gmem_ARID(axi_m.arid),
	.m_axi_gmem_ARLEN(axi_m.arlen),
	.m_axi_gmem_ARSIZE(axi_m.arsize),
	.m_axi_gmem_ARBURST(),
	.m_axi_gmem_ARLOCK(),
	.m_axi_gmem_ARCACHE(),
	.m_axi_gmem_ARPROT(),
	.m_axi_gmem_ARQOS(),
	.m_axi_gmem_ARREGION(),
	.m_axi_gmem_ARUSER(),
	
	.m_axi_gmem_RVALID(axi_m.rvalid),
	.m_axi_gmem_RREADY(axi_m.rready),
	.m_axi_gmem_RDATA(axi_m.rdata),
	.m_axi_gmem_RLAST(axi_m.rlast),
	.m_axi_gmem_RID(axi_m.rid),
	.m_axi_gmem_RUSER(0),
	.m_axi_gmem_RRESP(axi_m.rresp),
	
	.m_axi_gmem_BVALID(axi_m.bvalid),
	.m_axi_gmem_BREADY(axi_m.bready),
	.m_axi_gmem_BRESP(axi_m.bresp),
	.m_axi_gmem_BID(axi_m.bid),
	.m_axi_gmem_BUSER(0),
	
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

