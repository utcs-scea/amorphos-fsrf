// PCIM DMA Controller
// Joshua Landgraf

typedef struct packed {
	logic dram_read;
	logic [1:0] channel;
	logic [8:0] count;
	logic [23:0] dram_addr;
	logic [27:0] pcie_addr;
} PCIM_CMD;

module pcim_dma (
	// General signals
	input clk,
	input rst,
	
	// SoftReg control interface
	input  SoftRegReq  softreg_req,
	output SoftRegResp softreg_resp,
	
	// PCIM and DRAM interfaces
	axi_bus_t.slave cl_sh_pcim,
	axi_bus_t.slave dram_dma
);
localparam FIFO_LD = 6;

wire sr_read  = softreg_req.valid && !softreg_req.isWrite;
wire sr_write = softreg_req.valid &&  softreg_req.isWrite;

//// Buffer SoftReg commands
logic srf_wrreq;
logic [63:0] srf_data;
logic srf_full;
logic [63:0] srf_q;
logic srf_empty;
logic srf_rdreq;

assign srf_wrreq = sr_write;
assign srf_data = softreg_req.data;
//assign srf_rdreq = TODO; // will assign later

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

//// Buffer DRAM write addresses
logic dwf_wrreq;
logic [63:0] dwf_data;
logic dwf_full;
logic [63:0] dwf_q;
logic dwf_empty;
logic dwf_rdreq;

//assign dwf_wrreq = TODO; // will assign later
//assign dwf_data = TODO; // will assign later
//assign dwf_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(FIFO_LD)
) dw_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(dwf_wrreq),
	.data(dwf_data),
	.full(dwf_full),
	.q(dwf_q),
	.empty(dwf_empty),
	.rdreq(dwf_rdreq)
);

//// Buffer PCIe write addresses
logic pwf_wrreq;
logic [63:0] pwf_data;
logic pwf_full;
logic [63:0] pwf_q;
logic pwf_empty;
logic pwf_rdreq;

//assign pwf_wrreq = TODO; // will assign later
//assign pwf_data = TODO; // will assign later
//assign pwf_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(FIFO_LD)
) pw_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pwf_wrreq),
	.data(pwf_data),
	.full(pwf_full),
	.q(pwf_q),
	.empty(pwf_empty),
	.rdreq(pwf_rdreq)
);

//// Buffer channel info
logic cif_wrreq;
logic [2:0] cif_data;
logic cif_full;
logic [2:0] cif_q;
logic cif_empty;
logic cif_rdreq;

//assign cif_wrreq = TODO; // will assign later
//assign cif_data = TODO; // will assign later
//assign cif_rdreq = TODO; // will assign later

HullFIFO #(
	.TYPE(0),
	.WIDTH(3),
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

//// Buffer DRAM data for PCIe
logic dpf_wrreq;
logic [512:0] dpf_data;
logic dpf_full;
logic [512:0] dpf_q;
logic dpf_empty;
logic dpf_rdreq;

assign dram_dma.rready = !dpf_full;
assign dpf_wrreq = dram_dma.rvalid;
assign dpf_data = {dram_dma.rdata, dram_dma.rlast};
assign {cl_sh_pcim.wdata, cl_sh_pcim.wlast} = dpf_q;
assign cl_sh_pcim.wstrb = 64'hFFFFFFFFFFFFFFFF;
assign dpf_rdreq = cl_sh_pcim.wready;
assign cl_sh_pcim.wvalid = !dpf_empty;

HullFIFO #(
	.TYPE(3),
	.WIDTH(512+1),
	.LOG_DEPTH(9)
) dram_pcie_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(dpf_wrreq),
	.data(dpf_data),
	.full(dpf_full),
	.q(dpf_q),
	.empty(dpf_empty),
	.rdreq(dpf_rdreq)
);

//// Buffer PCIe data for DRAM
logic pdf_wrreq;
logic [512:0] pdf_data;
logic pdf_full;
logic [512:0] pdf_q;
logic pdf_empty;
logic pdf_rdreq;

