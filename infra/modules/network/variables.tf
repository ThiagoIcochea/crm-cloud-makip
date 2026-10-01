variable "project_id" { type = string }
variable "region" { type = string }
variable "prefix" { type = string }

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

variable "backoffice_allowed_cidrs" {
  description = "Rangos con acceso HTTPS al backoffice de Odoo. Restringir cuando sea posible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
