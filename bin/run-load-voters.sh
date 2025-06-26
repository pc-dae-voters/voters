#!/usr/bin/env bash

# Wrapper script to run the load-voters.py Python script.
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--help] [--debug]" >&2
    echo "This script runs the Python script to load voter records for citizens over 18." >&2
    echo "  --help     Display this help message" >&2
    echo "  --debug    Enable debug mode (set -x)" >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            set -x
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

# --- Main Logic ---
# Determine the project root using git and source the DB environment
PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV_FILE="${PROJECT_ROOT}/infra/db/db-env.sh"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Error: Database environment file not found at ${ENV_FILE}" >&2
    echo "Please run 'do-terraform.sh db apply' to generate it." >&2
    exit 1
fi
source "${ENV_FILE}"

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script
echo "Running load-voters.py..."
python3 "${PROJECT_ROOT}/db/load-voters.py" 