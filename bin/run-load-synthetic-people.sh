#!/bin/bash

# Script to run the load-synthetic-people.py Python script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT_PATH="$PROJECT_ROOT/voters/db/load-synthetic-people.py"

# --- Database Connection Parameters (from environment or command line) ---
DB_HOST=${PGHOST}
DB_PORT=${PGPORT:-5432}
DB_NAME=${PGDATABASE}
DB_USER=${PGUSER}
DB_PASSWORD=${PGPASSWORD}

# --- Script Specific Parameters ---
NUM_PEOPLE_ARG="1000" # Default number of people to generate
RANDOM_SEED_ARG=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --pghost) DB_HOST="$2"; shift; shift; ;;
        --pgport) DB_PORT="$2"; shift; shift; ;;
        --pgdatabase) DB_NAME="$2"; shift; shift; ;;
        --pguser) DB_USER="$2"; shift; shift; ;;
        --pgpassword) DB_PASSWORD="$2"; shift; shift; ;;
        --num-people) NUM_PEOPLE_ARG="$2"; shift; shift; ;;
        --random-seed) RANDOM_SEED_ARG="$2"; shift; shift; ;;
        *) echo "Unknown option: $1"; exit 1; ;;
    esac
done

# Check for required DB connection parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Missing PostgreSQL connection parameters. Set PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD or use command-line options."
    exit 1
fi

# Check if venv and Python script exist
if [ ! -d "$VENV_PATH/bin" ]; then echo "Error: Virtual environment not found at $VENV_PATH. Run setup-venv.sh from project root."; exit 1; fi
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then echo "Error: Python script not found at $PYTHON_SCRIPT_PATH"; exit 1; fi

echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo "Running Python script to load synthetic people data using names from DB tables..."
CMD_ARGS=(
    "$PYTHON_SCRIPT_PATH" \
    --pghost "$DB_HOST" \
    --pgport "$DB_PORT" \
    --pgdatabase "$DB_NAME" \
    --pguser "$DB_USER" \
    --pgpassword "$DB_PASSWORD" \
    --num-people "$NUM_PEOPLE_ARG"
)

if [ -n "$RANDOM_SEED_ARG" ]; then
    CMD_ARGS+=(--random-seed "$RANDOM_SEED_ARG")
fi

python3 "${CMD_ARGS[@]}"

SCRIPT_EXIT_CODE=$?

echo "Script finished with exit code $SCRIPT_EXIT_CODE."
exit $SCRIPT_EXIT_CODE 