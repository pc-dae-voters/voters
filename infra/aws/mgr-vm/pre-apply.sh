#!/usr/bin/env bash

# Pre-apply script for Voters Manager VM
# This script detects if an instance replacement is required and only detaches the EBS volume if needed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Pre-Apply Script for Voters Manager VM ===${NC}"

# Check if we have a plan file
if [[ ! -f "default.tfplan" ]]; then
    echo -e "${RED}Error: No plan file found. Run terraform plan first.${NC}" >&2
    exit 1
fi

# Get the volume ID from the plan
echo -e "${YELLOW}Checking for volume attachment in plan...${NC}"

# Check if the plan contains volume attachment changes
VOLUME_ATTACHMENT_CHANGES=$(terraform show -json default.tfplan 2>/dev/null | \
                           jq -r '.resource_changes[] | select(.type == "aws_volume_attachment" and .name == "data") | .change.actions[]' 2>/dev/null || echo "")

# Check if the plan contains instance replacement
INSTANCE_REPLACEMENT=$(terraform show -json default.tfplan 2>/dev/null | \
                      jq -r '.resource_changes[] | select(.type == "aws_instance" and .name == "manager") | .change.actions[]' 2>/dev/null || echo "")

# Get the volume ID from the plan
VOLUME_ID=$(terraform show -json default.tfplan 2>/dev/null | \
            jq -r '.resource_changes[] | select(.type == "aws_volume_attachment" and .name == "data") | .change.after.volume_id' 2>/dev/null || echo "")

if [[ -z "$VOLUME_ID" ]]; then
    # Try to get from current state if not in plan
    VOLUME_ID=$(terraform show -json 2>/dev/null | \
                jq -r '.values.root_module.resources[] | select(.type == "aws_volume_attachment" and .name == "data") | .values.volume_id' 2>/dev/null || echo "")
fi

echo -e "${BLUE}Volume ID: ${VOLUME_ID:-"Not found"}${NC}"

# Determine if we need to detach the volume
NEED_DETACH=false
REASON=""

if [[ "$INSTANCE_REPLACEMENT" == *"delete"* ]] || [[ "$INSTANCE_REPLACEMENT" == *"create"* ]]; then
    NEED_DETACH=true
    REASON="Instance replacement detected"
elif [[ "$VOLUME_ATTACHMENT_CHANGES" == *"delete"* ]] || [[ "$VOLUME_ATTACHMENT_CHANGES" == *"create"* ]]; then
    NEED_DETACH=true
    REASON="Volume attachment changes detected"
fi

if [[ "$NEED_DETACH" == "true" ]]; then
    echo -e "${YELLOW}${REASON} - Detaching EBS volume...${NC}"
    
    if [[ -n "$VOLUME_ID" ]]; then
        # Get current attachment info
        ATTACHMENT_INFO=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].Attachments[0]' --output json 2>/dev/null || echo "{}")
        INSTANCE_ID=$(echo "$ATTACHMENT_INFO" | jq -r '.InstanceId // empty' 2>/dev/null || echo "")
        DEVICE=$(echo "$ATTACHMENT_INFO" | jq -r '.Device // empty' 2>/dev/null || echo "")
        
        if [[ -n "$INSTANCE_ID" && "$INSTANCE_ID" != "null" ]]; then
            echo -e "${BLUE}Volume $VOLUME_ID is attached to instance $INSTANCE_ID at device $DEVICE${NC}"
            echo -e "${YELLOW}Detaching volume...${NC}"
            
            if aws ec2 detach-volume --volume-id "$VOLUME_ID" --force; then
                echo -e "${GREEN}Volume detached successfully${NC}"
                
                # Wait for detachment to complete
                echo -e "${YELLOW}Waiting for detachment to complete...${NC}"
                aws ec2 wait volume-available --volume-ids "$VOLUME_ID"
                echo -e "${GREEN}Volume detachment completed${NC}"
            else
                echo -e "${RED}Failed to detach volume${NC}" >&2
                exit 1
            fi
        else
            echo -e "${GREEN}Volume is not attached to any instance${NC}"
        fi
    else
        echo -e "${YELLOW}Could not determine volume ID, skipping detachment${NC}"
    fi
else
    echo -e "${GREEN}No instance replacement or volume changes detected - skipping volume detachment${NC}"
fi

echo -e "${GREEN}Pre-apply script completed successfully${NC}" 