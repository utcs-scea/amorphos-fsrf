#!/bin/bash

sudo killall -q daemon
make -s
sudo ./daemon
