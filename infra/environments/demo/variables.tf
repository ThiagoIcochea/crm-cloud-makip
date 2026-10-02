variable "project_id" { type = string }

variable "environment" {
  type    = string
  default = "demo"
}

variable "region" {
  description = "Región principal (contingencia: us-central1)"
  type        = string
  default     = "southamerica-west1"
}

variable "zone" {
  type    = string
  default = "southamerica-west1-a"
}

variable "github_repository" {
  description = "owner/repo autorizado para WIF"
  type        = string
}

variable "firebase_site_id" { type = string }

variable "enable_hosting" {
  description = "Crear el sitio de Firebase Hosting (false para probar solo la infraestructura base)"
  type        = bool
  default     = true
}

variable "create_firebase_project" {
  description = "false si Firebase ya se agregó al proyecto desde la consola"
  type        = bool
  default     = true
}

variable "custom_domain" {
  type    = string
  default = ""
}

variable "backoffice_domain" {
  description = "Subdominio del backoffice de Odoo, p. ej. crm.makiptecrea.pe"
  type        = string
  default     = ""
}

variable "allowed_origins" {
  type    = list(string)
  default = ["https://makiptecrea.pe", "https://www.makiptecrea.pe"]
}

variable "backoffice_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "alert_email" { type = string }

variable "billing_account" {
  type    = string
  default = ""
}

variable "enable_pitr" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}