assign cl_sh_pcim.rready = !pdf_full;
assign pdf_wrreq = cl_sh_pcim.rvalid;
assign pdf_data = {cl_sh_pcim.rdata, cl_sh_pcim.rlast};
assign {dram_dma.wdata, dram_dma.wlast} = pdf_q;
assign dram_dma.wuser = 0;   // TODO: packetize?
assign dram_dma.wstrb = 64'hFFFFFFFFFFFFFFFF;
assign pdf_rdreq = dram_dma.wready;
assign dram_dma.wvalid = !pdf_empty;

HullFIFO #(
	.TYPE(3),
	.TYPES("URAM"),
	.WIDTH(512+1),
	.LOG_DEPTH(12)
) pcie_dram_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pdf_wrreq),
	.data(pdf_data),
	.full(pdf_full),
	.q(pdf_q),
	.empty(pdf_empty),
	.rdreq(pdf_rdreq)
);

//// Write credits
reg [FIFO_LD:0] dw_creds;
wire have_dw_cred = dw_creds != 0;
logic add_dw_cred;
logic use_dw_cred;

reg [FIFO_LD:0] db_creds;
wire have_db_cred = db_creds != 0;
logic add_db_cred;
logic use_db_cred;

reg [FIFO_LD:0] pw_creds;
wire have_pw_cred = pw_creds != 0;
logic add_pw_cred;
logic use_pw_cred;

reg [FIFO_LD:0] pb_creds;
wire have_pb_cred = pb_creds != 0;
logic add_pb_cred;
logic use_pb_cred;

reg dd_first;
reg pd_first;

always @(posedge clk) begin
	dw_creds <= dw_creds - use_dw_cred + add_dw_cred;
	db_creds <= db_creds - use_db_cred + add_db_cred;
	pw_creds <= pw_creds - use_pw_cred + add_pw_cred;
	pb_creds <= pb_creds - use_pb_cred + add_pb_cred;
	
	if (dram_dma.rready && dram_dma.rvalid) dd_first <= dram_dma.rlast;
	if (cl_sh_pcim.rready && cl_sh_pcim.rvalid) pd_first <= cl_sh_pcim.rlast;
	
	if (rst) begin
		dw_creds <= 0;
		db_creds <= 0;
		pw_creds <= 0;
		pb_creds <= 0;
		
		dd_first <= 1;
		pd_first <= 1;
	end
end

//// Logic
reg [1:0] state;
PCIM_CMD cmd;
reg [63:0] counts [3:0];

always_comb begin
	cl_sh_pcim.awid = 0;
	cl_sh_pcim.awaddr = pwf_q;
	cl_sh_pcim.awlen = 8'h3F;
	cl_sh_pcim.awsize = 3'b110;
	cl_sh_pcim.awvalid = !pwf_empty && have_pw_cred;
	
	cl_sh_pcim.arid = 0;
	cl_sh_pcim.araddr = {24'h000000, cmd.pcie_addr, 12'h000};
	cl_sh_pcim.arlen = 8'h3F;
	cl_sh_pcim.arsize = 3'b110;
	cl_sh_pcim.arvalid = (state == 1) && !cmd.dram_read;
	
	cl_sh_pcim.bready = 1;
	
	dram_dma.awid = 0;
	dram_dma.awaddr = dwf_q;
	dram_dma.awlen = 8'h3F;
	dram_dma.awsize = 3'b110;
	dram_dma.awvalid = !dwf_empty & have_dw_cred;
	
	dram_dma.arid = 0;
	dram_dma.araddr = {28'h0000000, cmd.dram_addr, 12'h000};
	dram_dma.arlen = 8'h3F;
	dram_dma.arsize = 3'b110;
	dram_dma.arvalid = (state == 1) && cmd.dram_read;
	
	dram_dma.bready = 1;
	
	add_dw_cred = cl_sh_pcim.rready && cl_sh_pcim.rvalid && pd_first;
	use_dw_cred = dram_dma.awready && dram_dma.awvalid;
	
	add_db_cred = dram_dma.bvalid;
	use_db_cred = !cif_empty && cif_rdreq && !cif_q[0];
	
	add_pw_cred = dram_dma.rready && dram_dma.rvalid && dd_first;
	use_pw_cred = cl_sh_pcim.awready && cl_sh_pcim.awvalid;

	add_pb_cred = cl_sh_pcim.bvalid;
	use_pb_cred = !cif_empty && cif_rdreq && cif_q[0];
	
	srf_rdreq = state == 0;
	
	dwf_wrreq = (state == 2) && !cmd.dram_read;
	dwf_data  = {28'h0000000, cmd.dram_addr, 12'h000};
	dwf_rdreq = dram_dma.awready && dram_dma.awvalid;
	
	pwf_wrreq = (state == 2) && cmd.dram_read;
	pwf_data  = {24'h000000, cmd.pcie_addr, 12'h000};
	pwf_rdreq = cl_sh_pcim.awready && cl_sh_pcim.awvalid;
	
	cif_wrreq = state == 3;
	cif_data = {cmd.channel, cmd.dram_read};
	cif_rdreq = cif_q[0] ? have_pb_cred : have_db_cred;
