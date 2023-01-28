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

#ifndef AXIS_UTILS_HPP
#define AXIS_UTILS_HPP

#include <hls_stream.h>
#include "ap_int.h"
#include <stdint.h>
#include <iostream>
#include <fstream>
#include <iomanip>

#define AXI_WIDTH 64

const uint16_t PMTU = 1408; //dividable by 8, 16, 32, 64
const uint16_t PMTU_WORDS = PMTU / (AXI_WIDTH/8);
const uint16_t MAX_QPS = 500;
//This is not enabled/implemented for now due to simplification
//const uint16_t FPGA_LOCAL_QPN = 1;
const ap_uint<8> UDP_PROTOCOL = 0x11; //TODO move somewhere

typedef enum {
	ROUTE_DMA = 0x0,
	ROUTE_CUSTOM = 0x1,
} axiRoute;

//See page 246
typedef enum {
	RC_RDMA_WRITE_FIRST = 0x06,
	RC_RDMA_WRITE_MIDDLE = 0x07,
	RC_RDMA_WRITE_LAST = 0x08,
	RC_RDMA_WRITE_LAST_WITH_IMD = 0x09,
	RC_RDMA_WRITE_ONLY = 0x0A,
	RC_RDMA_WRITE_ONLY_WIT_IMD = 0x0B,
	RC_RDMA_READ_REQUEST = 0x0C,
	RC_RDMA_READ_RESP_FIRST = 0x0D,
	RC_RDMA_READ_RESP_MIDDLE = 0x0E,
	RC_RDMA_READ_RESP_LAST = 0x0F,
	RC_RDMA_READ_RESP_ONLY = 0x10,
	RC_ACK = 0x11,
	RC_RDMA_PART_ONLY = 0x18,
	RC_RDMA_PART_FIRST = 0x19,
	RC_RDMA_PART_MIDDLE = 0x1A,
	RC_RDMA_PART_LAST = 0x1B,
	RC_RDMA_READ_POINTER_REQUEST = 0x1C,
	RC_RDMA_READ_CONSISTENT_REQUEST = 0x1D,
} ibOpCode;

bool checkIfResponse(ibOpCode code);
bool checkIfWriteOrPartReq(ibOpCode code);
bool checkIfAethHeader(ibOpCode code);
bool checkIfRethHeader(ibOpCode code);

//Adaptation of ap_axiu<>
template <int D>
struct net_axis
{
	ap_uint<D>		data;
	ap_uint<D/8>	keep;
	ap_uint<1>		last;
	net_axis() {}
	net_axis(ap_uint<D> data, ap_uint<D/8> keep, ap_uint<1> last)
		:data(data), keep(keep), last(last) {}
};

template <int D, int R>
struct routed_net_axis
{
	ap_uint<D>		data;
	ap_uint<D/8>	keep;
	ap_uint<1>		last;
	ap_uint<R>		dest;
	routed_net_axis() {}
	routed_net_axis(net_axis<D> w, axiRoute r)
		:data(w.data), keep(w.keep), last(w.last), dest(r) {}
	routed_net_axis(net_axis<D> w, ap_uint<R> r)
		:data(w.data), keep(w.keep), last(w.last), dest(r) {}
	routed_net_axis(ap_uint<D> data, ap_uint<D/8> keep, ap_uint<1> last, ap_uint<R> r)
		:data(data), keep(keep), last(last), dest(r) {}	
};

typedef net_axis<AXI_WIDTH> axiWord;
typedef routed_net_axis<AXI_WIDTH, 1> routedAxiWord;

template<int D>
ap_uint<D> reverse(const ap_uint<D>& w)
{
	ap_uint<D> temp;
	for (int i = 0; i < D/8; i++)
	{
		#pragma HLS UNROLL
		temp(i*8+7, i*8) = w(D-(i*8)-1, D-(i*8)-8);
	}
	return temp;
}

template<int D>
ap_uint<D> reverse_bits(const ap_uint<D>& w)
{
	ap_uint<D> temp;
	for (int i = 0; i < D; i++)
	{
		#pragma HLS UNROLL
		temp[i] = w[D-i-1];
	}
	return temp;
}

template<int D>
bool scan(std::istream& inputFile, ap_uint<D>& data)
{
	uint16_t temp;
	for (int i = 0; i < D/8; i++)
	{
		if (inputFile >> std::hex >> temp)
		{
			data(i*8+7, i*8) = temp;
		}
		else
		{
			//std::cerr << "[ERROR]: could not scan input" << std::endl;
			return false;
		}
	}
	return !!inputFile;
}

