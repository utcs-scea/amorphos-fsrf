module cy_ram_wrapper #(
	parameter DATA_W = 64,
	parameter ADDR_W = 9
) (
	input clk,
	input rst,
	
	input [ADDR_W-1:0] waddr,
	input [DATA_W-1:0] wdata,
	input wvalid,
	
	input [ADDR_W-1:0] raddr,
	output reg [DATA_W-1:0] rdata
);
localparam DEPTH = 2**ADDR_W;

//(* rw_addr_collision = "yes" *)
(* ram_style = "block" *)
reg [DATA_W-1:0] mem [DEPTH-1:0];
reg [DATA_W-1:0] mem_out;

always @(posedge clk) begin
	if (wvalid) mem[waddr] <= wdata;
	mem_out <= mem[raddr];
	rdata <= mem_out;
end

endmodule


module cy_slave #(
	parameter ORDER = 10,
	parameter PAGE_BITS = 21,
	parameter ASSOC = 2
) (
	input clk,
	input rst,
	
	input tlb_write,
	input [ORDER-1:0] tlb_addr,
	input [ASSOC-1:0] tlb_way,
	input [63:0] tlb_data,
	
	input virt_read,
	input [63:0] virt_addr,
	output reg [63:0] phys_addr,
	output reg hit,
	output reg [63:0] temp [(2**ASSOC)-1:0]
);

genvar g;
wire [63:0] tlbe [(2**ASSOC)-1:0];
for (g = 0; g < 2**ASSOC; g = g + 1) begin
	cy_ram_wrapper #(
		.DATA_W(64),
		.ADDR_W(ORDER)
	) crw (
		.clk(clk),
		.rst(rst),
		
		.waddr(tlb_addr),
		.wdata(tlb_data),
		.wvalid(tlb_write && tlb_way == g),
		
		.raddr(virt_addr[PAGE_BITS+ORDER-1:PAGE_BITS]),
		.rdata(tlbe[g])
	);
end

always_comb begin
	hit = 0;
	phys_addr = 0;
	
	for (int i = 0; i < 2**ASSOC; i = i + 1) begin
		temp[i] = tlbe[i];
		// check virtual tag
		if (virt_addr[47:PAGE_BITS] == tlbe[i][63:16+PAGE_BITS]) begin
			if (virt_addr[63:48] == 16'h0) begin
				// check read / write
				if (virt_read ? tlbe[i][1] : tlbe[i][2]) begin
					// check present
					if (tlbe[i][0]) begin
						hit = 1;
						phys_addr[PAGE_BITS-1:0] = virt_addr[PAGE_BITS-1:0];
						phys_addr[35:PAGE_BITS] = tlbe[i][27:PAGE_BITS-8];
					end
				end
			end
		end
	end
end

endmodule


module cy_tlb (
	input clk,
	input rst,
	
	input  SoftRegReq  sr_req,
	output SoftRegResp sr_resp,
	
	axi_bus_t.master virt_m,
	axi_bus_t.slave  phys_s
);
localparam FIFO_LD = 6;
localparam DATA_FIFO_LD = 9;

wire sr_read = sr_req.valid && !sr_req.isWrite;
wire sr_write = sr_req.valid && sr_req.isWrite;


reg virt_read;
reg [63:0] virt_addr;
wire [63:0] phys_addr[3];
wire hit [3];
wire [63:0] temp0 [3:0];
wire [63:0] temp1 [1:0];
wire [63:0] temp2 [3:0];

wire sTLB_write = sr_write && sr_req.addr[15];
cy_slave #(
	.ORDER(10),
	.PAGE_BITS(12),
	.ASSOC(2)
) sTLB (
	.clk(clk),
	.rst(rst),
	
	.tlb_write(sTLB_write),
	.tlb_addr(sr_req.addr[14:5]),
	.tlb_way(sr_req.addr[4:3]),
	.tlb_data(sr_req.data),
	
	.virt_read(virt_read),
	.virt_addr(virt_addr),
	.phys_addr(phys_addr[0]),
	.hit(hit[0]),
	.temp(temp0)
);

wire lTLB_write = sr_write && (sr_req.addr[15:14] == 2'b01);
cy_slave #(
	.ORDER(6),
	.PAGE_BITS(21),
	.ASSOC(1)
) lTLB (
	.clk(clk),
	.rst(rst),
	
	.tlb_write(lTLB_write),
	.tlb_addr(sr_req.addr[13:8]),
	.tlb_way(sr_req.addr[7]),
	.tlb_data(sr_req.data),
	
	.virt_read(virt_read),
	.virt_addr(virt_addr),
	.phys_addr(phys_addr[1]),
	.hit(hit[1]),
	.temp(temp1)
);

