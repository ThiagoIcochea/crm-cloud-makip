variable "project_id" { type = string }
variable "project_number" { type = string }
variable "alert_email" { type = string }
variable "cloud_run_service" { type = string }

variable "uptime_targets" {
  description = "Hosts a vigilar por HTTPS (landing, API, backoffice)"
  type = map(object({
    enabled = bool
    host    = string
    path    = string
  }))
}

variable "billing_account" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  description = "Referencia: estimación de US$105.90/mes más margen"
  type        = number
  default     = 120
}
