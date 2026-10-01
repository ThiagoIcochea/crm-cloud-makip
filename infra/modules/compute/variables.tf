variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "prefix" { type = string }
variable "subnet_id" { type = string }
variable "service_account_email" { type = string }
variable "db_private_ip" { type = string }
variable "db_name" { type = string }
variable "db_password_secret_id" { type = string }

variable "machine_type" {
  description = "E2 con 2 vCPU y 4 GiB (e2-medium). Confirmar contra la estimación de costos."
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "odoo_version" {
  description = "Versión fijada de Odoo Community (ADR-008)"
  type        = string
  default     = "19.0"
}

variable "backoffice_domain" {
  description = "Subdominio del backoffice, p. ej. crm.makiptecrea.pe"
  type        = string
}

variable "repository_url" {
  description = "URL HTTPS del repositorio para clonar app/"
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
