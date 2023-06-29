
// Interface for address translations
interface tlb_bus_t;
	logic [51:0] req_page_num;
	logic        req_valid;
	logic        req_ready;
	
	logic [51:0] resp_page_num;
	logic        resp_ok;
	logic        resp_valid;
	//logic        resp_ready;
	
	logic        drained;
	
	modport master (input req_page_num, req_valid, output req_ready,
	                output resp_page_num, resp_ok, resp_valid, //input resp_ready,
	                input drained);
	modport slave  (output req_page_num, req_valid, input req_ready,
	                input resp_page_num, resp_ok, resp_valid, //output resp_ready,
	                output drained);
endinterface

// AXI read channel manager
module read_mgr (
	input clk,
	input rst,
	
	input [15:0] arid_m,
	input [63:0] araddr_m,
	input [7:0]  arlen_m,
	input [2:0]  arsize_m,
	input        arvalid_m,
	output       arready_m,
	
	output [15:0]  rid_m,
	output [511:0] rdata_m,
	output [1:0]   rresp_m,
	output         rlast_m,
	output         ruser_m,
	output         rvalid_m,
	input          rready_m,
	
	tlb_bus_t.slave tlb_s,
	axi_bus_t.slave phys_read_s
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

//// accept AXI reads and request address translation
// ar metadata FIFO signals
wire amf_wrreq;
wire [38:0] amf_data;
wire amf_full;
wire [38:0] amf_q;
wire amf_empty;
wire amf_rdreq;

// pg num FIFO signals
wire pnf_wrreq;
wire [51:0] pnf_data;
wire pnf_full;
wire [51:0] pnf_q;
wire pnf_empty;
wire pnf_rdreq;

// misc signal assigns
assign arready_m = !amf_full && !pnf_full;
assign tlb_s.req_page_num = pnf_q;
assign tlb_s.req_valid = !pnf_empty;

// ar metadata FIFO assigns
assign amf_wrreq = !pnf_full && arvalid_m;
assign amf_data = {arid_m, arlen_m, arsize_m, araddr_m[11:0]};
//assign amf_rdreq = TODO; // will assign later

// pg num FIFO assigns
assign pnf_wrreq = !amf_full && arvalid_m;
assign pnf_data = araddr_m[63:12];
assign pnf_rdreq = tlb_s.req_ready;

// FIFO instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(39),
	.LOG_DEPTH(FIFO_LD)
) ar_metadata_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(amf_wrreq),
	.data(amf_data),
	.full(amf_full),
	.q(amf_q),
	.empty(amf_empty),
	.rdreq(amf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(52),
	.LOG_DEPTH(1)
) pg_num_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pnf_wrreq),
	.data(pnf_data),
	.full(pnf_full),
	.q(pnf_q),
	.empty(pnf_empty),
	.rdreq(pnf_rdreq)
);

//// Buffer translation responses
// phys addr FIFO signals
wire paf_wrreq;
wire [52:0] paf_data;
wire paf_full;
wire [52:0] paf_q;
wire paf_empty;
wire paf_rdreq;

// phys addr FIFO assigns
assign paf_wrreq = tlb_s.resp_valid;
assign paf_data = {tlb_s.resp_page_num, tlb_s.resp_ok};
//assign paf_rdreq = TODO; // will assign later

// FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(53),
	.LOG_DEPTH(FIFO_LD)
) phys_addr_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(paf_wrreq),
	.data(paf_data),
	.full(paf_full),
	.q(paf_q),
	.empty(paf_empty),
	.rdreq(paf_rdreq)
);

//// Forward AXI reads if translation ok
// output metadata FIFO signals
wire omf_wrreq;
wire [24:0] omf_data;
wire omf_full;
wire [24:0] omf_q;
wire omf_empty;
wire omf_rdreq;

