#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <vector>
#include <unordered_set>
#include <set>

typedef std::unordered_set<uint64_t> myset;
//typedef std::set<uint64_t> myset;

uint64_t separator = 0;

const uint64_t UL_MAX = 0xFFFFFFFFFFFFFFFF;

bool write_to_hex = false;

void update_separator(FILE* fp) {
	separator++;
	if (write_to_hex && separator % 8 == 0)
		fprintf(fp, "\n");
}

void write_hex(FILE* fp, uint64_t n) {
	if (write_to_hex) fprintf(fp, "%016lX", n);
	else fwrite(&n, 8, 1, fp);
}

int main(int argc, char* argv[]) {
	char* p;
	uint64_t target_deg = strtoul(argv[1], &p, 10);
	//uint64_t vertices = strtoul(argv[1], &p, 10);
	uint64_t log_filesize = strtoul(argv[2], &p, 10);
	FILE* fp;
	if (write_to_hex) fp = fopen("mem_init.hex", "w+");
	else fp = fopen("graph.bin", "w+");

	uint64_t filesize = uint64_t{1} << log_filesize;

	uint64_t vertices = filesize / (16 + 32 * target_deg/2); // 16 bytes per vertex, 32 bytes per edge
	
	uint64_t edges = target_deg * vertices / 2;

	printf("%lu vertices, %lu log_filesize, %lu filesize\n", vertices, log_filesize, filesize);

	std::vector<myset> graph(vertices);//, myset());
	std::vector<uint64_t> deg(vertices);

	//uint64_t num_tris = 0;
	uint64_t fsize = vertices * 16; // 2 FFFFFFFF words per vertex

	// generate graph
	uint64_t n_full_vertices = 0;
	srand(12344321);
	uint64_t e = 0;
	printf("Begin graph generation\n");
	while (e < edges) {
	//while (fsize < filesize) {
		uint64_t src = rand() % vertices;
		uint64_t dest = rand() % vertices;
		if (src != dest && graph[dest].find(src) == graph[dest].end()) {
			// see if it would add a triangle
/*
			for (const auto& elem : graph[dest]) {
				
				//if (graph[elem].contains(src)) {
				auto search = graph[elem].find(src);
				if (search != graph[elem].end()) {
					num_tris++;
					fsize += 32; // bytes
				}
			}
*/
			// add the edge
			e++;
			graph[src].insert(dest);
			graph[dest].insert(src);
			deg[src]++;
			deg[dest]++;
			fsize += 32; // 16 bytes per side
			if (graph[src].size() == vertices-1) n_full_vertices++;
			if (graph[dest].size() == vertices-1) n_full_vertices++;
			if (n_full_vertices == vertices) {
				printf("Error: all %lu vertices have %lu edges\n", vertices, graph[src].size());
				exit(1);
			}
		}
	}
	printf("Begin calculating vertex offsets\n");


	uint64_t offset = 0;

	// calculate vertex offsets
	
	std::vector<uint64_t> vert_to_addr(vertices);
	for (uint64_t i = 0; i < vertices; i++) {
		vert_to_addr[i] = offset;
		offset += deg[i]*2+2;
	}

	printf("Begin writing final array\n");
	//std::vector<uint64_t> fpga_array;

	for (uint64_t i = 0; i < vertices; i++) {
		for (const auto& elem: graph[i]) {
			uint64_t neighbor_start = vert_to_addr[elem];
			uint64_t neighbor_end = neighbor_start + deg[elem]*2;
			write_hex(fp, neighbor_start);
			//fpga_array.push_back(neighbor_start);
			update_separator(fp);
			write_hex(fp, neighbor_end);
			//fpga_array.push_back(neighbor_end);
			update_separator(fp);
		}
		write_hex(fp, UL_MAX);
		//fpga_array.push_back(UL_MAX);
		update_separator(fp);
		write_hex(fp, UL_MAX);
		//fpga_array.push_back(UL_MAX);
		update_separator(fp);
	}

	// axi-align file contents
	/*while (separator % 8) {
		write_hex(fp, UL_MAX);
		fpga_array.push_back(UL_MAX);
		update_separator(fp);
	}*/

	// write output space, update separator
	/*for (uint64_t i = 0; i < num_tris*4; i++) {
		write_hex(fp, 0);
		update_separator(fp);
	}*/
	while (fsize < filesize) {
		write_hex(fp, UL_MAX);
		//fpga_array.push_back(UL_MAX);
		update_separator(fp);
		fsize += 8;
	}

	while (separator % 8) {
		write_hex(fp, UL_MAX);
		//fpga_array.push_back(UL_MAX);
		separator++;
		fsize += 8;
	}

	fclose(fp);

	printf("Starting counting2\n");
	uint64_t num_tris_3 = 0;
/*
	uint64_t cur_node = 0;
	for (uint64_t i = 0; i < fpga_array.size(); i+=2) {
		if (fpga_array[i] == UL_MAX) {
			cur_node = 2 + i;
			continue;
		}
		uint64_t start1 = fpga_array[i];
		uint64_t end1 = fpga_array[i+1];
		if (start1 > end1) printf("Error\n");
		if (start1 < cur_node) continue;
		for (uint64_t j = start1; j < end1; j+=2) {
			uint64_t start2 = fpga_array[j];
			uint64_t end2 = fpga_array[j+1];
			if (start2 > end2) printf("Error2\n");
			if (start2 == UL_MAX || end2 == UL_MAX) printf("Error4\n");
			if (start2 < start1) continue;
			for (uint64_t k = start2; k < end2; k+=2) {
				uint64_t start3 = fpga_array[k];
				uint64_t end3 = fpga_array[k+1];
				if (start3 > end3) printf("Error3\n");
				if (start3 == UL_MAX || end3 == UL_MAX) printf("Error4\n");
				if (start3 == cur_node) {
					num_tris_3++; break;
				}
			}
		}
	}

*/


	printf("Starting counting\n");
	uint64_t num_tris_2 = 0;

	for (uint64_t i = 0; i < vertices; i++) {
		for (const auto& elem : graph[i]) {
			if (elem < i) continue;
			for (const auto& elem2 : graph[elem]) {
				if (elem2 < elem) continue;
				auto search = graph[elem2].find(i);
				if (search != graph[elem2].end()) {
					num_tris_2++;
				}
			}
		}
	}


	printf("Done counting\n");

	// write parameters to file
	FILE* f = fopen("params.txt", "w+");

	uint64_t deg_sum = 0;
	for (uint64_t i = 0; i < vertices; i++) {
		deg_sum+=deg[i];
	}
	uint64_t deg_avg = deg_sum/vertices;

	fprintf(f, "n_vert: %lu\n", vertices);
	fprintf(f, "n_edges: %lu\n", e);
	//fprintf(f, "n_tris: %lu\n", num_tris);
	fprintf(f, "deg_avg: %lu\n", deg_avg);
	fprintf(f, "n_tris2: %lu\n", num_tris_2);
	fprintf(f, "n_tris3: %lu\n", num_tris_3);
	fprintf(f, "req_f: %lu\n", filesize);
	fprintf(f, "fsize: %lu\n", fsize);
	fprintf(f, "fsizeMB: %lu\n", filesize/1024/1024);
	fprintf(f, "fsize/vert: %lu\n", fsize/vertices);
	fclose(f);

	return 0;
}
