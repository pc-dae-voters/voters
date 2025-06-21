#!/bin/bash

# Script to run Terraform commands for the data volume module
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Running Terraform in $(pwd)..."

# Source credentials if available
if [ -f "../../infra/aws/creds.sh" ]; then
    source ../../infra/aws/creds.sh
fi

# Parse command line arguments
COMMAND=""
PLAN_ONLY=false
APPLY_ONLY=false
DESTROY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --plan)
            PLAN_ONLY=true
            shift
            ;;
        --apply)
            APPLY_ONLY=true
            shift
            ;;
        --destroy)
            DESTROY_ONLY=true
            shift
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Run the appropriate command
if [ "$DESTROY_ONLY" = true ]; then
    echo "Running terraform destroy..."
    terraform destroy -auto-approve
elif [ "$PLAN_ONLY" = true ]; then
    echo "Running terraform plan..."
    terraform plan
elif [ "$APPLY_ONLY" = true ]; then
    echo "Running terraform apply..."
    terraform apply -auto-approve
elif [ -n "$COMMAND" ]; then
    echo "Running terraform $COMMAND..."
    terraform "$COMMAND"
else
    echo "No command specified, running default plan and apply..."
    terraform plan
    terraform apply -auto-approve
fi

echo "Terraform execution completed." 