// assigns
// TODO: add support for re-ordering
assign {phys_read_s.arid, phys_read_s.arlen, phys_read_s.arsize} = {16'h00, amf_q[22:12]};
assign phys_read_s.araddr = {paf_q[52:1], amf_q[11:0]};
assign phys_read_s.arvalid = !omf_full && !amf_empty && !paf_empty && paf_q[0];
assign amf_rdreq = !omf_full && !paf_empty && (paf_q[0] ? phys_read_s.arready : 1'b1);
assign paf_rdreq = !omf_full && !amf_empty && (paf_q[0] ? phys_read_s.arready : 1'b1);

assign omf_wrreq = !amf_empty && !paf_empty && (paf_q[0] ? phys_read_s.arready : 1'b1);
assign omf_data = {amf_q[38:15], paf_q[0]};
//assign omf_rdreq = TODO; // will assign later

// output metadata FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(25),
	.LOG_DEPTH(FIFO_LD)
) output_metadata_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(omf_wrreq),
	.data(omf_data),
	.full(omf_full),
	.q(omf_q),
	.empty(omf_empty),
	.rdreq(omf_rdreq)
);

//// Return read / dummy data
// read return FIFO signals
wire rrf_wrreq;
wire [515:0] rrf_data;
wire rrf_full;
wire [514:0] rrf_q;
wire rrf_empty;
wire rrf_rdreq;

// track words out
reg [7:0] rdata_out;
always @(posedge clk) begin
	if (rvalid_m) rdata_out <= rlast_m ? 0 : rdata_out+1;
	if (rst) rdata_out <= 0;
end

// assigns
assign phys_read_s.rready = !rrf_full;
assign rrf_wrreq = phys_read_s.rvalid;
assign rrf_data = {phys_read_s.ruser, phys_read_s.rdata, phys_read_s.rresp, phys_read_s.rlast};
assign rrf_rdreq = rready_m && !omf_empty && omf_q[0];
assign omf_rdreq = rready_m && (omf_q[0] ? (!rrf_empty && rrf_q[0]) : 1'b1);

assign rid_m = omf_q[24:9];
assign rdata_m = rrf_q[514:3];
assign rresp_m = omf_q[0] ? rrf_q[2:1] : 2'b10;
assign ruser_m = rrf_q[515];
assign rlast_m = omf_q[0] ? rrf_q[0] : (rdata_out == omf_q[8:1]);
assign rvalid_m = !omf_empty && (omf_q[0] ? !rrf_empty : 1'b1);

// read return FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(516),
	.LOG_DEPTH(1)
) read_return_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rrf_wrreq),
	.data(rrf_data),
	.full(rrf_full),
	.q(rrf_q),
	.empty(rrf_empty),
	.rdreq(rrf_rdreq)
);

// drained logic
reg [DATA_FIFO_LD:0] reads_out;
wire read_start = phys_read_s.arvalid && phys_read_s.arready;
wire read_end = phys_read_s.rvalid && phys_read_s.rready && phys_read_s.rlast;
always @(posedge clk) begin
	reads_out <= reads_out + read_start - read_end;
	if (rst) reads_out <= 0;
end
assign tlb_s.drained = paf_empty && (reads_out == 0);

endmodule


// AXI write channel manager
module write_mgr (
	input clk,
	input rst,
	
	input [15:0] awid_m,
	input [63:0] awaddr_m,
	input [7:0]  awlen_m,
	input [2:0]  awsize_m,
	input        awvalid_m,
	output       awready_m,
	
	input [511:0] wdata_m,
	input [63:0]  wstrb_m,
	input         wlast_m,
	input         wuser_m,
	input         wvalid_m,
	output        wready_m,
	
	output [15:0] bid_m,
	output [1:0]  bresp_m,
	output        bvalid_m,
	input         bready_m,
	
	tlb_bus_t.slave tlb_s,
	axi_bus_t.slave phys_write_s
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

//// accept AXI writes and request address translation
// aw metadata FIFO signals
wire amf_wrreq;
wire [38:0] amf_data;
wire amf_full;
wire [38:0] amf_q;
wire amf_empty;
wire amf_rdreq;

// pg num FIFO signals
wire pnf_wrreq;
wire [51:0] pnf_data;
wire pnf_full;
wire [51:0] pnf_q;
wire pnf_empty;
wire pnf_rdreq;

// aw assigns
assign awready_m = !amf_full && !pnf_full;

// aw metadata FIFO assigns
assign amf_wrreq = !pnf_full && awvalid_m;
assign amf_data = {awid_m, awlen_m, awsize_m, awaddr_m[11:0]};
//assign amf_rdreq = TODO; // will assign later

// pg num FIFO assigns
assign pnf_wrreq = !amf_full && awvalid_m;
assign pnf_data = awaddr_m[63:12];
assign pnf_rdreq = tlb_s.req_ready;

// tlb assigns
assign tlb_s.req_valid = !pnf_empty;
assign tlb_s.req_page_num = pnf_q;

// FIFO instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(39),
	.LOG_DEPTH(FIFO_LD)
) aw_metadata_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(amf_wrreq),
	.data(amf_data),
	.full(amf_full),
	.q(amf_q),
	.empty(amf_empty),
	.rdreq(amf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(52),
	.LOG_DEPTH(1)
) pg_num_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pnf_wrreq),
	.data(pnf_data),
	.full(pnf_full),
	.q(pnf_q),
	.empty(pnf_empty),
	.rdreq(pnf_rdreq)
);

