variable "project_id" { type = string }

variable "github_repository" {
  description = "Repositorio autorizado para WIF, formato owner/repo"
  type        = string
}

variable "deploy_roles" {
  description = "Roles del despliegue. Revisar y reducir según el alcance real."
  type        = list(string)
  default = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/firebasehosting.admin",
    "roles/iam.serviceAccountUser",
    "roles/compute.instanceAdmin.v1",
    "roles/storage.objectAdmin",
  ]
}
