#include "sha-256.hpp"

sha_t sha256_strm(hls::stream<axis512> &axis_in, hls::stream<axis512> &axis_out, uint64 words, uint64 dest) {
#pragma HLS INTERFACE s_axilite register port=return
#pragma HLS INTERFACE axis register_mode=both register port=axis_in
#pragma HLS INTERFACE axis register_mode=both register port=axis_out
#pragma HLS INTERFACE s_axilite register port=words
#pragma HLS INTERFACE s_axilite register port=dest
	const uint256 state("5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667", 16);
	
	sha_t vars;
	
	vars.a = 0;
	vars.b = 0;
	vars.c = 0;
	vars.d = 0;
	vars.e = 0;
	vars.f = 0;
	vars.g = 0;
	vars.h = 0;
	
	for (uint64 i = 0; i < words; ++i) {
#pragma HLS PIPELINE II=1
		axis512 word = axis_in.read();
		uint512 data = word.data;
		word.dest = dest;
		word.keep = -1;
		word.strb = -1;
		axis_out.write(word);

		uint256 hash = sha256_transform(state, data);
		vars.a += uint32(hash(31,0));
		vars.b += uint32(hash(63,32));
		vars.c += uint32(hash(95,64));
		vars.d += uint32(hash(127,96));
		vars.e += uint32(hash(159,128));
		vars.f += uint32(hash(191,160));
		vars.g += uint32(hash(223,192));
		vars.h += uint32(hash(255,224));
	}
	
	return vars;
}
