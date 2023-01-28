// Reset signal pipe

module rst_pipe (
	input clk,
	input rst_n_in,
	
	output rst_n
);

logic rst_n_mid;
logic rst_n_out;

lib_pipe #(.WIDTH(1), .STAGES(3)) rst_pipe_mid (.clk(clk), .rst_n(1'b1), .in_bus(rst_n_in),  .out_bus(rst_n_mid));
lib_pipe #(.WIDTH(1), .STAGES(3)) rst_pipe_out (.clk(clk), .rst_n(1'b1), .in_bus(rst_n_mid), .out_bus(rst_n_out));

assign rst_n =  rst_n_out;

endmodule