//// Buffer translation responses
// phys addr FIFO signals
wire paf_wrreq;
wire [52:0] paf_data;
wire paf_full;
wire [52:0] paf_q;
wire paf_empty;
wire paf_rdreq;

// phys addr FIFO assigns
assign paf_wrreq = tlb_s.resp_valid;
assign paf_data = {tlb_s.resp_page_num, tlb_s.resp_ok};
//assign paf_rdreq = TODO; // will assign later

// FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(53),
	.LOG_DEPTH(FIFO_LD)
) phys_addr_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(paf_wrreq),
	.data(paf_data),
	.full(paf_full),
	.q(paf_q),
	.empty(paf_empty),
	.rdreq(paf_rdreq)
);

//// Forward AXI writes if translation ok
// input metadata FIFO signals
wire imf_wrreq;
wire [16:0] imf_data;
wire imf_full;
wire [16:0] imf_q;
wire imf_empty;
wire imf_rdreq;

// assigns
assign {phys_write_s.awid, phys_write_s.awlen, phys_write_s.awsize} = {16'h00, amf_q[22:12]};
assign phys_write_s.awaddr = {paf_q[52:1], amf_q[11:0]};
assign phys_write_s.awvalid = !imf_full && !amf_empty && !paf_empty && paf_q[0];
assign amf_rdreq = !imf_full && !paf_empty && (paf_q[0] ? phys_write_s.awready : 1'b1);
assign paf_rdreq = !imf_full && !amf_empty && (paf_q[0] ? phys_write_s.awready : 1'b1);
assign imf_wrreq = !amf_empty && !paf_empty && (paf_q[0] ? phys_write_s.awready : 1'b1);
assign imf_data = {amf_q[38:23], paf_q[0]};
//assign imf_rdreq = TODO; // will assign later

// input metadata FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(17),
	.LOG_DEPTH(FIFO_LD)
) input_metadata_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(imf_wrreq),
	.data(imf_data),
	.full(imf_full),
	.q(imf_q),
	.empty(imf_empty),
	.rdreq(imf_rdreq)
);

//// Accept and forward write data
// write data FIFO signals
wire wdf_wrreq;
wire [577:0] wdf_data;
wire wdf_full;
wire [576:0] wdf_q;
wire wdf_empty;
wire wdf_rdreq;

// response metadata FIFO signals
wire rmf_wrreq;
wire [16:0] rmf_data;
wire rmf_full;
wire [16:0] rmf_q;
wire rmf_empty;
wire rmf_rdreq;

// assigns
assign wready_m = !wdf_full;
assign wdf_wrreq = wvalid_m;
assign wdf_data = {wuser_m, wdata_m, wstrb_m, wlast_m};

assign phys_write_s.wdata = wdf_q[576:65];
assign phys_write_s.wstrb = wdf_q[64:1];
assign phys_write_s.wlast = wdf_q[0];
assign phys_write_s.wuser = wdf_q[577];
assign phys_write_s.wvalid = !rmf_full && !wdf_empty && !imf_empty && imf_q[0];
assign wdf_rdreq = !rmf_full && !imf_empty && (imf_q[0] ? phys_write_s.wready : 1'b1);
assign imf_rdreq = !rmf_full && !wdf_empty && (imf_q[0] ? phys_write_s.wready : 1'b1) && wdf_q[0];
assign rmf_wrreq = !imf_empty && !wdf_empty && (imf_q[0] ? phys_write_s.wready : 1'b1) && wdf_q[0];
assign rmf_data = imf_q;
//assign rmf_rdreq = TODO; // will assign later

// FIFO instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(578),
	.LOG_DEPTH(1)
) write_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_data),
	.full(wdf_full),
	.q(wdf_q),
	.empty(wdf_empty),
	.rdreq(wdf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(17),
	.LOG_DEPTH(FIFO_LD)
) response_metadata_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rmf_wrreq),
	.data(rmf_data),
	.full(rmf_full),
	.q(rmf_q),
	.empty(rmf_empty),
	.rdreq(rmf_rdreq)
);

//// Return write responses
// response data FIFO signals
wire rdf_wrreq;
wire [17:0] rdf_data;
wire rdf_full;
wire [17:0] rdf_q;
wire rdf_empty;
wire rdf_rdreq;

// assigns
assign phys_write_s.bready = !rdf_full;
assign rdf_wrreq = phys_write_s.bvalid;
assign rdf_data = {phys_write_s.bid, phys_write_s.bresp};
assign rdf_rdreq = bready_m && !rmf_empty && rmf_q[0];
assign rmf_rdreq = bready_m && (rmf_q[0] ? !rdf_empty : 1'b1);

assign bid_m = rmf_q[16:1];
assign bresp_m = rmf_q[0] ? rdf_q[1:0] : 2'b10;
assign bvalid_m = !rmf_empty && (rmf_q[0] ? !rdf_empty : 1'b1);

// response data FIFO instantiation
HullFIFO #(
	.TYPE(0),
	.WIDTH(18),
	.LOG_DEPTH(1)
) response_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_data),
	.full(rdf_full),
	.q(rdf_q),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);

