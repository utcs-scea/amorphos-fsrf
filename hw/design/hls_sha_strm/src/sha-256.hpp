#include "ap_int.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"

typedef ap_uint<32> uint32;
typedef ap_uint<64> uint64;
typedef ap_uint<256> uint256;
typedef ap_uint<512> uint512;
typedef ap_uint<768> uint768;

typedef struct sha_t {
	uint32 a, b, c, d, e, f, g, h;
} sha_t;

typedef hls::axis<uint512, 0, 5, 5> axis512;

uint256 sha256_transform(uint256 rx_state, uint512 rx_input);
sha_t sha256_strm(hls::stream<axis512> &axis_in, hls::stream<axis512> &axis_out, uint64 words, uint64 dest);
