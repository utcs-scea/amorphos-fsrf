// Manages stream data
// 128KB, 2048 packet capacity
// By Joshua Landgraf

module axi_strm (
	input clk,
	input rst,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave  axi_m
);
localparam FIFO_LD = 6;
localparam STAT_FIFO_LD = 11;
localparam DATA_FIFO_LD = 14;

//// Core FIFOs
/*
// Read stat FIFO
// TODO: currently unused
wire rsf_wrreq;
wire [DATA_FIFO_LD+1:0] rsf_data;
wire rsf_full;
wire [DATA_FIFO_LD+1:0] rsf_q;
wire rsf_empty;
wire rsf_rdreq;

HullFIFO #(
	.TYPE(3),
	.WIDTH(DATA_FIFO_LD+2),
	.LOG_DEPTH(STAT_FIFO_LD)
) rd_stat_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rsf_wrreq),
	.data(rsf_data),
	.full(rsf_full),
	.q(rsf_q),
	.empty(rsf_empty),
	.rdreq(rsf_rdreq)
);

// Write stat FIFO
// TODO: currently unused
wire wsf_wrreq;
wire [DATA_FIFO_LD+1:0] wsf_data;
wire wsf_full;
wire [DATA_FIFO_LD+1:0] wsf_q;
wire wsf_empty;
wire wsf_rdreq;

HullFIFO #(
	.TYPE(3),
	.WIDTH(DATA_FIFO_LD+2),
	.LOG_DEPTH(STAT_FIFO_LD)
) wr_stat_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wsf_wrreq),
	.data(wsf_data),
	.full(wsf_full),
	.q(wsf_q),
	.empty(wsf_empty),
	.rdreq(wsf_rdreq)
);
*/

// Data FIFO
logic df_wrreq;
logic [512:0] df_data;
logic df_full;
logic [512:0] df_q;
logic df_empty;
logic df_rdreq;

logic ddf_wrreq;
logic [511:0] ddf_data;
logic ddf_full;
logic [511:0] ddf_q;
logic ddf_empty;
logic ddf_rdreq;

logic udf_wrreq;
logic [0:0] udf_data;
logic udf_full;
logic [0:0] udf_q;
logic udf_empty;
logic udf_rdreq;

assign ddf_wrreq = df_wrreq && !udf_full;
assign udf_wrreq = df_wrreq && !ddf_full;
assign ddf_data = df_data[511:0];
assign udf_data = df_data[512];
assign ddf_rdreq = df_rdreq && !udf_empty;
assign udf_rdreq = df_rdreq && !ddf_empty;

assign df_full = ddf_full || udf_full;
assign df_q = {udf_q, ddf_q};
assign df_empty = ddf_empty || udf_empty;

wire fifo_read = df_rdreq && !df_empty;
wire fifo_write = df_wrreq && !df_full;

/*
HullFIFO #(
	.TYPE(3),
	.WIDTH(513),
	.LOG_DEPTH(DATA_FIFO_LD)
) data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(df_wrreq),
	.data(df_data),
	.full(df_full),
	.q(df_q),
	.empty(df_empty),
	.rdreq(df_rdreq)
);
*/


HullFIFO #(
	.TYPE(3),
	.TYPES("URAM"),
	.WIDTH(512),
	.LOG_DEPTH(DATA_FIFO_LD)
) data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(ddf_wrreq),
	.data(ddf_data),
	.full(ddf_full),
	.q(ddf_q),
	.empty(ddf_empty),
	.rdreq(ddf_rdreq)
);

HullFIFO #(
	.TYPE(3),
	.TYPES("BRAM"),
	.WIDTH(1),
	.LOG_DEPTH(DATA_FIFO_LD)
) user_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(udf_wrreq),
	.data(udf_data),
	.full(udf_full),
	.q(udf_q),
	.empty(udf_empty),
	.rdreq(udf_rdreq)
);


//// Credit system

// Read credits
// New readable data
reg [DATA_FIFO_LD:0] r_creds;
logic add_r_cred = fifo_write;
logic use_r_creds;

// Write credits
// New writable space
reg [DATA_FIFO_LD:0] w_creds;
logic add_w_cred = fifo_read;
logic use_w_creds;

// FIFO read credits
// Current used space
reg [DATA_FIFO_LD:0] fr_creds;
logic add_fr_cred = fifo_write;
logic use_fr_cred = fifo_read;

