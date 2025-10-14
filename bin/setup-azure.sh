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

# Clean up previous Terraform state to avoid caching issues
log_step "Cleaning up local Terraform cache"
find ./infra/azure -type d -name ".terraform" -exec rm -rf {} +
find ./infra/azure -type f -name ".terraform.lock.hcl" -delete
log_success "Terraform cache cleaned"

# Step 1: Create Terraform State Backend
log_step "Step 1: Creating Terraform State Backend"
echo "Creating Azure Storage Account for Terraform state..."
./bin/do-terraform.sh --path infra/azure/tf-state
log_success "Terraform state backend created successfully"

log_step "Step 2: Creating All Azure Infrastructure"
echo "Creating VNet, Database, Data Volume, Manager VM, and AKS Cluster..."
# Pass a unique version to the cloud-init script to force re-provisioning on change
CLOUD_INIT_VERSION=$(date +%s)
./bin/do-terraform.sh --path infra/azure -var "cloud_init_version=$CLOUD_INIT_VERSION"
log_success "All Azure infrastructure created successfully"

# The rest of the script (data upload, etc.) will run after this,
# but we run them separately in case the user wants to skip them.

# Step 3: Upload Data (optional)
if [[ "$SKIP_DATA_UPLOAD" == "false" ]]; then
    log_step "Step 3: Uploading Data Files"
    echo "Uploading data files to the manager instance..."
    ./bin/upload-data-azure.sh --data-folder ../data
    log_success "Data files uploaded successfully"
else
    log_warning "Skipping data upload (--skip-data-upload specified)"
fi

# Update Scripts on Manager Instance
log_step "Updating scripts on manager instance"
echo "Pulling latest changes from git..."
./bin/mgr-ssh-azure.sh 'cd ~/pc-dae-voters && git pull'
log_success "Scripts updated successfully"

# Step 4: Load Data (optional)
if [[ "$SKIP_DATA_LOAD" == "false" ]]; then
    log_step "Step 4: Loading Data into Database"
    echo "Running data loading scripts on the manager instance..."
    ./bin/mgr-ssh-azure.sh '~/load-data.sh'
    log_success "Data loaded into database successfully"
else
    log_warning "Skipping data load (--skip-data-load specified)"
fi
}

# --- Main Execution ---
# Clean up from previous runs
rm -rf infra/azure/.terraform* infra/azure/default.tfplan
rm -rf infra/azure/tf-state/.terraform* infra/azure/tf-state/default.tfplan

# Run the main setup function and capture its exit code
main "$@"
exit_code=$?

# --- Final Summary ---
echo ""
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}=== Azure Setup Succeeded! ===${NC}"
    log_success "All Azure infrastructure has been successfully deployed and configured."
else
    echo -e "${RED}=== Azure Setup Failed! ===${NC}"
    log_error "An error occurred during the setup process. Please check the logs above for details."
fi

exit $exit_code
