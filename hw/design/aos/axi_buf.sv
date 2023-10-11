
// Buffers up to 32KiB of data
// Limits outstanding transactions to 64
// Holds write transactions until data received
module axi_buf (
	input clk,
	input rst,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave  axi_m
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

//// Buffer AXI channels
// ar slave FIFO signals
wire arsf_wrreq;
wire [90:0] arsf_data;
wire arsf_full;
wire [90:0] arsf_q;
wire arsf_empty;
wire arsf_rdreq;

// ar master FIFO signals
wire armf_wrreq;
wire [90:0] armf_data;
wire armf_full;
wire [90:0] armf_q;
wire armf_empty;
wire armf_rdreq;

// r data FIFO signals
wire rdf_wrreq;
wire [530:0] rdf_data;
wire rdf_full;
wire [530:0] rdf_q;
wire rdf_empty;
wire rdf_rdreq;

// aw slave FIFO signals
wire awsf_wrreq;
wire [90:0] awsf_data;
wire awsf_full;
wire [90:0] awsf_q;
wire awsf_empty;
wire awsf_rdreq;

// aw master FIFO signals
wire awmf_wrreq;
wire [90:0] awmf_data;
wire awmf_full;
wire [90:0] awmf_q;
wire awmf_empty;
wire awmf_rdreq;

// w data FIFO signals
wire wdf_wrreq;
wire [576:0] wdf_data;
wire wdf_full;
wire [576:0] wdf_q;
wire wdf_empty;
wire wdf_rdreq;

// b data FIFO signals
wire bdf_wrreq;
wire [17:0] bdf_data;
wire bdf_full;
wire [17:0] bdf_q;
wire bdf_empty;
wire bdf_rdreq;

// assigns
assign axi_s.arready = !arsf_full;
assign arsf_wrreq = axi_s.arvalid;
assign arsf_data = {axi_s.arid, axi_s.araddr, axi_s.arlen, axi_s.arsize};
//assign arsf_rdreq = TODO; // will assign later

//assign armf_wrreq = TODO; // will assign later
assign armf_data = arsf_q;
assign armf_rdreq = axi_m.arready;
assign {axi_m.arid, axi_m.araddr, axi_m.arlen, axi_m.arsize} = armf_q;
assign axi_m.arvalid = !armf_empty;

assign axi_m.rready = !rdf_full;
assign rdf_wrreq = axi_m.rvalid;
assign rdf_data = {axi_m.rid, axi_m.rdata, axi_m.rresp, axi_m.rlast};
assign rdf_rdreq = axi_s.rready;
assign {axi_s.rid, axi_s.rdata, axi_s.rresp, axi_s.rlast} = rdf_q;
assign axi_s.rvalid = !rdf_empty;

assign axi_s.awready = !awsf_full;
assign awsf_wrreq = axi_s.awvalid;
assign awsf_data = {axi_s.awid, axi_s.awaddr, axi_s.awlen, axi_s.awsize};
//assign arsf_rdreq = TODO; // will assign later

//assign awmf_wrreq = TODO; // will assign later
assign awmf_data = awsf_q;
assign awmf_rdreq = axi_m.awready;
assign {axi_m.awid, axi_m.awaddr, axi_m.awlen, axi_m.awsize} = awmf_q;
assign axi_m.awvalid = !awmf_empty;

assign axi_s.wready = !wdf_full;
assign wdf_wrreq = axi_s.wvalid;
assign wdf_data = {axi_s.wdata, axi_s.wstrb, axi_s.wlast};
assign wdf_rdreq = axi_m.wready;
assign {axi_m.wdata, axi_m.wstrb, axi_m.wlast} = wdf_q;
assign axi_m.wvalid = !wdf_empty;

assign axi_m.bready = !bdf_full;
assign bdf_wrreq = axi_m.bvalid;
assign bdf_data = {axi_m.bid, axi_m.bresp};
assign bdf_rdreq = axi_s.bready;
assign {axi_s.bid, axi_s.bresp} = bdf_q;
assign axi_s.bvalid = !bdf_empty;

// FIFO instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(1)
) ar_s_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(arsf_wrreq),
	.data(arsf_data),
	.full(arsf_full),
	.q(arsf_q),
	.empty(arsf_empty),
	.rdreq(arsf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(1)
) ar_m_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(armf_wrreq),
	.data(armf_data),
	.full(armf_full),
	.q(armf_q),
	.empty(armf_empty),
	.rdreq(armf_rdreq)
);
HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(16+512+2+1),
	.LOG_DEPTH(DATA_FIFO_LD)
) r_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_data),
	.full(rdf_full),
	.q(rdf_q),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(FIFO_LD)
) aw_s_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(awsf_wrreq),
	.data(awsf_data),
	.full(awsf_full),
	.q(awsf_q),
	.empty(awsf_empty),
	.rdreq(awsf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(1)
) aw_m_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(awmf_wrreq),
	.data(awmf_data),
	.full(awmf_full),
	.q(awmf_q),
	.empty(awmf_empty),
	.rdreq(awmf_rdreq)
);
HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(512+64+1),
	.LOG_DEPTH(DATA_FIFO_LD)
) w_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_data),
	.full(wdf_full),
	.q(wdf_q),
	.empty(wdf_empty),
	.rdreq(wdf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(16+2),
	.LOG_DEPTH(FIFO_LD)
) b_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(bdf_wrreq),
	.data(bdf_data),
	.full(bdf_full),
	.q(bdf_q),
	.empty(bdf_empty),
	.rdreq(bdf_rdreq)
);


