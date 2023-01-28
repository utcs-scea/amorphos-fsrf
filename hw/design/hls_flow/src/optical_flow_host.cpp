/*===============================================================*/
/*                                                               */
/*                    optical_flow_host.cpp                      */
/*                                                               */
/*      Main host function for the Optical Flow application.     */
/*                                                               */
/*===============================================================*/

// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>

// other headers
#include "typedefs.h"
#include "check_result.h"

int main(int argc, char **argv)
{
  printf("Optical Flow Application\n");

  // parse command line arguments
  std::string dataPath("./data");
  std::string outFile("./data/out.flo");

  // create actual file names according to the datapath
  std::string frame_files[5];
  std::string reference_file;
  frame_files[0] = dataPath + "/frame1.ppm";
  frame_files[1] = dataPath + "/frame2.ppm";
  frame_files[2] = dataPath + "/frame3.ppm";
  frame_files[3] = dataPath + "/frame4.ppm";
  frame_files[4] = dataPath + "/frame5.ppm";
  reference_file = dataPath + "/ref.flo";

  // read in images and convert to grayscale
  printf("Reading input files ... \n");

  CByteImage imgs[5];
  for (int i = 0; i < 5; i++) 
  {
    CByteImage tmpImg;
    ReadImage(tmpImg, frame_files[i].c_str());
    imgs[i] = ConvertToGray(tmpImg);
  }

  // read in reference flow file
  printf("Reading reference output flow... \n");

  CFloatImage refFlow;
  ReadFlowFile(refFlow, reference_file.c_str());

  // timers
  struct timeval start, end;

  // arrays for compute
  // inputs
  frames_t* frames2 = new frames_t[2 * MAX_HEIGHT * MAX_WIDTH];
  frames_t* frames = frames2;// + MAX_HEIGHT * MAX_WIDTH;
  // output
  velocity_t* outputs2 = new velocity_t[2 * MAX_HEIGHT * MAX_WIDTH];
  velocity_t* outputs = outputs2;// + MAX_HEIGHT * MAX_WIDTH;
 
  // pack the values
  for (int i = 0; i < MAX_HEIGHT; i++) 
  {
    for (int j = 0; j < MAX_WIDTH; j++)
    {
      frames2[i*MAX_WIDTH+j] = 0;
      frames[i*MAX_WIDTH+j]( 7,  0) = imgs[0].Pixel(j%1024, i%436, 0);
      frames[i*MAX_WIDTH+j](15,  8) = imgs[1].Pixel(j%1024, i%436, 0);
      frames[i*MAX_WIDTH+j](23, 16) = imgs[2].Pixel(j%1024, i%436, 0);
      frames[i*MAX_WIDTH+j](31, 24) = imgs[3].Pixel(j%1024, i%436, 0);
      frames[i*MAX_WIDTH+j](39, 32) = imgs[4].Pixel(j%1024, i%436, 0);
      frames[i*MAX_WIDTH+j](63, 40) = 0;
    }
  }

  // run
  gettimeofday(&start, NULL);
  const uint64_t n = 1;
  optical_flow(frames2, outputs2, n);
  gettimeofday(&end, NULL);

  // check results
  printf("Checking results:\n");
  check_results(outputs, refFlow, outFile);

  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);

  // cleanup
  delete []frames2;
  delete []outputs2;

  return EXIT_SUCCESS;

}
