#!/usr/bin/env bash

# Wrapper script to run the load-places.py Python script.
# Version: 1.4
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Default Configuration ---
DEFAULT_ADDRESSES_FOLDER="data/addresses"
ADDRESSES_FOLDER=""

function usage() {
    echo "usage: ${0} [--addresses-folder <path>] [--help] [--debug]" >&2
    echo "This script runs the Python script to load places from address CSV files." >&2
    echo "  --addresses-folder <path>  Path to the folder containing address CSV files (default: project_root/${DEFAULT_ADDRESSES_FOLDER})." >&2
    echo "  --help                     Display this help message." >&2
    echo "  --debug                    Enable debug mode (set -x)." >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --addresses-folder)
            ADDRESSES_FOLDER="$2"
            shift 2
            ;;
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

# Use default addresses folder if one is not provided
if [[ -z "$ADDRESSES_FOLDER" ]]; then
    ADDRESSES_FOLDER="${PROJECT_ROOT}/${DEFAULT_ADDRESSES_FOLDER}"
fi

# Check if addresses folder exists
if [[ ! -d "$ADDRESSES_FOLDER" ]]; then
    echo "Error: Addresses folder not found at ${ADDRESSES_FOLDER}" >&2
    exit 1
fi

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script, passing the addresses-folder argument
echo "Running load-places.py..."
python3 "${PROJECT_ROOT}/db/load-places.py" --addresses-folder "$ADDRESSES_FOLDER" 