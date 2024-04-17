#ifndef PARAMETERS_H_
#define PARAMETERS_H_

#include "ap_fixed.h"
#include "ap_int.h"

#include "nnet_utils/nnet_code_gen.h"
#include "nnet_utils/nnet_helpers.h"
// hls-fpga-machine-learning insert includes
#include "nnet_utils/nnet_activation.h"
#include "nnet_utils/nnet_activation_stream.h"
#include "nnet_utils/nnet_conv2d.h"
#include "nnet_utils/nnet_conv2d_stream.h"
#include "nnet_utils/nnet_dense.h"
#include "nnet_utils/nnet_dense_compressed.h"
#include "nnet_utils/nnet_dense_stream.h"
#include "nnet_utils/nnet_pooling.h"
#include "nnet_utils/nnet_pooling_stream.h"

// hls-fpga-machine-learning insert weights
#include "weights/w2.h"
#include "weights/b2.h"
#include "weights/w7.h"
#include "weights/b7.h"

// hls-fpga-machine-learning insert layer-config
// conv2d
struct config2_mult : nnet::dense_config {
    static const unsigned n_in = 27;
    static const unsigned n_out = 128;
    static const unsigned reuse_factor = 1;
    static const unsigned strategy = nnet::latency;
    static const unsigned n_zeros = 0;
    static const unsigned multiplier_limit = DIV_ROUNDUP(n_in * n_out, reuse_factor) - n_zeros / reuse_factor;
    typedef model_default_t accum_t;
    typedef conv2d_bias_t bias_t;
    typedef conv2d_weight_t weight_t;
    template<class x_T, class y_T>
    using product = nnet::product::mult<x_T, y_T>;
};

struct config2 : nnet::conv2d_config {
    static const unsigned pad_top = 0;
    static const unsigned pad_bottom = 1;
    static const unsigned pad_left = 0;
    static const unsigned pad_right = 1;
    static const unsigned in_height = 128;
    static const unsigned in_width = 128;
    static const unsigned n_chan = 3;
    static const unsigned filt_height = 3;
    static const unsigned filt_width = 3;
    static const unsigned kernel_size = filt_height * filt_width;
    static const unsigned n_filt = 128;
    static const unsigned stride_height = 2;
    static const unsigned stride_width = 2;
    static const unsigned out_height = 64;
    static const unsigned out_width = 64;
    static const unsigned reuse_factor = 1;
    static const unsigned n_zeros = 0;
    static const unsigned multiplier_limit =
        DIV_ROUNDUP(kernel_size * n_chan * n_filt, reuse_factor) - n_zeros / reuse_factor;
    static const bool store_weights_in_bram = false;
    //static const unsigned strategy = nnet::latency;
    static const unsigned strategy = nnet::resource;
    static const nnet::conv_implementation implementation = nnet::conv_implementation::linebuffer;
    static const unsigned min_height = 128;
    static const unsigned min_width = 128;
    static const ap_uint<filt_height * filt_width> pixels[min_height * min_width];
    static const unsigned n_partitions = 4096;
    static const unsigned n_pixels = out_height * out_width / n_partitions;
    template<class data_T, class CONFIG_T>
    using fill_buffer = nnet::fill_buffer_2<data_T, CONFIG_T>;
    typedef model_default_t accum_t;
    typedef conv2d_bias_t bias_t;
    typedef conv2d_weight_t weight_t;
    typedef config2_mult mult_config;
    template<unsigned K, unsigned S, unsigned W>
    using scale_index_height = nnet::scale_index_unscaled<K, S, W>;
    template<unsigned K, unsigned S, unsigned W>
    using scale_index_width = nnet::scale_index_unscaled<K, S, W>;
};
const ap_uint<config2::filt_height * config2::filt_width> config2::pixels[] = {0};

// activation
struct relu_config5 : nnet::activ_config {
    static const unsigned n_in = 524288;
    static const unsigned table_size = 1024;
    static const unsigned io_type = nnet::io_parallel;
    static const unsigned reuse_factor = 1;
    typedef activation_table_t table_t;
};

// global_average_pooling2d
struct config6 : nnet::pooling2d_config {
    static const unsigned in_height = 64;
    static const unsigned in_width = 64;
    static const unsigned n_filt = 128;
    static const nnet::Pool_Op pool_op = nnet::Average;
    static const unsigned reuse_factor = 1;
    typedef model_default_t accum_t;
};

// dense
struct config7 : nnet::dense_config {
    static const unsigned n_in = 128;
    static const unsigned n_out = 1;
    static const unsigned io_type = nnet::io_parallel;
    static const unsigned strategy = nnet::latency;
    static const unsigned reuse_factor = 1;
    static const unsigned n_zeros = 0;
    static const unsigned n_nonzeros = 128;
    static const unsigned multiplier_limit = DIV_ROUNDUP(n_in * n_out, reuse_factor) - n_zeros / reuse_factor;
    static const bool store_weights_in_bram = false;
    typedef model_default_t accum_t;
    typedef dense_bias_t bias_t;
    typedef dense_weight_t weight_t;
    typedef layer7_index index_t;
    template<class x_T, class y_T>
    using product = nnet::product::mult<x_T, y_T>;
};


#endif
