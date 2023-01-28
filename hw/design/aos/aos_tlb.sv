module aos_tlb (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	output SoftRegResp sr_resp,
	
	axi_bus_t.master virt_m,
	axi_bus_t.slave  phys_s
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

wire sr_read  = sr_req.valid && !sr_req.isWrite;
wire sr_write = sr_req.valid &&  sr_req.isWrite;


// Serialize read / write requests
// Select bus
reg rd_prio;
always @(posedge clk) rd_prio <= !rd_prio;
wire rd_sel = rd_prio ? virt_m.arvalid : !virt_m.awvalid;

// Virtual Request FIFO
wire rqf_wrreq;
wire [91:0] rqf_din;
wire rqf_full;
wire [91:0] rqf_dout;
wire rqf_empty;
wire rqf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(1+16+64+8+3),
	.LOG_DEPTH(FIFO_LD)
) rd_rq_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rqf_wrreq),
	.data(rqf_din),
	.full(rqf_full),
	.q(rqf_dout),
	.empty(rqf_empty),
	.rdreq(rqf_rdreq)
);

assign rqf_wrreq = rd_sel ? virt_m.arvalid : virt_m.awvalid;
wire [91:0] rd_req = {1'b1, virt_m.arid, virt_m.araddr, virt_m.arlen, virt_m.arsize};
wire [91:0] wr_req = {1'b0, virt_m.awid, virt_m.awaddr, virt_m.awlen, virt_m.awsize};
assign rqf_din = rd_sel ? rd_req : wr_req;
assign virt_m.arready =  rd_sel && !rqf_full;
assign virt_m.awready = !rd_sel && !rqf_full;




endmodule