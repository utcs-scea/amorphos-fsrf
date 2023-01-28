#!/bin/bash

{
SYS="${1:-1}"
CYT="${2:-1}"
AOS="${3:-1}"
PHYS="${4:-1}"
#BIG="${5:-0}"

mkdir -p logs
I=0
while [ -f "logs/main_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/main_${I}.log"
touch $LOG

BENCH=(aes dnn md5 nw rng sha hls_sha hls_flow hls_hll hls_pgrnk gups)
AGFI=(agfi-0704fdf49203b1415 agfi-02888566899362e4e agfi-0d1fb0e4f3f2fe828 agfi-0383241d22f62a36b agfi-0a61af1de1792a2c4 agfi-01119bac0bf264483 agfi-0e58b18cd59c51593 agfi-0043d13dc8bf4970d agfi-04b2d4ee3b2ba47b0 agfi-0d3be5dce212b307f agfi-07a50babfdecda519)

for I in {0..10}; do
	echo ${BENCH[I]} >> $LOG
	sudo fpga-load-local-image -S 0 -I ${AGFI[I]} >> $LOG
	for J in {1..1}; do
		./script_${BENCH[I]}.sh $SYS $CYT $AOS $PHYS 0 >> $LOG
		./script_${BENCH[I]}.sh $SYS $CYT 0 0 1 >> $LOG
	done
done
}
