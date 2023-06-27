//
// Academic Shell Types
//
`ifndef SHELLTYPES_SV_INCLUDED
`define SHELLTYPES_SV_INCLUDED

package ShellTypes;

typedef struct packed {
	logic                       valid;
	logic                       isWrite;
	logic [31:0]                addr;
	logic [63:0]                data;
} SoftRegReq;

typedef struct packed {
	logic                       valid;
	logic [63:0]                data;
} SoftRegResp;

endpackage
`endif