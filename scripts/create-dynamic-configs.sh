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

create_secret_from_literal() {
   local name="${1}"
   local literal="${2}"

   kubectl create configmap "${name}" \
     --from-literal="${literal}"
}

main() {
  local redis_host
  local sql_ip_address
  local sql_password
  local secret_key_base
  local secret_key

  redis_host="$(terraform output redis_host)"
  sql_ip_address="$(terraform output sql_ip_address)"
  sql_password="$(terraform output sql_password)"

  for secret_key in lofocats-api-secret-key lofocats-ui-secret-key; do
    secret_key_base="$(generate_random_string 130)"
    create_secret_from_literal "${secret_key}" \
      "SECRET_KEY_BASE=${secret_key_base}"
  done

  create_configmap_from_literal lofocats-ui-redis-url \
    "REDIS_URL=redis://${redis_host}/0"
  create_secret_from_literal lofocats-api-database-url \
    "DATABASE_URL=postgres://lofocats:${sql_password}@${sql_ip_address}/lofocats?pool=5&timeout=5000"
}

main

exit 0
