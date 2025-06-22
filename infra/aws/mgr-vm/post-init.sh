#!/usr/bin/env bash

# Post-init script for Voters Manager VM Terraform
# This script handles cloud-init version management

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Post-Init Script for Voters Manager VM ===${NC}"

# Check if TF_VAR_CLOUD_INIT_VERSION is already set
if [[ -n "${TF_VAR_CLOUD_INIT_VERSION:-}" ]]; then
    echo -e "${GREEN}TF_VAR_CLOUD_INIT_VERSION is set to: ${TF_VAR_CLOUD_INIT_VERSION}${NC}"
    echo "This will force cloud-init to run with version ${TF_VAR_CLOUD_INIT_VERSION}"
else
    # Try to get the current version from Terraform state
    echo -e "${YELLOW}Checking current cloud-init version from Terraform state...${NC}"

    # Check if terraform state exists and has the variable
    if [[ -f ".terraform/terraform.tfstate" ]]; then
        CURRENT_VERSION=$(terraform show -json .terraform/terraform.tfstate 2>/dev/null | \
                         jq -r '.values.root_module.resources[] | select(.type == "aws_instance" and .name == "manager") | .values.user_data_base64' 2>/dev/null | \
                         base64 -d 2>/dev/null | \
                         grep -o 'version.*' | \
                         cut -d'=' -f2 | \
                         tr -d ' "' 2>/dev/null || echo "")
        
        if [[ -n "$CURRENT_VERSION" ]]; then
            echo -e "${GREEN}Current cloud-init version in state: ${CURRENT_VERSION}${NC}"
            export TF_VAR_CLOUD_INIT_VERSION="$CURRENT_VERSION"
            echo -e "${BLUE}Set TF_VAR_CLOUD_INIT_VERSION=${CURRENT_VERSION}${NC}"
        else
            echo -e "${YELLOW}Could not determine current version from state, using default${NC}"
            export TF_VAR_CLOUD_INIT_VERSION="1.0"
            echo -e "${BLUE}Set TF_VAR_CLOUD_INIT_VERSION=1.0${NC}"
        fi
    else
        echo -e "${YELLOW}No Terraform state found, using default version${NC}"
        export TF_VAR_CLOUD_INIT_VERSION="1.0"
        echo -e "${BLUE}Set TF_VAR_CLOUD_INIT_VERSION=1.0${NC}"
    fi
fi

echo ""
echo -e "${BLUE}To force cloud-init to run again, set TF_VAR_CLOUD_INIT_VERSION to a new value:${NC}"
echo -e "${YELLOW}  export TF_VAR_CLOUD_INIT_VERSION=\"1.1\"${NC}"
echo -e "${YELLOW}  ./do-terraform.sh${NC}"
echo ""
echo -e "${GREEN}Ready to proceed with Terraform plan/apply${NC}" 