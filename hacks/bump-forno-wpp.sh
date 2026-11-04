#!/usr/bin/env bash
# Bump the forno-wpp app and migration images to a new version,
# pinning each image by digest (tag@sha256:...).
#
# Usage: hacks/bump-forno-wpp.sh <version>   e.g. hacks/bump-forno-wpp.sh 0.2.2
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

REGISTRY="git.home399.thiagoalmeida.xyz/casa-de-farinha"
APP_IMAGE="${REGISTRY}/forno-wpp"
MIGRATE_IMAGE="${REGISTRY}/forno-wpp-migrate"

APP_HELMRELEASE="${ROOT_DIR}/kubernetes/apps/forno-wpp/app/app/helmrelease.yaml"
MIGRATE_JOB="${ROOT_DIR}/kubernetes/apps/forno-wpp/app/migrations/job.yaml"

for dependency in crane sed; do
    if ! command -v "${dependency}" >/dev/null 2>&1; then
        echo "ERROR: ${dependency} is required" >&2
        exit 1
    fi
done

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>   e.g. $0 0.2.2" >&2
    exit 1
fi

VERSION="${1}"

resolve_digest() {
    local image="${1}"
    local digest
    digest=$(crane digest "${image}:${VERSION}")
    echo "${digest}"
}

echo "Resolving digests for version ${VERSION}..."
APP_DIGEST=$(resolve_digest "${APP_IMAGE}")
MIGRATE_DIGEST=$(resolve_digest "${MIGRATE_IMAGE}")
echo "  ${APP_IMAGE}:${VERSION}@${APP_DIGEST}"
echo "  ${MIGRATE_IMAGE}:${VERSION}@${MIGRATE_DIGEST}"

echo "Updating ${APP_HELMRELEASE}"
sed -i '' \
    -E "s|tag: [^[:space:]]+@sha256:[a-f0-9]{64}|tag: ${VERSION}@${APP_DIGEST}|" \
    "${APP_HELMRELEASE}"

echo "Updating ${MIGRATE_JOB}"
sed -i '' \
    -E "s|image: ${MIGRATE_IMAGE}:[^[:space:]]+@sha256:[a-f0-9]{64}|image: ${MIGRATE_IMAGE}:${VERSION}@${MIGRATE_DIGEST}|" \
    "${MIGRATE_JOB}"

echo "Done."
