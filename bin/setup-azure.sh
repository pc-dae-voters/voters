#!/usr/bin/env bash

# Azure Infrastructure Setup Script
# This script automates the complete initial setup of the Voters project Azure infrastructure
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
    echo "This script automates the complete initial setup of the Voters project Azure infrastructure." >&2
    echo
    echo "Options:"
    echo "  --help                Display this help message."
    echo "  --skip-data-upload    Skip the data upload step."
    echo "  --skip-data-load      Skip the data loading step."
    echo "  --skip-aks            Skip the AKS cluster creation."
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
SKIP_AKS=false
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
        --skip-aks)
            SKIP_AKS=true
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
echo -e "${BLUE}=== Azure Infrastructure Setup ===${NC}"
echo "This script will set up the complete Voters project Azure infrastructure."
echo ""

# Check if we're in the right directory
if [[ ! -f "bin/do-terraform.sh" ]]; then
    log_error "This script must be run from the voters directory (where bin/do-terraform.sh exists)"
    exit 1
fi

# Source Azure service principal configuration
log_step "Setting up Azure environment"
if [[ -f "infra/azure/.az-sp.sh" ]]; then
    echo "Sourcing Azure service principal configuration..."
    source infra/azure/.az-sp.sh
    log_success "Azure service principal configuration loaded"
else
    log_error "Azure credential file not found at infra/azure/.az-sp.sh"
    log_error "Please run 'bin/create-azure-service-account.sh' first."
    exit 1
fi

# Check if Azure credentials are available by logging in
log_step "Verifying Azure credentials"
if ! az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" >/dev/null 2>&1; then
    log_error "Azure credentials not found or invalid after sourcing .az-sp.sh"
    log_error "Please ensure your Azure Service Principal is correctly configured and has contributor rights."
    exit 1
fi
az account set --subscription "$AZURE_SUBSCRIPTION_ID" >/dev/null 2>&1
log_success "Using Azure credentials for SPN: $AZURE_CLIENT_ID on Subscription: $AZURE_SUBSCRIPTION_ID"


# --- Main Setup Process ---

# Step 1: Create Terraform State Backend
log_step "Step 1: Creating Terraform State Backend"
echo "Creating Azure Storage Account for Terraform state..."
./bin/do-terraform.sh --path infra/azure/tf-state
log_success "Terraform state backend created successfully"

# Step 2: Create Core Infrastructure
log_step "Step 2: Creating Core Infrastructure (VNet & Database)"
echo "Creating VNet, subnets, and PostgreSQL Flexible Server..."
./bin/do-terraform.sh --path infra/azure
log_success "Core infrastructure created successfully"

# Step 3: Create Data Volume
log_step "Step 3: Creating Data Volume"
echo "Creating Managed Disk for persistent data storage..."
./bin/do-terraform.sh --path infra/azure/data-volume
log_success "Data volume created successfully"

# Step 4: Create Manager VM
log_step "Step 4: Creating Manager VM"
echo "Creating Linux VM for data management..."
./bin/do-terraform.sh --path infra/azure/mgr-vm
log_success "Manager VM created successfully"

# Step 5: Upload Data (optional)
if [[ "$SKIP_DATA_UPLOAD" == "false" ]]; then
    log_step "Step 5: Uploading Data Files"
    echo "Uploading data files to the manager instance..."
    ./bin/upload-data-azure.sh --data-folder ../data
    log_success "Data files uploaded successfully"
else
    log_warning "Skipping data upload (--skip-data-upload specified)"
fi

# Step 6: Load Data (optional)
if [[ "$SKIP_DATA_LOAD" == "false" ]]; then
    log_step "Step 6: Loading Data into Database"
    echo "Running data loading scripts on the manager instance..."
    ./bin/mgr-ssh-azure.sh '~/load-data.sh'
    log_success "Data loaded into database successfully"
else
    log_warning "Skipping data load (--skip-data-load specified)"
fi

# Step 7: Create AKS Cluster (optional)
if [[ "$SKIP_AKS" == "false" ]]; then
    log_step "Step 7: Creating AKS Cluster"
    echo "Creating Kubernetes cluster for application deployment..."
    ./bin/do-terraform.sh --path infra/azure/aks
    log_success "AKS cluster created successfully"
else
    log_warning "Skipping AKS creation (--skip-aks specified)"
fi

# --- Final Summary ---
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo "Your Azure infrastructure has been successfully created:"
echo "  ✅ Azure Storage backend for Terraform state"
echo "  ✅ VNet with application and database subnets"
echo "  ✅ Azure Database for PostgreSQL Flexible Server (VNet-only access)"
echo "  ✅ Managed Disk for persistent storage"
echo "  ✅ Manager Linux VM with data loading capabilities"
if [[ "$SKIP_DATA_UPLOAD" == "false" ]]; then
    echo "  ✅ Data files uploaded to manager instance"
fi
if [[ "$SKIP_DATA_LOAD" == "false" ]]; then
    echo "  ✅ Data loaded into database"
fi
if [[ "$SKIP_AKS" == "false" ]]; then
    echo "  ✅ AKS Kubernetes cluster"
fi

echo ""
echo "Next steps:"
echo "  • SSH to manager instance: ./bin/mgr-ssh-azure.sh"
echo "  • Check database: ./bin/db-query-azure.sh"
echo "  • Deploy applications to AKS cluster"
echo ""
log_success "Azure infrastructure setup completed successfully!"
