#!/bin/bash

# Script to run the get-uk-places.py Python script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Script Specific Parameters ---
INPUT_FOLDER_ARG=""
OUTPUT_CSV_ARG="$SCRIPT_DIR/../places.csv" # Default output file
ADDRESS_COLUMN_ARG="Address" # Default value in Python script
FILE_PATTERN_ARG="addresses*.csv" # Default value in Python script

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --input-folder) INPUT_FOLDER_ARG="$2"; shift; shift; ;;
        --output-csv) OUTPUT_CSV_ARG="$2"; shift; shift; ;;
        --address-column) ADDRESS_COLUMN_ARG="$2"; shift; shift; ;;
        --file-pattern) FILE_PATTERN_ARG="$2"; shift; shift; ;;
        *) echo "Unknown option: $1"; exit 1; ;;
    esac
done

# Check for required input folder
if [ -z "$INPUT_FOLDER_ARG" ]; then
    echo "Error: --input-folder is a required argument."
    exit 1
fi
if [ ! -d "$INPUT_FOLDER_ARG" ]; then
    echo "Error: Input folder '$INPUT_FOLDER_ARG' not found or is not a directory."
    exit 1
fi

# Determine the project root using git
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Set the PYTHONPATH to include the project's root directory
export PYTHONPATH="${PROJECT_ROOT}"

# Run the Python script
echo "Running get-uk-places.py..."
python3 "${PROJECT_ROOT}/db/get-uk-places.py" \
    --input-folder "$INPUT_FOLDER_ARG" \
    --output-csv "$OUTPUT_CSV_ARG" \
    --address-column "$ADDRESS_COLUMN_ARG" \
    --file-pattern "$FILE_PATTERN_ARG"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 