//// Drained logic
reg [DATA_FIFO_LD:0] writes_out;
wire write_start = phys_write_s.awvalid && phys_write_s.awready;
wire write_end = phys_write_s.bvalid && phys_write_s.bready;
always @(posedge clk) begin
	writes_out <= writes_out + write_start - write_end;
	if (rst) writes_out <= 0;
end
assign tlb_s.drained = paf_empty && (writes_out == 0);

endmodule

// Multiplexes physical memory channel
module phys_multiplexer (
	input clk,
	input rst,
	
	axi_bus_t.master phys_rm,
	axi_bus_t.master phys_wm,
	axi_bus_t.master phys_tlb,
	
	axi_bus_t.slave phys_s
);

//// Read path
// Interleave read address requests
// Use 1b of rid signal for tracking channels
assign phys_s.arid = phys_tlb.arvalid ? {phys_tlb.arid[14:0], 1'b0} : {phys_rm.arid[14:0], 1'b1};
assign phys_s.araddr = phys_tlb.arvalid ? phys_tlb.araddr : phys_rm.araddr;
assign phys_s.arlen = phys_tlb.arvalid ? phys_tlb.arlen : phys_rm.arlen;
assign phys_s.arsize = phys_tlb.arvalid ? phys_tlb.arsize : phys_rm.arsize;
assign phys_s.arvalid = phys_tlb.arvalid ? 1'b1 : phys_rm.arvalid;
assign phys_tlb.arready = phys_tlb.arvalid ? phys_s.arready : 1'b0;
assign phys_rm.arready = phys_tlb.arvalid ? 1'b0 : phys_s.arready;

