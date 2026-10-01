# ADR-010: Odoo como fuente única del catálogo

- **Estado:** Aceptada
- **Fecha:** 2026-10-01

## Contexto

Mantener productos y precios en dos lugares produce inconsistencias entre lo que ve el cliente y lo que cotiza la empresa.

## Decisión

Los productos, precios, categorías, descripciones, códigos e imágenes se administran solo en Odoo. La landing los obtiene por la API de catálogo. No se crea una segunda base de datos, panel administrativo ni CMS.

## Consecuencias

- Publicar un producto = `sale_ok = True` en Odoo (o el dominio definido en `CATALOG_DOMAIN`).
- La API filtra campos públicos; nunca expone costos ni datos de clientes.
- Indicador técnico: 0 diferencias de precio/nombre entre landing y Odoo en la muestra revisada.
