`include "conv_constants.v"
// hardcoded parameters - 1-byte color width, 3x3 kernel

module ConvPixel
#(parameter DEBUG = 0) (
    // Clock
    input wire clk,
    input wire rst,
    //input wire valid, // moved to convgrid

    // pixel inputs
    input wire [71:0] localPixels_mem,

    // kernel
    //input wire [71:0] kernel_in,
    //input wire [7:0] krnl_shift_in,

    input wire ready_out,
    // output
    output reg [7:0] o_color
    //output reg valid_out // moved to convgrid
);

    // stage 0 - store
    reg [71:0] pixels0;
    //reg [71:0] kernel0;
    //reg [7:0] krnl_shift0;
    reg [71:0] pixels;
    //reg [71:0] kernel;
    //reg [7:0] krnl_shift;
    //reg valid_0;
    always @(posedge clk) begin
        //if (rst) begin
            //valid_0 <= 0;
        //end else
        //if (ready_out) begin
            //valid_0 <= valid;
            pixels0 <= localPixels_mem;
            pixels <= pixels0;
            //kernel0 <= kernel_in;
            //kernel <= kernel0;
            //krnl_shift0 <= krnl_shift_in;
            //krnl_shift <= krnl_shift0;
            if (DEBUG) begin
                //$display("%h", localPixels_mem);
            end
        //end
    end


    // stage 1 - multiply
    reg signed [8:0]pixel_dumb[8:0];
    reg signed [8:0]pixel_dumb2[8:0];
    //reg signed [7:0]krnl_pix_dumb[8:0];
    //reg signed [7:0]krnl_pix_dumb2[8:0];

    genvar pix_15_;
    for (pix_15_ = 0; pix_15_ < 9; pix_15_ = pix_15_ + 1) begin
        always @(posedge clk) begin
            pixel_dumb[pix_15_] <= {1'b0, pixels[pix_15_*8 +: 8]};
            //krnl_pix_dumb[pix_15_] <= kernel[pix_15_*8 +: 8];
            pixel_dumb2[pix_15_] <= pixel_dumb[pix_15_];
            //krnl_pix_dumb2[pix_15_] <= krnl_pix_dumb[pix_15_];
        end
    end

    reg signed [15:0]mult_short_dumb1[8:0];
    reg signed [15:0]mult_short_dumb2[8:0];
    reg signed [19:0]mult_dumb1[8:0];

    //wire signed [19:0] mult_ [8:0];
    reg signed [19:0] mult [8:0];
    //reg valid_1;
    //
    wire [71:0]kernel_raw = `IMAGE_KERNEL;
    wire [7:0] krnl_shift = `IMAGE_KERNEL_SHIFT;
    wire signed [7:0]kernel[8:0];
    genvar krnl_i;
    for (krnl_i = 0; krnl_i < 9; krnl_i = krnl_i + 1) begin: KRNL_I
        assign kernel[krnl_i] = kernel_raw[8*krnl_i +: 8];
    end

    genvar pix_1;
    for (pix_1 = 0; pix_1 < 9; pix_1 = pix_1 + 1) begin: PIXEL_1
        //wire signed [8:0] pixel = pixel_dumb2[pix_1];
        //wire signed [7:0] krnl_pix = krnl_pix_dumb2[pix_1];
        //wire signed [15:0] mult_short = pixel * krnl_pix;
        always @(posedge clk) begin
            //mult_short_dumb1[pix_1] <= pixel_dumb2[pix_1] * krnl_pix_dumb2[pix_1];
            mult_short_dumb1[pix_1] <= pixel_dumb2[pix_1] * kernel[pix_1];
            mult_short_dumb2[pix_1] <= mult_short_dumb1[pix_1];
            mult_dumb1[pix_1] <= { {(4){mult_short_dumb2[pix_1][15]}}, mult_short_dumb2[pix_1][15:0]};
            mult[pix_1] <= mult_dumb1[pix_1];
        end
        
        //assign mult_[pix_1] = { {(4){mult_short[15]}}, mult_short[15:0]};
        
    end
    always @(posedge clk) begin
        /*if (rst) begin
            valid_1 <= 0;
        end else 
        if (ready_out) begin
            valid_1 <= valid_0;
        end*/

    end

    /*genvar pix_1_;
    for (pix_1_ = 0; pix_1_ < 9; pix_1_ = pix_1_ + 1) begin
        always @(posedge clk) mult[pix_1_] <= mult_[pix_1_];
    end*/


    // stage 2 - accumulate

    reg signed [19:0] basicSums [10:0];
    wire signed [19:0] sum;
    //reg signed [19:0] basicSums [5:3];
    //reg valid_2;

    always @(posedge clk) begin

        //if (ready_out) begin
            basicSums[0] <= mult[0] + mult[1];
            basicSums[1] <= mult[2] + mult[3];
            basicSums[2] <= mult[4] + mult[5];
            basicSums[3] <= mult[6] + mult[7];
            basicSums[4] <= mult[8];

            basicSums[5] <= basicSums[0] + basicSums[1];
            basicSums[6] <= basicSums[2] + basicSums[3];
            basicSums[7] <= basicSums[4];

            basicSums[8] <= basicSums[5] + basicSums[6];
            basicSums[9] <= basicSums[7];

            basicSums[10] <= basicSums[8] + basicSums[9];
        //end
    end
    assign sum = basicSums[10];

    //genvar pix_2_;
    //for (pix_2_ = 3; pix_2_ <= 5; pix_2_ = pix_2_ + 1) begin
        //always @(posedge clk) if (ready_out) basicSums[pix_2_] <= basicSums_[pix_2_];
    //end


    // stage 3 - shift

    reg signed [19:0] result_div;
    reg [7:0] result;
    // Register output score
    always @(posedge clk) begin
        //if (rst) begin
            //o_color <= 0;
            //valid_out <= 0;
        //end else 
        //if (ready_out) begin
            result_div <= sum >>> krnl_shift;
            result <= ((result_div[19]) ? 0 :
                                |result_div[19:8] ? {(8){1'b1}} : 
                                result_div[7:0]);

            o_color <= result;
        //end
    end
endmodule

module ConvGrid #(
    parameter TRANS_SIZE = 512
) (
	// Clock and reset
	input wire clk,
	input wire rst,
	
	// Inputs
	input wire valid_in,
	input wire [TRANS_SIZE-1:0] image, // we get in 64 bytes per cycle
	//input wire [71:0] kernel,
    //input wire [7:0] krnl_shift,
    input wire krnl_loaded,
	
    input wire ready_out,
	// Outputs
	output wire valid_out,
	output wire [TRANS_SIZE-1:0] image_out,
    input wire done,
	// Image size, MUST be a multiple of (TRANS_SIZE_B)
    input wire [$clog2(`I_SIZE_MAX)+1:0] vI_SIZE
);
    localparam TRANS_SIZE_B = TRANS_SIZE/8;
    //localparam BUFSIZ = 2*vI_SIZE + 3*TRANS_SIZE_B;
    //localparam IND = $clog2(BUFSIZ);
    localparam FIFO_SIZE = `I_SIZE_MAX / TRANS_SIZE_B - 3;
    //reg [7:0] mem [BUFSIZ-1:0];
    localparam LIVEZONE_SIZE = 3*TRANS_SIZE_B;
    wire[31:0] vEOF = vI_SIZE*(vI_SIZE/TRANS_SIZE_B);
    wire[31:0] vEOW = (vI_SIZE + 1) * (vI_SIZE/TRANS_SIZE_B) + 1;
    reg [7:0] top_live [LIVEZONE_SIZE-1:0];
    reg [7:0] mid_live [LIVEZONE_SIZE-1:0];
    reg [7:0] btm_live [LIVEZONE_SIZE-1:0];
    reg [$clog2(`I_SIZE_MAX+10)-1:0] readRow;
    reg [$clog2(`I_SIZE_MAX+10)-1:0] rowsDone;
    //reg [$clog2(vEOW + 10):0] cycles; // +10 is just for safety
    reg [31:0] cycles;

    wire live_next = cycles+1 > ((vI_SIZE/TRANS_SIZE_B) + 1);
    wire momentum_next = cycles+1 >= vEOF;
    wire notPast_next = cycles+1 <= vEOW;

    reg live;
    reg momentum;
    reg notPast;

    wire stalling = !(ready_out && (valid_in || momentum));

    reg bmwr;
    reg bmrr;
    reg mtwr;
    reg mtrr;

    wire btm_mid_wrreq = !stalling && bmwr;
    wire [TRANS_SIZE-1:0] btm_mid_data;
    wire btm_mid_full;
    wire btm_mid_rdreq = !stalling && bmrr;
    wire [TRANS_SIZE-1:0] btm_mid_q;
    wire btm_mid_empty;

    wire mid_top_wrreq = !stalling && mtwr;
    wire [TRANS_SIZE-1:0] mid_top_data;
    wire mid_top_full;
    wire mid_top_rdreq = !stalling && mtrr;
    wire [TRANS_SIZE-1:0] mid_top_q;
    wire mid_top_empty;
    
    wire bmwr_n = (1+cycles >= 3) && (1+cycles < 3 + vEOF);
    wire bmrr_n = (1+cycles >= 3 + FIFO_SIZE) && (1+cycles < 3 + FIFO_SIZE + vEOF);
    wire mtwr_n = (1+cycles >= 6 + FIFO_SIZE) && (1+cycles < 6 + FIFO_SIZE + vEOF);
    wire mtrr_n = (1+cycles >= 6 + 2*FIFO_SIZE) && (1+cycles < 6 + 2*FIFO_SIZE + vEOF) || (1+cycles < 6 + FIFO_SIZE && !mid_top_empty);

    genvar bmg;
    for (bmg = 0; bmg < TRANS_SIZE_B; bmg = bmg + 1) begin
        assign btm_mid_data[bmg*8+:8] = btm_live[bmg];
        assign mid_top_data[bmg*8+:8] = mid_live[bmg];
    end

    integer ii, jk, mtg;
    always @(posedge clk) begin
        if (rst) begin
            readRow <= 0;
            rowsDone <= 0;
            cycles <= 0;
            live <= 0;
            momentum <= 0;
            notPast <= 1;
            bmwr <= 0;
            bmrr <= 0;
            mtwr <= 0;
            mtrr <= 0;
        end else if (done) begin
            readRow <= 0;
            rowsDone <= 0;
            cycles <= 0;
            live <= 0;
            momentum <= 0;
            notPast <= 1;
            bmwr <= 0;
            bmrr <= 0;
            mtwr <= 0;
            mtrr <= 0;
        end else begin
            if (ready_out && valid_in) begin
                for (ii = 0; ii < TRANS_SIZE_B; ii = ii + 1) begin
                    btm_live[(LIVEZONE_SIZE - TRANS_SIZE_B) + ii] <= image[ii*8+:8];
                end
            end
            if (!stalling) begin // when we've loaded all memory, we don't need to rely on valid_in
                cycles <= cycles + 1;
                live <= live_next;
                momentum <= momentum_next;
                notPast <= notPast_next;
                bmwr <= bmwr_n;
                bmrr <= bmrr_n;
                mtwr <= mtwr_n;
                mtrr <= mtrr_n;
`ifdef SIMUL
		//$display("on cycle %d size %d %d rd=%d %d wr=%d %d (%d)", cycles, btm_mid.size, mid_top.size, btm_mid_rdreq, mid_top_rdreq, btm_mid_wrreq, mid_top_wrreq, goodInput);
		//$display(" we have %d %d %d %d/%d/%d/%d %d %d %d %d/%d/%d/%d %d %d %d", btm_live[2*TRANS_SIZE_B], btm_live[TRANS_SIZE_B], btm_live[0], btm_mid.mem[0][0+:8], btm_mid.mem[1][0+:8],btm_mid.mem[2][0+:8],  btm_mid.mem[3][0+:8], mid_live[2*TRANS_SIZE_B], mid_live[TRANS_SIZE_B], mid_live[0], mid_top.mem[0][0+:8], mid_top.mem[1][0+:8],mid_top.mem[2][0+:8],  mid_top.mem[3][0+:8], top_live[2*TRANS_SIZE_B], top_live[TRANS_SIZE_B], top_live[0]);
`endif
                for (jk = 0; jk < LIVEZONE_SIZE - TRANS_SIZE_B; jk = jk + 1) begin
                    btm_live[jk] <= btm_live[jk + TRANS_SIZE_B];
                    mid_live[jk] <= mid_live[jk + TRANS_SIZE_B];
                    top_live[jk] <= top_live[jk + TRANS_SIZE_B];
                end
                for (mtg = 0; mtg < TRANS_SIZE_B; mtg = mtg + 1) begin
                    mid_live[(LIVEZONE_SIZE - TRANS_SIZE_B) + mtg] <= btm_mid_q[mtg*8+:8];
                    top_live[(LIVEZONE_SIZE - TRANS_SIZE_B) + mtg] <= mid_top_q[mtg*8+:8];
                end
                if (live) begin
                    readRow <= readRow == vI_SIZE-TRANS_SIZE_B ? 0 : readRow + TRANS_SIZE_B;
                    rowsDone <= rowsDone + (readRow == vI_SIZE-TRANS_SIZE_B ? 1 : 0);
                end
            end
        end
    end

HullFIFO #(
    .TYPE(3),
    .WIDTH(TRANS_SIZE),
    .LOG_DEPTH($clog2(FIFO_SIZE+1))
) btm_mid (
    .clock(clk),
    .reset_n(!rst),
    .wrreq(btm_mid_wrreq),
    .data(btm_mid_data),
    .full(btm_mid_full),
    .rdreq(btm_mid_rdreq),
    .q(btm_mid_q),
    .empty(btm_mid_empty)
);

HullFIFO #(
    .TYPE(3),
    .WIDTH(TRANS_SIZE),
    .LOG_DEPTH($clog2(FIFO_SIZE+1))
) mid_top (
    .clock(clk),
    .reset_n(!rst),
    .wrreq(mid_top_wrreq),
    .data(mid_top_data),
    .full(mid_top_full),
    .rdreq(mid_top_rdreq),
    .q(mid_top_q),
    .empty(mid_top_empty)
);

    wire goodInput = !stalling && live && notPast;
    wire topIsEdge = rowsDone == 0;
    wire bottomIsEdge = rowsDone == vI_SIZE - 1;
    wire leftIsEdge = readRow == 0;
    wire rightIsEdge = readRow == vI_SIZE-TRANS_SIZE_B;
    genvar pix, i;
    for (pix = 0; pix < TRANS_SIZE_B; pix = pix + 1) begin: PIXELS

        wire myLeftIsEdge = leftIsEdge && pix == 0;
        wire myRightIsEdge = rightIsEdge && pix == TRANS_SIZE_B-1;
        wire [7:0]localPixels[8:0];
        wire [71:0]localPixels_mem;

        //localparam myReadI = vI_SIZE + TRANS_SIZE_B + pix;
        //localparam topMemAddr = myReadI - vI_SIZE;
        //localparam bottomMemAddr = myReadI + vI_SIZE;
        localparam myReadI = TRANS_SIZE_B + pix;
        localparam topMemAddr = myReadI;
        localparam bottomMemAddr = myReadI;

        wire [8:0]valids;

        assign valids[0] = !(myLeftIsEdge || topIsEdge);
        assign valids[1] = !topIsEdge;
        assign valids[2] = !(myRightIsEdge || topIsEdge);
        assign valids[3] = !myLeftIsEdge;
        assign valids[4] = 1;
        assign valids[5] = !myRightIsEdge;
        assign valids[6] = !(myLeftIsEdge || bottomIsEdge);
        assign valids[7] = !bottomIsEdge;
        assign valids[8] = !(myRightIsEdge || bottomIsEdge);

        assign localPixels[0] = valids[0] ? top_live[topMemAddr    - 1] : 0;
        assign localPixels[1] = valids[1] ? top_live[topMemAddr       ] : 0;
        assign localPixels[2] = valids[2] ? top_live[topMemAddr    + 1] : 0;
        assign localPixels[3] = valids[3] ? mid_live[myReadI       - 1] : 0;
        assign localPixels[4] = valids[4] ? mid_live[myReadI          ] : 0;
        assign localPixels[5] = valids[5] ? mid_live[myReadI       + 1] : 0;
        assign localPixels[6] = valids[6] ? btm_live[bottomMemAddr - 1] : 0;
        assign localPixels[7] = valids[7] ? btm_live[bottomMemAddr    ] : 0;
        assign localPixels[8] = valids[8] ? btm_live[bottomMemAddr + 1] : 0;

        for (i = 0; i < 9; i = i + 1) begin
            assign localPixels_mem[8*i +: 8] = localPixels[i];
        end

        //ConvPixel #(.DEBUG(pix == (0))) pixel (
        ConvPixel #(.DEBUG(0)) pixel (
            .clk(clk),
            .rst(rst),
            //.valid(goodInput),
            .localPixels_mem(localPixels_mem),
            //.kernel_in(kernel),
            //.krnl_shift_in(krnl_shift),
            .ready_out(ready_out),
            .o_color(image_out[pix*8 +: 8])
            //.valid_out(valid_out_all[pix])
        );
    end

    // pixel stage bookkeeping
    reg [`PIPELINE_SIZE - 1:0] validP;
    integer ppp;
    always @(posedge clk) begin
        if (rst) begin
            validP <= 0;
        end else /*if (ready_out)*/ begin
            validP[0] <= goodInput;
	    for (ppp = 1; ppp < `PIPELINE_SIZE; ppp = ppp + 1) begin
		validP[ppp] <= validP[ppp - 1];
	    end
        end
    end
/*
    genvar ppp;
    for (ppp = 1; ppp < `PIPELINE_SIZE; ppp = ppp + 1) begin
        always @(posedge clk) / *if (ready_out)* / validP[ppp] <= validP[ppp - 1];
    end
*/

    assign valid_out = validP[`PIPELINE_SIZE - 1];// && ready_out;

    always @(posedge clk) begin
        //$display("mem[0] and mem[1] are %h %h", mem[0], mem[1]);
        /*
        $write("mem: ");
        for (jk = 0; jk < BUFSIZ; jk = jk + 1) begin
            $write("%h",mem[jk]);
        end
        $display("");
        $display("cycles: %d", cycles);
        $display("writeI: %d", writeI);
        $display("readI: %d", readI);
        $display("readRow: %d", readRow);
        $display("rowsDone: %d", rowsDone);
        $display(" good?: %h", PIXELS[0].goodInput);
        $display(" 0: %h", PIXELS[0].localPixels_mem);
        $display(" 7: %h", PIXELS[7].localPixels_mem);
        */
        //$display(" in is %d", PIXELS[0].goodInput);
        //$display(" out0 is %d", valid_out_all[0]);
    end


endmodule
