#ifndef DEFINES_H_
#define DEFINES_H_

#include "ap_fixed.h"
#include "ap_int.h"
#include "nnet_utils/nnet_types.h"
#include <cstddef>
#include <cstdio>

// hls-fpga-machine-learning insert numbers
/*
#define N_INPUT_1_1 128
#define N_INPUT_2_1 128
#define N_INPUT_3_1 3
#define OUT_HEIGHT_2 64
#define OUT_WIDTH_2 64
#define N_FILT_2 128
#define OUT_HEIGHT_2 64
#define OUT_WIDTH_2 64
#define N_FILT_2 128
#define N_FILT_6 128
#define N_LAYER_7 1
*/
#define N_INPUT_1_1 128
#define N_INPUT_2_1 128
#define N_INPUT_3_1 1
#define OUT_HEIGHT_2 4
#define OUT_WIDTH_2 4
#define N_FILT_2 64
#define N_FILT_6 64
#define N_LAYER_7 1

// hls-fpga-machine-learning insert layer-precision
typedef ap_fixed<16,6> input_t;
typedef ap_fixed<16,6> model_default_t;
typedef ap_fixed<16,6> layer2_t;
typedef ap_fixed<16,6> conv2d_weight_t;
typedef ap_fixed<16,6> conv2d_bias_t;
typedef ap_fixed<16,6> layer5_t;
typedef ap_fixed<18,8> activation_table_t;
typedef ap_fixed<16,6> layer6_t;
typedef ap_fixed<16,6> result_t;
typedef ap_fixed<16,6> dense_weight_t;
typedef ap_fixed<16,6> dense_bias_t;
typedef ap_uint<1> layer7_index;
typedef ap_uint<1> layer4_index;

typedef ap_uint<32> uint32;
typedef ap_uint<8> uint8;

typedef ap_fixed<16,6> k_t;

#endif