wire xlTLB_write = sr_write && (sr_req.addr[15:13] == 3'b001);
cy_slave #(
	.ORDER(2),
	.PAGE_BITS(32),
	.ASSOC(2)
) xlTLB (
	.clk(clk),
	.rst(rst),
	
	.tlb_write(xlTLB_write),
	.tlb_addr(sr_req.addr[12:11]),
	.tlb_way(sr_req.addr[10:09]),
	.tlb_data(sr_req.data),
	
	.virt_read(virt_read),
	.virt_addr(virt_addr),
	.phys_addr(phys_addr[2]),
	.hit(hit[2]),
	.temp(temp2)
);


// read tx FIFO
reg rtf_wrreq;
reg [90:0] rtf_data;
wire rtf_full;
wire [90:0] rtf_q;
wire rtf_empty;
reg rtf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(FIFO_LD)
) r_tx_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rtf_wrreq),
	.data(rtf_data),
	.full(rtf_full),
	.q(rtf_q),
	.empty(rtf_empty),
	.rdreq(rtf_rdreq)
);

// write addr FIFO
reg wtf_wrreq;
reg [90:0] wtf_data;
wire wtf_full;
wire [90:0] wtf_q;
wire wtf_empty;
reg wtf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+64+8+3),
	.LOG_DEPTH(FIFO_LD)
) w_tx_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wtf_wrreq),
	.data(wtf_data),
	.full(wtf_full),
	.q(wtf_q),
	.empty(wtf_empty),
	.rdreq(wtf_rdreq)
);

// read data FIFO
reg rdf_wrreq;
reg [530:0] rdf_data;
wire rdf_full;
wire [530:0] rdf_q;
wire rdf_empty;
reg rdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+512+2+1),
	.LOG_DEPTH(1)
) r_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_data),
	.full(rdf_full),
	.q(rdf_q),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);

// write data FIFO
reg wdf_wrreq;
reg [576:0] wdf_data;
wire wdf_full;
wire [576:0] wdf_q;
wire wdf_empty;
reg wdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512+64+1),
	.LOG_DEPTH(1)
) w_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wdf_wrreq),
	.data(wdf_data),
	.full(wdf_full),
	.q(wdf_q),
	.empty(wdf_empty),
	.rdreq(wdf_rdreq)
);

// write response FIFO
reg wrf_wrreq;
reg [17:0] wrf_data;
wire wrf_full;
wire [17:0] wrf_q;
wire wrf_empty;
reg wrf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16+2),
	.LOG_DEPTH(1)
) w_resp_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wrf_wrreq),
	.data(wrf_data),
	.full(wrf_full),
	.q(wrf_q),
	.empty(wrf_empty),
	.rdreq(wrf_rdreq)
);

// write credits
reg [DATA_FIFO_LD:0] reads_out;
reg [FIFO_LD:0] writes_out;

// state machine
reg [2:0] state;
reg [63:0] addr_reg;
wire miss = state == 5;

