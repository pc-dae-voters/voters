#!/usr/bin/env bash

# AWS Infrastructure Setup Script
# This script automates the complete initial setup of the Voters project AWS infrastructure
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Functions ---
function usage() {
    echo "usage: ${0} [options]" >&2
    echo "This script automates the complete initial setup of the Voters project AWS infrastructure." >&2
    echo
    echo "Options:"
    echo "  --help                Display this help message."
    echo "  --skip-data-upload    Skip the data upload step."
    echo "  --skip-data-load      Skip the data loading step."
    echo "  --skip-eks            Skip the EKS cluster creation."
    echo "  --debug               Enable debug mode (set -x)."
    exit 1
}

function log_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

function log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# --- Argument Parsing ---
SKIP_DATA_UPLOAD=false
SKIP_DATA_LOAD=false
SKIP_EKS=false
DEBUG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            usage
            ;;
        --skip-data-upload)
            SKIP_DATA_UPLOAD=true
            shift
            ;;
        --skip-data-load)
            SKIP_DATA_LOAD=true
            shift
            ;;
        --skip-eks)
            SKIP_EKS=true
            shift
            ;;
        --debug)
            set -x
            DEBUG=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

# --- Validation ---
echo -e "${BLUE}=== AWS Infrastructure Setup ===${NC}"
echo "This script will set up the complete Voters project AWS infrastructure."
echo ""

# Check if we're in the right directory
if [[ ! -f "bin/do-terraform.sh" ]]; then
    log_error "This script must be run from the voters directory (where bin/do-terraform.sh exists)"
    exit 1
fi

# Source AWS session configuration
log_step "Setting up AWS environment"
if [[ -f "infra/aws/session.sh" ]]; then
    echo "Sourcing AWS session configuration..."
    source infra/aws/session.sh
    log_success "AWS session configuration loaded"
else
    log_warning "AWS session configuration file not found at infra/aws/session.sh"
fi

# Check if AWS credentials are available
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "AWS credentials not found or invalid after sourcing session.sh"
    log_error "Please ensure your AWS credentials are properly configured"
    exit 1
fi

# Show current AWS identity
AWS_IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text)
log_success "Using AWS credentials for: $AWS_IDENTITY"

# --- Main Setup Process ---

# Step 1: Create Terraform State Backend
log_step "Step 1: Creating Terraform State Backend"
echo "Creating S3 bucket for Terraform state..."
./bin/do-terraform.sh --path infra/aws/tf-state
log_success "Terraform state backend created successfully"

# Step 2: Create VPC
log_step "Step 2: Creating VPC Infrastructure"
echo "Creating VPC, subnets, and networking components..."
./bin/do-terraform.sh --path infra/aws/vpc
log_success "VPC infrastructure created successfully"

# Step 3: Create Database
log_step "Step 3: Creating Database Infrastructure"
echo "Creating RDS database and security groups..."
./bin/do-terraform.sh --path infra/aws/db
log_success "Database infrastructure created successfully"

# Step 4: Create Data Volume
log_step "Step 4: Creating Data Volume"
echo "Creating EBS volume for persistent data storage..."
./bin/do-terraform.sh --path infra/aws/data-volume
log_success "Data volume created successfully"

# Step 5: Create Manager VM
log_step "Step 5: Creating Manager VM"
echo "Creating EC2 instance for data management..."
./bin/do-terraform.sh --path infra/aws/mgr-vm

# Save the IP and private key from the output
echo "Saving instance IP and private key..."
(cd infra/aws/mgr-vm && terraform output -raw public_ip > instance-ip.txt)
(cd infra/aws/mgr-vm && terraform output -raw private_key > loader.key)
chmod 600 infra/aws/mgr-vm/loader.key
log_success "Instance IP and private key saved."

log_success "Manager VM created successfully"

# Step 6: Upload Data (optional)
if [[ "$SKIP_DATA_UPLOAD" == "false" ]]; then
    log_step "Step 6: Uploading Data Files"
    echo "Uploading data files to the manager instance..."
    ./bin/upload-data.sh --data-folder ../data
    log_success "Data files uploaded successfully"
else
    log_warning "Skipping data upload (--skip-data-upload specified)"
fi

# Update Scripts on Manager Instance
log_step "Updating scripts on manager instance"
echo "Pulling latest changes from git..."
./bin/mgr-ssh.sh 'cd /home/ec2-user/pc-dae-voters && git pull'
log_success "Scripts updated successfully"

# Step 7: Load Data (optional)
if [[ "$SKIP_DATA_LOAD" == "false" ]]; then
    log_step "Step 7: Recreating database tables"
    echo "Running create-tables.sh on the manager instance to ensure schema is up to date..."
    ./bin/mgr-ssh.sh 'cd /home/ec2-user/pc-dae-voters && ./bin/create-tables.sh --delete'
    log_success "Database tables recreated successfully"

    log_step "Step 7: Loading Data into Database"
    echo "Running data loading scripts on the manager instance..."
    ./bin/mgr-ssh.sh 'cd /home/ec2-user/pc-dae-voters && ./bin/load-data.sh'
    log_success "Data loaded into database successfully"
else
    log_warning "Skipping data load (--skip-data-load specified)"
fi

# Step 8: Create EKS Cluster (optional)
if [[ "$SKIP_EKS" == "false" ]]; then
    log_step "Step 8: Creating EKS Cluster"
    echo "Creating Kubernetes cluster for application deployment..."
    ./bin/mgr-ssh.sh 'do-terraform.sh --path infra/aws/eks'
    log_success "EKS cluster created successfully"
else
    log_warning "Skipping EKS creation (--skip-eks specified)"
fi

# --- Final Summary ---
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo "Your AWS infrastructure has been successfully created:"
echo "  ✅ S3 backend for Terraform state"
echo "  ✅ VPC with public and private subnets"
echo "  ✅ RDS PostgreSQL database (VPC-only access)"
echo "  ✅ EBS data volume for persistent storage"
echo "  ✅ Manager EC2 instance with data loading capabilities"
if [[ "$SKIP_DATA_UPLOAD" == "false" ]]; then
    echo "  ✅ Data files uploaded to manager instance"
fi
if [[ "$SKIP_DATA_LOAD" == "false" ]]; then
    echo "  ✅ Data loaded into database"
fi
if [[ "$SKIP_EKS" == "false" ]]; then
    echo "  ✅ EKS Kubernetes cluster"
fi

echo ""
echo "Next steps:"
echo "  • SSH to manager instance: ./bin/mgr-ssh.sh"
echo "  • Check database: ./bin/db-query.sh"
echo "  • Deploy applications to EKS cluster"
echo ""
log_success "AWS infrastructure setup completed successfully!" 