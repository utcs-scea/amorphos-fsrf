#!/bin/bash

{
echo "Copying files..."
sudo cp inputs/graph25.bin /mnt/nvme0/graph25_0.bin &
sudo cp inputs/graph25.bin /mnt/nvme0/graph25_1.bin &
sudo cp inputs/graph25.bin /mnt/nvme0/graph25_2.bin &
sudo cp inputs/graph25.bin /mnt/nvme0/graph25_3.bin &

sudo cp inputs/graph31.bin /mnt/nvme0/graph31_0.bin &
sudo cp inputs/graph31.bin /mnt/nvme0/graph31_1.bin &
sudo cp inputs/graph31.bin /mnt/nvme0/graph31_2.bin &
sudo cp inputs/graph31.bin /mnt/nvme0/graph31_3.bin &
wait

echo "Done"
tput bel
}
