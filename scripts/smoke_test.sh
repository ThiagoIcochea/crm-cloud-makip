#!/usr/bin/env bash
# Smoke tests posteriores al despliegue (sección 12.2).
# Uso: LANDING_URL=https://makiptecrea.pe API_URL=https://... BACKOFFICE_URL=https://crm.makiptecrea.pe bash scripts/smoke_test.sh
set -uo pipefail
fail=0

check() {
  local name="$1" url="$2" expect="$3"
  [ -z "$url" ] && { echo "SKIP  $name (URL no definida)"; return; }
  code=$(curl -s -o /tmp/smoke_body -w "%{http_code}" --max-time 20 "$url")
  if [ "$code" = "$expect" ]; then echo "OK    $name ($code)"; else echo "FAIL  $name: esperado $expect, obtenido $code"; fail=1; fi
}

check "landing"          "${LANDING_URL:-}"                  200
check "api healthz"      "${API_URL:-}${API_URL:+/healthz}"  200
check "api catálogo"     "${API_URL:-}${API_URL:+/api/catalogo}" 200
check "backoffice login" "${BACKOFFICE_URL:-}${BACKOFFICE_URL:+/web/login}" 200
check "gestor de BD bloqueado" "${BACKOFFICE_URL:-}${BACKOFFICE_URL:+/web/database/manager}" 403

if [ -n "${API_URL:-}" ]; then
  if grep -q '"standard_price"' /tmp/smoke_body 2>/dev/null; then echo "FAIL  la API expone campos internos"; fail=1; fi
fi

exit $fail
