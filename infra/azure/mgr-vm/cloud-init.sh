#!/bin/bash

# Cloud-init script for Voters Manager Azure VM
# This script installs all necessary software and configures the environment
# Version: ${version}

set -e

# --- Mount Data Disk ---
mount_data_disk() {
  DEVICE=$(find /dev/disk/by-partlabel -name 'LUN10' | head -n 1)
  MOUNTPOINT="/data"

  if [ -z "$DEVICE" ]; then
    echo "Data disk not found. Will retry via systemd service."
    return 1
  fi

  echo "Using device: $DEVICE"

  if ! file -s $DEVICE | grep -q ext4; then
    echo "Formatting $DEVICE as ext4..."
    mkfs.ext4 $DEVICE
  fi

  mkdir -p $MOUNTPOINT
  if ! mount | grep -q "$MOUNTPOINT"; then
    echo "Mounting $DEVICE at $MOUNTPOINT..."
    mount $DEVICE $MOUNTPOINT
  fi

  echo "Setting ownership and permissions on $MOUNTPOINT..."
  chown -R azureuser:azureuser $MOUNTPOINT
  chmod 755 $MOUNTPOINT

  if ! grep -q "$DEVICE" /etc/fstab; then
    echo "$DEVICE $MOUNTPOINT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  return 0
}

# --- Main Setup ---
echo "Starting cloud-init setup..."

# Wait for apt-daily to finish
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
   echo "Waiting for apt-daily to release lock..."
   sleep 5
done

# Update system
echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
    git \
    openjdk-21-jdk \
    maven \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client-14 \
    unzip \
    wget \
    curl \
    jq

# Install Terraform
echo "Installing Terraform..."
cd /tmp
wget "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
unzip "terraform_${terraform_version}_linux_amd64.zip"
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm "terraform_${terraform_version}_linux_amd64.zip"
terraform --version
echo "Terraform installed successfully!"

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
echo "Azure CLI installed successfully!"

# --- Project Setup ---
USER_HOME="/home/azureuser"
cd $USER_HOME

# Clone the project
echo "Cloning the voters project..."
git clone https://github.com/pc-dae-voters/voters.git pc-dae-voters
cd pc-dae-voters

# Create database environment file
echo "Creating database environment file..."
mkdir -p infra/db
cat > infra/db/db-env.sh << 'EOF'
#!/bin/bash
export PGHOST="${db_host}.postgres.database.azure.com"
export PGPORT=5432
export PGDATABASE="${db_name}"
export PGUSER="${db_username}"
export PGPASSWORD='${db_password}'
EOF

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install psycopg2-binary

# Create data loading script
echo "Creating data loading script..."
cat > $USER_HOME/load-data.sh << 'EOF'
#!/bin/bash
set -e
cd $USER_HOME/pc-dae-voters
source infra/db/db-env.sh
CON_CSV="$${CON_CSV:-/data/parl_constituencies_2025.csv}"
CON_POSTCODES_CSV="$${CON_POSTCODES_CSV:-/data/postcodes_with_con.csv}"
ADDRESSES_FOLDER="$${ADDRESSES_FOLDER:-/data/addresses}"
NAMES_FOLDER="$${NAMES_FOLDER:-/data/names/data}"
NUM_PEOPLE="$${NUM_PEOPLE:-10000}"
RANDOM_SEED="$${RANDOM_SEED:-12345}"
echo "Loading data into database..."
./bin/load-data.sh \
  --con-csv "$CON_CSV" \
  --con-postcodes-csv "$CON_POSTCODES_CSV" \
  --addresses-folder "$ADDRESSES_FOLDER" \
  --names-folder "$NAMES_FOLDER" \
  --num-people "$NUM_PEOPLE" \
  --random-seed "$RANDOM_SEED"
echo "Data loading completed successfully!"
EOF
chmod +x $USER_HOME/load-data.sh

# Set ownership
chown -R azureuser:azureuser $USER_HOME

# --- Systemd Service for Delayed Setup ---
echo "Creating delayed setup service..."
cat > /etc/systemd/system/voters-manager.service << 'EOF'
[Unit]
Description=Voters Manager Delayed Setup Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/voters-setup-delayed.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create the delayed setup script
cat > /usr/local/bin/voters-setup-delayed.sh << 'EOF'
#!/bin/bash
# Function to mount data disk, retrying until available
mount_data_disk_retry() {
  for i in {1..30}; do
    DEVICE=$(find /dev/disk/by-partlabel -name 'LUN10' | head -n 1)
    if [ -n "$DEVICE" ]; then
      echo "Data disk found at $DEVICE"
      mount_data_disk
      return 0
    fi
    echo "Attempt $i: Data disk not available yet, waiting 10 seconds..."
    sleep 10
  done
  echo "Failed to find data disk after 5 minutes."
  return 1
}
mount_data_disk_retry
EOF
chmod +x /usr/local/bin/voters-setup-delayed.sh

# Enable and start the service
systemctl enable voters-manager.service
systemctl start voters-manager.service

# We need to wait for the disk to be attached and available.
# The disk is attached at LUN 10 as specified in the Terraform config.
# SCSI devices can be slow to show up, so we'll wait for it.
DATA_DISK=""
for i in {1..30}; do
    if [[ -e /dev/disk/by-id/scsi-0HC_Azure_Serial-voters-data-disk-lun10 ]]; then
        DATA_DISK="/dev/disk/by-id/scsi-0HC_Azure_Serial-voters-data-disk-lun10"
        break
    fi
    sleep 5
done

if [[ -z "$DATA_DISK" ]]; then
    echo "Data disk was not found after 150 seconds. Aborting."
    exit 1
fi

# Partition and format the data disk
parted "$DATA_DISK" --script mklabel gpt mkpart xfspart xfs 0% 100%
mkfs.xfs -f "$${DATA_DISK}-part1"

# Mount the data disk
mkdir -p /mnt/data
mount "$${DATA_DISK}-part1" /mnt/data
echo "$${DATA_DISK}-part1 /mnt/data xfs defaults,nofail 0 2" >> /etc/fstab

# Create the target directory for data uploads on the mounted disk and set permissions
mkdir -p /mnt/data/uploads
chown -R azureuser:azureuser /mnt/data/uploads
ln -s /mnt/data/uploads /data

# --- Install Docker ---
# Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings

echo "Cloud-init completed successfully!"
echo "If data disk wasn't available, setup will continue via systemd service."
echo "To check status: systemctl status voters-manager.service"
echo "To load data, run: $USER_HOME/load-data.sh"
