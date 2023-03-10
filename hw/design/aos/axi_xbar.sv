
// Arbiter module
// Currenty hardcoded
module axi_xbar_arb (
	input clk,
	input rst,
	
	input [4:0] reqs,
	output reg [4:0] grant_b,
	output reg [2:0] grant_i
);

integer i;

reg [1:0] prio = 0;
always @(posedge clk) begin
	prio <= prio + 1;
end

always @(posedge clk) begin
	reg [2:0] idx;
	
	grant_b <= 5'b00001;
	grant_i <= 0;
	if (!reqs[0]) begin
		for (i = 0; i < 4; i = i + 1) begin
			idx = ((prio + i) % 4) + 1;
			if (reqs[idx]) begin
				grant_b <= 1 << idx;
				grant_i <= idx;
			end
		end
	end
end

endmodule


// MxN AXI4 Interconnect
// Addressing logic current hardcoded
module axi_xbar #(
	parameter NUM_SI = 5,
	parameter NUM_MI = 4
) (
	input clk,
	input rst,
	
	axi_bus_t.master axi_s[NUM_SI-1:0],
	axi_bus_t.slave  axi_m[NUM_MI-1:0]
);
localparam FIFO_LD = 6;

localparam SI_BITS = $clog2(NUM_SI);
localparam MI_BITS = $clog2(NUM_MI);

genvar m, s;

//// Shared interface
// Slave signals
logic [33:0] si_awaddr [NUM_SI-1:0];
logic [7:0] si_awlen [NUM_SI-1:0];
logic [2:0] si_awsize [NUM_SI-1:0];
logic [NUM_MI-1:0] si_awvalid [NUM_SI-1:0];
logic [NUM_MI-1:0] si_awready [NUM_SI-1:0];

logic [511:0] si_wdata [NUM_SI-1:0];
logic [63:0] si_wstrb [NUM_SI-1:0];
logic si_wlast [NUM_SI-1:0];
logic [NUM_MI-1:0] si_wvalid [NUM_SI-1:0];
logic [NUM_MI-1:0] si_wready [NUM_SI-1:0];

logic [33:0] si_araddr [NUM_SI-1:0];
logic [7:0] si_arlen [NUM_SI-1:0];
logic [2:0] si_arsize [NUM_SI-1:0];
logic [NUM_MI-1:0] si_arvalid [NUM_SI-1:0];
logic [NUM_MI-1:0] si_arready [NUM_SI-1:0];

// Master signals
logic [1:0] mi_bresp [NUM_MI-1:0];
logic [NUM_SI-1:0] mi_bvalid [NUM_MI-1:0];
logic [NUM_SI-1:0] mi_bready [NUM_MI-1:0];

logic [511:0] mi_rdata [NUM_MI-1:0];
logic [1:0] mi_rresp [NUM_MI-1:0];
logic mi_rlast [NUM_MI-1:0];
logic [NUM_SI-1:0] mi_rvalid [NUM_MI-1:0];
logic [NUM_SI-1:0] mi_rready [NUM_MI-1:0];

