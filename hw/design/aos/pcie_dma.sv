// PCIM DMA Controller
// Joshua Landgraf

typedef struct packed {
	logic fpga_read;
	logic [1:0] channel;
	logic [15:0] count;
	logic [5:0] pcie_sel;
	logic [23:0] fpga_addr;
	logic [14:0] padding;
} PCIM_CMD;

module pcim_dma (
	// General signals
	input clk,
	input rst,
	
	// SoftReg control interface
	input  SoftRegReq  softreg_req,
	output SoftRegResp softreg_resp,
	
	// PCIM and DRAM interfaces
	axi_bus_t.slave dram_dma
);
localparam FIFO_LD = 6;

wire sr_read  = softreg_req.valid && !softreg_req.isWrite;
wire sr_write = softreg_req.valid &&  softreg_req.isWrite;

//// AXI IDs
// 0 : DRAM
// 1 : PCIM

//// Manage address RAM
reg [63:0] pcie_addrs [63:0];

wire ram_write = sr_write && (softreg_req.addr < 32'd512);
always @(posedge clk) begin
	if (ram_write) pcie_addrs[softreg_req.addr[8:3]] <= softreg_req.data;
end

//// Buffer SoftReg commands
logic srf_wrreq;
logic [63:0] srf_data;
logic srf_full;
logic [63:0] srf_q;
logic srf_empty;
logic srf_rdreq;

assign srf_wrreq = sr_write && (softreg_req.addr == 32'd2048);
assign srf_data = softreg_req.data;
//assign srf_rdreq = TODO; // will assign later

PCIM_CMD srf_cmd = srf_q;

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(5)
) sr_req_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(srf_wrreq),
	.data(srf_data),
	.full(srf_full),
	.q(srf_q),
	.empty(srf_empty),
	.rdreq(srf_rdreq)
);

//// Buffer write addresses
logic awf_wrreq;
logic [71:0] awf_data;
logic awf_full;
logic [71:0] awf_q;
logic awf_empty;
logic awf_rdreq;

//assign awf_wrreq = TODO; // will assign later
//assign awf_data = TODO; // will assign later
//assign awf_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(8+64),
	.LOG_DEPTH(FIFO_LD)
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

//// Buffer channel info
logic cif_wrreq;
logic [1:0] cif_data;
logic cif_full;
logic [1:0] cif_q;
logic cif_empty;
logic cif_rdreq;

//assign cif_wrreq = TODO; // will assign later
//assign cif_data = TODO; // will assign later
//assign cif_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(2),
	.LOG_DEPTH(FIFO_LD)
) ci_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(cif_wrreq),
	.data(cif_data),
	.full(cif_full),
	.q(cif_q),
	.empty(cif_empty),
	.rdreq(cif_rdreq)
);

//// Buffer data
logic df_wrreq;
logic [512:0] df_data;
logic df_full;
logic [512:0] df_q;
logic df_empty;
logic df_rdreq;

assign dram_dma.rready = !df_full;
assign df_wrreq = dram_dma.rvalid;
assign df_data = {dram_dma.rdata, dram_dma.rlast};
assign {dram_dma.wdata, dram_dma.wlast} = df_q;
assign dram_dma.wuser = 0;   // TODO: packetize?
assign dram_dma.wstrb = 64'hFFFFFFFFFFFFFFFF;
assign df_rdreq = dram_dma.wready;
assign dram_dma.wvalid = !df_empty;

HullFIFO #(
	.TYPE(3),
	.WIDTH(512+1),
	.LOG_DEPTH(9)
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

//// Write credits
reg [FIFO_LD:0] aw_creds;
wire have_aw_cred = aw_creds != 0;
logic add_aw_cred;
logic use_aw_cred;

reg rfirst;

always @(posedge clk) begin
	aw_creds <= aw_creds - use_aw_cred + add_aw_cred;
	
	if (dram_dma.rready && dram_dma.rvalid) rfirst <= dram_dma.rlast;
	
	if (rst) begin
		aw_creds <= 0;
		
		rfirst <= 1;
	end
end

//// Logic
reg [1:0] state;
PCIM_CMD cmd;
reg [63:0] counts [3:0];
reg [63:0] pcie_addr;

