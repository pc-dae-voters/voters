#!/usr/bin/env bash

# This script runs terraform init and intelligently handles backend
# configuration changes by automatically re-running with -reconfigure.
# For Azure, it also fetches backend configuration from the tf-state module.

set -euo pipefail

# --- Azure Backend Configuration ---
# Determine if we are in an Azure module that needs remote state config.
is_azure_module() {
    [[ "$PWD" == *"/infra/azure"* && "$PWD" != *"/infra/azure/tf-state"* ]]
}

get_azure_backend_config() {
    # Check for jq dependency
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is not installed, but it is required for Azure backend configuration." >&2
        echo "Please install it to continue (e.g., 'brew install jq' on macOS)." >&2
        return 1
    fi

    local project_root
    project_root=$(git rev-parse --show-toplevel)
    local tf_state_path="${project_root}/infra/azure/tf-state"

    if [ ! -d "$tf_state_path" ]; then
        echo "Error: Azure tf-state directory not found at $tf_state_path" >&2
        return 1
    fi

    echo "Fetching Azure backend configuration from $tf_state_path..." >&2
    
    local outputs
    # Run terraform output and capture stderr to provide better error messages
    outputs=$(terraform -chdir="$tf_state_path" output -json 2>/dev/null)

    if [ -z "$outputs" ]; then
        echo "Error: Could not fetch outputs from Azure tf-state module." >&2
        echo "Please ensure the tf-state has been applied successfully by running:" >&2
        echo "  ./bin/do-terraform.sh --path infra/azure/tf-state" >&2
        return 1
    fi

    local resource_group_name storage_account_name container_name
    
    resource_group_name=$(echo "$outputs" | jq -r '.backend_config.value.resource_group_name')
    storage_account_name=$(echo "$outputs" | jq -r '.backend_config.value.storage_account_name')
    container_name=$(echo "$outputs" | jq -r '.backend_config.value.container_name')
    
    if [ -z "$resource_group_name" ] || [ "$resource_group_name" == "null" ] || \
       [ -z "$storage_account_name" ] || [ "$storage_account_name" == "null" ] || \
       [ -z "$container_name" ] || [ "$container_name" == "null" ]; then
        echo "Error: One or more backend configuration values are missing from tf-state outputs." >&2
        echo "Received: rg='$resource_group_name', sa='$storage_account_name', cn='$container_name'" >&2
        return 1
    fi

    # Return the arguments for terraform init
    echo "-backend-config=resource_group_name=$resource_group_name"
    echo "-backend-config=storage_account_name=$storage_account_name"
    echo "-backend-config=container_name=$container_name"
    local module_name
    module_name=$(basename "$PWD")
    echo "-backend-config=key=${module_name}.tfstate"
}

# --- Main Logic ---
BACKEND_ARGS=()
if is_azure_module; then
    echo "Azure module detected. Attempting to fetch backend configuration..."
    # Use process substitution to read lines into the array
    # The || true prevents the script exiting if get_azure_backend_config fails, allowing us to handle the error.
    while IFS= read -r line; do
        BACKEND_ARGS+=("$line")
    done < <(get_azure_backend_config || true)
    
    # Check if the array is empty, which indicates get_azure_backend_config failed
    if [ ${#BACKEND_ARGS[@]} -eq 0 ]; then
        echo "Error: Failed to get Azure backend configuration. See error messages above. Aborting." >&2
        exit 1
    fi
    echo "Successfully fetched Azure backend configuration."
fi

# Run terraform init, capturing stderr to check for specific errors
stderr_file=$(mktemp)

INIT_COMMAND=("terraform" "init" "-upgrade" "-no-color")
if [ ${#BACKEND_ARGS[@]} -gt 0 ]; then
    INIT_COMMAND+=("${BACKEND_ARGS[@]}")
fi

echo "Running: ${INIT_COMMAND[*]}"
if ! "${INIT_COMMAND[@]}" 2> "$stderr_file"; then
    # If init fails, check for the "Backend configuration changed" error.
    if grep -q "Backend configuration changed" "$stderr_file"; then
        echo "Backend configuration changed. Re-running with -reconfigure..."
        cat "$stderr_file" >&2
        
        # Retry with -reconfigure
        if ! terraform init -reconfigure "${BACKEND_ARGS[@]}"; then
            echo "Terraform init -reconfigure failed." >&2
            rm -f "$stderr_file"
            exit 1
        fi
    else
        # If it's a different error, print it and exit.
        echo "Terraform init failed:" >&2
        cat "$stderr_file" >&2
        rm -f "$stderr_file"
        exit 1
    fi
fi
# Cleanup the temp file.
rm -f "$stderr_file" 