// FIFO write credits
// Current free space
reg [DATA_FIFO_LD:0] fw_creds;
logic add_fw_cred = fifo_read;
logic use_fw_cred = fifo_write;

// Credit logic
always @(posedge clk) begin
	r_creds <= (use_r_creds ? 0 : r_creds) + add_r_cred;
	w_creds <= (use_w_creds ? 0 : w_creds) + add_w_cred;
	fr_creds <= fr_creds + add_fr_cred - use_fr_cred;
	fw_creds <= fw_creds + add_fw_cred - use_fw_cred;
	
	if (rst) begin
		r_creds <= 0;
		w_creds <= 1 << DATA_FIFO_LD;
		fr_creds <= 0;
		fw_creds <= 1 << DATA_FIFO_LD;
	end
end


//// AXI read interface
enum {READ_IDLE, READ_DATA} read_state;
enum {R_STAT, W_STAT, FR_STAT, FW_STAT, FIFO_DATA} read_sel;

reg [15:0] rid;
reg [7:0] rlen;

always @(posedge clk) begin
	case (read_state)
		READ_IDLE: begin
			rid <= axi_s.arid;
			rlen <= axi_s.arlen;
			// TODO: arsize?
			
			case (axi_s.araddr)
				64'd0:   read_sel <= R_STAT;
				64'd64:  read_sel <= W_STAT;
				64'd128: read_sel <= FR_STAT;
				64'd192: read_sel <= FW_STAT;
				default: read_sel <= FIFO_DATA;
			endcase
			
			if (axi_s.arvalid) read_state <= READ_DATA;
		end
		READ_DATA: begin
			if (axi_s.rready && axi_s.rvalid) begin
				rlen <= rlen - 1;
				
				if (axi_s.rlast) read_state <= READ_IDLE;
			end
		end
	endcase
	
	if (rst) read_state <= READ_IDLE;
end

wire reading = (read_state == READ_DATA);
always_comb begin
	use_r_creds = 0;
	use_w_creds = 0;
	df_rdreq = 0;
	
	axi_s.arready = !reading;
	
	axi_s.rid = rid;
	axi_s.rdata = 0;
	axi_s.rresp = 2'b00;
	axi_s.ruser = 0;
	axi_s.rlast = (rlen == 0);
	axi_s.rvalid = reading;
	
	case (read_sel)
		R_STAT: begin
			axi_s.rdata = r_creds;
			
			use_r_creds = axi_s.rready && axi_s.rvalid;
		end
		W_STAT: begin
			axi_s.rdata = w_creds;
			
			use_w_creds = axi_s.rready && axi_s.rvalid;
		end
		FR_STAT: begin
			axi_s.rdata = fr_creds;
		end
		FW_STAT: begin
			axi_s.rdata = fw_creds;
		end
		FIFO_DATA: begin
			axi_s.rdata = df_q[511:0];
			axi_s.ruser = df_q[512];
			axi_s.rvalid = reading && !df_empty;
			
			df_rdreq = reading && axi_s.rready;
		end
	endcase
end

//// AXI write interface
// B FIFO
logic bf_wrreq;
logic [15:0] bf_data;
logic bf_full;
logic [15:0] bf_q;
logic bf_empty;
logic bf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16),
	.LOG_DEPTH(FIFO_LD)
) b_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(bf_wrreq),
	.data(bf_data),
	.full(bf_full),
	.q(bf_q),
	.empty(bf_empty),
	.rdreq(bf_rdreq)
);

// WLast credits
reg [FIFO_LD:0] wl_creds;
wire have_wl_cred = wl_creds != 0;
logic add_wl_cred;
logic use_wl_cred;

// Logic
always_comb begin
	bf_data = axi_s.awid;
	bf_wrreq = axi_s.awvalid;
	axi_s.awready = !bf_full;
	// TODO: awsize?
	
	df_data = {axi_s.wuser, axi_s.wdata};
	df_wrreq = axi_s.wvalid && !wl_creds[FIFO_LD];
	axi_s.wready = !df_full && !wl_creds[FIFO_LD];
	add_wl_cred = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	
	axi_s.bid = bf_q;
	axi_s.bresp = 2'b00;
	axi_s.bvalid = !bf_empty && have_wl_cred;
	bf_rdreq = axi_s.bready && have_wl_cred;
	use_wl_cred = axi_s.bready && axi_s.bvalid;
end

always @(posedge clk) begin
	wl_creds <= wl_creds + add_wl_cred - use_wl_cred;
	
	if (rst) wl_creds <= 0;
end


endmodule
