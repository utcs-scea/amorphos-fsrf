// Simple streaming API test
// By Joshua Landgraf

module Strm (
	// User clock and reset
	input  clk,
	input  rst,
	
	// Virtual memory interface
	axi_bus_t.slave axi_m,
	
	// Soft register interface
	input  SoftRegReq   softreg_req,
	output SoftRegResp  softreg_resp
);
wire softreg_read = softreg_req.valid && !softreg_req.isWrite;
wire softreg_write = softreg_req.valid && softreg_req.isWrite;

logic [63:0] r_cred_addr, w_cred_addr, r_data_addr, w_data_addr;

logic [31:0] read_creds, write_creds, read_comps, write_comps;
logic [31:0] use_read_creds, use_write_creds, use_write_comp;
logic use_read_comp;

logic [63:0] read_cycles, write_cycles;

logic ar_cred, aw_cred;
logic add_ar_cred, add_aw_cred, use_ar_cred, use_aw_cred;

logic [18:0] r_creds, w_creds;
logic [18:0] add_r_creds, add_w_creds, use_r_creds, use_w_creds;

logic [15:0] b_creds;
logic add_b_cred, use_b_cred;

always @(posedge clk) begin
	read_creds <= read_creds - use_read_creds;
	write_creds <= write_creds - use_write_creds;
	read_comps <= read_comps - use_read_comp;
	write_comps <= write_comps - use_write_comp;
	
	read_cycles <= read_cycles + (read_comps != 0);
	write_cycles <= write_cycles + ((write_comps != 0) || (b_creds != 0));
	
	ar_cred <= ar_cred + add_ar_cred - use_ar_cred;
	aw_cred <= aw_cred + add_aw_cred - use_aw_cred;
	r_creds <= r_creds + add_r_creds - use_r_creds;
	w_creds <= w_creds + add_w_creds - use_w_creds;
	b_creds <= b_creds + add_b_cred - use_b_cred;
	
	if (softreg_write) begin
		case (softreg_req.addr)
			32'h00: r_cred_addr <= softreg_req.data;
			32'h08: w_cred_addr <= softreg_req.data;
			32'h10: r_data_addr <= softreg_req.data;
			32'h18: w_data_addr <= softreg_req.data;
			32'h20: begin
				read_creds <= softreg_req.data;
				read_comps <= softreg_req.data;
				
				read_cycles <= 0;
				
				ar_cred <= 1;
			end
			32'h28: begin
				write_creds <= softreg_req.data;
				write_comps <= softreg_req.data;
				
				write_cycles <= 0;
				
				aw_cred <= 1;
			end
		endcase
	end
	
	softreg_resp.valid <= softreg_read;
	if (softreg_read) begin
		case (softreg_req.addr)
			32'h00: softreg_resp.data <= r_cred_addr;
			32'h08: softreg_resp.data <= w_cred_addr;
			32'h10: softreg_resp.data <= r_data_addr;
			32'h18: softreg_resp.data <= w_data_addr;
			32'h20: softreg_resp.data <= read_creds;
			32'h28: softreg_resp.data <= write_creds;
			32'h30: softreg_resp.data <= read_comps;
			32'h38: softreg_resp.data <= write_comps;
			32'h40: softreg_resp.data <= read_cycles;
			32'h48: softreg_resp.data <= write_cycles;
			32'h50: softreg_resp.data <= ar_cred;
			32'h58: softreg_resp.data <= aw_cred;
			32'h60: softreg_resp.data <= r_creds;
			32'h68: softreg_resp.data <= w_creds;
			32'h70: softreg_resp.data <= b_creds;
		endcase
	end
	
	if (rst) begin
		read_creds <= 0;
		write_creds <= 0;
		read_comps <= 0;
		write_comps <= 0;
		ar_cred <= 0;
		aw_cred <= 0;
		r_creds <= 0;
		w_creds <= 0;
		b_creds <= 0;
	end
end


enum {IDLE_AR, GET_AR, GET_AW, GET_R} ar_state;

