#include "sha-256.hpp"

sha_t sha256_fpga(uint512 *mem, uint64 words) {
#pragma HLS INTERFACE m_axi num_write_outstanding=1 num_read_outstanding=8 max_write_burst_length=2 max_read_burst_length=64 latency=1 depth=64 port=mem
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
		uint512 data = mem[i];
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
