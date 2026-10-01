resource "google_compute_address" "odoo" {
  project = var.project_id
  name    = "${var.prefix}-odoo-ip"
  region  = var.region
}

resource "google_compute_instance" "odoo" {
  project      = var.project_id
  name         = "${var.prefix}-odoo"
  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["odoo"]
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {
      nat_ip = google_compute_address.odoo.address
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("${path.module}/startup.sh.tftpl", {
      db_host        = var.db_private_ip
      db_name        = var.db_name
      db_secret      = var.db_password_secret_id
      odoo_version   = var.odoo_version
      domain         = var.backoffice_domain
      repository_url = var.repository_url
    })
  }

  allow_stopping_for_update = true
}
