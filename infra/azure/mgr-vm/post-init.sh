#!/bin/bash
# This script contains the main setup logic for the manager VM.
# It is downloaded and executed by the main cloud-init script.

# Exit immediately if a command exits with a non-zero status, and print commands as they are executed.
set -ex

# Log everything to a file for debugging.
exec > /tmp/post-init-debug.log 2>&1

echo ">>> Starting post-init setup script..."

# --- Disk Management ---
echo ">>> Starting disk management..."

# Install tools for disk formatting
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y xfsprogs parted

# Find, partition, format, and mount the data disk
LUN=10
DATA_DISK=""
for i in {1..30}; do
    for disk_path in /sys/class/scsi_disk/*; do
        if [ "$$(cat $$disk_path/device/lun)" -eq "$LUN" ]; then
            # Use the most portable method possible to get the block device name, avoiding all nested command substitution
            read -r DEVICE_NAME < <(ls "$$disk_path/device/block/")
            DATA_DISK="/dev/$$DEVICE_NAME"
            echo ">>> Found disk with LUN $LUN at $$DATA_DISK"
            break 2
        fi
    done
    sleep 5
done

if [[ -z "$DATA_DISK" ]]; then
    echo ">>> CRITICAL: Data disk was not found after 150 seconds. Aborting."
    exit 1
fi

parted "$DATA_DISK" --script mklabel gpt mkpart primary xfs 0% 100%
sleep 5
PARTITION="${DATA_DISK}1"
mkfs.xfs -f "$PARTITION"
echo ">>> Disk formatted."

mkdir -p /mnt/data
mount "$PARTITION" /mnt/data
echo "$PARTITION /mnt/data xfs defaults,nofail 0 2" >> /etc/fstab
echo ">>> Disk mounted."

mkdir -p /mnt/data/uploads
chown -R azureuser:azureuser /mnt/data
echo ">>> Upload directory created and permissions set."

echo ">>> Disk management complete."

# Any other setup steps (like installing Docker, cloning repos, etc.) would go here.

echo ">>> Post-init setup script finished successfully."
