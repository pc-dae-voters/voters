#!/usr/bin/env bash

# Build the voters-api and voters-db images and push them to the kind cluster's local registry
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

function usage() {
    echo "usage: ${0} [--tag <tag>] [--registry <registry>] [--restart] [--debug]" >&2
    echo "This script builds the voters-api image, the API and web UI, and the voters-db image, PostgreSQL with the" >&2
    echo "voters schema, and pushes them to the kind cluster's local registry, see deploy/kind/README.md" >&2
    echo "  --tag <tag>            Image tag, default the voters-api version in voters-api/pom.xml" >&2
    echo "  --registry <registry>  Registry, default localhost:\${KIND_REGISTRY_PORT:-5001}" >&2
    echo "  --restart              Restart the voters-api deployment, in the voters namespace, to use the new image" >&2
    echo "  --debug                Enable debug mode (set -x)" >&2
    exit 1
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# The version element follows voters-api's artifactId in its pom.xml
TAG="$(sed -n '/<artifactId>voters-api<\/artifactId>/{n;s:.*<version>\(.*\)</version>.*:\1:p;}' "${ROOT_DIR}/voters-api/pom.xml")"
REGISTRY="localhost:${KIND_REGISTRY_PORT:-5001}"
RESTART=false
NAMESPACE="voters"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag) TAG="$2"; shift 2 ;;
        --registry) REGISTRY="$2"; shift 2 ;;
        --restart) RESTART=true; shift ;;
        --debug) set -x; shift ;;
        --help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

if [[ -z "${TAG}" ]]; then
    echo "Can't read the voters-api version from voters-api/pom.xml, use --tag" >&2
    exit 1
fi

for image in voters-api voters-db; do
    case "${image}" in
        voters-api) dockerfile="voters-api/Dockerfile" ;;
        voters-db) dockerfile="db/Dockerfile" ;;
    esac
    echo "Building ${REGISTRY}/${image}:${TAG}"
    docker build -f "${ROOT_DIR}/${dockerfile}" -t "${REGISTRY}/${image}:${TAG}" "${ROOT_DIR}"
    docker push "${REGISTRY}/${image}:${TAG}"
done

if [[ "${RESTART}" == "true" ]]; then
    # The voters-api deployment pulls its image on every start, voters-db is not restarted, it keeps its data
    kubectl rollout restart deployment/voters-api -n "${NAMESPACE}"
    kubectl rollout status deployment/voters-api -n "${NAMESPACE}" --timeout=5m
fi
