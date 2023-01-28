#!/bin/bash

{
mkdir -p logs
I=0
while [ -f "logs/multi_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/multi_${I}.log"
touch $LOG

echo "rng" >> $LOG
sudo fpga-load-local-image -S 0 -I agfi-0a61af1de1792a2c4 >> $LOG
for I in {0..4}; do
	echo "./rng 1 6 0 1 1 0 0" >> $LOG
	./rng 1 6 0 1 1 0 0 >> $LOG
	echo "./rng 1 6 0 1 1 1 0" >> $LOG
	./rng 1 6 0 1 1 1 0 >> $LOG
	echo "./rng 1 6 0 1 1 1 1" >> $LOG
	./rng 1 6 0 1 1 1 1 >> $LOG
	echo "./rng 1 6 0 1 1 4 0" >> $LOG
	./rng 1 6 0 1 1 4 0 >> $LOG
	echo "./rng 1 6 0 1 1 4 1" >> $LOG
	./rng 1 6 0 1 1 4 1 >> $LOG
	echo "./rng 1 6 0 1 1 2 0" >> $LOG
	./rng 1 6 0 1 1 2 0 >> $LOG
done

echo "hls_sha" >> $LOG
sudo fpga-load-local-image -S 0 -I agfi-0e58b18cd59c51593 >> $LOG
for I in {0..4}; do
	echo "./hls_sha 25 1 1 1 2" >> $LOG
	./hls_sha 25 1 1 1 2 >> $LOG
	echo "./hls_sha 25 1 1 1 0" >> $LOG
	./hls_sha 25 1 1 1 0 >> $LOG
	echo "./hls_sha 25 1 1 1 1" >> $LOG
	./hls_sha 25 1 1 1 1 >> $LOG
	echo "./hls_sha 25 1 1 4 0" >> $LOG
	./hls_sha 25 1 1 4 0 >> $LOG
	echo "./hls_sha 25 1 1 4 1" >> $LOG
	./hls_sha 25 1 1 4 1 >> $LOG
	echo "./hls_sha 25 1 1 2 0" >> $LOG
	./hls_sha 25 1 1 2 0 >> $LOG
done

echo "hls_pgrnk" >> $LOG
sudo fpga-load-local-image -S 0 -I agfi-0d3be5dce212b307f >> $LOG
for I in {0..4}; do
	echo "./hls_pgrnk 68863488 143415296 2 1 1 1 2" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 1 2 >> $LOG
	echo "./hls_pgrnk 68863488 143415296 2 1 1 1 0" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 1 0 >> $LOG
	echo "./hls_pgrnk 68863488 143415296 2 1 1 1 1" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 1 1 >> $LOG
	echo "./hls_pgrnk 68863488 143415296 2 1 1 4 0" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 4 0 >> $LOG
	echo "./hls_pgrnk 68863488 143415296 2 1 1 4 1" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 4 1 >> $LOG
	echo "./hls_pgrnk 68863488 143415296 2 1 1 2 0" >> $LOG
	./hls_pgrnk 68863488 143415296 2 1 1 2 0 >> $LOG
done

echo "aes" >> $LOG
sudo fpga-load-local-image -S 0 -I agfi-0704fdf49203b1415 >> $LOG
for I in {0..4}; do
	echo "./aes 24 1 1 1 2" >> $LOG
	./aes 24 1 1 1 2 >> $LOG
	echo "./aes 24 1 1 1 0" >> $LOG
	./aes 24 1 1 1 0 >> $LOG
	echo "./aes 24 1 1 1 1" >> $LOG
	./aes 24 1 1 1 1 >> $LOG
	echo "./aes 24 1 1 4 0" >> $LOG
	./aes 24 1 1 4 0 >> $LOG
	echo "./aes 24 1 1 4 1" >> $LOG
	./aes 24 1 1 4 1 >> $LOG
	echo "./aes 24 1 1 2 0" >> $LOG
	./aes 24 1 1 2 0 >> $LOG
done

echo "multi" >> $LOG
sudo fpga-load-local-image -S 0 -I agfi-0f8a3b6bcbfeb2a7b >> $LOG
for I in {0..4}; do
	echo "./multi 0 1" >> $LOG
	./multi 0 1 >> $LOG
	echo "./multi 1 0" >> $LOG
	./multi 1 0 >> $LOG
	echo "./multi 1 1" >> $LOG
	./multi 1 1 >> $LOG
	echo "./multi 4 0" >> $LOG
	./multi 4 0 >> $LOG
	echo "./multi 4 1" >> $LOG
	./multi 4 1 >> $LOG
	echo "./multi 2 0" >> $LOG
	./multi 2 0 >> $LOG
done
}
