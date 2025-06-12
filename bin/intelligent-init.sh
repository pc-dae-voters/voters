#!/usr/bin/env bash

# This script runs terraform init and intelligently handles backend
# configuration changes by automatically re-running with -reconfigure.

set -euo pipefail

# Run terraform init, capturing stderr to check for specific errors
stderr_file=$(mktemp)

# We are using -no-color to make string matching easier.
if ! terraform init -no-color 2> "$stderr_file"; then
    # If init fails, check for the "Backend configuration changed" error.
    if grep -q "Backend configuration changed" "$stderr_file"; then
        echo "Backend configuration changed. Re-running with -reconfigure..."
        # Show the initial error message.
        cat "$stderr_file" >&2
        
        # Retry with -reconfigure
        if ! terraform init -reconfigure; then
            echo "Terraform init -reconfigure failed." >&2
            rm -f "$stderr_file"
            exit 1
        fi
    else
        # If it's a different error, print it and exit.
        echo "Terraform init failed:" >&2
        cat "$stderr_file" >&2
        rm -f "$stderr_file"
        exit 1
    fi
fi
# Cleanup the temp file.
rm -f "$stderr_file" 