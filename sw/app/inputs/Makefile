CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -Wall

all: matrix2graph

matrix2graph: matrix2graph.cpp
	$(CC) $(CFLAGS) $(LDLIBS) $(HSRC) matrix2graph.cpp -o matrix2graph

clean:
	rm -f matrix2graph

.PHONY: clean
