#!/usr/bin/env bash

# SSH script for connecting to the Voters Manager instance
# Version: 1.0
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

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

# Construct and execute SSH command
echo "Connecting to manager instance at $INSTANCE_IP..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$INSTANCE_IP" "$@" 