//// Credit system
// read tx credits
reg [FIFO_LD:0] ra_creds;
wire have_ra_cred = ra_creds != 0;
logic add_ra_cred;
logic use_ra_cred;

// read data credits
reg [DATA_FIFO_LD:0] rd_creds;
wire [7:0] arlen = arsf_q[10:3];
wire have_rd_cred = rd_creds > arlen;
logic add_rd_cred;
logic [7:0] use_rd_creds;

// write tx credits
reg [FIFO_LD:0] wa_creds;
wire have_wa_cred = wa_creds != 0;
logic add_wa_cred;
logic use_wa_cred;

// wlast credits
reg [DATA_FIFO_LD:0] wl_creds;
wire have_wl_cred = wl_creds != 0;
logic add_wl_cred;
logic use_wl_cred;

// update logic
always @(posedge clk) begin
	ra_creds <= ra_creds - use_ra_cred + add_ra_cred;
	rd_creds <= rd_creds + add_rd_cred - use_rd_creds;
	
	wa_creds <= wa_creds + add_wa_cred - use_wa_cred;
	wl_creds <= wl_creds + add_wl_cred - use_wl_cred;
	
	if (rst) begin
		ra_creds <= 1 << FIFO_LD;
		rd_creds <= 1 << DATA_FIFO_LD;
		
		wa_creds <= 1 << FIFO_LD;
		wl_creds <= 0;
	end
end


//// Logic
wire have_r_cred = have_ra_cred && have_rd_cred;
assign use_ra_cred = have_r_cred && !arsf_empty && !armf_full;
assign use_rd_creds = use_ra_cred ? arlen + 1 : 0;

assign arsf_rdreq = have_r_cred && !armf_full;
assign armf_wrreq = have_r_cred && !arsf_empty;

wire have_w_cred = have_wa_cred && have_wl_cred;
assign use_wa_cred = have_w_cred && !awsf_empty && !awmf_full;
assign use_wl_cred = use_wa_cred;

assign awsf_rdreq = have_w_cred && !awmf_full;
assign awmf_wrreq = have_w_cred && !awsf_empty;

always @(posedge clk) begin
	add_ra_cred <= axi_s.rready && axi_s.rvalid && axi_s.rlast;
	add_rd_cred <= axi_s.rready && axi_s.rvalid;
	
	add_wa_cred <= axi_s.bready && axi_s.bvalid;
	add_wl_cred <= axi_s.wready && axi_s.wvalid && axi_s.wlast;
	
	if (rst) begin
		add_ra_cred <= 0;
		add_rd_cred <= 0;
		
		add_wa_cred <= 0;
		add_wl_cred <= 0;
	end
end

endmodule
