#!/usr/bin/env bash
# Pone en marcha la demostración completa después de `terraform apply` (entorno dev):
#   1) espera a que Odoo termine de inicializarse en la VM,
#   2) carga el catálogo real, el pipeline y datos de prueba en Odoo (túnel IAP),
#   3) guarda las credenciales generadas en Secret Manager,
#   4) construye la imagen (API + landing) y la publica en Cloud Run.
# Uso (Cloud Shell):  bash scripts/demo_gcp.sh [ID_DEL_PROYECTO]
set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="southamerica-west1"; ZONE="${REGION}-a"
VM="makip-dev-odoo"; SERVICE="makip-dev-catalog-api"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/makip-dev-images/catalogo:$(date +%Y%m%d-%H%M)"
gcloud config set project "$PROJECT_ID" >/dev/null
gcloud services enable cloudbuild.googleapis.com --quiet

paso() { printf '\n\033[1;35m▶ %s\033[0m\n' "$*"; }

paso "1) Esperando a que Odoo responda en la VM $VM (la primera vez tarda ~10 min)"
gcloud compute start-iap-tunnel "$VM" 8069 --local-host-port=localhost:8069 --zone "$ZONE" >/tmp/tunel.log 2>&1 &
TUNEL=$!
trap 'kill $TUNEL 2>/dev/null || true' EXIT
for i in $(seq 1 90); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8069/web/login || true)
  [ "$code" = "200" ] && { echo "Odoo listo (HTTP 200)"; break; }
  printf '.'; sleep 20
  if ! kill -0 $TUNEL 2>/dev/null; then
    gcloud compute start-iap-tunnel "$VM" 8069 --local-host-port=localhost:8069 --zone "$ZONE" >/tmp/tunel.log 2>&1 &
    TUNEL=$!
  fi
done

paso "2) Credenciales generadas y guardadas en Secret Manager"
gen() { openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-20; }
if gcloud secrets describe odoo-admin-password >/dev/null 2>&1; then
  ADMIN_PW="$(gcloud secrets versions access latest --secret odoo-admin-password)"; ACTUAL_ADMIN="$ADMIN_PW"
else
  ADMIN_PW="$(gen)"; ACTUAL_ADMIN="admin"
  printf '%s' "$ADMIN_PW" | gcloud secrets create odoo-admin-password --replication-policy=automatic --data-file=- >/dev/null
fi
API_PW="$(gen)"
printf '%s' "$API_PW" | gcloud secrets versions add odoo-api-key --data-file=- >/dev/null
gcloud secrets list --format='table(name,createTime.date("%Y-%m-%d %H:%M"))'

paso "3) Cargando catálogo real, pipeline y datos de prueba en Odoo"
python3 "$REPO_ROOT/scripts/cargar_odoo.py" --url http://localhost:8069 --db makip \
  --admin-password "$ACTUAL_ADMIN" --nuevo-admin-password "$ADMIN_PW" --api-password "$API_PW"

bash "$REPO_ROOT/scripts/permisos_analitica.sh"
bash "$REPO_ROOT/scripts/publicar_landing.sh" "$PROJECT_ID"
URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"

cat <<FIN

============================================================
Landing + catálogo:  $URL
Odoo (backoffice):   gcloud compute start-iap-tunnel $VM 8069 --local-host-port=localhost:8080 --zone $ZONE
                     y luego Vista previa web → puerto 8080 (usuario admin;
                     contraseña: gcloud secrets versions access latest --secret odoo-admin-password)
Al terminar:         bash scripts/destruir_gcp.sh
============================================================
FIN
