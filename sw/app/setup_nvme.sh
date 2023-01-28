#!/bin/bash

{
echo "Creating XFS file system..."
sudo mkfs.xfs /dev/nvme0n1

echo "Mounting file system..."
sudo mkdir -p /mnt/nvme0
sudo mount -t xfs /dev/nvme0n1 /mnt/nvme0/

echo "Done"
}
