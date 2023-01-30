#include <stdint.h>
#include <ap_int.h>
#include <array>

typedef ap_uint<512> uint512_t;
typedef ap_uint<256> uint256_t;

const uint64_t WORDS_PER =  sizeof(uint512_t)/sizeof(uint64_t);

// zipf
void triangle(uint64_t *mem1, uint64_t *mem2, uint64_t *mem3, uint64_t len_in_big_words, uint256_t *outs) {
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem1 port=mem1
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem2 port=mem2
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem3 port=mem3

	typedef std::array<uint64_t, WORDS_PER> ARR;
	ARR* mem1_wide_arrs = (ARR*)(mem1);
	ARR* mem2_wide_arrs = (ARR*)(mem2);
	ARR* mem3_wide_arrs = (ARR*)(mem3);
	uint64_t cur_node = 0;
	uint64_t fin = 0;
	for (uint64_t i = 0; i < len_in_big_words; i++) {
		ARR mem1_wide = mem1_wide_arrs[i];
		for (uint64_t j = 0; j != WORDS_PER; j+=2) {
			uint64_t start_idx1 = mem1_wide[j];
			uint64_t words1 = mem1_wide[j+1];
			if (start_idx1 == -1 && words1 == -1) {
				cur_node++;
				continue;
			}
			if (start_idx1 < cur_node) continue;
			uint64_t bursts = (words1 / WORDS_PER) + (words1 % WORDS_PER != 0);
			uint64_t offset = start_idx1 % WORDS_PER;
			uint64_t index1 = start_idx1 / WORDS_PER;
			uint64_t cur_offset = offset;
			for (uint64_t b1 = index1; b1 < bursts + index1; b1++) {
				ARR mem2_wide = mem2_wide_arrs[b1];
				for (; cur_offset != WORDS_PER; cur_offset+=2) {
					uint64_t start_idx2 = mem2_wide[cur_offset];
					uint64_t end_idx2 = mem2_wide[cur_offset+1];
					if (start_idx2 < start_idx1) continue;
					for (uint64_t vertex3Addr = start_idx2; vertex3Addr < end_idx2; vertex3Addr+=2) {
						uint64_t start_idx3 = mem3[vertex3Addr];
						if (start_idx3 == cur_node) {
							// found
							uint256_t out = (uint256_t(cur_node) << 128) | (uint256_t(start_idx1) << 64) | uint256_t(start_idx2);
							outs[fin++] = out;
						}
					}
				}
				cur_offset = 0;
			}
		}
	}
}
