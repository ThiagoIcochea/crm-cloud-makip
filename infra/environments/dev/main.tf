locals {
  prefix = "makip-${var.environment}"
  labels = {
    proyecto = "makip-te-crea"
    entorno  = var.environment
    curso    = "servicios-cloud-45104"
  }
  apis = [
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "billingbudgets.googleapis.com",
    "iap.googleapis.com",
  ]
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "random_password" "bq_reader" {
  length  = 24
  special = false
}

module "network" {
  source                   = "../../modules/network"
  project_id               = var.project_id
  region                   = var.region
  prefix                   = local.prefix
  backoffice_allowed_cidrs = var.backoffice_allowed_cidrs
  depends_on               = [google_project_service.apis]
}

module "security" {
  source            = "../../modules/security"
  project_id        = var.project_id
  github_repository = var.github_repository
  depends_on        = [google_project_service.apis]
}

module "database" {
  source              = "../../modules/database"
  project_id          = var.project_id
  region              = var.region
  prefix              = local.prefix
  network_id          = module.network.network_id
  psa_connection      = module.network.psa_connection
  db_password         = module.security.db_password
  analytics_password  = random_password.bq_reader.result
  enable_pitr         = var.enable_pitr
  deletion_protection = var.deletion_protection
  labels              = local.labels
}

module "compute" {
  source                = "../../modules/compute"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  prefix                = local.prefix
  subnet_id             = module.network.subnet_id
  service_account_email = module.security.crm_runtime_sa_email
  db_private_ip         = module.database.private_ip
  db_name               = module.database.database_name
  db_password_secret_id = module.security.db_password_secret_id
  backoffice_domain     = var.backoffice_domain
  repository_url        = "https://github.com/${var.github_repository}.git"
  labels                = local.labels
}

module "cloudrun" {
  source                 = "../../modules/cloudrun"
  project_id             = var.project_id
  region                 = var.region
  prefix                 = local.prefix
  network_name           = module.network.network_name
  subnet_name            = module.network.subnet_name
  service_account_email  = module.security.catalog_api_sa_email
  odoo_internal_ip       = module.compute.internal_ip
  odoo_db                = module.database.database_name
  odoo_api_key_secret_id = module.security.odoo_api_key_secret_id
  allowed_origins        = var.allowed_origins
  labels                 = local.labels
}

module "hosting" {
  source        = "../../modules/hosting"
  project_id    = var.project_id
  site_id       = var.firebase_site_id
  custom_domain = var.custom_domain
  depends_on    = [google_project_service.apis]
}

module "observability" {
  source            = "../../modules/observability"
  project_id        = var.project_id
  project_number    = data.google_project.this.number
  alert_email       = var.alert_email
  cloud_run_service = module.cloudrun.service_name
  billing_account   = var.billing_account
  uptime_targets = {
    landing    = { enabled = var.custom_domain != "", host = var.custom_domain, path = "/" }
    api        = { enabled = true, host = trimprefix(module.cloudrun.service_url, "https://"), path = "/healthz" }
    backoffice = { enabled = var.backoffice_domain != "", host = var.backoffice_domain, path = "/web/login" }
  }
}

module "analytics" {
  source                   = "../../modules/analytics"
  project_id               = var.project_id
  region                   = var.region
  cloudsql_connection_name = module.database.connection_name
  database_name            = module.database.database_name
  analytics_sa_email       = module.security.analytics_sa_email
  reader_password          = random_password.bq_reader.result
  labels                   = local.labels
}