always @(posedge clk) begin
	case (state)
		0: begin
			// idle
			if (virt_m.arvalid && !rtf_full) begin
				virt_read <= 1;
				virt_addr <= virt_m.araddr;
				state <= 1;
			end else if (virt_m.awvalid && !wtf_full) begin
				virt_read <= 0;
				virt_addr <= virt_m.awaddr;
				state <= 1;
			end
		end
		1: begin
			// mutex
			state <= 2;
		end
		2: begin
			// wait for BRAM data
			state <= 3;
		end
		3: begin
			// check
			state <= (hit[0] || hit[1] || hit[2]) ? 6 : 4;
		end
		4: begin
			// drain
			if (reads_out == 0 && writes_out == 0) state <= 5;
		end
		5: begin
			// miss
			if (sr_write && sr_req.addr == 8) state <= 3;
		end
		6: begin
			// hit
			addr_reg <= hit[0] ? phys_addr[0] : (hit[1] ? phys_addr[1] : phys_addr[2]);
			state <= 7;
		end
		7: begin
			// send
			state <= 0;
		end
	endcase
	
	sr_resp.valid <= sr_read;
	sr_resp.data <= {10'h000, virt_addr[63:12], virt_read, miss};
	/*
	case (sr_req.addr)
		32'h00: sr_resp.data <= {10'h000, virt_addr[63:12], virt_read, miss};
		32'h08: sr_resp.data <= state;
		32'h10: sr_resp.data <= virt_read;
		32'h18: sr_resp.data <= virt_addr;
		32'h20: sr_resp.data <= hit[0];
		32'h28: sr_resp.data <= hit[1];
		32'h30: sr_resp.data <= phys_addr[0];
		32'h38: sr_resp.data <= phys_addr[1];
		32'h40: sr_resp.data <= temp0[0];
		32'h48: sr_resp.data <= temp0[1];
		32'h50: sr_resp.data <= temp0[2];
		32'h58: sr_resp.data <= temp0[3];
		32'h60: sr_resp.data <= temp1[0];
		32'h68: sr_resp.data <= temp1[1];
		32'h70: sr_resp.data <= addr_reg;
		32'h78: sr_resp.data <= wr_cred;
		32'h80: sr_resp.data <= rtf_empty;
		32'h88: sr_resp.data <= rtf_full;
		32'h90: sr_resp.data <= wtf_empty;
		32'h98: sr_resp.data <= wtf_full;
		32'hA0: sr_resp.data <= wdf_empty;
		32'hA8: sr_resp.data <= wdf_full;
		32'hB0: sr_resp.data <= reads_out;
		32'hB8: sr_resp.data <= writes_out;
		default: sr_resp.data <= {10'h000, virt_addr[63:12], virt_read, miss};
	endcase */
	
	if (rst) state <= 0;
end

axi_bus_t phys_o();

always_comb begin
	// read requests buffered in FIFO
	virt_m.arready = virt_read && (state == 7);
	rtf_wrreq = virt_read && (state == 7);
	rtf_data = {virt_m.arid, addr_reg, virt_m.arlen, virt_m.arsize};
	phys_o.arvalid = !rtf_empty;
	rtf_rdreq = phys_o.arready;
	{phys_o.arid, phys_o.araddr, phys_o.arlen, phys_o.arsize} = rtf_q;
	
	// read data buffered in FIFO
	phys_o.rready = !rdf_full;
	rdf_wrreq = phys_o.rvalid;
	rdf_data = {phys_o.rid, phys_o.rdata, phys_o.rresp, phys_o.rlast};
	virt_m.rvalid = !rdf_empty;
	rdf_rdreq = virt_m.rready;
	{virt_m.rid, virt_m.rdata, virt_m.rresp, virt_m.rlast} = rdf_q;
	
	// write requests buffered in FIFO
	virt_m.awready = !virt_read && (state == 7);
	wtf_wrreq = !virt_read && (state == 7);
	wtf_data = {virt_m.awid, addr_reg, virt_m.awlen, virt_m.awsize};
	phys_o.awvalid = !wtf_empty;
	wtf_rdreq = phys_o.awready;
	{phys_o.awid, phys_o.awaddr, phys_o.awlen, phys_o.awsize} = wtf_q;
	
	// write data buffered in FIFO
	virt_m.wready = !wdf_full;
	wdf_wrreq = virt_m.wvalid;
	wdf_data = {virt_m.wdata, virt_m.wstrb, virt_m.wlast};
	phys_o.wvalid = !wdf_empty;
	wdf_rdreq = phys_o.wready;
	{phys_o.wdata, phys_o.wstrb, phys_o.wlast} = wdf_q;
	
	// write response pass through
	phys_o.bready = !wrf_full;
	wrf_wrreq = phys_o.bvalid;
	wrf_data = {phys_o.bid, phys_o.bresp};
	virt_m.bvalid = !wrf_empty;
	wrf_rdreq = virt_m.bready;
	{virt_m.bid, virt_m.bresp} = wrf_q;
end

wire read_start = rtf_wrreq;
wire read_end = rdf_wrreq && !rdf_full && phys_o.rlast;
wire write_start = wtf_wrreq;
wire write_end = wrf_wrreq;
always @(posedge clk) begin
	reads_out <= reads_out + read_start - read_end;
	writes_out <= writes_out + write_start - write_end;
	
	if (rst) begin
		reads_out <= 0;
		writes_out <= 0;
	end
end

cy_stripe #(
	.INIT_MODE(1),
	.SR_ADDR('h10)
) cy_str (
	.clk(clk),
	.rst(rst),
	
	.sr_req(sr_req),
	
	.phys_m(phys_o),
	.phys_s(phys_s)
);

endmodule
