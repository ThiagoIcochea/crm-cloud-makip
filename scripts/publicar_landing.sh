#!/usr/bin/env bash
# Construye la imagen (API de catálogo + landing) con Cloud Build y la publica en Cloud Run.
# Uso (Cloud Shell): bash scripts/publicar_landing.sh [ID_DEL_PROYECTO]
set -euo pipefail
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="southamerica-west1"; SERVICE="makip-dev-catalog-api"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/makip-dev-images/catalogo:$(date +%Y%m%d-%H%M)"
paso() { printf '\n\033[1;35m▶ %s\033[0m\n' "$*"; }
gcloud services enable cloudbuild.googleapis.com --quiet
paso "4) Construyendo la imagen (API de catálogo + landing) con Cloud Build"
gcloud builds submit "$REPO_ROOT" --tag "$IMAGE" --region "$REGION"

paso "5) Publicando en Cloud Run: $SERVICE"
gcloud run deploy "$SERVICE" --image "$IMAGE" --region "$REGION" \
  --update-env-vars "ODOO_API_MODE=jsonrpc,ODOO_API_USER=api_catalogo,STATIC_DIR=/app/web" \
  --update-secrets "ODOO_API_KEY=odoo-api-key:latest" --quiet
URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"

paso "6) Verificación"
curl -s "$URL/healthz"; echo
curl -s "$URL/api/catalogo" | python3 -c 'import json,sys; d=json.load(sys.stdin); p=d["productos"]; print(len(p), "productos publicados desde Odoo"); [print(" -", x["codigo"], x["nombre"], x["precio"]) for x in p[:5]]'
