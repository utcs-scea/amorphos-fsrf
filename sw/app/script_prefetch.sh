#!/bin/bash

{
BENCH=md5
APPS=4

mkdir -p logs
I=0
while [ -f "logs/prefetch_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/prefetch_${I}.log"
touch $LOG

for FETCH in {0..12}; do
	for LEN in 19 25 29; do
		sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
		for POP in 0 0; do
			echo "./$BENCH $LEN $APPS $POP 0 0 $FETCH" >> $LOG
			./$BENCH $LEN $APPS $POP 0 0 $FETCH >> $LOG
		done
	done
done

grep "e2e" $LOG | awk '{ print $4, $5, $6, $7, $8, $9, $10 }'
}