//// Logic
for (s = 0; s < NUM_SI; s = s + 1) begin: si_logic
	//// Register slave interface
	axi_bus_t si_reg ();
	
	axi_reg axi_s_reg (
		.clk(clk),
		.rst_n(~rst),
		
		.axi_s(axi_s[s]),
		.axi_m(si_reg)
	);

	//// Local FIFOs
	// W metadata channel
	wire wmf_wrreq;
	wire [MI_BITS-1:0] wmf_data;
	wire wmf_full;
	wire [MI_BITS-1:0] wmf_q;
	wire wmf_empty;
	wire wmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(MI_BITS),
		.LOG_DEPTH(FIFO_LD)
	) w_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(wmf_wrreq),
		.data(wmf_data),
		.full(wmf_full),
		.q(wmf_q),
		.empty(wmf_empty),
		.rdreq(wmf_rdreq)
	);

	// B metadata channel
	wire bmf_wrreq;
	wire [MI_BITS+15:0] bmf_data;
	wire bmf_full;
	wire [MI_BITS+15:0] bmf_q;
	wire bmf_empty;
	wire bmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(MI_BITS+16),
		.LOG_DEPTH(FIFO_LD)
	) b_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(bmf_wrreq),
		.data(bmf_data),
		.full(bmf_full),
		.q(bmf_q),
		.empty(bmf_empty),
		.rdreq(bmf_rdreq)
	);
	
	// R metadata channel
	wire rmf_wrreq;
	wire [MI_BITS+15:0] rmf_data;
	wire rmf_full;
	wire [MI_BITS+15:0] rmf_q;
	wire rmf_empty;
	wire rmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(MI_BITS+16),
		.LOG_DEPTH(FIFO_LD)
	) r_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(rmf_wrreq),
		.data(rmf_data),
		.full(rmf_full),
		.q(rmf_q),
		.empty(rmf_empty),
		.rdreq(rmf_rdreq)
	);
	
	//// Logic
	// AW channel
	wire [MI_BITS-1:0] aw_mi_sel = si_reg.awaddr[35:34];
	
	assign si_awaddr[s] = si_reg.awaddr[33:0];
	assign si_awlen[s] = si_reg.awlen;
	assign si_awsize[s] = si_reg.awsize;
	for (m = 0; m < NUM_MI; m = m + 1) begin
		assign si_awvalid[s][m] = si_reg.awvalid && !bmf_full && (m == aw_mi_sel);
	end
	assign si_reg.awready = si_awready[s][aw_mi_sel] && !bmf_full;
	
	assign wmf_wrreq = si_reg.awready && si_reg.awvalid;
	assign bmf_wrreq = si_reg.awready && si_reg.awvalid;
	assign wmf_data = aw_mi_sel;
	assign bmf_data = {aw_mi_sel, si_reg.awid};
	
	// W channel
	wire [MI_BITS-1:0] w_mi_sel = wmf_q;
	
	assign si_wdata[s] = si_reg.wdata;
	assign si_wstrb[s] = si_reg.wstrb;
	assign si_wlast[s] = si_reg.wlast;
	for (m = 0; m < NUM_MI; m = m + 1) begin
		assign si_wvalid[s][m] = si_reg.wvalid && !wmf_empty && (m == w_mi_sel);
	end
	assign si_reg.wready = si_wready[s][w_mi_sel] && !wmf_empty;
	
	assign wmf_rdreq = si_reg.wready && si_reg.wvalid && si_reg.wlast;
	
	// B channel
	wire [MI_BITS-1:0] b_mi_sel;
	
	assign {b_mi_sel, si_reg.bid} = bmf_q;
	assign si_reg.bresp = mi_bresp[b_mi_sel];
	assign si_reg.bvalid = !bmf_empty && mi_bvalid[b_mi_sel][s];
	for (m = 0; m < NUM_MI; m = m + 1) begin
		assign mi_bready[m][s] = si_reg.bready && !bmf_empty && (m == b_mi_sel);
	end
	
	assign bmf_rdreq = si_reg.bready && si_reg.bvalid;
	
	// AR channel
	wire [MI_BITS-1:0] ar_mi_sel = si_reg.araddr[35:34];
	
	assign si_araddr[s] = si_reg.araddr[33:0];
	assign si_arlen[s] = si_reg.arlen;
	assign si_arsize[s] = si_reg.arsize;
	for (m = 0; m < NUM_MI; m = m + 1) begin
		assign si_arvalid[s][m] = si_reg.arvalid && !rmf_full && (m == ar_mi_sel);
	end
	assign si_reg.arready = si_arready[s][ar_mi_sel] && !rmf_full;
	
	assign rmf_wrreq = si_reg.arready && si_reg.arvalid;
	assign rmf_data = {ar_mi_sel, si_reg.arid};
	
	// R channel
	wire [MI_BITS-1:0] r_mi_sel;
	
	assign {r_mi_sel, si_reg.rid} = rmf_q;
	assign si_reg.rdata = mi_rdata[r_mi_sel];
	assign si_reg.rresp = mi_rresp[r_mi_sel];
	assign si_reg.rlast = mi_rlast[r_mi_sel];
	assign si_reg.rvalid = !rmf_empty && mi_rvalid[r_mi_sel][s];
	for (m = 0; m < NUM_MI; m = m + 1) begin
		assign mi_rready[m][s] = si_reg.rready && !rmf_empty && (m == r_mi_sel);
	end
	
	assign rmf_rdreq = si_reg.rready && si_reg.rvalid && si_reg.rlast;
end

