output "service_name" { value = google_cloud_run_v2_service.catalog_api.name }
output "service_url" { value = google_cloud_run_v2_service.catalog_api.uri }

output "image_repository" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}
