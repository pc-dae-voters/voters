#!/usr/bin/env bash

# Upload data to the Voters Manager instance
# Version: 1.1
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Functions ---
function usage() {
    echo "usage: ${0} --data-folder <path_to_data_folder> [--update <sub_path>] [--help] [--debug]" >&2
    echo "This script uploads data to the manager instance using SCP." >&2
    echo "  --data-folder <path>  The path to the data folder to upload." >&2
    echo "  --update <sub_path>   Update specific file/folder within the data folder." >&2
    echo "  --help                Display this help message." >&2
    echo "  --debug               Enable debug mode (set -x)." >&2
    echo
    echo "Examples:" >&2
    echo "  ${0} --data-folder ../data                    # Upload only new files" >&2
    echo "  ${0} --data-folder ../data --update names/    # Update specific subfolder" >&2
    echo "  ${0} --data-folder ../data --update file.csv  # Update specific file" >&2
    exit 1
}

# --- Argument Parsing ---
DATA_FOLDER=""
UPDATE_SUBPATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --data-folder)
            DATA_FOLDER="$2"
            shift 2
            ;;
        --update)
            UPDATE_SUBPATH="$2"
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

if [[ -n "$UPDATE_SUBPATH" ]]; then
    echo "Update mode: $UPDATE_SUBPATH"
    
    # Validate the subpath exists
    SUBPATH_FULL="${DATA_FOLDER_ABS}/${UPDATE_SUBPATH}"
    if [[ ! -e "$SUBPATH_FULL" ]]; then
        echo "Error: Subpath '$UPDATE_SUBPATH' does not exist in '$DATA_FOLDER'" >&2
        exit 1
    fi
    
    echo ""
    echo "Starting update..."
    scp -r -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SUBPATH_FULL" ec2-user@"$INSTANCE_IP":/data/
    
    echo ""
    echo "✅ Update completed successfully!"
    echo "Updated: /data/$(basename "$UPDATE_SUBPATH") on the manager instance."
else
    echo "Mode: Incremental upload (only new files)"
    echo ""
    
    # Create a temporary script to handle incremental upload
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

LOCAL_FOLDER="$1"
REMOTE_IP="$2"
KEY_FILE="$3"

echo "Checking for new files..."

# Get list of files in local folder
find "$LOCAL_FOLDER" -type f | while read -r local_file; do
    # Get relative path from local folder
    rel_path="${local_file#$LOCAL_FOLDER/}"
    
    # Check if file exists on remote
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$REMOTE_IP" "test -f /data/$rel_path" 2>/dev/null; then
        echo "  ✓ $rel_path (exists, skipping)"
    else
        echo "  + $rel_path (new, uploading)"
        # Create remote directory if needed
        remote_dir=$(dirname "/data/$rel_path")
        ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$REMOTE_IP" "mkdir -p $remote_dir"
        # Upload the file
        scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$local_file" ec2-user@"$REMOTE_IP:$remote_dir/"
    fi
done

echo "Checking for files to remove..."

# Get list of files on remote that should be removed
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$REMOTE_IP" "find /data -type f" 2>/dev/null | while read -r remote_file; do
    # Get relative path from /data
    rel_path="${remote_file#/data/}"
    
    # Check if file exists locally
    if [[ -f "$LOCAL_FOLDER/$rel_path" ]]; then
        echo "  ✓ $rel_path (exists locally, keeping)"
    else
        echo "  - $rel_path (missing locally, removing)"
        ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$REMOTE_IP" "rm -f '$remote_file'"
    fi
done

echo "Incremental upload completed!"
EOF

    chmod +x "$TEMP_SCRIPT"
    
    # Execute the incremental upload script
    "$TEMP_SCRIPT" "$DATA_FOLDER_ABS" "$INSTANCE_IP" "$KEY_FILE"
    
    # Clean up
    rm "$TEMP_SCRIPT"
    
    echo ""
    echo "✅ Incremental upload completed successfully!"
    echo "Only new files were uploaded to /data on the manager instance."
fi 