#!/usr/bin/env bash

# Create tables in the Voters database from SQL files.
# Version: 1.3
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--help] [--debug]" >&2
    echo "This script connects to the RDS database and creates the tables" >&2
    echo "defined in the .sql files in the 'voters/db' directory." >&2
    echo "  --help   Display this help message" >&2
    echo "  --debug  Enable debug mode (set -x)" >&2
}

if [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
elif [[ "${1:-}" == "--debug" ]]; then
    set -x
fi

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

echo "Successfully fetched connection details."
echo "Host: ${PGHOST}"
echo "Port: ${PGPORT}"
echo "Database: ${PGDATABASE}"
echo "User: ${PGUSER}"

# The order of execution matters due to table dependencies.
SQL_FILES=(
    "countries.sql"
    "places.sql"
    "constituencies.sql"
    "con-postcodes.sql"
    "addresses.sql"
    "citizen-status.sql"
    "voter_status.sql"
    "citizen.sql"
    "voters.sql"
    "first-names.sql"
    "surnames.sql"
    "births.sql"
    "citizen-changes.sql"
)

# Return to the db directory to execute SQL files
cd "${PROJECT_ROOT}/db"

echo "Executing SQL scripts..."
for file in "${SQL_FILES[@]}"; do
    echo " - Running ${file}..."
    psql -f "$file"
done

echo "All tables created successfully." 