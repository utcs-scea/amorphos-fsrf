module rob_ram_wrapper #(
	parameter DATA_W = 512,
	parameter ADDR_W = 9
) (
	input clk,
	input rst,
	
	input [ADDR_W-1:0] waddr,
	input [DATA_W-1:0] wdata,
	input wvalid,
	
	input [ADDR_W-1:0] raddr,
	output reg [DATA_W-1:0] rdata
);
localparam DEPTH = 2**ADDR_W;

//(* ram_style = "block" *)
(* rw_addr_collision = "yes" *)
reg [DATA_W-1:0] mem [DEPTH-1:0];

reg [ADDR_W-1:0] raddr_reg;
always @(posedge clk) begin
	if (wvalid) mem[waddr] <= wdata;
	rdata <= mem[raddr];
end

endmodule


module axi_rob (
	input clk,
	input rst,
	
	axi_bus_t.master axi_m,
	axi_bus_t.slave  axi_s
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

genvar g;
integer i;

////// Read path
//// Register AR* signals from axi_m
wire arf_wrreq;
wire [90:0] arf_data;
wire arf_full;
wire [90:0] arf_q;
wire arf_empty;
wire arf_rdreq;

assign arf_wrreq = axi_m.arvalid;
assign arf_data = {axi_m.arid, axi_m.araddr, axi_m.arlen, axi_m.arsize};
assign axi_m.arready = !arf_full;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(1)
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

//// Record R TX IDs
wire rtf_wrreq;
wire [15:0] rtf_data;
wire rtf_full;
wire [15:0] rtf_q;
wire rtf_empty;
wire rtf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16),
	.LOG_DEPTH(FIFO_LD)
) r_tx_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rtf_wrreq),
	.data(rtf_data),
	.full(rtf_full),
	.q(rtf_q),
	.empty(rtf_empty),
	.rdreq(rtf_rdreq)
);

//// Handle and forward AR transactions to axi_s
// FIFO unpacking
wire [15:0] ar_arid = arf_q[90:75];
wire [63:0] ar_araddr = arf_q[74:11];
wire [7:0] ar_arlen = arf_q[10:3];
wire [2:0] ar_arsize = arf_q[2:0];
wire [6:0] ar_arlen1 = ar_arlen[5:0] + 1;
assign rtf_data = ar_arid;

// TX accept logic
wire ar_valid = (!arf_empty) && (!rtf_full);
wire ar_accept = axi_s.arready && ar_valid;
assign arf_rdreq = ar_accept;
assign rtf_wrreq = ar_accept;

// Stripe DRAM on TX forward
wire [1:0] ar_chan = ar_araddr[35:34];
assign axi_s.arid = {14'b0, ar_chan};
assign axi_s.araddr = ar_araddr;
assign axi_s.arlen = ar_arlen;
assign axi_s.arsize = ar_arsize;
assign axi_s.arvalid = ar_valid;

//// Reserve space for data in read buffer
reg [DATA_FIFO_LD:0] rb_ptr;

always @(posedge clk) begin
	if (ar_accept) rb_ptr <= rb_ptr + ar_arlen1;
	
	if (rst) rb_ptr <= 1 << DATA_FIFO_LD;
end

// Read buffer pointer FIFO signals
// One per DRAM channel
wire rbpf_wrreq [3:0];
wire [DATA_FIFO_LD:0] rbpf_data [3:0];
wire rbpf_full [3:0];
wire [DATA_FIFO_LD:0] rbpf_q [3:0];
wire rbpf_empty [3:0];
wire rbpf_rdreq [3:0];

generate
for (g = 0; g < 4; g = g + 1) begin
	assign rbpf_wrreq[g] = ar_accept && (ar_chan == g);
	assign rbpf_data[g] = rb_ptr;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(DATA_FIFO_LD+1),
		.LOG_DEPTH(FIFO_LD)
	) r_buf_ptr_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(rbpf_wrreq[g]),
		.data(rbpf_data[g]),
		.full(rbpf_full[g]),
		.q(rbpf_q[g]),
		.empty(rbpf_empty[g]),
		.rdreq(rbpf_rdreq[g])
	);
end
endgenerate

//// R TX buffer
wire [DATA_FIFO_LD-1:0] rb_waddr;
wire [515:0] rb_wdata;
wire rb_wvalid;
wire [DATA_FIFO_LD-1:0] rb_raddr;
wire [515:0] rb_rdata;

