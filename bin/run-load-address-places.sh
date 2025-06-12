#!/bin/bash

# Script to load place names from address CSVs into the places table

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Database Connection Parameters (from environment or command line) ---
DB_HOST=${PGHOST}
DB_PORT=${PGPORT}
DB_NAME=${PGDATABASE}
DB_USER=${PGUSER}
DB_PASSWORD=${PGPASSWORD}

# --- Script Specific Parameters ---
INPUT_FOLDER_ARG=""
ADDRESS_COLUMN_ARG="ADDRESS" # Default value in Python script
PLACES_TABLE_ARG="places"   # Default value in Python script
FILE_PATTERN_ARG="addresses*.csv" # Default value in Python script

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --pghost) DB_HOST="$2"; shift; shift; ;;
        --pgport) DB_PORT="$2"; shift; shift; ;;
        --pgdatabase) DB_NAME="$2"; shift; shift; ;;
        --pguser) DB_USER="$2"; shift; shift; ;;
        --pgpassword) DB_PASSWORD="$2"; shift; shift; ;;
        --input-folder) INPUT_FOLDER_ARG="$2"; shift; shift; ;;
        --address-column) ADDRESS_COLUMN_ARG="$2"; shift; shift; ;;
        --places-table) PLACES_TABLE_ARG="$2"; shift; shift; ;;
        --file-pattern) FILE_PATTERN_ARG="$2"; shift; shift; ;;
        *) echo "Unknown option: $1"; exit 1; ;;
    esac
done

# Check for required DB connection parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Missing PostgreSQL connection parameters. Set PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD or use command-line options."
    exit 1
fi

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
echo "Running load-address-places.py..."
python3 "${PROJECT_ROOT}/db/load-address-places.py"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 