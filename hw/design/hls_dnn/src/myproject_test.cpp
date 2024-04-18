#include <algorithm>
#include <fstream>
#include <iostream>
#include <map>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>

#include "firmware/myproject_axi.h"
#include "firmware/nnet_utils/nnet_helpers.h"

void bitwise_or (int bytes, char *a, char *b) {
    for (int i = 0; i < bytes; i++) {
        *a |= *b;
        a++;
        b++;
    }
}

// hls-fpga-machine-learning insert bram

#define CHECKPOINT 5000

namespace nnet {
    bool trace_enabled = true;
    std::map<std::string, void *> *trace_outputs = NULL;
    size_t trace_type_size = sizeof(double);
} // namespace nnet

int main(int argc, char **argv) {
    // load input data from text file
    std::ifstream fin("tb_data/tb_input_features.dat");
    // load predictions from text file
    std::ifstream fpr("tb_data/tb_output_predictions.dat");

#ifdef RTL_SIM
    std::string RESULTS_LOG = "tb_data/rtl_cosim_results.log";
#else
    std::string RESULTS_LOG = "tb_data/csim_results.log";
#endif
    std::ofstream fout(RESULTS_LOG);

    std::string iline;
    std::string pline;
    int e = 0;

    if (fin.is_open() && fpr.is_open()) {
        while (std::getline(fin, iline) && std::getline(fpr, pline)) {
            if (e % CHECKPOINT == 0)
                std::cout << "Processing input " << e << std::endl;
            char *cstr = const_cast<char *>(iline.c_str());
            char *current;
            std::vector<float> in;
            current = strtok(cstr, " ");
            while (current != NULL) {
                in.push_back(atof(current));
                current = strtok(NULL, " ");
            }
            cstr = const_cast<char *>(pline.c_str());
            std::vector<float> pr;
            current = strtok(cstr, " ");
            while (current != NULL) {
                pr.push_back(atof(current));
                current = strtok(NULL, " ");
            }

            // hls-fpga-machine-learning insert data
            input_axi_t inputs[N_IN];
            nnet::copy_data_axi<float, input_axi_t, 0, N_IN>(in, inputs);
            output_axi_t outputs[N_OUT];

            // hls-fpga-machine-learning insert top-level-function
            myproject_axi(inputs,outputs);
      
            if (e % CHECKPOINT == 0) {
                std::cout << "Predictions" << std::endl;
                // hls-fpga-machine-learning insert predictions
                for(int i = 0; i < N_OUT; i++) {
                    std::cout << pr[i] << " ";
                }
                std::cout << std::endl;
                std::cout << "Quantized predictions" << std::endl;
                // hls-fpga-machine-0learning insert quantized
                nnet::print_result<output_axi_t, N_OUT>(outputs, std::cout, true);
            }
            e++;

            // hls-fpga-machine-learning insert tb-output
            nnet::print_result<output_axi_t, N_OUT>(outputs, fout);
        }
        fin.close();
        fpr.close();
    } else {
        std::cout << "INFO: Unable to open input/predictions file, using default input." << std::endl;

        // hls-fpga-machine-learning insert zero
        input_axi_t inputs[N_IN];
        printf("N_IN is %d\n", N_IN);
        for (int i = 0; i < N_IN; i++) {
            inputs[i].data = 92;
        }
        inputs[N_IN-1].last = 1;
        output_axi_t outputs[N_OUT];
        for (int i = 0; i < N_OUT; i++) {
            outputs[i].data = 0;
        }

        // hls-fpga-machine-learning insert top-level-function
#ifdef USE_MYPROJECT_AXI
        myproject_axi(inputs,outputs);
#else
        //int axiwords_in_input = N_IN / 16; // since 16 floats in a 512 block
        int pixels_in_word = 64;
        int nimages = 100;
        int axiwords_in_input = N_IN / pixels_in_word; // uint8_t

        uint64 words = axiwords_in_input;
        hls::stream<axis512> axis_in;
        hls::stream<axis512> axis_out;

        for (int h = 0; h < nimages; h++) {
            for (int i = 0; i < axiwords_in_input; i++) {
                uint512 word = 0;
                for (int j = 0; j < pixels_in_word; j++) {
                    word((j * 8) + 7, j * 8) = inputs[i * pixels_in_word + j].data;
                }
                axis512 word_;
                word_.data = word;
                axis_in << word_;
            }
        }

        printf("calling myproject...\n");
        myproject(axis_in, axis_out, nimages, 0);
	
        for (int h = 0; h < nimages; h++) {
            for (int i = 0; i < axiwords_in_input; i++) {
                axis512 word_;
                axis_out >> word_;
                if (word_.last) {
                    assert(h == nimages - 1 && i == axiwords_in_input - 1);
                } else {
                    assert(h < nimages - 1 || i < axiwords_in_input - 1);
                }
            }
        }
#endif
      
        // hls-fpga-machine-learning insert output
        //nnet::print_result<output_axi_t, N_OUT>(outputs, std::cout, true);

        // hls-fpga-machine-learning insert tb-output
        //nnet::print_result<output_axi_t, N_OUT>(outputs, fout);
    }

    fout.close();
    std::cout << "INFO: Saved inference results to file: " << RESULTS_LOG << std::endl;

    return 0;
}
