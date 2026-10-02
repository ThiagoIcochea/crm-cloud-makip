#!/usr/bin/env bash
# Prepara tu proyecto de Google Cloud y ejecuta `terraform plan` del entorno dev.
# Pensado para Google Cloud Shell (ya trae gcloud y Terraform).
#
# Uso:  bash scripts/probar_gcp.sh <ID_DEL_PROYECTO>
#
# El plan NO crea recursos ni genera costos. Para crearlos, ejecuta después
# `terraform apply tfplan` (ver los pasos que imprime este script al final).
set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
[ -z "$PROJECT_ID" ] && { echo "Uso: bash scripts/probar_gcp.sh <ID_DEL_PROYECTO>"; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_DIR="$REPO_ROOT/infra/environments/dev"
BUCKET="${PROJECT_ID}-tfstate"
REGION="southamerica-west1"
EMAIL="$(gcloud config get-value account 2>/dev/null)"
SITE_ID="$(echo "${PROJECT_ID}-landing" | cut -c1-30 | sed 's/-$//')"

echo "==> Proyecto: $PROJECT_ID | Cuenta: $EMAIL | Región: $REGION"
gcloud config set project "$PROJECT_ID" >/dev/null

echo "==> Verificando facturación"
if [ "$(gcloud billing projects describe "$PROJECT_ID" --format='value(billingEnabled)' 2>/dev/null)" != "True" ]; then
  echo "ERROR: el proyecto no tiene facturación activa. Vincula una cuenta de facturación o créditos y vuelve a intentar."
  exit 1
fi

echo "==> Verificando Terraform"
terraform version | head -1

echo "==> Habilitando APIs base (Terraform habilita el resto)"
gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com storage.googleapis.com

echo "==> Bucket de estado: gs://$BUCKET"
if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://$BUCKET" --location="$REGION" --uniform-bucket-level-access
  gcloud storage buckets update "gs://$BUCKET" --versioning
fi

cd "$ENV_DIR"
if [ ! -f terraform.tfvars ]; then
  echo "==> Creando terraform.tfvars"
  cat > terraform.tfvars <<TFVARS
project_id        = "$PROJECT_ID"
github_repository = "ThiagoIcochea/crm-cloud-makip"
firebase_site_id  = "$SITE_ID"
alert_email       = "$EMAIL"

# Primera prueba: solo la infraestructura base. Activa Firebase Hosting después
# (true) cuando hayas agregado Firebase al proyecto en console.firebase.google.com
enable_hosting          = false
create_firebase_project = false

custom_domain     = ""
backoffice_domain = ""
billing_account   = ""
TFVARS
else
  echo "==> terraform.tfvars ya existe; se usa tal cual"
fi

echo "==> terraform init"
terraform init -input=false -reconfigure -backend-config="bucket=$BUCKET"

echo "==> terraform validate"
terraform validate

echo "==> terraform plan (no crea nada)"
terraform plan -input=false -out=tfplan

cat <<NEXT

============================================================
Plan generado sin errores: Terraform se conecta a tu proyecto.

Para CREAR la infraestructura (≈ 15 min; Cloud SQL es lo más lento):
  cd infra/environments/dev && terraform apply tfplan

Costo aproximado mientras esté encendida: ~US\$3.50 por día
(Cloud SQL + VM). Al terminar la prueba, elimínala con:
  cd infra/environments/dev && terraform destroy
============================================================
NEXT
