#!/usr/bin/env bash
# Crea la base "makip" e instala los módulos estándar del MVP en Odoo (local o en la VM).
# Uso: bash scripts/init_odoo.sh   (desde la raíz del repo, con app/.env configurado)
set -euo pipefail
cd "$(dirname "$0")/../app"
MODULES="${MODULES:-base,contacts,crm,sale_management}"
docker compose run --rm odoo odoo -d makip -i "$MODULES" --without-demo=all --stop-after-init
echo "Listo. Importa app/seed/etapas_pipeline.csv (CRM > Configuración > Etapas) y app/seed/productos_ficticios.csv (Ventas > Productos)."