end
always @(posedge clk) begin
	case (state)
		0: begin
			if (!srf_empty) begin
				cmd <= srf_q;
				state <= 1;
			end
		end
		1: begin
			if (cmd.dram_read ? dram_dma.arready : cl_sh_pcim.arready) begin
				state <= 2;
			end
		end
		2: begin
			if (cmd.dram_read ? !pwf_full : !dwf_full) begin
				state <= 3;
			end
		end
		3: begin
			if (!cif_full) begin
				if (cmd.count == 0) begin
					state <= 0;
				end else begin
					state <= 1;
				end
				cmd.count <= cmd.count - 1;
				cmd.dram_addr <= cmd.dram_addr + 1;
				cmd.pcie_addr <= cmd.pcie_addr + 1;
				
			end
		end
	endcase
	
	for (integer i = 0; i < 4; i = i + 1) begin
		//if (sr_read && (softreg_req.addr[4:3] == i)) counts[i] <= 0;
		if (!cif_empty && cif_rdreq && (cif_q[2:1] == i)) counts[i] <= counts[i] + 1;
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
localparam FIFO_LD = 5;

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
	
	// PCIM
	// Write address channel
	output logic [15:0]  cl_sh_pcim_awid,
	output logic [63:0]  cl_sh_pcim_awaddr,
	output logic [7:0]   cl_sh_pcim_awlen,
	output logic [2:0]   cl_sh_pcim_awsize,
	output logic [18:0]  cl_sh_pcim_awuser,   // RESERVED (not used)
	output logic         cl_sh_pcim_awvalid,
	input  logic         sh_cl_pcim_awready,
	
	// Write data channel
	output logic [511:0] cl_sh_pcim_wdata,
	output logic [63:0]  cl_sh_pcim_wstrb,
	output logic         cl_sh_pcim_wlast,
	output logic         cl_sh_pcim_wvalid,
	input  logic         sh_cl_pcim_wready,
	
	// Write response channel
	input  logic [15:0]  sh_cl_pcim_bid,
	input  logic [1:0]   sh_cl_pcim_bresp,
	input  logic         sh_cl_pcim_bvalid,
	output logic         cl_sh_pcim_bready,
	
	// Read address channel
	// Note max 32 outstanding txns are supported, width is larger to allow bits for AXI fabrics
	output logic [15:0]  cl_sh_pcim_arid,
	output logic [63:0]  cl_sh_pcim_araddr,
	output logic [7:0]   cl_sh_pcim_arlen,
	output logic [2:0]   cl_sh_pcim_arsize,
	output logic [18:0]  cl_sh_pcim_aruser,   // RESERVED (not used)
	output logic         cl_sh_pcim_arvalid,
	input  logic         sh_cl_pcim_arready,
	
	// Read data channel
	input  logic [15:0]  sh_cl_pcim_rid,
	input  logic [511:0] sh_cl_pcim_rdata,
	input  logic [1:0]   sh_cl_pcim_rresp,
	input  logic         sh_cl_pcim_rlast,
	input  logic         sh_cl_pcim_rvalid,
	output logic         cl_sh_pcim_rready,
	
	/// PCIS
	// Write address channel
	input  logic [5:0]   sh_cl_dma_pcis_awid,
	input  logic [63:0]  sh_cl_dma_pcis_awaddr,
	input  logic [7:0]   sh_cl_dma_pcis_awlen,
	input  logic [2:0]   sh_cl_dma_pcis_awsize,
	input  logic         sh_cl_dma_pcis_awvalid,
	output logic         cl_sh_dma_pcis_awready,
	
	// Write data channel
	input  logic [511:0] sh_cl_dma_pcis_wdata,
	input  logic [63:0]  sh_cl_dma_pcis_wstrb,
	input  logic         sh_cl_dma_pcis_wlast,
	input  logic         sh_cl_dma_pcis_wvalid,
	output logic         cl_sh_dma_pcis_wready,
	
	// Write response channel
	output logic [5:0]   cl_sh_dma_pcis_bid,
	output logic [1:0]   cl_sh_dma_pcis_bresp,
	output logic         cl_sh_dma_pcis_bvalid,
	input  logic         sh_cl_dma_pcis_bready,
	
	// Read address channel
	input  logic [5:0]   sh_cl_dma_pcis_arid,
	input  logic [63:0]  sh_cl_dma_pcis_araddr,
	input  logic [7:0]   sh_cl_dma_pcis_arlen,
	input  logic [2:0]   sh_cl_dma_pcis_arsize,
	input  logic         sh_cl_dma_pcis_arvalid,
	output logic         cl_sh_dma_pcis_arready,
	
	// Read data channel
	output logic [5:0]   cl_sh_dma_pcis_rid,
	output logic [511:0] cl_sh_dma_pcis_rdata,
	output logic [1:0]   cl_sh_dma_pcis_rresp,
	output logic         cl_sh_dma_pcis_rlast,
	output logic         cl_sh_dma_pcis_rvalid,
	input  logic         sh_cl_dma_pcis_rready,
	
	// Other shell signals
	// Max payload size - 00:128B, 01:256B, 10:512B
	input[1:0]          cfg_max_payload,
	// Max read requst size - 000b:128B, 001b:256B, 010b:512B, 011b:1024B, 100b-2048B, 101b:4096B
	input[2:0]          cfg_max_read_req,
	
	// SoftReg control interface
	input  SoftRegReq  softreg_req,
	output SoftRegResp softreg_resp,
	
	// DRAM interface
	axi_bus_t.slave dram_dma
);

