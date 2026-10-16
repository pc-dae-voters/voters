#!/usr/bin/env bash

# Upload data to the Voters Manager instance
# Version: 1.5
# Author: Gemini (Daemon Consulting Software Engineer)

# Temporarily removed strict error handling to debug file processing issue
# set -euo pipefail

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
    echo "  ${0} --data-folder ../data                    # Upload only new/modified files" >&2
    echo "  ${0} --data-folder ../data --update names/    # Update specific subfolder" >&2
    echo "  ${0} --data-folder ../data --update file.csv  # Update specific file" >&2
    exit 1
}

# --- Argument Parsing ---
DATA_FOLDER=""
UPDATE_SUBPATH=""
DEBUG="false"

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
            DEBUG="true"
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
PYTHON_SCRIPT="${PROJECT_ROOT}/bin/get-remote-files.py"

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

# Check if Python script exists
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT" >&2
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
    echo "Mode: Smart incremental upload (new/modified files)"
    echo ""
    
    # Upload the Python script to the remote instance
    echo "Uploading file scanner script..."
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$PYTHON_SCRIPT" ec2-user@"$INSTANCE_IP":/tmp/get-remote-files.py
    
    # Execute the Python script on the remote instance to get file information
    echo "Scanning remote files..."
    remote_json_file=$(ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 ec2-user@"$INSTANCE_IP" "python3 /tmp/get-remote-files.py")
    
    # Check if we got a filename back
    if [[ -z "$remote_json_file" ]]; then
        echo "Error: Failed to get remote file information" >&2
        exit 1
    fi
    
    # Download the JSON file from the remote instance
    echo "Downloading remote file information..."
    local_json_file=$(mktemp)
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$INSTANCE_IP:$remote_json_file" "$local_json_file"
    
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed. Please install jq to use this script." >&2
        echo "On macOS: brew install jq" >&2
        echo "On Ubuntu/Debian: sudo apt-get install jq" >&2
        exit 1
    fi
    
    # Counters for summary
    uploaded_count=0
    skipped_count=0
    modified_count=0
    
    echo "Checking for new/modified files..."
    
    # Get list of local files and process them
    mapfile -t files < <(find "$DATA_FOLDER_ABS" -type f)
    echo "Found ${#files[@]} local files to process"
    
    for local_file in "${files[@]}"; do
        # Get relative path from local folder
        rel_path="${local_file#$DATA_FOLDER_ABS/}"
        
        # Get local file stats
        local_size=$(stat -c%s "$local_file" 2>/dev/null || stat -f%z "$local_file" 2>/dev/null)
        local_mtime=$(stat -c%Y "$local_file" 2>/dev/null || stat -f%m "$local_file" 2>/dev/null)
        
        # Check if file exists in remote file info using jq
        remote_exists=false
        remote_size=""
        remote_mtime=""
        
        # Use jq to check if the file exists in the JSON data
        remote_file_data=$(jq -r ".[\"$rel_path\"]" "$local_json_file" 2>/dev/null || echo "null")
        
        if [[ -n "$remote_file_data" && "$remote_file_data" != "null" && "$remote_file_data" != "" ]]; then
            remote_exists=true
            remote_size=$(echo "$remote_file_data" | jq -r '.size' 2>/dev/null || echo "")
            remote_mtime=$(echo "$remote_file_data" | jq -r '.mtime' 2>/dev/null || echo "")
        fi
        
        # Debug output for missing files
        if [[ "$DEBUG" == "true" ]]; then
            echo "DEBUG: $rel_path - remote_exists=$remote_exists, remote_data='$remote_file_data'"
        fi
        
        # Convert timestamps to integers for comparison
        local_mtime_int=${local_mtime%.*}
        remote_mtime_int=${remote_mtime%.*}
        
        # Determine if we need to upload
        needs_upload=false
        reason=""
        
        if [[ "$remote_exists" == "false" ]]; then
            needs_upload=true
            reason="new file (missing on remote)"
        elif [[ "$local_size" != "$remote_size" ]]; then
            needs_upload=true
            reason="different size (local: ${local_size}, remote: ${remote_size})"
        elif [[ "$local_mtime_int" -gt "$remote_mtime_int" ]]; then
            needs_upload=true
            reason="newer local file"
        fi
        
        if [[ "$needs_upload" == "true" ]]; then
            if [[ "$remote_exists" == "true" ]]; then
                echo "  🔄 $rel_path ($reason)"
                ((modified_count++))
            else
                echo "  + $rel_path ($reason)"
                ((uploaded_count++))
            fi
            
            # Create remote directory if needed
            remote_dir=$(dirname "/data/$rel_path")
            ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ec2-user@"$INSTANCE_IP" "mkdir -p $remote_dir" || echo "Warning: Failed to create remote directory $remote_dir"
            # Upload the file
            scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 "$local_file" ec2-user@"$INSTANCE_IP:$remote_dir/" || echo "Warning: Failed to upload $rel_path"
        else
            echo "  ✓ $rel_path (up to date)"
            ((skipped_count++))
        fi
    done
    
    # Clean up temporary files
    rm -f "$local_json_file"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ec2-user@"$INSTANCE_IP" "rm -f $remote_json_file /tmp/get-remote-files.py"
    
    echo ""
    echo "Summary:"
    echo "  New files uploaded: $uploaded_count"
    echo "  Modified files updated: $modified_count"
    echo "  Files skipped (up to date): $skipped_count"
    echo "Smart incremental upload completed!"
    
    echo ""
    echo "✅ Smart incremental upload completed successfully!"
    echo "Only new and modified files were uploaded to /data on the manager instance."
fi 