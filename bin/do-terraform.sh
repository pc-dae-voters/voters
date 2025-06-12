#!/usr/bin/env bash

# Utility to run terraform with options for init, plan, and apply
# Version: 1.5
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--path <terraform_folder>] [--plan [<plan_file>]] [--apply [<plan_file>] [--help] [--debug]" >&2
    echo "This script simplifies running common Terraform commands." >&2
    echo "  --path <terraform_folder>  Path to the Terraform folder (default: .)" >&2
    echo "  --plan [<plan_file>]      Generate a plan and save it to a file, then exit. Defaults to default.tfplan." >&2
    echo "  --apply [<plan_file>]    Apply a previously generated plan file. Defaults to default.tfplan." >&2
    echo "  --help                   Display this help message" >&2
    echo "  --debug                  Enable debug mode (set -x)" >&2
}

function intelligent_init() {
    # Run terraform init, capturing stderr to check for specific errors
    local stderr_file
    stderr_file=$(mktemp)

    # We are using -no-color to make string matching easier.
    if ! terraform init -no-color 2> "$stderr_file"; then
        # If init fails, check for the "Backend configuration changed" error.
        if grep -q "Backend configuration changed" "$stderr_file"; then
            echo "Backend configuration changed. Re-running with -reconfigure..."
            # Show the initial error message.
            cat "$stderr_file" >&2
            
            # Retry with -reconfigure
            if ! terraform init -reconfigure; then
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
}

function args() {
    terraform_path="."
    plan=false
    apply=false
    plan_file=""
    apply_file=""

    arg_list=("$@")
    arg_count=${#arg_list[@]}
    arg_index=0

    while ((arg_index < arg_count)); do
        case "${arg_list[$arg_index]}" in
            "--path")
                ((arg_index += 1))
                terraform_path="${arg_list[$arg_index]}"
                ;;
            "--plan")
                plan=true
                if [[ $((arg_index + 1)) -lt $arg_count && "${arg_list[$((arg_index + 1))]:0:2}" != "--" ]]; then
                    ((arg_index += 1))
                    plan_file="${arg_list[$arg_index]}"
                fi
                ;;
            "--apply")
                apply=true
                if [[ $((arg_index + 1)) -lt $arg_count && "${arg_list[$((arg_index + 1))]:0:2}" != "--" ]]; then
                    ((arg_index += 1))
                    apply_file="${arg_list[$arg_index]}"
                fi
                ;;
            "--help" | "-h" | "-?")
                usage
                exit 0
                ;;
            "--debug")
                set -x
                ;;
            *)
                if [[ "${arg_list[$arg_index]:0:2}" == "--" ]]; then
                    echo "Invalid argument: ${arg_list[$arg_index]}" >&2
                    usage
                    exit 1
                fi
                break
                ;;
        esac
        ((arg_index += 1))
    done
}

args "$@"

# Determine the script's directory and cd into the parent 'voters' directory
# This allows terraform paths to be relative to the 'voters' directory.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."

# Terraform Workflow
cd "${terraform_path}"

if ! $plan && ! $apply; then
    intelligent_init
    terraform plan -out=default.tfplan
    terraform apply default.tfplan
elif $plan; then
    intelligent_init
    if [[ -z "$plan_file" ]]; then
        plan_file="default.tfplan"
    fi
    terraform plan -out="$plan_file"
elif $apply; then
    intelligent_init
    if [[ -z "$apply_file" ]]; then
        apply_file="default.tfplan"
    fi
    terraform apply "$apply_file"
fi

echo "Terraform execution completed."