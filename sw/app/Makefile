CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -DCONFIG_LOGLEVEL=4 -Wall

LDLIBS = -pthread

HSRC = aos.hpp utils.hpp

BENCHES = aes conv dnn gups hls_flow hls_hll hls_pgrnk hls_sha hls_tri md5 multi nw rng sha cpu_rng

all: $(BENCHES)

aes: $(HSRC) aes.cpp
	$(CC) $(CFLAGS) $(LDLIBS) aes.cpp -o aes

conv: $(HSRC) conv.cpp
	$(CC) $(CFLAGS) $(LDLIBS) conv.cpp -o conv

dnn: $(HSRC) dnn.cpp
	$(CC) $(CFLAGS) $(LDLIBS) dnn.cpp -o dnn

gups: $(HSRC) gups.cpp
	$(CC) $(CFLAGS) $(LDLIBS) gups.cpp -o gups

hls_flow: $(HSRC) hls_flow.cpp
	$(CC) $(CFLAGS) $(LDLIBS) hls_flow.cpp -o hls_flow

hls_hll: $(HSRC) hls_hll.cpp
	$(CC) $(CFLAGS) $(LDLIBS) hls_hll.cpp -o hls_hll

hls_pgrnk: $(HSRC) hls_pgrnk.cpp
	$(CC) $(CFLAGS) $(LDLIBS) hls_pgrnk.cpp -o hls_pgrnk

hls_sha: $(HSRC) hls_sha.cpp
	$(CC) $(CFLAGS) $(LDLIBS) hls_sha.cpp -o hls_sha

hls_tri: $(HSRC) hls_tri.cpp
	$(CC) $(CFLAGS) $(LDLIBS) hls_tri.cpp -o hls_tri

md5: $(HSRC) md5.cpp
	$(CC) $(CFLAGS) $(LDLIBS) md5.cpp -o md5

multi: $(HSRC) multi.cpp
	$(CC) $(CFLAGS) $(LDLIBS) multi.cpp -o multi

nw: $(HSRC) nw.cpp
	$(CC) $(CFLAGS) $(LDLIBS) nw.cpp -o nw

rng: $(HSRC) rng.cpp
	$(CC) $(CFLAGS) $(LDLIBS) rng.cpp -o rng

sha: $(HSRC) sha.cpp
	$(CC) $(CFLAGS) $(LDLIBS) sha.cpp -o sha

cpu_rng: cpu_rng.cpp
	$(CC) $(CFLAGS) $(LDLIBS) cpu_rng.cpp -o cpu_rng

clean:
	rm -f $(BENCHES)

.PHONY: clean
