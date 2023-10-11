CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -DCONFIG_LOGLEVEL=4 -Wall

LDLIBS = -pthread

HSRC = aos.hpp utils.hpp

BENCHES = aes axis_strm conv dnn gups hls_flow hls_hll hls_pgrnk hls_sha hls_tri md5 multi nw rng sha strm strm_host strm_p2p strm_p2p2 cpu_rng

all: $(BENCHES)

$(BENCHES): %: %.cpp $(HSRC)
	$(CC) $(CFLAGS) $(LDLIBS) $< -o $@

clean:
	rm -f $(BENCHES)

.PHONY: clean
