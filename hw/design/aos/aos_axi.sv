// Converts AXI4 bursts into AXI-Lite transactions
// By Joshua Landgraf

module aos_axi (
	input clk,
	input rst,
	
	axi_bus_t.master axi_m,
	axi_bus_t.slave  axi_s
);

// Read requests
// Read id+len FIFO
wire rmf_wrreq;
wire [23:0] rmf_din;
wire rmf_full;
wire [23:0] rmf_dout;
wire rmf_empty;
wire rmf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+8),
	.LOG_DEPTH(6)
) rd_meta_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rmf_wrreq),
	.data(rmf_din),
	.full(rmf_full),
	.q(rmf_dout),
	.empty(rmf_empty),
	.rdreq(rmf_rdreq)
);

// Outgoing read request FIFO
wire rqf_wrreq;
wire [90:0] rqf_din;
wire rqf_full;
wire [90:0] rqf_dout;
wire rqf_empty;
wire rqf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(3)
) rd_rq_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rqf_wrreq),
	.data(rqf_din),
	.full(rqf_full),
	.q(rqf_dout),
	.empty(rqf_empty),
	.rdreq(rqf_rdreq)
);

// Current read request state
reg [63:0] araddr;
reg [ 7:0] arlen;
reg [ 2:0] arsize;
reg arvalid;

assign axi_m.arready = !rmf_full && (!arvalid || ((arlen == 0) && !rqf_full));

assign rmf_wrreq = axi_m.arvalid && (!arvalid || ((arlen == 0) && !rqf_full));
assign rmf_din = {axi_m.arid, axi_m.arlen};

assign rqf_wrreq = arvalid;
assign rqf_din = {16'h0000, {araddr[63:6], 6'h00}, 8'h00, 3'b110};

assign {axi_s.arid, axi_s.araddr, axi_s.arlen, axi_s.arsize} = rqf_dout;
assign axi_s.arvalid = !rqf_empty;
assign rqf_rdreq = axi_s.arready;

always_ff @(posedge clk) begin
	if (arvalid && !rqf_full) begin
		araddr <= araddr + (1 << arsize);
		arlen <= arlen - 1;
		if (arlen == 0) arvalid = 0;
	end
	
	if (!arvalid) begin
		araddr <= axi_m.araddr & ~((1 << axi_m.arsize) - 1);
		arlen <= axi_m.arlen;
		arsize <= axi_m.arsize;
		arvalid = axi_m.arvalid && !rmf_full;
	end
	
	if (rst) arvalid = 0;
end


// Read responses
// Read data FIFO
wire rdf_wrreq;
wire [513:0] rdf_din;
wire rdf_full;
wire [513:0] rdf_dout;
wire rdf_empty;
wire rdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512+2),
	.LOG_DEPTH(1)
) r_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_din),
	.full(rdf_full),
	.q(rdf_dout),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);

assign rdf_wrreq = axi_s.rvalid;
assign rdf_din = {axi_s.rdata, axi_s.rresp};
assign axi_s.rready = !rdf_full;

reg [7:0] rlen;
wire rlast = rlen == rmf_dout[7:0];

always_ff @(posedge clk) begin
	if (axi_m.rready && axi_m.rvalid) begin
		rlen <= rlast ? 0 : rlen + 1;
	end
	
	if (rst) rlen <= 0;
end

assign {axi_m.rdata, axi_m.rresp} = rdf_dout;
assign axi_m.rid = rmf_dout[23:8];
assign axi_m.rlast = rlast;
assign axi_m.rvalid = !rdf_empty;
assign rdf_rdreq = axi_m.rready;
assign rmf_rdreq = axi_m.rready && axi_m.rvalid && rlast;


// Write requests
// Write id+len FIFO
wire wmf_wrreq;
wire [23:0] wmf_din;
wire wmf_full;
wire [23:0] wmf_dout;
wire wmf_empty;
wire wmf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+8),
	.LOG_DEPTH(6)
) wr_meta_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wmf_wrreq),
	.data(wmf_din),
	.full(wmf_full),
	.q(wmf_dout),
	.empty(wmf_empty),
	.rdreq(wmf_rdreq)
);

