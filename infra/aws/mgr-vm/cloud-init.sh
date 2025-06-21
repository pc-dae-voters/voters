#!/bin/bash

# Cloud-init script for Voters Manager EC2 instance
# This script installs all necessary software and runs the database setup
# Timestamp: ${timestamp}

set -e

# Function to mount EBS volume
mount_ebs_volume() {
  # Handle both xvdf and nvme device naming conventions
  if [ -b /dev/nvme1n1 ]; then
    DEVICE="/dev/nvme1n1"
  elif [ -b /dev/xvdf ]; then
    DEVICE="/dev/xvdf"
  else
    return 1
  fi

  MOUNTPOINT="/data"
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

  # Set proper ownership and permissions for ec2-user
  echo "Setting ownership and permissions on $MOUNTPOINT..."
  chown ec2-user:ec2-user $MOUNTPOINT
  chmod 755 $MOUNTPOINT

  # Ensure it is mounted on boot
  if ! grep -q "$DEVICE" /etc/fstab; then
    echo "$DEVICE $MOUNTPOINT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  return 0
}

# Try to mount the volume, but don't fail if it's not available yet
echo "Attempting to mount EBS volume..."
if ! mount_ebs_volume; then
  echo "EBS volume not available yet, will retry via systemd service"
fi

# Update system
echo "Updating system packages..."
yum update -y

# Install required packages
echo "Installing required packages..."
# Remove curl-minimal first to avoid conflicts on ECS-optimized AMI
yum remove -y curl-minimal || true
yum install -y \
    git \
    java-21-amazon-corretto \
    maven \
    python3 \
    python3-pip \
    postgresql15 \
    postgresql15-server \
    postgresql15-contrib \
    unzip \
    wget \
    curl \
    jq \
    --allowerasing

# Clone the project first
echo "Cloning the voters project..."
cd /home/ec2-user
git clone https://github.com/pc-dae-voters/voters.git pc-dae-voters
cd pc-dae-voters

# Create database environment file in the correct location (infra/db/db-env.sh)
echo "Creating database environment file..."
mkdir -p infra/db
cat > infra/db/db-env.sh << 'EOF'
#!/bin/bash
# Database connection environment variables
export PGHOST="${db_host}"
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

# Create a script to run the database setup
echo "Creating database setup script..."
cat > /home/ec2-user/setup-database.sh << 'EOF'
#!/bin/bash
set -e

cd /home/ec2-user/pc-dae-voters

# Source database environment
source infra/db/db-env.sh

echo "Creating database tables..."
./bin/create-tables.sh

echo "Database setup completed successfully!"
EOF

chmod +x /home/ec2-user/setup-database.sh

# Create a script to load data
echo "Creating data loading script..."
cat > /home/ec2-user/load-data.sh << 'EOF'
#!/bin/bash
set -e

cd /home/ec2-user/pc-dae-voters

# Source database environment
source infra/db/db-env.sh

echo "Loading data into database..."
./bin/load-data.sh

echo "Data loading completed successfully!"
EOF

chmod +x /home/ec2-user/load-data.sh

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user

# Create a systemd service to handle delayed setup
echo "Creating delayed setup service..."
cat > /etc/systemd/system/voters-manager.service << 'EOF'
[Unit]
Description=Voters Manager Setup Service
After=network.target
Wants=network.target

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

# Function to mount EBS volume
mount_ebs_volume() {
  # Handle both xvdf and nvme device naming conventions
  if [ -b /dev/nvme1n1 ]; then
    DEVICE="/dev/nvme1n1"
  elif [ -b /dev/xvdf ]; then
    DEVICE="/dev/xvdf"
  else
    return 1
  fi

  MOUNTPOINT="/data"
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

  # Set proper ownership and permissions for ec2-user
  echo "Setting ownership and permissions on $MOUNTPOINT..."
  chown ec2-user:ec2-user $MOUNTPOINT
  chmod 755 $MOUNTPOINT

  # Ensure it is mounted on boot
  if ! grep -q "$DEVICE" /etc/fstab; then
    echo "$DEVICE $MOUNTPOINT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  return 0
}

# Wait for EBS volume to be available (max 5 minutes)
echo "Waiting for EBS volume to be available..."
for i in {1..30}; do
  if mount_ebs_volume; then
    echo "EBS volume mounted successfully!"
    break
  fi
  echo "Attempt $i: EBS volume not available yet, waiting 10 seconds..."
  sleep 10
done

# Run the database setup
echo "Running database setup..."
sudo -u ec2-user /home/ec2-user/setup-database.sh

echo "Delayed setup completed successfully!"
EOF

chmod +x /usr/local/bin/voters-setup-delayed.sh

# Enable and start the service
systemctl enable voters-manager.service
systemctl start voters-manager.service

echo "Cloud-init completed successfully!"
echo "If EBS volume wasn't available, setup will continue via systemd service."
echo "To check status: systemctl status voters-manager.service"
echo "To load data, run: /home/ec2-user/load-data.sh" 