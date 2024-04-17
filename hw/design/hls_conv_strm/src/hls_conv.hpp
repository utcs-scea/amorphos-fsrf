#ifndef HLS_CONV_HPP
#define HLS_CONV_HPP

#include "ap_int.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"

typedef ap_uint<32> uint32;
typedef ap_uint<64> uint64;
typedef ap_uint<256> uint256;
typedef ap_uint<512> uint512;
typedef ap_uint<768> uint768;

typedef hls::axis<uint512, 0, 5, 5> axis512;

#endif // HLS_CONV_HPP
