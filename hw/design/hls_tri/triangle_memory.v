module triangle_memory (
	ap_clk,
	ap_rst_n,
	
	m_axi_gmem_AWVALID,
	m_axi_gmem_AWREADY,
	m_axi_gmem_AWADDR,
	m_axi_gmem_AWID,
	m_axi_gmem_AWLEN,
	m_axi_gmem_AWSIZE,
	m_axi_gmem_AWBURST,
	m_axi_gmem_AWLOCK,
	m_axi_gmem_AWCACHE,
	m_axi_gmem_AWPROT,
	m_axi_gmem_AWQOS,
	m_axi_gmem_AWREGION,
	m_axi_gmem_AWUSER,
	
	m_axi_gmem_WVALID,
	m_axi_gmem_WREADY,
	m_axi_gmem_WDATA,
	m_axi_gmem_WSTRB,
	m_axi_gmem_WLAST,
	m_axi_gmem_WID,
	m_axi_gmem_WUSER,
	
	m_axi_gmem_ARVALID,
	m_axi_gmem_ARREADY,
	m_axi_gmem_ARADDR,
	m_axi_gmem_ARID,
	m_axi_gmem_ARLEN,
	m_axi_gmem_ARSIZE,
	m_axi_gmem_ARBURST,
	m_axi_gmem_ARLOCK,
	m_axi_gmem_ARCACHE,
	m_axi_gmem_ARPROT,
	m_axi_gmem_ARQOS,
	m_axi_gmem_ARREGION,
	m_axi_gmem_ARUSER,
	
	m_axi_gmem_RVALID,
	m_axi_gmem_RREADY,
	m_axi_gmem_RDATA,
	m_axi_gmem_RLAST,
	m_axi_gmem_RID,
	m_axi_gmem_RUSER,
	m_axi_gmem_RRESP,
	
	m_axi_gmem_BVALID,
	m_axi_gmem_BREADY,
	m_axi_gmem_BRESP,
	m_axi_gmem_BID,
	m_axi_gmem_BUSER,
	
	s_axi_control_AWVALID,
	s_axi_control_AWREADY,
	s_axi_control_AWADDR,
	
	s_axi_control_WVALID,
	s_axi_control_WREADY,
	s_axi_control_WDATA,
	s_axi_control_WSTRB,
	
	s_axi_control_ARVALID,
	s_axi_control_ARREADY,
	s_axi_control_ARADDR,
	
	s_axi_control_RVALID,
	s_axi_control_RREADY,
	s_axi_control_RDATA,
	s_axi_control_RRESP,
	
	s_axi_control_BVALID,
	s_axi_control_BREADY,
	s_axi_control_BRESP,
	
	interrupt


);

