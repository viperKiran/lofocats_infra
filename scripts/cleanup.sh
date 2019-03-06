#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../.env
source "${ROOT_DIR}/.env"

printf '>>> Deleting Google project %s...\n' "${GOOGLE_PROJECT}"
gcloud projects delete "${GOOGLE_PROJECT}"

echo '>>> Removing Google application credentials...'
rm "${GOOGLE_APPLICATION_CREDENTIALS}"

echo '>>> Removing Terraform remote backend configuration...'
rm "${ROOT_DIR}/backend_override.tf"

echo '>>> Removing Terraform data...'
rm -rf "${ROOT_DIR}/.terraform"

echo '>>> Removing .env file...'
rm "${ROOT_DIR}/.env"

exit 0