axi_bus_t sh_cl_pcis ();
axi_bus_t dma_pcis_rs0 ();
axi_bus_t dma_pcis_rs1 ();
axi_bus_t dma_pcis ();
axi_bus_t cl_sh_pcim ();
axi_bus_t dma_pcim_rs ();
axi_bus_t dma_pcim ();
axi_bus_t dram_dma_rs ();

// PCIS interface bridge
always_comb begin
	sh_cl_pcis.awid = sh_cl_dma_pcis_awid;
	sh_cl_pcis.awaddr = sh_cl_dma_pcis_awaddr;
	sh_cl_pcis.awlen = sh_cl_dma_pcis_awlen;
	sh_cl_pcis.awsize = sh_cl_dma_pcis_awsize;
	sh_cl_pcis.awvalid = sh_cl_dma_pcis_awvalid;
	cl_sh_dma_pcis_awready = sh_cl_pcis.awready;
	
	sh_cl_pcis.wdata = sh_cl_dma_pcis_wdata;
	sh_cl_pcis.wstrb = sh_cl_dma_pcis_wstrb;
	sh_cl_pcis.wlast = sh_cl_dma_pcis_wlast;
	sh_cl_pcis.wvalid = sh_cl_dma_pcis_wvalid;
	cl_sh_dma_pcis_wready = sh_cl_pcis.wready;
	
	cl_sh_dma_pcis_bid = sh_cl_pcis.bid;
	cl_sh_dma_pcis_bresp = sh_cl_pcis.bresp;
	cl_sh_dma_pcis_bvalid = sh_cl_pcis.bvalid;
	sh_cl_pcis.bready = sh_cl_dma_pcis_bready;
	
	sh_cl_pcis.arid = sh_cl_dma_pcis_arid;
	sh_cl_pcis.araddr = sh_cl_dma_pcis_araddr;
	sh_cl_pcis.arlen = sh_cl_dma_pcis_arlen;
	sh_cl_pcis.arsize = sh_cl_dma_pcis_arsize;
	sh_cl_pcis.arvalid = sh_cl_dma_pcis_arvalid;
	cl_sh_dma_pcis_arready = sh_cl_pcis.arready;
	
	cl_sh_dma_pcis_rid = sh_cl_pcis.rid;
	cl_sh_dma_pcis_rdata = sh_cl_pcis.rdata;
	cl_sh_dma_pcis_rresp = sh_cl_pcis.rresp;
	cl_sh_dma_pcis_rlast = sh_cl_pcis.rlast;
	//cl_sh_dma_pcis_ruser = sh_cl_pcis.ruser;
	cl_sh_dma_pcis_rvalid = sh_cl_pcis.rvalid;
	sh_cl_pcis.rready = sh_cl_dma_pcis_rready;
