#!/usr/bin/env bash

# Master script to run all data loading shell scripts in the correct order.
# Version: 1.2
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [options]" >&2
    echo "This script runs all the data loading scripts in the correct sequence." >&2
    echo "Any options provided will be passed down to the underlying scripts." >&2
    exit 1
}

if [[ "${1:-}" == "--help" ]]; then
    usage
fi

# Get the directory where the script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function run_loader() {
    local script_name="$1"
    shift
    echo "--- Running ${script_name} ---"
    if ! bash "${SCRIPT_DIR}/${script_name}" "$@"; then
        echo "Error: ${script_name} failed. Aborting." >&2
        exit 1
    fi
    echo "--- Finished ${script_name} ---"
    echo
}

echo "Starting data loading process..."
echo "All arguments will be passed to each script: $@"
echo

run_loader "run-load-con.sh" "$@"
run_loader "run-load-con-postcodes.sh" "$@"
run_loader "run-load-places.sh" "$@"
run_loader "run-load-addresses.sh" "$@"
run_loader "run-load-names-from-csv.sh" "$@"
run_loader "run-load-synthetic-people.sh" "$@"

echo "All data loading scripts completed successfully." 