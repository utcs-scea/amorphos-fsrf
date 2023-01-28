#!/bin/bash

{
echo "Writing files..."
sudo touch /mnt/nvme0/file0.bin
sudo touch /mnt/nvme0/file1.bin
sudo touch /mnt/nvme0/file2.bin
sudo touch /mnt/nvme0/file3.bin
sudo shred -n 1 -s 34G /mnt/nvme0/file0.bin &
sudo shred -n 1 -s 34G /mnt/nvme0/file1.bin &
sudo shred -n 1 -s 34G /mnt/nvme0/file2.bin &
sudo shred -n 1 -s 34G /mnt/nvme0/file3.bin &
wait

echo "Done"
tput bel
}
