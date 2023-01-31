CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -Wall

all: graphgen matrix2graph

graphgen: graphgen.cpp
	$(CC) $(CFLAGS) graphgen.cpp -o graphgen

matrix2graph: matrix2graph.cpp
	$(CC) $(CFLAGS) matrix2graph.cpp -o matrix2graph

clean:
	rm -f graphgen matrix2graph

.PHONY: clean