template<int D>
bool scan(std::istream& inputFile, net_axis<D>& word)
{
	uint16_t temp;
	uint32_t keepTemp;
	uint16_t lastTemp;
	for (int i = 0; i < D/8; i++)
	{
		if (inputFile >> std::hex >> temp)
		{
			word.data(i*8+7, i*8) = temp;
		}
		else
		{
			//std::cerr << "[ERROR]: could not scan input" << std::endl;
			return false;
		}
	}
	inputFile >> keepTemp;
	inputFile >> lastTemp;
	word.keep = keepTemp;
	word.last = lastTemp;
	//if (!inputFile)
	//	std::cerr << "[ERROR]: could not scan input" << std::endl;
	return !!inputFile;
}

template<int D>
bool scanLE(std::istream& inputFile, ap_uint<D>& data)
{
	uint16_t temp;
	for (int i = (D/8)-1; i >= 0; i--)
	{
		if (inputFile >> std::hex >> temp)
		{
			data(i*8+7, i*8) = temp;
		}
		else
		{
			//std::cerr << "[ERROR]: could not scan input" << std::endl;
			return false;
		}
	}
	return !!inputFile;
}

template<int D>
void print(std::ostream& output, ap_uint<D> data)
{
	output << std::hex;
	output << std::setfill('0');
	for (int i = 0; i < D/8; i++)
	{
		output << std::noshowbase << std::setw(2) << (uint16_t) data(i*8+7, i*8) << " ";
	}
}

template<int D>
void print(std::ostream& output, net_axis<D>& word)
{
#ifndef __SYNTHESIS__
	output << std::hex;
	output << std::setfill('0');
	for (int i = 0; i < D/8; i++)
	{
		output << std::noshowbase << std::setw(2) << (uint16_t) word.data(i*8+7, i*8) << " ";
	}
	output << std::setw(D/8/4) << (uint64_t) reverse(word.keep) << " ";
	output << std::setw(1) << (uint16_t)word.last;
#endif
}

template<int D>
void printLE(std::ostream& output, ap_uint<D>& data)
{
#ifndef __SYNTHESIS__
	output << std::hex;
	output << std::setfill('0') ;
	for (int i = (D/8)-1; i >= 0; i--)
	{
		output << std::noshowbase << std::setw(2) << (uint16_t) data(i*8+7, i*8) << " ";
	}
#endif
}

template<int D>
void printLE(std::ostream& output, net_axis<D>& word)
{
#ifndef __SYNTHESIS__
	output << std::hex;
	output << std::setfill('0') ;
	for (int i = (D/8)-1; i >= 0; i--)
	{
		output << std::noshowbase << std::setw(2) << (uint16_t) word.data(i*8+7, i*8) << " ";
	}
	output << std::setw(D/8/4) << (uint64_t) word.keep << " ";
	output << std::setw(1) << (uint16_t)word.last;
#endif
}

template<int D, int R>
void printLE(std::ostream& output, routed_net_axis<D, R>& word)
{
#ifndef __SYNTHESIS__
	output << std::hex;
	output << std::setfill('0') ;
	for (int i = (D/8)-1; i >= 0; i--)
	{
		output << std::noshowbase << std::setw(2) << (uint16_t) word.data(i*8+7, i*8) << " ";
	}
	output << std::setw(D/8/4) << (uint64_t) word.keep << " ";
	output << std::setw(1) << (uint16_t)word.last;
	output << std::setw(R) << " TDEST:" << (uint16_t)word.dest;
#endif
}

