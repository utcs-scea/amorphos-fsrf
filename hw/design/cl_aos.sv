/*

    Top level module for running on an F1 instance

    Written by Ahmed Khawaja

*/

import ShellTypes::*;
import UserParams::*;

module cl_aos (
   `include "cl_ports.vh" // Fixed port definition
);

`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_aos_defines.vh" // CL Defines for cl_hello_world

// CL Version

`ifndef CL_VERSION
   `define CL_VERSION 32'hee_ee_ee_00
`endif

//--------------------------------------------
// Start with Tie-Off of Unused Interfaces
//--------------------------------------------
// the developer should use the next set of `include
// to properly tie-off any unused interface
// The list is put in the top of the module
// to avoid cases where developer may forget to
// remove it from the end of the file

// User defined interrupts, NOT USED
`include "unused_apppf_irq_template.inc"
// Function level reset, NOT USED
`include "unused_flr_template.inc"
// Main PCI-e in/out interfaces, currently not used
//`include "unused_pcim_template.inc"
//`include "unused_dma_pcis_template.inc"
// Unused AXIL interfaces
`include "unused_cl_sda_template.inc"
//`include "unused_sh_ocl_template.inc"
//`include "unused_sh_bar1_template.inc"
// Unused DDR
`include "unused_ddr_a_b_d_template.inc"


//------------------------------------
// Globals
//------------------------------------

// Parameterization
localparam F1_NUM_APPS = UserParams::NUM_APPS;
localparam F1_CONFIG_APPS = UserParams::CONFIG_APPS;

// Gen vars
genvar i;
genvar g;
genvar app_num;

// Clock
logic global_clk = clk_main_a0;

// Reset synchronization
logic rst_n [2:0];

(* KEEP_HIERARCHY = "TRUE" *) rst_pipe slr2_rp (
	.clk(global_clk),
	.rst_n_in(rst_main_n),
	.rst_n(rst_n[2])
);
(* KEEP_HIERARCHY = "TRUE" *) rst_pipe slr1_rp (
	.clk(global_clk),
	.rst_n_in(rst_main_n),
	.rst_n(rst_n[1])
);
(* KEEP_HIERARCHY = "TRUE" *) rst_pipe slr0_rp (
	.clk(global_clk),
	.rst_n_in(rst_main_n),
	.rst_n(rst_n[0])
);


//------------------------------------
// System SoftReg
//------------------------------------

// Mapped onto BAR1
/*
|----- AppPF  
|   |------- BAR1
|   |         * 32-bit BAR, non-prefetchable
|   |         * 2MiB (0 to 0x1F-FFFF)
|   |         * Maps to BAR1 AXI-L of the CL
|   |         * Typically used for CL application registers 
*/

// AXIL2SR to AmorphOS System
SoftRegReq  sys_softreg_req[7:0];
SoftRegReq  sys_softreg_req_[7:0];
SoftRegReq  sys_softreg_req_buf;
logic       sys_softreg_req_grant;

SoftRegResp sys_softreg_resp[7:0];
SoftRegResp sys_softreg_resp_[7:0];
SoftRegResp sys_softreg_resp_buf;
logic       sys_softreg_resp_grant;

AXIL2SR sys_axil2sr (
	// General Signals
	.clk(global_clk),
	.rst(!rst_n[1]), // expects active high
	
	// Write Address
	.sh_awvalid(sh_bar1_awvalid),
	.sh_awaddr(sh_bar1_awaddr),
	.sh_awready(bar1_sh_awready),
	
	//Write data
	.sh_wvalid(sh_bar1_wvalid),
	.sh_wdata(sh_bar1_wdata),
	.sh_wstrb(sh_bar1_wstrb),
	.sh_wready(bar1_sh_wready),
	
	//Write response
	.sh_bvalid(bar1_sh_bvalid),
	.sh_bresp(bar1_sh_bresp),
	.sh_bready(sh_bar1_bready),
	
	//Read address
	.sh_arvalid(sh_bar1_arvalid),
	.sh_araddr(sh_bar1_araddr),
	.sh_arready(bar1_sh_arready),
	
	//Read data/response
	.sh_rvalid(bar1_sh_rvalid),
	.sh_rdata(bar1_sh_rdata),
	.sh_rresp(bar1_sh_rresp),
	.sh_rready(sh_bar1_rready),
	
	// Interface to SoftReg
	// Requests
	.softreg_req(sys_softreg_req_buf),
	.softreg_req_grant(sys_softreg_req_grant),
	// Responses
	.softreg_resp(sys_softreg_resp_buf),
	.softreg_resp_grant(sys_softreg_resp_grant)
);
assign sys_softreg_req_grant = 1;

AmorphOSSoftReg_RouteTree #(.SR_NUM_APPS(8))
sys_sr_tree
(
	// User clock and reset
	.clk(global_clk),
	.rst(!rst_n[1]),
	// Interface to Host
	.softreg_req(sys_softreg_req_buf),
	.softreg_resp(sys_softreg_resp_buf),
	// Virtualized interface
	.app_softreg_req(sys_softreg_req_),
	.app_softreg_resp(sys_softreg_resp_)
);

for (i = 0; i < 8; i = i + 1) begin : sys_sr_pipe
	lib_pipe #(
		.WIDTH(98),
		.STAGES(2)
	) PIPE_SYS_SR_REQ (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		.in_bus(sys_softreg_req_[i]),
		.out_bus(sys_softreg_req[i])
	);
	lib_pipe #(
		.WIDTH(65),
		.STAGES(2)
	) PIPE_SYS_SR_RESP (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		.in_bus(sys_softreg_resp[i]),
		.out_bus(sys_softreg_resp_[i])
	);
end


//------------------------------------
// Interconnect
//------------------------------------

axi_bus_t cl_axi_mstr_bus [4:0] ();
axi_bus_t cl_axi_slv_bus [4:0] ();

axi_bus_t ax_axi_m [4:0] ();
axi_bus_t ax_axi_s [4:0] ();

for (g = 0; g < 5; g = g + 1) begin: ax_ar
	axi_bus_t ar_axi_m [4:0] ();
	axi_bus_t ar_axi_s [4:0] ();
	
	axi_reg ar_m1 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		
		.axi_s(cl_axi_mstr_bus[g]),
		.axi_m(ar_axi_m[g])
	);
	axi_reg ar_m0 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		
		.axi_s(ar_axi_m[g]),
		.axi_m(ax_axi_m[g])
	);
	
	axi_reg ar_s0 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		
		.axi_s(ax_axi_s[g]),
		.axi_m(ar_axi_s[g])
	);
	axi_reg ar_s1 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		
		.axi_s(ar_axi_s[g]),
		.axi_m(cl_axi_slv_bus[g])
	);
end

axi_xbar ax (
	.clk(global_clk),
	.rst(!rst_n[1]),
	
	.axi_s(ax_axi_m),
	.axi_m(ax_axi_s)
);


//------------------------------------
// PCIe
//------------------------------------

// PCIM interface bridge
axi_bus_t pcim_axi_s ();
axi_bus_t pcim_axi_ar ();
axi_bus_t cl_sh_pcim ();

axi_reg #(
	.EN_RD(1)
) pcim_ar1 (
	.clk(global_clk),
	.rst_n(rst_n[0]),
	
	.axi_s(pcim_axi_s),
	.axi_m(pcim_axi_ar)
);
axi_reg #(
	.EN_RD(1)
) pcim_ar0 (
	.clk(global_clk),
	.rst_n(rst_n[0]),
	
	.axi_s(pcim_axi_ar),
	.axi_m(cl_sh_pcim)
);

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


// PCIS interface bridge
axi_bus_t sh_cl_pcis ();
axi_bus_t pcis_ax_axi ();

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

assign cl_sh_dma_rd_full  = 1'b0;
assign cl_sh_dma_wr_full  = 1'b0;

axi_reg pcis_ar_m (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s(sh_cl_pcis),
	.axi_m(pcis_ax_axi)
);


//------------------------------------
// Host FIFO
//------------------------------------
axi_bus_t ax_host_axi ();
axi_bus_t host_ax_axi ();
axi_bus_t host_pcim_axi ();
axi_bus_t ax_pcim_axi ();
axi_bus_t ax_pcim_axi_ar ();
axi_bus_t pcim_axi_ar2 ();

// AX to HF / PCIM
axi_split #(
	.THE_BIT(48)
) ax_splitter (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_axi_slv_bus[4]),
	.axi_m0(ax_host_axi),
	.axi_m1(ax_pcim_axi_ar)
);

axi_reg pcim_ar3 (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s(ax_pcim_axi_ar),
	.axi_m(ax_pcim_axi)
);

host_fifo host_inst (
	.clk(global_clk),
	.rst(!rst_n[1]),
	
	.softreg_req(sys_softreg_req[7:4]),
	.softreg_resp(sys_softreg_resp[7:4]),
	
	.ax_s(ax_host_axi),
	.ax_m(host_ax_axi),
	
	.pcim(host_pcim_axi)
);

// PCIS / HF to AX
axi_merge ax_merger (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s0(pcis_ax_axi),
	.axi_s1(host_ax_axi),
	.axi_m(cl_axi_mstr_bus[4])
);

// AX / HF to PCIM
// HF must be in S1 slot
axi_merge #(
	.EN_RD(1)
) pcim_merger (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s0(ax_pcim_axi),
	.axi_s1(host_pcim_axi),
	.axi_m(pcim_axi_ar2)
);

axi_reg #(
	.EN_RD(1)
) pcim_ar2_wr (
	.clk(global_clk),
	.rst_n(rst_n[1]),
	
	.axi_s(pcim_axi_ar2),
	.axi_m(pcim_axi_s)
);


//------------------------------------
// Application SoftReg
//------------------------------------

// Mapped onto BAR0 
/* AppPF
  |   |------- BAR0
  |   |         * 32-bit BAR, non-prefetchable
  |   |         * 32MiB (0 to 0x1FF-FFFF)
  |   |         * Maps to BAR0 AXI-L of the CL 
*/

// AXIL2SR to AmorphOS
SoftRegReq  app_softreg_req_buf;
logic       app_softreg_req_grant;

SoftRegResp app_softreg_resp_buf;
logic       app_softreg_resp_grant;

AXIL2SR app_axil2sr (
	// General Signals
	.clk(global_clk),
	.rst(!rst_n[1]), // expects active high

	// Write Address
	.sh_awvalid(sh_ocl_awvalid),
	.sh_awaddr(sh_ocl_awaddr),
	.sh_awready(ocl_sh_awready),

	//Write data
	.sh_wvalid(sh_ocl_wvalid),
	.sh_wdata(sh_ocl_wdata),
	.sh_wstrb(sh_ocl_wstrb),
	.sh_wready(ocl_sh_wready),

	//Write response
	.sh_bvalid(ocl_sh_bvalid),
	.sh_bresp(ocl_sh_bresp),
	.sh_bready(sh_ocl_bready),

	//Read address
	.sh_arvalid(sh_ocl_arvalid),
	.sh_araddr(sh_ocl_araddr),
	.sh_arready(ocl_sh_arready),

	//Read data/response
	.sh_rvalid(ocl_sh_rvalid),
	.sh_rdata(ocl_sh_rdata),
	.sh_rresp(ocl_sh_rresp),
	.sh_rready(sh_ocl_rready),

	// Interface to SoftReg
	// Requests
	.softreg_req(app_softreg_req_buf),
	.softreg_req_grant(app_softreg_req_grant),
	// Responses
	.softreg_resp(app_softreg_resp_buf),
	.softreg_resp_grant(app_softreg_resp_grant)
);
assign app_softreg_req_grant = 1;

// AmorphOS to apps
SoftRegReq  app_softreg_req_  [F1_NUM_APPS-1:0];
SoftRegResp app_softreg_resp_ [F1_NUM_APPS-1:0];

AmorphOSSoftReg_RouteTree #(
	.SR_NUM_APPS(F1_NUM_APPS)
) app_softreg_inst (
	// User clock and reset
	.clk(global_clk),
	.rst(!rst_n[1]),
	// Interface to Host
	.softreg_req(app_softreg_req_buf),
	.softreg_resp(app_softreg_resp_buf),
	// Virtualized interface each app
	.app_softreg_req(app_softreg_req_),
	.app_softreg_resp(app_softreg_resp_)
);


//------------------------------------
// Apps 
//------------------------------------

for (app_num = 0; app_num < F1_NUM_APPS; app_num = app_num + 1) begin : app
	// Use SLR reset that matches constraints
	reg app_rst_n;
	always_comb begin
		case (app_num)
			0: app_rst_n = rst_n[1];
			1: app_rst_n = rst_n[0];
			2: app_rst_n = rst_n[2];
			3: app_rst_n = rst_n[2];
		endcase
	end
	wire app_rst = !app_rst_n;
	
	// Buffer app SoftReg
	SoftRegReq  app_softreg_req_buf;
	SoftRegReq  app_softreg_req;
	SoftRegResp app_softreg_resp;
	SoftRegResp app_softreg_resp_buf;
	lib_pipe #(
		.WIDTH(98),
		.STAGES(2)
	) PIPE_APP_SR_REQ0 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		.in_bus(app_softreg_req_[app_num]),
		.out_bus(app_softreg_req_buf)
	);
	lib_pipe #(
		.WIDTH(98),
		.STAGES(2)
	) PIPE_APP_SR_REQ1 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		.in_bus(app_softreg_req_buf),
		.out_bus(app_softreg_req)
	);
	lib_pipe #(
		.WIDTH(65),
		.STAGES(2)
	) PIPE_APP_SR_RESP1 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		.in_bus(app_softreg_resp),
		.out_bus(app_softreg_resp_buf)
	);
	lib_pipe #(
		.WIDTH(65),
		.STAGES(2)
	) PIPE_APP_SR_RESP0 (
		.clk(global_clk),
		.rst_n(rst_n[1]),
		.in_bus(app_softreg_resp_buf),
		.out_bus(app_softreg_resp_[app_num])
	);
	
	// Buffer sys SoftReg
	SoftRegReq  ab_softreg_req;
	SoftRegResp ab_softreg_resp;
	lib_pipe #(
		.WIDTH(98),
		.STAGES(2)
	) PIPE_SYS_SR_REQ (
		.clk(global_clk),
		.rst_n(app_rst_n),
		.in_bus(sys_softreg_req[app_num]),
		.out_bus(ab_softreg_req)
	);
	lib_pipe #(
		.WIDTH(65),
		.STAGES(2)
	) PIPE_SYS_SR_RESP (
		.clk(global_clk),
		.rst_n(app_rst_n),
		.in_bus(ab_softreg_resp),
		.out_bus(sys_softreg_resp[app_num])
	);
	
	// Buffer app AXI_M
	axi_bus_t app_axi_m1 ();
	axi_bus_t app_axi_m ();
	axi_reg app_ar_m1 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		
		.axi_m(cl_axi_mstr_bus[app_num]),
		.axi_s(app_axi_m1)
	);
	axi_reg app_ar_m0 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		
		.axi_m(app_axi_m1),
		.axi_s(app_axi_m)
	);

	// Buffer app AXI_S
	axi_bus_t app_axi_s1 ();
	axi_bus_t app_axi_s ();
	axi_reg app_ar_s1 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		
		.axi_s(cl_axi_slv_bus[app_num]),
		.axi_m(app_axi_s1)
	);
	axi_reg app_ar_s0 (
		.clk(global_clk),
		.rst_n(app_rst_n),
		
		.axi_s(app_axi_s1),
		.axi_m(app_axi_s)
	);
	
	// Convert AXI to AXIS
	axi_stream_t app_axis_m ();
	axi_stream_t app_axis_s ();
	axis_buf app_axis_buf (
		.clk(global_clk),
		.rst(app_rst),
		
		.softreg_req(ab_softreg_req),
		.softreg_resp(ab_softreg_resp),
		
		.axi_m(app_axi_m),
		.axi_s(app_axi_s),
		
		.axis_s(app_axis_m),
		.axis_m(app_axis_s)
	);
	
	// Instantiate app
	AXIS_Strm strm_inst (
		// General signals
		.clk(global_clk),
		.rst(app_rst),
		
		// SoftReg control interface
		.softreg_req(app_softreg_req),
		.softreg_resp(app_softreg_resp),
		
		// Virtual stream interface
		.axis_m(app_axis_m),
		.axis_s(app_axis_s)
	);
	
	/*
	if (F1_CONFIG_APPS == 1) begin : aes
		AESWrapper aes_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 2) begin : conv
		ConvWrapper conv_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 4) begin : hls_flow
		HLSFlowWrapper hls_flow_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 6) begin : hls_hll
		HLSHLLWrapper hls_hll_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 7) begin : md5
		MD5Wrapper md5_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 11) begin : sha
		SHAWrapper sha_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 12) begin : hls_sha
		HLSSHAWrapper hls_sha_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end else if (F1_CONFIG_APPS == 14) begin : multi
		if (app_num == 0) begin
			RNGWrapper rng_inst (
				// General signals
				.clk(global_clk),
				.rst(app_rst),
				
				// Virtual memory interface
				.axi_m(app_axi_bus),
				
				// SoftReg control interface
				.softreg_req(app_softreg_req),
				.softreg_resp(app_softreg_resp)
			);
		end else if (app_num == 1) begin
			HLSSHAWrapper hls_sha_inst (
				// General signals
				.clk(global_clk),
				.rst(app_rst),
				
				// Virtual memory interface
				.axi_m(app_axi_bus),
				
				// SoftReg control interface
				.softreg_req(app_softreg_req),
				.softreg_resp(app_softreg_resp)
			);
		end else if (app_num == 2) begin
			HLSPgRnkWrapper hls_pgrnk_inst (
				// General signals
				.clk(global_clk),
				.rst(app_rst),
				
				// Virtual memory interface
				.axi_m(app_axi_bus),
				
				// SoftReg control interface
				.softreg_req(app_softreg_req),
				.softreg_resp(app_softreg_resp)
			);
		end else if (app_num == 3) begin
			AESWrapper aes_inst (
				// General signals
				.clk(global_clk),
				.rst(app_rst),
				
				// Virtual memory interface
				.axi_m(app_axi_bus),
				
				// SoftReg control interface
				.softreg_req(app_softreg_req),
				.softreg_resp(app_softreg_resp)
			);
		end
	end else if (F1_CONFIG_APPS == 15) begin : strm
		Strm strm_inst (
			// General signals
			.clk(global_clk),
			.rst(app_rst),
			
			// Virtual memory interface
			.axi_m(app_axi_bus),
			
			// SoftReg control interface
			.softreg_req(app_softreg_req),
			.softreg_resp(app_softreg_resp)
		);
	end
	*/
end


//------------------------------------
// Misc/Debug Bridge
//------------------------------------
assign cl_sh_id0[31:0]       = `CL_SH_ID0;
assign cl_sh_id1[31:0]       = `CL_SH_ID1;
assign cl_sh_status0[31:0]   = 32'h0000_0000;
assign cl_sh_status1[31:0]   = 32'h0000_0000;

assign cl_sh_status_vled = 16'h0000;

assign tdo = 1'b0; // TODO: Not really sure what this does since we're not creating a debug bridge


endmodule
