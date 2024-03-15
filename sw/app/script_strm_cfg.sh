#!/bin/bash

{
BENCH=strm_cfg

mkdir -p logs
I=0
while [ -f "logs/${BENCH}_${I}.log" ]; do
	I=$((I+1))
done
LOG="logs/${BENCH}_${I}.log"
touch $LOG

APPS_I=(1 2 4 8 16 32)
APPS_P=(2 4 8 16)
APPS_C=(2 4)

for APPS in ${APPS_I[@]}; do
	sudo ./$BENCH 0 2 $APPS >> $LOG
done

for APPS in ${APPS_P[@]}; do
	sudo ./$BENCH 0 1 $APPS >> $LOG
done

for APPS in ${APPS_C[@]}; do
	sudo ./$BENCH 0 0 $APPS >> $LOG
done

grep "e2e" $LOG | awk '{ print $5, $6 }'
}
