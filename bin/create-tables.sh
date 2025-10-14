#!/usr/bin/env bash

# Create tables in the Voters database from SQL files.
# Version: 1.4
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# Define available tables and their dependencies
declare -A TABLE_DEPENDENCIES=(
    ["countries"]=""
    ["places"]="countries"
    ["constituencies"]=""
    ["con-postcodes"]="constituencies"
    ["addresses"]="places"
    ["citizen-status"]=""
    ["citizen"]="citizen-status"
    ["voters"]="addresses citizen"
    ["first-names"]=""
    ["surnames"]=""
    ["births"]="voters"
    ["citizen-changes"]="citizen"
    ["marriages"]="citizen"
)

function usage() {
    echo "usage: ${0} [--help] [--debug] [--delete] [--tables TABLE1,TABLE2,...]" >&2
    echo "This script connects to the RDS database and creates/updates the tables" >&2
    echo "defined in the .sql files in the 'voters/db' directory." >&2
    echo "  --help     Display this help message" >&2
    echo "  --debug    Enable debug mode (set -x)" >&2
    echo "  --delete   Delete existing tables before creating new ones" >&2
    echo "  --tables   Comma-separated list of tables to create/update" >&2
    echo "             Available tables: ${!TABLE_DEPENDENCIES[*]}" >&2
}

function get_dependent_tables() {
    local table=$1
    local deps=()
    local visited=()
    
    function visit() {
        local t=$1
        if [[ " ${visited[*]} " =~ " ${t} " ]]; then
            return
        fi
        visited+=("$t")
        local dep=${TABLE_DEPENDENCIES[$t]}
        if [[ -n "$dep" ]]; then
            for d in $dep; do
                visit "$d"
            done
        fi
        deps+=("$t")
    }
    
    visit "$table"
    echo "${deps[@]}"
}

function delete_table() {
    local table=$1
    echo "Dropping table ${table}..."
    psql -c "DROP TABLE IF EXISTS \"${table}\" CASCADE;"
}

# Parse command line arguments
DELETE_TABLES=false
SELECTED_TABLES=""
DEBUG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            usage
            exit 0
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --delete)
            DELETE_TABLES=true
            shift
            ;;
        --tables)
            SELECTED_TABLES=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ "$DEBUG" == "true" ]]; then
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
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DB_DIR="$SCRIPT_DIR/../db"

# Source the database environment variables
DB_ENV_FILE="$SCRIPT_DIR/../infra/db/db-env.sh"

if [[ -f "$DB_ENV_FILE" ]]; then
    echo "Loading database environment file..."
    source "$DB_ENV_FILE"
else
    echo "Warning: Database environment file not found. Using default local values."
    export PGHOST="${PGHOST:-localhost}"
    export PGPORT="${PGPORT:-5432}"
    export PGDATABASE="${PGDATABASE:-voters}"
    export PGUSER="${PGUSER:-postgres}"
    export PGPASSWORD="${PGPASSWORD:-password}"
fi

echo "Successfully fetched connection details."
echo "Host: ${PGHOST}"
echo "Port: ${PGPORT}"
echo "Database: ${PGDATABASE}"
echo "User: ${PGUSER}"

# Process selected tables
if [[ -n "$SELECTED_TABLES" ]]; then
    # Convert comma-separated list to array
    IFS=',' read -ra REQUESTED_TABLES <<< "$SELECTED_TABLES"
    
    # Validate requested tables
    for table in "${REQUESTED_TABLES[@]}"; do
        if [[ ! -v "TABLE_DEPENDENCIES[$table]" ]]; then
            echo "Error: Unknown table '$table'" >&2
            echo "Available tables: ${!TABLE_DEPENDENCIES[*]}" >&2
            exit 1
        fi
    done
    
    # Get all required tables including dependencies
    SQL_FILES=()
    for table in "${REQUESTED_TABLES[@]}"; do
        deps=($(get_dependent_tables "$table"))
        for dep in "${deps[@]}"; do
            SQL_FILES+=("${dep}.sql")
        done
    done
    
    # Remove duplicates while preserving order
    SQL_FILES=($(printf "%s\n" "${SQL_FILES[@]}" | sort -u))
else
    # Use all tables in dependency order
    SQL_FILES=(
        "countries.sql"
        "places.sql"
        "constituencies.sql"
        "con-postcodes.sql"
        "addresses.sql"
        "citizen-status.sql"
        "citizen.sql"
        "voters.sql"
        "first-names.sql"
        "surnames.sql"
        "births.sql"
        "citizen-changes.sql"
        "marriages.sql"
    )
fi

# Return to the db directory to execute SQL files
cd "${PROJECT_ROOT}/db"

echo "Executing SQL scripts..."
for file in "${SQL_FILES[@]}"; do
    table_name=${file%.sql}
    if [[ "$DELETE_TABLES" == "true" ]]; then
        delete_table "$table_name"
    fi
    echo " - Running ${file}..."
    psql -f "$file"
done

echo "All tables created successfully." 