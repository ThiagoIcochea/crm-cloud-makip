resource "google_sql_database_instance" "odoo" {
  project             = var.project_id
  name                = "${var.prefix}-pg"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection
  depends_on          = [var.psa_connection]

  settings {
    tier              = var.tier
    edition           = "ENTERPRISE"
    availability_type = "ZONAL" # sin HA en el MVP (ver ADR-007)
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false # sin IP pública: solo red privada
      private_network = var.network_id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "07:00" # 02:00 hora de Lima
      point_in_time_recovery_enabled = var.enable_pitr
      backup_retention_settings {
        retained_backups = 7
      }
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    user_labels = var.labels
  }
}

resource "google_sql_database" "odoo" {
  project  = var.project_id
  name     = "makip"
  instance = google_sql_database_instance.odoo.name
}

resource "google_sql_user" "odoo" {
  project  = var.project_id
  name     = "odoo"
  instance = google_sql_database_instance.odoo.name
  password = var.db_password
}

# Usuario de solo lectura para la federación de BigQuery
resource "google_sql_user" "analytics" {
  project  = var.project_id
  name     = "bq_reader"
  instance = google_sql_database_instance.odoo.name
  password = var.analytics_password
}
