output "instance_name" { value = google_compute_instance.odoo.name }
output "external_ip" { value = google_compute_address.odoo.address }
output "internal_ip" { value = google_compute_instance.odoo.network_interface[0].network_ip }
