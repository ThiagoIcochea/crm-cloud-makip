resource "google_artifact_registry_repository" "api" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.prefix}-images"
  format        = "DOCKER"
  labels        = var.labels

  cleanup_policies {
    id     = "keep-last-5"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }
}

resource "google_cloud_run_v2_service" "catalog_api" {
  project             = var.project_id
  name                = "${var.prefix}-catalog-api"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  labels              = var.labels

  template {
    service_account                  = var.service_account_email
    max_instance_request_concurrency = 20

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = var.network_name
        subnetwork = var.subnet_name
      }
    }

    containers {
      # La imagen real la publica el workflow deploy.yml; esta es la inicial.
      image = var.image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      env {
        name  = "ODOO_URL"
        value = "http://${var.odoo_internal_ip}:8069"
      }
      env {
        name  = "ODOO_DB"
        value = var.odoo_db
      }
      env {
        name  = "ODOO_API_MODE"
        value = var.odoo_api_mode
      }
      env {
        name  = "ODOO_API_USER"
        value = var.odoo_api_user
      }
      env {
        name  = "ALLOWED_ORIGINS"
        value = join(",", var.allowed_origins)
      }
      env {
        name = "ODOO_API_KEY"
        value_source {
          secret_key_ref {
            secret  = var.odoo_api_key_secret_id
            version = "latest"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }
}

# API pública de solo lectura (el catálogo es información pública)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.catalog_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