assign phys_tlb.rid = {1'b0, phys_s.rid[15:1]};
assign phys_rm.rid = {1'b0, phys_s.rid[15:1]};
assign phys_tlb.rdata = phys_s.rdata;
assign phys_rm.rdata = phys_s.rdata;
assign phys_tlb.rresp = phys_s.rresp;
assign phys_rm.rresp = phys_s.rresp;
assign phys_tlb.rlast = phys_s.rlast;
assign phys_rm.rlast = phys_s.rlast;
assign phys_tlb.ruser = phys_s.ruser;
assign phys_rm.ruser = phys_s.ruser;
assign phys_tlb.rvalid = phys_s.rvalid && (phys_s.rid[0] == 1'b0);
assign phys_rm.rvalid = phys_s.rvalid && (phys_s.rid[0] == 1'b1);
assign phys_s.rready = (phys_s.rid[0] == 1'b0) ? phys_tlb.rready : phys_rm.rready;

//// Write path
// Assume no writes from TLB for now
assign phys_s.awid = phys_wm.awid;
assign phys_s.awaddr = phys_wm.awaddr;
assign phys_s.awlen = phys_wm.awlen;
assign phys_s.awsize = phys_wm.awsize;
assign phys_s.awvalid = phys_wm.awvalid;
assign phys_wm.awready = phys_s.awready;

assign phys_s.wdata = phys_wm.wdata;
assign phys_s.wstrb = phys_wm.wstrb;
assign phys_s.wlast = phys_wm.wlast;
assign phys_s.wuser = phys_wm.wuser;
assign phys_s.wvalid = phys_wm.wvalid;
assign phys_wm.wready = phys_s.wready;

assign phys_wm.bid = phys_s.bid;
assign phys_wm.bresp = phys_s.bresp;
assign phys_wm.bvalid = phys_s.bvalid;
assign phys_s.bready = phys_wm.bready;

endmodule


// Processes PTEs in TLB
// Entirely combinational
module pte_helper (

	input [63:0] pte,
	input [52:0] vpn,
	
	output found,
//	output ok,
	output [51:0] rpn
);

wire prsnt_ok = pte[0];	// entry present
wire rw_ok = vpn[0] ? pte[1] : pte[2];  // entry readable / writable
wire vpn_ok = vpn[52:1] == {16'h0000, pte[63:28]};  // vpn matches pte

assign found = prsnt_ok && vpn_ok && rw_ok;
//assign ok = found ? rw_ok : 1'b0;
assign rpn = found ? {28'h0000000, pte[27:4]} : 52'h0000000000000;

endmodule


// Handles address translation requests
// Fetches relevant data from memory when needed
module tlb_top #(
	parameter SR_ID = 0
) (
	input clk,
	input rst,
	
	tlb_bus_t.master tlb_read,
	tlb_bus_t.master tlb_write,
	
	axi_bus_t.slave  phys_tlb_s,
	
	input  SoftRegReq  sr_req,
	output SoftRegResp sr_resp
);
localparam FIFO_LD = 6;

//// Miss handler control registers
reg [2:0] miss_state;
reg stopped;
reg waiting;
reg draining;
reg restarting;

// credits
reg [FIFO_LD:0] credits;
wire add_credit;
wire use_credit;

// virtual page num backup FIFO signals
wire vbf_wrreq;
wire [52:0] vbf_data;
wire vbf_full;
wire [52:0] vbf_q;
wire vbf_empty;
wire vbf_rdreq;

//// Read / write channel select
reg last_read_sel = 0;
wire read_sel = last_read_sel ? !tlb_write.req_valid : tlb_read.req_valid;
always @(posedge clk) begin
	last_read_sel <= read_sel;
end

//// Mux and buffer inputs
// virtual page num FIFO signals
wire vpnf_wrreq;
wire [52:0] vpnf_data;
wire vpnf_full;
wire [52:0] vpnf_q;
wire vpnf_empty;
wire vpnf_rdreq;

// pte addr FIFO signals
wire ptaf_wrreq;
wire [63:0] ptaf_data;
wire ptaf_full;
wire [63:0] ptaf_q;
wire ptaf_empty;
wire ptaf_rdreq;

// assigns
wire in_valid = !credits[FIFO_LD] && (read_sel ? tlb_read.req_valid : tlb_write.req_valid);
wire [51:0] virt_page_num = read_sel ? tlb_read.req_page_num : tlb_write.req_page_num;
assign tlb_read.req_ready = read_sel && !credits[FIFO_LD] && !stopped;
assign tlb_write.req_ready = !read_sel && !credits[FIFO_LD] && !stopped;

wire [52:0] virt_page_data = restarting ? vbf_q : {virt_page_num, read_sel};
assign add_credit = in_valid && !stopped;

assign vbf_data = virt_page_data;
assign vbf_wrreq = in_valid && !stopped || restarting;
//assign vbf_rdreq = TODO; // will assign later

assign vpnf_data = virt_page_data;
assign vpnf_wrreq = in_valid && !stopped || restarting;
//assign vpnf_rdreq = TODO; // will assign later

wire [1:0] app_id = SR_ID;
assign ptaf_data = {28'h0000000, app_id[0], app_id[1], 7'h00, virt_page_data[21:1], 6'h00};
assign ptaf_wrreq = in_valid && !stopped || restarting;
//assign ptaf_rdreq = TODO; // will assign later

// FIFO instantiations
HullFIFO #(
	.TYPE(0),
	.WIDTH(53),
	.LOG_DEPTH(FIFO_LD)
) vpn_backup_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(vbf_wrreq),
	.data(vbf_data),
	.full(vbf_full),
	.q(vbf_q),
	.empty(vbf_empty),
	.rdreq(vbf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(53),
	.LOG_DEPTH(FIFO_LD)
) vpn_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(vpnf_wrreq),
	.data(vpnf_data),
	.full(vpnf_full),
	.q(vpnf_q),
	.empty(vpnf_empty),
	.rdreq(vpnf_rdreq)
);
HullFIFO #(
	.TYPE(0),
	.WIDTH(64),
	.LOG_DEPTH(FIFO_LD)
) pte_addr_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(ptaf_wrreq),
	.data(ptaf_data),
	.full(ptaf_full),
	.q(ptaf_q),
	.empty(ptaf_empty),
	.rdreq(ptaf_rdreq)
);

//// Request PTEs
assign phys_tlb_s.arid = 16'h0000;
assign phys_tlb_s.araddr = ptaf_q;
assign phys_tlb_s.arlen = 8'h00;
assign phys_tlb_s.arsize = 3'b110;
assign phys_tlb_s.arvalid = !ptaf_empty && !stopped;
assign ptaf_rdreq = phys_tlb_s.arready && !stopped || draining;

//// Receive PTEs
reg [511:0] pte_data;
reg pte_valid = 0;

assign phys_tlb_s.rready = 1;
always @(posedge clk) begin
	pte_data <= phys_tlb_s.rdata;
	pte_valid <= phys_tlb_s.rvalid && !stopped;
end

//// Process PTEs
reg resp_found_arr [7:0];
reg resp_found_reg [7:0];
reg resp_found;
reg [51:0] resp_page_num_arr [7:0];
reg [51:0] resp_page_num_reg [7:0];
reg [51:0] resp_page_num;
reg [52:0] resp_vpnd;
reg resp_valid = 0;

genvar g;
generate
	for (g = 0; g < 8; g += 1) begin: pte_helpers
		pte_helper pteh (
			.pte(pte_data[64*g +: 64]),
			.vpn(vpnf_q),
			.found(resp_found_arr[g]),
			.rpn(resp_page_num_arr[g])
		);
		always @(posedge clk) begin
			resp_found_reg[g] <= resp_found_arr[g];
			resp_page_num_reg[g] <= resp_page_num_arr[g];
		end
	end
endgenerate

assign vpnf_rdreq = pte_valid && !stopped || draining;

integer i;
always_comb begin
	resp_found = resp_found_reg[0];
	resp_page_num = resp_page_num_reg[0];
	
	for (i = 1; i < 8; i += 1) begin: pte_merge
		resp_found |= resp_found_reg[i];
		resp_page_num |= resp_page_num_reg[i];
	end
end

always @(posedge clk) begin
	resp_vpnd <= vpnf_q;
	resp_valid <= pte_valid && !stopped;
end

//// Record result
// processed PTE signals
wire ppf_wrreq;
wire [53:0] ppf_data;
wire ppf_full;
wire [53:0] ppf_q;
wire ppf_empty;
wire ppf_rdreq;

// host request signals
wire hrqf_wrreq;
wire [52:0] hrqf_data;
wire hrqf_full;
wire [52:0] hrqf_q;
wire hrqf_empty;
wire hrqf_rdreq;

// assigns
assign ppf_data  = {resp_page_num, resp_vpnd[0], resp_found};
assign hrqf_data = resp_vpnd;

assign ppf_wrreq  = resp_valid && !stopped;
assign hrqf_wrreq = resp_valid && !resp_found && !stopped;
//assign ppf_rdreq  = TODO; // will assign later
//assign hrqf_rdreq = TODO; // will assign later

assign use_credit = resp_valid && !stopped;
assign vbf_rdreq = use_credit || restarting;

// FIFO instantiations
HullFIFO #(
    .TYPE(0),
    .WIDTH(54),
    .LOG_DEPTH(1)
) proc_pte_fifo (
    .clock(clk),
    .reset_n(~rst),
    .wrreq(ppf_wrreq),
    .data(ppf_data),
    .full(ppf_full),
    .q(ppf_q),
    .empty(ppf_empty),
    .rdreq(ppf_rdreq)
);
HullFIFO #(
    .TYPE(0),
    .WIDTH(53),
    .LOG_DEPTH(1)
) host_req_fifo (
    .clock(clk),
    .reset_n(~rst),
    .wrreq(hrqf_wrreq),
    .data(hrqf_data),
    .full(hrqf_full),
    .q(hrqf_q),
    .empty(hrqf_empty),
    .rdreq(hrqf_rdreq)
);

//// SoftReg interface
// host response signals
wire hrpf_wrreq;
wire [52:0] hrpf_data;
wire hrpf_full;
wire [52:0] hrpf_q;
wire hrpf_empty;
wire hrpf_rdreq;

// assigns
always @(posedge clk) begin
	sr_resp.data <= {credits, miss_state, hrqf_q, waiting};
	sr_resp.valid <= sr_req.valid && !sr_req.isWrite;
	if (rst) sr_resp.valid <= 0;
end
assign hrqf_rdreq = sr_req.valid && !sr_req.isWrite && waiting;

assign hrpf_data = sr_req.data[52:0];
assign hrpf_wrreq = sr_req.valid && sr_req.isWrite && (sr_req.addr == 0);
//assign hrpf_rdreq = TODO; // will assign later

// host response FIFO instantiation
HullFIFO #(
    .TYPE(0),
    .WIDTH(53),
    .LOG_DEPTH(1)
) host_resp_fifo (
    .clock(clk),
    .reset_n(~rst),
    .wrreq(hrpf_wrreq),
    .data(hrpf_data),
    .full(hrpf_full),
    .q(hrpf_q),
    .empty(hrpf_empty),
    .rdreq(hrpf_rdreq)
);

