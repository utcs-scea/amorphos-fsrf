#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <iostream>
#include <vector>
#include <chrono>

using namespace std;
using namespace std::chrono;

uint32_t permute(uint32_t idx) {
	uint64_t prime = (1<<19)-1;
	uint64_t temp = idx;
	temp = (temp * temp) & 0x3FFFFFFFFF;
	temp = temp % prime;
	temp = (idx & (1<<18)) ? prime - temp : temp;
	return temp;
}

int main(int argc, char *argv[]) {
	uint64_t page_size = 1;
	if (argc > 1) page_size = strtoull(argv[1], nullptr, 10);
	
	bool reading = true;
	if (argc > 2) reading = (strtoull(argv[2], nullptr, 10) == 1);
	
	int fd = open(argc > 3 ? argv[3] : "/mnt/nvme0/file0.bin", O_RDWR);
	if (fd == -1) {
		printf("File open failed\n");
		exit(EXIT_FAILURE);
	}
	void *buf = aligned_alloc(4<<10, page_size<<12);
	if (buf == nullptr) {
		printf("Data buffer allocation failed\n");
	}
	std::vector<bool> faulted((1<<19)/page_size, false);
	
	high_resolution_clock::time_point start, end;
	start = high_resolution_clock::now();
	for (uint64_t i = 0; i < (1<<19); ++i) {
		uint64_t rng = permute(permute(i)^0x3635);
		uint64_t big_page = rng / page_size;
		if (!faulted[big_page]) {
			int64_t io_size = page_size<<12;
			if (reading) {
				if (pread(fd, buf, io_size, page_size*big_page<<12) != io_size) {
					//printf("%d %p %ld %lu\n", fd, buf, io_size, page_size*big_page<<12);
					perror("Pread failed: ");
					exit(EXIT_FAILURE);
				}
			} else {
				if (pwrite(fd, buf, io_size, page_size*big_page<<12) != io_size) {
					perror("Pwrite failed: ");
					exit(EXIT_FAILURE);
				}
			}
			faulted[big_page] = true;
		}
		
	}
	end = high_resolution_clock::now();
	
	duration<double> diff = end - start;
	double seconds = diff.count();
	double throughput = ((double)(2ull<<30))/seconds/(1<<20);
	printf("cpu rng: %lu bytes in %g seconds for %g MiB/s\n", 2ul<<30, seconds, throughput);
	
	return 0;
}

