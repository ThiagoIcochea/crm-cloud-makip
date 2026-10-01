output "site_id" { value = google_firebase_hosting_site.landing.site_id }
output "default_url" { value = google_firebase_hosting_site.landing.default_url }

output "dns_records" {
  description = "Registros a crear en el DNS del registrador"
  value       = try(google_firebase_hosting_custom_domain.main[0].required_dns_updates, null)
}