rob_ram_wrapper #(
	.DATA_W(1+512+2+1),
	.ADDR_W(DATA_FIFO_LD)
) r_buf (
	.clk(clk),
	.rst(rst),
	
	.waddr(rb_waddr),
	.wdata(rb_wdata),
	.wvalid(rb_wvalid),
	
	.raddr(rb_raddr),
	.rdata(rb_rdata)
);

//// Accept R transactions from axi_s
reg [DATA_FIFO_LD:0] r_waddr;
reg [5:0] r_woff [3:0];
reg [514:0] r_wdata;
reg r_wvalid;

wire [1:0] r_chan1 = axi_s.rid[1:0];
assign rb_waddr = r_waddr[DATA_FIFO_LD-1:0];
assign rb_wdata = {r_waddr[DATA_FIFO_LD], r_wdata};
assign rb_wvalid = r_wvalid;
assign axi_s.rready = 1;

// Register address and data signals
always @(posedge clk) begin
	r_waddr <= rbpf_q[r_chan1] + r_woff[r_chan1];
	r_wdata <= {axi_s.rdata, axi_s.rresp, axi_s.rlast};
	r_wvalid <= axi_s.rvalid;
	
	if (rst) r_wvalid <= 0;
end

generate
for (g = 0; g < 4; g = g + 1) begin
	assign rbpf_rdreq[g] = axi_s.rvalid && axi_s.rlast && (r_chan1 == g);
	
	always @(posedge clk) begin
		if (axi_s.rvalid && (r_chan1 == g)) begin
			r_woff[g] <= axi_s.rlast ? 0 : (r_woff[g] + 1);
		end
		
		if (rst) r_woff[g] <= 0;
	end
end
endgenerate

/*
//// Accept R transactions from axi_s
reg r_first [3:0];
reg [DATA_FIFO_LD:0] r_waddr [3:0];
reg [514:0] r_wdata;
reg r_wvalid;
reg [1:0] r_chan1_reg;

wire [1:0] r_chan1 = axi_s.rid[1:0];
assign rb_waddr = r_waddr[r_chan1_reg][DATA_FIFO_LD-1:0];
assign rb_wdata = {r_waddr[r_chan1_reg][DATA_FIFO_LD], r_wdata};
assign rb_wvalid = r_wvalid;
assign axi_s.rready = 1;

// Register address and data signals
always @(posedge clk) begin
	r_wdata <= {axi_s.rdata, axi_s.rresp, axi_s.rlast};
	r_wvalid <= axi_s.rvalid;
	r_chan1_reg <= r_chan1;
	
	if (rst) begin
		r_wvalid <= 0;
	end
end

generate
for (g = 0; g < 4; g = g + 1) begin
	assign rbpf_rdreq[g] = axi_s.rvalid && r_first[g] && (r_chan1 == g);
	
	always @(posedge clk) begin
		if (axi_s.rvalid && (r_chan1 == g)) begin
			r_first[g] <= axi_s.rlast;
			r_waddr[g] <= r_first[g] ? rbpf_q[g] : (r_waddr[g] + 1);
		end
		
		if (rst) r_first[g] <= 1;
	end
end
endgenerate
*/

//// Forward R transactions to axi_m
// State
reg [DATA_FIFO_LD:0] r_raddr;

// Unpack and connect signals
wire [15:0] r_rid = rtf_q;
wire r_rlast = rb_rdata[0];
wire r_key = rb_rdata[515];
assign axi_m.rid = r_rid;
assign axi_m.rdata = rb_rdata[514:3];
assign axi_m.rresp = rb_rdata[2:1];
assign axi_m.rlast = r_rlast;

// Logic
wire r_valid = r_key == r_raddr[DATA_FIFO_LD];
wire r_accept = r_valid && axi_m.rready;
assign axi_m.rvalid = r_valid;
assign rtf_rdreq = r_accept && r_rlast;

assign rb_raddr = r_raddr + r_accept;
always @(posedge clk) begin
	r_raddr <= r_raddr + r_accept;
	
	if (rst) r_raddr <= 1 << DATA_FIFO_LD;
end