for (m = 0; m < NUM_MI; m = m + 1) begin: mi_logic
	//// Register master interface
	axi_bus_t mi_reg ();
	
	axi_reg axi_m_reg (
		.clk(clk),
		.rst_n(~rst),
		
		.axi_s(mi_reg),
		.axi_m(axi_m[m])
	);

	//// Local FIFOs
	// W metadata channel
	wire wmf_wrreq;
	wire [SI_BITS-1:0] wmf_data;
	wire wmf_full;
	wire [SI_BITS-1:0] wmf_q;
	wire wmf_empty;
	wire wmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(SI_BITS),
		.LOG_DEPTH(FIFO_LD)
	) w_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(wmf_wrreq),
		.data(wmf_data),
		.full(wmf_full),
		.q(wmf_q),
		.empty(wmf_empty),
		.rdreq(wmf_rdreq)
	);

	// B metadata channel
	wire bmf_wrreq;
	wire [SI_BITS-1:0] bmf_data;
	wire bmf_full;
	wire [SI_BITS-1:0] bmf_q;
	wire bmf_empty;
	wire bmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(SI_BITS),
		.LOG_DEPTH(FIFO_LD)
	) b_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(bmf_wrreq),
		.data(bmf_data),
		.full(bmf_full),
		.q(bmf_q),
		.empty(bmf_empty),
		.rdreq(bmf_rdreq)
	);
	
	// R metadata channel
	wire rmf_wrreq;
	wire [SI_BITS-1:0] rmf_data;
	wire rmf_full;
	wire [SI_BITS-1:0] rmf_q;
	wire rmf_empty;
	wire rmf_rdreq;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(SI_BITS),
		.LOG_DEPTH(FIFO_LD)
	) r_meta_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(rmf_wrreq),
		.data(rmf_data),
		.full(rmf_full),
		.q(rmf_q),
		.empty(rmf_empty),
		.rdreq(rmf_rdreq)
	);
	
	//// Logic
	// AW channel
	wire [NUM_SI-1:0] aw_si_reqs, aw_si_sel_b;
	wire [SI_BITS-1:0] aw_si_sel;
	
	assign mi_reg.awid = 0;
	assign mi_reg.awaddr = {30'h00000000, si_awaddr[aw_si_sel]};
	assign mi_reg.awlen = si_awlen[aw_si_sel];
	assign mi_reg.awsize = si_awsize[aw_si_sel];
	assign mi_reg.awvalid = si_awvalid[aw_si_sel][m] && !bmf_full;
	//assign mi_reg.awvalid = |aw_si_reqs && !bmf_full;
	for (s = 0; s < NUM_SI; s = s + 1) begin
		assign aw_si_reqs[s] = si_awvalid[s][m];
		
		assign si_awready[s][m] = mi_reg.awready && !bmf_full && (s == aw_si_sel);
	end
	
	assign wmf_wrreq = mi_reg.awready && mi_reg.awvalid;
	assign bmf_wrreq = mi_reg.awready && mi_reg.awvalid;
	assign wmf_data = aw_si_sel;
	assign bmf_data = aw_si_sel;
	
	axi_xbar_arb aw_arb (
		.clk(clk),
		.rst(rst),
		
		.reqs(aw_si_reqs),
		.grant_b(aw_si_sel_b),
		.grant_i(aw_si_sel)
	);
	
	// W channel
	wire [SI_BITS-1:0] w_si_sel = wmf_q;
	
	assign mi_reg.wdata = si_wdata[w_si_sel];
	assign mi_reg.wstrb = si_wstrb[w_si_sel];
	assign mi_reg.wlast = si_wlast[w_si_sel];
	assign mi_reg.wvalid = !wmf_empty && si_wvalid[w_si_sel][m];
	for (s = 0; s < NUM_SI; s = s + 1) begin
		assign si_wready[s][m] = mi_reg.wready && !wmf_empty && (s == w_si_sel);
	end
	
	assign wmf_rdreq = mi_reg.wready && mi_reg.wvalid && mi_reg.wlast;
	
	// B channel
	wire [SI_BITS-1:0] b_si_sel = bmf_q;
	
	assign mi_bresp[m] = mi_reg.bresp;
	for (s = 0; s < NUM_SI; s = s + 1) begin
		assign mi_bvalid[m][s] = mi_reg.bvalid && !bmf_empty && (s == b_si_sel);
	end
	assign mi_reg.bready = !bmf_empty && mi_bready[m][b_si_sel];
	
	assign bmf_rdreq = mi_reg.bready && mi_reg.bvalid;
	
	// AR channel
	wire [NUM_SI-1:0] ar_si_reqs, ar_si_sel_b;
	wire [SI_BITS-1:0] ar_si_sel;
	
	assign mi_reg.arid = 0;
	assign mi_reg.araddr = {30'h00000000, si_araddr[ar_si_sel]};
	assign mi_reg.arlen = si_arlen[ar_si_sel];
	assign mi_reg.arsize = si_arsize[ar_si_sel];
	assign mi_reg.arvalid = si_arvalid[ar_si_sel][m] && !rmf_full;
	//assign mi_reg.arvalid = |ar_si_reqs && !rmf_full;
	for (s = 0; s < NUM_SI; s = s + 1) begin
		assign ar_si_reqs[s] = si_arvalid[s][m];
		
		assign si_arready[s][m] = mi_reg.arready && !rmf_full && (s == ar_si_sel);
	end
	
	assign rmf_wrreq = mi_reg.arready && mi_reg.arvalid;
	assign rmf_data = ar_si_sel;
	
	axi_xbar_arb ar_arb (
		.clk(clk),
		.rst(rst),
		
		.reqs(ar_si_reqs),
		.grant_b(ar_si_sel_b),
		.grant_i(ar_si_sel)
	);
	
	// R channel
	wire [SI_BITS-1:0] r_si_sel = rmf_q;
	
	assign mi_rdata[m] = mi_reg.rdata;
	assign mi_rresp[m] = mi_reg.rresp;
	assign mi_rlast[m] = mi_reg.rlast;
	for (s = 0; s < NUM_SI; s = s + 1) begin
		assign mi_rvalid[m][s] = mi_reg.rvalid && !rmf_empty && (s == r_si_sel);
	end
	assign mi_reg.rready = !rmf_empty && mi_rready[m][r_si_sel];
	
	assign rmf_rdreq = mi_reg.rready && mi_reg.rvalid && mi_reg.rlast;
end

endmodule
