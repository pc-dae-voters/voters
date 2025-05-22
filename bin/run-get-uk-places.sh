#!/bin/bash

# Script to run the get-uk-places.py Python script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT_PATH="$PROJECT_ROOT/voters/db/get-uk-places.py"

# --- Script Specific Parameters ---
INPUT_FOLDER_ARG=""
OUTPUT_CSV_ARG="$PROJECT_ROOT/voters/db/places.csv" # Default output file
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

# Check if venv and Python script exist
if [ ! -d "$VENV_PATH/bin" ]; then echo "Virtual environment not found at $VENV_PATH. Run setup-venv.sh from project root."; exit 1; fi
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then echo "Python script not found at $PYTHON_SCRIPT_PATH"; exit 1; fi

echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo "Running Python script to extract UK place names..."
python3 "$PYTHON_SCRIPT_PATH" \
    --input-folder "$INPUT_FOLDER_ARG" \
    --output-csv "$OUTPUT_CSV_ARG" \
    --address-column "$ADDRESS_COLUMN_ARG" \
    --file-pattern "$FILE_PATTERN_ARG"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 