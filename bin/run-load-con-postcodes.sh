#!/bin/bash

# Script to activate virtual environment and run the Python con_postcodes data loading script

# Determine the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths relative to the SCRIPT_DIR
PROJECT_ROOT="$SCRIPT_DIR/../.."
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT_PATH="$PROJECT_ROOT/voters/db/load-con-postcodes.py"
DEFAULT_CSV_FILE="$PROJECT_ROOT/voters/db/postcodes_with_con.csv"

# --- Database Connection Parameters ---
DB_HOST=${PGHOST}
DB_PORT=${PGPORT}
DB_NAME=${PGDATABASE}
DB_USER=${PGUSER}
DB_PASSWORD=${PGPASSWORD}

# --- Python script arguments ---
TABLE_NAME_ARG="con_postcodes"
CSV_FILE_PATH_ARG=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --pghost) DB_HOST="$2"; shift; shift; ;;
        --pgport) DB_PORT="$2"; shift; shift; ;;
        --pgdatabase) DB_NAME="$2"; shift; shift; ;;
        --pguser) DB_USER="$2"; shift; shift; ;;
        --pgpassword) DB_PASSWORD="$2"; shift; shift; ;;
        --table) TABLE_NAME_ARG="$2"; shift; shift; ;;
        --csv-file) CSV_FILE_PATH_ARG="$2"; shift; shift; ;;
        *) echo "Unknown option: $1"; exit 1; ;;
    esac
done

# Use default CSV file path if not provided
if [ -z "$CSV_FILE_PATH_ARG" ]; then
    CSV_FILE_PATH_ARG="$DEFAULT_CSV_FILE"
fi

# Check for required DB connection parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Missing PostgreSQL connection parameters. Set PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD or use command-line options."
    exit 1
fi

# Check if venv, Python script, and CSV file exist
if [ ! -d "$VENV_PATH/bin" ]; then echo "Virtual environment not found at $VENV_PATH. Run setup-venv.sh."; exit 1; fi
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then echo "Python script not found at $PYTHON_SCRIPT_PATH"; exit 1; fi
if [ ! -f "$CSV_FILE_PATH_ARG" ]; then echo "CSV file not found at $CSV_FILE_PATH_ARG. Use --csv-file to specify."; exit 1; fi

# Activate venv and run script
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo "Running Python script: $PYTHON_SCRIPT_PATH with CSV $CSV_FILE_PATH_ARG..."
python3 "$PYTHON_SCRIPT_PATH" \
    --pghost "$DB_HOST" \
    --pgport "$DB_PORT" \
    --pgdatabase "$DB_NAME" \
    --pguser "$DB_USER" \
    --pgpassword "$DB_PASSWORD" \
    --table "$TABLE_NAME_ARG" \
    --csv-file "$CSV_FILE_PATH_ARG"

# deactivate (optional)
echo "Script finished." 