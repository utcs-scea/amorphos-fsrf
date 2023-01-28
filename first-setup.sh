#!/bin/bash

echo "Installing AWS dependencies..."
sudo pip install boto3==1.16

echo "Setting up AWS FPGA repo..."
cd /home/centos/src/project_data/
git clone https://github.com/aws/aws-fpga.git
cd aws-fpga/
git checkout f29834c1dc98d5e4bab5f84eb4d9fe1430580fa7
source sdk_setup.sh
source hdk_setup.sh
cd ..

echo "Setting up FSRF repo..."
git clone https://github.com/utcs-scea/amorphos-fsrf.git fsrf
cd fsrf
cd sw/daemon/
make
cd ../app/
make
cd inputs/
./get_data.sh
cd /home/centos/src/project_data/

echo "Enabling FPGA DMA..."
sudo setpci -v -s 0000:00:1d.0 COMMAND=06
sudo setpci -v -s 0000:00:1b.0 COMMAND=06

echo "Done"
