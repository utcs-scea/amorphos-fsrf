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

void fill_bucket(
		uint64_t N,
		hls::stream<bucketMeta>&	bucketMetaFifoIn,
		hls::stream<rank_t>&		bucket_stream_fifo
) {

	rank_t buckets[num_buckets_m];
#pragma HLS DEPENDENCE variable=buckets inter false

	for (bucket_cnt_t i = 0; i < num_buckets_m; ++i) {
#pragma HLS PIPELINE II=1
		buckets[i] = 0;
	}

	bucket_id_t prev_bucketNum  = 0;
	bucket_id_t prev_prev_bucketNum  = 0;
	bucket_id_t prev_prev_prev_bucketNum  = 0;
	bucket_id_t prev_prev_prev_prev_bucketNum  = 0;
	//bucket_id_t prev_prev_prev_prev_prev_bucketNum  = 0;

	rank_t	prev_rank = 0;
	rank_t	prev_prev_rank = 0;
	rank_t	prev_prev_prev_rank = 0;
	rank_t	prev_prev_prev_prev_rank = 0;
	//rank_t prev_prev_prev_prev_prev_rank = 0;

	for (uint64_t i = 0; i < N; ++i) {
		#pragma HLS PIPELINE II=1

		bucketMeta	const	meta = bucketMetaFifoIn.read();
		rank_t		const	rank = meta.numZeros + 1;

		/* Handling the dependency -- Start*/
		rank_t	current_rank;
		if (meta.bucketNum == prev_bucketNum) {
			current_rank = prev_rank;
		}
		else if (meta.bucketNum == prev_prev_bucketNum) {
			current_rank = prev_prev_rank;
		}
		else if (meta.bucketNum == prev_prev_prev_bucketNum) {
			current_rank = prev_prev_prev_rank;
		}
		else if (meta.bucketNum == prev_prev_prev_prev_bucketNum) {
			current_rank = prev_prev_prev_prev_rank;
		}
		//else if (meta.bucketNum == prev_prev_prev_prev_prev_bucketNum) {
		//	current_rank = prev_prev_prev_prev_prev_rank;
		//}
		else {
			current_rank = buckets[meta.bucketNum];
		}
		//prev_prev_prev_prev_prev_rank = prev_prev_prev_prev_rank;
		prev_prev_prev_prev_rank = prev_prev_prev_rank;
		prev_prev_prev_rank = prev_prev_rank;
		prev_prev_rank = prev_rank;

		if (rank > current_rank) {
			buckets[meta.bucketNum] = rank;
			prev_rank = rank;
		} else {
			prev_rank = current_rank;
		}
		//prev_prev_prev_prev_prev_bucketNum = prev_prev_prev_prev_bucketNum;
		prev_prev_prev_prev_bucketNum = prev_prev_prev_bucketNum;
		prev_prev_prev_bucketNum = prev_prev_bucketNum;
		prev_prev_bucketNum = prev_bucketNum;
		prev_bucketNum = meta.bucketNum;
		/* Handling the dependency -- End*/
	}

	for (bucket_cnt_t i = 0; i < num_buckets_m; ++i) {
#pragma HLS PIPELINE II=1

		rank_t const buckVal = buckets[i];
		bucket_stream_fifo.write(buckVal);
	}
}