////// Write path
//// Register AW* signals from axi_m
wire awf_wrreq;
wire [90:0] awf_data;
wire awf_full;
wire [90:0] awf_q;
wire awf_empty;
wire awf_rdreq;

assign awf_wrreq = axi_m.awvalid;
assign awf_data = {axi_m.awid, axi_m.awaddr, axi_m.awlen, axi_m.awsize};
assign axi_m.awready = !awf_full;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(1)
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

//// Handle and forward AW transactions to axi_s
// FIFO unpacking
wire [15:0] aw_awid = awf_q[90:75];
wire [63:0] aw_awaddr = awf_q[74:11];
wire [7:0] aw_awlen = awf_q[10:3];
wire [2:0] aw_awsize = awf_q[2:0];
wire [6:0] aw_awlen1 = aw_awlen + 1;

// TX accept logic
wire aw_valid = !awf_empty;
wire aw_accept = axi_s.awready && aw_valid;
assign awf_rdreq = aw_accept;

// Stripe DRAM on TX forward
wire [1:0] aw_chan = aw_awaddr[35:34];
assign axi_s.awid = {14'b0, aw_chan};
assign axi_s.awaddr = aw_awaddr;
assign axi_s.awlen = aw_awlen;
assign axi_s.awsize = aw_awsize;
assign axi_s.awvalid = aw_valid;

//// Record write response metadata
wire wrmf_wrreq;
wire [17:0] wrmf_data;
wire wrmf_full;
wire [17:0] wrmf_q;
wire wrmf_empty;
wire wrmf_rdreq;

assign wrmf_wrreq = aw_accept;
assign wrmf_data = {aw_awid, aw_chan};

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+2),
	.LOG_DEPTH(FIFO_LD)
) wr_tx_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wrmf_wrreq),
	.data(wrmf_data),
	.full(wrmf_full),
	.q(wrmf_q),
	.empty(wrmf_empty),
	.rdreq(wrmf_rdreq)
);

//// Forward write data
wire wdf_wrreq;
wire [576:0] wdf_data;
wire wdf_full;
wire [576:0] wdf_q;
wire wdf_empty;
wire wdf_rdreq;

assign axi_m.wready = !wdf_full;
assign wdf_wrreq = axi_m.wvalid;
assign wdf_data = {axi_m.wdata, axi_m.wstrb, axi_m.wlast};

assign wdf_rdreq = axi_s.wready;
assign {axi_s.wdata, axi_s.wstrb, axi_s.wlast} = wdf_q;
assign axi_s.wvalid = !wdf_empty;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512+64+1),
	.LOG_DEPTH(1)
) wr_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_data),
	.full(wdf_full),
	.q(wdf_q),
	.empty(wdf_empty),
	.rdreq(wdf_rdreq)
);

//// Buffer write responses
// One FIFO per DRAM channel
wire wrf_wrreq [3:0];
wire [1:0] wrf_data [3:0];
wire wrf_full [3:0];
wire [1:0] wrf_q [3:0];
wire wrf_empty [3:0];
wire wrf_rdreq [3:0];

wire [1:0] wr_chan1 = axi_s.bid[1:0];
assign axi_s.bready = 1;
generate
for (g = 0; g < 4; g = g + 1) begin
	assign wrf_wrreq[g] = axi_s.bvalid && (wr_chan1 == g);
	assign wrf_data[g] = axi_s.bresp;
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(2),
		.LOG_DEPTH(FIFO_LD)
	) wr_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(wrf_wrreq[g]),
		.data(wrf_data[g]),
		.full(wrf_full[g]),
		.q(wrf_q[g]),
		.empty(wrf_empty[g]),
		.rdreq(wrf_rdreq[g])
	);
end
endgenerate

//// Return write responses to axi_m
wire [1:0] wr_chan2 = wrmf_q[1:0];
wire wr_valid = (!wrmf_empty) && (!wrf_empty[wr_chan2]);
wire wr_accept = wr_valid && axi_m.bready;

assign axi_m.bid = wrmf_q[17:2];
assign axi_m.bresp = wrf_q[wr_chan2];
assign axi_m.bvalid = wr_valid;

assign wrmf_rdreq = wr_accept;
generate
for (g = 0; g < 4; g = g + 1) begin
	assign wrf_rdreq[g] = wr_accept && (wr_chan2 == g);
end
endgenerate

endmodule

