#!/usr/bin/env bash
set -euo pipefail

# --- Utility Functions ---
log_error() {
    echo "❌ Error: $1" >&2
    exit 1
}

# --- Default values ---
ACTION=""
AUTO_APPROVE=false
MODULE_PATH=""
EXTRA_ARGS=()

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path) MODULE_PATH="$2"; shift ;;
        --apply) ACTION="apply" ;;
        --destroy) ACTION="destroy" ;;
        --refresh) ACTION="refresh" ;;
        --auto-approve) AUTO_APPROVE=true ;;
        --plan) ACTION="plan" ;; # Added for clarity, though apply is default
        -var|--target) EXTRA_ARGS+=("$1" "$2"); shift ;;
        *) 
            # Capture any other arguments for terraform
            EXTRA_ARGS+=("$1")
            ;;
    esac
    shift
done

if [[ -z "$MODULE_PATH" ]]; then
    log_error "Module path not specified. Use --path <path>."
fi

# Default to apply if no other action is specified
if [[ -z "$ACTION" ]]; then
    ACTION="apply"
fi

if [[ ! -d "$MODULE_PATH" ]]; then
    log_error "Module path does not exist: $MODULE_PATH"
fi

# Change to the module directory
cd "$MODULE_PATH"
echo "Running Terraform in ${PWD}..." >&2

# --- Intelligent Init ---
# shellcheck source=../bin/intelligent-init.sh
source "$(git rev-parse --show-toplevel)/bin/intelligent-init.sh"

# --- Execute Terraform Command ---
if [[ "$ACTION" == "apply" ]]; then
    echo "Running terraform plan and apply..." >&2
    
    plan_args=("-out=default.tfplan")
    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
        plan_args+=("${EXTRA_ARGS[@]}")
    fi
    terraform plan "${plan_args[@]}"
    
    # Apply is always non-interactive in this script for automation
    terraform apply -auto-approve default.tfplan

elif [[ "$ACTION" == "refresh" ]]; then
    echo "Running terraform refresh..." >&2
    terraform apply -refresh-only -auto-approve

elif [[ "$ACTION" == "plan" ]]; then
    echo "Running terraform plan..." >&2
    terraform plan "${EXTRA_ARGS[@]}"

elif [[ "$ACTION" == "destroy" ]]; then
    echo "Running terraform destroy..." >&2
    
    destroy_args=()
    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
        destroy_args+=("${EXTRA_ARGS[@]}")
    fi
    if [[ "$AUTO_APPROVE" = true ]]; then
        destroy_args+=("-auto-approve")
    fi
    
    terraform destroy "${destroy_args[@]}"
else
    log_error "Invalid action: $ACTION"
fi

echo "✅ Terraform execution completed." >&2