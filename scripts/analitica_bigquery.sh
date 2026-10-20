#!/usr/bin/env bash
# ELT de fidelización: extrae de Odoo (Cloud SQL, IP privada) → carga en makip_staging → segmenta en makip_marts.
# Cloud SQL no tiene IP pública, por eso la extracción corre en la VM de Odoo (dentro de la VPC) por IAP.
set -euo pipefail
PROJECT=${1:-sc-45104-makip}
ZONE=${ZONE:-southamerica-west1-a}
VM=${VM:-makip-dev-odoo}
DIR=$(cd "$(dirname "$0")/.." && pwd)
CSV=$(mktemp --suffix=.csv)

gcloud compute ssh "$VM" --project "$PROJECT" --zone "$ZONE" --tunnel-through-iap --quiet --command \
  "sudo docker exec -i app-odoo-1 bash -c 'PGPASSWORD=\$PASSWORD psql -q -h \$HOST -U \$USER -d makip'" \
  < "$DIR/analytics/sql/clientes_odoo.sql" > "$CSV" 2>/dev/null
echo "Extraídos $(($(wc -l < "$CSV") - 1)) clientes de Odoo"

bq load --project_id "$PROJECT" --quiet --replace --source_format=CSV --skip_leading_rows=1 \
  makip_staging.clientes_odoo "$CSV" \
  cliente:STRING,pedidos:INTEGER,monto_total:FLOAT,ultimo_pedido:TIMESTAMP,oportunidades_abiertas:INTEGER
echo "Cargado en makip_staging.clientes_odoo"

bq query --project_id "$PROJECT" --quiet --use_legacy_sql=false --format=pretty \
  < "$DIR/analytics/sql/fidelizacion_bq.sql"
rm -f "$CSV"
