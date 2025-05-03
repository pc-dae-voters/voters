#!/bin/bash

# Initialize Terraform (local backend is assumed to be configured)
terraform init

# Check for existing state (optional, but good practice)
if [ -f "terraform.tfstate" ]; then # Assumes local backend with "terraform.tfstate"
  echo "State file already exists.  If you intend to create a new backend, remove or rename the existing state file."
  exit 1 # Exit if state exists to prevent accidental overwrites
fi

# Plan the changes
terraform plan -out=tfplan

# Apply the changes to create the backend resources
terraform apply tfplan


# ---  Switch to S3 backend (Perform these steps manually after the above) ---
# 1. Modify your Terraform configuration to use the "s3" backend (as shown in previous responses).
# 2. Run 'terraform init' again to initialize the S3 backend and migrate the state.