variable "project_id" { type = string }
variable "region" { type = string }
variable "cloudsql_connection_name" { type = string }
variable "database_name" { type = string }
variable "analytics_sa_email" { type = string }

variable "reader_password" {
  type      = string
  sensitive = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
