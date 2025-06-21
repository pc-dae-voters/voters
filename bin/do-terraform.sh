#!/usr/bin/env bash

# Utility to run terraform for a specific module.
# Version: 2.1
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [<module>] [<command>] [options]" >&2
    echo "This script simplifies running common Terraform commands against a module." >&2
    echo
    echo "Arguments:"
    echo "  <module>     The name of the module (e.g., 'db', 'vpc'). Can also be set with --path."
    echo "  <command>    The terraform command (e.g., 'plan', 'apply')."
    echo
    echo "Options:"
    echo "  --path <path>    Path to the Terraform module folder (e.g., 'infra/db'). Overrides <module>."
    echo "  --plan           Generate a plan. (Default action if no command)."
    echo "  --apply          Apply a plan. (Default action if no command)."
    echo "  --destroy        Destroy resources. Works with --plan and --apply."
    echo "  --debug          Enable debug mode (set -x)."
    exit 1
}

# --- Argument Parsing ---
MODULE=""
COMMAND=""
TERRAFORM_ARGS=()
PLAN=false
APPLY=false
DESTROY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            MODULE="$2"
            shift 2
            ;;
        --plan)
            PLAN=true
            shift
            ;;
        --apply)
            APPLY=true
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        --debug)
            set -x
            shift
            ;;
        -*) # Unknown flag
            echo "Error: Unknown flag: $1" >&2
            usage
            ;;
        *) # Positional arguments
            if [[ -z "$MODULE" ]]; then
                MODULE="$1"
            elif [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                TERRAFORM_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done


# --- Main Logic ---
if [[ -z "$MODULE" ]]; then
    echo "Error: No module specified." >&2
    usage
fi

# Determine module path
PROJECT_ROOT=$(git rev-parse --show-toplevel)
# Handle both full paths like 'infra/db' and just 'db'
if [[ ! "$MODULE" == infra/* ]]; then
    MODULE_PATH="${PROJECT_ROOT}/infra/${MODULE}"
else
    MODULE_PATH="${PROJECT_ROOT}/${MODULE}"
fi


if [[ ! -d "${MODULE_PATH}" ]]; then
    echo "Error: Module directory not found at ${MODULE_PATH}" >&2
    exit 1
fi

# Change to the module directory
cd "${MODULE_PATH}"
echo "Running Terraform in ${PWD}..."

# --- Command Logic ---
# Run intelligent init
source "${PROJECT_ROOT}/bin/intelligent-init.sh"

# Determine which terraform command to run
if [[ "$COMMAND" == "plan" || "$PLAN" == true ]]; then
    if [[ "$DESTROY" == true ]]; then
        echo "Executing: terraform plan -destroy"
        terraform plan -destroy "${TERRAFORM_ARGS[@]}"
    else
        echo "Executing: terraform plan"
        terraform plan "${TERRAFORM_ARGS[@]}"
    fi
elif [[ "$COMMAND" == "apply" || "$APPLY" == true ]]; then
    if [[ "$DESTROY" == true ]]; then
        echo "Executing: terraform apply -destroy"
        terraform apply -destroy "${TERRAFORM_ARGS[@]}"
        echo "Destroy completed. Skipping post.sh execution."
    else
        echo "Executing: terraform apply"
        terraform apply "${TERRAFORM_ARGS[@]}"
        if [[ -f "post.sh" ]]; then
            echo "Found post.sh, executing..."
            source ./post.sh
        fi
    fi
elif [[ -n "$COMMAND" ]]; then # Any other command
    echo "Executing: terraform ${COMMAND}"
    terraform "${COMMAND}" "${TERRAFORM_ARGS[@]}"
else # Default action if no command specified
    if [[ "$DESTROY" == true ]]; then
        echo "No command specified, running default destroy plan and apply..."
        terraform plan -destroy -out=default.tfplan
        terraform apply default.tfplan
        echo "Destroy completed. Skipping post.sh execution."
    else
        echo "No command specified, running default plan and apply..."
        terraform plan -out=default.tfplan
        terraform apply default.tfplan
        if [[ -f "post.sh" ]]; then
            echo "Found post.sh, executing..."
            source ./post.sh
        fi
    fi
fi

echo "Terraform execution completed."