#!/usr/bin/env bash
# Regenerate custom Flux validation schemas from installed CRDs
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCHEMA_DIR="${ROOT_DIR}/.schemas"

for dependency in flux kubectl; do
    if ! command -v "${dependency}" >/dev/null 2>&1; then
        echo "ERROR: ${dependency} is required" >&2
        exit 1
    fi
done

extract_crd_schema() {
    local crd_name="${1}"

    echo "Extracting installed CRD: ${crd_name}..."
    kubectl get crd "${crd_name}" -o yaml \
        | flux schema extract crd \
            --strip-description \
            --index-source "cluster/${crd_name}" \
            --output-dir "${SCHEMA_DIR}"
}

CRDS=(
    interceptorroutes.http.keda.sh
)

for crd in "${CRDS[@]}"; do
    extract_crd_schema "${crd}"
done