template <int W>
void convertStreamToDoubleWidth(hls::stream<net_axis<W> >& input, hls::stream<net_axis<W*2> >&output)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	static ap_uint<1> even = 0;

	static net_axis<W*2> temp;
	net_axis<W> currWord;

	if (!input.empty())
	{
		input.read(currWord);
		switch (even)
		{
			case 0:
				temp.data(W-1, 0) = currWord.data;
				temp.keep((W/8)-1, 0) = currWord.keep;
				temp.keep((W*2/8)-1, (W/8)) = 0; //0x0000; //TODO
				temp.last = currWord.last;
				even = 1;
				//output.write(temp);
				if (currWord.last)
				{
					temp.data((W*2)-1, W) = 0;
					temp.keep((W*2/8)-1, (W/8)) = 0;
					even = 0;
					output.write(temp);
				}
				break;
			case 1:
				temp.data((W*2)-1, W) = currWord.data;
				temp.keep((W*2/8)-1, (W/8)) = currWord.keep;
				temp.last = currWord.last;
				output.write(temp);
				even = 0;
				/*if (currWord.last)
				{
					even = 0;
					output.write(temp);
				}*/
				break;
		}
		/*if (temp.last)
		{
			even = 0;
			//temp.last = 1;
			output.write(temp);
			//std::cout << "convert write last" << std::endl;
			output.write(temp);
			even = false;
		}
		else
		{
			if (even)
			{
				//std::cout << "convert write even" << std::endl;
				output.write(temp);
			}
			even = !even;
		}*/
	}
}

template <int W, int DUMMY>
void convertStreamToHalfWidth(hls::stream<net_axis<W> >& input, hls::stream<net_axis<W/2> >&output)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	enum fsmStateType {FIRST, SECOND};
	static fsmStateType fsmState = FIRST;
	static bool even = false;

	static net_axis<W> currWord;
	net_axis<W/2> temp;

	switch (fsmState)
	{
		case FIRST:
			if (!input.empty())
			{
				input.read(currWord);
				temp.data = currWord.data((W/2)-1, 0);
				temp.keep = currWord.keep(((W/2)/8)-1, 0);
				temp.last = (currWord.keep[(W/8)/2] == 0); //(currWord.keep((W/8)-1, (W/8)/2) == 0);
				output.write(temp);
				if (currWord.keep[(W/8)/2])
				{
					fsmState = SECOND;
				}
			}
			break;
		case SECOND:
			temp.data = currWord.data(W-1, W/2);
			temp.keep = currWord.keep((W/8)-1, (W/8)/2);
			temp.last = currWord.last;
			output.write(temp);
			fsmState = FIRST;
			break;
	}
}

template <class T>
void assignDest(T& d, T& s) {}

template <>
void assignDest<routedAxiWord>(routedAxiWord& d, routedAxiWord& s);

// The 2nd template parameter is a hack to use this function multiple times

template <typename T, int W, int whatever>
void rshiftWordByOctet(	uint16_t offset,
						hls::stream<T>& input,
						hls::stream<T>& output)
{
#pragma HLS inline off
#pragma HLS pipeline II=1 //TODO this has a bug, the bug might come from how it is used
	//std::cout << "ENTER rshiftWordByOctet" << std::endl;

	enum fsmStateType {PKG, REMAINDER};
	static fsmStateType fsmState = PKG;
	static bool rs_firstWord = true;
	//static bool rs_writeRemainder = false;
	static T prevWord;

	T currWord;
	T sendWord;

	sendWord.last = 0;
	switch (fsmState)
	{
	case PKG:
		if (!input.empty())
		{
			input.read(currWord);

			if (!rs_firstWord)
			{
				if (offset == 0)
				{
					sendWord = currWord;
				}
				else
				{
					sendWord.data((W-1)-(8*offset), 0) = prevWord.data((W-1), 8*offset);
					sendWord.data((W-1), W-(8*offset)) = currWord.data((8*offset)-1, 0);

					sendWord.keep((W/8-1)-offset, 0) = prevWord.keep((W/8-1), offset);
					sendWord.keep((W/8-1), (W/8)-offset) = currWord.keep(offset-1, 0);

					sendWord.last = (currWord.keep((W/8-1), offset) == 0);
					assignDest(sendWord, currWord);
				}//else offset
				output.write(sendWord);
			}

			prevWord = currWord;
			rs_firstWord = false;
			if (currWord.last)
			{
				rs_firstWord = true;
				//rs_writeRemainder = (sendWord.last == 0);
				if (!sendWord.last)
				{
					fsmState = REMAINDER;
				}
			}
			//}//else offset
		}
		break;
	case REMAINDER:
		sendWord.data((W-1)-(8*offset), 0) = prevWord.data((W-1), 8*offset);
		sendWord.data((W-1), W-(8*offset)) = 0;
		sendWord.keep((W/8-1)-offset, 0) = prevWord.keep((W/8-1), offset);
		sendWord.keep((W/8-1), (W/8)-offset) = 0;
		sendWord.last = 1;
		assignDest(sendWord, currWord);

		output.write(sendWord);
		fsmState = PKG;
		break;
	}
}

