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

#pragma once
#include <stdint.h>
#include "ap_axi_sdata.h"
#include "axi_utils.hpp"

#include "globals.hpp"

#include "estimate_cardinality.hpp"

const unsigned NUM_PIPELINES = 64;

struct aggrOutput
{
	rank_t	value;
	ap_uint<1>	last;
	aggrOutput() {}
	aggrOutput(rank_t value, ap_uint<1> last)
		:value(value), last(last) {}
};


//forward declarations

#include "globals.hpp"
#include "axi_utils.hpp"

#ifdef soft_compare

#include <fstream>
#include <cstdlib> // for exit function
#endif

using namespace std;
using namespace hls;

typedef ap_uint<512> uint512;
typedef hls::axis<uint512, 0, 5, 5> axis512;

void aggr_bucket(
	hls::stream<rank_t> numZerosFifo[NUM_PIPELINES],
	hls::stream<aggrOutput>& zeros
);

void divide_data(
	uint64_t N,
	uint64_t dest,
	hls::stream<axis512> &axis_in,
	hls::stream<axis512> &axis_out,
	hls::stream<dataItem<8> >	dataFifoOut[NUM_PIPELINES]
);

void pipeline(
	uint64_t N,
	hls::stream<dataItem<8>>& line_data,
	hls::stream<rank_t>&      bucket_stream_fifo
);

void murmur3(
	uint64_t N,
	hls::stream<dataItem<8>>&	dataFifo,
	hls::stream<dataItem<8>>&	hashFifo
);

void bz_detector(
	uint64_t N,
	hls::stream<dataItem<HASH_SIZE>>& hashFifoIn,
	hls::stream<bucketMeta>&          bucketFifoOut
);

void fill_bucket(
	uint64_t N,
	hls::stream<bucketMeta>&	bucketMetaFifoIn,
	hls::stream<rank_t>&		bucket_stream_fifo
);

void zero_counter(
	hls::stream<aggrOutput>&	buck_val_in,
	hls::stream<rank_t>&		buck_val_out,
	hls::stream<bucket_cnt_t>&	zero_counter
);

void accumulate (
	hls::stream<rank_t>&		buck_val,
	hls::stream<float>&			accm
);

float hyperloglog_strm(
	hls::stream<axis512> &axis_in,
	hls::stream<axis512> &axis_out,
	uint64_t dest,
	uint64_t N
);
