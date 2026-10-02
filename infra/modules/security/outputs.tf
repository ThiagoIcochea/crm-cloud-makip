output "crm_runtime_sa_email" { value = google_service_account.crm_runtime.email }
output "catalog_api_sa_email" { value = google_service_account.catalog_api.email }
output "deploy_sa_email" { value = google_service_account.deploy.email }
output "analytics_sa_email" { value = google_service_account.analytics.email }

output "db_password_secret_id" { value = google_secret_manager_secret.db_password.secret_id }
output "odoo_api_key_secret_id" {
  value      = google_secret_manager_secret.odoo_api_key.secret_id
  depends_on = [google_secret_manager_secret_version.odoo_api_key_initial, google_secret_manager_secret_iam_member.api_key]
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "wif_provider" {
  description = "Valor para GCP_WIF_PROVIDER en GitHub"
  value       = google_iam_workload_identity_pool_provider.github.name
}
