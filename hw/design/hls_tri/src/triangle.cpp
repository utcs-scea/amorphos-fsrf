#include <array>
//#include <stdio.h>
#include "triangle.h"

const uint64_t WORDS_PER =  sizeof(uint512_t)/sizeof(uint64_t);

// zipf
Ret triangle(uint64_t *mem1, uint64_t *mem2, uint64_t *mem3, uint64_t len_in_big_words, uint512_t *outs) {
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem1 port=mem1 depth=(40*8/8)
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem2 port=mem2 depth=(40*8/8)
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 bundle=mem3 port=mem3 depth=(40*8/8)
#pragma HLS INTERFACE m_axi max_widen_bitwidth=512 port=outs depth=5

	typedef std::array<uint64_t, WORDS_PER> ARR;
	ARR* mem1_wide_arrs = (ARR*)(mem1);
	ARR* mem2_wide_arrs = (ARR*)(mem2);
	ARR* mem3_wide_arrs = (ARR*)(mem3);
	uint64_t cur_node = 0;
	uint64_t fin = 0;
	Ret ret = {0,0,0,0,0,0,0};
	for (uint64_t i = 0; i < len_in_big_words; i++) {
		ARR mem1_wide = mem1_wide_arrs[i];
		ret.mem_reqs[0]++;
		for (uint64_t j = 0; j != WORDS_PER; j+=2) {
			uint64_t start_idx1 = mem1_wide[j];
			uint64_t end_idx1 = mem1_wide[j+1];
			ret.mem_reqs_short[0]+=2;
			if (start_idx1 == -1) {
				cur_node = 2 + i * WORDS_PER + j;
				continue;
			}
			if (start_idx1 < cur_node) continue;
			uint64_t start_word1 = start_idx1 / WORDS_PER;
			uint64_t end_word1 = (end_idx1-1) / WORDS_PER;
			uint64_t start_offset1 = start_idx1 % WORDS_PER;
			uint64_t end_offset1 = (end_idx1-1) % WORDS_PER;
			for (uint64_t b1 = start_word1; b1 <= end_word1; b1++) {
				ARR mem2_wide = mem2_wide_arrs[b1];
				ret.mem_reqs[1]++;
				uint64_t start1 = (b1 == start_word1 ? start_offset1 : 0);
				uint64_t end1 = (b1 == end_word1 ? (end_offset1+1) : WORDS_PER);
				for (uint64_t cur_offset = start1; cur_offset != end1; cur_offset+=2) {
					//if (b1 == start_word1 && cur_offset < start_offset) continue;
					uint64_t start_idx2 = mem2_wide[cur_offset];
					uint64_t end_idx2 = mem2_wide[cur_offset+1];
					ret.mem_reqs_short[1]+=2;
					if (start_idx2 < start_idx1) continue;
					uint64_t start_word2 = start_idx2 / WORDS_PER;
					uint64_t end_word2 = (end_idx2-1) / WORDS_PER;
					uint64_t start_offset2 = start_idx2 % WORDS_PER;
					uint64_t end_offset2 = (end_idx2-1) % WORDS_PER;
					bool foundtri = false;
					for (uint64_t b2 = start_word2; b2 <= end_word2; b2++) {
#pragma HLS PIPELINE
						ARR mem3_wide = mem3_wide_arrs[b2];
						ret.mem_reqs[2]++;
						uint64_t start2 = (b2 == start_word2 ? start_offset2 : 0);
						uint64_t end2 = (b2 == end_word2 ? (end_offset2+1) : WORDS_PER);
						ret.mem_reqs_short[2]+=((end2-start2) >> 1);
						for (uint64_t cur_offset2_off = 0; cur_offset2_off < WORDS_PER; cur_offset2_off+=2) {
#pragma HLS UNROLL
							if (cur_offset2_off >= start2 && cur_offset2_off < end2) {
								uint64_t start_idx3 = mem3_wide[cur_offset2_off];
								if (start_idx3 == cur_node) {
									foundtri = true;
								}
							}
						}
					}
					if (foundtri) {
						ret.num_tris++;
					}
				}
			}
		}
	}
	return ret;
}
