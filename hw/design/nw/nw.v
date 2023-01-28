module Cell #(
	// Character width in bits
	parameter C_WIDTH = 2,
	// Score width in bits
	parameter S_WIDTH = 8
) (
	// Clock
	input wire clk,
	
	// Left inputs
	input wire [C_WIDTH-1:0] l_char,
	input wire signed [S_WIDTH-1:0] l_score,
	
	// Top inputs
	input wire [C_WIDTH-1:0] t_char,
	input wire signed [S_WIDTH-1:0] t_score,
	
	// Corner input
	input wire signed [S_WIDTH-1:0] c_score,
	
	// Output
	output reg signed [S_WIDTH-1:0] o_score
);
// Score values
localparam signed [S_WIDTH-1:0] S_MATCH = 1;
localparam signed [S_WIDTH-1:0] S_MISMATCH = -1;
localparam signed [S_WIDTH-1:0] S_INDEL = -1;

// Temporary scores
wire signed [S_WIDTH-1:0] lt_max = (l_score > t_score) ? l_score : t_score;
wire signed [S_WIDTH-1:0] lt_next = lt_max + S_INDEL;
wire signed [S_WIDTH-1:0] c_next = c_score + (l_char == t_char ? S_MATCH : S_MISMATCH);
wire signed [S_WIDTH-1:0] ltc_next = (lt_next > c_next) ? lt_next : c_next;

// Register output score
always @(posedge clk) begin
	o_score <= ltc_next;
end

endmodule


module StaticShiftReg #(
	parameter LENGTH = 1,
	parameter WIDTH = 2
) (
	// Clock and reset
	input wire clk,
	input wire rst,
	
	// Interface
	input  wire [WIDTH-1:0] din,
	output wire [WIDTH-1:0] dout
);

//(* shreg_extract = "yes" *)
reg [WIDTH-1:0] data [LENGTH-1:0];

assign dout = data[0];

integer i;
always @(posedge clk) begin
	for (i = 0; i < (LENGTH-1); i = i + 1) begin
		data[i] <= data[i+1];
	end
	data[LENGTH-1] <= din;
	
	if (rst) begin
		for (i = 0; i < LENGTH; i = i + 1) begin
			data[i] <= 0;
		end
	end
end

endmodule


module Grid #(
	// String length in characters
	parameter S_LEN = 64,
	// Character width in bits
	parameter C_WIDTH = 2,
	// Score width in bits
	parameter S_WIDTH = 8
) (
	// Clock and reset
	input wire clk,
	input wire rst,
	
	// Inputs
	input wire valid_in,
	input wire [S_LEN*C_WIDTH-1:0] t_str,
	input wire [S_LEN*C_WIDTH-1:0] l_str,
	
	// Outputs
	output wire valid_out,
	output wire signed [S_WIDTH-1:0] score
);

genvar r, c;
generate
for (r = 0; r < S_LEN; r = r + 1) begin: ROW
	for (c = 0; c < S_LEN; c = c + 1) begin: COL
		localparam S_W = $clog2(r+c+2)+1;
		
		wire [C_WIDTH-1:0] t_char;
		wire [C_WIDTH-1:0] l_char;
		
		wire signed [S_W-1:0] t_score;
		wire signed [S_W-1:0] l_score;
		wire signed [S_W-1:0] c_score;
		wire signed [S_W-1:0] o_score;
		
		if (r == 0) begin
			StaticShiftReg #(
				.LENGTH(c+1),
				.WIDTH(C_WIDTH)
			) t_ssr (
				.clk(clk),
				.rst(1'b0),
				.din(t_str[c*C_WIDTH+:C_WIDTH]),
				.dout(t_char)
			);
			assign t_score = -1-c;
		end else begin
			reg [C_WIDTH-1:0] t_char_reg;
			always @(posedge clk) begin
				t_char_reg <= ROW[r-1].COL[c].t_char;
			end
			assign t_char = t_char_reg;
			assign t_score = ROW[r-1].COL[c].o_score;
		end
		
		if (c == 0) begin
			StaticShiftReg #(
				.LENGTH(r+1),
				.WIDTH(C_WIDTH)
			) l_ssr (
				.clk(clk),
				.rst(1'b0),
				.din(l_str[r*C_WIDTH+:C_WIDTH]),
				.dout(l_char)
			);
			assign l_score = -1-r;
		end else begin
			reg [C_WIDTH-1:0] l_char_reg;
			always @(posedge clk) begin
				l_char_reg <= ROW[r].COL[c-1].l_char;
			end
			assign l_char = l_char_reg;
			assign l_score = ROW[r].COL[c-1].o_score;
		end
		
		if (r == 0 || c == 0) begin
			assign c_score = 0-c-r;
		end else begin
			localparam S_W2 = $clog2(r+c)+1;
			wire signed [S_W2-1:0] signed_temp;
			StaticShiftReg #(
				.LENGTH(1),
				.WIDTH(S_W2)
			) l_ssr (
				.clk(clk),
				.rst(1'b0),
				.din(ROW[r-1].COL[c-1].o_score),
				.dout(signed_temp)
			);
			assign c_score = signed_temp;
		end
		
		Cell #(
			.C_WIDTH(C_WIDTH),
			.S_WIDTH(S_W)
		) cl (
			.clk(clk),
			.l_char(l_char),
			.l_score(l_score),
			.t_char(t_char),
			.t_score(t_score),
			.c_score(c_score),
			.o_score(o_score)
		);
	end
end
endgenerate

StaticShiftReg #(
	.LENGTH(2*S_LEN),
	.WIDTH(1)
) valid_ssr (
	.clk(clk),
	.rst(rst),
	.din(valid_in),
	.dout(valid_out)
);

assign score = ROW[S_LEN-1].COL[S_LEN-1].o_score;

endmodule
