// Manages host streams
// 1 FIFO per app, 32 packets per FIFO
// By Joshua Landgraf

import ShellTypes::*;

// Arbiter module
module fifo_arb (
	input clk,
	input rst,
	
	input ready,
	input [3:0] reqs,
	output logic [1:0] sel
);

reg [1:0] prio = 0;
always @(posedge clk) begin
	if (ready) prio <= prio + 1;
end

always_comb begin
	logic [1:0] idx;
	
	sel = 0;
	for (integer i = 0; i < 4; i = i + 1) begin
		idx = (prio + i) % 4;
		if (reqs[idx]) begin
			sel = idx;
		end
	end
end

endmodule


module host_fifo (
	input clk,
	input rst,
	
	// Soft register interface
	input  SoftRegReq  softreg_req[3:0],
	output SoftRegResp softreg_resp[3:0],
	
	axi_bus_t.master ax_s,
	axi_bus_t.slave  ax_m,
	
	// PCIe access
	axi_bus_t.slave pcim
);
localparam SEND_LD = 4;
localparam RECV_LD = 3;


//// AXI register slices
// Locks in addr bus values
axi_bus_t axi_m ();
axi_reg ar_m (
	.clk(clk),
	.rst_n(!rst),
	
	.axi_s(axi_m),
	.axi_m(ax_m)
);

axi_bus_t axi_s ();
axi_reg ar_s (
	.clk(clk),
	.rst_n(!rst),
	
	.axi_s(ax_s),
	.axi_m(axi_s)
);

axi_bus_t pcie_m ();
axi_reg #(
	.EN_RD(1)
) ar_pm (
	.clk(clk),
	.rst_n(!rst),
	
	.axi_s(pcie_m),
	.axi_m(pcim)
);


//// Global FIFOs
// Read metadata FIFO
// Select, length, and last
logic rmf_wrreq;
logic [8:0] rmf_data;
logic rmf_full;
logic [8:0] rmf_q;
logic rmf_empty;
logic rmf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(2+6+1),
	.LOG_DEPTH(6)
) read_meta_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rmf_wrreq),
	.data(rmf_data),
	.full(rmf_full),
	.q(rmf_q),
	.empty(rmf_empty),
	.rdreq(rmf_rdreq)
);

// Read data FIFO
logic rdf_wrreq;
logic [511:0] rdf_data;
logic rdf_full;
logic [511:0] rdf_q;
logic rdf_empty;
logic rdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512),
	.LOG_DEPTH(6)
) read_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rdf_wrreq),
	.data(rdf_data),
	.full(rdf_full),
	.q(rdf_q),
	.empty(rdf_empty),
	.rdreq(rdf_rdreq)
);

// Write metadata FIFO
// Select, length, and last
logic wmf_wrreq;
logic [8:0] wmf_data;
logic wmf_full;
logic [8:0] wmf_q;
logic wmf_empty;
logic wmf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(2+6+1),
	.LOG_DEPTH(1)
) write_meta_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(wmf_wrreq),
	.data(wmf_data),
	.full(wmf_full),
	.q(wmf_q),
	.empty(wmf_empty),
	.rdreq(wmf_rdreq)
);

// Write data FIFO
logic wdf_wrreq;
logic [511:0] wdf_data;
logic wdf_full;
logic [511:0] wdf_q;
logic wdf_empty;
logic wdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(512),
	.LOG_DEPTH(6)
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

// PCIe meta FIFO
// Index, sel, last, and length
logic pmf_wrreq;
logic [23:0] pmf_data;
logic pmf_full;
logic [23:0] pmf_q;
logic pmf_empty;
logic pmf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(15+2+1+6),
	.LOG_DEPTH(1)
) pcie_meta_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pmf_wrreq),
	.data(pmf_data),
	.full(pmf_full),
	.q(pmf_q),
	.empty(pmf_empty),
	.rdreq(pmf_rdreq)
);

// PCIe meta data FIFO
// Sel, last, and length
logic pmdf_wrreq;
logic [8:0] pmdf_data;
logic pmdf_full;
logic [8:0] pmdf_q;
logic pmdf_empty;
logic pmdf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(2+1+6),
	.LOG_DEPTH(1)
) pcie_meta_data_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(pmdf_wrreq),
	.data(pmdf_data),
	.full(pmdf_full),
	.q(pmdf_q),
	.empty(pmdf_empty),
	.rdreq(pmdf_rdreq)
);