//// Return results
// assigns
assign ppf_rdreq = (ppf_q[0] || !hrpf_empty);
assign hrpf_rdreq = !ppf_empty && !ppf_q[0];

wire [52:0] tlb_resp = ppf_q[0] ? {ppf_q[53:2], 1'b1} : hrpf_q;
assign {tlb_read.resp_page_num, tlb_read.resp_ok} = tlb_resp;
assign {tlb_write.resp_page_num, tlb_write.resp_ok} = tlb_resp;
assign tlb_read.resp_valid = ppf_q[1] && !ppf_empty && (ppf_q[0] || !hrpf_empty);
assign tlb_write.resp_valid = !ppf_q[1] && !ppf_empty && (ppf_q[0] || !hrpf_empty);

//// Miss handler
reg [FIFO_LD:0] mem_reqs;
wire mem_req_start = phys_tlb_s.arready && phys_tlb_s.arvalid;
wire mem_req_end = phys_tlb_s.rready && phys_tlb_s.rvalid;
reg [FIFO_LD-1:0] restart_count;
always @(posedge clk) begin
	credits <= credits + add_credit - use_credit;
	mem_reqs <= mem_reqs + mem_req_start - mem_req_end;
	
	case (miss_state)
		3'd0: begin
			if (hrqf_wrreq) begin
				miss_state <= 1;
				stopped <= 1;
				draining <= 1;
			end
		end
		3'd1: begin
			// flush already-translated I/O
			if (tlb_read.drained && tlb_write.drained && !ppf_q[0]) begin
				miss_state <= 2;
				waiting <= 1;
			end
		end
		3'd2: begin
			if (hrqf_rdreq) begin
				miss_state <= 3;
				waiting <= 0;
			end
		end
		3'd3: begin
			if (hrpf_wrreq) begin
				miss_state <= 4;
			end
		end
		3'd4: begin
			if (vpnf_empty && ptaf_empty && !pte_valid && !resp_valid && !mem_reqs) begin
				miss_state <= 5;
				restart_count <= 0;
				draining <= 0;
			end
		end
		3'd5: begin
			restarting <= 1;
			restart_count <= restart_count + 1;
			if (restart_count == credits) begin
				miss_state <= 0;
				restarting <= 0;
				stopped <= 0;
			end
		end
	endcase
	
	
	if (rst) begin
		credits <= 0;
		mem_reqs <= 0;
		miss_state <= 0;
		stopped <= 0;
		draining <= 0;
		restarting <= 0;
	end
end

endmodule


// AXI Address Translation Module
// Slave interface accepts requests in virtual addresses
// Master interface generates physical memory traffic
module axi_tlb #(
	parameter SR_ID = 0
) (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	output SoftRegResp sr_resp,
	
	axi_bus_t.master virt_m,
	axi_bus_t.slave  phys_s
);

