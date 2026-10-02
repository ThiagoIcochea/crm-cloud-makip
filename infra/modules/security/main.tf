# Cuentas de servicio con mínimo privilegio
resource "google_service_account" "crm_runtime" {
  project      = var.project_id
  account_id   = "sa-crm-runtime"
  display_name = "Runtime de la VM de Odoo"
}

resource "google_service_account" "catalog_api" {
  project      = var.project_id
  account_id   = "sa-catalog-api"
  display_name = "Runtime de la API de catálogo (Cloud Run)"
}

resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = "sa-terraform-deploy"
  display_name = "Despliegue desde GitHub Actions (WIF)"
}

resource "google_service_account" "analytics" {
  project      = var.project_id
  account_id   = "sa-bigquery-analytics"
  display_name = "Consultas programadas de BigQuery"
}

locals {
  crm_roles = [
    "roles/cloudsql.client",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
  analytics_roles = [
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/bigquery.connectionUser",
  ]
}

resource "google_project_iam_member" "crm" {
  for_each = toset(local.crm_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.crm_runtime.email}"
}

resource "google_project_iam_member" "catalog_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.catalog_api.email}"
}

resource "google_project_iam_member" "analytics" {
  for_each = toset(local.analytics_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.analytics.email}"
}

resource "google_project_iam_member" "deploy" {
  for_each = toset(var.deploy_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.deploy.email}"
}

# ---------- Secretos (los valores reales se cargan fuera de Terraform) ----------
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "odoo-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

# Clave de API del usuario técnico de Odoo (solo lectura de productos).
# Se genera en Odoo y se carga con: gcloud secrets versions add odoo-api-key --data-file=-
resource "google_secret_manager_secret" "odoo_api_key" {
  project   = var.project_id
  secret_id = "odoo-api-key"
  replication {
    auto {}
  }
}

# Versión inicial para que Cloud Run pueda arrancar. El valor real se carga
# después con gcloud; Terraform no lo sobrescribe (ignore_changes).
resource "google_secret_manager_secret_version" "odoo_api_key_initial" {
  secret      = google_secret_manager_secret.odoo_api_key.id
  secret_data = "PENDIENTE-cargar-clave-real"

  lifecycle {
    ignore_changes = [secret_data, enabled]
  }
}

resource "google_secret_manager_secret_iam_member" "crm_db" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.crm_runtime.email}"
}

resource "google_secret_manager_secret_iam_member" "api_key" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.odoo_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.catalog_api.email}"
}

# ---------- Workload Identity Federation para GitHub Actions ----------
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif_deploy" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
