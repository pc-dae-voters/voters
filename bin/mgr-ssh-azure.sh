#!/usr/bin/env bash

# Azure Manager VM SSH Script
# This script fetches the public IP and SSH key from Terraform to connect to the manager VM.
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

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

echo "Connecting to manager VM at $IP_ADDRESS..."
echo "Username: azureuser"
echo "To execute a command on the remote host, pass it as an argument to this script."
echo "e.g., $0 'ls -l /data'"

# If arguments are provided, execute them as a remote command. Otherwise, start an interactive session.
if [[ $# -gt 0 ]]; then
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "azureuser@$IP_ADDRESS" "$@"
else
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "azureuser@$IP_ADDRESS"
fi
