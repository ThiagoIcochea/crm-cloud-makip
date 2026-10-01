variable "project_id" { type = string }
variable "region" { type = string }
variable "prefix" { type = string }
variable "network_name" { type = string }
variable "subnet_name" { type = string }
variable "service_account_email" { type = string }
variable "odoo_internal_ip" { type = string }
variable "odoo_api_key_secret_id" { type = string }

variable "odoo_db" {
  type    = string
  default = "makip"
}

variable "odoo_api_mode" {
  description = "json2 (Odoo 19+) o jsonrpc. Confirmar en la PoC."
  type        = string
  default     = "json2"
}

variable "odoo_api_user" {
  description = "Login del usuario técnico de solo lectura (modo jsonrpc)"
  type        = string
  default     = "api_catalogo"
}

variable "allowed_origins" {
  type    = list(string)
  default = ["https://makiptecrea.pe", "https://www.makiptecrea.pe"]
}

variable "max_instances" {
  description = "Límite para contener costos ante picos desde redes sociales"
  type        = number
  default     = 3
}

variable "image" {
  type    = string
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "labels" {
  type    = map(string)
  default = {}
}