// The 2nd template parameter is a hack to use this function multiple times
template <int W, int whatever>
void lshiftWordByOctet(	uint16_t offset,
						hls::stream<axiWord>& input,
						hls::stream<axiWord>& output)
{
#pragma HLS inline off
#pragma HLS pipeline II=1
	static bool ls_firstWord = true;
		static bool ls_writeRemainder = false;
		static axiWord prevWord;

		axiWord currWord;
		axiWord sendWord;

		//std::cout << "ENTER lshiftWordByOctet" << std::endl;
		//TODO use states
		if (ls_writeRemainder)
		{
			sendWord.data((8*offset)-1, 0) = prevWord.data((W-1), W-(8*offset));
			sendWord.data((W-1), (8*offset)) = 0;
			sendWord.keep(offset-1, 0) = prevWord.keep((W/8-1), (W/8)-offset);
			sendWord.keep((W/8-1), offset) = 0;
			sendWord.last = 1;

			output.write(sendWord);
			//print(std::cout, sendWord);
			std::cout << std::endl;
			ls_writeRemainder = false;
		}
		else if (!input.empty())
		{
			input.read(currWord);
			//std::cout << offset << ": read" << std::endl;
			//print(std::cout, currWord);
			//std::cout << std::endl;

			if (offset == 0)
			{
				output.write(currWord);
			}
			else
			{

				if (ls_firstWord)
				{
					sendWord.data((8*offset)-1, 0) = 0;
					sendWord.data((W-1), (8*offset)) = currWord.data((W-1)-(8*offset), 0);
					sendWord.keep(offset-1, 0) = 0xFFFFFFFF;
					sendWord.keep((W/8-1), offset) = currWord.keep((W/8-1)-offset, 0);
					sendWord.last = (currWord.keep((W/8-1), (W/8)-offset) == 0);
				}
				else
				{
					sendWord.data((8*offset)-1, 0) = prevWord.data((W-1), W-(8*offset));
					sendWord.data((W-1), (8*offset)) = currWord.data((W-1)-(8*offset), 0);

					sendWord.keep(offset-1, 0) = prevWord.keep((W/8-1), (W/8)-offset);
					sendWord.keep((W/8-1), offset) = currWord.keep((W/8-1)-offset, 0);

					sendWord.last = (currWord.keep((W/8-1), (W/8)-offset) == 0);

				}
				output.write(sendWord);
				//std::cout << offset << ": write" << std::endl;
				//print(std::cout, sendWord);
				//std::cout << std::endl;

				prevWord = currWord;
				ls_firstWord = false;
				if (currWord.last)
				{
					ls_firstWord = true;
					ls_writeRemainder = !sendWord.last;
				}
			} //else offset
		}

		//std::cout << "LEAVE lshiftWordByOctet" << std::endl;
}

//TODO move to utils
template <typename T>
void stream_merger(hls::stream<T>& in1, hls::stream<T>& in2, hls::stream<T>& out)
{
#pragma HLS PIPELINE II=1
#pragma HLS inline off

	if (!in1.empty())
	{
		out.write(in1.read());
	}
	else if (!in2.empty())
	{
		out.write(in2.read());
	}
}

template <typename T>
void stream_merger(	hls::stream<ap_uint<1> >&	originIn,
					hls::stream<T>&	input0,
					hls::stream<T>&	input1,
					hls::stream<T>&	output)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	enum stateType {IDLE, FWD0, FWD1};
	static stateType state = IDLE;
	T word;
	ap_uint<1> origin;

	switch (state)
	{
	case IDLE:
		if (!originIn.empty())
		{
			originIn.read(origin);
			if (origin == 0)
			{
				if (!input0.empty())
				{
					input0.read(word);
					output.write(word);
				}
				else
				{
					state = FWD0;
				}
			}
			else
			{
				if (!input1.empty())
				{
					input1.read(word);
					output.write(word);
				}
				else
				{
					state = FWD1;
				}
			}
		}
		break;
	case FWD0:
		if (!input0.empty())
		{
			input0.read(word);
			output.write(word);
			state = IDLE;
		}
		break;
	case FWD1:
		if (!input1.empty())
		{
			input1.read(word);
			output.write(word);
			state = IDLE;
		}
		break;
	}//switch
}

