#!/bin/bash

# Source environment variables if they exist
if [ -f .env ]; then
    source .env
fi

# Check if CSV file path is provided
if [ -z "$1" ]; then
    echo "Error: Please provide the path to the CSV file"
    echo "Usage: $0 <path-to-csv>"
    exit 1
fi

# Run the Python script
python3 db/load-constituencies.py --csv-file "$1" 