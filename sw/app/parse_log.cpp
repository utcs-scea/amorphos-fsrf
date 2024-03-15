#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <cassert>

int main(int argc, char *argv[]) {
	assert(argc >= 2);
	
	int fd = open(argv[1], O_RDONLY);
	int len = lseek(fd, 0, SEEK_END);
	char *str = (char*)mmap(0, len, PROT_READ, MAP_SHARED, fd, 0);
	
	char *next = str;
	for (int i = 0; i < (1+2+4+8+16+32); ++i) {
		if (argc == 3) {
			next = strchr(next, '/');
			if (next == NULL) break;
			++next;
			next = strchr(next, '/');
			if (next == NULL) break;
			++next;
		}
		next = strchr(next, '/');
		if (next == NULL) break;
		++next;
		long long cyc = strtoll(next, &next, 10);
		printf("%lld\n", cyc);
	}
}
