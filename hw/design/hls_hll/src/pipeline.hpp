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

#include "axi_utils.hpp"

#include "murmur3.hpp"
#include "bucket_num_zero_detector.hpp"
#include "fill_bucket.hpp"

template <int DUMMY>
void pipeline(
		uint64_t N,
		hls::stream<dataItem<32> >&	line_data,
		hls::stream<rank_t>&		bucket_stream_fifo
) {
#pragma HLS INLINE

	static hls::stream<dataItem<HASH_SIZE>> hashFifo;
	#pragma HLS stream depth=8 variable=hashFifo

	static hls::stream<bucketMeta> bucketMetaFifo;
	#pragma HLS stream depth=8 variable=bucketMetaFifo

	murmur3<DUMMY>(N, line_data, hashFifo);

	//extract bucket index and zero detection
	bz_detector<DUMMY>(N, hashFifo, bucketMetaFifo);

	//call the fill_bucket
	fill_bucket<DUMMY>(N, bucketMetaFifo, bucket_stream_fifo);
}
