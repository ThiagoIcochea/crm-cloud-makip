variable "project_id" { type = string }
variable "region" { type = string }
variable "prefix" { type = string }
variable "network_id" { type = string }
variable "psa_connection" { type = string }

variable "database_version" {
  type    = string
  default = "POSTGRES_16"
}

variable "tier" {
  type    = string
  default = "db-g1-small"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "enable_pitr" {
  description = "Recuperación a un punto en el tiempo (aumenta costo)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "analytics_password" {
  type      = string
  sensitive = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
