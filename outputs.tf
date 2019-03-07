output "region" {
  value = "${data.google_client_config.current.region}"
}

output "zone" {
  value = "${data.google_compute_zones.available.names[0]}"
}

output "endpoint" {
  value = "${module.endpoint-dns.endpoint}"
}

output "redis_host" {
  value ="${google_redis_instance.cache.host}"
}

output "sql_ip_address" {
  value = "${google_sql_database_instance.primary.first_ip_address}"
}

output "sql_password" {
  value = "${google_sql_user.default.password}"
}
