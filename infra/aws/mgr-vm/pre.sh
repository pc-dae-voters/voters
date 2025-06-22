#!/usr/bin/env bash

# Pre-execution script for mgr-vm Terraform module
# This script handles cleanup operations before Terraform runs

set -euo pipefail

echo "--- Pre-execution: Checking EBS volume attachment ---"

# Get the volume ID from the data volume remote state
VOLUME_ID=$(cd /Users/paul/go/src/github.com/pc-dae-voters/voters/infra/aws/data-volume && terraform output -raw volume_id 2>/dev/null || echo "")

if [[ -z "$VOLUME_ID" ]]; then
    echo "No volume ID found in data-volume remote state, skipping volume detachment check."
    return 0
fi

echo "Found volume ID: $VOLUME_ID"

# Check if the volume is attached to any instance
ATTACHMENT_INFO=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].Attachments[0]' --output json 2>/dev/null || echo "null")

if [[ "$ATTACHMENT_INFO" == "null" || "$ATTACHMENT_INFO" == "[]" ]]; then
    echo "Volume $VOLUME_ID is not attached to any instance."
    return 0
fi

# Extract instance ID and device name
INSTANCE_ID=$(echo "$ATTACHMENT_INFO" | jq -r '.InstanceId // empty')
DEVICE_NAME=$(echo "$ATTACHMENT_INFO" | jq -r '.Device // empty')

if [[ -z "$INSTANCE_ID" ]]; then
    echo "Could not determine instance ID for volume $VOLUME_ID."
    return 0
fi

echo "Volume $VOLUME_ID is attached to instance $INSTANCE_ID at device $DEVICE_NAME"

# Check if this is the current instance we're about to create
# We'll compare with the instance ID from the current state if it exists
CURRENT_INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")

if [[ "$INSTANCE_ID" == "$CURRENT_INSTANCE_ID" ]]; then
    echo "Volume is already attached to the current instance, no action needed."
    return 0
fi

# Detach the volume from the other instance
echo "Detaching volume $VOLUME_ID from instance $INSTANCE_ID..."
aws ec2 detach-volume --volume-id "$VOLUME_ID" --force

# Wait for the volume to be detached
echo "Waiting for volume to be detached..."
aws ec2 wait volume-available --volume-ids "$VOLUME_ID"

echo "Volume $VOLUME_ID successfully detached from instance $INSTANCE_ID"
echo "--- Pre-execution: Complete ---" 