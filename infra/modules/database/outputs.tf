output "instance_name" { value = google_sql_database_instance.odoo.name }
output "connection_name" { value = google_sql_database_instance.odoo.connection_name }
output "private_ip" { value = google_sql_database_instance.odoo.private_ip_address }
output "database_name" { value = google_sql_database.odoo.name }
