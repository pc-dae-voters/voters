#cloud-config
# The runcmd module ensures commands are run late in the boot process, after networking is up.
runcmd:
  - apt-get update

#!/bin/bash
# This script is executed by cloud-init on the manager VM at first boot.
# It installs all necessary software, configures the environment, and starts the manager service.

# --- Logging ---
# Log everything from the very beginning to ensure we can debug any step.
exec > /var/log/cloud-init-voters-debug.log 2>&1
# Exit immediately if a command exits with a non-zero status, and print commands as they are executed.
set -ex

echo ">>> Starting cloud-init script. Version: ${version}"

# --- Initial Setup & Prerequisites ---
echo ">>> Installing prerequisites..."
# apt-get update is now handled by the runcmd module above to ensure network is ready.
for i in {1..5}; do
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq git xfsprogs parted && break
  echo "apt-get install failed (attempt $i of 5), retrying in 5 seconds..."
  sleep 5
done

# --- Set Environment Variables ---
echo ">>> Setting environment variables..."
export DB_HOST="${db_host}"
export DB_NAME="${db_name}"
export DB_USERNAME="${db_username}"
export DB_PASSWORD="${db_password}"

# --- Systemd Service for Manager ---
echo ">>> Creating systemd service for the manager..."
cat > /etc/systemd/system/voters-manager.service <<EOF
[Unit]
Description=Voters Project Manager Service
After=network.target

[Service]
User=azureuser
Group=azureuser
WorkingDirectory=/home/azureuser/voters
ExecStart=/home/azureuser/voters/bin/run-voters-manager.sh
Restart=always
Environment="DB_HOST=${db_host}"
Environment="DB_NAME=${db_name}"
Environment="DB_USERNAME=${db_username}"
Environment="DB_PASSWORD=${db_password}"

[Install]
WantedBy=multi-user.target
EOF

# --- Disk Management ---
echo ">>> Starting disk management..."

# Use LUN to find the right disk, which is the most reliable method on Azure
LUN=10
DATA_DISK=""
echo ">>> Waiting for data disk with LUN $LUN to appear..."
for i in {1..30}; do
    # Use a glob pattern for maximum portability, avoiding command substitution
    for disk_path in /sys/class/scsi_disk/*; do
        if [ "$$(cat $$disk_path/device/lun)" -eq "$LUN" ]; then
            DEVICE_NAME=$$(basename $$disk_path)
            # Use a simple glob to get the block device name, avoiding ls
            DATA_DISK="/dev/$$(basename $$(ls -d $$disk_path/device/block/* | head -n 1))"
            echo ">>> Found disk with LUN $LUN at $$DATA_DISK"
            break 2
        fi
    done
    sleep 5
done

if [[ -z "$DATA_DISK" ]]; then
    echo ">>> CRITICAL: Data disk with LUN $LUN was not found after 150 seconds. Aborting."
    ls -l /dev/disk/by-id/
    exit 1
fi

# Partition and format the data disk
echo ">>> Partitioning and formatting $$DATA_DISK..."
parted "$$DATA_DISK" --script mklabel gpt mkpart primary xfs 0% 100%
sleep 5 # Give a moment for the partition to be recognized by the kernel
PARTITION="$$DATA_DISK""1"
mkfs.xfs -f "$$PARTITION"
echo ">>> Disk formatted."

# Mount the data disk
echo ">>> Mounting the data disk..."
mkdir -p /mnt/data
mount "$$PARTITION" /mnt/data
echo "$$PARTITION /mnt/data xfs defaults,nofail 0 2" >> /etc/fstab
echo ">>> Disk mounted."

# Create the target directory for data uploads on the mounted disk and set permissions
echo ">>> Creating upload directory and setting permissions..."
mkdir -p /mnt/data/uploads
chown -R azureuser:azureuser /mnt/data
ln -s /mnt/data/uploads /data
echo ">>> Upload directory created."

# --- Install Docker ---
echo ">>> Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker azureuser

# --- Install Terraform ---
echo ">>> Installing Terraform..."
TERRAFORM_VERSION="${terraform_version}"
TERRAFORM_ZIP="terraform_$${TERRAFORM_VERSION}_linux_amd64.zip"
wget "https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/$${TERRAFORM_ZIP}"
unzip "$${TERRAFORM_ZIP}"
mv terraform /usr/local/bin/
rm "$${TERRAFORM_ZIP}"

# --- Clone Project Repository ---
echo ">>> Cloning project repository..."
cd /home/azureuser
git clone https://github.com/pc-dae/voters.git
chown -R azureuser:azureuser voters

# --- Finalize Setup ---
echo ">>> Finalizing setup and starting services..."
# Create db-env.sh from environment variables for scripts that need it
cat > /home/azureuser/voters/db-env.sh <<EOF
export DB_HOST=${db_host}
export DB_NAME=${db_name}
export DB_USERNAME=${db_username}
export DB_PASSWORD=${db_password}
EOF
chown azureuser:azureuser /home/azureuser/voters/db-env.sh

# Enable and start the manager service
systemctl daemon-reload
systemctl enable voters-manager.service
systemctl start voters-manager.service

echo ">>> Cloud-init script completed successfully!"
