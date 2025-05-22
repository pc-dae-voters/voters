#!/bin/bash

# Script to activate virtual environment and run the Python places data loading script

# Determine the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths relative to the SCRIPT_DIR
# Project root is two levels up from pc-dae-voters/voters/bin/
PROJECT_ROOT="$SCRIPT_DIR/../.."
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT_PATH="$PROJECT_ROOT/voters/db/load-places.py" # Path to the new script

# --- Database Connection Parameters ---
# Initialize with environment variables as defaults
DB_HOST=${PGHOST}
DB_PORT=${PGPORT}
DB_NAME=${PGDATABASE}
DB_USER=${PGUSER}
DB_PASSWORD=${PGPASSWORD}

# --- Python script arguments ---
TABLE_NAME_ARG="places" # Default table name for places
# Default path to the CSV file, relative to the project root
DEFAULT_CSV_FILE_PATH="$PROJECT_ROOT/voters/db/uk-cities.csv"
CSV_FILE_PATH_ARG=""

# Parse command-line arguments to override environment variables or set script args
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --pghost)
        DB_HOST="$2"
        shift # past argument
        shift # past value
        ;;
        --pgport)
        DB_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --pgdatabase)
        DB_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --pguser)
        DB_USER="$2"
        shift # past argument
        shift # past value
        ;;
        --pgpassword)
        DB_PASSWORD="$2"
        shift # past argument
        shift # past value
        ;;
        --table)
        TABLE_NAME_ARG="$2"
        shift # past argument
        shift # past value
        ;;
        --csv-file)
        CSV_FILE_PATH_ARG="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Use default CSV file path if not provided via argument
if [ -z "$CSV_FILE_PATH_ARG" ]; then
    CSV_FILE_PATH_ARG="$DEFAULT_CSV_FILE_PATH"
fi

# Check for required database connection parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Missing one or more PostgreSQL connection environment variables or command-line arguments."
    echo "Please set PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD environment variables,"
    echo "or pass them as --pghost, --pgport, --pgdatabase, --pguser, --pgpassword arguments."
    echo "Example: ./run-load-places-script.sh --pghost localhost --pgport 5432 --pgdatabase mydb --pguser myuser --pgpassword mypass"
    exit 1
fi

# Check if the virtual environment exists
if [ ! -d "$VENV_PATH/bin" ]; then
    echo "Virtual environment not found at $VENV_PATH"
    echo "Please run the setup-venv.sh script first from the project root (pc-dae-voters/)"
    echo "e.g., cd $PROJECT_ROOT && ./bin/setup-venv.sh"
    exit 1
fi

# Check if the Python script exists
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
    echo "Python script not found at $PYTHON_SCRIPT_PATH"
    exit 1
fi

# Check if the CSV file exists
if [ ! -f "$CSV_FILE_PATH_ARG" ]; then
    echo "CSV file not found at $CSV_FILE_PATH_ARG"
    echo "Please ensure the file exists or provide the correct path using --csv-file argument."
    exit 1
fi

# Activate the virtual environment
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Run the Python script with all necessary arguments
echo "Running Python script: $PYTHON_SCRIPT_PATH with CSV $CSV_FILE_PATH_ARG..."
python3 "$PYTHON_SCRIPT_PATH" \
    --pghost "$DB_HOST" \
    --pgport "$DB_PORT" \
    --pgdatabase "$DB_NAME" \
    --pguser "$DB_USER" \
    --pgpassword "$DB_PASSWORD" \
    --table "$TABLE_NAME_ARG" \
    --csv-file "$CSV_FILE_PATH_ARG"

# Deactivate the virtual environment (optional, as script ends here)
# deactivate

echo "Script finished." 