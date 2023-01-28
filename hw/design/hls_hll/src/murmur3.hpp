/**
 * Copyright (c) 2020, Systems Group, ETH Zurich
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "hyperloglog.hpp"

typedef ap_uint<128>	uint_128_t;
typedef ap_uint<64>		uint_64_t;
typedef ap_uint<32>		uint_32_t;
typedef ap_uint<8>		uint_8_t;
typedef ap_uint<1>		uint_1_t;

template <int DUMMY>
void murmur3(
		uint64_t N,
		hls::stream<dataItem<32>>&	dataFifo,
		hls::stream<dataItem<32>>&	hashFifo
) {
	#pragma HLS INLINE off

	const uint_32_t c1 = 0xcc9e2d51;
	const uint_32_t c2 = 0x1b873593;
	uint_32_t seed ;
	uint_32_t len;
	uint_32_t h1;
	uint_32_t k1_t;

	for (uint64_t i = 0; i < N; ++i) {
		#pragma HLS PIPELINE II=1

		dataItem<32> key = dataFifo.read();

		seed = 42;
		len = 4; //32-bit input (4 bytes)
		h1 = seed;

		// body
		k1_t =  key.data;
		k1_t *= c1;
		k1_t = (k1_t << 15) | (k1_t >> (32 - 15));
		k1_t *= c2;
		h1 ^= k1_t;
		h1 = (h1 << 13) | (h1 >> (32 - 13));
		h1 = h1*5+0xe6546b64;

		//finalization
		h1 ^= len;
		h1 ^= h1 >> 16;
		h1 *= 0x85ebca6b;
		h1 ^= h1 >> 13;
		h1 *= 0xc2b2ae35;
		h1 ^= h1 >> 16;

		hashFifo.write(dataItem<32>(h1, key.valid, key.last));
	}
} // murmur3<32>
