#!/usr/bin/env bash

# Create Azure service account with admin permissions
# Version: 1.5
# Author: Gemini (Daemon Consulting Software Engineer)

set -euo pipefail

# --- Configuration ---
SERVICE_PRINCIPAL_NAME="pc-dae-voters-admin"
PROJECT_ROOT=$(git rev-parse --show-toplevel)
OUTPUT_FILE="${PROJECT_ROOT}/.az-sp.sh"

# --- Functions ---
function usage() {
    echo "usage: ${0} [--help] [--debug] [--output-file <file>]" >&2
    echo "This script creates an Azure service principal with admin permissions." >&2
    echo "  --output-file <file>    Output file for credentials (default: .az-sp.sh in repository root)" >&2
    echo "  --help                  Display this help message" >&2
    echo "  --debug                 Enable debug mode (set -x)" >&2
    exit 1
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        --debug)
            set -x
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

# Check for az CLI dependency
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI (az) is not installed or not in your PATH." >&2
    echo "Please install the Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" >&2
    exit 1
fi

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in your PATH." >&2
    echo "Please install jq: https://stedolan.github.io/jq/download/" >&2
    exit 1
fi

# --- Get Current Azure Account Info ---
echo "Getting current Azure account information..."
ACCOUNT_INFO=$(az account show)
if [[ $? -ne 0 ]]; then
    echo "Error: Not logged into Azure. Please run 'az login' first." >&2
    exit 1
fi

SUBSCRIPTION_ID=$(echo "$ACCOUNT_INFO" | jq -r '.id')
TENANT_ID=$(echo "$ACCOUNT_INFO" | jq -r '.tenantId')
SUBSCRIPTION_NAME=$(echo "$ACCOUNT_INFO" | jq -r '.name')

echo "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "Using tenant: $TENANT_ID"

# --- Main Logic ---
echo "Creating Azure service principal..."

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SERVICE_PRINCIPAL_NAME" \
    --role "Owner" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --query "{clientId:appId, clientSecret:password, tenantId:tenant}")

# Extract credentials
APP_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')
PASSWORD=$(echo "$SP_OUTPUT" | jq -r '.clientSecret')

# Create output file
cat > "$OUTPUT_FILE" << EOF
#!/usr/bin/env bash

# Azure Service Principal Credentials
# Generated on $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

# Azure Service Principal Details
export AZURE_TENANT_ID=$TENANT_ID
export AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export AZURE_CLIENT_ID=$APP_ID
export AZURE_CLIENT_SECRET=$PASSWORD

# Azure Resource Group (to be created)
export AZURE_RESOURCE_GROUP=pc-dae-voters-rg
export AZURE_LOCATION=uksouth

# Azure Database Details
export AZURE_DB_SERVER=pc-dae-voters-db
export AZURE_DB_NAME=voters
export AZURE_DB_USER=voters_admin
EOF

# Set secure permissions on the output file
chmod 600 "$OUTPUT_FILE"

echo "Service principal created successfully!"
echo "Credentials have been saved to $OUTPUT_FILE"
echo
echo "To use these credentials:"
echo "1. Source the file: source $OUTPUT_FILE"
echo "2. Login with the service principal:"
echo "   az login --service-principal -u \$AZURE_CLIENT_ID -p \$AZURE_CLIENT_SECRET --tenant \$AZURE_TENANT_ID"
echo
echo "IMPORTANT: Keep these credentials secure and never commit them to version control!" 