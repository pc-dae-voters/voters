#!/usr/bin/env bash

# Pre-execution script for mgr-vm Terraform module
# This script handles cleanup operations before Terraform runs
# Note: Volume detachment is now handled by pre-apply.sh only when needed

set -euo pipefail

echo "--- Pre-execution: Checking for any cleanup operations ---"

# This script is now minimal since volume detachment is handled by pre-apply.sh
# which only detaches when an instance replacement is actually needed

echo "No cleanup operations required at this stage."
echo "Volume detachment (if needed) will be handled by pre-apply.sh after plan generation."
echo "--- Pre-execution: Complete ---" 