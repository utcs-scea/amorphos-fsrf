CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -DCONFIG_LOGLEVEL=4 -Wall

LDLIBS = -pthread

HSRC = aos.hpp utils.hpp

BENCHES = aes aes_strm axis_strm conv dnn gups hls_flow hls_hll hls_pgrnk hls_sha hls_sha_strm hls_tri md5 md5_strm multi nw rng sha strm strm_cfg strm_host strm_p2p strm_p2p2 cpu_rng parse_log

all: $(BENCHES)

$(BENCHES): %: %.cpp $(HSRC)
	$(CC) $(CFLAGS) $(LDLIBS) $< -o $@

clean:
	rm -f $(BENCHES)

.PHONY: clean
