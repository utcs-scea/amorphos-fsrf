#ifndef NNET_IMAGE_STREAM_H_
#define NNET_IMAGE_STREAM_H_

#include "hls_stream.h"
#include "nnet_common.h"

namespace nnet {

template <class data_T, typename CONFIG_T> void resize_nearest(hls::stream<data_T> &image, hls::stream<data_T> &resized) {
    assert(CONFIG_T::new_height % CONFIG_T::height == 0);
    assert(CONFIG_T::new_width % CONFIG_T::width == 0);
    constexpr unsigned ratio_height = CONFIG_T::new_height / CONFIG_T::height;
    constexpr unsigned ratio_width = CONFIG_T::new_width / CONFIG_T::width;

ImageHeight:
    for (unsigned h = 0; h < CONFIG_T::height; h++) {
        //#kpragma HLS PIPELINE

        data_T data_in_row[CONFIG_T::width];

    ImageWidth:
        for (unsigned i = 0; i < CONFIG_T::width; i++) {
            //#kpragma HLS UNROLL

            data_T in_data = image.read();

        ImageChan:
            for (unsigned j = 0; j < CONFIG_T::n_chan; j++) {
                //#kpragma HLS UNROLL

                data_in_row[i][j] = in_data[j];
            }
        }

    ResizeHeight:
        for (unsigned i = 0; i < ratio_height; i++) {
            //#kpragma HLS UNROLL

        ImageWidth2:
            for (unsigned l = 0; l < CONFIG_T::width; l++) {
                //#kpragma HLS UNROLL

            ResizeWidth:
                for (unsigned j = 0; j < ratio_width; j++) {
                    //#kpragma HLS UNROLL

                    data_T out_data;
                    PRAGMA_DATA_PACK(out_data)

                ResizeChan:
                    for (unsigned k = 0; k < CONFIG_T::n_chan; k++) {
                        //#kpragma HLS UNROLL

                        out_data[k] = data_in_row[l][k];
                    }

                    resized.write(out_data);
                }
            }
        }
    }
}

} // namespace nnet

#endif
