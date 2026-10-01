resource "google_bigquery_dataset" "staging" {
  project    = var.project_id
  dataset_id = "makip_staging"
  location   = var.region
  labels     = var.labels
}

resource "google_bigquery_dataset" "marts" {
  project    = var.project_id
  dataset_id = "makip_marts"
  location   = var.region
  labels     = var.labels
}

# Conexión federada a Cloud SQL (solo lectura, usuario bq_reader).
# Verificar en la PoC su funcionamiento con la instancia de IP privada.
resource "google_bigquery_connection" "cloudsql" {
  project       = var.project_id
  connection_id = "odoo-cloudsql"
  location      = var.region
  friendly_name = "Odoo Cloud SQL (solo lectura)"

  cloud_sql {
    instance_id = var.cloudsql_connection_name
    database    = var.database_name
    type        = "POSTGRES"
    credential {
      username = "bq_reader"
      password = var.reader_password
    }
  }
}

# El agente de la conexión necesita acceso de cliente a Cloud SQL
resource "google_project_iam_member" "connection_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_bigquery_connection.cloudsql.cloud_sql[0].service_account_id}"
}

resource "google_bigquery_dataset_iam_member" "analytics_staging" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.analytics_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "analytics_marts" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marts.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.analytics_sa_email}"
}
