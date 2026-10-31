#!/usr/bin/env bash
# Activa TODA la plataforma de Makip Te Crea en Google Cloud con un solo comando y muestra los enlaces de prueba:
#   infraestructura (Terraform) → Odoo con catálogo real y datos de prueba → landing en Cloud Run
#   → analítica en BigQuery → backoffice de Odoo con HTTPS (sslip.io).
# Uso (Cloud Shell): bash scripts/activar_todo.sh [ID_DEL_PROYECTO]     (≈ 30–40 min la primera vez)
# Costo aproximado mientras esté encendida: ~US$3.50 por día. Al terminar: bash scripts/destruir_gcp.sh
set -euo pipefail
PROJECT_ID="${1:-sc-45104-makip}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="southamerica-west1"
paso() { printf '\n\033[1;36m######## %s\033[0m\n' "$*"; }
gcloud config set project "$PROJECT_ID" >/dev/null

paso "1/5 Plan de Terraform"
bash "$REPO_ROOT/scripts/probar_gcp.sh" "$PROJECT_ID"

paso "2/5 Creando la infraestructura (Cloud SQL tarda ~15 min)"
cd "$REPO_ROOT/infra/environments/dev"
for intento in 1 2 3; do
  if terraform apply -input=false -auto-approve tfplan; then break; fi
  echo "Reintentando (propagación de APIs)…"; sleep 90
  terraform plan -input=false -out=tfplan
done
cd "$REPO_ROOT"

paso "3/5 Odoo: catálogo real, pipeline y datos de prueba + landing en Cloud Run"
bash "$REPO_ROOT/scripts/demo_gcp.sh" "$PROJECT_ID"

paso "4/5 Analítica en BigQuery (segmentación de clientes)"
bash "$REPO_ROOT/scripts/analitica_bigquery.sh" "$PROJECT_ID" || echo "(analítica: reintentar luego con scripts/analitica_bigquery.sh)"

paso "5/5 Backoffice de Odoo con HTTPS"
bash "$REPO_ROOT/scripts/backoffice_publico.sh" "$PROJECT_ID" || echo "(backoffice: reintentar con scripts/backoffice_publico.sh)"

LANDING="$(gcloud run services describe makip-dev-catalog-api --region "$REGION" --format='value(status.url)')"
IP="$(gcloud compute instances describe makip-dev-odoo --zone "${REGION}-a" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"
ODOO="https://$(echo "$IP" | tr . -).sslip.io"
cat <<FIN | tee "$HOME/enlaces_makip.txt"

================= ENLACES DE PRUEBA · Makip Te Crea · $(TZ=America/Lima date '+%d/%m/%Y %H:%M') =================
Landing + catálogo (Cloud Run):  $LANDING
API de catálogo:                 $LANDING/api/catalogo
Salud de la API:                 $LANDING/api/salud
Backoffice Odoo (CRM, ventas):   $ODOO/web/login
   usuario: admin · contraseña: gcloud secrets versions access latest --secret odoo-admin-password
Dashboard (Data Studio):         https://datastudio.google.com/reporting/7d01ac4d-e6be-4b8d-b3dc-bf8c10090b89
BigQuery (consola):              https://console.cloud.google.com/bigquery?project=$PROJECT_ID
Monitoreo (uptime):              https://console.cloud.google.com/monitoring/uptime?project=$PROJECT_ID
Landing de respaldo (Pages):     https://thiagoicochea.github.io/crm-cloud-makip/
Apagar todo al terminar:         bash scripts/destruir_gcp.sh $PROJECT_ID
====================================================================================================
FIN
