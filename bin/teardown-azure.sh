#!/usr/bin/env bash

# Azure Infrastructure Teardown Script
# This script automates the complete destruction of the Voters project Azure infrastructure.
# WARNING: This is a destructive operation and will remove all created resources.
# Version: 2.0
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
    echo "This script automates the complete destruction of the Voters project Azure infrastructure." >&2
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
echo -e "${RED}=== Azure Infrastructure Teardown ===${NC}"
echo -e "${YELLOW}WARNING: This is a destructive operation and will permanently delete all Azure resources managed by this project."
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

# Source Azure service principal configuration
log_step "Setting up Azure environment"
if [[ -f "infra/azure/.az-sp.sh" ]]; then
    source infra/azure/.az-sp.sh
fi

# Check if Azure credentials are available
log_step "Verifying Azure credentials"
if ! az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" >/dev/null 2>&1; then
    log_error "Azure credentials not found or invalid."
    exit 1
fi
az account set --subscription "$AZURE_SUBSCRIPTION_ID" >/dev/null 2>&1
log_success "Using Azure credentials for teardown."

# --- Main Teardown Process ---
# To ensure a clean slate and avoid issues with orphaned resources (like AKS NICs locking subnets)
# or soft-deleted resources (like Key Vault secrets), we will take a multi-step approach.

KEY_VAULT_NAME="voters-key-vault-unique"
SECRET_NAME="pc-dae-voters-db-password"
RESOURCE_GROUP_NAME="pc-dae-voters-rg"
TFSTATE_RESOURCE_GROUP_NAME="pc-dae-voters-tfstate"

log_step "Purging Key Vault secrets to prevent conflicts"
# Check if the vault exists before trying to purge
if az keyvault show --name "${KEY_VAULT_NAME}" &>/dev/null; then
    echo "Key Vault '${KEY_VAULT_NAME}' found. Purging secret '${SECRET_NAME}'..."
    # This command will fail if the secret doesn't exist, which is fine.
    az keyvault secret purge --vault-name "${KEY_VAULT_NAME}" --name "${SECRET_NAME}" || true
    log_success "Key Vault secret purge command issued."
else
    log_warning "Key Vault '${KEY_VAULT_NAME}' not found. Skipping secret purge."
fi

log_step "Deleting main resource group: ${RESOURCE_GROUP_NAME}"
if az group show --name "${RESOURCE_GROUP_NAME}" &>/dev/null; then
    echo "Resource group '${RESOURCE_GROUP_NAME}' found. Deleting... (this will take several minutes)"
    az group delete --name "${RESOURCE_GROUP_NAME}" --yes
    log_success "Deletion of '${RESOURCE_GROUP_NAME}' complete."
else
    log_warning "Resource group '${RESOURCE_GROUP_NAME}' not found. Skipping."
fi

log_step "Deleting Terraform state resource group: ${TFSTATE_RESOURCE_GROUP_NAME}"
if az group show --name "${TFSTATE_RESOURCE_GROUP_NAME}" &>/dev/null; then
    echo "Resource group '${TFSTATE_RESOURCE_GROUP_NAME}' found. Deleting... (this may take a few minutes)"
    az group delete --name "${TFSTATE_RESOURCE_GROUP_NAME}" --yes
    log_success "Deletion of '${TFSTATE_RESOURCE_GROUP_NAME}' complete."
else
    log_warning "Resource group '${TFSTATE_RESOURCE_GROUP_NAME}' not found. Skipping."
fi


# --- Final Summary ---
echo ""
echo -e "${GREEN}=== Teardown Complete! ===${NC}"
echo "All Voters project Azure resource groups have been successfully destroyed."
log_success "Azure teardown completed."
