#include "hyperloglog.hpp"
//#include "hyperloglog.cpp"

void bll_input(volatile ap_uint<512> *input__, uint64_t N__, hls::stream<net_axis<line_width> > & s_axis_input_tuple) {
	for (uint64_t i = 0; i < N__; i++) {
	#pragma HLS PIPELINE II=1
		net_axis<line_width> data_in;
		ap_uint<line_width> data_sent;
		// put data into stream and call HLL
		data_sent = input__[i];
		data_in.data = data_sent;
		data_in.last = (i == N__-1);
		data_in.keep = 0xFFFFFFFFFFFFFFFF;
		s_axis_input_tuple.write(data_in);
	}
}

void bll(uint64_t N__, hls::stream<net_axis<line_width> > & s_axis_input_tuple, hls::stream<hll_out> & m_axis_write_data) {
	hyperloglog(N__, s_axis_input_tuple, m_axis_write_data);
}

uint32_t bll_output(hls::stream<hll_out> & m_axis_write_data) {
	hll_out cardinality = m_axis_write_data.read();

	union {
		float f;
		uint32_t u;
	};

	f = cardinality.data;
	return u;
}

uint32_t hyperloglog_top(
		ap_uint<512> *input__,
		uint64_t N__
	){
#pragma HLS INTERFACE m_axi num_write_outstanding=1 num_read_outstanding=8 max_write_burst_length=2 max_widen_bitwidth=512 max_read_burst_length=64 depth=64 port=input__

	hls::stream<net_axis<line_width> > s_axis_input_tuple;
#pragma HLS stream depth=8 variable=s_axis_input_tuple
	hls::stream<hll_out>  m_axis_write_data;
#pragma HLS stream depth=8 variable=m_axis_write_data

#pragma HLS DATAFLOW

	bll_input(input__, N__, s_axis_input_tuple);
	bll(N__, s_axis_input_tuple, m_axis_write_data);
	return bll_output(m_axis_write_data);

}