end

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

// PCIM interface bridge
always_comb begin
	cl_sh_pcim_awid = cl_sh_pcim.awid;
	cl_sh_pcim_awaddr = cl_sh_pcim.awaddr;
	cl_sh_pcim_awlen = cl_sh_pcim.awlen;
	cl_sh_pcim_awsize = cl_sh_pcim.awsize;
	//cl_sh_pcim_awuser = 0;
	cl_sh_pcim_awvalid = cl_sh_pcim.awvalid;
	cl_sh_pcim.awready = sh_cl_pcim_awready;
	
	cl_sh_pcim_wdata = cl_sh_pcim.wdata;
	cl_sh_pcim_wstrb = cl_sh_pcim.wstrb;
	cl_sh_pcim_wlast = cl_sh_pcim.wlast;
	cl_sh_pcim_wvalid = cl_sh_pcim.wvalid;
	cl_sh_pcim.wready = sh_cl_pcim_wready;
	
	cl_sh_pcim.bid = sh_cl_pcim_bid;
	cl_sh_pcim.bresp = sh_cl_pcim_bresp;
	cl_sh_pcim.bvalid = sh_cl_pcim_bvalid;
	cl_sh_pcim_bready = cl_sh_pcim.bready;
	
	cl_sh_pcim_arid = cl_sh_pcim.arid;
	cl_sh_pcim_araddr = cl_sh_pcim.araddr;
	cl_sh_pcim_arlen = cl_sh_pcim.arlen;
	cl_sh_pcim_arsize = cl_sh_pcim.arsize;
	//cl_sh_pcim_aruser = 0;
	cl_sh_pcim_arvalid = cl_sh_pcim.arvalid;
	cl_sh_pcim.arready = sh_cl_pcim_arready;
	
	cl_sh_pcim.rid = sh_cl_pcim_rid;
	cl_sh_pcim.rdata = sh_cl_pcim_rdata;
	cl_sh_pcim.rresp = sh_cl_pcim_rresp;
	cl_sh_pcim.rlast = sh_cl_pcim_rlast;
	//cl_sh_pcim.ruser = sh_cl_pcim_ruser;
	cl_sh_pcim.rvalid = sh_cl_pcim_rvalid;
	cl_sh_pcim_rready = cl_sh_pcim.rready;
end

pcim_dma pd (
	.clk(clk),
	.rst(!rst_n[1]),
	
	.softreg_req(softreg_req),
	.softreg_resp(softreg_resp),
	
	.cl_sh_pcim(cl_sh_pcim),
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
