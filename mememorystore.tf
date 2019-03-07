resource "google_project_service" "redis_api" {
  service = "redis.googleapis.com"
}

resource "google_redis_instance" "cache" {
  name           = "lofocats-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  location_id             = "${data.google_compute_zones.available.names[0]}"
  alternative_location_id = "${data.google_compute_zones.available.names[1]}"

  authorized_network = "${google_compute_network.network.self_link}"

  redis_version = "REDIS_3_2"

  depends_on = ["google_project_service.redis_api"]
}
