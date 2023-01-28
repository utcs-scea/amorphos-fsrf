/*===============================================================*/
/*                                                               */
/*                      optical_flow.cpp                         */
/*                                                               */
/*             Hardware function for optical flow                */
/*                                                               */
/*===============================================================*/

#include "typedefs.h"

// use HLS video library
#include "xf_video_mem.hpp"

#include "hls_stream.h"
#include <array>

// read in and buffer input frames
void read_frames(frames_t *frames,
    hls::stream<input_t> frame1[PAR_FACTOR],
    hls::stream<input_t> frame2[PAR_FACTOR],
    hls::stream<input_t> frame3a[PAR_FACTOR],
    hls::stream<input_t> frame3b[PAR_FACTOR],
    hls::stream<input_t> frame4[PAR_FACTOR],
    hls::stream<input_t> frame5[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_hs port=return
  typedef std::array<frames_t,IO_FACTOR> wide_frame_t;
  wide_frame_t *wide_frames = (wide_frame_t*)frames;
  const int TARGET_II = IO_FACTOR / PAR_FACTOR;
  FRAMES_CP: for (int i=0; i<(MAX_HEIGHT * MAX_WIDTH / IO_FACTOR); ++i)
  {
    #pragma HLS pipeline II=TARGET_II
    wide_frame_t wide_frame = wide_frames[i];
    FRAMES_CP_PAR: for (int w=0; w<IO_FACTOR; w++)
    {
      #pragma HLS unroll
      // assign values to the FIFOs
      frames_t buf = wide_frame[w];
      const int p = w % PAR_FACTOR;
      frame1[p].write( (input_t)(buf( 7,  0)) >> 8);
      frame2[p].write( (input_t)(buf(15,  8)) >> 8);
      frame3a[p].write((input_t)(buf(23, 16)) >> 8);
      frame3b[p].write((input_t)(buf(23, 16)) >> 8);
      frame4[p].write( (input_t)(buf(31, 24)) >> 8);
      frame5[p].write( (input_t)(buf(39, 32)) >> 8);
    }
  }
}

// calculate gradient in x and y directions
void gradient_xy_calc(hls::stream<input_t> frame[PAR_FACTOR],
    hls::stream<pixel_t> gradient_x[PAR_FACTOR],
    hls::stream<pixel_t> gradient_y[PAR_FACTOR])
{
#pragma HLS INTERFACE ap_ctrl_none port=return
  // our own line buffer
  static pixel_t buf[4][MAX_WIDTH];
  #pragma HLS array_reshape variable=buf dim=1 complete
  #pragma HLS array_partition variable=buf dim=2 factor=PAR_FACTOR cyclic

  // small buffer
  pixel_t smallbuf[5];
  #pragma HLS array_partition variable=smallbuf dim=1 complete
  
  // window buffer
  xf::cv::Window<5,5,input_t> window;

  const int GRAD_WEIGHTS[] =  {1,-8,0,8,-1};

  GRAD_XY_OUTER: for(int r=0; r<MAX_HEIGHT+2; r++)
  {
    GRAD_XY_INNER: for(int c=0; c<MAX_WIDTH+2; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      GRAD_XY_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        int new_c = c+p;
        int c = new_c;
        if (c >= MAX_WIDTH+2) continue;

        // read out values from current line buffer
        for (int i = 0; i < 4; i ++ )
          smallbuf[i] = buf[i][c];
        // the new value is either 0 or read from frame
        if (r<MAX_HEIGHT && c<MAX_WIDTH)
          smallbuf[4] = (pixel_t)(frame[p].read());
        else// if (c < MAX_WIDTH)
          smallbuf[4] = 0;
        // update line buffer
        if(r<MAX_HEIGHT && c<MAX_WIDTH)
        {
          for (int i = 0; i < 3; i ++ )
            buf[i][c] = smallbuf[i+1];
          buf[3][c] = smallbuf[4];
        }
        else if(c<MAX_WIDTH)
        {
          for (int i = 0; i < 3; i ++ )
            buf[i][c] = smallbuf[i+1];
          buf[3][c] = smallbuf[4];
        }

        // manage window buffer
        if(r<MAX_HEIGHT && c<MAX_WIDTH)
        {
          window.shift_pixels_left();

          for (int i = 0; i < 5; i ++ )
            window.insert_pixel(smallbuf[i],i,4);
        }
        else
        {
          window.shift_pixels_left();
          window.insert_pixel(0,0,4);
          window.insert_pixel(0,1,4);
          window.insert_pixel(0,2,4);
          window.insert_pixel(0,3,4);
          window.insert_pixel(0,4,4);
        }

        // compute gradient
        pixel_t x_grad = 0;
        pixel_t y_grad = 0;
        if(r>=4 && r<MAX_HEIGHT && c>=4 && c<MAX_WIDTH)
        {
          GRAD_XY_XYGRAD: for(int i=0; i<5; i++)
          {
            x_grad += (pixel_t)window.getval(2,i)*GRAD_WEIGHTS[i];
            y_grad += (pixel_t)window.getval(i,2)*GRAD_WEIGHTS[i];
          }
          gradient_x[(p+16-2)%PAR_FACTOR].write(x_grad/12);
          gradient_y[(p+16-2)%PAR_FACTOR].write(y_grad/12);
        }
        else if(r>=2 && c>=2)
        {
          gradient_x[(p+16-2)%PAR_FACTOR].write(0);
          gradient_y[(p+16-2)%PAR_FACTOR].write(0);
        }
      }
    }
  }
}

