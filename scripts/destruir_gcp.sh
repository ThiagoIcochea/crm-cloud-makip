#!/usr/bin/env bash
# Elimina toda la infraestructura de la demostración (entorno dev) y los recursos creados fuera de Terraform.
# Uso (Cloud Shell):  bash scripts/destruir_gcp.sh [ID_DEL_PROYECTO]
set -uo pipefail
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="southamerica-west1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
gcloud config set project "$PROJECT_ID" >/dev/null

echo "==> terraform destroy (entorno dev)"
cd "$REPO_ROOT/infra/environments/dev"
terraform destroy -auto-approve -input=false

echo "==> Recursos creados fuera de Terraform"
gcloud secrets delete odoo-admin-password --quiet 2>/dev/null || true
for b in $(gcloud storage buckets list --format='value(name)' 2>/dev/null | grep -E "_cloudbuild$|^run-sources-" || true); do
  gcloud storage rm -r "gs://$b" --quiet 2>/dev/null || true
done
gcloud storage rm -r "gs://${PROJECT_ID}-tfstate" --quiet 2>/dev/null || true

echo "==> Verificación (todo debe quedar vacío)"
gcloud compute instances list
gcloud sql instances list
gcloud run services list --region "$REGION"
gcloud secrets list
gcloud compute addresses list
gcloud compute networks list --filter="name~makip"
gcloud storage buckets list --format='value(name)'
