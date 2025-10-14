#!/bin/bash
set -ex
exec > /tmp/post-init-debug.log 2>&1

echo ">>> Starting post-init setup script..."

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y xfsprogs parted

LUN=10
DATA_DISK=""
for i in {1..30}; do
    for disk_path in /sys/class/scsi_disk/*; do
        # We must use a subshell here, there is no other way
        if (($(cat "$disk_path/device/lun") == "$LUN")); then
            # This is the most reliable way to get the block device name
            DATA_DISK="/dev/$(ls "$disk_path/device/block/")"
            echo ">>> Found disk with LUN $LUN at $DATA_DISK"
            break 2
        fi
    done
    sleep 5
done

if [[ -z "$DATA_DISK" ]]; then
    echo ">>> CRITICAL: Data disk was not found. Aborting."
    exit 1
fi

parted "$DATA_DISK" --script mklabel gpt mkpart primary xfs 0% 100%
sleep 5
PARTITION="${DATA_DISK}1"
mkfs.xfs -f "$PARTITION"
mkdir -p /mnt/data
mount "$PARTITION" /mnt/data
echo "$PARTITION /mnt/data xfs defaults,nofail 0 2" >> /etc/fstab
mkdir -p /mnt/data/uploads
chown -R azureuser:azureuser /mnt/data

echo ">>> Post-init setup script finished successfully."