logic [63:0] fpga_addr;
always_comb begin
	fpga_addr = {28'h0000000, cmd.fpga_addr, 12'h000};
	
	srf_rdreq = state == 0;
	
	dram_dma.arid = 0;
	dram_dma.araddr = cmd.fpga_read ? fpga_addr : pcie_addr;
	dram_dma.arlen = (cmd.count <= 63) ? cmd.count[7:0] : 8'd63;
	dram_dma.arsize = 3'b110;
	dram_dma.arvalid = (state == 1);
	
	dram_dma.awid = 0;
	dram_dma.awaddr = awf_q[63:0];
	dram_dma.awlen = awf_q[71:64];
	dram_dma.awsize = 3'b110;
	dram_dma.awvalid = !awf_empty && have_aw_cred;
	
	dram_dma.bready = !cif_empty;
	
	awf_wrreq = (state == 2);
	awf_data[63:0] = cmd.fpga_read ? pcie_addr : fpga_addr;
	awf_data[71:64] = dram_dma.arlen;
	awf_rdreq = dram_dma.awready && dram_dma.awvalid;
	
	add_aw_cred = dram_dma.rready && dram_dma.rvalid && rfirst;
	use_aw_cred = dram_dma.awready && dram_dma.awvalid;
	
	cif_wrreq = state == 3;
	cif_data = cmd.channel;
	cif_rdreq = dram_dma.bvalid;
end
always @(posedge clk) begin
	case (state)
		0: begin
			cmd <= srf_q;
			pcie_addr <= pcie_addrs[srf_cmd.pcie_sel];
			if (!srf_empty) begin
				state <= 1;
			end
		end
		1: begin
			if (dram_dma.arready) begin
				state <= 2;
			end
		end
		2: begin
			if (!awf_full) begin
				state <= 3;
			end
		end
		3: begin
			if (!cif_full) begin
				if (cmd.count <= 63) begin
					state <= 0;
				end else begin
					state <= 1;
				end
				cmd.count <= cmd.count - 64;
				cmd.fpga_addr <= cmd.fpga_addr + 1;
				pcie_addr <= {pcie_addr[63:12] + 1, 12'h000};
			end
		end
	endcase
	
	for (integer i = 0; i < 4; i = i + 1) begin
		if (!cif_empty && cif_rdreq && (cif_q == i)) counts[i] <= counts[i] + 1;
		if (rst) counts[i] <= 0;
	end
	
	softreg_resp.valid <= sr_read;
	softreg_resp.data <= counts[softreg_req.addr[4:3]];
	
	if (rst) state <= 0;
end

endmodule


module axi_arb (
	input clk,
	input rst_n,
	
	axi_bus_t.master axi_m0,
	axi_bus_t.master axi_m1,
	axi_bus_t.slave axi_s
);
localparam FIFO_LD = 6;

//// Buffer arb_w
logic bwf_wrreq;
logic bwf_data;
logic bwf_full;
logic bwf_q;
logic bwf_empty;
logic bwf_rdreq;

//assign bwf_wrreq = TODO; // will assign later
//assign bwf_data = TODO; // will assign later
//assign bwf_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(1),
	.LOG_DEPTH(FIFO_LD)
) arb_w_fifo (
	.clock(clk),
	.reset_n(rst_n),
	.wrreq(bwf_wrreq),
	.data(bwf_data),
	.full(bwf_full),
	.q(bwf_q),
	.empty(bwf_empty),
	.rdreq(bwf_rdreq)
);

reg arb = 0;
//always @(posedge clk) arb <= ~arb;