// calculate gradient in the z direction
void gradient_z_calc(hls::stream<input_t> frame1[PAR_FACTOR],
    hls::stream<input_t> frame2[PAR_FACTOR],
    hls::stream<input_t> frame3[PAR_FACTOR],
    hls::stream<input_t> frame4[PAR_FACTOR],
    hls::stream<input_t> frame5[PAR_FACTOR],
    hls::stream<pixel_t> gradient_z[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  const int GW[] =  {1,-8,0,8,-1};
  GRAD_Z_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
    GRAD_Z_INNER: for(int c=0; c<MAX_WIDTH; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      GRAD_Z_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        input_t f1 = frame1[p].read();
        input_t f2 = frame2[p].read();
        input_t f3 = frame3[p].read();
        input_t f4 = frame4[p].read();
        input_t f5 = frame5[p].read();

        pixel_t px = (f1*GW[0]+f2*GW[1]+f3*GW[2]+f4*GW[3]+f5*GW[4]);
        gradient_z[p].write(px/12);
      }
    }
  }
}

// average the gradient in y direction
void gradient_weight_y(hls::stream<pixel_t> gradient_x[PAR_FACTOR],
    hls::stream<pixel_t> gradient_y[PAR_FACTOR],
    hls::stream<pixel_t> gradient_z[PAR_FACTOR],
    hls::stream<gradient_t> filt_grad[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  xf::cv::LineBuffer<7,MAX_WIDTH,gradient_t,PAR_FACTOR> buf;
  //std::array<gradient_t,7> arr[MAX_WIDTH];
  //#pragma HLS aggregate variable=arr
  //#pragma HLS array_reshape variable=arr cyclic factor=PAR_FACTOR dim=1

  const pixel_t GRAD_FILTER[] = {0.0755, 0.133, 0.1869, 0.2903, 0.1869, 0.133, 0.0755};
  GRAD_WEIGHT_Y_OUTER: for(int r=0; r<MAX_HEIGHT+3; r++)
  {
    GRAD_WEIGHT_Y_INNER: for(int c=0; c<MAX_WIDTH; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      #pragma HLS dependence variable=buf inter false
      GRAD_WEIGHT_Y_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        int new_c = c+p;
        int c = new_c;

        buf.shift_pixels_up(c);
        gradient_t tmp;
        if(r<MAX_HEIGHT)
        {
          tmp.x = gradient_x[p].read();
          tmp.y = gradient_y[p].read();
          tmp.z = gradient_z[p].read();
        }
        else
        {
          tmp.x = 0;
          tmp.y = 0;
          tmp.z = 0;
        }
        buf.insert_bottom_row(tmp,c);
        //arr[c][r%7] = tmp;

        gradient_t acc;
        acc.x = 0;
        acc.y = 0;
        acc.z = 0;
        if(r >= 6 && r<MAX_HEIGHT)
        {
          GRAD_WEIGHT_Y_ACC: for(int i=0; i<7; i++)
          {
            gradient_t tmp = buf.getval(i,c);
            //gradient_t tmp = arr[c][(r+1+i)%7];
            //gradient_t tmp = arr[c][i];
            acc.x += tmp.x*GRAD_FILTER[i];
            acc.y += tmp.y*GRAD_FILTER[i];
            acc.z += tmp.z*GRAD_FILTER[i];
          }
          filt_grad[p].write(acc);
        }
        else if(r>=3)
        {
          filt_grad[p].write(acc);
        }
      }
    }
  }
}

