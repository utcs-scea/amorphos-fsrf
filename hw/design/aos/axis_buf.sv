// Manages stream data
// 32KB, 32 stream capacity
// By Joshua Landgraf

// Tracks requests
// Reorders responses
module req_resp_rob #(
	parameter RAM_LD = 5
) (
	input clk,
	input rst,
	
	input req_wrreq,
	input [11:0] req_data,
	output req_full,
	
	input req_rdreq,
	output [RAM_LD+12:0] req_q,
	output req_empty,
	
	input resp_wrreq,
	input [RAM_LD+12:0] resp_data,
	output resp_full,
	
	input resp_rdreq,
	output [11:0] resp_q,
	output resp_empty
);
localparam RAM_SZ = (1 << RAM_LD) - 1;

// RAMs
reg req_vld [RAM_SZ:0];
reg [RAM_LD+12:0] req  [RAM_SZ:0];
reg [12:0] resp [RAM_SZ:0];

// Initialize to zero
integer i;
initial begin
	for (i = 0; i <= RAM_SZ; i = i + 1) begin
		req_vld[i] = 0;
		req[i] = 0;
		resp[i] = 0;
	end
end

// Req logic
reg [RAM_LD:0] req_in_ptr = 1 << RAM_LD;
reg [RAM_LD:0] req_out_ptr = 0;

wire [RAM_LD-1:0] req_in_idx = req_in_ptr[RAM_LD-1:0];
wire [RAM_LD-1:0] req_out_idx = req_out_ptr[RAM_LD-1:0];
assign req_full = req_vld[req_in_idx] == req_in_ptr[RAM_LD];
assign req_q = req[req_out_idx];
assign req_empty = req_q[RAM_LD+12] == req_out_ptr[RAM_LD];

always_ff @(posedge clk) begin
	if (req_wrreq && !req_full) begin
		req[req_in_idx] <= {req_in_ptr, req_data};
		req_in_ptr <= req_in_ptr + 1;
	end
	
	if (req_rdreq && !req_empty) req_out_ptr <= req_out_ptr + 1;
	
	if (rst) begin
		req_in_ptr <= 1 << RAM_LD;
		req_out_ptr <= 0;
	end
end

// Resp logic
reg [RAM_LD:0] resp_out_ptr = 0;

wire [RAM_LD:0] resp_in_ptr = resp_data[RAM_LD+12:12];
wire [RAM_LD-1:0] resp_in_idx = resp_in_ptr[RAM_LD-1:0];
wire [RAM_LD-1:0] resp_out_idx = resp_out_ptr[RAM_LD-1:0];
assign resp_full = 0;
assign resp_q = resp[resp_out_idx][11:0];
assign resp_empty = resp[resp_out_idx][12] == resp_out_ptr[RAM_LD];

always_ff @(posedge clk) begin
	if (resp_wrreq && !resp_full) begin
		resp[resp_in_idx] <= {resp_in_ptr[RAM_LD], resp_data[11:0]};
	end
	
	if (resp_rdreq && !resp_empty) begin
		req_vld[resp_out_idx] <= !resp_out_ptr[RAM_LD];
		resp_out_ptr <= resp_out_ptr + 1;
	end
	
	if (rst) begin
		resp_out_ptr <= 0;
	end
end

endmodule



module axis_buf (
	input clk,
	input rst,
	
	input  SoftRegReq   softreg_req,
	output SoftRegResp  softreg_resp,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave  axi_m,
	
	axi_stream_t.master axis_s,
	axi_stream_t.slave axis_m
);
//localparam FIFO_LD = 6;
localparam SEND_FIFO_LD = 9;
localparam RECV_FIFO_LD = 9;


//// FIFOs
// Send data FIFO
logic sdf_wrreq;
logic [511:0] sdf_data;
logic sdf_full;
logic [511:0] sdf_q;
logic sdf_empty;
logic sdf_rdreq;

HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(512),
	.LOG_DEPTH(SEND_FIFO_LD)
) send_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(sdf_wrreq),
	.data(sdf_data),
	.full(sdf_full),
	.q(sdf_q),
	.empty(sdf_empty),
	.rdreq(sdf_rdreq)
);

// Receive request FIFO
// Length, tdest, tlast, and pointer
logic rqf_wrreq;
logic [17:0] rqf_data;
logic rqf_full;
logic [17:0] rqf_q;
logic rqf_empty;
logic rqf_rdreq;

HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(6+5+1+6),
	.LOG_DEPTH(10)
) recv_req_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rqf_wrreq),
	.data(rqf_data),
	.full(rqf_full),
	.q(rqf_q),
	.empty(rqf_empty),
	.rdreq(rqf_rdreq)
);

// Receive response FIFO
// Length, tdest, and tlast
logic rpf_wrreq;
logic [17:0] rpf_data;
logic rpf_full;
logic [17:0] rpf_q;
logic rpf_empty;
logic rpf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(6+5+1+6),
	.LOG_DEPTH(1)
) recv_resp_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rpf_wrreq),
	.data(rpf_data),
	.full(rpf_full),
	.q(rpf_q),
	.empty(rpf_empty),
	.rdreq(rpf_rdreq)
);

// RX bid FIFO
logic rbf_wrreq;
logic [15:0] rbf_data;
logic rbf_full;
logic [15:0] rbf_q;
logic rbf_empty;
logic rbf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16),
	.LOG_DEPTH(1)
) rx_bid_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rbf_wrreq),
	.data(rbf_data),
	.full(rbf_full),
	.q(rbf_q),
	.empty(rbf_empty),
	.rdreq(rbf_rdreq)
);

// Receive data FIFO
// Data, tid, tlast
logic rdf_wrreq;
logic [517:0] rdf_data;
logic rdf_full;
logic [517:0] rdf_q;
logic rdf_empty;
logic rdf_rdreq;

HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(512+5+1),
	.LOG_DEPTH(RECV_FIFO_LD)
) recv_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_data),
	.full(rdf_full),
	.q(rdf_q),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);


//// RAMs
reg strm_en [31:0];
reg [48:0] data_addr [31:0];
reg [48:0] cntrl_addr [31:0];


//// Send req / resp ROB
// Send request FIFO
// Length, tdest, tlast, and metadata
logic sqf_wrreq;
logic [11:0] sqf_data;
logic sqf_full;
logic [17:0] sqf_q;
logic sqf_empty;
logic sqf_rdreq;

// Send response "FIFO"
// Length, tdest, tlast, and metadata
logic spf_wrreq;
logic [17:0] spf_data;
logic spf_full;
logic [11:0] spf_q;
logic spf_empty;
logic spf_rdreq;

// ROB
// Metadata allows for RAM_LD up to 5
req_resp_rob #(
	.RAM_LD(5)
) srr_rob (
	.clk(clk),
	.rst(rst),
	
	.req_wrreq(sqf_wrreq),
	.req_data(sqf_data),
	.req_full(sqf_full),
	
	.req_rdreq(sqf_rdreq),
	.req_q(sqf_q),
	.req_empty(sqf_empty),
	
	.resp_wrreq(spf_wrreq),
	.resp_data(spf_data),
	.resp_full(spf_full),
	
	.resp_rdreq(spf_rdreq),
	.resp_q(spf_q),
	.resp_empty(spf_empty)
);


//// Buffer data to send
// Send data (sdf)
// Send request (sqf)
begin: SEND_BUF
	reg valid;
	reg last;
	reg [5:0] len;
	reg [4:0] dest;
	logic done;
	
	always_comb begin
		axis_s.tready = !sqf_full && !sdf_full && strm_en[axis_s.tdest];
		sdf_wrreq = axis_s.tready && axis_s.tvalid;
		
		sqf_data = {last, len, dest};
		sdf_data = axis_s.tdata;
		
		sqf_wrreq = 0;
		done = 0;
		if (valid) begin
			if (last || (len == 63) || (axis_s.tvalid && (axis_s.tdest != dest))) begin
				sqf_wrreq = 1;
				done = !sqf_full;
			end
		end
	end
	
	always_ff @(posedge clk) begin
		if (done) begin
			valid <= 0;
		end
		
		if (axis_s.tready && axis_s.tvalid) begin
			valid <= 1;
			last <= axis_s.tlast;
			len <= (done || !valid) ? 0 : (len + 1);
			dest <= axis_s.tdest;
		end
		
		if (rst) begin
			valid <= 0;
		end
	end
end


//// Credit system
// Track reservable space
reg [RECV_FIFO_LD:0] r_creds;
logic [RECV_FIFO_LD:0] ovw_r_creds;
logic [5:0] req_r_creds;
wire have_r_cred = r_creds > req_r_creds;
logic add_r_cred;
logic ovw_r_cred;
logic req_r_cred;

