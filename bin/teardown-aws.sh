#!/usr/bin/env bash

# AWS Infrastructure Teardown Script
# Destroys the voters infrastructure created by tofu-controller on the EKS cluster, see infra/aws/flux
# Version: 2.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--yes] [--debug]" >&2
    echo "This script destroys the voters AWS infrastructure: the manager VM, data volume, database, VPC peering and VPC." >&2
    echo "It suspends the voters-infra Kustomization on the EKS cluster, so Flux doesn't recreate the Terraform objects," >&2
    echo "then deletes them in reverse dependency order, tofu-controller destroys their AWS resources." >&2
    echo "Use flux resume kustomization voters-infra -n flux-system to create the infrastructure again." >&2
    echo "kubectl must use the EKS cluster, e.g. KUBECONFIG=~/.kube/eks-voters.yaml" >&2
    echo "  --yes    Do not ask for confirmation." >&2
    echo "  --debug  Enable debug mode (set -x)." >&2
    exit 1
}

YES=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes) YES=true; shift ;;
        --debug) set -x; shift ;;
        --help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"
if [[ "${server}" != *.eks.amazonaws.com ]]; then
    echo "kubectl's current context, ${server:-none}, is not an EKS cluster, set KUBECONFIG, e.g. ~/.kube/eks-voters.yaml" >&2
    exit 1
fi

if [[ "${YES}" != "true" ]]; then
    read -rp "Destroy the voters AWS infrastructure, including the database and data volume? [y/N] " answer
    if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
        exit 1
    fi
fi

flux suspend kustomization voters-infra -n flux-system

# Dependents first, the VPC can't be deleted while anything uses it
for group in "voters-mgr-vm" "voters-db voters-data-volume voters-peering" "voters-vpc"; do
    for tf in ${group}; do
        kubectl delete terraforms.infra.contrib.fluxcd.io "${tf}" -n flux-system --ignore-not-found --wait=false
    done
    for tf in ${group}; do
        echo "Waiting for ${tf} to be destroyed..."
        if ! kubectl wait --for=delete terraforms.infra.contrib.fluxcd.io/"${tf}" -n flux-system --timeout=30m 2>/dev/null; then
            if kubectl get terraforms.infra.contrib.fluxcd.io "${tf}" -n flux-system >/dev/null 2>&1; then
                echo "${tf} has not been destroyed, see kubectl describe terraform ${tf} -n flux-system" >&2
                exit 1
            fi
        fi
    done
done

PROJECT_ROOT=$(git rev-parse --show-toplevel)
rm -f "${PROJECT_ROOT}/infra/aws/mgr-vm/instance-ip.txt" "${PROJECT_ROOT}/infra/aws/mgr-vm/loader.key"
echo "The voters AWS infrastructure has been destroyed"
