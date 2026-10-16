#!/usr/bin/env bash

# Azure Data Upload Script
# This script uploads data files to the manager VM using rsync over SSH.
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Functions ---
function usage() {
    echo "usage: ${0} --data-folder <path>" >&2
    echo "This script uploads data to the Azure manager VM." >&2
    echo
    echo "Options:"
    echo "  --data-folder <path>  Path to the local folder containing the data to upload."
    echo "  --help                Display this help message."
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
        *)
            echo "Error: Unknown argument: $1" >&2
            usage
            ;;
    esac
done

if [[ -z "$DATA_FOLDER" ]]; then
    echo "Error: --data-folder is a required argument." >&2
    usage
fi

if [[ ! -d "$DATA_FOLDER" ]]; then
    echo "Error: Data folder not found at '$DATA_FOLDER'" >&2
    exit 1
fi

# --- Main Logic ---
TF_MODULE_PATH="infra/azure"

# Check if we're in the right directory
if [[ ! -d "$TF_MODULE_PATH" ]]; then
    echo "Error: This script must be run from the 'voters' project root directory." >&2
    exit 1
fi

echo "Fetching connection details from Terraform outputs in $TF_MODULE_PATH..."

# Fetch the public IP address
IP_ADDRESS=$(terraform -chdir="$TF_MODULE_PATH" output -raw manager_vm_public_ip)
if [[ -z "$IP_ADDRESS" ]]; then
    echo "Error: Could not retrieve the public IP address of the manager VM." >&2
    echo "Please ensure that the core Azure infrastructure has been created successfully." >&2
    exit 1
fi

# Fetch the private SSH key and save to a temporary file
SSH_KEY_FILE=$(mktemp)
trap 'rm -f "$SSH_KEY_FILE"' EXIT
terraform -chdir="$TF_MODULE_PATH" output -raw manager_vm_private_ssh_key > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

echo "Uploading data from '$DATA_FOLDER' to azureuser@$IP_ADDRESS:/mnt/data/uploads/"

# Use rsync to upload the data. Trailing slash on source is important!
rsync -avz -e "ssh -i $SSH_KEY_FILE -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "${DATA_FOLDER}/" "azureuser@${IP_ADDRESS}:/mnt/data/uploads/"

echo "Data upload completed successfully!"
