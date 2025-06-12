#!/bin/bash

# Script to run the load-addresses.py Python script to populate the addresses table.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT_PATH="$PROJECT_ROOT/voters/db/load-addresses.py"

# --- Database Connection Parameters (from environment or command line) ---
DB_HOST=${PGHOST}
DB_PORT=${PGPORT:-5432} # Default to 5432 if not set
DB_NAME=${PGDATABASE}
DB_USER=${PGUSER}
DB_PASSWORD=${PGPASSWORD}

# --- Script Specific Parameters ---
# Default input folder assumes a 'data/addresses' structure in the project root
INPUT_FOLDER_ARG="$PROJECT_ROOT/data/addresses"
ADDRESS_COLUMN_ARG="Address"      # Default value in Python script
POSTCODE_COLUMN_ARG="Postcode"    # Default value in Python script
FILE_PATTERN_ARG="*.csv"          # Default value in Python script
TARGET_COUNTRY_ARG="United Kingdom" # Default value in Python script

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
        --postcode-column) POSTCODE_COLUMN_ARG="$2"; shift; shift; ;;
        --file-pattern) FILE_PATTERN_ARG="$2"; shift; shift; ;;
        --target-country) TARGET_COUNTRY_ARG="$2"; shift; shift; ;;
        *) echo "Unknown option: $1"; exit 1; ;;
    esac
done

# Check for required DB connection parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Missing PostgreSQL connection parameters. Set PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD or use command-line options."
    exit 1
fi

# Check if input folder exists
if [ ! -d "$INPUT_FOLDER_ARG" ]; then
    echo "Error: Input folder '$INPUT_FOLDER_ARG' not found or is not a directory."
    exit 1
fi

# Check if venv and Python script exist
if [ ! -d "$VENV_PATH/bin" ]; then echo "Error: Virtual environment not found at $VENV_PATH. Run setup-venv.sh from project root."; exit 1; fi
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then echo "Error: Python script not found at $PYTHON_SCRIPT_PATH"; exit 1; fi

echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo "Running Python script to load addresses..."
python3 "$PYTHON_SCRIPT_PATH" \
    --pghost "$DB_HOST" \
    --pgport "$DB_PORT" \
    --pgdatabase "$DB_NAME" \
    --pguser "$DB_USER" \
    --pgpassword "$DB_PASSWORD" \
    --input-folder "$INPUT_FOLDER_ARG" \
    --address-column "$ADDRESS_COLUMN_ARG" \
    --postcode-column "$POSTCODE_COLUMN_ARG" \
    --file-pattern "$FILE_PATTERN_ARG" \
    --target-country "$TARGET_COUNTRY_ARG"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 