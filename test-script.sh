#!/usr/bin/env bash

echo "Test script starting..."
echo "Current directory: $(pwd)"

# Test the post-init script directly
if [[ -f "infra/aws/mgr-vm/post-init.sh" ]]; then
    echo "Found post-init.sh, testing it..."
    cd infra/aws/mgr-vm
    source ./post-init.sh
    echo "post-init.sh test completed"
    cd ../..
else
    echo "post-init.sh not found"
fi

echo "Test script completed" 