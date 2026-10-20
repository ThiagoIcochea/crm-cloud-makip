#!/usr/bin/env bash
# Lista lo que queda del proyecto (para verificar que la destrucción fue completa).
P=${1:-sc-45104-makip}
run() { echo "--- $1"; shift; "$@" 2>&1 | grep -v -E "^Listed 0|^$" ; }
run "VMs"            gcloud compute instances list --project "$P" --format='value(name)'
run "Cloud SQL"      gcloud sql instances list --project "$P" --format='value(name)'
run "Cloud Run"      gcloud run services list --project "$P" --format='value(metadata.name)'
run "Redes"          gcloud compute networks list --project "$P" --format='value(name)'
run "Subredes"       gcloud compute networks subnets list --project "$P" --filter='name~makip' --format='value(name)'
run "Firewall"       gcloud compute firewall-rules list --project "$P" --filter='network~makip' --format='value(name)'
run "Direcciones"    gcloud compute addresses list --project "$P" --format='value(name,status)'
run "Routers"        gcloud compute routers list --project "$P" --format='value(name)'
run "Peerings"       gcloud services vpc-peerings list --network=makip-dev-vpc --project "$P" --format='value(network)'
run "Secretos"       gcloud secrets list --project "$P" --format='value(name)'
run "Artifact Reg."  gcloud artifacts repositories list --project "$P" --format='value(name)'
run "BigQuery"       bq ls --project_id "$P"
run "Cuentas serv."  gcloud iam service-accounts list --project "$P" --filter='email~^sa-' --format='value(email)'
run "WIF pools"      gcloud iam workload-identity-pools list --location=global --project "$P" --format='value(name)'
run "Uptime checks"  gcloud monitoring uptime list-configs --project "$P" --format='value(displayName)'
run "Alertas"        gcloud alpha monitoring policies list --project "$P" --format='value(displayName)'
run "Buckets"        gcloud storage buckets list --project "$P" --format='value(name)'
