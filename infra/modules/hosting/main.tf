# Firebase Hosting para la landing. Requiere el proyecto habilitado en Firebase.
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

resource "google_firebase_hosting_site" "landing" {
  provider   = google-beta
  project    = var.project_id
  site_id    = var.site_id
  depends_on = [google_firebase_project.default]
}

# Dominio personalizado (makiptecrea.pe). Firebase emite el certificado TLS.
# Los registros DNS que devuelve se configuran en el registrador del dominio.
resource "google_firebase_hosting_custom_domain" "main" {
  provider              = google-beta
  count                 = var.custom_domain == "" ? 0 : 1
  project               = var.project_id
  site_id               = google_firebase_hosting_site.landing.site_id
  custom_domain         = var.custom_domain
  wait_dns_verification = false
}