template <class T, int DUMMY>
void fair_merger(hls::stream<T>& in0, hls::stream<T>& in1, hls::stream<T>& out)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	static bool merge_pref = true;

	if (merge_pref)
	{
		if (!in0.empty())
		{
			out.write(in0.read());
			merge_pref = false;
		}
		else if(!in1.empty())
		{
			out.write(in1.read());
		}
	}
	else
	{
		if(!in1.empty())
		{
			out.write(in1.read());
			merge_pref = true;
		}
		else if (!in0.empty())
		{
			out.write(in0.read());
		}
	}
}

template <int W>
void fair_pkg_merger(hls::stream<net_axis<W> >& in0, hls::stream<net_axis<W> >& in1, hls::stream<net_axis<W> >& out)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	enum fpmStateType{IDLE, FWD0, FWD1};
	static fpmStateType state = IDLE;
	static bool merge_pref = true;
	net_axis<W> currWord;

	currWord.last = 0;
	switch (state)
	{
	case IDLE:
		if (merge_pref)
		{
			if (!in0.empty())
			{
				in0.read(currWord);
				out.write(currWord);
				state = FWD1;

			}
			else if(!in1.empty())
			{
				in1.read(currWord);
				out.write(currWord);
				state = FWD1;
			}
		}
		else
		{
			if(!in1.empty())
			{
				in1.read(currWord);
				out.write(currWord);
				state = FWD1;

			}
			else if (!in0.empty())
			{
				in0.read(currWord);
				out.write(currWord);
				state = FWD0;
			}
		}
		if (currWord.last)
		{
			state = IDLE;
		}
		break;
	case FWD0:
		if (!in0.empty())
		{
			in0.read(currWord);
			out.write(currWord);
			if (currWord.last)
			{
				merge_pref = false;
				state = IDLE;
			}
		}
		break;
	case FWD1:
		if (!in1.empty())
		{
			in1.read(currWord);
			out.write(currWord);
			if (currWord.last)
			{
				merge_pref = true;
				state = IDLE;
			}
		}
		break;
	}//switch
}

template <int W>
void stream_pkg_merger(	hls::stream<ap_uint<1> >&	originIn,
						hls::stream<net_axis<W> >&	input0,
						hls::stream<net_axis<W> >&	input1,
						hls::stream<net_axis<W> >&	output)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	enum stateType {IDLE, FWD0, FWD1};
	static stateType state = IDLE;
	net_axis<W> currWord;
	ap_uint<1> origin;

	switch (state)
	{
	case IDLE:
		if (!originIn.empty())
		{
			originIn.read(origin);
			if (origin == 0)
			{
				if (!input0.empty())
				{
					input0.read(currWord);
					output.write(currWord);
					if (!currWord.last)
					{
						state = FWD0;
					}
				}
				else
				{
					state = FWD0;
				}
			}
			else
			{
				if (!input1.empty())
				{
					input1.read(currWord);
					output.write(currWord);
					if (!currWord.last)
					{
						state = FWD1;
					}
				}
				else
				{
					state = FWD1;
				}
			}
		}
		break;
	case FWD0:
		if (!input0.empty())
		{
			input0.read(currWord);
			output.write(currWord);
			if (currWord.last)
			{
				state = IDLE;
			}
		}
		break;
	case FWD1:
		if (!input1.empty())
		{
			input1.read(currWord);
			output.write(currWord);
			if (currWord.last)
			{
				state = IDLE;
			}
		}
		break;
	}//switch
}

template <int W>
void stream_pkg_splitter(	hls::stream<ap_uint<1> >&	destIn,
							hls::stream<net_axis<W> >&	input,
							hls::stream<net_axis<W> >&	output0,
							hls::stream<net_axis<W> >&	output1)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE off

	enum stateType {IDLE, FWD0, FWD1};
	static stateType state = IDLE;
	net_axis<W> currWord;
	ap_uint<1> dest;

	switch (state)
	{
	case IDLE:
		if (!destIn.empty())
		{
			destIn.read(dest);
			state = (dest == 0) ? FWD0 : FWD1;
			if (!input.empty())
			{
				input.read(currWord);
				if (dest == 0)
				{
					output0.write(currWord);
				}
				else
				{
					output1.write(currWord);

				}
				if (currWord.last)
				{
					state = IDLE;
				}
			}
		}
		break;
	case FWD0:
		if (!input.empty())
		{
			input.read(currWord);
			output0.write(currWord);
			if (currWord.last)
			{
				state = IDLE;
			}
		}
		break;
	case FWD1:
		if (!input.empty())
		{
			input.read(currWord);
			output1.write(currWord);
			if (currWord.last)
			{
				state = IDLE;
			}
		}
		break;
	}//switch
}



