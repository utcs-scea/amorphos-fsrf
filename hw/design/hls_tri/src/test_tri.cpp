#include <array>
#include <sys/mman.h>
#include <fcntl.h>
#include "triangle.h"

const uint64_t WORDS_PER =  sizeof(uint512_t)/sizeof(uint64_t);
const uint64_t WORDS_PER_OUT =  sizeof(uint512_t)/sizeof(uint256_t);
const uint64_t WORDS_PER_OUT_NICE =  sizeof(uint256_t)/sizeof(uint64_t);
const uint64_t MU = 0xffffffffffffffff;

typedef std::array<uint64_t, WORDS_PER> ARR_IN;
typedef std::array<uint256_t, WORDS_PER_OUT> ARR_OUT;
typedef std::array<uint64_t, WORDS_PER_OUT_NICE> ARR_OUT_NICE;

// zipf
//void triangle(ARR_IN *mem1, ARR_IN *mem2_w, ARR_IN *mem3_w, uint64_t len_in_big_words, ARR_OUT *outs_w);
int main() {

	size_t len = 40;
	size_t len_bytes = 40*sizeof(uint64_t);
	uint64_t mem[40] = {
			8,10,12,18,24,30,MU,MU,0,6,MU,MU,
			0,6,20,22,24,30,MU,MU,12,18,MU,MU,
			0,6,12,18,32,34,MU,MU,24,30,MU,MU,
			MU,MU,MU,MU
	};

/*
	size_t len_bytes = 32768;
	uint64_t *mem;
	int rcode = open("/home/centos/src/project_data/triangle/graphgen/graph.bin", O_RDONLY);
	if (rcode < 0) std::cout << "Error" << std::endl;
	mem = (uint64_t*)mmap(NULL, len_bytes, PROT_READ, MAP_SHARED, rcode, 0);
	if ((int64_t)mem == 0) std::cout << "Error 2" << std::endl;
*/
	uint512_t outs[5] = {0, 0, 0, 0, 0};


	//triangle(mem, mem, mem, len * 64 / 512, outs);

	Ret ret = triangle(mem, mem, mem, len_bytes / 64, outs);
	std::cout << ret.mem_reqs[0] << std::endl;
	std::cout << ret.mem_reqs[1] << std::endl;
	std::cout << ret.mem_reqs[2] << std::endl;
	std::cout << ret.mem_reqs_short[0] << std::endl;
	std::cout << ret.mem_reqs_short[1] << std::endl;
	std::cout << ret.mem_reqs_short[2] << std::endl;
	std::cout << ret.num_tris << std::endl;
	//for (uint64_t i = 0; i < len_bytes/sizeof(uint64_t); i++) {
	//	std::cout << mem[i] << ",";
	//}
	/*for (uint64_t i = 0; i < 2; i++) {
		uint512_t my_out = outs[i];
		uint256_t my_outs[2] = {my_out.range(511, 256), my_out.range(255, 0)};
		for (uint64_t ii = 0; ii < 2; ii++) {
			std::cout << i*2+ii << ": " << std::endl;
			for (int64_t j = 2; j >= 0; j--) {
				std::cout << my_outs[ii].range(63 + j*64, j*64) << std::endl;
			}
		}
	}*/

}