// Outgoing write request FIFO
wire wqf_wrreq;
wire [90:0] wqf_din;
wire wqf_full;
wire [90:0] wqf_dout;
wire wqf_empty;
wire wqf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(3)
) wr_rq_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wqf_wrreq),
	.data(wqf_din),
	.full(wqf_full),
	.q(wqf_dout),
	.empty(wqf_empty),
	.rdreq(wqf_rdreq)
);

// Current write request state
reg [63:0] awaddr;
reg [ 7:0] awlen;
reg [ 2:0] awsize;
reg awvalid;

assign axi_m.awready = !wmf_full && (!awvalid || ((awlen == 0) && !wqf_full));

assign wmf_wrreq = axi_m.awvalid && (!awvalid || ((awlen == 0) && !wqf_full));
assign wmf_din = {axi_m.awid, axi_m.awlen};

assign wqf_wrreq = awvalid;
assign wqf_din = {16'h0000, {awaddr[63:6], 6'h00}, 8'h00, 3'b110};

assign {axi_s.awid, axi_s.awaddr, axi_s.awlen, axi_s.awsize} = wqf_dout;
assign axi_s.awvalid = !wqf_empty;
assign wqf_rdreq = axi_s.awready;

always_ff @(posedge clk) begin
	if (awvalid && !wqf_full) begin
		awaddr <= awaddr + (1 << awsize);
		awlen <= awlen - 1;
		if (awlen == 0) awvalid = 0;
	end
	
	if (!awvalid) begin
		awaddr <= axi_m.awaddr & ~((1 << axi_m.awsize) - 1);
		awlen <= axi_m.awlen;
		awsize <= axi_m.awsize;
		awvalid = axi_m.awvalid && !wmf_full;
	end
	
	if (rst) awvalid = 0;
end


// Write data
// Write data FIFO
wire wdf_wrreq;
wire [575:0] wdf_din;
wire wdf_full;
wire [575:0] wdf_dout;
wire wdf_empty;
wire wdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512+64),
	.LOG_DEPTH(1)
) w_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_din),
	.full(wdf_full),
	.q(wdf_dout),
	.empty(wdf_empty),
	.rdreq(wdf_rdreq)
);

assign wdf_wrreq = axi_m.wvalid;
assign wdf_din = {axi_m.wdata, axi_m.wstrb};
assign axi_m.wready = !wdf_full;

assign {axi_s.wdata, axi_s.wstrb} = wdf_dout;
assign axi_s.wlast = 1;
assign axi_s.wvalid = !wdf_empty;
assign wdf_rdreq = axi_s.wready;


// Write responses
// Write response FIFO
wire wpf_wrreq;
wire [17:0] wpf_din;
wire wpf_full;
wire [17:0] wpf_dout;
wire wpf_empty;
wire wpf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+2),
	.LOG_DEPTH(1)
) w_resp_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wpf_wrreq),
	.data(wpf_din),
	.full(wpf_full),
	.q(wpf_dout),
	.empty(wpf_empty),
	.rdreq(wpf_rdreq)
);

// Write response state
reg [7:0] wlen;
reg [1:0] wresp;
wire wlast = wlen == wmf_dout[7:0];
wire [1:0] bresp = (axi_s.bresp > wresp) ? axi_s.bresp : wresp;
// TODO?: handle EXOKAY properly

always_ff @(posedge clk) begin
	if (axi_s.bready && axi_s.bvalid) begin
		wlen <= wlast ? 0 : wlen + 1;
		wresp <= wlast ? 0 : bresp;
	end
	
	if (rst) begin
		wlen <= 0;
		wresp <= 0;
	end
end

assign wpf_wrreq = axi_s.bvalid && wlast;
assign wpf_din = {wmf_dout[23:8], bresp};
assign axi_s.bready = !wpf_full;
assign wmf_rdreq = axi_s.bready && axi_s.bvalid && wlast;

assign {axi_m.bid, axi_m.bresp} = wpf_dout;
assign axi_m.bvalid = !wpf_empty;
assign wpf_rdreq = axi_m.bready;


endmodule