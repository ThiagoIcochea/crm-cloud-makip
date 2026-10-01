output "odoo_external_ip" { value = module.compute.external_ip }
output "catalog_api_url" { value = module.cloudrun.service_url }
output "image_repository" { value = module.cloudrun.image_repository }
output "firebase_default_url" { value = module.hosting.default_url }
output "dns_records" { value = module.hosting.dns_records }
output "wif_provider" { value = module.security.wif_provider }
output "deploy_sa_email" { value = module.security.deploy_sa_email }
output "bq_connection" { value = module.analytics.connection_id }
