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

activate_venv
echo "Installing dependencies..."
pip3 install -r "$SCRIPT_DIR/../db/requirements.txt"

function run_python_loader() {
    local loader_script=$1
    echo "--- Running $loader_script ---"
    if ! python3 "$SCRIPT_DIR/../db/$loader_script"; then
        echo "Error: $loader_script failed. Aborting." >&2
        exit 1
    fi
}

echo "Starting data loading process..."

run_python_loader "load-constituencies.py"
run_python_loader "load-con-postcodes.py"
run_python_loader "load-names-from-csv.py"
run_python_loader "get-uk-places.py"
run_python_loader "load-places.py"
run_python_loader "load-addresses.py"
run_python_loader "load-address-places.py"
run_python_loader "load-synthetic-people.py"
run_python_loader "load-voters.py"

echo "Data loading process completed successfully." 