//
// Types used throughout the AMI memory system
//

`ifndef AMITYPES_SV_INCLUDED
`define AMITYPES_SV_INCLUDED

import UserParams::*;

package AMITypes;

parameter AMI_NUM_APPS     = UserParams::NUM_APPS;
parameter AMI_NUM_PORTS    = 2;

parameter AMI_APP_BITS     = (AMI_NUM_APPS  > 1 ? $clog2(AMI_NUM_APPS)  : 1);

parameter AMI_ADDR_WIDTH = 64;
parameter AMI_DATA_WDITH = 512 + 64;
parameter AMI_REQ_SIZE_WIDTH = 6; // enables 64 byte size

parameter USE_SOFT_FIFO = 1;

parameter BLOCK_BUFFER_REQ_IN_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);
parameter BLOCK_BUFFER_RESP_OUT_Q_DEPTH = (USE_SOFT_FIFO ? 3 : 9);

typedef struct packed
{
	logic                          valid;
	logic                          isWrite;
	logic [AMI_ADDR_WIDTH-1:0]     addr;
	logic [AMI_DATA_WDITH-1:0] 	   data;
	logic [AMI_REQ_SIZE_WIDTH-1:0] size;
} AMIRequest;

typedef struct packed {
	logic                          valid;
	logic [AMI_DATA_WDITH-1:0]     data;
	logic [AMI_REQ_SIZE_WIDTH-1:0] size;
} AMIResponse;

typedef struct packed {
	logic 		 valid;
	logic [31:0] addr;
	logic [19:0]  size;
} DNNMicroRdTag;

typedef struct packed {
	logic valid;
	logic isWrite;
	logic [31:0] addr;
	logic [19:0] size;
	logic [9:0]  pu_id;
} DNNWeaverMemReq;

endpackage
`endif
