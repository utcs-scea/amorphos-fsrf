#!/bin/bash

{
BENCH=hls_pgrnk
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

ARGS=(1000448 3105792 1 68863488 143415296 2 134217728 4223264768 3)
OFFS=(0 3)
POPS=(0 0 1)
if [[ "$BIG" -eq 1 ]]; then
	OFFS=(6)
	POPS=(0 0)
fi

for I in ${OFFS[@]}; do
	LEN0=${ARGS[$I]}
	LEN1=${ARGS[$I+1]}
	FSEL=${ARGS[$I+2]}
	
	# System
	if [[ "$SYS" -eq 1 ]]; then
		sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
		for POP in ${POPS[@]}; do
			echo "./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 0 0" >> $LOG
			./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 0 0 >> $LOG
		done
		sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
		for POP in ${POPS[@]}; do
			echo "./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 1 2" >> $LOG
			./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 1 2 >> $LOG
		done
	fi
	
	# Coyote
	if [[ "$CYT" -eq 1 ]]; then
		for CFG in 0 1; do
			sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
			for POP in ${POPS[@]}; do
				echo "./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 1 $CFG" >> $LOG
				./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 1 $CFG >> $LOG
			done
		done
	fi
	
	# AOS
	if [[ "$AOS" -eq 1 ]]; then
		for CFG in 0 1; do
			sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
			for POP in ${POPS[@]}; do
				echo "./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 4 $CFG" >> $LOG
				./$BENCH $LEN0 $LEN1 $FSEL $APPS $POP 4 $CFG >> $LOG
			done
		done
	fi
	
	# Physical
	if [[ "$PHYS" -eq 1 ]]; then
		echo "./$BENCH $LEN0 $LEN1 $FSEL $APPS 1 2 0" >> $LOG
		./$BENCH $LEN0 $LEN1 $FSEL $APPS 1 2 0 >> $LOG
	fi
done

grep "e2e" $LOG | awk '{ print $4, $5, $6, $7, $8, $9, $10 }'
}
