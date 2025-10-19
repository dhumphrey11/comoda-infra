#!/usr/bin/env bash
set -euo pipefail
# Create Secret Manager secrets used by services.
# Requires: gcloud authenticated and project set; terraform optional.

PROJECT_ID=${GCP_PROJECT_ID:-comoda}

create_secret() {
  local name=$1
  local value=$2
  echo -n "$value" | gcloud secrets create "$name" --replication-policy=automatic --data-file=- || \
  gcloud secrets versions add "$name" --data-file=-
}

# Examples (fill with real values or CI-injected values)
# create_secret backend-db-password "supersecret"
# create_secret api-key-coinapi "$COINAPI_KEY"
# create_secret service-account-json "$(cat path/to/sa.json)"

echo "Secrets script executed. Create specific secrets by uncommenting and providing values."
