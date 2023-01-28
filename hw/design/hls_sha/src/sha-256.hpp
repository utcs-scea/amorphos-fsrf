#include "ap_int.h"

typedef ap_uint<32> uint32;
typedef ap_uint<64> uint64;
typedef ap_uint<256> uint256;
typedef ap_uint<512> uint512;
typedef ap_uint<768> uint768;

typedef struct sha_t {
	uint32 a, b, c, d, e, f, g, h;
} sha_t;

uint256 sha256_transform(uint256 rx_state, uint512 rx_input);
sha_t sha256_fpga(uint512 *mem, uint64 words);
