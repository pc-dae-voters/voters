#!/usr/bin/env bash

# Wrapper script to run the load-synthetic-people.py Python script.
# Version: 1.3
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Default Configuration ---
NUM_PEOPLE=1000
RANDOM_SEED=""
PASS_THRU_ARGS=""

function usage() {
    echo "usage: ${0} [--num-people <n>] [--random-seed <n>] [--help] [--debug]" >&2
    echo "This script runs the Python script to generate synthetic people." >&2
    echo "  --num-people <n>   Number of people to generate (default: ${NUM_PEOPLE})." >&2
    echo "  --random-seed <n>  Optional random seed for reproducibility." >&2
    echo "  --help             Display this help message." >&2
    echo "  --debug            Enable debug mode (set -x)." >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
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

# Construct arguments to pass to python script
PASS_THRU_ARGS="--num-people ${NUM_PEOPLE}"
if [[ -n "$RANDOM_SEED" ]]; then
    PASS_THRU_ARGS="${PASS_THRU_ARGS} --random-seed ${RANDOM_SEED}"
fi

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script, passing the constructed arguments
echo "Running load-synthetic-people.py..."
python3 "${PROJECT_ROOT}/db/load-synthetic-people.py" ${PASS_THRU_ARGS} 