output "region" {
  value = "${data.google_client_config.current.region}"
}

output "zone" {
  value = "${data.google_compute_zones.available.names[0]}"
}

output "endpoint" {
  value = "${module.endpoint-dns.endpoint}"
}

output "credentials_json" {
  value = "${base64decode(google_service_account_key.db_client_key.private_key)}"
}

output "connection_name" {
  value = "${google_sql_database_instance.primary.connection_name}"
}

output "sql_password" {
  value = "${google_sql_user.default.password}"
}
