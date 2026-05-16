#!/usr/bin/env bash
# Generate state.config for the Terraform S3 backend by fetching the
# MinIO Terraform service-account credentials from Bitwarden via rbw.
# The Bitwarden item stores the value pre-formatted as `access_key = "..."`
# and `secret_key = "..."`, so we just write it out verbatim.
#
# Usage:
#   ./generate-state-config.sh
#
# Run before `terraform init -backend-config=state.config`.
set -euo pipefail

ITEM="${RBW_ITEM:-minio-tf-creds}"
HERE="$(cd "$(dirname "$0")" && pwd)"

command -v rbw >/dev/null || { echo "error: rbw not installed" >&2; exit 1; }

rbw get "$ITEM" > "$HERE/state.config"
chmod 600 "$HERE/state.config"
echo "Wrote $HERE/state.config"
