#!/bin/bash

echo "Downloading matrices..."
wget http://sparse-files.engr.tamu.edu/MM/Williams/webbase-1M.tar.gz
wget http://sparse-files.engr.tamu.edu/MM/MAWI/mawi_201512020030.tar.gz
wget http://sparse-files.engr.tamu.edu/MM/GAP/GAP-kron.tar.gz
#wait

echo "Unarchiving..."
tar -xf webbase-1M.tar.gz &
tar -xf mawi_201512020030.tar.gz &
tar -xf GAP-kron.tar.gz &
wait

echo "Cleaning up..."
rm webbase-1M.tar.gz
rm mawi_201512020030.tar.gz
rm GAP-kron.tar.gz

echo "Converting to binary..."
make
./matrix2graph webbase-1M/webbase-1M.mtx webbase-1M/webbase-1M.bin &
./matrix2graph mawi_201512020030/mawi_201512020030.mtx mawi_201512020030/mawi_201512020030.bin 1 &
./matrix2graph GAP-kron/GAP-kron.mtx GAP-kron/GAP-kron.bin 1 &
wait

echo "Done"
tput bel
