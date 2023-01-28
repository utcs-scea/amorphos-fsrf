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

ap_uint<line_width> data_merge (
					uint32_t inp1,
					uint32_t inp2,
					uint32_t inp3,
					uint32_t inp4,
					uint32_t inp5,
					uint32_t inp6,
					uint32_t inp7,
					uint32_t inp8,
					uint32_t inp9,
					uint32_t inp10,
					uint32_t inp11,
					uint32_t inp12,
					uint32_t inp13,
					uint32_t inp14,
					uint32_t inp15,
					uint32_t inp16
					){
	return
			(((ap_uint<line_width>) inp16) << 480) |
			(((ap_uint<line_width>) inp15)  << 448) |
			(((ap_uint<line_width>) inp14)  << 416) |
			(((ap_uint<line_width>) inp13)  << 384) |
			(((ap_uint<line_width>) inp12)  << 352) |
			(((ap_uint<line_width>) inp11)  << 320) |
			(((ap_uint<line_width>) inp10) << 288) |
			(((ap_uint<line_width>) inp9)  << 256) |
			(((ap_uint<line_width>) inp8)  << 224) |
			(((ap_uint<line_width>) inp7)  << 192) |
			(((ap_uint<line_width>) inp6)  << 160) |
			(((ap_uint<line_width>) inp5)  << 128) |
			(((ap_uint<line_width>) inp4)  << 96) |
			(((ap_uint<line_width>) inp3)  << 64) |
			(((ap_uint<line_width>) inp2)  << 32) |
			((ap_uint<line_width>) inp1);
}
uint32_t hyperloglog_top(
		ap_uint<512> *input__,
		uint64_t N__
	);
int main (){
    float std_error = 0;
    int actual_count = 0;
    printf("\n Hyperloglog..\n");
    uint64_t N = max_count/16;
	ap_uint<line_width> sends[N];
    for(uint64_t j=0; j<N; j++){
    	uint64_t i = j*160+1;
    	sends[j] = data_merge(i,
    						   i+10,
    						   i+20,
    						   i+30,
    						   i+40,
    						   i+50,
    						   i+60,
    						   i+70,
    						   i+80,
    						   i+90,
    						   i+100,
    						   i+110,
    						   i+120,
    						   i+130,
    						   i+140,
							   i+150
    	);
    }
    uint32_t v = hyperloglog_top(sends, N);
    //printf("done thank god\n");
    union {
    	float f;
    	uint32_t u;
    };

    u = v;
    float card = f;

    printf("\n HI! The estimated cardinality is: %f \n", card);

    //assert(max_count != 0);
    //std_error = ((card - (float)1) / (float)1)*100;

    //std_error = ((card - (float)max_count) / (float)max_count)*100;
    //printf("\n The standard error: %f%% \n\n\n", std_error);

    return 0;
}
