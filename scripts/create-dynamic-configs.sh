#!/usr/bin/env bash
set -euo pipefail

# This will be incorporated to Terraform in the future

if ! command -v kubectl >/dev/null; then
  echo "kubectl command not found. Please install kubectl"
  echo "See https://kubernetes.io/docs/tasks/tools/install-kubectl/"
fi

generate_random_string() {
  local length="${1}"

  dd if=/dev/urandom bs="$(( length * 2 ))" count=1 2>/dev/null \
    | base64 | tr -d "=+/[:space:]" \
    | dd bs="${length}" count=1 2>/dev/null
}

create_secret_from_literal() {
   local name="${1}"
   local literal="${2}"

   kubectl create secret generic "${name}" \
     --from-literal="${literal}"
}

create_confimap_from_literal() {
   local name="${1}"
   local literal="${2}"

   kubectl create configmap "${name}" \
     --from-literal="${literal}"
}

main() {
  local sql_password
  local connection_name
  local credentials_json
  local secret_key_base
  local secret_key

  sql_password="$(terraform output sql_password)"
  connection_name="$(terraform output connection_name)"
  credentials_json="$(terraform output credentials_json)"

  for secret_key in lofocats-api-secret-key lofocats-ui-secret-key; do
    secret_key_base="$(generate_random_string 130)"
    create_secret_from_literal "${secret_key}" \
      "SECRET_KEY_BASE=${secret_key_base}"
  done

  create_secret_from_literal lofocats-api-database-url \
    "DATABASE_URL=postgres://lofocats:${sql_password}@localhost/lofocats?pool=5&timeout=5000"
  create_confimap_from_literal lofocats-db-instances \
    "INSTANCES=${connection_name}=tcp:5432"
  create_secret_from_literal lofocats-db-instance-credentials \
    "credentials.json=${credentials_json}"
}

main

exit 0
