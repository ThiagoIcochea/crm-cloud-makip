resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  project                  = var.project_id
  name                     = "${var.prefix}-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# Rango reservado para Private Service Access (Cloud SQL con IP privada)
resource "google_compute_global_address" "private_services" {
  project       = var.project_id
  name          = "${var.prefix}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# Backoffice de Odoo: solo HTTP/HTTPS (HTTP redirige a HTTPS en Nginx)
resource "google_compute_firewall" "odoo_web" {
  project       = var.project_id
  name          = "${var.prefix}-allow-odoo-web"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = var.backoffice_allowed_cidrs
  target_tags   = ["odoo"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# SSH y Odoo (8069) solo a través de IAP: sin puertos administrativos abiertos a Internet
resource "google_compute_firewall" "iap_ssh" {
  project       = var.project_id
  name          = "${var.prefix}-allow-iap-ssh"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["odoo"]

  allow {
    protocol = "tcp"
    ports    = ["22", "8069"]
  }
}

# Cloud Run (egreso directo a VPC) hacia la API interna de Odoo
resource "google_compute_firewall" "api_to_odoo" {
  project       = var.project_id
  name          = "${var.prefix}-allow-api-to-odoo"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = [var.subnet_cidr]
  target_tags   = ["odoo"]

  allow {
    protocol = "tcp"
    ports    = ["8069"]
  }
}