// average gradient in the x direction
void gradient_weight_x(hls::stream<gradient_t> y_filt[PAR_FACTOR],
    hls::stream<gradient_t> filt_grad[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  xf::cv::Window<1,7,gradient_t> buf;
  const pixel_t GRAD_FILTER[] = {0.0755, 0.133, 0.1869, 0.2903, 0.1869, 0.133, 0.0755};
  GRAD_WEIGHT_X_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
    GRAD_WEIGHT_X_INNER: for(int c=0; c<MAX_WIDTH+3; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      GRAD_WEIGHT_X_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        int new_c = c+p;
        int c = new_c;
        if (c >= MAX_WIDTH+3) continue;

        buf.shift_pixels_left();
        gradient_t tmp;
        if(c<MAX_WIDTH)
        {
          tmp = y_filt[p].read();
        }
        else
        {
          tmp.x = 0;
          tmp.y = 0;
          tmp.z = 0;
        }
        buf.insert_pixel(tmp,0,6);

        gradient_t acc;
        acc.x = 0;
        acc.y = 0;
        acc.z = 0;
        if(c >= 6 && c<MAX_WIDTH)
        {
          GRAD_WEIGHT_X_ACC: for(int i=0; i<7; i++)
          {
            acc.x += buf.getval(0,i).x*GRAD_FILTER[i];
            acc.y += buf.getval(0,i).y*GRAD_FILTER[i];
            acc.z += buf.getval(0,i).z*GRAD_FILTER[i];
          }
          filt_grad[(p+16-3)%PAR_FACTOR].write(acc);
        }
        else if(c>=3)
        {
          filt_grad[(p+16-3)%PAR_FACTOR].write(acc);
        }
      }
    }
  }
}

// outer product 
void outer_product(hls::stream<gradient_t> gradient[PAR_FACTOR],
    hls::stream<outer_t> outer_product[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  OUTER_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
    OUTER_INNER: for(int c=0; c<MAX_WIDTH; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      OUTER_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        gradient_t grad = gradient[p].read();
        outer_pixel_t x = (outer_pixel_t) grad.x;
        outer_pixel_t y = (outer_pixel_t) grad.y;
        outer_pixel_t z = (outer_pixel_t) grad.z;
        outer_t out;
        out.val[0] = (x*x);
        out.val[1] = (y*y);
        out.val[2] = (z*z);
        out.val[3] = (x*y);
        out.val[4] = (x*z);
        out.val[5] = (y*z);
        outer_product[p].write(out);
      }
    }
  }
}

// tensor weight
void tensor_weight_y(hls::stream<outer_t> outer[PAR_FACTOR],
    hls::stream<tensor_t> tensor_y[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  xf::cv::LineBuffer<3,MAX_WIDTH,outer_t,PAR_FACTOR> buf;
  //std::array<outer_t,3> arr[MAX_WIDTH];
  //#pragma HLS aggregate variable=arr
  //#pragma HLS array_reshape variable=arr cyclic factor=PAR_FACTOR dim=1
  const pixel_t TENSOR_FILTER[] = {0.3243, 0.3513, 0.3243};
  TENSOR_WEIGHT_Y_OUTER: for(int r=0; r<MAX_HEIGHT+1; r++)
  {
    TENSOR_WEIGHT_Y_INNER: for(int c=0; c<MAX_WIDTH; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      TENSOR_WEIGHT_Y_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        int new_c = c + p;
        int c = new_c;

        outer_t tmp;
        #pragma HLS aggregate variable=tmp
        //#pragma HLS aggregate variable=buf.val[0]
        buf.shift_pixels_up(c);
        //arr[c][2] = arr[c][1];
        //arr[c][1] = arr[c][0];
        if(r<MAX_HEIGHT)
        {
          tmp = outer[p].read();
        }
        else
        {
          TENSOR_WEIGHT_Y_TMP_INIT: for(int i=0; i<6; i++)
            tmp.val[i] = 0;
        }
        buf.insert_bottom_row(tmp,c);
        //arr[c][r%3] = tmp;

        tensor_t acc;
        TENSOR_WEIGHT_Y_ACC_INIT: for(int k =0; k<6; k++)
        acc.val[k] = 0;

        if (r >= 2 && r < MAX_HEIGHT)
        {
          TENSOR_WEIGHT_Y_TMP_OUTER: for(int i=0; i<3; i++)
          {
            tmp = buf.getval(i,c);
            //tmp = arr[c][i];
            pixel_t k = TENSOR_FILTER[i];
            TENSOR_WEIGHT_Y_TMP_INNER: for(int component=0; component<6; component++)
            {
              acc.val[component] += tmp.val[component]*k;
            }
          }
        }
        if(r >= 1)
        {
          tensor_y[p].write(acc);
        }
      }
    }
  }
}

