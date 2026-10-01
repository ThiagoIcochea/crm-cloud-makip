variable "project_id" { type = string }

variable "site_id" {
  description = "ID global del sitio de Firebase Hosting"
  type        = string
}

variable "custom_domain" {
  description = "Dominio personalizado; vacío para omitir"
  type        = string
  default     = ""
}
