#include <iostream>
#include "sha-256.hpp"

uint32 e0(uint32 x) {
	uint32 temp0 = (x(1,0), x(31,2));
	uint32 temp1 = (x(12,0), x(31,13));
	uint32 temp2 = (x(21,0), x(31,22));
	
	return temp0 ^ temp1 ^ temp2;
}

uint32 e1(uint32 x) {
	uint32 temp0 = (x(5,0), x(31,6));
	uint32 temp1 = (x(10,0), x(31,11));
	uint32 temp2 = (x(24,0), x(31,25));
	
	return temp0 ^ temp1 ^ temp2;
}

uint32 ch(uint32 x, uint32 y, uint32 z) {
	return z ^ (x & (y ^ z));
}

uint32 maj(uint32 x, uint32 y, uint32 z) {
	return (x & y) | (z & (x | y));
	//return (y & z) | (x & (y | z));  // why not this?
}

uint32 s0(uint32 x) {
	typedef ap_uint<3> uint3;
	typedef ap_uint<29> uint29;
	
	uint3 temp0 = x(6,4) ^ x(17,15);
	uint29 temp1 = (x(3,0), x(31,7));
	uint29 temp2 = (x(14,0), x(31,18));
	uint29 temp3 = x(31,3);
	uint29 temp4 = temp1 ^ temp2 ^ temp3;
	
	return (temp0, temp4);
}

uint32 s1(uint32 x) {
	typedef ap_uint<10> uint10;
	typedef ap_uint<22> uint22;
	
	uint10 temp0 = x(16,7) ^ x(18,9);
	uint22 temp1 = (x(6,0), x(31,17));
	uint22 temp2 = (x(8,0), x(31,19));
	uint22 temp3 = x(31,10);
	uint22 temp4 = temp1 ^ temp2 ^ temp3;
	
	return (temp0, temp4);
}

uint768 sha256_digester(uint32 k, uint256 rx_state, uint512 rx_w) {
	
	uint32 e0_w, e1_w, ch_w, maj_w, s0_w, s1_w;
	e0_w = e0(rx_state(31,0));
	e1_w = e1(rx_state(159,128));
	ch_w = ch(rx_state(159,128), rx_state(191,160), rx_state(223,192));
	maj_w = maj(rx_state(31,0), rx_state(63,32), rx_state(95,64));
	s0_w = s0(rx_w(63,32));
	s1_w = s1(rx_w(479,448));
	
	uint32 t1, t2, new_w;
	t1 = uint32(rx_state(255,224)) + e1_w + ch_w + uint32(rx_w(31,0)) + k;
	t2 = e0_w + maj_w;
	new_w = s1_w + uint32(rx_w(319,288)) + s0_w + uint32(rx_w(31,0));
	
	uint512 tx_w;
	tx_w(511,480) = new_w;
	tx_w(479,0) = rx_w(511,32);
	
	uint256 tx_state;
	tx_state(255,224) = rx_state(223,192);
	tx_state(223,192) = rx_state(191,160);
	tx_state(191,160) = rx_state(159,128);
	tx_state(159,128) = rx_state(127,96) + t1;
	tx_state(127,96) = rx_state(95,64);
	tx_state(95,64) = rx_state(63,32);
	tx_state(63,32) = rx_state(31,0);
	tx_state(31,0) = t1 + t2;
	
	return (tx_state, tx_w);
}

uint32 Ks[64] = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

uint256 sha256_transform(uint256 rx_state, uint512 rx_input) {
	uint256 state = rx_state;
	uint512 W = rx_input;
	
	for (int i = 0; i < 64; ++i) {
#pragma HLS UNROLL
		uint32 k = Ks[i];
		(state, W) = sha256_digester(k, state, W);
	}
	
	uint256 tx_hash;
	tx_hash(31,0) = uint32(rx_state(31,0)) + uint32(state(31,0));
	tx_hash(63,32) = uint32(rx_state(63,32)) + uint32(state(63,32));
	tx_hash(95,64) = uint32(rx_state(95,64)) + uint32(state(95,64));
	tx_hash(127,96) = uint32(rx_state(127,96)) + uint32(state(127,96));
	tx_hash(159,128) = uint32(rx_state(159,128)) + uint32(state(159,128));
	tx_hash(191,160) = uint32(rx_state(191,160)) + uint32(state(191,160));
	tx_hash(223,192) = uint32(rx_state(223,192)) + uint32(state(223,192));
	tx_hash(255,224) = uint32(rx_state(255,224)) + uint32(state(255,224));
	
	return tx_hash;
}
