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
#include "hyperloglog.cpp"

#define max_count 100000

ap_uint<line_width> data_merge_old (
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

int main_old (){
	hls::stream<net_axis<line_width> > s_axis_input_tuple;
	//hls::stream<memCmd>  m_axis_write_cmd;
	hls::stream<hll_out>  m_axis_write_data;

	ap_uint<64>   regBaseAddr = 0xAAAAAAAA;

	net_axis<line_width> data_in;
	hll_out cardinality;

    float std_error = 0;
    int actual_count = 0;
    printf("\n Hyperloglog..\n");
    uint32_t i = 1;
	uint32_t j;
    ap_uint<line_width> data_sent;
    for(i=1; i<=max_count; i=i+16){
    	data_sent = data_merge_old(i,
    						   i+1,
    						   i+2,
    						   i+3,
    						   i+4,
    						   i+5,
    						   i+6,
    						   i+7,
    						   i+8,
    						   i+9,
    						   i+10,
    						   i+11,
    						   i+12,
    						   i+13,
    						   i+14,
							   i+15
    	);

    	data_in.data = data_sent;
    	data_in.last = 0;
    	data_in.keep = 0xFFFFFFFFFFFFFFFF;
    	s_axis_input_tuple.write(data_in);

        hyperloglog<0>(s_axis_input_tuple,
        		//m_axis_write_cmd,
				m_axis_write_data,
				regBaseAddr);
    }

    	//The last
  		data_in.data = data_sent;
    	data_in.last = 1;
    	s_axis_input_tuple.write(data_in);
        hyperloglog<0>(s_axis_input_tuple, /*m_axis_write_cmd,*/ m_axis_write_data, regBaseAddr);

    	data_in.keep = 0;

    for(i=1; i<=2*num_buckets_m;i++){
        hyperloglog<0>(s_axis_input_tuple, /*m_axis_write_cmd,*/ m_axis_write_data, regBaseAddr);
    }

    if(!m_axis_write_data.empty())
    {
    	cardinality = m_axis_write_data.read();
    }

    float card = cardinality.data;
    printf("\n The estimated cardinality is: %f \n", card);

    assert(max_count != 0);
    //std_error = ((card - (float)1) / (float)1)*100;

    std_error = ((card - (float)max_count) / (float)max_count)*100;
    printf("\n The standard error: %f%% \n\n\n", std_error);

    return 0;
}
