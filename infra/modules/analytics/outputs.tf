output "connection_id" {
  description = "Usar en EXTERNAL_QUERY(\"<project>.<region>.<connection>\", ...)"
  value       = google_bigquery_connection.cloudsql.name
}
output "staging_dataset" { value = google_bigquery_dataset.staging.dataset_id }
output "marts_dataset" { value = google_bigquery_dataset.marts.dataset_id }
