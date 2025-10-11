#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Source the database environment variables
DB_ENV_FILE="$SCRIPT_DIR/../infra/db/db-env.sh"

if [[ -f "$DB_ENV_FILE" ]]; then
    source "$DB_ENV_FILE"
else
    # Use default local values if not set
    export PGHOST="${PGHOST:-localhost}"
    export PGPORT="${PGPORT:-5432}"
    export PGDATABASE="${PGDATABASE:-voters}"
    export PGUSER="${PGUSER:-postgres}"
    export PGPASSWORD="${PGPASSWORD:-password}"
fi

echo "Loading addresses..."
python3 "$SCRIPT_DIR/../db/load-addresses.py" 