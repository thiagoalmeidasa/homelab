#!/usr/bin/env bash
# Build, substitute, and apply (or render) a kustomization path
# Usage: ./hacks/sops-subs-apply.sh <path> [render|apply]
set -euo pipefail

KUSTOMIZATION_PATH="${1:?Usage: $0 <kustomization-path> [render|apply]}"
ACTION="${2:-apply}"

load_env_vars() {
    local cluster_secret_file="./kubernetes/flux/vars/cluster-secrets.sops.yaml"
    local cluster_config_file="./kubernetes/flux/vars/cluster-settings.yaml"

    while read -r line; do declare -x "${line}"; done < <(sops -d "${cluster_secret_file}" | yq eval '.stringData' - | sed 's/: /=/g')
    while read -r line; do declare -x "${line}"; done < <(yq eval '.data' "${cluster_config_file}" | sed 's/: /=/g')
}

decrypt_sops_secrets() {
    for f in "${KUSTOMIZATION_PATH}"/*.sops.yaml "${KUSTOMIZATION_PATH}"/*.sops.yml; do
        [ -f "${f}" ] || continue
        sops -d "${f}"
        echo "---"
    done
}

build_manifests() {
    kustomize build --load-restrictor=LoadRestrictionsNone "${KUSTOMIZATION_PATH}" \
        | envsubst
}

apply() {
    decrypt_sops_secrets | kubectl apply --server-side -f -
    build_manifests | kubectl apply --server-side -f -
}

render() {
    decrypt_sops_secrets
    build_manifests
}

load_env_vars

case "${ACTION}" in
    render) render ;;
    apply)  apply ;;
    *)      echo "Unknown action: ${ACTION}. Use 'render' or 'apply'." >&2; exit 1 ;;
esac
