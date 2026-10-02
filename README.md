# crm-cloud-makip

Plataforma comercial cloud para **Makip Te Crea**: landing con catálogo digital, WhatsApp contextual, **Odoo Community** como CRM y analítica en **BigQuery + Data Studio**, desplegada en **Google Cloud** con **Terraform** y **GitHub Actions**.

Proyecto del curso **Servicios Cloud — Sección 45104**, Universidad Tecnológica del Perú (Lima, 2026).

> Enunciado: *Evaluación de una plataforma cloud con CRM y catálogo web en las operaciones comerciales de Makip Te Crea, Lima, 2026.*

## Arquitectura

```
Cliente (TikTok / redes)
   │
   ▼
makiptecrea.pe ──► Firebase Hosting (web/)  ──── CTA ───► WhatsApp +51 923 119 167 (mensaje contextual)
                        │ /api/catalogo
                        ▼
                   Cloud Run (api/)  ── API externa Odoo (clave en Secret Manager)
                        │ VPC privada
                        ▼
                   Compute Engine: Odoo Community + Nginx (app/)
                        │ IP privada
                        ▼
                   Cloud SQL PostgreSQL ──► BigQuery (EXTERNAL_QUERY) ──► Data Studio
```

Transversales: Cloud Storage (estado Terraform), Secret Manager, Cloud Logging/Monitoring, Billing Budget, IAM de mínimo privilegio y Workload Identity Federation para GitHub Actions.

**Reglas clave**
- La landing **no** es un e-commerce: sin carrito, checkout, pasarela ni cuentas de compradores.
- **Odoo es la fuente única del catálogo** (productos, precios, imágenes). No hay segunda BD ni CMS.
- El navegador **nunca** se conecta a PostgreSQL. Cloud SQL solo tiene IP privada.
- Flujo comercial: consulta → cotización → confirmación → **adelanto 50 %** → diseño → revisión → **aprobación (diseño congelado)** → producción → empaquetado → **saldo** → delivery (costo adicional) o recojo.

## Estructura

| Ruta | Contenido |
|---|---|
| `infra/modules/` | Módulos Terraform: `network`, `security`, `database`, `compute`, `cloudrun`, `hosting`, `observability`, `analytics` |
| `infra/environments/dev`, `demo` | Composición de módulos, variables y backend por entorno |
| `web/` | Landing y catálogo (HTML/CSS/JS sin framework) + `firebase.json` |
| `api/` | API de catálogo de solo lectura (Node.js) para Cloud Run + Dockerfile + tests |
| `app/` | Odoo Community con Docker Compose, Nginx y configuración del pipeline |
| `analytics/sql/` | Staging, data marts y controles de calidad para BigQuery |
| `scripts/` | Smoke tests y utilidades |
| `docs/` | Arquitectura, runbook, pipeline de estados, medición y ADRs |
| `.github/workflows/` | CI (validaciones) y despliegue (WIF) |

## Inicio rápido (local)

```bash
# 1. Odoo + PostgreSQL locales
cd app && cp .env.example .env && docker compose --profile local up -d && bash ../scripts/init_odoo.sh
# Odoo en http://localhost:8069 (BD "makip" con CRM, Ventas y Contactos)

# 2. API de catálogo
cd api && npm install && cp .env.example .env && npm run dev     # http://localhost:8080/api/catalogo

# 3. Landing
cd web && npx serve .     # o abre web/index.html; usa datos de demostración si la API no responde
```

## Probar en tu proyecto de Google Cloud

Desde Google Cloud Shell:

```bash
git clone https://github.com/ThiagoIcochea/crm-cloud-makip.git && cd crm-cloud-makip
bash scripts/probar_gcp.sh TU_ID_DE_PROYECTO   # init + validate + plan, sin costo
```

Guía completa (crear, verificar, abrir Odoo por túnel IAP y destruir): [`docs/probar-gcp.md`](docs/probar-gcp.md).

## Despliegue en GCP

1. Crear el bucket de estado: `gsutil mb -l southamerica-west1 gs://<PROYECTO>-tfstate && gsutil versioning set on gs://<PROYECTO>-tfstate`.
2. `cd infra/environments/dev && cp terraform.tfvars.example terraform.tfvars` y completar.
3. `terraform init -backend-config="bucket=<PROYECTO>-tfstate"` → `terraform plan` → `terraform apply`.
4. Registrar en GitHub (Settings → Variables) los valores que imprime `terraform output` (`wif_provider`, `deploy_sa_email`, etc.).
5. Los despliegues posteriores se hacen por Pull Request y el workflow `deploy.yml`.

Guía completa: [`docs/runbook.md`](docs/runbook.md).

## Costos estimados (Pricing Calculator, southamerica-west1)

| Servicio | US$/mes |
|---|---:|
| Compute Engine (E2, 2 vCPU, 4 GiB, 20 GiB) | 61.78 |
| Cloud SQL (db-g1-small, 20 GiB SSD) | 40.53 |
| Cloud Run (supuesto: 100 000 solicitudes/mes) | 1.89 |
| Networking | 0.76 |
| Cloud Storage | 0.60 |
| Secret Manager | 0.24 |
| Cloud Logging | 0.10 |
| BigQuery | 0.00 |
| **Total GCP** | **105.90** |

Dominio `makiptecrea.pe`: S/110/año (aparte). Firebase Hosting y TLS: US$0.00 dentro de cuotas. Estimación, no facturación real.

## Por completar

- [x] Número de WhatsApp de la empresa en `web/config.js` (+51 923 119 167).
- [ ] ID de proyecto GCP, cuenta de facturación y correo de alertas en `terraform.tfvars`.
- [ ] Validar en la PoC el mecanismo de API externa de la versión fijada de Odoo (`ODOO_API_MODE`).
- [ ] Validar estados operativos en Odoo (Proyecto vs. campo de estado) — ver `docs/pipeline-estados.md`.

## Equipo

Icochea Rodriguez, Thiago Paolo · Gonzales Aguilar, Carlos Enrique Giussepe · Huamani Pereira, Eddyson Cesar · Torres Centeno, Emmanuel Misael · Remuzgo Tovar, Huber Eduardo · Quispe Saavedra, Karen Meylin

Flujo de trabajo: ramas por tarea, Pull Request con revisión de otro integrante, `main` protegida.
