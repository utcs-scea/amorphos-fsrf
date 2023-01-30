`ifndef CONV_CONSTANTS_V
`define CONV_CONSTANTS_V

`ifndef SIMUL
`define SIMUL 0
`endif

`define I_SIZE_MAX (131072)
//`define IMAGE_SIZE (128)
`define PIPELINE_SIZE (15)
`define IMAGE_KERNEL (72'h01_02_01_02_04_02_01_02_01)
`define IMAGE_KERNEL_SHIFT (4)
/*module consts();
    parameter IMAGE_SIZE = 128;
endmodule*/

`endif
