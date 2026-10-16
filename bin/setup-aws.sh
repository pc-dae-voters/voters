#!/usr/bin/env bash

# AWS Infrastructure Setup Script
# The infrastructure, the VPC peered with the EKS cluster's, database, data volume and manager VM, is created by
# tofu-controller on the EKS cluster from the Terraform objects in infra/aws/flux. This script waits for it, then
# uploads the data to the manager VM's data volume and runs the database loaders on the VM
# Version: 2.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Functions ---
function usage() {
    echo "usage: ${0} [options]" >&2
    echo "This script waits for the voters AWS infrastructure, created by tofu-controller on the EKS cluster," >&2
    echo "then uploads the data to the manager instance and loads it into the database." >&2
    echo "kubectl must use the EKS cluster, e.g. KUBECONFIG=~/.kube/eks-voters.yaml, see the cluster repository's" >&2
    echo "target-cluster folder." >&2
    echo
    echo "Options:"
    echo "  --help                Display this help message."
    echo "  --data-folder <path>  The data folder to upload, default ../data"
    echo "  --skip-data-upload    Skip the data upload step."
    echo "  --skip-data-load      Skip the data loading step."
    echo "  --timeout <duration>  How long to wait for each part of the infrastructure, default 60m"
    echo "  --debug               Enable debug mode (set -x)."
    exit 1
}

function log_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

function log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function log_error() {
    echo -e "${RED}❌ $1${NC}"
}

function mgr_ssh() {
    ssh -i "${KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
        -o LogLevel=ERROR ec2-user@"${INSTANCE_IP}" "$@"
}

# --- Argument Parsing ---
SKIP_DATA_UPLOAD=false
SKIP_DATA_LOAD=false
DATA_FOLDER="../data"
TIMEOUT="60m"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            usage
            ;;
        --data-folder)
            DATA_FOLDER="$2"
            shift 2
            ;;
        --skip-data-upload)
            SKIP_DATA_UPLOAD=true
            shift
            ;;
        --skip-data-load)
            SKIP_DATA_LOAD=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
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

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "${PROJECT_ROOT}"
IP_FILE="${PROJECT_ROOT}/infra/aws/mgr-vm/instance-ip.txt"
KEY_FILE="${PROJECT_ROOT}/infra/aws/mgr-vm/loader.key"

# --- Validation ---
echo -e "${BLUE}=== AWS Infrastructure Setup ===${NC}"

server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"
if [[ "${server}" != *.eks.amazonaws.com ]]; then
    log_error "kubectl's current context, ${server:-none}, is not an EKS cluster, set KUBECONFIG, e.g. ~/.kube/eks-voters.yaml"
    exit 1
fi
if [[ "${SKIP_DATA_UPLOAD}" == "false" && ! -d "${DATA_FOLDER}" ]]; then
    log_error "Data folder ${DATA_FOLDER} does not exist, use --data-folder"
    exit 1
fi

# --- Infrastructure ---
log_step "Step 1: Waiting for the infrastructure, created by tofu-controller on the EKS cluster"
for tf in voters-vpc voters-peering voters-db voters-data-volume voters-mgr-vm; do
    echo "Waiting for Terraform ${tf}..."
    if ! kubectl wait --for=condition=Ready --timeout="${TIMEOUT}" terraforms.infra.contrib.fluxcd.io "${tf}" -n flux-system; then
        log_error "Terraform ${tf} is not ready, see kubectl describe terraform ${tf} -n flux-system"
        log_error "and the runner pod's logs, kubectl logs -n flux-system ${tf}-tf-runner"
        exit 1
    fi
done
log_success "Infrastructure created"

# The manager instance's IP address and SSH key, used by upload-data.sh and mgr-ssh.sh
log_step "Step 2: Getting the manager instance's details"
kubectl get secret voters-mgr-vm-outputs -n flux-system -o jsonpath='{.data.public_ip}' | base64 -d > "${IP_FILE}"
( umask 077; kubectl get secret voters-mgr-vm-outputs -n flux-system -o jsonpath='{.data.private_key}' | base64 -d > "${KEY_FILE}" )
INSTANCE_IP="$(cat "${IP_FILE}")"
log_success "Manager instance ${INSTANCE_IP}, key ${KEY_FILE}"

log_step "Step 3: Waiting for the manager instance to be set up"
for i in {1..40}; do
    if mgr_ssh true 2>/dev/null; then
        break
    fi
    echo "Waiting for SSH access to ${INSTANCE_IP} (attempt ${i}/40)"
    sleep 15
done
# cloud-init installs the tools and clones this repository, then the voters-manager service mounts the data volume
# at /data and creates the database tables
mgr_ssh "sudo cloud-init status --wait" || {
    log_error "cloud-init failed, see the end of /var/log/cloud-init-output.log:"
    mgr_ssh "sudo tail -20 /var/log/cloud-init-output.log"
    exit 1
}
for i in {1..30}; do
    state="$(mgr_ssh "systemctl show voters-manager.service -p ActiveState --value" || true)"
    if [[ "${state}" == "active" ]]; then
        break
    elif [[ "${state}" == "failed" ]]; then
        log_error "The voters-manager service failed, see sudo journalctl -u voters-manager.service"
        mgr_ssh "sudo journalctl -u voters-manager.service --no-pager | tail -20"
        exit 1
    fi
    echo "Waiting for the voters-manager service, ${state:-unknown} (attempt ${i}/30)"
    sleep 10
done
mgr_ssh "mountpoint -q /data" || { log_error "The data volume is not mounted at /data"; exit 1; }
log_success "Manager instance set up, data volume mounted at /data"

# --- Data ---
if [[ "${SKIP_DATA_UPLOAD}" == "false" ]]; then
    log_step "Step 4: Uploading data files"
    ./bin/upload-data.sh --data-folder "${DATA_FOLDER}"
    log_success "Data files uploaded"
else
    log_warning "Skipping data upload (--skip-data-upload specified)"
fi

if [[ "${SKIP_DATA_LOAD}" == "false" ]]; then
    log_step "Step 5: Loading data into the database"
    mgr_ssh "cd /home/ec2-user/pc-dae-voters && git pull --quiet"
    if ! mgr_ssh "cd /home/ec2-user/pc-dae-voters && ./bin/create-tables.sh --delete"; then
        log_error "Failed to create the database tables. Aborting."
        exit 1
    fi
    if ! mgr_ssh "cd /home/ec2-user/pc-dae-voters && ./bin/load-data.sh"; then
        log_error "Data loading failed. Check the loader output above. Aborting."
        exit 1
    fi
    log_success "Data loaded into the database"
else
    log_warning "Skipping data load (--skip-data-load specified)"
fi

# --- Database credentials ---
# For apps on the EKS cluster that use the database, e.g. the voters-debug pod, see debug/
log_step "Step 6: Writing the database's connection details to Vault"
if [[ -n "${VAULT_ADDR:-}" && -n "${VAULT_TOKEN:-}" ]]; then
    ./bin/db-vault-secret.sh
    log_success "Database connection details written to Vault"
else
    log_warning "VAULT_ADDR and VAULT_TOKEN aren't set, run bin/db-vault-secret.sh in the cluster repository's target-cluster folder"
fi

# --- Final Summary ---
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo "Next steps:"
echo "  • SSH to manager instance: ./bin/mgr-ssh.sh"
echo "  • Check database: ./bin/mgr-ssh.sh 'cd pc-dae-voters && ./bin/db-query.sh'"
echo "  • Or from the EKS cluster: kubectl exec -it -n voters deploy/voters-debug -- bash -c 'source /etc/voters-db/db-env.sh && psql'"
