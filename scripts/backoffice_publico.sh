#!/usr/bin/env bash
# Publica el backoffice de Odoo con HTTPS sin dominio propio, usando <IP>.sslip.io + Let's Encrypt.
# Pensado para pruebas y mediciones (Anexo G). Para producción usar crm.makiptecrea.pe.
# Uso (Cloud Shell): bash scripts/backoffice_publico.sh [ID_DEL_PROYECTO]
set -euo pipefail
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
ZONE="southamerica-west1-a"; VM="makip-dev-odoo"
IP="$(gcloud compute instances describe "$VM" --project "$PROJECT_ID" --zone "$ZONE" \
      --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"
DOMINIO="$(echo "$IP" | tr . -).sslip.io"
echo "==> Backoffice: https://$DOMINIO"
gcloud compute ssh "$VM" --project "$PROJECT_ID" --zone "$ZONE" --tunnel-through-iap --quiet --command "
set -e
cd /opt/makip/repo/app
sudo sed -i 's/^BACKOFFICE_DOMAIN=.*/BACKOFFICE_DOMAIN=$DOMINIO/' .env
C='sudo docker compose -f docker-compose.yml -f docker-compose.gcp.yml'
\$C stop nginx >/dev/null 2>&1 || true
if [ ! -f /etc/letsencrypt/live/$DOMINIO/fullchain.pem ]; then
  sudo docker run --rm -p 80:80 -v /etc/letsencrypt:/etc/letsencrypt certbot/certbot certonly --standalone \
    --non-interactive --agree-tos --register-unsafely-without-email -d $DOMINIO
fi
\$C up -d --force-recreate nginx
sleep 3; \$C ps nginx
"
for i in 1 2 3 4 5 6; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMINIO/web/login" || true)
  [ "$code" = "200" ] && break; sleep 5
done
echo "HTTP $code en https://$DOMINIO/web/login"
