#!/bin/bash
set -euo pipefail
terraform output | while IFS=' = ' read -r key value; do
  # Remove quotes from value if present
  clean_value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//')
  # Only process non-empty keys and values
  if [[ -n "$key" && -n "$clean_value" ]]; then
    echo "TF_VAR_${key}=${clean_value}" >> all_outputs.env
  fi
done