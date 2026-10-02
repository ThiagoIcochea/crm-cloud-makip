variable "project_id" { type = string }

variable "site_id" {
  description = "ID global del sitio de Firebase Hosting"
  type        = string
}

variable "create_firebase_project" {
  description = "false si Firebase ya se agregó al proyecto desde la consola"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Dominio personalizado; vacío para omitir"
  type        = string
  default     = ""
}
