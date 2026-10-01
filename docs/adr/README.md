# Architecture Decision Records

Cada decisión relevante se registra en un archivo `ADR-NNN-titulo.md` con la plantilla [`template.md`](template.md). Estado inicial de las decisiones del documento (Anexo D):

| ADR | Decisión | Estado |
|---|---|---|
| [ADR-001](ADR-001-odoo-community.md) | Adoptar Odoo Community en lugar de desarrollar un CRM | Aceptada (validar en PoC) |
| ADR-002 | Compute Engine containerizado en lugar de GKE para el MVP | Aceptada |
| ADR-003 | Cloud SQL PostgreSQL privado como persistencia administrada | Aceptada |
| ADR-004 | Terraform como fuente de verdad de la infraestructura | Aceptada |
| ADR-005 | Workload Identity Federation para CI/CD, sin claves estáticas | Aceptada |
| ADR-006 | BigQuery Federation + materialización antes que CDC | Aceptada |
| ADR-007 | Separar arquitectura objetivo e implementada (sin HA en el MVP) | Aceptada |
| ADR-008 | Fijar versiones de Odoo (19.0) y de los providers de Terraform | Aceptada |
| [ADR-009](ADR-009-landing-firebase-cloudrun.md) | Landing en Firebase Hosting y catálogo por API en Cloud Run | Aceptada |
| [ADR-010](ADR-010-odoo-fuente-unica-catalogo.md) | Odoo como fuente única del catálogo | Aceptada |
| ADR-011 | Balanceador de carga y Cloud Armor fuera de la estimación base | Aceptada |
| ADR-012 | WhatsApp como canal sin integración nativa con Odoo (app Enterprise) | Aceptada |
| ADR-013 | Mecanismo de estados operativos (Proyecto vs. campo de estado) | Pendiente (PoC) |

Las filas sin enlace tienen su justificación en el documento del proyecto; crear el archivo cuando la decisión se revise o cambie.
