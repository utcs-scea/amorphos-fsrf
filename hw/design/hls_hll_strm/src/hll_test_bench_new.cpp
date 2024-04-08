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

int main (){
	const uint64_t max_count = 64*1024;
	const uint64_t N = max_count/64;
	hls::stream<axis512> data_in, data_out;

    float std_error = 0;
    int actual_count = 0;

	for (uint64_t i = 0; i < N; ++i) {
		uint512 d;
		for (uint64_t j = 0; j < 64/1; ++j) {
			d(8*(j+1)-1,8*j) = i*64+j;
		}

		axis512 word;
		word.data = d;
		word.dest = 0;
		word.last = (i == N-1);
		data_in.write(word);
	}

    printf("\n Hyperloglog..\n");

    float card = hyperloglog_strm(data_in, data_out, 1, N);
    //printf("done thank god\n");

    printf("\n HI! The estimated cardinality is: %f \n", card);

    for (uint64_t i = 0; i < N; ++i) {
    	axis512 word = data_out.read();
    }

    //assert(max_count != 0);
    //std_error = ((card - (float)1) / (float)1)*100;

    //std_error = ((card - (float)max_count) / (float)max_count)*100;
    //printf("\n The standard error: %f%% \n\n\n", std_error);

    return 0;
}
