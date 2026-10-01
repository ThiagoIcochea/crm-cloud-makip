# Arquitectura

Resumen técnico de la sección 10 del documento del proyecto.

| Capa | Servicio | Carpeta |
|---|---|---|
| Landing y catálogo | Firebase Hosting (HTTPS administrado, dominio makiptecrea.pe) | `web/` |
| API de catálogo | Cloud Run (solo lectura, mín. 0 instancias, máx. 3) | `api/` |
| CRM | Odoo Community en Docker sobre Compute Engine E2 (2 vCPU, 4 GiB) | `app/` |
| Base de datos | Cloud SQL PostgreSQL db-g1-small, IP privada, backups diarios | `infra/modules/database` |
| Analítica | BigQuery (federación + marts) y Data Studio | `analytics/` |
| Transversales | Cloud Storage, Secret Manager, Cloud Logging/Monitoring, Billing Budget, IAM, WIF | `infra/modules/*` |

## Flujos

**Catálogo:** Administrador → Odoo (Productos) → API externa de Odoo → Cloud Run (`/api/catalogo`) → Landing. Odoo es la fuente única: no hay segunda base de datos ni CMS.

**Contacto:** Ficha de producto → botón *Consultar por WhatsApp* → `wa.me` con el mensaje contextual (producto, código, enlace). No crea pedidos ni transmite datos personales.

**Analítica:** Cloud SQL → `EXTERNAL_QUERY` (usuario `bq_reader`, solo lectura) → `makip_staging` → `makip_marts` → Data Studio.

## Seguridad

- El navegador nunca llega a PostgreSQL. Cloud SQL no tiene IP pública.
- Cloud Run accede a Odoo por la VPC (egreso directo) con un usuario técnico de solo lectura; la clave vive en Secret Manager.
- La API expone únicamente nombre, categoría, descripción, precio, moneda, código e imagen de productos con `sale_ok = True`.
- Backoffice solo por HTTPS; el gestor de bases de datos de Odoo está deshabilitado (`list_db = False`) y bloqueado en Nginx.
- SSH solo por IAP. GitHub Actions usa WIF: sin llaves JSON.

## Aspectos a validar en la prueba de concepto

1. Mecanismo de API externa de la versión fijada de Odoo (`ODOO_API_MODE=json2` o `jsonrpc`).
2. Reescrituras de Firebase Hosting hacia Cloud Run en `southamerica-west1`; si no aplica, la landing usa la URL de Cloud Run (`apiBase` en `web/config.js`) con CORS restringido.
3. Federación de BigQuery con la instancia de IP privada.
4. Estados operativos en Odoo (ver `pipeline-estados.md`).
