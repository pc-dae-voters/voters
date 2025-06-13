#!/usr/bin/env bash

# Master script to run all data loading shell scripts in the correct order.
# Version: 1.4
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Default Configuration ---
CON_CSV=""
CON_POSTCODES_CSV=""
PLACES_CSV=""
ADDRESSES_FOLDER=""
NAMES_FOLDER=""
NUM_PEOPLE=1000
RANDOM_SEED=""

function usage() {
    echo "usage: ${0} [options]" >&2
    echo "This script runs all the data loading scripts in the correct sequence." >&2
    echo
    echo "Options:" >&2
    echo "  --con-csv <path>           Path to constituencies CSV file" >&2
    echo "  --con-postcodes-csv <path> Path to constituency postcodes CSV file" >&2
    echo "  --places-csv <path>        Path to places CSV file" >&2
    echo "  --addresses-folder <path>  Path to folder containing address CSVs" >&2
    echo "  --names-folder <path>      Path to folder containing name CSVs" >&2
    echo "  --num-people <n>           Number of synthetic people to generate (default: 1000)" >&2
    echo "  --random-seed <n>          Random seed for synthetic people generation" >&2
    echo "  --debug                    Enable debug mode (set -x)" >&2
    echo "  --help                     Display this help message" >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --con-csv)
            CON_CSV="$2"
            shift 2
            ;;
        --con-postcodes-csv)
            CON_POSTCODES_CSV="$2"
            shift 2
            ;;
        --places-csv)
            PLACES_CSV="$2"
            shift 2
            ;;
        --addresses-folder)
            ADDRESSES_FOLDER="$2"
            shift 2
            ;;
        --names-folder)
            NAMES_FOLDER="$2"
            shift 2
            ;;
        --num-people)
            NUM_PEOPLE="$2"
            shift 2
            ;;
        --random-seed)
            RANDOM_SEED="$2"
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

# Get the directory where the script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Check if virtual environment exists, if not create it
VENV_DIR="${PROJECT_ROOT}/.venv"
if [[ ! -d "${VENV_DIR}" ]]; then
    echo "Virtual environment not found. Creating it..."
    "${SCRIPT_DIR}/setup-venv.sh"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "${VENV_DIR}/bin/activate"

function run_loader() {
    local script_name="$1"
    shift
    echo "--- Running ${script_name} ---"
    if ! "${SCRIPT_DIR}/${script_name}" "$@"; then
        echo "Error: ${script_name} failed. Aborting." >&2
        exit 1
    fi
    echo "--- Finished ${script_name} ---"
    echo
}

echo "Starting data loading process..."

# Run each loader with its specific arguments
if [[ -n "$CON_CSV" ]]; then
    run_loader "run-load-con.sh" --csv-file "$CON_CSV"
else
    run_loader "run-load-con.sh"
fi

if [[ -n "$CON_POSTCODES_CSV" ]]; then
    run_loader "run-load-con-postcodes.sh" --csv-file "$CON_POSTCODES_CSV"
else
    run_loader "run-load-con-postcodes.sh"
fi

if [[ -n "$PLACES_CSV" ]]; then
    run_loader "run-load-places.sh" --csv-file "$PLACES_CSV"
else
    run_loader "run-load-places.sh"
fi

if [[ -n "$ADDRESSES_FOLDER" ]]; then
    run_loader "run-load-addresses.sh" --input-folder "$ADDRESSES_FOLDER"
else
    run_loader "run-load-addresses.sh"
fi

if [[ -n "$NAMES_FOLDER" ]]; then
    run_loader "run-load-names-from-csv.sh" --input-folder "$NAMES_FOLDER"
else
    run_loader "run-load-names-from-csv.sh"
fi

# For synthetic people, we always pass num-people and random-seed if provided
SYNTHETIC_ARGS="--num-people ${NUM_PEOPLE}"
if [[ -n "$RANDOM_SEED" ]]; then
    SYNTHETIC_ARGS="${SYNTHETIC_ARGS} --random-seed ${RANDOM_SEED}"
fi
run_loader "run-load-synthetic-people.sh" ${SYNTHETIC_ARGS}

# Deactivate virtual environment
deactivate

echo "All data loading scripts completed successfully." 