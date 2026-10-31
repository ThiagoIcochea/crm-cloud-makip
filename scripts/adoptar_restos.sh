#!/usr/bin/env bash
# Si un despliegue anterior dejó recursos (red, firewall, pool de WIF en estado eliminado…),
# los recupera y los importa al estado de Terraform para que `apply` no falle con «already exists».
# Uso: bash scripts/adoptar_restos.sh [ID_DEL_PROYECTO]
set -uo pipefail
P="${1:-$(gcloud config get-value project 2>/dev/null)}"; R=southamerica-west1
cd "$(dirname "$0")/../infra/environments/dev"
# Los pools de WIF eliminados quedan 30 días en estado DELETED: se restauran
gcloud iam workload-identity-pools undelete github-pool --location=global --project "$P" --quiet >/dev/null 2>&1 || true
gcloud iam workload-identity-pools providers undelete github-provider --workload-identity-pool=github-pool \
  --location=global --project "$P" --quiet >/dev/null 2>&1 || true
imp() { terraform state show "$1" >/dev/null 2>&1 && return 0
        terraform import -input=false "$1" "$2" >/dev/null 2>&1 && echo "  importado: $1" || true; }
echo "==> Adoptando recursos existentes"
imp module.network.google_compute_network.vpc                    "projects/$P/global/networks/makip-dev-vpc"
imp module.network.google_compute_subnetwork.main                "projects/$P/regions/$R/subnetworks/makip-dev-subnet"
imp module.network.google_compute_global_address.private_services "projects/$P/global/addresses/makip-dev-psa-range"
imp module.network.google_service_networking_connection.psa      "projects/$P/global/networks/makip-dev-vpc:servicenetworking.googleapis.com"
imp module.network.google_compute_firewall.odoo_web              "projects/$P/global/firewalls/makip-dev-allow-odoo-web"
imp module.network.google_compute_firewall.iap_ssh               "projects/$P/global/firewalls/makip-dev-allow-iap-ssh"
imp module.network.google_compute_firewall.api_to_odoo           "projects/$P/global/firewalls/makip-dev-allow-api-to-odoo"
imp module.security.google_iam_workload_identity_pool.github     "projects/$P/locations/global/workloadIdentityPools/github-pool"
imp module.security.google_iam_workload_identity_pool_provider.github "projects/$P/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
imp module.compute.google_compute_address.odoo                   "projects/$P/regions/$R/addresses/makip-dev-odoo-ip"
imp module.cloudrun.google_artifact_registry_repository.api      "projects/$P/locations/$R/repositories/makip-dev-images"
imp 'module.analytics.google_bigquery_dataset.staging'           "projects/$P/datasets/makip_staging"
imp 'module.analytics.google_bigquery_dataset.marts'             "projects/$P/datasets/makip_marts"
echo "==> Listo"