parameter    C_S_AXI_CONTROL_DATA_WIDTH = 64;
parameter    C_S_AXI_CONTROL_ADDR_WIDTH = 8;
parameter    C_S_AXI_DATA_WIDTH = 64;
parameter    C_M_AXI_MEM1_ID_WIDTH = 2;
parameter    C_M_AXI_MEM1_ADDR_WIDTH = 64;
parameter    C_M_AXI_MEM1_DATA_WIDTH = 512;
parameter    C_M_AXI_MEM1_AWUSER_WIDTH = 1;
parameter    C_M_AXI_MEM1_ARUSER_WIDTH = 1;
parameter    C_M_AXI_MEM1_WUSER_WIDTH = 1;
parameter    C_M_AXI_MEM1_RUSER_WIDTH = 1;
parameter    C_M_AXI_MEM1_BUSER_WIDTH = 1;
parameter    C_M_AXI_MEM1_USER_VALUE = 0;
parameter    C_M_AXI_MEM1_PROT_VALUE = 0;
parameter    C_M_AXI_MEM1_CACHE_VALUE = 3;
parameter    C_M_AXI_DATA_WIDTH = 32;
parameter    C_M_AXI_MEM2_ID_WIDTH = 2;
parameter    C_M_AXI_MEM2_ADDR_WIDTH = 64;
parameter    C_M_AXI_MEM2_DATA_WIDTH = 512;
parameter    C_M_AXI_MEM2_AWUSER_WIDTH = 1;
parameter    C_M_AXI_MEM2_ARUSER_WIDTH = 1;
parameter    C_M_AXI_MEM2_WUSER_WIDTH = 1;
parameter    C_M_AXI_MEM2_RUSER_WIDTH = 1;
parameter    C_M_AXI_MEM2_BUSER_WIDTH = 1;
parameter    C_M_AXI_MEM2_USER_VALUE = 0;
parameter    C_M_AXI_MEM2_PROT_VALUE = 0;
parameter    C_M_AXI_MEM2_CACHE_VALUE = 3;
parameter    C_M_AXI_MEM3_ID_WIDTH = 2;
parameter    C_M_AXI_MEM3_ADDR_WIDTH = 64;
parameter    C_M_AXI_MEM3_DATA_WIDTH = 512;
parameter    C_M_AXI_MEM3_AWUSER_WIDTH = 1;
parameter    C_M_AXI_MEM3_ARUSER_WIDTH = 1;
parameter    C_M_AXI_MEM3_WUSER_WIDTH = 1;
parameter    C_M_AXI_MEM3_RUSER_WIDTH = 1;
parameter    C_M_AXI_MEM3_BUSER_WIDTH = 1;
parameter    C_M_AXI_MEM3_USER_VALUE = 0;
parameter    C_M_AXI_MEM3_PROT_VALUE = 0;
parameter    C_M_AXI_MEM3_CACHE_VALUE = 3;
parameter    C_M_AXI_GMEM_ID_WIDTH = 2;
parameter    C_M_AXI_GMEM_ADDR_WIDTH = 64;
parameter    C_M_AXI_GMEM_DATA_WIDTH = 512;
parameter    C_M_AXI_GMEM_AWUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_ARUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_WUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_RUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_BUSER_WIDTH = 1;
parameter    C_M_AXI_GMEM_USER_VALUE = 0;
parameter    C_M_AXI_GMEM_PROT_VALUE = 0;
parameter    C_M_AXI_GMEM_CACHE_VALUE = 3;

parameter C_S_AXI_CONTROL_WSTRB_WIDTH = (64 / 8);
parameter C_S_AXI_WSTRB_WIDTH = (64 / 8);
parameter C_M_AXI_MEM1_WSTRB_WIDTH = (512 / 8);
parameter C_M_AXI_WSTRB_WIDTH = (32 / 8);
parameter C_M_AXI_MEM2_WSTRB_WIDTH = (512 / 8);
parameter C_M_AXI_MEM3_WSTRB_WIDTH = (512 / 8);
parameter C_M_AXI_GMEM_WSTRB_WIDTH = (512 / 8);


input   ap_clk;
input   ap_rst_n;
output   m_axi_gmem_AWVALID;
input   m_axi_gmem_AWREADY;
output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_gmem_AWADDR;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_AWID;
output  [7:0] m_axi_gmem_AWLEN;
output  [2:0] m_axi_gmem_AWSIZE;
output  [1:0] m_axi_gmem_AWBURST;
output  [1:0] m_axi_gmem_AWLOCK;
output  [3:0] m_axi_gmem_AWCACHE;
output  [2:0] m_axi_gmem_AWPROT;
output  [3:0] m_axi_gmem_AWQOS;
output  [3:0] m_axi_gmem_AWREGION;
output  [C_M_AXI_GMEM_AWUSER_WIDTH - 1:0] m_axi_gmem_AWUSER;
output   m_axi_gmem_WVALID;
input   m_axi_gmem_WREADY;
output  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_gmem_WDATA;
output  [C_M_AXI_GMEM_WSTRB_WIDTH - 1:0] m_axi_gmem_WSTRB;
output   m_axi_gmem_WLAST;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_WID;
output  [C_M_AXI_GMEM_WUSER_WIDTH - 1:0] m_axi_gmem_WUSER;
output   m_axi_gmem_ARVALID;
input   m_axi_gmem_ARREADY;
output  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_gmem_ARADDR;
output  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_ARID;
output  [7:0] m_axi_gmem_ARLEN;
output  [2:0] m_axi_gmem_ARSIZE;
output  [1:0] m_axi_gmem_ARBURST;
output  [1:0] m_axi_gmem_ARLOCK;
output  [3:0] m_axi_gmem_ARCACHE;
output  [2:0] m_axi_gmem_ARPROT;
output  [3:0] m_axi_gmem_ARQOS;
output  [3:0] m_axi_gmem_ARREGION;
output  [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_gmem_ARUSER;
input   m_axi_gmem_RVALID;
output   m_axi_gmem_RREADY;
input  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_gmem_RDATA;
input   m_axi_gmem_RLAST;
input  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_RID;
input  [C_M_AXI_GMEM_RUSER_WIDTH - 1:0] m_axi_gmem_RUSER;
input  [1:0] m_axi_gmem_RRESP;
input   m_axi_gmem_BVALID;
output   m_axi_gmem_BREADY;
input  [1:0] m_axi_gmem_BRESP;
input  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_gmem_BID;
input  [C_M_AXI_GMEM_BUSER_WIDTH - 1:0] m_axi_gmem_BUSER;
input   s_axi_control_AWVALID;
output   s_axi_control_AWREADY;
input  [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] s_axi_control_AWADDR;
input   s_axi_control_WVALID;
output   s_axi_control_WREADY;
input  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0] s_axi_control_WDATA;
input  [C_S_AXI_CONTROL_WSTRB_WIDTH - 1:0] s_axi_control_WSTRB;
input   s_axi_control_ARVALID;
output   s_axi_control_ARREADY;
input  [C_S_AXI_CONTROL_ADDR_WIDTH - 1:0] s_axi_control_ARADDR;
output   s_axi_control_RVALID;
input   s_axi_control_RREADY;
output  [C_S_AXI_CONTROL_DATA_WIDTH - 1:0] s_axi_control_RDATA;
output  [1:0] s_axi_control_RRESP;
output   s_axi_control_BVALID;
input   s_axi_control_BREADY;
output  [1:0] s_axi_control_BRESP;
output   interrupt;


