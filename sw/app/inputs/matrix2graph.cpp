#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <vector>
#include <limits>

using namespace std;
int main(int argc, char *argv[]) {
	assert(argc >= 3);
	
	const bool symmetric = argc >= 4;
	
	// Open files
	FILE *ifp = fopen(argv[1], "r");
	assert(ifp != NULL);
	FILE *ofp = fopen(argv[2], "w");
	assert(ofp != NULL);
	
	// Allocate line buffer
	const uint64_t line_size = 1025;
	char line[line_size];
	char *lp;
	
	// Skip comments
	while (true) {
		lp = fgets(line, line_size, ifp);
		assert(lp != NULL);
		if (line[0] != '%') break;
	}
	
	// Get dimensions
	uint64_t rows, cols, entries;
	assert(sscanf(line, "%lu %lu %lu", &rows, &cols, &entries) == 3);
	assert(rows != 0);
	assert(rows == cols);
	assert(entries != 0);

	const uint64_t verts = rows;
	const uint64_t edges = symmetric ? 2 * entries : entries;
	printf("Matrix vertices, edges: %lu %lu %s\n", verts, edges, symmetric ? "(with sym)" : "");
	
	// Get vertex data
	vector<uint64_t> num_in_edges(verts, 0);
	vector<uint64_t> num_out_edges(verts, 0);
	vector<vector<uint64_t>> in_edges(verts, vector<uint64_t>());
	for (uint64_t i = 0; i < entries; ++i) {
		lp = fgets(line, line_size, ifp);
		assert(lp != NULL);
		
		uint64_t src, dst;
		//assert(sscanf(line, "%lu %lu", &src, &dst) == 2);
		src = strtoul(line, &lp, 10);
		assert(lp != NULL);
		dst = strtoul(lp+1, &lp, 10);
		assert(lp != NULL);
		
		assert(src != 0);
		assert(dst != 0);
		
		src -= 1;
		dst -= 1;
		
		assert(src < verts);
		assert(dst < verts);
		
		num_in_edges[dst]++;
		num_out_edges[src]++;
		in_edges[dst].push_back(src);
		
		if (symmetric) {
			num_in_edges[src]++;
			num_out_edges[dst]++;
			in_edges[src].push_back(dst);
		}
	}
	
	// Page-length padding metadata
	const uint64_t extra_verts = 512 - (verts % 512);
	const uint64_t extra_edges = 512 - (edges % 512);
	
	uint64_t val;

	// Write vertex metadata
	for (uint64_t i = 0; i < verts; ++i) {
		fwrite(&num_in_edges[i], 8, 1, ofp);
		fwrite(&num_out_edges[i], 8, 1, ofp);
	}
	
	// Write vertex padding
	for (uint64_t i = 0; i < extra_verts; ++i) {
		val = (i == 0) ? extra_edges : 0;
		
		fwrite(&val, 8, 1, ofp);
		fwrite(&val, 8, 1, ofp);
	}
	
	// Write edge data
	for (auto srcs : in_edges) {
		for (uint64_t src : srcs) {
			fwrite(&src, 8, 1, ofp);
		}
	}
	
	// Write edge padding
	for (uint64_t i = 0; i < extra_edges; ++i) {
		val = rows;
		fwrite(&val, 8, 1, ofp);
	}
	
	// Write source pageranks
	val = std::numeric_limits<uint64_t>::max() / verts;
	for (uint64_t i = 0; i < rows; ++i) {
		fwrite(&val, 8, 1, ofp);
	}
	
	val = 0;
	for (uint64_t i = 0; i < extra_verts; ++i) {
		fwrite(&val, 8, 1, ofp);
	}
	
	// Write destination pageranks
	for (uint64_t i = 0; i < verts; ++i) {
		fwrite(&val, 8, 1, ofp);
	}
	for (uint64_t i = 0; i < extra_verts; ++i) {
		fwrite(&val, 8, 1, ofp);
	}
	
	// Print metadata
	const uint64_t final_verts = verts + extra_verts;
	const uint64_t final_edges = edges + extra_edges;
	printf("Final vertices, edges: %lu %lu\n", final_verts, final_edges);
	
	// Close files
	fclose(ofp);
	fclose(ifp);
}
