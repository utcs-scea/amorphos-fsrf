#!/bin/bash

{
echo "Copying files..."
sudo cp inputs/webbase-1M/webbase-1M.bin /mnt/nvme0/small0.bin &
sudo cp inputs/webbase-1M/webbase-1M.bin /mnt/nvme0/small1.bin &
sudo cp inputs/webbase-1M/webbase-1M.bin /mnt/nvme0/small2.bin &
sudo cp inputs/webbase-1M/webbase-1M.bin /mnt/nvme0/small3.bin &

sudo cp inputs/mawi_201512020030/mawi_201512020030.bin /mnt/nvme0/medium0.bin &
sudo cp inputs/mawi_201512020030/mawi_201512020030.bin /mnt/nvme0/medium1.bin &
sudo cp inputs/mawi_201512020030/mawi_201512020030.bin /mnt/nvme0/medium2.bin &
sudo cp inputs/mawi_201512020030/mawi_201512020030.bin /mnt/nvme0/medium3.bin &

sudo cp inputs/GAP-kron/GAP-kron.bin /mnt/nvme0/large0.bin &
sudo cp inputs/GAP-kron/GAP-kron.bin /mnt/nvme0/large1.bin &
sudo cp inputs/GAP-kron/GAP-kron.bin /mnt/nvme0/large2.bin &
sudo cp inputs/GAP-kron/GAP-kron.bin /mnt/nvme0/large3.bin &
wait

echo "Done"
tput bel
}
