#!/usr/bin/env bash
# Da al usuario bq_reader (conexión de BigQuery) permiso de solo lectura sobre las tablas de Odoo en Cloud SQL.
set -euo pipefail
ZONE="southamerica-west1-a"; VM="makip-dev-odoo"
gcloud compute ssh "$VM" --zone "$ZONE" --tunnel-through-iap --quiet --command \
  "sudo docker exec app-odoo-1 bash -c 'PGPASSWORD=\$PASSWORD psql -h \$HOST -U \$USER -d makip -c \"GRANT USAGE ON SCHEMA public TO bq_reader; GRANT SELECT ON ALL TABLES IN SCHEMA public TO bq_reader; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO bq_reader;\"'" 2>&1 | grep -v -i -E 'numpy|tcp_upload|^$|Testing if|WARNING'
echo "Permisos de lectura para BigQuery listos"