reg arb_ar, arb_r, arb_aw, arb_w, arb_b;
always_comb begin
	arb_ar = arb ? axi_m1.arvalid : !axi_m0.arvalid;
	axi_s.arid = {arb_ar ? axi_m1.arid : axi_m0.arid, arb_ar};
	axi_s.araddr = arb_ar ? axi_m1.araddr : axi_m0.araddr;
	axi_s.arlen = arb_ar ? axi_m1.arlen : axi_m0.arlen;
	axi_s.arsize = arb_ar ? axi_m1.arsize : axi_m0.arsize;
	axi_s.arvalid = arb_ar ? axi_m1.arvalid : axi_m0.arvalid;
	axi_m0.arready = arb_ar ? 0 : axi_s.arready;
	axi_m1.arready = arb_ar ? axi_s.arready : 0;
	
	arb_r = axi_s.rid[0];
	axi_m0.rid = arb_r ? 0 : axi_s.rid[15:1];
	axi_m0.rdata = arb_r ? 0 : axi_s.rdata;
	axi_m0.rresp = arb_r ? 0 : axi_s.rresp;
	axi_m0.rlast = arb_r ? 0 : axi_s.rlast;
	axi_m0.ruser = arb_r ? 0 : axi_s.ruser;
	axi_m0.rvalid = arb_r ? 0 : axi_s.rvalid;
	axi_m1.rid = arb_r ? axi_s.rid[15:1] : 0;
	axi_m1.rdata = arb_r ? axi_s.rdata : 0;
	axi_m1.rresp = arb_r ? axi_s.rresp : 0;
	axi_m1.rlast = arb_r ? axi_s.rlast : 0;
	axi_m1.ruser = arb_r ? axi_s.ruser : 0;
	axi_m1.rvalid = arb_r ? axi_s.rvalid : 0;
	axi_s.rready = arb_r ? axi_m1.rready : axi_m0.rready;
	
	arb_aw = arb ? axi_m1.awvalid : !axi_m0.awvalid;
	axi_s.awid = {arb_aw ? axi_m1.awid : axi_m0.awid, arb_aw};
	axi_s.awaddr = arb_aw ? axi_m1.awaddr : axi_m0.awaddr;
	axi_s.awlen = arb_aw ? axi_m1.awlen : axi_m0.awlen;
	axi_s.awsize = arb_aw ? axi_m1.awsize : axi_m0.awsize;
	axi_s.awvalid = (arb_aw ? axi_m1.awvalid : axi_m0.awvalid) && !bwf_full;
	axi_m0.awready = arb_aw ? 0 : (axi_s.awready && !bwf_full);
	axi_m1.awready = arb_aw ? (axi_s.awready && !bwf_full) : 0;
	
	bwf_wrreq = axi_s.awvalid && axi_s.awready;
	bwf_data = arb_aw;
	bwf_rdreq = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	
	arb_w = bwf_q;
	axi_s.wdata = arb_w ? axi_m1.wdata : axi_m0.wdata;
	axi_s.wstrb = arb_w ? axi_m1.wstrb : axi_m0.wstrb;
	axi_s.wlast = arb_w ? axi_m1.wlast : axi_m0.wlast;
	axi_s.wvalid = (arb_w ? axi_m1.wvalid : axi_m0.wvalid) && !bwf_empty;
	axi_m0.wready = arb_w ? 0 : (axi_s.wready && !bwf_empty);
	axi_m1.wready = arb_w ? (axi_s.wready && !bwf_empty) : 0;
	
	arb_b = axi_s.bid[0];
	axi_m0.bid = arb_b ? 0 : axi_s.bid[15:1];
	axi_m0.bresp = arb_b ? 0 : axi_s.bresp;
	axi_m0.bvalid = arb_b ? 0 : axi_s.bvalid;
	axi_m1.bid = arb_b ? axi_s.bid[15:1] : 0;
	axi_m1.bresp = arb_b ? axi_s.bresp : 0;
	axi_m1.bvalid = arb_b ? axi_s.bvalid : 0;
	axi_s.bready = arb_b ? axi_m1.bready : axi_m0.bready;
end

endmodule


module pcie_dma (
	// General signals
	input clk,
	input rst_n [2:0],
	
	// SoftReg control interface
	input  SoftRegReq  softreg_req,
	output SoftRegResp softreg_resp,
	
	// DRAM interface
	axi_bus_t.master sh_cl_pcis,
	axi_bus_t.slave  dram_dma
);

axi_bus_t dma_pcis_rs0 ();
axi_bus_t dma_pcis_rs1 ();
axi_bus_t dma_pcis ();
axi_bus_t dma_pcim_rs ();
axi_bus_t dma_pcim ();
axi_bus_t dram_dma_rs ();


// AXI4 Register Slice for dma_pcis interface
axi_reg pcis_src_reg (
	.clk(clk),
	.rst_n(rst_n[0]),
	
	.axi_s(sh_cl_pcis),
	.axi_m(dma_pcis_rs0)
);

axi_reg pcis_mid_reg (
	.clk(clk),
	.rst_n(rst_n[0]),
	
	.axi_s(dma_pcis_rs0),
	.axi_m(dma_pcis_rs1)
);

axi_reg pcis_dst_reg (
	.clk(clk),
	.rst_n(rst_n[1]),
	
	.axi_s(dma_pcis_rs1),
	.axi_m(dma_pcis)
);

pcim_dma pd (
	.clk(clk),
	.rst(!rst_n[1]),
	
	.softreg_req(softreg_req),
	.softreg_resp(softreg_resp),
	
	.dram_dma(dma_pcim)
);

axi_arb pcie_arb (
	.clk(clk),
	.rst_n(rst_n[1]),
	
	.axi_m0(dma_pcis),
	.axi_m1(dma_pcim),
	.axi_s(dram_dma_rs)
);

/*
axi_buf pcie_ab (
	.clk(clk),
	.rst(!rst_n[1]),
	
	.axi_s(dram_dma_rs),
	.axi_m(dram_dma)
);*/

axi_reg pcie_reg (
	.clk(clk),
	.rst_n(rst_n[1]),
	
	.axi_s(dram_dma_rs),
	.axi_m(dram_dma)
);

endmodule
