module sha_top (
	input clk,
	input rst,
	
	output reg [15:0] arid_m,
	output reg [63:0] araddr_m,
	output reg [7:0]  arlen_m,
	output reg [2:0]  arsize_m,
	output reg        arvalid_m,
	input             arready_m,
	
	input [15:0]  rid_m,
	input [511:0] rdata_m,
	input [1:0]   rresp_m,
	input         rlast_m,
	input         rvalid_m,
	output        rready_m,
	
	output reg [15:0] awid_m,
	output reg [63:0] awaddr_m,
	output reg [7:0]  awlen_m,
	output reg [2:0]  awsize_m,
	output reg        awvalid_m,
	input             awready_m,
	
	output [511:0] wdata_m,
	output [63:0]  wstrb_m,
	output         wlast_m,
	output         wvalid_m,
	input          wready_m,
	
	input [15:0] bid_m,
	input [1:0]  bresp_m,
	input        bvalid_m,
	output       bready_m,
	
	input        softreg_req_valid,
	input        softreg_req_isWrite,
	input [31:0] softreg_req_addr,
	input [63:0] softreg_req_data,
	
	output reg        softreg_resp_valid,
	output reg [63:0] softreg_resp_data
);

//// Input data stream
// state and signals
reg [63:0] id_addr;
reg [63:0] id_words;
reg [4:0] id_credits;
wire id_consume;

// FIFO signals
wire idf_wrreq = rvalid_m;
wire [511:0] idf_din = rdata_m;
wire idf_full;
wire idf_rdreq;
wire [511:0] idf_dout;
wire idf_empty;
assign rready_m = !idf_full;
assign id_consume = rvalid_m && rready_m && rlast_m;

// logic
reg [6:0] id_len_addr;
reg [6:0] id_len_words;
reg [6:0] id_len;
always @(*) begin
	arid_m = 0;
	araddr_m = id_addr;
	//arlen_m = 0;
	arsize_m = 3'b110;
	arvalid_m = id_words && id_credits;
	
	id_len_addr = 7'd64 - id_addr[5:0];
	id_len_words = (id_words < id_len_addr) ? id_words : id_len_addr;
	id_len = id_len_words;
	
	arlen_m = id_len - 1;
end
always @(posedge clk) begin
	if (rst) begin
		id_addr <= 0;
		id_words <= 0;
		id_credits <= 8;
	end else begin
		if (arvalid_m && arready_m) begin
			id_addr <= id_addr + (id_len << 6);
			id_words <= id_words - id_len;
		end
		if ((arvalid_m && arready_m) && id_consume) begin
			// Do nothing
		end else if (arvalid_m && arready_m) begin
			id_credits <= id_credits - 1;
		end else if (id_consume) begin
			id_credits <= id_credits + 1;
		end else begin
			// Do nothing
		end
		if (softreg_req_valid && softreg_req_isWrite) begin
			case (softreg_req_addr)
				32'h20: id_addr <= softreg_req_data;
				32'h28: id_credits <= softreg_req_data;
				32'h30: id_words <= softreg_req_data;
			endcase
		end
	end
end

// instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(512),
	.LOG_DEPTH(1)
) input_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(idf_wrreq),
	.data(idf_din),
	.full(idf_full),
	.rdreq(idf_rdreq),
	.q(idf_dout),
	.empty(idf_empty)
);


//// SHA256 core
// state and signals
reg [63:0] sha_words;
reg [64:0] sha_valid;
wire sha_in_valid = !idf_empty;
wire sha_out_valid = sha_valid[64];

reg [31:0] sha_a_reg;
reg [31:0] sha_b_reg;
reg [31:0] sha_c_reg;
reg [31:0] sha_d_reg;
reg [31:0] sha_e_reg;
reg [31:0] sha_f_reg;
reg [31:0] sha_g_reg;
reg [31:0] sha_h_reg;
wire [255:0] sha_hash;
wire [31:0] sha_a = sha_hash[31:0];
wire [31:0] sha_b = sha_hash[63:32];
wire [31:0] sha_c = sha_hash[95:64];
wire [31:0] sha_d = sha_hash[127:96];
wire [31:0] sha_e = sha_hash[159:128];
wire [31:0] sha_f = sha_hash[191:160];
wire [31:0] sha_g = sha_hash[223:192];
wire [31:0] sha_h = sha_hash[255:224];
wire [511:0] sha_chunk = idf_dout;

// logic
assign idf_rdreq = 1;
always @(posedge clk) begin
	sha_valid <= {sha_valid[63:0], sha_in_valid};
	if (sha_out_valid) begin
		sha_a_reg <= sha_a_reg + sha_a;
		sha_b_reg <= sha_b_reg + sha_b;
		sha_c_reg <= sha_c_reg + sha_c;
		sha_d_reg <= sha_d_reg + sha_d;
		sha_e_reg <= sha_e_reg + sha_e;
		sha_f_reg <= sha_f_reg + sha_f;
		sha_g_reg <= sha_g_reg + sha_g;
		sha_h_reg <= sha_h_reg + sha_h;
		sha_words <= sha_words + 1;
	end
	if (softreg_req_valid && softreg_req_isWrite) begin
		case (softreg_req_addr)
			32'h30: begin
				sha_a_reg <= 0;
				sha_b_reg <= 0;
				sha_c_reg <= 0;
				sha_d_reg <= 0;
				sha_e_reg <= 0;
				sha_f_reg <= 0;
				sha_g_reg <= 0;
				sha_h_reg <= 0;
				sha_words <= 0;
			end
		endcase
	end
	if (rst) begin
		sha_valid <= 0;
	end
end

// instantiation
sha256_transform #(
	.LOOP(1)
) sha (
	.clk(clk),
	.feedback(0),
	.cnt(0),
	.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
	.rx_input(sha_chunk),
	.tx_hash(sha_hash)
);


//// SoftReg output
always @(posedge clk) begin
	if (rst) begin
		softreg_resp_valid <= 0;
		softreg_resp_data <= 0;
	end else begin
		softreg_resp_valid <= softreg_req_valid && !softreg_req_isWrite;
		case (softreg_req_addr)
			32'h00: softreg_resp_data <= {sha_b_reg, sha_a_reg};
			32'h08: softreg_resp_data <= {sha_d_reg, sha_c_reg};
			32'h10: softreg_resp_data <= {sha_f_reg, sha_e_reg};
			32'h18: softreg_resp_data <= {sha_h_reg, sha_g_reg};
			32'h38: softreg_resp_data <= sha_words;
		endcase
	end
end

endmodule
