#!/bin/bash

# Master script to run all data loading shell scripts in the correct order.
# Assumes database schema is already created and environment variables for DB connection are set.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" # pc-dae-voters project root

# --- Default Paths & Parameters (can be overridden by CLI arguments) ---
CONSTITUENCIES_CSV_PATH="$PROJECT_ROOT/data/parl_constituencies_2025.csv" # Example path
CON_POSTCODES_CSV_PATH="$PROJECT_ROOT/data/postcodes_with_con.csv"      # Example path
NAMES_DATA_FOLDER="$PROJECT_ROOT/data/names/data"
ADDRESS_CSVS_INPUT_FOLDER="$PROJECT_ROOT/data/addresses" # For load-address-places & load-addresses
SYNTHETIC_PEOPLE_COUNT="1000"
RANDOM_SEED=""

# --- Helper function to run a script and check its exit code ---
run_loader() {
    local script_name="$1"
    shift # Remove script_name from arguments
    local script_path="$SCRIPT_DIR/$script_name"
    
    echo "----------------------------------------------------------------------"
    echo "Executing: $script_name with arguments: $@"
    echo "----------------------------------------------------------------------"
    
    if [ ! -f "$script_path" ]; then
        echo "Error: Loader script '$script_path' not found. Skipping." >&2
        return 1
    fi

    bash "$script_path" "$@" # Pass remaining arguments to the sub-script
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "Error: '$script_name' failed with exit code $exit_code." >&2
        echo "Aborting further data loading." >&2
        exit $exit_code
    else
        echo "Successfully completed: $script_name"
    fi
    echo ""
}

# --- Parse Master Script Arguments (Optional Overrides) ---
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --constituencies-csv) CONSTITUENCIES_CSV_PATH="$2"; shift; shift; ;;
        --con-postcodes-csv) CON_POSTCODES_CSV_PATH="$2"; shift; shift; ;;
        --names-data-folder) NAMES_DATA_FOLDER="$2"; shift; shift; ;;
        --address-csvs-folder) ADDRESS_CSVS_INPUT_FOLDER="$2"; shift; shift; ;;
        --num-people) SYNTHETIC_PEOPLE_COUNT="$2"; shift; shift; ;;
        --random-seed) RANDOM_SEED="$2"; shift; shift; ;;
        *) echo "Unknown master script option: $1"; exit 1; ;;
    esac
done

# --- Execute loading scripts in order --- 
# These calls assume the sub-scripts can pick up DB connection details from env vars.

# 1. Constituencies
# run-load-con.sh expects --csv-file
run_loader "run-load-con.sh" --csv-file "$CONSTITUENCIES_CSV_PATH"

# 2. Constituency Postcodes
# run-load-con-postcodes.sh expects --csv-file
run_loader "run-load-con-postcodes.sh" --csv-file "$CON_POSTCODES_CSV_PATH"

# 3. First Names & Surnames
# run-load-names-from-csv.sh expects --names-data-folder and optionally --random-seed
LOAD_NAMES_ARGS=(--names-data-folder "$NAMES_DATA_FOLDER")
if [ -n "$RANDOM_SEED" ]; then LOAD_NAMES_ARGS+=(--random-seed "$RANDOM_SEED"); fi
run_loader "run-load-names-from-csv.sh" "${LOAD_NAMES_ARGS[@]}"

# 4. Places (from address CSVs + 'not specified')
# run-load-address-places.sh expects --input-folder (for UK addresses)
# It will generate "not specified" for all countries in the DB internally.
run_loader "run-load-address-places.sh" --input-folder "$ADDRESS_CSVS_INPUT_FOLDER"

# 5. Addresses (from address CSVs)
# run-load-addresses.sh expects --input-folder
run_loader "run-load-addresses.sh" --input-folder "$ADDRESS_CSVS_INPUT_FOLDER"

# 6. Synthetic People (Citizens & Births)
# run-load-synthetic-people.sh expects --num-people and optionally --random-seed
SYNTHETIC_ARGS=(--num-people "$SYNTHETIC_PEOPLE_COUNT")
if [ -n "$RANDOM_SEED" ]; then SYNTHETIC_ARGS+=(--random-seed "$RANDOM_SEED"); fi
run_loader "run-load-synthetic-people.sh" "${SYNTHETIC_ARGS[@]}"


echo "----------------------------------------------------------------------"
echo "All data loading scripts completed successfully!"
echo "----------------------------------------------------------------------"

exit 0 