// Buses
tlb_bus_t tlb_read();
tlb_bus_t tlb_write();

axi_bus_t phys_rm();
axi_bus_t phys_wm();
axi_bus_t phys_tlb();

// Module instantiations
read_mgr rm (
	.clk(clk),
	.rst(rst),
	
	.arid_m   (virt_m.arid),
	.araddr_m (virt_m.araddr),
	.arlen_m  (virt_m.arlen),
	.arsize_m (virt_m.arsize),
	.arvalid_m(virt_m.arvalid),
	.arready_m(virt_m.arready),
	
	.rid_m   (virt_m.rid),
	.rdata_m (virt_m.rdata),
	.rresp_m (virt_m.rresp),
	.rlast_m (virt_m.rlast),
	.ruser_m (virt_m.ruser),
	.rvalid_m(virt_m.rvalid),
	.rready_m(virt_m.rready),
	
	.tlb_s(tlb_read),
	.phys_read_s(phys_rm)
);
write_mgr wm (
	.clk(clk),
	.rst(rst),
	
	.awid_m   (virt_m.awid),
	.awaddr_m (virt_m.awaddr),
	.awlen_m  (virt_m.awlen),
	.awsize_m (virt_m.awsize),
	.awvalid_m(virt_m.awvalid),
	.awready_m(virt_m.awready),
	
	.wdata_m (virt_m.wdata),
	.wstrb_m (virt_m.wstrb),
	.wlast_m (virt_m.wlast),
	.wuser_m (virt_m.wuser),
	.wvalid_m(virt_m.wvalid),
	.wready_m(virt_m.wready),
	
	.bid_m   (virt_m.bid),
	.bresp_m (virt_m.bresp),
	.bvalid_m(virt_m.bvalid),
	.bready_m(virt_m.bready),
	
	.tlb_s(tlb_write),
	.phys_write_s(phys_wm)
);
tlb_top #(
	.SR_ID(SR_ID)
) tt (
	.clk(clk),
	.rst(rst),
	
	.tlb_read(tlb_read),
	.tlb_write(tlb_write),
	
	.phys_tlb_s(phys_tlb),
	
	.sr_req(sr_req),
	.sr_resp(sr_resp)
);
phys_multiplexer pm (
	.clk(clk),
	.rst(rst),
	
	.phys_rm(phys_rm),
	.phys_wm(phys_wm),
	.phys_tlb(phys_tlb),
	
	.phys_s(phys_s)
);

endmodule

