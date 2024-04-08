/**
 * Copyright (c) 2020, Systems Group, ETH Zurich
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "hyperloglog.hpp"

float hyperloglog_strm(
		hls::stream<axis512> &axis_in,
		hls::stream<axis512> &axis_out,
		uint64_t dest,
		uint64_t N
){
#pragma HLS INTERFACE ap_ctrl_chain port=return
#pragma HLS INTERFACE s_axilite register port=return
#pragma HLS INTERFACE axis register_mode=both register port=axis_in
#pragma HLS INTERFACE axis register_mode=both register port=axis_out
#pragma HLS INTERFACE s_axilite register port=dest
#pragma HLS INTERFACE s_axilite register port=N

#pragma HLS DATAFLOW

    hls::stream<aggrOutput> aggr_out;
#pragma HLS stream depth=2 variable=aggr_out
#pragma HLS AGGREGATE variable=aggr_out

    hls::stream<float>  accm;
#pragma HLS stream depth=2 variable=accm

	hls::stream<rank_t> numzeros_out;
#pragma HLS stream depth=2 variable=numzeros_out

    hls::stream<bucket_cnt_t> zero_count;
#pragma HLS stream depth=4 variable=zero_count

    hls::stream<uint_1_t> done_out;
#pragma HLS stream depth=2 variable=done_out

	hls::stream<dataItem<8> > dataFifo[NUM_PIPELINES];
#pragma HLS stream depth=2 variable=dataFifo
#pragma HLS AGGREGATE variable=dataFifo

	hls::stream<rank_t> bucket_fifo[NUM_PIPELINES];
#pragma HLS stream depth=2 variable=bucket_fifo


	divide_data(N, dest, axis_in, axis_out, dataFifo);

	pipeline(N, dataFifo[0], bucket_fifo[0]);
	pipeline(N, dataFifo[1], bucket_fifo[1]);
	pipeline(N, dataFifo[2], bucket_fifo[2]);
	pipeline(N, dataFifo[3], bucket_fifo[3]);
	pipeline(N, dataFifo[4], bucket_fifo[4]);
	pipeline(N, dataFifo[5], bucket_fifo[5]);
	pipeline(N, dataFifo[6], bucket_fifo[6]);
	pipeline(N, dataFifo[7], bucket_fifo[7]);
	pipeline(N, dataFifo[8], bucket_fifo[8]);
	pipeline(N, dataFifo[9], bucket_fifo[9]);
	pipeline(N, dataFifo[10], bucket_fifo[10]);
	pipeline(N, dataFifo[11], bucket_fifo[11]);
	pipeline(N, dataFifo[12], bucket_fifo[12]);
	pipeline(N, dataFifo[13], bucket_fifo[13]);
	pipeline(N, dataFifo[14], bucket_fifo[14]);
	pipeline(N, dataFifo[15], bucket_fifo[15]);
	pipeline(N, dataFifo[16], bucket_fifo[16]);
	pipeline(N, dataFifo[17], bucket_fifo[17]);
	pipeline(N, dataFifo[18], bucket_fifo[18]);
	pipeline(N, dataFifo[19], bucket_fifo[19]);
	pipeline(N, dataFifo[20], bucket_fifo[20]);
	pipeline(N, dataFifo[21], bucket_fifo[21]);
	pipeline(N, dataFifo[22], bucket_fifo[22]);
	pipeline(N, dataFifo[23], bucket_fifo[23]);
	pipeline(N, dataFifo[24], bucket_fifo[24]);
	pipeline(N, dataFifo[25], bucket_fifo[25]);
	pipeline(N, dataFifo[26], bucket_fifo[26]);
	pipeline(N, dataFifo[27], bucket_fifo[27]);
	pipeline(N, dataFifo[28], bucket_fifo[28]);
	pipeline(N, dataFifo[29], bucket_fifo[29]);
	pipeline(N, dataFifo[30], bucket_fifo[30]);
	pipeline(N, dataFifo[31], bucket_fifo[31]);
	pipeline(N, dataFifo[32], bucket_fifo[32]);
	pipeline(N, dataFifo[33], bucket_fifo[33]);
	pipeline(N, dataFifo[34], bucket_fifo[34]);
	pipeline(N, dataFifo[35], bucket_fifo[35]);
	pipeline(N, dataFifo[36], bucket_fifo[36]);
	pipeline(N, dataFifo[37], bucket_fifo[37]);
	pipeline(N, dataFifo[38], bucket_fifo[38]);
	pipeline(N, dataFifo[39], bucket_fifo[39]);
	pipeline(N, dataFifo[40], bucket_fifo[40]);
	pipeline(N, dataFifo[41], bucket_fifo[41]);
	pipeline(N, dataFifo[42], bucket_fifo[42]);
	pipeline(N, dataFifo[43], bucket_fifo[43]);
	pipeline(N, dataFifo[44], bucket_fifo[44]);
	pipeline(N, dataFifo[45], bucket_fifo[45]);
	pipeline(N, dataFifo[46], bucket_fifo[46]);
	pipeline(N, dataFifo[47], bucket_fifo[47]);
	pipeline(N, dataFifo[48], bucket_fifo[48]);
	pipeline(N, dataFifo[49], bucket_fifo[49]);
	pipeline(N, dataFifo[50], bucket_fifo[50]);
	pipeline(N, dataFifo[51], bucket_fifo[51]);
	pipeline(N, dataFifo[52], bucket_fifo[52]);
	pipeline(N, dataFifo[53], bucket_fifo[53]);
	pipeline(N, dataFifo[54], bucket_fifo[54]);
	pipeline(N, dataFifo[55], bucket_fifo[55]);
	pipeline(N, dataFifo[56], bucket_fifo[56]);
	pipeline(N, dataFifo[57], bucket_fifo[57]);
	pipeline(N, dataFifo[58], bucket_fifo[58]);
	pipeline(N, dataFifo[59], bucket_fifo[59]);
	pipeline(N, dataFifo[60], bucket_fifo[60]);
	pipeline(N, dataFifo[61], bucket_fifo[61]);
	pipeline(N, dataFifo[62], bucket_fifo[62]);
	pipeline(N, dataFifo[63], bucket_fifo[63]);

	aggr_bucket(bucket_fifo, aggr_out);

	//count zeros in the bucket
	zero_counter(aggr_out, numzeros_out, zero_count);

	accumulate(numzeros_out, accm);

	//cardinality estimation
	return estimate_cardinality<HASH_SIZE>(accm, zero_count);
}