always_ff @(posedge clk) begin
	r_creds <= r_creds + add_r_cred - ((req_r_cred && have_r_cred) ? (req_r_creds + 1) : 0);
	
	if (ovw_r_cred) r_creds <= ovw_r_creds;
	
	if (rst) begin
		r_creds <= 1 << RECV_FIFO_LD;
	end
end


//// Return data to app
// Received data (rdf)
always_comb begin
	axis_m.tvalid = !rdf_empty;
	rdf_rdreq = axis_m.tready;
	add_r_cred = rdf_rdreq && !rdf_empty;
	
	{axis_m.tdata, axis_m.tid, axis_m.tlast} = rdf_q;
	axis_m.tdest = 0;
end


//// Receive response generator
// Credit requests (rqf)
// Credit responses (rpf)
always_comb begin
	req_r_cred = !rqf_empty && !rpf_full;
	req_r_creds = rqf_q[10:5];
	
	rqf_rdreq = req_r_cred && have_r_cred;
	rpf_wrreq = req_r_cred && have_r_cred;
	rpf_data = rqf_q;
end


//// TX interface
// Credit responses (rpf)
// Credit requests (sqf)
// Data payloads (spf, sdf)
begin: TX
	reg [20:0] tx_data;
	reg tx_valid;
	wire tx_rd = axi_m.wready && axi_m.wvalid && axi_m.wlast;
	wire tx_wr = axi_m.awready && axi_m.awvalid;
	wire tx_ready = !tx_valid || tx_rd;
	logic [20:0] tx_next;
	
	// AXI_M AW
	logic [12:0] data_addr_off;
	always_comb begin
		axi_m.awid = 0;
		axi_m.awsize = 3'b110;
		
		rpf_rdreq = 0;
		sqf_rdreq = 0;
		spf_rdreq = 0;
		
		data_addr_off = spf_q[11] ? (4096 + 64*(63-spf_q[10:5])) : 0;
		
		if (!rpf_empty) begin
			axi_m.awaddr = cntrl_addr[rpf_q[4:0]];
			axi_m.awlen = 0;
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = rpf_q[17:5];
			tx_next[1:0] = 2'd0;
			rpf_rdreq = axi_m.awready && axi_m.awvalid;
		end else if (!sqf_empty) begin
			axi_m.awaddr = cntrl_addr[sqf_q[4:0]];
			axi_m.awlen = 0;
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = sqf_q[17:5];
			tx_next[1:0] = 2'd1;
			sqf_rdreq = axi_m.awready && axi_m.awvalid;
		end else if (!spf_empty) begin
			axi_m.awaddr = data_addr[spf_q[4:0]] + data_addr_off;
			axi_m.awlen = spf_q[10:5];
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = 0;
			tx_next[1:0] = 2'd2;
			spf_rdreq = axi_m.awready && axi_m.awvalid;
		end else begin
			axi_m.awaddr = data_addr[spf_q[4:0]] + data_addr_off;
			axi_m.awlen = spf_q[10:5];
			axi_m.awvalid = 0;
			
			tx_next[20:8] = 0;
			tx_next[1:0] = 2'd2;
		end
		
		tx_next[7:2] = axi_m.awlen[5:0];
	end
	
	// AXI_M W
	reg [5:0] len;
	
	always_comb begin
		axi_m.wlast = len == tx_data[7:2];
		
		sdf_rdreq = 0;
		
		case (tx_data[1:0])
			2'd0: begin
				axi_m.wdata = {1'b1, tx_data[20:8]};
				axi_m.wstrb = 64'h000000000000000F;
				axi_m.wvalid = tx_valid;
			end
			2'd1: begin
				axi_m.wdata = {1'b0, tx_data[20:8]};
				axi_m.wstrb = 64'h000000000000000F;
				axi_m.wvalid = tx_valid;
			end
			2'd2: begin
				axi_m.wdata = sdf_q;
				axi_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
				axi_m.wvalid = tx_valid && !sdf_empty;
				
				sdf_rdreq = tx_valid && axi_m.wready;
			end
			default: begin
				axi_m.wdata = sdf_q;
				axi_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
				axi_m.wvalid = 0;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		tx_valid <= tx_wr || (tx_valid && !tx_rd);
		if (tx_wr && (!tx_valid || tx_rd)) tx_data <= tx_next;
		
		if (axi_m.wready && axi_m.wvalid) len <= axi_m.wlast ? 0 : (len + 1);
		
		if (rst) begin
			tx_valid <= 0;
			len <= 0;
		end
	end
	
	// AXI_M B
	assign axi_m.bready = 1;
end

//// RX interface
// Configuration
// Credit responses (spf)
// Credit requests (rqf)
// Data payloads (rdf)
begin: RX
	wire last_addr = (axi_s.awaddr[12:6] + axi_s.awlen[5:0]) == 7'h7F;
	assign axi_s.awready = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	assign rbf_wrreq = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	
	always_comb begin
		// AXI_S AW and W
		axi_s.wready = 0;
		
		spf_wrreq = 0;
		rqf_wrreq = 0;
		rdf_wrreq = 0;
		
		spf_data = {axi_s.wdata[12:0], axi_s.awaddr[10:6]};
		rqf_data = {axi_s.wdata[12:0], axi_s.awaddr[10:6]};
		rdf_data = {axi_s.wdata, axi_s.awaddr[17:13], last_addr && axi_s.wlast};
		rbf_data = axi_s.awid;
		
		if (axi_s.awvalid && axi_s.wvalid && !rbf_full) begin
			if (axi_s.awaddr[18]) begin
				// Configuration
				if (axi_s.awaddr[12]) begin
					if (axi_s.awaddr[11]) begin
						// Credit overrides
						axi_s.wready = 1;
					end else begin
						if (axi_s.wdata[13]) begin
							// Response
							axi_s.wready = !spf_full;
							spf_wrreq = 1;
						end else begin
							// Request
							axi_s.wready = !rqf_full;
							rqf_wrreq = 1;
						end
					end
				end else begin
					// Stream config
					axi_s.wready = 1;
				end
			end else begin
				// Data
				axi_s.wready = !rdf_full;
				rdf_wrreq = 1;
			end
		end
		
		// AXI_S B
		axi_s.bid = rbf_q;
		axi_s.bresp = 2'b00;
		axi_s.bvalid = !rbf_empty;
		rbf_rdreq = axi_s.bready;
	end
end


// SoftReg interface
wire softreg_read = softreg_req.valid && !softreg_req.isWrite;
wire softreg_write = softreg_req.valid && softreg_req.isWrite;

always_comb begin
	ovw_r_cred = softreg_write && (softreg_req.addr == 32'h200);
	ovw_r_creds = softreg_req.data;
end

always_ff @(posedge clk) begin
	if (softreg_write) begin
		if (softreg_req.addr[31:9] == 0) begin
			strm_en[softreg_req.addr[7:3]] <= softreg_req.data[49];
			if (softreg_req.addr[8]) begin
				data_addr[softreg_req.addr[7:3]] <= softreg_req.data[48:0];
			end else begin
				cntrl_addr[softreg_req.addr[7:3]] <= softreg_req.data[48:0];
			end
		end
	end
	
	softreg_resp.valid <= softreg_read;
	if (softreg_read) begin
		if (softreg_req.addr[9]) begin
			case (softreg_req.addr[8:3])
				0: softreg_resp.data <= r_creds;
				1: softreg_resp.data <= {sdf_q[61:0], sdf_full, sdf_empty};
				2: softreg_resp.data <= {sqf_q, sqf_full, sqf_empty};
				3: softreg_resp.data <= {spf_q, spf_full, spf_empty};
				4: softreg_resp.data <= {rdf_q[61:0], rdf_full, rdf_empty};
				5: softreg_resp.data <= {rqf_q, rqf_full, rqf_empty};
				6: softreg_resp.data <= {rpf_q, rpf_full, rpf_empty};
				7: softreg_resp.data <= {rbf_q, rbf_full, rbf_empty};
				8: softreg_resp.data <= {TX.tx_data, TX.tx_valid};
				9: softreg_resp.data <= axi_m.awaddr;
				10: softreg_resp.data <= {axi_m.awlen, axi_m.awready, axi_m.awvalid};
				11: softreg_resp.data <= {axi_m.wdata[61:0], axi_m.wready, axi_m.wvalid};
				default: softreg_resp.data <= 0;
			endcase
		end else begin
			if (softreg_req.addr[8]) begin
				softreg_resp.data <= data_addr[softreg_req.addr[7:3]];
			end else begin
				softreg_resp.data <= cntrl_addr[softreg_req.addr[7:3]];
			end
			softreg_resp.data[49] <= strm_en[softreg_req.addr[7:3]];
		end
	end
end

endmodule
					