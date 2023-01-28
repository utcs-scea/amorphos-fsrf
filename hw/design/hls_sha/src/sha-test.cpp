#include "sha-256.hpp"

int main() {
	uint64_t mem[512];

	for (uint64_t i = 0; i < 512; ++i) {
		//mem[i] = i;
		mem[i] = 0;
		if (i == 6) mem[i] = 1;
		if (i == 7) mem[i] = 384;
	}
	//std::cout << *((uint512*)mem) << std::endl;
	
	sha_t vars = sha256_fpga((uint512*)mem, 1);

	std::cout << std::hex << vars.a << std::endl;
	std::cout << std::hex << vars.b << std::endl;
	std::cout << std::hex << vars.c << std::endl;
	std::cout << std::hex << vars.d << std::endl;
	std::cout << std::hex << vars.e << std::endl;
	std::cout << std::hex << vars.f << std::endl;
	std::cout << std::hex << vars.g << std::endl;
	std::cout << std::hex << vars.h << std::endl;
	
	return 0;
}
