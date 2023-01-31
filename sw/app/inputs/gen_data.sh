#!/bin/bash

make

echo "Generating graph25..."
./graphgen 20 25
mv graph.bin graph25.bin
mv params.txt params25.txt

echo "Generating graph31..."
./graphgen 20 31
mv graph.bin graph31.bin
mv params.txt params31.txt

echo "Done"
tput bel
