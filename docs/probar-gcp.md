# Probar el Terraform en tu proyecto de Google Cloud

Guía para comprobar que la infraestructura se conecta y se crea en tu proyecto. Usa **Google Cloud Shell**: ya trae `gcloud` y Terraform, y usa tu sesión sin descargar credenciales.

## Requisitos

- Proyecto de GCP con **facturación activa** (o créditos) y rol **Propietario** (Owner).
- Anota el **ID del proyecto** (no el nombre): aparece en el selector de proyectos de la consola.

## 1. Plan (sin costo)

En la consola de GCP abre **Cloud Shell** (icono `>_` arriba a la derecha) y ejecuta:

```bash
git clone https://github.com/ThiagoIcochea/crm-cloud-makip.git
cd crm-cloud-makip
bash scripts/probar_gcp.sh TU_ID_DE_PROYECTO
```

El script verifica la facturación, habilita las APIs base, crea el bucket de estado `TU_ID-tfstate`, genera `terraform.tfvars` y ejecuta `init`, `validate` y `plan`.

**Resultado esperado:** `Plan: N to add, 0 to change, 0 to destroy` y el mensaje «Plan generado sin errores». Con eso ya se comprobó la conexión y que el código es válido para tu proyecto.

## 2. Crear la infraestructura (con costo)

```bash
cd infra/environments/dev
terraform apply tfplan
```

Tarda unos 15 minutos; Cloud SQL es lo más lento. Costo aproximado mientras esté encendida: **~US$3.50 por día**.

Si falla con *«API has not been used in project… or it is disabled»*, es la propagación de una API recién habilitada: espera 2 minutos y repite `terraform plan -out=tfplan && terraform apply tfplan`.

## 3. Verificar

```bash
terraform output
```

| Qué | Cómo probarlo | Resultado esperado |
|---|---|---|
| API de catálogo (Cloud Run) | `curl -s -o /dev/null -w "%{http_code}\n" $(terraform output -raw catalog_api_url)` | `200` (imagen de prueba hasta el primer despliegue) |
| VM de Odoo | `gcloud compute instances list` | `makip-dev-odoo` en `RUNNING` |
| Base de datos | `gcloud sql instances list` | `makip-dev-pg` en `RUNNABLE`, sin IP pública |
| Secretos | `gcloud secrets list` | `odoo-db-password`, `odoo-api-key` |
| BigQuery | `bq ls` | `makip_staging`, `makip_marts` |
| Monitoreo | Consola → Monitoring → Uptime checks | `uptime-api` |

### Abrir Odoo sin dominio (túnel IAP)

La VM tarda unos 5–10 minutos más en instalar Docker e inicializar la base. Luego, desde Cloud Shell:

```bash
gcloud compute start-iap-tunnel makip-dev-odoo 8069 \
  --local-host-port=localhost:8080 --zone=southamerica-west1-a
```

Deja el túnel abierto y en Cloud Shell pulsa **Vista previa web → Vista previa en el puerto 8080**. Verás el login de Odoo. Usuario inicial: `admin` / contraseña: `admin`; cámbiala de inmediato en *Preferencias*.

Para revisar el arranque de la VM:

```bash
gcloud compute ssh makip-dev-odoo --zone=southamerica-west1-a --tunnel-through-iap \
  --command="sudo journalctl -u google-startup-scripts -n 50 --no-pager"
```

## 4. Eliminar todo al terminar

```bash
cd ~/crm-cloud-makip/infra/environments/dev
terraform destroy
```

El bucket `TU_ID-tfstate` no se borra (guarda el estado). Si ya no lo necesitas: `gcloud storage rm -r gs://TU_ID-tfstate`.

## Activar Firebase Hosting (opcional, después)

1. En [console.firebase.google.com](https://console.firebase.google.com) pulsa **Agregar proyecto** y elige tu proyecto de GCP.
2. En `infra/environments/dev/terraform.tfvars` cambia `enable_hosting = true` (deja `create_firebase_project = false`).
3. `terraform plan -out=tfplan && terraform apply tfplan`.
