#!/bin/bash

# Cloud-init script for Voters Data Loader EC2 instance
# This script installs all necessary software and runs the database setup
# Timestamp: ${timestamp}

set -e

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

# Start and enable PostgreSQL client services
systemctl enable postgresql15
systemctl start postgresql15

# Create database environment file
echo "Creating database environment file..."
mkdir -p /home/ec2-user/infra/aws/db
cat > /home/ec2-user/infra/aws/db/db-env.sh << 'EOF'
#!/bin/bash
# Database connection environment variables
export PGHOST="${db_host}"
export PGPORT=5432
export PGDATABASE="${db_name}"
export PGUSER="${db_username}"
export PGPASSWORD="${db_password}"
EOF

chmod +x /home/ec2-user/infra/aws/db/db-env.sh

# Clone the project
echo "Cloning the voters project..."
cd /home/ec2-user
git clone https://github.com/pc-dae-voters/voters.git pc-dae-voters
cd pc-dae-voters

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
source infra/aws/db/db-env.sh

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
source infra/aws/db/db-env.sh

echo "Loading data into database..."
./bin/load-data.sh

echo "Data loading completed successfully!"
EOF

chmod +x /home/ec2-user/load-data.sh

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user

# Run the database setup
echo "Running database setup..."
sudo -u ec2-user /home/ec2-user/setup-database.sh

echo "Cloud-init completed successfully!"
echo "Database tables have been created."
echo "To load data, run: /home/ec2-user/load-data.sh" 