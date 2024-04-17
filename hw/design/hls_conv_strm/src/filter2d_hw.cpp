
/*
* Copyright 2021 Xilinx, Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include "common.h"
#include "hls_stream.h"
#include <algorithm>

void ReadFromMem(
//        unsigned short       width,
//        unsigned short       height,
//        unsigned short       stride,
        //const unsigned char *src,
		hls::stream<axis512> &axis_in,
		unsigned int 		batch_size,
        hls::stream<U8>     pixel_stream[64] )
{
//    assert(stride <= MAX_IMAGE_WIDTH);
//    assert(height <= MAX_IMAGE_HEIGHT);
//    assert(stride%64 == 0);

//    unsigned num_coefs = FILTER_V_SIZE*FILTER_H_SIZE;
//    unsigned num_coefs_padded = (((num_coefs-1)/64)+1)*64; // Make sure number of reads of multiple of 64, enables auto-widening
//    read_coefs: for (int i=0; i<num_coefs_padded; i++) {
//        U8 coef = coeffs[i];
//        if (i<num_coefs) coeff_stream.write( coef );
//    }

//    stride = (stride/64)*64; // Makes compiler see that stride is a multiple of 64, enables auto-widening
//    unsigned offset = 0;
//    unsigned x = 0;
    ap_uint<512> data;
//    printf("Max pixels is %d\n", height*stride);
    read_batch: for (int k = 0; k < batch_size; k++){
    	printf("Reading batch of %d of %d total\n", k+1, batch_size);

    	read_image: for (int n = 0; n < 128*128; n++) {//stride; n++) {
#pragma HLS unroll factor=64
//#pragma HLS PIPELINE II=1
    		if (n % 64 == 0) {
    			//printf("Reading in new batch of data at pixel %d\n", n);
    			data = axis_in.read().data; // update data every 64 pixels
    		}

    		unsigned offset = n % 64;
    		//printf("Writing pixel #%d at offset %d to %d to pixel stream\n", n, offset*8+7, offset*8);

    		U8 pix = data(offset*8+7, offset*8); // read data from pixel offset
//    		if (x<width) {
			pixel_stream[n%64].write( pix );
//			printf("Wrote pixel %d to stream %d\n", n, n%64);
//    		}
//    		if (x==(stride-1)) x=0; else x++;
    	}
    }
}


void WriteToMem(
//        unsigned short       width,
//        unsigned short       height,
//        unsigned short       stride,
        hls::stream<U8>     pixel_stream[64],
        //unsigned char       *dst)
		hls::stream<axis512> &axis_out,
		unsigned int batch_size,
		unsigned int dest)
{
//    assert(height <= MAX_IMAGE_HEIGHT);

    axis512 outpix;
    write_batch: for (int k = 0; k < batch_size; k++){
		write_image: for (int n = 0; n < 128*128; n++) {
#pragma HLS unroll factor=64
			U8 pix = pixel_stream[n%64].read();

			outpix.data (((n%64)*8)+7, (n%64)*8) = pix;

			if (n % 64 == 63){
				outpix.dest = dest;
				outpix.last = (n == ((128*128)-1));
				axis_out.write(outpix);
			}
		}
    }
}


struct window {
    U8 pix[FILTER_V_SIZE][FILTER_H_SIZE];
};


void Window2D(
//        unsigned short        width,
//        unsigned short        height,
		unsigned int		  batch_size,
        hls::stream<U8>      pixel_stream[64],
        hls::stream<window>  window_stream[64])
{
    // Line buffers - used to store [FILTER_V_SIZE-1] entire lines of pixels
    U8 LineBuffer[FILTER_V_SIZE-1][MAX_IMAGE_WIDTH];  
#pragma HLS ARRAY_PARTITION variable=LineBuffer factor=64 dim=2 cyclic
#pragma HLS ARRAY_PARTITION variable=LineBuffer dim=1 complete
#pragma HLS DEPENDENCE variable=LineBuffer inter false
#pragma HLS DEPENDENCE variable=LineBuffer intra false

    // Sliding window of [FILTER_V_SIZE][FILTER_H_SIZE] pixels
    window Window;

    unsigned ramp_up = 128*((FILTER_V_SIZE-1)/2)+(FILTER_H_SIZE-1)/2;
    unsigned num_pixels = 128*128;
    unsigned num_iterations = num_pixels + ramp_up;

    const unsigned max_iterations = 128*128 + 128*((FILTER_V_SIZE-1)/2)+(FILTER_H_SIZE-1)/2;
    printf("Max iterations: %d\n", max_iterations);
    // Iterate until all pixels have been processed
    for (int k=0; k<batch_size; k++) {
		update_window: for (int n=0; n<num_iterations; n++)
		{
//	#pragma HLS LOOP_TRIPCOUNT max=max_iterations
	#pragma HLS unroll factor=64
//	#pragma HLS PIPELINE II=1

			unsigned col_ptr = n % 128;


			// Read a new pixel from the input stream
//			printf("Reading pixel %d from stream %d\n", n, n%64);
			U8 new_pixel = (n<num_pixels) ? pixel_stream[n%64].read() : 0;

			// Shift the window and add a column of new pixels from the line buffer
			for(int i = 0; i < FILTER_V_SIZE; i++) {
				for(int j = 0; j < FILTER_H_SIZE-1; j++) {
					Window.pix[i][j] = Window.pix[i][j+1];
				}
				Window.pix[i][FILTER_H_SIZE-1] = (i<FILTER_V_SIZE-1) ? LineBuffer[i][col_ptr] : new_pixel;
			}

			// Shift pixels in the column of pixels in the line buffer, add the newest pixel
			for(int i = 0; i < FILTER_V_SIZE-2; i++) {
				LineBuffer[i][col_ptr] = LineBuffer[i+1][col_ptr];
			}
			LineBuffer[FILTER_V_SIZE-2][col_ptr] = new_pixel;

			// Write output only when enough pixels have been read the buffers and ramped-up
			if (n>=ramp_up) {
//				printf("Writing to window stream %d\n", n%64);
				window_stream[n%64].write(Window);
			}
		}
    }
}


void Filter2D(
//        unsigned short       width,
//        unsigned short       height,
//        float                factor,
//        short                bias,
		unsigned int		 batch_size,
        hls::stream<window> window_stream[64],
		hls::stream<U8>     pixel_stream[64] )
{
//    assert(width  <= MAX_IMAGE_WIDTH);
//    assert(height <= MAX_IMAGE_HEIGHT);

    const float factor = 1.0/(FILTER_V_SIZE*FILTER_H_SIZE);
	const short bias   = 0;

    // Filtering coefficients
    char coeffs[FILTER_V_SIZE][FILTER_H_SIZE];
#pragma HLS ARRAY_PARTITION variable=coeffs complete dim=0

    // Load the coefficients into local storage
    load_coefs: for (int i=0; i<FILTER_V_SIZE; i++) {
        for (int j=0; j<FILTER_H_SIZE; j++) {
#pragma HLS PIPELINE II=1
            coeffs[i][j] = 1; //coeff_stream.read();
        }
    }

    // Process the incoming stream of pixel windows
    apply_batch: for (int z = 0; z < batch_size; z++)
    {
		apply_filter: for (int y = 0; y < 128; y++)
		{
			for (int x = 0; x < 128; x++)
			{
#pragma HLS unroll factor=64
//#pragma HLS PIPELINE II=1
				// Read a 2D window of pixels
//				printf("Reading window stream %d\n", x%64);
				window w = window_stream[x%64].read();

				// Apply filter to the 2D window
				int sum = 0;
				for(int row=0; row<FILTER_V_SIZE; row++)
				{
					for(int col=0; col<FILTER_H_SIZE; col++)
					{
						unsigned char pixel;
						int xoffset = (x+col-(FILTER_H_SIZE/2));
						int yoffset = (y+row-(FILTER_V_SIZE/2));
						// Deal with boundary conditions : clamp pixels to 0 when outside of image
						if ( (xoffset<0) || (xoffset>=128) || (yoffset<0) || (yoffset>=128) ) {
							pixel = 0;
						} else {
							pixel = w.pix[row][col];
						}
						sum += pixel*(char)coeffs[row][col];
					}
				}

				// Normalize result
				unsigned char outpix = MIN(MAX((int(factor * sum)+bias), 0), 255);

				// Write the output pixel
				pixel_stream[x%64].write(outpix);
			}
		}
    }
}



extern "C" {

void Filter2DKernel(
//        float                factor,
//        short                bias,
//        unsigned short       width,
//        unsigned short       height,
//        unsigned short       stride,
        //const unsigned char  src[MAX_IMAGE_WIDTH*MAX_IMAGE_HEIGHT],
        //unsigned char        dst[MAX_IMAGE_WIDTH*MAX_IMAGE_HEIGHT],
		hls::stream<axis512> &axis_in,
		hls::stream<axis512> &axis_out,
		unsigned int dest,
		unsigned int batch_size
		)
  {

#pragma HLS INTERFACE axis register_mode=both register port=axis_in
#pragma HLS INTERFACE axis register_mode=both register port=axis_out
#pragma HLS INTERFACE s_axilite register port=dest
#pragma HLS INTERFACE s_axilite register port=batch_size

#pragma HLS INTERFACE s_axilite register port=return
            
#pragma HLS DATAFLOW



	// Stream of pixels from kernel input to filter, and from filter to output
//    hls::stream<char,3>    coefs_stream;
    hls::stream<U8>      pixel_stream[64];
#pragma HLS stream depth=2 variable=pixel_stream
    //hls::stream<window,3>  window_stream("window stream"); // Set FIFO depth to 0 to minimize resources
	hls::stream<window> window_stream[64];
#pragma HLS stream depth=4 variable=window_stream
    hls::stream<U8>     output_stream[64];
#pragma HLS stream depth=64 variable=output_stream

	// Read image data from global memory over AXI4 MM, and stream pixels out
    ReadFromMem(axis_in, batch_size, pixel_stream);

    // Read incoming pixels and form valid HxV windows
    Window2D(batch_size, pixel_stream, window_stream);

	// Process incoming stream of pixels, and stream pixels out
	Filter2D(batch_size, window_stream, output_stream);

	// Write incoming stream of pixels and write them to global memory over AXI4 MM
	WriteToMem(output_stream, axis_out, batch_size, dest);

  }

}
