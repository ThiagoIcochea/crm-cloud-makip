# Backlog técnico (Anexo A)

| ID | Ítem | Prioridad | Semana | Carpeta |
|---|---|---|---|---|
| INF-01 | Proyecto, APIs y backend de Terraform | Must | 3 | `infra/environments` |
| INF-02 | VPC, subred y firewall | Must | 4 | `infra/modules/network` |
| INF-03 | Cloud SQL PostgreSQL privado | Must | 5 | `infra/modules/database` |
| INF-04 | Compute Engine + Docker/Odoo + Nginx/TLS | Must | 5 | `infra/modules/compute`, `app/` |
| INF-05 | Secret Manager e IAM | Must | 4 | `infra/modules/security` |
| INF-06 | HTTPS Load Balancer + Cloud Armor | Could (evolución) | — | — |
| CRM-01 | Pipeline, estados operativos y reglas RN-01 a RN-08 | Must | 6 | `app/seed`, `docs/pipeline-estados.md` |
| CRM-02 | Cartera: etiquetas, filtros y actividades de seguimiento | Should | 6 | Odoo |
| WEB-01 | Landing y catálogo responsive en Firebase Hosting | Must | 7 | `web/` |
| WEB-02 | Dominio makiptecrea.pe y HTTPS | Must | 7 | `infra/modules/hosting` |
| WEB-03 | CTA de WhatsApp contextual | Must | 7 | `web/app.js` |
| API-01 | API de catálogo en Cloud Run (solo lectura) | Must | 8 | `api/` |
| API-02 | Integración privada con Odoo y secreto de API | Must | 8 | `infra/modules/cloudrun` |
| DEV-01 | CI: fmt/validate/lint/seguridad | Must | 8 | `.github/workflows/ci.yml` |
| DEV-02 | WIF para GitHub Actions | Must | 4 | `infra/modules/security` |
| DEV-03 | Plan/apply y despliegues controlados | Must | 8 | `.github/workflows/deploy.yml` |
| OBS-01 | Logging, Monitoring y uptime | Must | 10 | `infra/modules/observability` |
| OBS-02 | Alertas y presupuesto | Must | 10 | `infra/modules/observability` |
| DAT-01 | Conexión BigQuery–Cloud SQL | Must | 11 | `infra/modules/analytics` |
| DAT-02 | Staging y marts | Must | 12 | `analytics/sql` |
| DAT-03 | Dashboard en Data Studio (≥ 6 KPIs) | Must | 12 | `analytics/sql/kpis` |
| DR-01 | Backups/PITR y ejercicio de restauración | Must | 13 | `docs/runbook.md` |
| QA-01 | Pruebas integrales y mediciones | Must | 13–14 | `docs/medicion`, `scripts/` |
