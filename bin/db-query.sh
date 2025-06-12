#!/usr/bin/env bash

# Query the Voters database.
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Configuration ---
TABLE=""
SHOW_LAYOUT=false
SHOW_COUNT=false
SHOW_ROWS=0

# --- Functions ---
function usage() {
    echo "usage: ${0} --table <table_name> [--layout] [--count] [--show-rows <n>] [--help] [--debug]" >&2
    echo "This script queries the RDS database. You can combine --layout, --count, and --show-rows." >&2
    echo "  --table <table_name>  The name of the table to query." >&2
    echo "  --layout              Display the table layout (schema)." >&2
    echo "  --count               Display the number of rows in the table." >&2
    echo "  --show-rows <n>       Display the first 'n' rows of the table." >&2
    echo "  --help                Display this help message." >&2
    echo "  --debug               Enable debug mode (set -x)." >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --table)
            TABLE="$2"
            shift 2
            ;;
        --layout)
            SHOW_LAYOUT=true
            shift
            ;;
        --count)
            SHOW_COUNT=true
            shift
            ;;
        --show-rows)
            SHOW_ROWS="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        --debug)
            set -x
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

# --- Validation ---
if [[ -z "$TABLE" ]]; then
    echo "Error: --table is a required argument." >&2
    usage
fi

if [[ "$SHOW_LAYOUT" == false && "$SHOW_COUNT" == false && $SHOW_ROWS -eq 0 ]]; then
    echo "Error: You must specify at least one action: --layout, --count, or --show-rows." >&2
    usage
fi

# --- Main Logic ---
# Check for psql dependency
if ! command -v psql &> /dev/null; then
    echo "Error: psql is not installed or not in your PATH." >&2
    echo "Please install the PostgreSQL client tools." >&2
    exit 1
fi

# Determine the project root using git
PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV_FILE="${PROJECT_ROOT}/infra/db/db-env.sh"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Error: Database environment file not found at ${ENV_FILE}" >&2
    echo "Please run 'do-terraform.sh db apply' to generate it." >&2
    exit 1
fi

source "${ENV_FILE}"

# Construct and execute psql command(s)
if [[ "$SHOW_LAYOUT" == true ]]; then
    echo
    echo "--- Table Layout for '${TABLE}' ---"
    psql -c "\d \"$TABLE\""
fi

if [[ "$SHOW_COUNT" == true ]]; then
    echo
    echo "--- Row Count for '${TABLE}' ---"
    psql -c "SELECT COUNT(*) FROM \"$TABLE\";"
fi

if (( SHOW_ROWS > 0 )); then
    echo
    echo "--- First ${SHOW_ROWS} rows from '${TABLE}' ---"
    psql -c "SELECT * FROM \"$TABLE\" LIMIT $SHOW_ROWS;"
fi 