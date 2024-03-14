module axi_reg #(
    parameter EN_WR = 1,
    parameter EN_RD = 0,
    parameter FIFO_LD = 1,
    parameter META_FIFO_LD = 1
) (
	input clk,
	input rst_n,
	
	axi_bus_t.master axi_s,
	axi_bus_t.slave axi_m
);

generate if (EN_WR) begin
    // AW channel
    wire awf_wrreq;
    wire [90:0] awf_data;
    wire awf_full;
    wire [90:0] awf_q;
    wire awf_empty;
    wire awf_rdreq;
    
    HullFIFO #(
        .TYPE(META_FIFO_LD > 7 ? 3 : 0),
        .WIDTH(16+64+8+3),
        .LOG_DEPTH(META_FIFO_LD)
    ) aw_fifo (
        .clock(clk),
        .reset_n(rst_n),
        .wrreq(awf_wrreq),
        .data(awf_data),
        .full(awf_full),
        .q(awf_q),
        .empty(awf_empty),
        .rdreq(awf_rdreq)
    );
    
    assign axi_s.awready = !awf_full;
    assign awf_wrreq = axi_s.awvalid;
    assign awf_data = {axi_s.awid, axi_s.awaddr, axi_s.awlen, axi_s.awsize};
    
    assign axi_m.awvalid = !awf_empty;
    assign awf_rdreq = axi_m.awready;
    assign {axi_m.awid, axi_m.awaddr, axi_m.awlen, axi_m.awsize} = awf_q;
    
    
    // W channel
    wire wf_wrreq;
    wire [576:0] wf_data;
    wire wf_full;
    wire [576:0] wf_q;
    wire wf_empty;
    wire wf_rdreq;
    
    HullFIFO #(
        .TYPE((FIFO_LD > 7) ? 3 : 0),
        .WIDTH(512+64+1),
        .LOG_DEPTH(FIFO_LD)
    ) w_fifo (
        .clock(clk),
        .reset_n(rst_n),
        .wrreq(wf_wrreq),
        .data(wf_data),
        .full(wf_full),
        .q(wf_q),
        .empty(wf_empty),
        .rdreq(wf_rdreq)
    );
    
    assign axi_s.wready = !wf_full;
    assign wf_wrreq = axi_s.wvalid;
    assign wf_data = {axi_s.wdata, axi_s.wstrb, axi_s.wlast};
    
    assign axi_m.wvalid = !wf_empty;
    assign wf_rdreq = axi_m.wready;
    assign {axi_m.wdata, axi_m.wstrb, axi_m.wlast} = wf_q;
    
    
    // B channel
    wire bf_wrreq;
    wire [17:0] bf_data;
    wire bf_full;
    wire [17:0] bf_q;
    wire bf_empty;
    wire bf_rdreq;
    
    HullFIFO #(
        .TYPE(META_FIFO_LD > 7 ? 3 : 0),
        .WIDTH(16+2),
        .LOG_DEPTH(META_FIFO_LD)
    ) b_fifo (
        .clock(clk),
        .reset_n(rst_n),
        .wrreq(bf_wrreq),
        .data(bf_data),
        .full(bf_full),
        .q(bf_q),
        .empty(bf_empty),
        .rdreq(bf_rdreq)
    );
    
    assign axi_m.bready = !bf_full;
    assign bf_wrreq = axi_m.bvalid;
    assign bf_data = {axi_m.bid, axi_m.bresp};
    
    assign axi_s.bvalid = !bf_empty;
    assign bf_rdreq = axi_s.bready;
    assign {axi_s.bid, axi_s.bresp} = bf_q;
end endgenerate

generate if (EN_RD) begin
    // AR channel
    wire arf_wrreq;
    wire [90:0] arf_data;
    wire arf_full;
    wire [90:0] arf_q;
    wire arf_empty;
    wire arf_rdreq;
    
    HullFIFO #(
        .TYPE(META_FIFO_LD > 7 ? 3 : 0),
        .WIDTH(16+64+8+3),
        .LOG_DEPTH(META_FIFO_LD)
    ) ar_fifo (
        .clock(clk),
        .reset_n(rst_n),
        .wrreq(arf_wrreq),
        .data(arf_data),
        .full(arf_full),
        .q(arf_q),
        .empty(arf_empty),
        .rdreq(arf_rdreq)
    );
    
    assign axi_s.arready = !arf_full;
    assign arf_wrreq = axi_s.arvalid;
    assign arf_data = {axi_s.arid, axi_s.araddr, axi_s.arlen, axi_s.arsize};
    
    assign axi_m.arvalid = !arf_empty;
    assign arf_rdreq = axi_m.arready;
    assign {axi_m.arid, axi_m.araddr, axi_m.arlen, axi_m.arsize} = arf_q;
    
    
    // R channel
    wire rf_wrreq;
    wire [530:0] rf_data;
    wire rf_full;
    wire [530:0] rf_q;
    wire rf_empty;
    wire rf_rdreq;
    
    HullFIFO #(
        .TYPE(FIFO_LD > 7 ? 3 : 0),
        .WIDTH(16+512+2+1),
        .LOG_DEPTH(FIFO_LD)
    ) r_fifo (
        .clock(clk),
        .reset_n(rst_n),
        .wrreq(rf_wrreq),
        .data(rf_data),
        .full(rf_full),
        .q(rf_q),
        .empty(rf_empty),
        .rdreq(rf_rdreq)
    );
    
    assign axi_m.rready = !rf_full;
    assign rf_wrreq = axi_m.rvalid;
    assign rf_data = {axi_m.rid, axi_m.rdata, axi_m.rresp, axi_m.rlast};
    
    assign axi_s.rvalid = !rf_empty;
    assign rf_rdreq = axi_s.rready;
    assign {axi_s.rid, axi_s.rdata, axi_s.rresp, axi_s.rlast} = rf_q;
end endgenerate


endmodule
