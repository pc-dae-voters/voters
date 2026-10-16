#!/usr/bin/env bash

# Write the voters database's connection details to the EKS cluster's Vault, for apps that use it, e.g. the voters-debug
# app, see debug/
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--app <app name>] [--debug]" >&2
    echo "This script reads the voters database's connection details from the voters-db-outputs secret on the EKS" >&2
    echo "cluster, written by the voters-db Terraform object, and writes them to Vault at apps/<app name>/voters-db, as" >&2
    echo "PGHOST, PGPORT, PGDATABASE, PGUSER and PGPASSWORD. The app's ExternalSecret reads them, see debug/external-secret.yaml" >&2
    echo "kubectl must use the EKS cluster and VAULT_ADDR and VAULT_TOKEN its Vault, as set by the aws-eks-voters" >&2
    echo "cluster repository's target-cluster/.envrc, e.g. run it in a shell in that folder" >&2
    echo "  --app <app name>  The app, default voters-debug" >&2
    echo "  --debug           Enable debug mode (set -x)." >&2
    exit 1
}

APP="voters-debug"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --app) APP="$2"; shift 2 ;;
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
if [[ -z "${VAULT_ADDR:-}" || -z "${VAULT_TOKEN:-}" ]]; then
    echo "VAULT_ADDR and VAULT_TOKEN must be set for the EKS cluster's Vault, see the cluster repository's target-cluster/.envrc" >&2
    exit 1
fi

outputs="$(kubectl get secret voters-db-outputs -n flux-system -o json)"
function output() {
    jq -r --arg key "$1" '.data[$key] | @base64d' <<<"${outputs}"
}

# Passed on stdin, so the password isn't in the process list
jq -n --arg host "$(output db_host)" --arg port "$(output db_port)" --arg database "$(output db_name)" \
      --arg user "$(output db_username)" --arg password "$(output db_password)" \
      '{PGHOST: $host, PGPORT: $port, PGDATABASE: $database, PGUSER: $user, PGPASSWORD: $password}' | \
    vault kv put -mount=secrets "apps/${APP}/voters-db" - >/dev/null
echo "Written the voters database's connection details to Vault at apps/${APP}/voters-db"

# Refresh the app's secret now, rather than at the ExternalSecret's refresh interval
namespace="$(kubectl get externalsecrets.external-secrets.io -A -o json | \
    jq -r --arg key "apps/${APP}/voters-db" '.items[] | select(.spec.dataFrom[]?.extract.key == $key) | .metadata.namespace' | head -1)"
if [[ -n "${namespace}" ]]; then
    kubectl annotate externalsecrets.external-secrets.io voters-db -n "${namespace}" --overwrite force-sync="$(date +%s)" >/dev/null
    echo "Refreshed the voters-db secret in namespace ${namespace}"
fi
