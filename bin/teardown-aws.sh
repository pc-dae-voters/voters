#!/usr/bin/env bash

# AWS Infrastructure Teardown Script
# This script automates the complete destruction of the Voters project AWS infrastructure.
# WARNING: This is a destructive operation and will remove all created resources.
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
    echo "This script automates the complete destruction of the Voters project AWS infrastructure." >&2
    echo "It will destroy resources in the reverse order of their creation." >&2
    echo
    echo "Options:"
    echo "  --help          Display this help message."
    echo "  --auto-approve  Skip the confirmation prompt and proceed with destruction."
    echo "  --debug         Enable debug mode (set -x)."
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
AUTO_APPROVE=false
DEBUG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            usage
            ;;
        --auto-approve)
            AUTO_APPROVE=true
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

# --- Validation and Confirmation ---
echo -e "${RED}=== AWS Infrastructure Teardown ===${NC}"
echo -e "${YELLOW}WARNING: This is a destructive operation and will permanently delete all AWS resources managed by this project."
echo ""

if [[ "$AUTO_APPROVE" == "false" ]]; then
    read -p "Are you sure you want to continue? Type 'destroy' to proceed: " CONFIRMATION
    if [[ "$CONFIRMATION" != "destroy" ]]; then
        echo "Teardown cancelled."
        exit 0
    fi
fi

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
fi

# Check if AWS credentials are available
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "AWS credentials not found or invalid."
    exit 1
fi
log_success "Using AWS credentials for teardown."

# --- Main Teardown Process ---
# Resources are destroyed in the reverse order of creation.

destroy_module() {
    local MODULE_PATH=$1
    log_step "Destroying $MODULE_PATH"
    if [ -d "$MODULE_PATH" ]; then
        ./bin/do-terraform.sh --path "$MODULE_PATH" --destroy --apply -auto-approve
        log_success "$MODULE_PATH destroyed successfully."
    else
        log_warning "Module path $MODULE_PATH not found, skipping."
    fi
}

# Step 1: Destroy EKS Cluster
destroy_module "infra/aws/eks"

# Step 2: Destroy Manager VM
destroy_module "infra/aws/mgr-vm"

# Step 3: Destroy Data Volume
destroy_module "infra/aws/data-volume"

# Step 4: Destroy Database
destroy_module "infra/aws/db"

# Step 5: Destroy VPC
destroy_module "infra/aws/vpc"

# Step 6: Destroy Terraform State Backend
destroy_module "infra/aws/tf-state"

# --- Final Summary ---
echo ""
echo -e "${GREEN}=== Teardown Complete! ===${NC}"
echo "All Voters project AWS infrastructure has been successfully destroyed."
log_success "AWS teardown completed."
