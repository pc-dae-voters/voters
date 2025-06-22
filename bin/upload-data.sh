#!/usr/bin/env bash

# Upload data to the Voters Manager instance
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Functions ---
function usage() {
    echo "usage: ${0} --data-folder <path_to_data_folder> [--help] [--debug]" >&2
    echo "This script uploads data to the manager instance using SCP." >&2
    echo "  --data-folder <path>  The path to the data folder to upload." >&2
    echo "  --help                Display this help message." >&2
    echo "  --debug               Enable debug mode (set -x)." >&2
    echo
    echo "Examples:" >&2
    echo "  ${0} --data-folder ../data" >&2
    echo "  ${0} --data-folder /path/to/my/data" >&2
    exit 1
}

# --- Argument Parsing ---
DATA_FOLDER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --data-folder)
            DATA_FOLDER="$2"
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
if [[ -z "$DATA_FOLDER" ]]; then
    echo "Error: --data-folder is required." >&2
    usage
fi

if [[ ! -d "$DATA_FOLDER" ]]; then
    echo "Error: Data folder '$DATA_FOLDER' does not exist or is not a directory." >&2
    exit 1
fi

# --- Main Logic ---
# Get the project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)
IP_FILE="${PROJECT_ROOT}/infra/aws/mgr-vm/instance-ip.txt"
KEY_FILE="${PROJECT_ROOT}/infra/aws/mgr-vm/loader.key"

# Check if IP file exists
if [[ ! -f "$IP_FILE" ]]; then
    echo "Error: Instance IP file not found at $IP_FILE" >&2
    echo "Please run the Terraform deployment first." >&2
    exit 1
fi

# Check if key file exists
if [[ ! -f "$KEY_FILE" ]]; then
    echo "Error: SSH key file not found at $KEY_FILE" >&2
    echo "Please run the Terraform deployment first." >&2
    exit 1
fi

# Read the IP address
INSTANCE_IP=$(cat "$IP_FILE")

# Get absolute path to data folder
DATA_FOLDER_ABS=$(realpath "$DATA_FOLDER")

echo "Uploading data from: $DATA_FOLDER_ABS"
echo "To instance: $INSTANCE_IP"
echo "Destination: /data"
echo ""

# Upload the data
echo "Starting upload..."
scp -r -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$DATA_FOLDER_ABS" ec2-user@"$INSTANCE_IP":/data/

echo ""
echo "✅ Data upload completed successfully!"
echo "Data is now available at /data/$(basename "$DATA_FOLDER_ABS") on the manager instance." 