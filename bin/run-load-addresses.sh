#!/usr/bin/env bash

# Wrapper script to run the load-addresses.py Python script.
# Version: 1.2
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Default Configuration ---
DEFAULT_INPUT_FOLDER="data/addresses"
INPUT_FOLDER=""

function usage() {
    echo "usage: ${0} [--input-folder <path>] [--help] [--debug]" >&2
    echo "This script runs the Python script to load addresses from a folder of CSVs." >&2
    echo "  --input-folder <path>  Path to the folder of address CSVs (default: project_root/${DEFAULT_INPUT_FOLDER})." >&2
    echo "  --help                 Display this help message." >&2
    echo "  --debug                Enable debug mode (set -x)." >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input-folder)
            INPUT_FOLDER="$2"
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

# Use default folder if one is not provided
if [[ -z "$INPUT_FOLDER" ]]; then
    INPUT_FOLDER="${PROJECT_ROOT}/${DEFAULT_INPUT_FOLDER}"
fi

# Check if folder exists
if [[ ! -d "$INPUT_FOLDER" ]]; then
    echo "Error: Input folder not found at ${INPUT_FOLDER}" >&2
    exit 1
fi

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script, passing the input-folder argument
echo "Running load-addresses.py..."
python3 "${PROJECT_ROOT}/db/load-addresses.py" --input-folder "$INPUT_FOLDER"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 