// RX bid FIFO
logic rbf_wrreq;
logic [15:0] rbf_data;
logic rbf_full;
logic [15:0] rbf_q;
logic rbf_empty;
logic rbf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(16),
	.LOG_DEPTH(1)
) rx_bid_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(rbf_wrreq),
	.data(rbf_data),
	.full(rbf_full),
	.q(rbf_q),
	.empty(rbf_empty),
	.rdreq(rbf_rdreq)
);

// Global receive response FIFO
// Sel, pointer, last, and length
logic grpf_wrreq;
logic [14:0] grpf_data;
logic grpf_full;
logic [14:0] grpf_q;
logic grpf_empty;
logic grpf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(2+6+1+6),
	.LOG_DEPTH(1)
) glbl_recv_resp_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(grpf_wrreq),
	.data(grpf_data),
	.full(grpf_full),
	.q(grpf_q),
	.empty(grpf_empty),
	.rdreq(grpf_rdreq)
);

// Global send request FIFO
// Sel, length, and last
logic gsqf_wrreq;
logic [8:0] gsqf_data;
logic gsqf_full;
logic [8:0] gsqf_q;
logic gsqf_empty;
logic gsqf_rdreq;

HullFIFO #(
	.TYPE(0),
	.WIDTH(2+6+1),
	.LOG_DEPTH(1)
) glbl_send_req_fifo (
	.clock(clk),
	.reset_n(~rst),
	.wrreq(gsqf_wrreq),
	.data(gsqf_data),
	.full(gsqf_full),
	.q(gsqf_q),
	.empty(gsqf_empty),
	.rdreq(gsqf_rdreq)
);


//// Per-app data structures
// Host send request FIFO
// Full length and last
logic shf_wrreq [3:0];
logic [15:0] shf_data [3:0];
logic shf_full [3:0];
logic [15:0] shf_q [3:0];
logic shf_empty [3:0];
logic shf_rdreq [3:0];

// Send address FIFO
logic saf_wrreq [3:0];
logic [47:0] saf_data [3:0];
logic saf_full [3:0];
logic [47:0] saf_q [3:0];
logic saf_empty [3:0];
logic saf_rdreq [3:0];

// Send request FIFO
// Length and last
logic sqf_wrreq [3:0];
logic [6:0] sqf_data [3:0];
logic sqf_full [3:0];
logic [6:0] sqf_q [3:0];
logic sqf_empty [3:0];
logic sqf_rdreq [3:0];

// Send response FIFO
// Length and last
logic spf_wrreq [3:0];
logic [6:0] spf_data [3:0];
logic spf_full [3:0];
logic [6:0] spf_q [3:0];
logic spf_empty [3:0];
logic spf_rdreq [3:0];

// Receive request FIFO
// Pointer, last, and length
logic rqf_wrreq [3:0];
logic [12:0] rqf_data [3:0];
logic rqf_full [3:0];
logic [12:0] rqf_q [3:0];
logic rqf_empty [3:0];
logic rqf_rdreq [3:0];

// Receive response FIFO
// Pointer, last, and length
logic rpf_wrreq [3:0];
logic [12:0] rpf_data [3:0];
logic rpf_full [3:0];
logic [12:0] rpf_q [3:0];
logic rpf_empty [3:0];
logic rpf_rdreq [3:0];

// Addresses, indices, and more
reg [48:0] cntrl_addr [3:0];
reg [48:0] data_addr [3:0];
reg [48:0] host_send_addr [3:0];
reg [48:0] host_recv_addr [3:0];
reg [48:0] host_meta_addr [3:0];
reg [14:0] recv_idx [3:0];
reg [10:0] meta_idx [3:0];
reg [5:0] s_creds [3:0];
reg [15:0] s_data_creds [3:0];
reg [15:0] r_creds [3:0];
reg [10:0] r_meta_creds [3:0];

// Signals
logic rst_send [3:0];
logic add_s_data_cred [3:0];
logic use_s_creds [3:0];
logic [6:0] add_recv_idx [3:0];
logic add_meta_idx [3:0];
logic rst_recv [3:0];
logic [15:0] add_r_creds [3:0];
logic [10:0] add_r_meta_creds [3:0];
logic send_done [3:0];
logic recv_done [3:0];


