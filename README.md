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
                   Cloud SQL PostgreSQL ──► (ELT desde la VM) BigQuery staging → marts ──► Data Studio
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

### Landing de prueba en GitHub Pages

Cada cambio en `web/` o en el catálogo publica una versión estática de prueba en GitHub Pages (workflow `pages.yml`):
catálogo real con fotos y precios, selección de varios productos y envío del pedido por WhatsApp con emojis.
El registro automático de la consulta en Odoo (número MK-xxxx) solo funciona en la versión desplegada en Google Cloud.

### Demostración completa (catálogo real en Odoo + landing en Cloud Run)

```bash
bash scripts/probar_gcp.sh TU_ID_DE_PROYECTO && (cd infra/environments/dev && terraform apply tfplan)
bash scripts/demo_gcp.sh TU_ID_DE_PROYECTO     # carga 43 productos reales, pipeline y datos de prueba; publica la landing
bash scripts/analitica_bigquery.sh TU_ID_DE_PROYECTO  # segmentación de clientes en makip_marts
bash scripts/destruir_gcp.sh TU_ID_DE_PROYECTO # elimina todo al terminar
bash scripts/limpiar_restos_gcp.sh TU_ID_DE_PROYECTO  # solo si destroy se detiene (usuarios de Cloud SQL o IP serverless)
bash scripts/inventario_gcp.sh TU_ID_DE_PROYECTO      # verifica que no quede nada
```

El catálogo real (productos, precios y fotos de Makip Te Crea) está en `app/seed/catalogo/`.

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
- [x] Validar el modo de API externa de Odoo 19 (`ODOO_API_MODE=jsonrpc`).
- [x] Datos del proveedor y redes oficiales en `web/config.js` y en el pie de la landing.
- [ ] Validar con la empresa los términos, la política de privacidad y el plazo de cambios antes de publicar.

## Equipo y responsabilidades

Proyecto Final Integrador · Servicios Cloud · Sección 45104 · UTP

| Integrante | Rol principal | Tareas |
|---|---|---|
| Thiago Paolo Icochea Rodriguez | Líder del proyecto · Arquitectura GCP, IaC y CI/CD | Arquitectura GCP e infraestructura con Terraform; Repositorio, CI/CD y despliegue; Cierre del entorno cloud |
| Carlos Enrique Giussepe Gonzales Aguilar | CRM y procesos comerciales (Odoo) | Configuración de Odoo CRM; Flujo comercial y cotizaciones; Fidelización de clientes en el CRM |
| Eddyson Cesar Huamani Pereira | Landing, integración con WhatsApp y API | Landing y catálogo web; Pedido por WhatsApp; API de catálogo e integración con Odoo |
| Huber Eduardo Remuzgo Tovar | Datos, observabilidad y costos | Analítica en BigQuery; Monitoreo y registros; Análisis de costos |
| Karen Meylin Quispe Saavedra | Calidad, aspectos legales y documentación | Pruebas y control de calidad; Cumplimiento legal de la landing; Documento final y presentación |

Responsabilidad compartida: documentación, seguridad, revisión de cambios y sustentación.

- Tablero de trabajo (Trello): https://trello.com/b/p78Xemzg/servicios-cloud-grupo-2 — una tarjeta por responsabilidad con sus subtareas.
- Laboratorios del curso: https://github.com/ThiagoIcochea/labs-servicios-cloud
- Landing de prueba (GitHub Pages): https://thiagoicochea.github.io/crm-cloud-makip/
- Dashboard comercial (Data Studio): https://datastudio.google.com/reporting/7d01ac4d-e6be-4b8d-b3dc-bf8c10090b89 — KPIs de pedidos, ventas, pipeline y conversión, y segmentación de clientes.
