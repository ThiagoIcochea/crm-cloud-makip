#!/usr/bin/env bash
# Mide tiempos de respuesta HTTP de la plataforma (landing, API de catálogo y backoffice de Odoo).
# Hace N solicitudes por URL y reporta mínimo, mediana, p95 y máximo en milisegundos; guarda el detalle en CSV.
# Uso: bash scripts/medir_tiempos.sh [N=30]     (lee los enlaces de ~/enlaces_makip.txt)
set -euo pipefail
N="${1:-30}"; OUT="$HOME/tiempos_respuesta_$(TZ=America/Lima date +%Y%m%d_%H%M).csv"
L="$(grep -oP 'Landing \+ catálogo \(Cloud Run\):\s+\K\S+' ~/enlaces_makip.txt)"
O="$(grep -oP 'Backoffice Odoo \(CRM, ventas\):\s+\K\S+' ~/enlaces_makip.txt)"
declare -A URLS=( [landing]="$L/" [api_catalogo]="$L/api/catalogo" [api_salud]="$L/api/salud" [odoo_login]="$O" )
echo "recurso,intento,http,tiempo_ms,fecha_hora_lima" > "$OUT"
printf '\nMediciones del %s (hora de Lima) · %s solicitudes por recurso\n' "$(TZ=America/Lima date '+%d/%m/%Y %H:%M')" "$N"
printf '%-14s %6s %8s %8s %8s %8s\n' recurso http min_ms mediana p95_ms max_ms
for k in landing api_catalogo api_salud odoo_login; do
  for i in $(seq 1 "$N"); do
    r=$(curl -s -o /dev/null -w '%{http_code} %{time_total}' "${URLS[$k]}")
    echo "$k,$i,${r% *},$(python3 -c "print(round(${r#* }*1000,1))"),$(TZ=America/Lima date '+%H:%M:%S')" >> "$OUT"
  done
  python3 - "$OUT" "$k" <<'PY'
import csv,sys,statistics as s
v=[r for r in csv.DictReader(open(sys.argv[1])) if r['recurso']==sys.argv[2]]
t=sorted(float(r['tiempo_ms']) for r in v); p95=t[max(0,int(round(0.95*len(t)))-1)]
print(f"{sys.argv[2]:<14} {v[-1]['http']:>6} {t[0]:>8.0f} {s.median(t):>8.0f} {p95:>8.0f} {t[-1]:>8.0f}")
PY
done
echo "Detalle: $OUT"
