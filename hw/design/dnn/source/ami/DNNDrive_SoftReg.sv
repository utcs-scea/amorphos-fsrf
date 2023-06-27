import ShellTypes::*;
import AMITypes::*;

`include "dw_params.vh"
`include "common.vh"

module dummy_dnn_ami(
  input  wire                                        clk,
  input  wire                                        reset,
  input  wire                                        start,
  output wire                                        done
);

    reg start_d;
    
    always@(posedge clk) begin
        if (reset) begin
            start_d <= 1'b0;
        end else begin
            if (start) begin
                start_d = 1'b1;
            end
        end
    end

    assign done = start_d;

endmodule

module DNNDrive_SoftReg #(
// ******************************************************************
// Parameters
// ******************************************************************
  parameter integer PU_TID_WIDTH      = 16,
  parameter integer AXI_TID_WIDTH     = 6,
  parameter integer NUM_PU            = `num_pu,
  parameter integer ADDR_W            = 32,
  parameter integer OP_WIDTH          = 16,
  parameter integer AXI_DATA_W        = 64,
  parameter integer NUM_PE            = `num_pe,
  parameter integer BASE_ADDR_W       = ADDR_W,
  parameter integer OFFSET_ADDR_W     = ADDR_W,
  parameter integer TX_SIZE_WIDTH     = 20,
  parameter integer RD_LOOP_W         = 32,
  parameter integer D_TYPE_W          = 2,
  parameter integer ROM_ADDR_W        = 3,
  parameter integer SERDES_COUNT_W    = 6,
  parameter integer PE_SEL_W          = `C_LOG_2(NUM_PE),
  parameter integer DATA_W            = NUM_PE * OP_WIDTH, // double check this
  parameter integer LAYER_PARAM_WIDTH  = 10,
  parameter integer USE_DUMMY          = 0
)
(
    // User clock and reset
    input                               clk,
    input                               rst, 
    
    // Simplified Memory interface
    output AMIRequest                   mem_reqs        [1:0],
    input                               mem_req_grants  [1:0],
    input AMIResponse                   mem_resps       [1:0],
    output logic                        mem_resp_grants [1:0],

    // Soft register interface
    input SoftRegReq                    softreg_req,
    output SoftRegResp                  softreg_resp
);
    localparam DNNDRIVE_SOFTREG_Type  = 0;
    localparam DNNDRIVE_SOFTREG_Depth = 4;
    
    // DNNWeaver signals
    AMIRequest mem_req [1:0];
    logic dnn_start;
    wire  dnn_done;
    
    logic dummy_l_inc;
    wire l_inc;
    
    generate
        if  (USE_DUMMY == 1) begin : dummy_dnn_gen
            dummy_dnn_ami
            dummy_inst
            (
                .clk                      ( clk                    ),
                .reset                    ( rst                    ),
                .start                    ( dnn_start              ),
                .done                     ( dnn_done               )
            );
            assign mem_req[0] = '{valid: 0, isWrite: 1'b0, addr: 64'b0, data: 512'b0, size: 64};
            assign mem_req[1] = '{valid: 0, isWrite: 1'b0, addr: 64'b0, data: 512'b0, size: 64};
            assign mem_resp_grants[0] = 1'b0;
            assign mem_resp_grants[1] = 1'b0;
            assign dummy_l_inc = 1'b0;
            assign l_inc = dummy_l_inc;
        end else begin : real_dnn_gen
          dnnweaver_ami_top #(
          // TODO: Double check all the parameters
          // INPUT PARAMETERS
            .NUM_PE                   ( NUM_PE                   ),
            .NUM_PU                   ( NUM_PU                   ),
            .ADDR_W                   ( ADDR_W                   ),
            .AXI_DATA_W               ( DATA_W                   ),
            .BASE_ADDR_W              ( BASE_ADDR_W              ),
            .OFFSET_ADDR_W            ( OFFSET_ADDR_W            ),
            .RD_LOOP_W                ( RD_LOOP_W                ),
            .TX_SIZE_WIDTH            ( TX_SIZE_WIDTH            ),
            .D_TYPE_W                 ( D_TYPE_W                 ),
            .ROM_ADDR_W               ( ROM_ADDR_W               )
          ) real_accelerator_top ( // PORTS
            .clk                      ( clk                    ),
            .reset                    ( rst                    ),
            .start                    ( dnn_start              ),
            .done                     ( dnn_done               ),

            // Memory signals
            .flush_buffer (1'b0), // TODO: Actually connect it
            .mem_req(mem_req),
            .mem_req_grant(mem_req_grants),
            .mem_resp(mem_resps),
            .mem_resp_grant(mem_resp_grants),
            .l_inc(l_inc)
          );
        end
    endgenerate

    // Information to read/write
    logic[47:0] start_addr;
    
    // Counter
    reg[63:0] cycles;
    
    // FSM registers
    reg[1:0] state;
    
    // Address logic
    always_comb begin
        mem_reqs[0] = mem_req[0];
        mem_reqs[0].addr = mem_req[0].addr + start_addr;
        
        mem_reqs[1] = mem_req[1];
        mem_reqs[1].addr = mem_req[1].addr + start_addr;
    end
    
    // Start logic
    assign dnn_start = (state == 1);
    
    // FSM logic
    always @(posedge clk) begin
        case (state)
            2'h0: begin
                if (softreg_req.valid && softreg_req.isWrite && softreg_req.addr == 'h0) begin
                    state <= 1;
                end
            end
            2'h1: begin
                state <= 2;
                cycles <= 0;
            end
            2'h2: begin
                cycles <= cycles + 1;
                if (dnn_done) begin
                    state <= 0;
                end
            end
        endcase
        
        if (softreg_req.valid && softreg_req.isWrite && softreg_req.addr == 'h0) begin
            start_addr <= softreg_req.data;
        end
        
        softreg_resp.valid <= softreg_req.valid && !softreg_req.isWrite;
        softreg_resp.data <= cycles;
        
        if (rst) state <= 0;
    end
    
endmodule
