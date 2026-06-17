#!/bin/bash

set -e
set -o pipefail

get_bitwarden_notes() {
  notes=$(rbw get --field notes minio-tf-creds)
  echo "$notes" > state.config
}

get_bitwarden_notes || {
  echo "Error fetching Bitwarden notes!"
  exit 1
}

echo "To initialize Terraform, use the following command:"
echo "terraform init -backend-config=./state.config"