void tensor_weight_x(hls::stream<tensor_t> tensor_y[PAR_FACTOR],
    hls::stream<tensor_t> tensor[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  xf::cv::Window<1,3,tensor_t> buf;
  const pixel_t TENSOR_FILTER[] = {0.3243, 0.3513, 0.3243};
  TENSOR_WEIGHT_X_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
    TENSOR_WEIGHT_X_INNER: for(int c=0; c<MAX_WIDTH+1; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      TENSOR_WEIGHT_X_PAR: for(int p=0; p<PAR_FACTOR; ++p)
      {
        #pragma HLS unroll
        int new_c = c + p;
        int c = new_c;
        if (c >= MAX_WIDTH+1) continue;

        buf.shift_pixels_left();
        tensor_t tmp;
        if(c<MAX_WIDTH)
        {
          tmp = tensor_y[p].read();
        }
        else
        {
          TENSOR_WEIGHT_X_TMP_INIT: for(int i=0; i<6; i++)
            tmp.val[i] = 0;
        }
        buf.insert_pixel(tmp,0,2);

        tensor_t acc;
        TENSOR_WEIGHT_X_ACC_INIT: for(int k =0; k<6; k++)
          acc.val[k] = 0;
        if (c >= 2 && c < MAX_WIDTH)
        {
          TENSOR_WEIGHT_X_TMP_OUTER: for(int i=0; i<3; i++)
          {
            tmp = buf.getval(0,i);
            TENSOR_WEIGHT_X_TMP_INNER: for(int component=0; component<6; component++)
            {
              acc.val[component] += tmp.val[component]*TENSOR_FILTER[i];
            }
          }
        }
        if(c>=1)
        {
          tensor[(p+PAR_FACTOR-1)%PAR_FACTOR].write(acc);
        }
      }
    }
  }
}

// compute output flow
void flow_calc(hls::stream<tensor_t> tensors[PAR_FACTOR],
               hls::stream<velocity_t> velocity[PAR_FACTOR])
{
  #pragma HLS INTERFACE ap_ctrl_none port=return
  static outer_pixel_t buf[2];
  FLOW_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
    FLOW_INNER: for(int c=0; c<MAX_WIDTH; c+=PAR_FACTOR)
    {
      #pragma HLS pipeline II=1
      FLOW_PAR: for(int p=0; p<PAR_FACTOR; p++)
      {
        #pragma HLS unroll
        int new_c = c + p;
        int c = new_c;

        tensor_t tmp_tensor = tensors[p].read();
        if(r>=2 && r<MAX_HEIGHT-2 && c>=2 && c<MAX_WIDTH-2)
        {
          calc_pixel_t t1 = (calc_pixel_t) tmp_tensor.val[0];
          calc_pixel_t t2 = (calc_pixel_t) tmp_tensor.val[1];
          calc_pixel_t t3 = (calc_pixel_t) tmp_tensor.val[2];
          calc_pixel_t t4 = (calc_pixel_t) tmp_tensor.val[3];
          calc_pixel_t t5 = (calc_pixel_t) tmp_tensor.val[4];
          calc_pixel_t t6 = (calc_pixel_t) tmp_tensor.val[5];

          calc_pixel_t denom = t1*t2-t4*t4;
          calc_pixel_t one = 1;
          calc_pixel_t numer0 = t6*t4-t5*t2;
          calc_pixel_t numer1 = t5*t4-t6*t1;

          if(denom != 0)
          {
            calc_pixel_t denom_1 = one / denom;
            buf[0] = numer0 * denom_1;
            buf[1] = numer1 * denom_1;
          }
          else
          {
            buf[0] = 0;
            buf[1] = 0;
          }
        }
        else
        {
          buf[0] = buf[1] = 0;
        }
        velocity_t out;
        out.x = (vel_pixel_t)buf[0];
        out.y = (vel_pixel_t)buf[1];
        velocity[p].write(out);
      }
    }
  }
}

