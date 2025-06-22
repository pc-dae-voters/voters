#!/bin/bash

# Cloud-init script for Voters Manager EC2 instance
# This script installs all necessary software and runs the database setup
# Version: ${version}

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

# Install Terraform
echo "Installing Terraform..."
TERRAFORM_VERSION="1.7.0"
TERRAFORM_ZIP="terraform_1.7.0_linux_amd64.zip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip"

cd /tmp
wget "$TERRAFORM_URL"
unzip "$TERRAFORM_ZIP"
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm "$TERRAFORM_ZIP"

# Verify Terraform installation
echo "Verifying Terraform installation..."
terraform version

echo "Terraform 1.7.0 installed successfully!"

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
AWSCLI_ZIP="awscliv2.zip"
AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

cd /tmp
wget "$AWSCLI_URL" -O "$AWSCLI_ZIP"
unzip "$AWSCLI_ZIP"
./aws/install
rm -rf aws "$AWSCLI_ZIP"

# Verify AWS CLI installation
echo "Verifying AWS CLI installation..."
aws --version

echo "AWS CLI v2 installed successfully!"

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