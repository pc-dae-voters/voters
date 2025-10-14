#!/bin/bash

# This script orchestrates the loading of all data into the database.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(git rev-parse --show-toplevel)
VENV_DIR="$PROJECT_ROOT/.venv"

# Source the database environment variables
DB_ENV_FILE="$PROJECT_ROOT/infra/db/db-env.sh"

if [[ -f "$DB_ENV_FILE" ]]; then
    source "$DB_ENV_FILE"
else
    echo "Warning: Database environment file not found. Using default local values."
    export PGHOST="${PGHOST:-localhost}"
    export PGPORT="${PGPORT:-5432}"
    export PGDATABASE="${PGDATABASE:-voters}"
    export PGUSER="${PGUSER:-postgres}"
    export PGPASSWORD="${PGPASSWORD:-password}"
fi

# Function to activate virtual environment
activate_venv() {
    echo "Activating virtual environment..."
    if [[ ! -f "${VENV_DIR}/bin/activate" ]]; then
        echo "Virtual environment not found, creating..."
        python3 -m venv "${VENV_DIR}"
    fi
    source "${VENV_DIR}/bin/activate"
}

# --- Configuration ---
DATA_DIR="/data"
CONSTITUENCIES_CSV="${DATA_DIR}/parl_constituencies_2025.csv"
CON_POSTCODES_CSV="${DATA_DIR}/postcodes_with_con.csv"
ADDRESSES_FOLDER="${DATA_DIR}/addresses"
NAMES_FOLDER="${DATA_DIR}/names/data"
UK_PLACES_CSV="${DATA_DIR}/uk_places.csv"
NUM_PEOPLE=10000
RANDOM_SEED=12345

echo "Loading data into database..."
echo "Using configuration:"
echo "  Constituencies CSV: ${CONSTITUENCIES_CSV}"
echo "  Constituency Postcodes CSV: ${CON_POSTCODES_CSV}"
echo "  Addresses Folder: ${ADDRESSES_FOLDER}"
echo "  Names Folder: ${NAMES_FOLDER}"
echo "  Number of People: ${NUM_PEOPLE}"
echo "  Random Seed: ${RANDOM_SEED}"

activate_venv
echo "Installing dependencies..."
pip3 install -r "$SCRIPT_DIR/../db/requirements.txt"

function run_python_loader() {
    local loader_script=$1
    shift # remove the script name from the arguments list
    echo "--- Running $loader_script ---"
    python3 "$SCRIPT_DIR/../db/$loader_script" "$@"
    if [ $? -ne 0 ]; then
        echo "Error: $loader_script failed. Aborting."
        exit 1
    fi
}

echo "Starting data loading process..."

run_python_loader "load-constituencies.py" --csv-file "$CONSTITUENCIES_CSV"
run_python_loader "load-con-postcodes.py" --csv-file "$CON_POSTCODES_CSV"
run_python_loader "load-names-from-csv.py" --names-data-folder "$NAMES_FOLDER" --random-seed "$RANDOM_SEED"
run_python_loader "load-places.py" --addresses-folder "$ADDRESSES_FOLDER"
run_python_loader "load-address-places.py" --input-folder "$ADDRESSES_FOLDER"
run_python_loader "load-addresses.py" --input-folder "$ADDRESSES_FOLDER"
run_python_loader "load-synthetic-people.py" --num-people "$NUM_PEOPLE" --random-seed "$RANDOM_SEED"
run_python_loader "load-voters.py" --num-people "$NUM_PEOPLE" --random-seed "$RANDOM_SEED"

echo "Data loading process completed." 