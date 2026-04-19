#!/usr/bin/env bash
# Run the flux-check-hook helm values check against a HelmRelease file
# Usage: ./hacks/helm-lint-hr.sh kubernetes/apps/monitoring/mimir/app/helmrelease.yaml
set -euo pipefail

pre-commit run check-flux-helm-values --files "${@}"