always @(posedge clk) begin
	case (ar_state)
		IDLE_AR: begin
			if ((read_creds != 0) && (r_creds != 0)) ar_state <= GET_R;
			if (ar_cred) ar_state <= GET_AR;
			if (aw_cred) ar_state <= GET_AW;
		end
		default: begin
			if (axi_m.arready && axi_m.arvalid) begin
				ar_state <= IDLE_AR;
			end
		end
	endcase
	
	if (rst) ar_state <= IDLE_AR;
end


wire [7:0] min_r_creds = (read_creds < 64) ? read_creds : 64;
wire [7:0] min_rlen = (r_creds < min_r_creds) ? r_creds : min_r_creds;
always_comb begin
	use_read_creds = 0;
	use_read_comp = 0;
	use_ar_cred = 0;
	use_aw_cred = 0;
	use_r_creds = 0;
	
	add_ar_cred = 0;
	add_aw_cred = 0;
	add_r_creds = 0;
	add_w_creds = 0;
	
	axi_m.arid = 0;
	axi_m.araddr = 0;
	axi_m.arlen = 0;
	axi_m.arsize = 3'b110;
	axi_m.arvalid = 1;
	
	axi_m.rready = 1;
	
	case (ar_state)
		IDLE_AR: begin
			axi_m.arvalid = 0;
		end
		GET_AR: begin
			axi_m.arid = 0;
			axi_m.araddr = r_cred_addr;
			
			use_ar_cred = axi_m.arready;
		end
		GET_AW: begin
			axi_m.arid = 1;
			axi_m.araddr = w_cred_addr;
			
			use_aw_cred = axi_m.arready;
		end
		GET_R: begin
			axi_m.arid = 2;
			axi_m.araddr = r_data_addr;
			axi_m.arlen = min_rlen - 1;
			
			use_r_creds = axi_m.arready ? min_rlen : 0;
			use_read_creds = axi_m.arready ? min_rlen : 0;
		end
	endcase
	
	if (axi_m.rready && axi_m.rvalid) begin
		case (axi_m.rid)
			16'd0: begin
				add_ar_cred = (read_creds != 0);
				add_r_creds = axi_m.rdata[31:0];
			end
			16'd1: begin
				add_aw_cred = (write_creds != 0);
				add_w_creds = axi_m.rdata[31:0];
			end
			16'd2: begin
				use_read_comp = 1;
			end
		endcase
	end
end


reg [31:0] wlen;
always @(posedge clk) begin
	if (axi_m.wready && axi_m.wvalid) begin
		wlen <= axi_m.wlast ? 0 : wlen + 1;
	end
	if (rst) wlen <= 0;
end

logic wlf_wrreq;
logic [7:0] wlf_data;
logic wlf_full;
logic [7:0] wlf_q;
logic wlf_empty;
logic wlf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(8),
	.LOG_DEPTH(6)
) wlen_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wlf_wrreq),
	.data(wlf_data),
	.full(wlf_full),
	.q(wlf_q),
	.empty(wlf_empty),
	.rdreq(wlf_rdreq)
);

wire [7:0] min_aw_creds = (write_creds < 64) ? write_creds : 64;
wire [7:0] min_awlen = (w_creds < min_aw_creds) ? w_creds : min_aw_creds;
always_comb begin
	axi_m.awid = 0;
	axi_m.awaddr = w_data_addr;
	axi_m.awlen = min_awlen - 1;
	axi_m.awsize = 3'b110;
	axi_m.awvalid = (write_creds != 0) && (w_creds != 0) && !wlf_full;
	
	wlf_wrreq = (write_creds != 0) && (w_creds != 0) && axi_m.awready;
	wlf_data = axi_m.awlen;
	use_write_creds = (axi_m.awready && axi_m.awvalid) ? min_awlen : 0;
	use_w_creds = (axi_m.awready && axi_m.awvalid) ? min_awlen : 0;
	add_b_cred = axi_m.awready && axi_m.awvalid;
	
	axi_m.wdata = {16{wlen}};
	axi_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
	axi_m.wlast = (wlen == wlf_q);
	axi_m.wuser = 0;
	axi_m.wvalid = !wlf_empty;
	use_write_comp = (axi_m.wready && axi_m.wvalid);
	wlf_rdreq = axi_m.wready && axi_m.wvalid && axi_m.wlast;
	
	axi_m.bready = 1;
	use_b_cred = axi_m.bready && axi_m.bvalid;
end


endmodule
