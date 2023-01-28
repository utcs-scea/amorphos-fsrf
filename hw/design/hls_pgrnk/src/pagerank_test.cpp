#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

void pgrnk (
	uint64_t num_verts,
	uint64_t num_edges,
	uint64_t *vertices,
	uint64_t *edges,
	uint64_t *inputs,
	uint64_t *outputs
);

int main() {
	printf("Here\n");

	const uint64_t num_verts = 1 << 14;
	const uint64_t num_edges = 1 << 16;

	printf("Opening file...\n");
	int fd = open("data/graph.bin", O_RDONLY);
	if (fd == -1) return 1;
	printf("File opened\n");

	printf("Loading file...\n");
	const uint64_t length = num_verts*32 + num_edges*8;
	void *ptr = malloc(length);
	int rc = pread(fd, ptr, length, 0);
	if (rc != length) return 1;
	//void *ptr = mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	//if (ptr == MAP_FAILED) return 1;
	printf("File loaded\n");

	uint64_t *uptr = (uint64_t*)ptr;
	uint64_t *vertices = uptr;
	uint64_t *edges = uptr + num_verts*2;
	uint64_t *inputs = edges + num_edges;
	uint64_t *outputs = inputs + num_verts;

	printf("Starting...\n");
	pgrnk(num_verts, num_edges, vertices, edges, inputs, outputs);
	pgrnk(num_verts, num_edges, vertices, edges, inputs, outputs);
	printf("Done!\n");

	return 0;
}
