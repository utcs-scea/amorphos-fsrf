#include <stdint.h>
#include <hls_stream.h>
#include <assert.h>
#include <ap_int.h>

void fetch_verts (
	uint64_t num_verts,
	uint64_t *vertices,
	hls::stream<uint64_t> &ie_counts,
	hls::stream<uint64_t> &oe_counts
) {
	typedef ap_uint<128> uint128_t;
	uint128_t *vert_ptr = (uint128_t*)vertices;

	assert(num_verts % 8 == 0);
	for (uint64_t i = 0; i < num_verts; ++i) {
		#pragma HLS pipeline II=1

		const uint128_t vertex = vert_ptr[i];
		const uint64_t ie_count = vertex(63,0);
		const uint64_t oe_count = vertex(127,64);
		ie_counts.write(ie_count);
		oe_counts.write(oe_count);
	}
}

void fetch_edges (
	uint64_t num_edges,
	uint64_t *edges,
	hls::stream<uint64_t> &in_edges
) {
	assert(num_edges % 8 == 0);
	for (uint64_t i = 0; i < num_edges; ++i) {
		#pragma HLS pipeline II=1

		const uint64_t edge = edges[i];
		in_edges.write(edge);
	}
}

void fetch_weights (
	uint64_t num_weights,
	uint64_t *weights,
	hls::stream<uint64_t> &in_edges,
	hls::stream<uint64_t> &in_weights
) {
	for (uint64_t i = 0; i < num_weights; ++i) {
		#pragma HLS pipeline II=1

		const uint64_t index = in_edges.read();
		const uint64_t weight = weights[index];
		in_weights.write(weight);
	}
}

void sum_weights (
	uint64_t num_verts,
	hls::stream<uint64_t> &ie_counts,
	hls::stream<uint64_t> &in_weights,
	hls::stream<uint64_t> &weights
) {
	for (uint64_t i = 0; i < num_verts; ++i) {
		#pragma HLS pipeline

		const uint64_t num_edges = ie_counts.read();
		uint64_t sum = 0;
		for (uint64_t j = 0; j < num_edges; ++j) {
			#pragma HLS PIPELINE II=1 rewind

			const uint64_t weight = in_weights.read();
			sum += weight;
		}
		weights.write(sum);
	}
}

void div_weights (
	uint64_t num_verts,
	hls::stream<uint64_t> &weights,
	hls::stream<uint64_t> &oe_counts,
	hls::stream<uint64_t> &out_weights
) {
	for (uint64_t i = 0; i < num_verts; ++i) {
		#pragma HLS pipeline II=1

		const uint64_t weight = weights.read();
		const uint64_t oe_count = oe_counts.read();
		const uint64_t out_weight = oe_count ? weight / oe_count : 0;
		out_weights.write(out_weight);
	}
}

void write_weights (
	uint64_t num_verts,
	hls::stream<uint64_t> &out_weights,
	uint64_t *weights
) {
	assert(num_verts % 8 == 0);
	for (uint64_t i = 0; i < num_verts; ++i) {
		#pragma HLS pipeline II=1

		const uint64_t weight = out_weights.read();
		weights[i] = weight;
	}
}

void pgrnk (
	uint64_t num_verts,
	uint64_t num_edges,
	uint64_t *vertices,
	uint64_t *edges,
	uint64_t *inputs,
	uint64_t *outputs
) {
	#pragma HLS INTERFACE m_axi num_write_outstanding=1 num_read_outstanding=4  max_write_burst_length=2  max_read_burst_length=64 depth=32768 bundle=gmem0 port=vertices
	#pragma HLS INTERFACE m_axi num_write_outstanding=1 num_read_outstanding=4  max_write_burst_length=2  max_read_burst_length=64 depth=65536 bundle=gmem1 port=edges
	#pragma HLS INTERFACE m_axi num_write_outstanding=1 num_read_outstanding=64 max_write_burst_length=2  max_read_burst_length=2  depth=16384  bundle=gmem2 port=inputs
	#pragma HLS INTERFACE m_axi num_write_outstanding=4 num_read_outstanding=1  max_write_burst_length=64 max_read_burst_length=2  depth=16384  bundle=gmem3 port=outputs

	#pragma HLS dataflow

	hls::stream<uint64_t> ie_counts;
#pragma HLS STREAM variable=ie_counts depth=32
	hls::stream<uint64_t> oe_counts;
#pragma HLS STREAM variable=oe_counts depth=32

	hls::stream<uint64_t> in_edges;
#pragma HLS STREAM variable=in_edges depth=32

	hls::stream<uint64_t> in_weights;
#pragma HLS STREAM variable=in_weights depth=32

	hls::stream<uint64_t> weights;
#pragma HLS STREAM variable=weights depth=32

	hls::stream<uint64_t> out_weights;
#pragma HLS STREAM variable=out_weights depth=32

	fetch_verts(num_verts, vertices, ie_counts, oe_counts);
	fetch_edges(num_edges, edges, in_edges);
	fetch_weights(num_edges, inputs, in_edges, in_weights);
	sum_weights(num_verts, ie_counts, in_weights, weights);
	div_weights(num_verts, weights, oe_counts, out_weights);
	write_weights(num_verts, out_weights, outputs);
}
