output "url" {
  value       = google_cloud_run_v2_service.service.uri
  description = "The service URL. Private unless invokers grants access."
}

output "image_repository" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
  description = "Where to push images."
}

output "service_account" {
  value = google_service_account.service.email
}
