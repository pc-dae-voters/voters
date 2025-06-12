#!/usr/bin/env bash

# Wrapper script to run the load-con-postcodes.py Python script.
# Version: 1.3
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Default Configuration ---
DEFAULT_CSV_FILE="db/postcodes_with_con.csv"
CSV_FILE=""

function usage() {
    echo "usage: ${0} [--csv-file <path>] [--help] [--debug]" >&2
    echo "This script runs the Python script to load constituency postcodes." >&2
    echo "  --csv-file <path>  Path to the postcodes CSV file (default: project_root/${DEFAULT_CSV_FILE})." >&2
    echo "  --help             Display this help message." >&2
    echo "  --debug            Enable debug mode (set -x)." >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --csv-file)
            CSV_FILE="$2"
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

# Use default CSV if one is not provided
if [[ -z "$CSV_FILE" ]]; then
    CSV_FILE="${PROJECT_ROOT}/${DEFAULT_CSV_FILE}"
fi

# Check if CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found at ${CSV_FILE}" >&2
    exit 1
fi

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script, passing the csv-file argument
echo "Running load-con-postcodes.py..."
python3 "${PROJECT_ROOT}/db/load-con-postcodes.py" --csv-file "$CSV_FILE" 