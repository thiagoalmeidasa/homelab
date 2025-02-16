#!/bin/bash

# Script Name and Purpose
# ======================

# Description: Fetches notes from Bitwarden and generates a state-config file.
# Usage: Run this script to retrieve your Bitwarden notes and generate a state-config file.

# Author Information
# ===============

# Thiago Almeida
# thiagoalmeidasa@gmail.com

# Date Created: 2025-02-16
# Last Updated: 2025-02-16

# Set up logging and error handling

DEBUG=${DEBUG:-false}

if [ "$DEBUG" = "true" ]; then
  set -x # Print commands before executing them for debugging purposes
fi

set -e          # Exit immediately on first command that fails, making debugging more efficient
set -o pipefail # Enable pipefail to exit script if last command fails

# Define the function to run
get_bitwarden_notes() {
  # Fetch notes from Bitwarden using bw get notes minio-tf-creds
  notes=$(bw get notes minio-tf-creds)

  # Generate a state-config file with the fetched notes
  echo "$notes" > state.config
}

# Run the function and handle errors
get_bitwarden_notes || {
  echo "Error fetching Bitwarden notes!"
  exit 1
}

set +x
echo "To initialize Terraform, use the following command:"
echo "tf init -backend-config=./state.config"
