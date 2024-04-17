#include <systemc>
#include <vector>
#include <iostream>
#include "hls_stream.h"
#include "ap_int.h"
#include "ap_fixed.h"
using namespace std;
using namespace sc_dt;
class AESL_RUNTIME_BC {
  public:
    AESL_RUNTIME_BC(const char* name) {
      file_token.open( name);
      if (!file_token.good()) {
        cout << "Failed to open tv file " << name << endl;
        exit (1);
      }
      file_token >> mName;//[[[runtime]]]
    }
    ~AESL_RUNTIME_BC() {
      file_token.close();
    }
    int read_size () {
      int size = 0;
      file_token >> mName;//[[transaction]]
      file_token >> mName;//transaction number
      file_token >> mName;//pop_size
      size = atoi(mName.c_str());
      file_token >> mName;//[[/transaction]]
      return size;
    }
  public:
    fstream file_token;
    string mName;
};
unsigned int ap_apatb_axis_in_V_cap_bc;
static AESL_RUNTIME_BC __xlx_axis_in_V_size_Reader("../tv/stream_size/stream_size_in_axis_in_V.dat");
unsigned int ap_apatb_axis_out_V_cap_bc;
static AESL_RUNTIME_BC __xlx_axis_out_V_size_Reader("../tv/stream_size/stream_size_out_axis_out_V.dat");
struct __cosim_s80__ { char data[128]; };
struct __cosim_s8__ { char data[8]; };
struct __cosim_s40__ { char data[64]; };
extern "C" void myproject(__cosim_s80__*, __cosim_s80__*, __cosim_s8__, __cosim_s8__);
extern "C" void apatb_myproject_hw(volatile void * __xlx_apatb_param_axis_in, volatile void * __xlx_apatb_param_axis_out, __cosim_s8__ __xlx_apatb_param_nimages, __cosim_s8__ __xlx_apatb_param_dest) {
  // collect __xlx_axis_in_tmp_vec
  unsigned __xlx_axis_in_V_tmp_Count = 0;
  unsigned __xlx_axis_in_V_read_Size = __xlx_axis_in_V_size_Reader.read_size();
  vector<__cosim_s80__> __xlx_axis_in_tmp_vec;
  while (!((hls::stream<__cosim_s80__>*)__xlx_apatb_param_axis_in)->empty() && __xlx_axis_in_V_tmp_Count < __xlx_axis_in_V_read_Size) {
    __xlx_axis_in_tmp_vec.push_back(((hls::stream<__cosim_s80__>*)__xlx_apatb_param_axis_in)->read());
    __xlx_axis_in_V_tmp_Count++;
  }
  ap_apatb_axis_in_V_cap_bc = __xlx_axis_in_tmp_vec.size();
  // store input buffer
  __cosim_s80__* __xlx_axis_in_input_buffer= new __cosim_s80__[__xlx_axis_in_tmp_vec.size()];
  for (int i = 0; i < __xlx_axis_in_tmp_vec.size(); ++i) {
    __xlx_axis_in_input_buffer[i] = __xlx_axis_in_tmp_vec[i];
  }
  //Create input buffer for axis_out
  ap_apatb_axis_out_V_cap_bc = __xlx_axis_out_V_size_Reader.read_size();
  __cosim_s80__* __xlx_axis_out_input_buffer= new __cosim_s80__[ap_apatb_axis_out_V_cap_bc];
  // DUT call
  myproject(__xlx_axis_in_input_buffer, __xlx_axis_out_input_buffer, __xlx_apatb_param_nimages, __xlx_apatb_param_dest);
  for (unsigned i = 0; i <ap_apatb_axis_out_V_cap_bc; ++i)
    ((hls::stream<__cosim_s80__>*)__xlx_apatb_param_axis_out)->write(__xlx_axis_out_input_buffer[i]);
}
