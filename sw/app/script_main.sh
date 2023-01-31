#!/bin/bash

{
SYS="${1:-1}"
CYT="${2:-1}"
AOS="${3:-1}"
PHYS="${4:-1}"
BIG="${5:-1}"

if [ ! -f "/tmp/aos_daemon.socket" ]; then
	echo "AOS daemon not running"
	exit 1
fi
if [ ! -f "/mnt/nvme0/file3.bin" ]; then
	echo "NVME SSD missing main input files"
	exit 1
fi
if [ ! -f "/mnt/nvme0/large3.bin" ]; then
	echo "NVME SSD missing hls_pgrnk input files"
	exit 1
fi
if [ ! -f "/mnt/nvme0/graph31_3.bin" ]; then
	echo "NVME SSD missing hls_tri input files"
	exit 1
fi

mkdir -p logs
I=0
while [ -f "logs/main_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/main_${I}.log"
touch $LOG

BENCH=(aes conv dnn md5 nw rng sha hls_sha hls_flow hls_hll hls_pgrnk gups hls_tri)
AGFI=(agfi-0704fdf49203b1415 agfi-0de1e651e85a966f8 agfi-02888566899362e4e agfi-0d1fb0e4f3f2fe828 agfi-0383241d22f62a36b agfi-0a61af1de1792a2c4 agfi-01119bac0bf264483 agfi-0e58b18cd59c51593 agfi-0043d13dc8bf4970d agfi-04b2d4ee3b2ba47b0 agfi-0d3be5dce212b307f agfi-07a50babfdecda519 agfi-06549cf85b4de54a7)

for I in {0..12}; do
	echo ${BENCH[I]} >> $LOG
	sudo fpga-load-local-image -S 0 -I ${AGFI[I]} >> $LOG
	for J in {1..1}; do
		./script_${BENCH[I]}.sh $SYS $CYT $AOS $PHYS 0 >> $LOG
		if [[ "$BIG" -eq 1 ]]; then
			./script_${BENCH[I]}.sh $SYS $CYT 0 0 1 >> $LOG
		fi
	done
done
}
