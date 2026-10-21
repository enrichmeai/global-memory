resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = var.service_name
  format        = "DOCKER"
  description   = "Images for ${var.service_name}."
}

resource "google_service_account" "service" {
  account_id   = "${var.service_name}-run"
  display_name = "${var.service_name} on Cloud Run"
}

resource "google_secret_manager_secret" "secret" {
  for_each  = var.secrets
  secret_id = each.value
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "service_reads" {
  for_each  = google_secret_manager_secret.secret
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service.email}"
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.service.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.secret[env.key].secret_id
              version = "latest"
            }
          }
        }
      }

      startup_probe {
        http_get {
          path = "/actuator/health/readiness"
        }
      }

      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
        }
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.service_reads]
}

resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = toset(var.invokers)
  name     = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role     = "roles/run.invoker"
  member   = each.value
}
