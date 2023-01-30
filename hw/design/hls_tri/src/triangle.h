#pragma once

#include <stdint.h>
#include <ap_int.h>

typedef ap_uint<512> uint512_t;
typedef ap_uint<256> uint256_t;

struct Ret {
	uint64_t mem_reqs[3];
	uint64_t mem_reqs_short[3];
	uint64_t num_tris;
};

Ret triangle(uint64_t *mem1, uint64_t *mem2, uint64_t *mem3, uint64_t len_in_big_words, uint512_t *outs);
