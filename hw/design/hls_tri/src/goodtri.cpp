#include <stdint.h>
#include <ap_int.h>
#include <array>

typedef ap_uint<512> uint512_t;
typedef ap_uint<256> uint256_t;

const uint64_t WORDS_PER =  sizeof(uint512_t)/sizeof(uint64_t);
const uint64_t WORDS_PER_OUT =  sizeof(uint512_t)/sizeof(uint256_t);
const uint64_t WORDS_PER_OUT_NICE =  sizeof(uint256_t)/sizeof(uint64_t);
const uint64_t MU = 0xffffffffffffffff;

typedef std::array<uint64_t, WORDS_PER> ARR_IN;
typedef std::array<uint256_t, WORDS_PER_OUT> ARR_OUT;
typedef std::array<uint64_t, WORDS_PER_OUT_NICE> ARR_OUT_NICE;

// zipf
void triangle(ARR_IN *mem1, ARR_IN *mem2_w, ARR_IN *mem3_w, uint64_t len_in_big_words, ARR_OUT *outs_w);

int main() {
	uint64_t mem[40] = {
			8,10,12,18,24,30,MU,MU,0,6,MU,MU,
			0,6,20,22,24,30,MU,MU,12,18,MU,MU,
			0,6,12,18,32,34,MU,MU,24,30,MU,MU,
			MU,MU,MU,MU
	};
	uint256_t outs[5] = {0, 0, 0, 0, 0};

	triangle((ARR_IN*)mem, (ARR_IN*)mem, (ARR_IN*)mem, 40 * 64 / 512, (ARR_OUT*)outs);

	for (uint64_t i = 0; i < 2; i++) {
		uint256_t my_out = outs[i];
		std::cout << i << ": " << std::endl;
		for (int64_t j = 2; j >= 0; j--) {
			std::cout << my_out.range(63 + j*64, j*64) << std::endl;
		}
	}

}
