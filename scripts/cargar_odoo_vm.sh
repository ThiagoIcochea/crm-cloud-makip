#!/usr/bin/env bash
# Ejecuta cargar_odoo.py dentro de la VM (conexión local a Odoo, más rápida y estable que el túnel IAP).
set -euo pipefail
ZONE="southamerica-west1-a"; VM="makip-dev-odoo"
ADMIN_PW="$(gcloud secrets versions access latest --secret odoo-admin-password)"
API_PW="$(gcloud secrets versions access latest --secret odoo-api-key)"
gcloud compute ssh "$VM" --zone "$ZONE" --tunnel-through-iap --quiet --command \
  "cd /opt/makip/repo && sudo git pull -q && python3 -u scripts/cargar_odoo.py --url http://localhost:8069 --admin-password '$ADMIN_PW' --api-password '$API_PW'" \
  2>&1 | grep -v -i -E 'numpy|tcp_upload|^$|Testing if|WARNING'
