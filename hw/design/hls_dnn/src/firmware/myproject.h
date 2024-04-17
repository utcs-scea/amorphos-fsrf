#ifndef MYPROJECT_H_
#define MYPROJECT_H_

#include "ap_fixed.h"
#include "ap_int.h"
#include "hls_stream.h"
#include "ap_axi_sdata.h"

#include "defines.h"

typedef ap_uint<512> uint512;
typedef hls::axis<uint512, 0, 5, 5> axis512;
typedef ap_uint<64> uint64;

// Prototype of top level function for C-synthesis
/*
void myproject(
    input_t input_1[N_INPUT_1_1*N_INPUT_2_1*N_INPUT_3_1],
    result_t layer7_out[N_LAYER_7]
);
*/

void myproject(
		hls::stream<axis512> &axis_in,
		hls::stream<axis512> &axis_out,
		uint64 words,
		uint64 dest
);

#endif
