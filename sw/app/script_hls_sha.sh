#!/bin/bash

{
BENCH=hls_sha
APPS=4

SYS="${1:-1}"
CYT="${2:-1}"
AOS="${3:-1}"
PHYS="${4:-1}"
BIG="${5:-0}"

mkdir -p logs
I=0
while [ -f "logs/${BENCH}_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/${BENCH}_${I}.log"
touch $LOG

LENS=(19 25)
POPS=(0 0 1)
if [[ "$BIG" -eq 1 ]]; then
	LENS=(29)
	POPS=(0 0)
fi

for LEN in ${LENS[@]}; do
	# System
	if [[ "$SYS" -eq 1 ]]; then
		sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
		for POP in ${POPS[@]}; do
			echo "./$BENCH $LEN $APPS $POP 0 0" >> $LOG
			./$BENCH $LEN $APPS $POP 0 0 >> $LOG
		done
		sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
		for POP in ${POPS[@]}; do
			echo "./$BENCH $LEN $APPS $POP 1 2" >> $LOG
			./$BENCH $LEN $APPS $POP 1 2 >> $LOG
		done
	fi
	
	# Coyote
	if [[ "$CYT" -eq 1 ]]; then
		for CFG in 0 1; do
			sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
			for POP in ${POPS[@]}; do
				echo "./$BENCH $LEN $APPS $POP 1 $CFG" >> $LOG
				./$BENCH $LEN $APPS $POP 1 $CFG >> $LOG
			done
		done
	fi
	
	# AOS
	if [[ "$AOS" -eq 1 ]]; then
		for CFG in 0 1; do
			sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
			for POP in ${POPS[@]}; do
				echo "./$BENCH $LEN $APPS $POP 4 $CFG" >> $LOG
				./$BENCH $LEN $APPS $POP 4 $CFG >> $LOG
			done
		done
	fi
	
	# Physical
	if [[ "$PHYS" -eq 1 ]]; then
		echo "./$BENCH $LEN $APPS 1 2 0" >> $LOG
		./$BENCH $LEN $APPS 1 2 0 >> $LOG
	fi
done

grep "e2e" $LOG | awk '{ print $4, $5, $6, $7, $8, $9, $10 }'
}
