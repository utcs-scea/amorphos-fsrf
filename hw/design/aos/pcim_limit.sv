module pcim_limit (
	input clk,
	input rst,
	
	// Soft register interface
	input  SoftRegReq  softreg_req,
	output SoftRegResp softreg_resp,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave axi_m
);

wire softreg_read = softreg_req.valid && !softreg_req.isWrite;
wire softreg_write = softreg_req.valid && softreg_req.isWrite;

reg [15:0] w_minus;
reg [5:0] w_plus;

reg [5:0] cyc_cnt;
reg [6:0] aw_creds;
reg [15:0] aw_delay;
reg [15:0] w_delay;
reg [15:0] w_creds;

wire have_cred = aw_creds > axi_s.awlen;
wire use_cred = axi_m.awvalid && axi_m.awready;
wire [6:0] use_creds = use_cred ? (axi_s.awlen + 1) : 0;

wire have_w_cred = w_creds > 0;
wire use_w_cred = axi_m.wvalid && axi_m.wready;

always_ff @(posedge clk) begin
	// Decrease delay periodically
	if (cyc_cnt == 0) begin
		cyc_cnt <= 63;
		if (w_delay >= w_minus) w_delay <= w_delay - w_minus;
		else w_delay <= 0;
	end else begin
		cyc_cnt <= cyc_cnt - 1;
	end
	
	// Reset write credits every quantum
	if (aw_delay == 0) begin
		aw_creds <= 65;
		aw_delay <= 64 + w_delay;
	end else begin
		aw_delay <= aw_delay - 1;
		aw_creds <= aw_creds - use_creds;
	end
	
	// Increase delay in response to backpressure
	// TODO: add saturation check
	if (axi_m.wvalid && !axi_m.wready) w_delay <= w_delay + w_plus;
	
	// Track write credits
	w_creds <= w_creds + use_creds - use_w_cred;
	
	// Enable SR access
	softreg_resp.valid <= softreg_read;
	softreg_resp.data <= w_delay;
	
	if (softreg_write) begin
		case (softreg_req.addr)
			32'h0: w_minus <= softreg_req.data;
			32'h8: w_plus <= softreg_req.data;
			default: begin end
		endcase
	end
	
	if (rst) begin
		w_minus <= 8;
		w_plus <= 4;
		
		cyc_cnt <= 0;
		aw_creds <= 0;
		aw_delay <= 0;
		w_delay <= 0;
		w_creds <= 0;
	end
end

always_comb begin
	axi_m.awid = axi_s.awid;
	axi_m.awaddr = axi_s.awaddr;
	axi_m.awlen = axi_s.awlen;
	axi_m.awsize = axi_s.awsize;
	axi_m.awvalid = have_cred && axi_s.awvalid;
	axi_s.awready = have_cred && axi_m.awready;
	
	axi_m.wdata = axi_s.wdata;
	axi_m.wstrb = axi_s.wstrb;
	axi_m.wlast = axi_s.wlast;
	axi_m.wvalid = have_w_cred && axi_s.wvalid;
	axi_s.wready = have_w_cred && axi_m.wready;
	
	axi_s.bid = axi_m.bid;
	axi_s.bresp = axi_m.bresp;
	axi_s.bvalid = axi_m.bvalid;
	axi_m.bready = axi_s.bready;
	
	axi_m.arid = axi_s.arid;
	axi_m.araddr = axi_s.araddr;
	axi_m.arlen = axi_s.arlen;
	axi_m.arsize = axi_s.arsize;
	axi_m.arvalid = axi_s.arvalid;
	axi_s.arready = axi_m.arready;
	
	axi_s.rid = axi_m.rid;
	axi_s.rdata = axi_m.rdata;
	axi_s.rresp = axi_m.rresp;
	axi_s.rlast = axi_m.rlast;
	axi_s.rvalid = axi_m.rvalid;
	axi_m.rready = axi_s.rready;
end

endmodule
