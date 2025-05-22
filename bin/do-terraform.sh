#!/usr/bin/env bash

# Utility to run terraform with options for init, plan, and apply
# Version: 1.2
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--path <terraform_folder>] [--plan [<plan_file>]] [--apply [<plan_file>] [--help] [--debug]" >&2
    echo "This script simplifies running common Terraform commands." >&2
    echo "  --path <terraform_folder>  Path to the Terraform folder (default: .)" >&2
    echo "  --plan [<plan_file>]      Execute terraform plan. If no plan file is provided, uses default.tfplan" >&2
    echo "  --apply [<plan_file>]    Execute terraform apply. If no plan file is provided, uses default.tfplan" >&2
    echo "  --help                   Display this help message" >&2
    echo "  --debug                  Enable debug mode (set -x)" >&2
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

# Terraform Workflow
cd "${terraform_path}"

if ! $plan && ! $apply; then
    terraform init
    terraform plan -out=default.tfplan
    terraform apply default.tfplan
elif $plan; then
    terraform init
    if [[ -z "$plan_file" ]]; then
        plan_file="default.tfplan"
    fi
    terraform plan -out="$plan_file"
elif $apply; then
    if [[ -z "$apply_file" ]]; then
        apply_file="default.tfplan"
    fi
    terraform apply "$apply_file"
fi

echo "Terraform execution completed."