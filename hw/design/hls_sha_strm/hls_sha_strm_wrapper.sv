module HLSSHAStrmWrapper
(
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

sha256_strm s256strm (
	.ap_clk(clk),
	.ap_rst_n(~rst),
	
	.axis_in_TDATA(axis_s.tdata),
	.axis_in_TVALID(axis_s.tvalid),
	.axis_in_TREADY(axis_s.tready),
	.axis_in_TKEEP('1),
	.axis_in_TSTRB('1),
	.axis_in_TLAST(axis_s.tlast),
	.axis_in_TID(axis_s.tid),
	.axis_in_TDEST(0),
	
	.axis_out_TDATA(axis_m.tdata),
	.axis_out_TVALID(axis_m.tvalid),
	.axis_out_TREADY(axis_m.tready),
	.axis_out_TKEEP(),
	.axis_out_TSTRB(),
	.axis_out_TLAST(axis_m.tlast),
	.axis_out_TID(),
	.axis_out_TDEST(axis_m.tdest),
	
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