void write_outputs(hls::stream<velocity_t> velocity[PAR_FACTOR],
                   velocity_t *outputs)
{
  #pragma HLS INTERFACE ap_ctrl_hs port=return
  typedef std::array<velocity_t,IO_FACTOR> wide_velocity_t;
  wide_velocity_t *wide_outputs = (wide_velocity_t*)outputs;
  const int TARGET_II = IO_FACTOR / PAR_FACTOR;
  OUTPUTS_CP: for (int i=0; i<(MAX_HEIGHT * MAX_WIDTH / IO_FACTOR); ++i)
  {
    #pragma HLS pipeline II=TARGET_II
    wide_velocity_t wide_velocity;
	OUTPUTS_PAR: for(int w=0; w<IO_FACTOR; w++)
    {
      #pragma HLS unroll
	  wide_velocity[w] = velocity[w % PAR_FACTOR].read();
	}
	wide_outputs[i] = wide_velocity;
  }
}

// top-level kernel function
void optical_flow(frames_t *frames,
                  velocity_t *outputs,
                  uint64_t n)
{
  #pragma HLS INTERFACE ap_ctrl_hs port=return
  const int AXI_DEPTH = 2 * MAX_HEIGHT * MAX_WIDTH;
  #pragma HLS INTERFACE m_axi latency=1 depth=AXI_DEPTH port=frames
  #pragma HLS INTERFACE m_axi latency=1 depth=AXI_DEPTH port=outputs

  for (uint64_t i = 0; i < n; ++i) {
    #pragma HLS DATAFLOW
    const uint64_t off = i * MAX_HEIGHT * MAX_WIDTH;

    // FIFOs connecting the stages
    hls::stream<input_t> frame1[PAR_FACTOR];
    hls::stream<input_t> frame2[PAR_FACTOR];
    hls::stream<input_t> frame3a[PAR_FACTOR];
    hls::stream<input_t> frame3b[PAR_FACTOR];
    hls::stream<input_t> frame4[PAR_FACTOR];
    hls::stream<input_t> frame5[PAR_FACTOR];

    hls::stream<pixel_t> gradient_x[PAR_FACTOR];
    hls::stream<pixel_t> gradient_y[PAR_FACTOR];
    hls::stream<pixel_t> gradient_z[PAR_FACTOR];
    const int GZ_DEPTH = 2*MAX_WIDTH/PAR_FACTOR+8;
    #pragma HLS STREAM variable=gradient_z depth=GZ_DEPTH
    #pragma HLS BIND_STORAGE variable=gradient_z type=fifo impl=bram

    hls::stream<gradient_t> y_filtered[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=y_filtered
    hls::stream<gradient_t> filtered_gradient[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=filtered_gradient

    hls::stream<outer_t> out_product[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=out_product

    hls::stream<tensor_t> tensor_y[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=tensor_y
    hls::stream<tensor_t> tensor[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=tensor

    hls::stream<velocity_t> velocity[PAR_FACTOR];
    #pragma HLS AGGREGATE variable=velocity

    // stream in and organize the inputs
    frames_t *frames_ptr = frames+off;
    read_frames(frames_ptr, frame1, frame2, frame3a, frame3b, frame4, frame5);

    // compute
    gradient_xy_calc(frame3a, gradient_x, gradient_y);
    gradient_z_calc(frame1, frame2, frame3b, frame4, frame5, gradient_z);
    gradient_weight_y(gradient_x, gradient_y, gradient_z, y_filtered);
    gradient_weight_x(y_filtered, filtered_gradient);
    outer_product(filtered_gradient, out_product);
    tensor_weight_y(out_product, tensor_y);
    tensor_weight_x(tensor_y, tensor);
    flow_calc(tensor, velocity);

    // stream out outputs
    velocity_t *outputs_ptr = outputs+off;
    write_outputs(velocity, outputs_ptr);
  }
}
