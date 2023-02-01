#!/bin/bash

{
BENCH=rng
APPS=4

mkdir -p logs
I=0
while [ -f "logs/access_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/access_${I}.log"
touch $LOG

sudo fpga-load-local-image -S 0 -I agfi-0a61af1de1792a2c4 >> $LOG

for SEQ in 0 1; do
	for RW in 1 2; do
		for LEN in {0..11}; do
			echo "./$BENCH $APPS $RW $LEN $SEQ 1 0 0" >> $LOG
			./$BENCH $RW $LEN $SEQ $APPS 0 0 0 > /dev/null
			./$BENCH $RW $LEN $SEQ $APPS 1 0 0 >> $LOG
		done
	done
done
for SEQ in 0 1; do
	for RW in 1 2; do
		for LEN in {0..11}; do
			echo "./$BENCH $APPS $RW $LEN $SEQ 1 1 2" >> $LOG
			./$BENCH $RW $LEN $SEQ $APPS 0 1 2 > /dev/null
			./$BENCH $RW $LEN $SEQ $APPS 1 1 2 >> $LOG
		done
	done
done

grep "e2e" $LOG | awk '{ print $4, $5, $6, $7, $8, $9, $10 }'
}
