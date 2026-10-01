# Runbook de operación

Procedimientos de despliegue, operación, respaldo, recuperación, rollback y destrucción segura (entregable E09).

## 1. Preparación (una sola vez)

1. Crear el proyecto GCP y vincular la cuenta de facturación (o créditos académicos).
2. Habilitar Firebase en el proyecto (consola de Firebase → Agregar proyecto → elegir el proyecto GCP).
3. Bucket de estado de Terraform:
   ```bash
   gsutil mb -l southamerica-west1 gs://<PROYECTO>-tfstate
   gsutil versioning set on gs://<PROYECTO>-tfstate
   ```
4. Primer `apply` desde una máquina con `gcloud auth application-default login`:
   ```bash
   cd infra/environments/dev
   cp terraform.tfvars.example terraform.tfvars   # completar
   terraform init -backend-config="bucket=<PROYECTO>-tfstate"
   terraform plan -out tfplan && terraform apply tfplan
   ```
5. En GitHub → Settings → Environments (`dev`, `demo`) → Variables:

   | Variable | Origen |
   |---|---|
   | `GCP_PROJECT_ID` | ID del proyecto |
   | `GCP_WIF_PROVIDER` | `terraform output wif_provider` |
   | `GCP_DEPLOY_SA` | `terraform output deploy_sa_email` |
   | `TF_STATE_BUCKET` | `<PROYECTO>-tfstate` |
   | `FIREBASE_SITE_ID`, `ALERT_EMAIL`, `CUSTOM_DOMAIN`, `BACKOFFICE_DOMAIN`, `BILLING_ACCOUNT` | tfvars |
   | `LANDING_URL`, `API_URL`, `BACKOFFICE_URL` | para smoke tests |

   Marcar el entorno `demo` con **Required reviewers** para aprobar cada despliegue.

## 2. Odoo en la VM

El startup script clona el repo y levanta Odoo + Nginx. Si el repositorio es privado, clonar manualmente por SSH (IAP):

```bash
gcloud compute ssh makip-dev-odoo --zone southamerica-west1-a --tunnel-through-iap
```

Certificado TLS gratuito del backoffice (primera vez, con el DNS `crm.` apuntando a la IP estática):

```bash
sudo docker run --rm -p 80:80 -v /etc/letsencrypt:/etc/letsencrypt certbot/certbot \
  certonly --standalone -d crm.makiptecrea.pe --agree-tos -m <correo> -n
cd /opt/makip/repo/app && sudo docker compose -f docker-compose.yml -f docker-compose.gcp.yml up -d
```

Inicializar la base y los módulos: `bash scripts/init_odoo.sh`.

**Usuario técnico de la API:** crear `api_catalogo` con permisos solo de lectura de productos, generar su clave de API y cargarla:

```bash
printf '%s' '<CLAVE>' | gcloud secrets versions add odoo-api-key --data-file=-
gcloud run services update makip-dev-catalog-api --region southamerica-west1   # toma la nueva versión
```

## 3. Dominio makiptecrea.pe

`terraform output dns_records` lista los registros que pide Firebase Hosting. Crearlos en el panel del registrador del dominio. El certificado TLS de la landing lo emite Firebase sin costo. Para el backoffice crear un registro `A crm → terraform output odoo_external_ip`.

## 4. Despliegues

- Cambios por Pull Request → CI (`ci.yml`) → revisión → merge.
- Despliegue: Actions → **Deploy** → entorno y objetivo (`all`, `infra`, `api`, `web`).

## 5. Respaldo y recuperación (RPO ≤ 24 h, RTO ≤ 4 h)

| Escenario | Procedimiento |
|---|---|
| Fallo de Odoo | `docker compose restart odoo`; validar `/web/login` |
| Fallo de VM | `terraform apply -replace=module.compute.google_compute_instance.odoo` y restaurar el filestore desde snapshot |
| Error lógico en BD | Clonar desde backup: `gcloud sql backups list --instance makip-dev-pg` → `gcloud sql backups restore <ID> --restore-instance=<instancia-recuperación>` |
| API defectuosa | `gcloud run services update-traffic makip-dev-catalog-api --to-revisions=<REV_ANTERIOR>=100` |
| Landing defectuosa | Firebase Hosting → Versiones → Revertir |
| Cambio IaC defectuoso | `git revert` + Deploy `infra` |

Snapshot del disco antes de cambios mayores:

```bash
gcloud compute disks snapshot makip-dev-odoo --zone southamerica-west1-a --snapshot-names pre-cambio-$(date +%Y%m%d)
```

Registrar cada ejercicio en `docs/medicion/bitacora_dr.md` con hora de inicio, fin y resultado.

## 6. Contingencia en us-central1

Cambiar `region`/`zone` en un tfvars de contingencia, aplicar en un proyecto o prefijo separado y restaurar el último backup de Cloud SQL. Destruir al terminar para limitar el costo.

## 7. Destrucción segura

```bash
terraform plan -destroy -out destroy.tfplan   # revisar
terraform apply destroy.tfplan
```

`demo` tiene `deletion_protection = true` en Cloud SQL: desactivarlo explícitamente solo si se decide eliminar los datos.