// AR uses these variables to route, R uses RID
wire m_axi_mem3_ARVALID;
wire m_axi_mem2_ARVALID;
wire is_3 = m_axi_mem3_ARVALID; // 3 gets highest priority
wire is_2 = !is_3 && m_axi_mem2_ARVALID;
wire is_1 = !is_3 && !is_2;

wire   m_axi_mem1_ARVALID;
wire   m_axi_mem1_ARREADY = m_axi_gmem_ARREADY && is_1;
wire  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_mem1_ARADDR;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem1_ARID;
wire  [7:0] m_axi_mem1_ARLEN;
wire  [2:0] m_axi_mem1_ARSIZE;
wire  [1:0] m_axi_mem1_ARBURST;
wire  [1:0] m_axi_mem1_ARLOCK;
wire  [3:0] m_axi_mem1_ARCACHE;
wire  [2:0] m_axi_mem1_ARPROT;
wire  [3:0] m_axi_mem1_ARQOS;
wire  [3:0] m_axi_mem1_ARREGION;
wire  [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_mem1_ARUSER;

wire   m_axi_mem1_RVALID = m_axi_gmem_RVALID && m_axi_gmem_RID == 1;
wire   m_axi_mem1_RREADY;
wire  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_mem1_RDATA = m_axi_gmem_RDATA;
wire   m_axi_mem1_RLAST = m_axi_gmem_RLAST;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem1_RID = 0;
wire  [C_M_AXI_GMEM_RUSER_WIDTH - 1:0] m_axi_mem1_RUSER = m_axi_gmem_RUSER;
wire  [1:0] m_axi_mem1_RRESP = m_axi_gmem_RRESP;


wire   m_axi_mem2_ARREADY = m_axi_gmem_ARREADY && is_2;
wire  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_mem2_ARADDR;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem2_ARID;
wire  [7:0] m_axi_mem2_ARLEN;
wire  [2:0] m_axi_mem2_ARSIZE;
wire  [1:0] m_axi_mem2_ARBURST;
wire  [1:0] m_axi_mem2_ARLOCK;
wire  [3:0] m_axi_mem2_ARCACHE;
wire  [2:0] m_axi_mem2_ARPROT;
wire  [3:0] m_axi_mem2_ARQOS;
wire  [3:0] m_axi_mem2_ARREGION;
wire  [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_mem2_ARUSER;

wire   m_axi_mem2_RVALID = m_axi_gmem_RVALID && m_axi_gmem_RID == 2;
wire   m_axi_mem2_RREADY;
wire  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_mem2_RDATA = m_axi_gmem_RDATA;
wire   m_axi_mem2_RLAST = m_axi_gmem_RLAST;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem2_RID = 0;
wire  [C_M_AXI_GMEM_RUSER_WIDTH - 1:0] m_axi_mem2_RUSER = m_axi_gmem_RUSER;
wire  [1:0] m_axi_mem2_RRESP = m_axi_gmem_RRESP;


wire   m_axi_mem3_ARREADY = m_axi_gmem_ARREADY && is_3;
wire  [C_M_AXI_GMEM_ADDR_WIDTH - 1:0] m_axi_mem3_ARADDR;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem3_ARID;
wire  [7:0] m_axi_mem3_ARLEN;
wire  [2:0] m_axi_mem3_ARSIZE;
wire  [1:0] m_axi_mem3_ARBURST;
wire  [1:0] m_axi_mem3_ARLOCK;
wire  [3:0] m_axi_mem3_ARCACHE;
wire  [2:0] m_axi_mem3_ARPROT;
wire  [3:0] m_axi_mem3_ARQOS;
wire  [3:0] m_axi_mem3_ARREGION;
wire  [C_M_AXI_GMEM_ARUSER_WIDTH - 1:0] m_axi_mem3_ARUSER;

wire   m_axi_mem3_RVALID = m_axi_gmem_RVALID && m_axi_gmem_RID == 3;
wire   m_axi_mem3_RREADY;
wire  [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_mem3_RDATA = m_axi_gmem_RDATA;
wire   m_axi_mem3_RLAST = m_axi_gmem_RLAST;
wire  [C_M_AXI_GMEM_ID_WIDTH - 1:0] m_axi_mem3_RID = 0;
wire  [C_M_AXI_GMEM_RUSER_WIDTH - 1:0] m_axi_mem3_RUSER = m_axi_gmem_RUSER;
wire  [1:0] m_axi_mem3_RRESP = m_axi_gmem_RRESP;


assign   m_axi_gmem_ARVALID = is_1 ? m_axi_mem1_ARVALID : (is_2 ? m_axi_mem2_ARVALID : m_axi_mem3_ARVALID);
//input   m_axi_gmem_ARREADY;
assign   m_axi_gmem_ARADDR = is_1 ? m_axi_mem1_ARADDR : (is_2 ? m_axi_mem2_ARADDR : m_axi_mem3_ARADDR);
assign   m_axi_gmem_ARID = is_1 ? 1 : (is_2 ? 2 : 3); // TODO: fix width
assign   m_axi_gmem_ARLEN = is_1 ? m_axi_mem1_ARLEN : (is_2 ? m_axi_mem2_ARLEN : m_axi_mem3_ARLEN);
assign   m_axi_gmem_ARSIZE = is_1 ? m_axi_mem1_ARSIZE : (is_2 ? m_axi_mem2_ARSIZE : m_axi_mem3_ARSIZE);
assign   m_axi_gmem_ARBURST = is_1 ? m_axi_mem1_ARBURST : (is_2 ? m_axi_mem2_ARBURST : m_axi_mem3_ARBURST);
assign   m_axi_gmem_ARLOCK = is_1 ? m_axi_mem1_ARLOCK : (is_2 ? m_axi_mem2_ARLOCK : m_axi_mem3_ARLOCK);
assign   m_axi_gmem_ARCACHE = is_1 ? m_axi_mem1_ARCACHE : (is_2 ? m_axi_mem2_ARCACHE : m_axi_mem3_ARCACHE);
assign   m_axi_gmem_ARPROT = is_1 ? m_axi_mem1_ARPROT : (is_2 ? m_axi_mem2_ARPROT : m_axi_mem3_ARPROT);
assign   m_axi_gmem_ARQOS = is_1 ? m_axi_mem1_ARQOS : (is_2 ? m_axi_mem2_ARQOS : m_axi_mem3_ARQOS);
assign   m_axi_gmem_ARREGION = is_1 ? m_axi_mem1_ARREGION : (is_2 ? m_axi_mem2_ARREGION : m_axi_mem3_ARREGION);
assign   m_axi_gmem_ARUSER = is_1 ? m_axi_mem1_ARUSER : (is_2 ? m_axi_mem2_ARUSER : m_axi_mem3_ARUSER);


// multiplex read responses based on ID
wire ready1 = m_axi_gmem_RID == 1 && m_axi_mem1_RREADY;
wire ready2 = m_axi_gmem_RID == 2 && m_axi_mem2_RREADY;
wire ready3 = m_axi_gmem_RID == 3 && m_axi_mem3_RREADY;
assign m_axi_gmem_RREADY = ready1 || ready2 || ready3;



// Triangle top module
triangle triangle_inst (
        .ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),

        .m_axi_mem1_AWVALID(),
        .m_axi_mem1_AWREADY(0),
        .m_axi_mem1_AWADDR(),
        .m_axi_mem1_AWID(),
        .m_axi_mem1_AWLEN(),
        .m_axi_mem1_AWSIZE(),
        .m_axi_mem1_AWBURST(),
        .m_axi_mem1_AWLOCK(),
        .m_axi_mem1_AWCACHE(),
        .m_axi_mem1_AWPROT(),
        .m_axi_mem1_AWQOS(),
        .m_axi_mem1_AWREGION(),
        .m_axi_mem1_AWUSER(),
        .m_axi_mem1_WVALID(),
        .m_axi_mem1_WREADY(0),
        .m_axi_mem1_WDATA(),
        .m_axi_mem1_WSTRB(),
        .m_axi_mem1_WLAST(),
        .m_axi_mem1_WID(),
        .m_axi_mem1_WUSER(),
        .m_axi_mem1_ARVALID(m_axi_mem1_ARVALID),
        .m_axi_mem1_ARREADY(m_axi_mem1_ARREADY),
        .m_axi_mem1_ARADDR(m_axi_mem1_ARADDR),
        .m_axi_mem1_ARID(m_axi_mem1_ARID),
        .m_axi_mem1_ARLEN(m_axi_mem1_ARLEN),
        .m_axi_mem1_ARSIZE(m_axi_mem1_ARSIZE),
        .m_axi_mem1_ARBURST(m_axi_mem1_ARBURST),
        .m_axi_mem1_ARLOCK(m_axi_mem1_ARLOCK),
        .m_axi_mem1_ARCACHE(m_axi_mem1_ARCACHE),
        .m_axi_mem1_ARPROT(m_axi_mem1_ARPROT),
        .m_axi_mem1_ARQOS(m_axi_mem1_ARQOS),
        .m_axi_mem1_ARREGION(m_axi_mem1_ARREGION),
        .m_axi_mem1_ARUSER(m_axi_mem1_ARUSER),
        .m_axi_mem1_RVALID(m_axi_mem1_RVALID),
        .m_axi_mem1_RREADY(m_axi_mem1_RREADY),
        .m_axi_mem1_RDATA(m_axi_mem1_RDATA),
        .m_axi_mem1_RLAST(m_axi_mem1_RLAST),
        .m_axi_mem1_RID(m_axi_mem1_RID),
        .m_axi_mem1_RUSER(m_axi_mem1_RUSER),
        .m_axi_mem1_RRESP(m_axi_mem1_RRESP),
        .m_axi_mem1_BVALID(0),
        .m_axi_mem1_BREADY(),
        .m_axi_mem1_BRESP(0),
        .m_axi_mem1_BID(0),
        .m_axi_mem1_BUSER(0),


        .m_axi_mem2_AWVALID(),
        .m_axi_mem2_AWREADY(0),
        .m_axi_mem2_AWADDR(),
        .m_axi_mem2_AWID(),
        .m_axi_mem2_AWLEN(),
        .m_axi_mem2_AWSIZE(),
        .m_axi_mem2_AWBURST(),
        .m_axi_mem2_AWLOCK(),
        .m_axi_mem2_AWCACHE(),
        .m_axi_mem2_AWPROT(),
        .m_axi_mem2_AWQOS(),
        .m_axi_mem2_AWREGION(),
        .m_axi_mem2_AWUSER(),
        .m_axi_mem2_WVALID(),
        .m_axi_mem2_WREADY(0),
        .m_axi_mem2_WDATA(),
        .m_axi_mem2_WSTRB(),
        .m_axi_mem2_WLAST(),
        .m_axi_mem2_WID(),
        .m_axi_mem2_WUSER(),
        .m_axi_mem2_ARVALID(m_axi_mem2_ARVALID),
        .m_axi_mem2_ARREADY(m_axi_mem2_ARREADY),
        .m_axi_mem2_ARADDR(m_axi_mem2_ARADDR),
        .m_axi_mem2_ARID(m_axi_mem2_ARID),
        .m_axi_mem2_ARLEN(m_axi_mem2_ARLEN),
        .m_axi_mem2_ARSIZE(m_axi_mem2_ARSIZE),
        .m_axi_mem2_ARBURST(m_axi_mem2_ARBURST),
        .m_axi_mem2_ARLOCK(m_axi_mem2_ARLOCK),
        .m_axi_mem2_ARCACHE(m_axi_mem2_ARCACHE),
        .m_axi_mem2_ARPROT(m_axi_mem2_ARPROT),
        .m_axi_mem2_ARQOS(m_axi_mem2_ARQOS),
        .m_axi_mem2_ARREGION(m_axi_mem2_ARREGION),
        .m_axi_mem2_ARUSER(m_axi_mem2_ARUSER),
        .m_axi_mem2_RVALID(m_axi_mem2_RVALID),
        .m_axi_mem2_RREADY(m_axi_mem2_RREADY),
        .m_axi_mem2_RDATA(m_axi_mem2_RDATA),
        .m_axi_mem2_RLAST(m_axi_mem2_RLAST),
        .m_axi_mem2_RID(m_axi_mem2_RID),
        .m_axi_mem2_RUSER(m_axi_mem2_RUSER),
        .m_axi_mem2_RRESP(m_axi_mem2_RRESP),
        .m_axi_mem2_BVALID(0),
        .m_axi_mem2_BREADY(),
        .m_axi_mem2_BRESP(0),
        .m_axi_mem2_BID(0),
        .m_axi_mem2_BUSER(0),



        .m_axi_mem3_AWVALID(),
        .m_axi_mem3_AWREADY(0),
        .m_axi_mem3_AWADDR(),
        .m_axi_mem3_AWID(),
        .m_axi_mem3_AWLEN(),
        .m_axi_mem3_AWSIZE(),
        .m_axi_mem3_AWBURST(),
        .m_axi_mem3_AWLOCK(),
        .m_axi_mem3_AWCACHE(),
        .m_axi_mem3_AWPROT(),
        .m_axi_mem3_AWQOS(),
        .m_axi_mem3_AWREGION(),
        .m_axi_mem3_AWUSER(),
        .m_axi_mem3_WVALID(),
        .m_axi_mem3_WREADY(0),
        .m_axi_mem3_WDATA(),
        .m_axi_mem3_WSTRB(),
        .m_axi_mem3_WLAST(),
        .m_axi_mem3_WID(),
        .m_axi_mem3_WUSER(),
        .m_axi_mem3_ARVALID(m_axi_mem3_ARVALID),
        .m_axi_mem3_ARREADY(m_axi_mem3_ARREADY),
        .m_axi_mem3_ARADDR(m_axi_mem3_ARADDR),
        .m_axi_mem3_ARID(m_axi_mem3_ARID),
        .m_axi_mem3_ARLEN(m_axi_mem3_ARLEN),
        .m_axi_mem3_ARSIZE(m_axi_mem3_ARSIZE),
        .m_axi_mem3_ARBURST(m_axi_mem3_ARBURST),
        .m_axi_mem3_ARLOCK(m_axi_mem3_ARLOCK),
        .m_axi_mem3_ARCACHE(m_axi_mem3_ARCACHE),
        .m_axi_mem3_ARPROT(m_axi_mem3_ARPROT),
        .m_axi_mem3_ARQOS(m_axi_mem3_ARQOS),
        .m_axi_mem3_ARREGION(m_axi_mem3_ARREGION),
        .m_axi_mem3_ARUSER(m_axi_mem3_ARUSER),
        .m_axi_mem3_RVALID(m_axi_mem3_RVALID),
        .m_axi_mem3_RREADY(m_axi_mem3_RREADY),
        .m_axi_mem3_RDATA(m_axi_mem3_RDATA),
        .m_axi_mem3_RLAST(m_axi_mem3_RLAST),
        .m_axi_mem3_RID(m_axi_mem3_RID),
        .m_axi_mem3_RUSER(m_axi_mem3_RUSER),
        .m_axi_mem3_RRESP(m_axi_mem3_RRESP),
        .m_axi_mem3_BVALID(0),
        .m_axi_mem3_BREADY(),
        .m_axi_mem3_BRESP(0),
        .m_axi_mem3_BID(0),
        .m_axi_mem3_BUSER(0),

        .m_axi_gmem_AWVALID(m_axi_gmem_AWVALID),
        .m_axi_gmem_AWREADY(m_axi_gmem_AWREADY),
        .m_axi_gmem_AWADDR(m_axi_gmem_AWADDR),
        .m_axi_gmem_AWID(m_axi_gmem_AWID),
        .m_axi_gmem_AWLEN(m_axi_gmem_AWLEN),
        .m_axi_gmem_AWSIZE(m_axi_gmem_AWSIZE),
        .m_axi_gmem_AWBURST(m_axi_gmem_AWBURST),
        .m_axi_gmem_AWLOCK(m_axi_gmem_AWLOCK),
        .m_axi_gmem_AWCACHE(m_axi_gmem_AWCACHE),
        .m_axi_gmem_AWPROT(m_axi_gmem_AWPROT),
        .m_axi_gmem_AWQOS(m_axi_gmem_AWQOS),
        .m_axi_gmem_AWREGION(m_axi_gmem_AWREGION),
        .m_axi_gmem_AWUSER(m_axi_gmem_AWUSER),
        .m_axi_gmem_WVALID(m_axi_gmem_WVALID),
        .m_axi_gmem_WREADY(m_axi_gmem_WREADY),
        .m_axi_gmem_WDATA(m_axi_gmem_WDATA),
        .m_axi_gmem_WSTRB(m_axi_gmem_WSTRB),
        .m_axi_gmem_WLAST(m_axi_gmem_WLAST),
        .m_axi_gmem_WID(m_axi_gmem_WID),
        .m_axi_gmem_WUSER(m_axi_gmem_WUSER),
        .m_axi_gmem_ARVALID(),
        .m_axi_gmem_ARREADY(0),
        .m_axi_gmem_ARADDR(),
        .m_axi_gmem_ARID(),
        .m_axi_gmem_ARLEN(),
        .m_axi_gmem_ARSIZE(),
        .m_axi_gmem_ARBURST(),
        .m_axi_gmem_ARLOCK(),
        .m_axi_gmem_ARCACHE(),
        .m_axi_gmem_ARPROT(),
        .m_axi_gmem_ARQOS(),
        .m_axi_gmem_ARREGION(),
        .m_axi_gmem_ARUSER(),
        .m_axi_gmem_RVALID(0),
        .m_axi_gmem_RREADY(),
        .m_axi_gmem_RDATA(0),
        .m_axi_gmem_RLAST(0),
        .m_axi_gmem_RID(0),
        .m_axi_gmem_RUSER(0),
        .m_axi_gmem_RRESP(0),
        .m_axi_gmem_BVALID(m_axi_gmem_BVALID),
        .m_axi_gmem_BREADY(m_axi_gmem_BREADY),
        .m_axi_gmem_BRESP(m_axi_gmem_BRESP),
        .m_axi_gmem_BID(m_axi_gmem_BID),
        .m_axi_gmem_BUSER(m_axi_gmem_BUSER),

        .s_axi_control_AWVALID(s_axi_control_AWVALID),
        .s_axi_control_AWREADY(s_axi_control_AWREADY),
        .s_axi_control_AWADDR(s_axi_control_AWADDR),
        .s_axi_control_WVALID(s_axi_control_WVALID),
        .s_axi_control_WREADY(s_axi_control_WREADY),
        .s_axi_control_WDATA(s_axi_control_WDATA),
        .s_axi_control_WSTRB(s_axi_control_WSTRB),
        .s_axi_control_ARVALID(s_axi_control_ARVALID),
        .s_axi_control_ARREADY(s_axi_control_ARREADY),
        .s_axi_control_ARADDR(s_axi_control_ARADDR),
        .s_axi_control_RVALID(s_axi_control_RVALID),
        .s_axi_control_RREADY(s_axi_control_RREADY),
        .s_axi_control_RDATA(s_axi_control_RDATA),
        .s_axi_control_RRESP(s_axi_control_RRESP),
        .s_axi_control_BVALID(s_axi_control_BVALID),
        .s_axi_control_BREADY(s_axi_control_BREADY),
        .s_axi_control_BRESP(s_axi_control_BRESP),
        .interrupt(interrupt)
);
endmodule
