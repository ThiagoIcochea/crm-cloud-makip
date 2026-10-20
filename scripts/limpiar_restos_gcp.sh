#!/usr/bin/env bash
# Termina la destrucción cuando terraform destroy se detiene por:
#  - usuarios de Cloud SQL que no se pueden borrar porque poseen objetos (se borra la instancia completa), o
#  - la subred aún ocupada por la IP serverless de Cloud Run (Google la libera unos minutos después).
set -uo pipefail
P=${1:-sc-45104-makip}; R=southamerica-west1; NET=makip-dev-vpc; SUB=makip-dev-subnet
g() { gcloud --project "$P" --quiet "$@"; }

echo "==> Cloud SQL"
g sql instances delete makip-dev-pg 2>&1 | tail -1 || true
echo "==> Peering de Service Networking y rango PSA"
g services vpc-peerings delete --network="$NET" --service=servicenetworking.googleapis.com 2>&1 | tail -1 || true
g compute addresses delete makip-dev-psa-range --global 2>&1 | tail -1 || true

echo "==> Esperando que Google libere la IP serverless de Cloud Run (hasta 4 h)"
for i in $(seq 1 240); do
  ips=$(g compute addresses list --filter="name~^serverless-ipv4 AND region:$R" --format='value(name)')
  [ -z "$ips" ] && break
  for ip in $ips; do g compute addresses delete "$ip" --region "$R" >/dev/null 2>&1 || true; done
  sleep 60
done

echo "==> Peering (reintento) , subred y VPC"
g services vpc-peerings delete --network="$NET" --service=servicenetworking.googleapis.com 2>&1 | tail -1 || true
g compute networks peerings list --network="$NET" --format="value(name)" | while read -r pe; do g compute networks peerings delete "$pe" --network="$NET" 2>&1 | tail -1; done
g compute networks subnets delete "$SUB" --region "$R" 2>&1 | tail -1 || true
g compute networks delete "$NET" 2>&1 | tail -1 || true
echo "==> Inventario final"
bash "$(dirname "$0")/inventario_gcp.sh" "$P"