//// Per-app FIFO implementation
for (genvar i = 0; i < 4; i = i + 1) begin : FIFO
	//// FIFOs
	HullFIFO #(
		.TYPE(0),
		.WIDTH(15+1),
		.LOG_DEPTH(5)
	) host_send_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(shf_wrreq[i]),
		.data(shf_data[i]),
		.full(shf_full[i]),
		.q(shf_q[i]),
		.empty(shf_empty[i]),
		.rdreq(shf_rdreq[i])
	);
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(48),
		.LOG_DEPTH(SEND_LD)
	) send_addr_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(saf_wrreq[i]),
		.data(saf_data[i]),
		.full(saf_full[i]),
		.q(saf_q[i]),
		.empty(saf_empty[i]),
		.rdreq(saf_rdreq[i])
	);
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(6+1),
		.LOG_DEPTH(1)
	) send_req_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(sqf_wrreq[i]),
		.data(sqf_data[i]),
		.full(sqf_full[i]),
		.q(sqf_q[i]),
		.empty(sqf_empty[i]),
		.rdreq(sqf_rdreq[i])
	);
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(6+1),
		.LOG_DEPTH(SEND_LD)
	) send_resp_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(spf_wrreq[i]),
		.data(spf_data[i]),
		.full(spf_full[i]),
		.q(spf_q[i]),
		.empty(spf_empty[i]),
		.rdreq(spf_rdreq[i])
	);
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(6+1+6),
		.LOG_DEPTH(5)
	) recv_req_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(rqf_wrreq[i]),
		.data(rqf_data[i]),
		.full(rqf_full[i]),
		.q(rqf_q[i]),
		.empty(rqf_empty[i]),
		.rdreq(rqf_rdreq[i])
	);
	
	HullFIFO #(
		.TYPE(0),
		.WIDTH(6+1+6),
		.LOG_DEPTH(1)
	) recv_resp_fifo (
		.clock(clk),
		.reset_n(~rst),
		.wrreq(rpf_wrreq[i]),
		.data(rpf_data[i]),
		.full(rpf_full[i]),
		.q(rpf_q[i]),
		.empty(rpf_empty[i]),
		.rdreq(rpf_rdreq[i])
	);
	
	
	// Throttling
	reg [SEND_LD:0] send_limit;
	reg [RECV_LD:0] recv_limit;
	wire send_space = send_limit > 0;
	wire recv_space = recv_limit > 0;
	logic send_req;
	logic recv_req;
	
	always @(posedge clk) begin
		send_limit <= send_limit + send_done[i] - (send_req && send_space);
		recv_limit <= recv_limit + recv_done[i] - (recv_req && recv_space);
		
		if (rst_send[i]) send_limit <= 1<<SEND_LD;
		if (rst_recv[i]) recv_limit <= 1<<RECV_LD;
		
		if (rst) begin
			send_limit <= 1<<SEND_LD;
			recv_limit <= 1<<RECV_LD;
		end
	end
	
	
	//// Send credits
	logic add_s_cred;
	
	always_ff @(posedge clk) begin
		s_creds[i] <= (use_s_creds[i] ? 0 : s_creds[i]) + add_s_cred;
		s_data_creds[i] <= (use_s_creds[i] ? 0 : s_data_creds[i]) + add_s_data_cred[i];
		
		if (rst_send[i]) begin
			s_creds[i] <= 0;
			s_data_creds[i] <= 0;
		end
		
		if (rst) begin
			s_creds[i] <= 0;
			s_data_creds[i] <= 0;
		end
	end
	
	
	//// Send logic
	begin: SEND
		reg [14:0] idx;
		reg [14:0] len_done;
		
		wire [14:0] len_left = shf_q[i][15:1] - len_done;
		wire [5:0] page_len = 63 - idx[5:0];
		wire last = len_left <= page_len;
		wire [5:0] len = last ? len_left : page_len;
		wire accept = send_space && !shf_empty[i] && !saf_full[i] && !sqf_full[i];
		
		assign send_req = accept;
		
		assign saf_data[i] = {host_send_addr[i][48:21], idx, 6'h00};
		assign saf_wrreq[i] = accept;
		
		assign sqf_data[i] = {len, last && shf_q[i][0]};
		assign sqf_wrreq[i] = accept;
		
		assign shf_rdreq[i] = accept && last;
		assign add_s_cred = accept && last;
		
		always_ff @(posedge clk) begin
			if (accept) begin
				idx <= idx + len + 1;
				len_done <= last ? 0 : (len_done + len + 1);
			end
			
			if (rst_send[i]) begin
				idx <= 0;
				len_done <= 0;
			end
			
			if (rst) begin
				idx <= 0;
				len_done <= 0;
			end
		end
	end
	
	
	//// Receive logic
	always_ff @(posedge clk) begin
		recv_idx[i] <= recv_idx[i] + add_recv_idx[i];
		meta_idx[i] <= meta_idx[i] + add_meta_idx[i];
		
		if (rst_recv[i]) begin
			recv_idx[i] <= 0;
			meta_idx[i] <= 0;
		end
		
		if (rst) begin
			recv_idx[i] <= 0;
			meta_idx[i] <= 0;
		end
	end
	
	
	//// Receive credits
	// Data and metadata
	logic [5:0] req_r_creds;
	logic req_r_cred;
	
	wire have_r_cred = recv_space && (r_meta_creds[i] > 0) && (r_creds[i] > req_r_creds);
	wire use_r_cred = req_r_cred && have_r_cred;
	wire [6:0] use_r_creds = use_r_cred ? (req_r_creds + 1) : 0;
	
	always_ff @(posedge clk) begin
		r_creds[i] <= r_creds[i] + add_r_creds[i] - use_r_creds;
		r_meta_creds[i] <= r_meta_creds[i] + add_r_meta_creds[i] - use_r_cred;
		
		if (rst_recv[i]) begin
			r_creds[i] <= 0;
			r_meta_creds[i] <= 0;
		end
		
		if (rst) begin
			r_creds[i] <= 0;
			r_meta_creds[i] <= 0;
		end
	end
	
	//// Receive response generator
	// Credit requests (rqf)
	// Credit responses (rpf)
	always_comb begin
		req_r_cred = !rqf_empty[i] && !rpf_full[i];
		req_r_creds = rqf_q[i][5:0];
		
		rpf_data[i] = rqf_q[i];
		rqf_rdreq[i] = req_r_cred && have_r_cred;
		rpf_wrreq[i] = req_r_cred && have_r_cred;
		recv_req = req_r_cred && have_r_cred;
	end
end


//// FPGA write to PCIe write
// Write metadata (wmf)
// PCIe metadata (pmf)
begin: CONV
	wire [1:0] sel = wmf_q[8:7];
	wire [14:0] idx = recv_idx[sel];
	reg [5:0] len_done;
	
	wire [5:0] len_left = wmf_q[6:1] - len_done;
	wire [5:0] page_len = 63 - idx[5:0];
	wire last = len_left <= page_len;
	wire [5:0] len = last ? len_left : page_len;
	wire accept = !wmf_empty && !pmf_full && !pmdf_full;
	
	assign pmf_data = {idx, sel, len, last};
	assign pmf_wrreq = accept;
	
	assign pmdf_data = {sel, len, wmf_q[0]};
	assign pmdf_wrreq = accept && last;
	
	assign wmf_rdreq = accept && last;
	
	always_comb begin
		for (integer i = 0; i < 4; i = i + 1) begin
			add_recv_idx[i] = 0;
		end
		if (accept) add_recv_idx[sel] = len + 1;
	end
	
	always_ff @(posedge clk) begin
		if (accept) len_done <= last ? 0 : (len_done + len + 1);
		
		if (rst) len_done <= 0;
	end
end


//// PCIe write
// Write data (pmf, wdf)
// Write metadata (pmdf)
begin: WRITE
	reg [20:0] tx_data;
	reg tx_valid;
	wire tx_rd = pcie_m.wready && pcie_m.wvalid && pcie_m.wlast;
	wire tx_wr = pcie_m.awready && pcie_m.awvalid;
	wire tx_ready = !tx_valid || tx_rd;
	logic [20:0] tx_next;
	
	// PCIE_M AW
	reg pmdf_valid;
	logic pmdf_next;
	logic [1:0] sel;
	always_comb begin
		pcie_m.awid = 0;
		pcie_m.awsize = 3'b110;
		
		pmf_rdreq = 0;
		pmdf_rdreq = 0;
		pmdf_next = 0;
		
		for (integer i = 0; i < 4; i = i + 1) begin
			add_meta_idx[i] = 0;
		end
		
		if (pmdf_valid) begin
			sel = pmdf_q[8:7];
			pcie_m.awaddr = {host_meta_addr[sel][48:12], meta_idx[sel][9:4], 6'h00};
			pcie_m.awlen = 0;
			pcie_m.awvalid = tx_ready && !pmdf_empty;
			
			tx_next[20:7] = {meta_idx[sel][3:0], pmdf_q[8:7], !meta_idx[sel][10], pmdf_q[6:0]};
			tx_next[0] = 1'd0;
			pmdf_rdreq = pcie_m.awready && pcie_m.awvalid;
			add_meta_idx[sel] = pcie_m.awready && pcie_m.awvalid;
		end else if (!pmf_empty && !wdf_empty) begin
			sel = pmf_q[8:7];
			pcie_m.awaddr = {host_recv_addr[sel][48:21], pmf_q[23:9], 6'h00};
			pcie_m.awlen = pmf_q[6:1];
			pcie_m.awvalid = tx_ready;
			
			tx_next[20:7] = 0;
			tx_next[0] = 1'd1;
			pmf_rdreq = pcie_m.awready && pcie_m.awvalid;
			pmdf_next = pmf_q[0];
		end else begin
			sel = pmf_q[8:7];
			pcie_m.awaddr = {host_recv_addr[sel][48:21], pmf_q[23:9], 6'h00};
			pcie_m.awlen = pmf_q[6:1];
			pcie_m.awvalid = 0;
			
			tx_next[20:7] = 0;
			tx_next[0] = 1'd1;
		end
		
		tx_next[6:1] = pcie_m.awlen[5:0];
	end
	
	// pcie_m W
	reg [5:0] len;
	
	always_comb begin
		pcie_m.wlast = len == tx_data[6:1];
		
		wdf_rdreq = 0;
		
		for (integer i = 0; i < 4; i = i + 1) begin
			recv_done[i] = 0;
		end
		
		case (tx_data[0])
			1'd0: begin
				pcie_m.wdata = {16 {24'h000000, tx_data[14:7]}};
				pcie_m.wstrb = 4'hF << (4*tx_data[20:17]);
				pcie_m.wvalid = tx_valid;
				
				recv_done[tx_data[16:15]] = pcie_m.wready && pcie_m.wvalid && pcie_m.wlast;
			end
			1'd1: begin
				pcie_m.wdata = wdf_q;
				pcie_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
				pcie_m.wvalid = tx_valid && !wdf_empty;
				
				wdf_rdreq = tx_valid && pcie_m.wready;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		tx_valid <= tx_wr || (tx_valid && !tx_rd);
		if (tx_wr && (!tx_valid || tx_rd)) tx_data <= tx_next;
		
		if (pcie_m.awready && pcie_m.awvalid) pmdf_valid <= pmdf_next;
		if (pcie_m.wready && pcie_m.wvalid) len <= pcie_m.wlast ? 0 : (len + 1);
		
		if (rst) begin
			tx_valid <= 0;
			pmdf_valid <= 0;
			len <= 0;
		end
	end
	
	// pcie_m B
	assign pcie_m.bready = 1;
end


//// PCIe read
begin: READ
	//// AR logic
	reg [1:0] sel = 0;
	wire valid = !saf_empty[sel] && !spf_empty[sel];
	wire ready = pcie_m.arready && !rmf_full;
	wire accept = ready && valid;
	
	assign pcie_m.arid = 0;
	assign pcie_m.araddr = saf_q[sel];
	assign pcie_m.arlen = spf_q[sel][6:1];
	assign pcie_m.arsize = 3'b110;
	assign pcie_m.arvalid = valid && !rmf_full;
	
	assign rmf_data = {sel, spf_q[sel]};
	assign rmf_wrreq = accept;
	
	always_comb begin
		for (integer i = 0; i < 4; i = i + 1) begin
			saf_rdreq[i] = 0;
			spf_rdreq[i] = 0;
		end
		if (accept) begin
			saf_rdreq[sel] = 1;
			spf_rdreq[sel] = 1;
		end
	end
	
	// Hold valid data until accepted
	always_ff @(posedge clk) begin
		if (ready || !valid) sel <= sel + 1;
	end
	
	
	//// R logic
	assign rdf_data = pcie_m.rdata;
	assign rdf_wrreq = pcie_m.rvalid;
	assign pcie_m.rready = !rdf_full;
end


//// Global receive response logic
// Receive response (rpf)
// Global receive response (grpf)
begin: GRP
	logic grp_arb_ready;
	logic [3:0] grp_arb_reqs;
	logic [1:0] grp_arb_sel;
	
	fifo_arb grp_arb (
		.clk(clk),
		.rst(rst),
		
		.ready(grp_arb_ready),
		.reqs(grp_arb_reqs),
		.sel(grp_arb_sel)
	);
	
	always_comb begin
		for (integer i = 0; i < 4; i = i + 1) begin
			rpf_rdreq[i] = 0;
			grp_arb_reqs[i] = !rpf_empty[i];
		end
		
		grp_arb_ready = !grpf_full;
		
		grpf_data[14:13] = grp_arb_sel;
		grpf_data[12:0] = rpf_q[grp_arb_sel];
		grpf_wrreq = !rpf_empty[grp_arb_sel];
		rpf_rdreq[grp_arb_sel] = !grpf_full;
	end
end


//// Global send request logic
// Send request (sqf)
// Global send request (gsqf)
begin: GSQ
	logic gsq_arb_ready;
	logic [3:0] gsq_arb_reqs;
	logic [1:0] gsq_arb_sel;
	
	fifo_arb gsq_arb (
		.clk(clk),
		.rst(rst),
		
		.ready(gsq_arb_ready),
		.reqs(gsq_arb_reqs),
		.sel(gsq_arb_sel)
	);
	
	always_comb begin
		for (integer i = 0; i < 4; i = i + 1) begin
			sqf_rdreq[i] = 0;
			gsq_arb_reqs[i] = !sqf_empty[i];
		end
		
		gsq_arb_ready = !gsqf_full;
		
		gsqf_data[8:7] = gsq_arb_sel;
		gsqf_data[6:0] = sqf_q[gsq_arb_sel];
		gsqf_wrreq = !sqf_empty[gsq_arb_sel];
		sqf_rdreq[gsq_arb_sel] = !gsqf_full;
	end
end


//// TX
// Receive response (grpf)
// Send request (gsqf)
// Data payloads (rmf, rdf)
begin: TX
	reg [20:0] tx_data;
	reg tx_valid;
	wire tx_rd = axi_m.wready && axi_m.wvalid && axi_m.wlast;
	wire tx_wr = axi_m.awready && axi_m.awvalid;
	wire tx_ready = !tx_valid || tx_rd;
	logic [20:0] tx_next;
	
	// AXI_M AW
	logic [12:0] data_addr_off;
	always_comb begin
		axi_m.awid = 0;
		axi_m.awsize = 3'b110;
		
		grpf_rdreq = 0;
		gsqf_rdreq = 0;
		rmf_rdreq = 0;
		
		data_addr_off = rmf_q[0] ? (4096 + 64*(63-rmf_q[6:1])) : 0;
		
		 if (!grpf_empty) begin
			axi_m.awaddr = cntrl_addr[grpf_q[14:13]];
			axi_m.awlen = 0;
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = grpf_q[12:0];
			tx_next[1:0] = 2'd0;
			grpf_rdreq = axi_m.awready && axi_m.awvalid;
		end else if (!gsqf_empty) begin
			axi_m.awaddr = cntrl_addr[gsqf_q[8:7]];
			axi_m.awlen = 0;
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = {gsqf_q[0], gsqf_q[6:1]};
			tx_next[1:0] = 2'd1;
			gsqf_rdreq = axi_m.awready && axi_m.awvalid;
		end else if (!rmf_empty && !rdf_empty) begin
			axi_m.awaddr = data_addr[rmf_q[8:7]] | data_addr_off;
			axi_m.awlen = rmf_q[6:1];
			axi_m.awvalid = tx_ready;
			
			tx_next[20:8] = rmf_q[8:7];
			tx_next[1:0] = 2'd2;
			rmf_rdreq = axi_m.awready && axi_m.awvalid;
		end else begin
			axi_m.awaddr = data_addr[rmf_q[8:7]] | data_addr_off;
			axi_m.awlen = rmf_q[6:1];
			axi_m.awvalid = 0;
			
			tx_next[20:8] = rmf_q[8:7];
			tx_next[1:0] = 2'd2;
		end
		
		tx_next[7:2] = axi_m.awlen[5:0];
	end
	
	// AXI_M W
	reg [5:0] len;
	
	always_comb begin
		axi_m.wlast = len == tx_data[7:2];
		
		rdf_rdreq = 0;
		
		for (integer i = 0; i < 4; i = i + 1) begin
			add_s_data_cred[i] = 0;
			send_done[i] = 0;
		end
		
		case (tx_data[1:0])
			2'd0: begin
				axi_m.wdata = {1'b1, tx_data[20:8]};
				axi_m.wstrb = 64'h000000000000000F;
				axi_m.wvalid = tx_valid;
			end
			2'd1: begin
				axi_m.wdata = {1'b0, tx_data[20:8]};
				axi_m.wstrb = 64'h000000000000000F;
				axi_m.wvalid = tx_valid;
			end
			2'd2: begin
				axi_m.wdata = rdf_q;
				axi_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
				axi_m.wvalid = tx_valid && !rdf_empty;
				
				rdf_rdreq = tx_valid && axi_m.wready;
				add_s_data_cred[tx_data[9:8]] = axi_m.wready && axi_m.wvalid;
				send_done[tx_data[9:8]] = axi_m.wready && axi_m.wvalid && axi_m.wlast;
			end
			default: begin
				axi_m.wdata = rdf_q;
				axi_m.wstrb = 64'hFFFFFFFFFFFFFFFF;
				axi_m.wvalid = 0;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		tx_valid <= tx_wr || (tx_valid && !tx_rd);
		if (tx_wr && (!tx_valid || tx_rd)) tx_data <= tx_next;
		
		if (axi_m.wready && axi_m.wvalid) len <= axi_m.wlast ? 0 : (len + 1);
		
		if (rst) begin
			tx_valid <= 0;
			len <= 0;
		end
	end
	
	// AXI_M B
	assign axi_m.bready = 1;
end


//// RX
// Credit responses (spf)
// Credit requests (rqf)
// Data payloads (wmf, wdf)
begin: RX
	reg first;
	wire last_addr = (axi_s.awaddr[12:6] + axi_s.awlen[5:0]) == 7'h7F;
	assign axi_s.awready = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	assign rbf_wrreq = axi_s.wready && axi_s.wvalid && axi_s.wlast;
	
	always_comb begin
		// AXI_S AW and W
		axi_s.wready = 0;
		
		for (integer i = 0; i < 4; i = i + 1) begin
			spf_wrreq[i] = 0;
			rqf_wrreq[i] = 0;
			
			spf_data[i] = {axi_s.wdata[5:0], axi_s.wdata[6]};
			rqf_data[i] = {axi_s.wdata[12:0]};
		end
		
		wmf_wrreq = 0;
		wdf_wrreq = 0;
		
		wmf_data = {axi_s.awaddr[14:13], axi_s.awlen[5:0], last_addr};
		wdf_data = axi_s.wdata;
		rbf_data = axi_s.awid;
		
		if (axi_s.awvalid && axi_s.wvalid && !rbf_full) begin
			if (axi_s.awaddr[15]) begin
				if (axi_s.wdata[13]) begin
					// Response
					axi_s.wready = !spf_full[axi_s.awaddr[7:6]];
					spf_wrreq[axi_s.awaddr[7:6]] = 1;
				end else begin
					// Request
					axi_s.wready = !rqf_full[axi_s.awaddr[7:6]];
					rqf_wrreq[axi_s.awaddr[7:6]] = 1;
				end
			end else begin
				// Data
				axi_s.wready = !wmf_full && !wdf_full;
				wmf_wrreq = !wdf_full && first;
				wdf_wrreq = !wmf_full;
			end
		end
		
		// AXI_S B
		axi_s.bid = rbf_q;
		axi_s.bresp = 2'b00;
		axi_s.bvalid = !rbf_empty;
		rbf_rdreq = axi_s.bready;
	end
	
	always_ff @(posedge clk) begin
		if (axi_s.wready && axi_s.wvalid) first <= axi_s.wlast;
		
		if (rst) first <= 1;
	end
end


//// SoftReg
for (genvar i = 0; i < 4; i = i + 1) begin : SR
	wire softreg_read = softreg_req[i].valid && !softreg_req[i].isWrite;
	wire softreg_write = softreg_req[i].valid && softreg_req[i].isWrite;
	
	assign rst_send[i] = softreg_write && (softreg_req[i].addr == 32'h10);
	
	assign shf_data[i] = softreg_req[i].data;
	assign shf_wrreq[i] = softreg_write && (softreg_req[i].addr == 32'h18);
	
	assign use_s_creds[i] = softreg_read && (softreg_req[i].addr == 32'h18);
	
	assign rst_recv[i] = softreg_write && (softreg_req[i].addr == 32'h28);
	
	wire add_r_cred = softreg_write && (softreg_req[i].addr == 32'h30);
	assign add_r_creds[i] = add_r_cred ? softreg_req[i].data[15:0] : 0;
	assign add_r_meta_creds[i] = add_r_cred ? softreg_req[i].data[26:16] : 0;
	
	always_ff @(posedge clk) begin
		if (softreg_write) begin
			case (softreg_req[i].addr)
				32'h00: cntrl_addr[i] <= softreg_req[i].data;
				32'h08: data_addr[i] <= softreg_req[i].data;
				32'h10: host_send_addr[i] <= softreg_req[i].data;
				32'h18: begin end
				32'h20: host_recv_addr[i] <= softreg_req[i].data;
				32'h28: host_meta_addr[i] <= softreg_req[i].data;
				32'h30: begin end
				default: begin end
			endcase
		end
		
		softreg_resp[i].valid <= softreg_read;
		if (softreg_read) begin
			case (softreg_req[i].addr)
				32'h00: softreg_resp[i].data <= cntrl_addr[i];
				32'h08: softreg_resp[i].data <= data_addr[i];
				32'h10: softreg_resp[i].data <= host_send_addr[i];
				32'h18: softreg_resp[i].data <= {s_creds[i], s_data_creds[i]};
				32'h20: softreg_resp[i].data <= host_recv_addr[i];
				32'h28: softreg_resp[i].data <= host_meta_addr[i];
				32'h30: softreg_resp[i].data <= {r_meta_creds[i], r_creds[i]};
				32'h38: softreg_resp[i].data <= {meta_idx[i], recv_idx[i]};
				
				32'h40: softreg_resp[i].data <= {shf_q[i], shf_full[i], shf_empty[i]};
				32'h48: softreg_resp[i].data <= {saf_q[i], saf_full[i], saf_empty[i]};
				32'h50: softreg_resp[i].data <= {sqf_q[i], sqf_full[i], sqf_empty[i]};
				32'h58: softreg_resp[i].data <= {spf_q[i], spf_full[i], spf_empty[i]};
				32'h60: softreg_resp[i].data <= {rqf_q[i], rqf_full[i], rqf_empty[i]};
				32'h68: softreg_resp[i].data <= {rpf_q[i], rpf_full[i], rpf_empty[i]};
				
				32'h70: softreg_resp[i].data <= {rmf_q, rmf_full, rmf_empty};
				32'h78: softreg_resp[i].data <= {rdf_q[61:0], rdf_full, rdf_empty};
				32'h80: softreg_resp[i].data <= {wmf_q, wmf_full, wmf_empty};
				32'h88: softreg_resp[i].data <= {wdf_q, wdf_full, wdf_empty};
				32'h90: softreg_resp[i].data <= {pmf_q, pmf_full, pmf_empty};
				32'h98: softreg_resp[i].data <= {pmdf_q, pmdf_full, pmdf_empty};
				
				32'h100: softreg_resp[i].data <= {FIFO[i].SEND.idx, FIFO[i].SEND.len_done};
				32'h108: softreg_resp[i].data <= {CONV.len_done};
				32'h110: softreg_resp[i].data <= {WRITE.len, WRITE.tx_data, WRITE.tx_valid};
				32'h118: softreg_resp[i].data <= {READ.sel};
				32'h120: softreg_resp[i].data <= {TX.len, TX.tx_data, TX.tx_valid};
				32'h128: softreg_resp[i].data <= {rbf_q, rbf_full, rbf_empty};
				32'h130: softreg_resp[i].data <= {recv_done[i], send_done[i], rst_recv[i], add_meta_idx[i], use_s_creds[i], add_s_data_cred[i], rst_send[i], add_recv_idx[i], add_r_meta_creds[i], add_r_creds[i]};
				32'h138: softreg_resp[i].data <= {FIFO[i].recv_limit, FIFO[i].send_limit};
				
				32'h140: softreg_resp[i].data <= {axi_s.awaddr[48:0], axi_s.awlen, axi_s.awvalid, axi_s.awready};
				32'h148: softreg_resp[i].data <= {axi_s.wdata[60:0], axi_s.wlast, axi_s.wvalid, axi_s.wready};
				32'h150: softreg_resp[i].data <= {axi_m.awaddr[48:0], axi_m.awlen, axi_m.awvalid, axi_m.awready};
				32'h158: softreg_resp[i].data <= {axi_m.wdata[60:0], axi_m.wlast, axi_m.wvalid, axi_m.wready};
				32'h160: softreg_resp[i].data <= {pcie_m.awaddr[48:0], pcie_m.awlen, pcie_m.awvalid, pcie_m.awready};
				32'h168: softreg_resp[i].data <= {pcie_m.wstrb[7:0], pcie_m.wdata[52:0], pcie_m.wlast, pcie_m.wvalid, pcie_m.wready};
				32'h170: softreg_resp[i].data <= {pcie_m.araddr[48:0], pcie_m.arlen, pcie_m.arvalid, pcie_m.arready};
				32'h178: softreg_resp[i].data <= {pcie_m.rdata[60:0], pcie_m.rlast, pcie_m.rvalid, pcie_m.rready};
				32'h180: softreg_resp[i].data <= {pcie_m.bvalid, pcie_m.bready, axi_s.bvalid, axi_s.bready, axi_m.bvalid, axi_m.bready};
				
				32'h188: softreg_resp[i].data <= {gsqf_q, gsqf_full, gsqf_empty};
				32'h190: softreg_resp[i].data <= {grpf_q, grpf_full, grpf_empty};
				default: begin end
			endcase
		end
	end
end


endmodule
