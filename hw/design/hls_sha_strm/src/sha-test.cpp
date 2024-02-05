#include "sha-256.hpp"

int main() {
	hls::stream<axis512> data_in, data_out;
	for (uint64_t i = 0; i < 64; ++i) {
		uint512 d;
		for (uint64_t j = 0; j < 64/8; ++j) {
			d(64*(j+1)-1,64*j) = 8*i+j;
		}

		axis512 word;
		word.data = d;
		word.dest = 0;
		word.last = (i == 63);
		data_in.write(word);
	}
	
	sha_t vars = sha256_strm(data_in, data_out, 64, 2);

	std::cout << std::hex << vars.a << std::endl;
	std::cout << std::hex << vars.b << std::endl;
	std::cout << std::hex << vars.c << std::endl;
	std::cout << std::hex << vars.d << std::endl;
	std::cout << std::hex << vars.e << std::endl;
	std::cout << std::hex << vars.f << std::endl;
	std::cout << std::hex << vars.g << std::endl;
	std::cout << std::hex << vars.h << std::endl;
	
	for (uint64_t i = 0; i < 64; ++i) {
		axis512 word = data_out.read();
		if (i == 0 || i == 63) {
			std::cout << word.data << std::endl;
			std::cout << word.dest << std::endl;
			std::cout << word.last << std::endl;
		}
	}

	return 0;
}
