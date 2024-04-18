#include <iostream>

#include "myproject.h"
#include "parameters.h"

#define KFLOW

#ifdef KDEBUG
#define LOG(...) printf(__VA_ARGS__)
#else
#define LOG(...)
#endif

void kzero (char *ptr, int n) {
    for (int i = 0; i < n; i++) {
        ptr[i] = 0;
    }
}

struct krelu_config5 : nnet::activ_config {
    static const unsigned n_in = INPUT_SIZE;
    static const unsigned table_size = 1024;
    static const unsigned io_type = nnet::io_parallel;
    static const unsigned reuse_factor = 1;
    typedef activation_table_t table_t;
};

// global_average_pooling2d
struct kconfig6 : nnet::pooling2d_config {
    static const unsigned in_height = 8;
    static const unsigned in_width = 8;
    static const unsigned out_height = 1;
    static const unsigned out_width = 1;
    static const unsigned n_filt = 256;
    static const nnet::Pool_Op pool_op = nnet::Average;
    static const unsigned reuse_factor = 1;
    typedef model_default_t accum_t;
};

// dense
struct kconfig7 : nnet::dense_config {
    static const unsigned n_in = 256;
    static const unsigned n_out = 1;
    static const unsigned io_type = nnet::io_parallel;
    static const unsigned strategy = nnet::latency;
    static const unsigned reuse_factor = 1;
    static const unsigned n_zeros = 0;
    //static const unsigned n_nonzeros = 256;
    static const unsigned multiplier_limit = DIV_ROUNDUP(n_in * n_out, reuse_factor) - n_zeros / reuse_factor;
    static const bool store_weights_in_bram = false;
    typedef model_default_t accum_t;
    typedef dense_bias_t bias_t;
    typedef dense_weight_t weight_t;
    typedef layer7_index index_t;
    template<class x_T, class y_T>
    using product = nnet::product::mult<x_T, y_T>;
};

// dense
struct kconfig4 : nnet::dense_config {
    static const unsigned n_in = INPUT_SIZE;
    static const unsigned n_out = 1;
    static const unsigned io_type = nnet::io_parallel;
    static const unsigned strategy = nnet::latency;
    static const unsigned reuse_factor = 1;
    static const unsigned n_zeros = 0;
    //static const unsigned n_nonzeros = 128; // what is this? does it matter? i think it refers to number of weights
    //nvm it matters not at all bc we dont use the compressed impl
    static const unsigned multiplier_limit = DIV_ROUNDUP(n_in * n_out, reuse_factor) - n_zeros / reuse_factor;
    static const bool store_weights_in_bram = false;
    typedef model_default_t accum_t;
    typedef dense_bias_t bias_t;
    typedef dense_weight_t weight_t;
    typedef layer4_index index_t;
    template<class x_T, class y_T>
    using product = nnet::product::mult<x_T, y_T>;
};

void fill_input_helper (k_t input_1[INPUT_SIZE], uint512 &data, int i) {
    for (int j = 0; j < 64; j++)
#pragma HLS UNROLL factor=16
    {
        uint8 tmp = data((j * 8) + 7, j * 8);
        float tmpf = tmp;
        tmpf /= 255;
        input_1[i * 64 + j] = tmpf;
    }    
}

void fill_input (k_t input_1[INPUT_SIZE], hls::stream<axis512> &axis_in) {
    for (int i = 0; i < AXIWORDS_IN_INPUT; i++) 
#pragma HLS PIPELINE II=2
    {
        axis512 word = axis_in.read();
        uint512 data = word.data;
        fill_input_helper(input_1, data, i);
    }
}

void write_output_helper (k_t buf[INPUT_SIZE], uint512 &data, int i) {
    for (int j = 0; j < 64; j++)
        //#pragma HLS UNROLL factor=16
    {
        float tmpf = buf[i * 64 + j];
        uint8 tmpi = tmpf;
        data((j * 8) + 7, j * 8) = tmpi;
    }    
}

void write_output (k_t buf[INPUT_SIZE], hls::stream<axis512> &axis_out, uint64 dest, int img) {
    for (int i = 0; i < AXIWORDS_IN_INPUT; i++) 
#pragma HLS PIPELINE
    {
        axis512 word;
        uint512 data = word.data;
        write_output_helper(buf, data, i);
        word.last = (img == 1 && i == AXIWORDS_IN_INPUT - 1) ? 1 : 0;
        word.dest = dest;
        word.keep = -1;
        word.strb = -1;
        axis_out.write(word);
    }
}

void myproject (
               hls::stream<axis512> &axis_in,
               hls::stream<axis512> &axis_out,
               uint64 nimages,
               uint64 dest
               ) {
#pragma HLS INTERFACE s_axilite register port=return
#pragma HLS INTERFACE axis register_mode=both register port=axis_in
#pragma HLS INTERFACE axis register_mode=both register port=axis_out
#pragma HLS INTERFACE s_axilite register port=nimages
#pragma HLS INTERFACE s_axilite register port=dest

#pragma HLS DATAFLOW

    k_t input_1[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=input_1 cyclic factor=64
    k_t layer4a_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4a_out cyclic factor=64
    k_t layer4b_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4b_out cyclic factor=64
    k_t layer4c_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4c_out cyclic factor=64
    k_t layer4d_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4d_out cyclic factor=64
    k_t layer4e_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4e_out cyclic factor=64
    k_t layer4f_out[INPUT_SIZE];
#pragma HLS ARRAY_PARTITION variable=layer4f_out cyclic factor=64
//     k_t layer4g_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4g_out cyclic factor=64
//     k_t layer4h_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4h_out cyclic factor=64
//     k_t layer4i_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4i_out cyclic factor=64
//     k_t layer4j_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4j_out cyclic factor=64
//     k_t layer4k_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4k_out cyclic factor=64
//     k_t layer4l_out[INPUT_SIZE];
// #pragma HLS ARRAY_PARTITION variable=layer4l_out cyclic factor=64

    for (int i = 0; i < nimages; i++)
    {
#pragma HLS DATAFLOW
        
        fill_input(input_1, axis_in);
        nnet::dense_latency<k_t, k_t, kconfig4>(input_1, layer4a_out, kw0, kb0);
        nnet::dense_latency<k_t, k_t, kconfig4>(layer4a_out, layer4b_out, kw1, kb1);
        nnet::dense_latency<k_t, k_t, kconfig4>(layer4b_out, layer4c_out, kw2, kb3);
        nnet::dense_latency<k_t, k_t, kconfig4>(layer4c_out, layer4d_out, kw3, kb2);
        nnet::dense_latency<k_t, k_t, kconfig4>(layer4d_out, layer4e_out, kw4, kb4);
        nnet::dense_latency<k_t, k_t, kconfig4>(layer4e_out, layer4f_out, kw5, kb5);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4f_out, layer4g_out, kw6, kb6);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4g_out, layer4h_out, kw7, kb7);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4h_out, layer4i_out, kw8, kb8);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4i_out, layer4j_out, kw9, kb9);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4j_out, layer4k_out, kwa, kba);
        // nnet::dense_latency<k_t, k_t, kconfig4>(layer4k_out, layer4l_out, kwb, kbb);
        write_output(layer4f_out, axis_out, dest, nimages - i);
    }
}
