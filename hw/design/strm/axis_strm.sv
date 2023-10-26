// Simple AXIS API test
// By Joshua Landgraf

import ShellTypes::*;

module AXIS_Strm (
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
wire softreg_read = softreg_req.valid && !softreg_req.isWrite;
wire softreg_write = softreg_req.valid && softreg_req.isWrite;


reg [34:0] to_write, to_read;
reg [34:0] packet_len;
reg [4:0] dest_write, read_id;
reg read_last;
reg [34:0] curr_len;
reg [47:0] write_cyc, read_cyc;
reg [511:0] read_data;
reg [34:0] last_count;

always_comb begin
	axis_m.tdest = dest_write;
	axis_m.tdata = {16{curr_len[31:0]}};
	axis_m.tlast = curr_len == packet_len;
	axis_m.tvalid = to_write != 0;
	
	axis_s.tready = to_read != 0;
end

always @(posedge clk) begin
	if (axis_m.tready && axis_m.tvalid) begin
		to_write <= to_write - 1;
		curr_len <= axis_m.tlast ? 0 : curr_len + 1;
	end
	
	if (axis_s.tready && axis_s.tvalid) begin
		to_read <= to_read - 1;
		read_id <= axis_s.tid;
		read_last <= axis_s.tlast;
		read_data <= axis_s.tdata;
		last_count <= axis_s.tlast ? last_count + 1 : last_count;
	end
	
	if (to_write != 0) write_cyc <= write_cyc + 1;
	if (to_read != 0) read_cyc <= read_cyc + 1;
	
	softreg_resp.valid <= softreg_read;
	if (softreg_read) begin
		case (softreg_req.addr)
			32'h00: softreg_resp.data <= to_write;
			32'h08: softreg_resp.data <= to_read;
			32'h10: softreg_resp.data <= dest_write;
			32'h18: softreg_resp.data <= packet_len;
			32'h20: softreg_resp.data <= read_id;
			32'h28: softreg_resp.data <= read_last;
			32'h30: softreg_resp.data <= curr_len;
			32'h38: softreg_resp.data <= write_cyc;
			32'h40: softreg_resp.data <= read_data[0+:64];
			32'h48: softreg_resp.data <= read_data[64+:64];
			32'h50: softreg_resp.data <= read_data[128+:64];
			32'h58: softreg_resp.data <= read_data[192+:64];
			32'h60: softreg_resp.data <= read_data[256+:64];
			32'h68: softreg_resp.data <= read_data[320+:64];
			32'h70: softreg_resp.data <= read_data[384+:64];
			32'h78: softreg_resp.data <= read_data[448+:64];
			32'h80: softreg_resp.data <= last_count;
			32'h88: softreg_resp.data <= read_cyc;
		endcase
	end
	
	if (softreg_write) begin
		case (softreg_req.addr)
			32'h00: begin
				to_write <= softreg_req.data;
				curr_len <= 0;
				write_cyc <= 0;
			end
			32'h08: begin
				to_read <= softreg_req.data;
				last_count <= 0;
				read_cyc <= 0;
			end
			32'h10: dest_write <= softreg_req.data;
			32'h18: packet_len <= softreg_req.data;
		endcase
	end
	
	if (rst) begin
		to_write <= 0;
		to_read <= 0;
		packet_len <= 0;
		dest_write <= 0;
		read_id <= 0;
		read_last <= 0;
	end
end

endmodule
