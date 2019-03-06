#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo '>>> Initializing Google project...'
scripts/initialize-gcp-project.sh

echo '>>> Building infrastructure...'
scripts/build-infrastructure.sh

echo '>>> Waiting 60 seconds for the app to be running...'
sleep 60
echo '>>> Loading demo data...'
scripts/load-demo-data.sh

echo '>>> Done! Your application should be available at this URL in a few minutes:'
# shellcheck source=../.env
source .env
endpoint="$(terraform output endpoint)"
printf 'http://%s\n' "${endpoint}"
