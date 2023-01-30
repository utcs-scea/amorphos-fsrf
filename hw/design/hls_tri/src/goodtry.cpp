#include <stdint.h>
#include <ap_int.h>
#include <array>

typedef ap_uint<512> uint512_t;
typedef ap_uint<256> uint256_t;

const uint64_t WORDS_PER =  sizeof(uint512_t)/sizeof(uint64_t);
const uint64_t WORDS_PER_OUT =  sizeof(uint512_t)/sizeof(uint256_t);
const uint64_t MU = 0xffffffffffffffff;

typedef std::array<uint64_t, WORDS_PER> ARR_IN;
typedef std::array<uint256_t, WORDS_PER_OUT> ARR_OUT;

// zipf
void triangle(ARR_IN *mem1, ARR_IN *mem2_w, ARR_IN *mem3_w, uint64_t len_in_big_words, ARR_OUT *outs_w) {
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem1 port=mem1 depth=40
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem2 port=mem2_w depth=40
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem3 port=mem3_w depth=40
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 port=outs_w depth=5

	uint64_t *mem2 = (uint64_t*)mem2_w;
	uint64_t *mem3 = (uint64_t*)mem3_w;
	uint256_t *outs = (uint256_t*)outs_w;
	uint64_t cur_node = 0;
	uint64_t fin = 0;
	for (uint64_t i = 0; i != len_in_big_words; i++) {
		ARR_IN mem1_wide = mem1[i];
		for (uint64_t j = 0; j < WORDS_PER; j+=2) {
			uint64_t start_idx1 = mem1_wide[j];
			uint64_t end_idx1 = mem1_wide[j+1];
			if (start_idx1 == MU && end_idx1 == MU) {
				cur_node++;
				continue;
			}
			if (start_idx1 < cur_node) continue;
			for (uint64_t vertex2Addr = start_idx1; vertex2Addr != end_idx1; vertex2Addr+=2) {
				uint64_t start_idx2 = mem2[vertex2Addr];
				uint64_t end_idx2 = mem2[vertex2Addr+1];
				if (start_idx2 < start_idx1) continue;
				for (uint64_t vertex3Addr = start_idx2; vertex3Addr != end_idx2; vertex3Addr+=2) {
					uint64_t start_idx3 = mem3[vertex3Addr];
					if (start_idx3 == cur_node) {
						// found
						uint256_t out = (uint256_t(cur_node) << 128) | (uint256_t(start_idx1) << 64) | uint256_t(start_idx2);
						outs[fin++] = out;
					}
				}
			}
		}
	}
}