ap_uint<64> lenToKeep(ap_uint<32> length);

template<int W>
ap_uint<8> keepToLen(ap_uint<W/8> keepValue)
{
	switch (keepValue)
	{
	case 0x01:
		return 0x1;
	case 0x3:
		return 0x2;
	case 0x07:
		return 0x3;
	case 0x0F:
		return 0x4;
	case 0x1F:
		return 0x5;
	case 0x3F:
		return 0x6;
	case 0x7F:
		return 0x7;
	case 0xFF:
		return 0x8;
//#if W > 64
	case 0x01FF:
		return 0x9;
	case 0x3FF:
		return 0xA;
	case 0x07FF:
		return 0xB;
	case 0x0FFF:
		return 0xC;
	case 0x1FFF:
		return 0xD;
	case 0x3FFF:
		return 0xE;
	case 0x7FFF:
		return 0xF;
	case 0xFFFF:
		return 0x10;
//#if W > 128
	case 0x01FFFF:
		return 0x11;
	case 0x3FFFF:
		return 0x12;
	case 0x07FFFF:
		return 0x13;
	case 0x0FFFFF:
		return 0x14;
	case 0x1FFFFF:
		return 0x15;
	case 0x3FFFFF:
		return 0x16;
	case 0x7FFFFF:
		return 0x17;
	case 0xFFFFFF:
		return 0x18;
	case 0x01FFFFFF:
		return 0x19;
	case 0x3FFFFFF:
		return 0x1A;
	case 0x07FFFFFF:
		return 0x1B;
	case 0x0FFFFFFF:
		return 0x1C;
	case 0x1FFFFFFF:
		return 0x1D;
	case 0x3FFFFFFF:
		return 0x1E;
	case 0x7FFFFFFF:
		return 0x1F;
	case 0xFFFFFFFF:
		return 0x20;
//#if W > 256
	case 0x01FFFFFFFF:
		return 0x21;
	case 0x3FFFFFFFF:
		return 0x22;
	case 0x07FFFFFFFF:
		return 0x23;
	case 0x0FFFFFFFFF:
		return 0x24;
	case 0x1FFFFFFFFF:
		return 0x25;
	case 0x3FFFFFFFFF:
		return 0x26;
	case 0x7FFFFFFFFF:
		return 0x27;
	case 0xFFFFFFFFFF:
		return 0x28;
	case 0x01FFFFFFFFFF:
		return 0x29;
	case 0x3FFFFFFFFFF:
		return 0x2A;
	case 0x07FFFFFFFFFF:
		return 0x2B;
	case 0x0FFFFFFFFFFF:
		return 0x2C;
	case 0x1FFFFFFFFFFF:
		return 0x2D;
	case 0x3FFFFFFFFFFF:
		return 0x2E;
	case 0x7FFFFFFFFFFF:
		return 0x2F;
	case 0xFFFFFFFFFFFF:
		return 0x30;

	case 0x01FFFFFFFFFFFF:
		return 0x31;
	case 0x3FFFFFFFFFFFF:
		return 0x32;
	case 0x07FFFFFFFFFFFF:
		return 0x33;
	case 0x0FFFFFFFFFFFFF:
		return 0x34;
	case 0x1FFFFFFFFFFFFF:
		return 0x35;
	case 0x3FFFFFFFFFFFFF:
		return 0x36;
	case 0x7FFFFFFFFFFFFF:
		return 0x37;
	case 0xFFFFFFFFFFFFFF:
		return 0x38;
	case 0x01FFFFFFFFFFFFFF:
		return 0x39;
	case 0x3FFFFFFFFFFFFFF:
		return 0x3A;
	case 0x07FFFFFFFFFFFFFF:
		return 0x3B;
	case 0x0FFFFFFFFFFFFFFF:
		return 0x3C;
	case 0x1FFFFFFFFFFFFFFF:
		return 0x3D;
	case 0x3FFFFFFFFFFFFFFF:
		return 0x3E;
	case 0x7FFFFFFFFFFFFFFF:
		return 0x3F;
	case 0xFFFFFFFFFFFFFFFF:
		return 0x40;
//#endif
//#endif
//#endif
	}
}

#endif
