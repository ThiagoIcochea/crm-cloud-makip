# ADR-009: Landing en Firebase Hosting y catálogo por API en Cloud Run

- **Estado:** Aceptada
- **Fecha:** 2026-10-01

## Contexto

Los clientes llegan desde TikTok y otras redes y la empresa necesita una página con catálogo, precios e imágenes referenciales que dirija a WhatsApp. No se requiere e-commerce.

## Decisión

Publicar una landing estática en Firebase Hosting (HTTPS y dominio administrados) y servir el catálogo con una API de solo lectura en Cloud Run que consulta Odoo por red privada.

## Alternativas consideradas

| Alternativa | A favor | En contra |
|---|---|---|
| Módulo Website de Odoo | Sin integración | Expone Odoo directamente al público; acopla la web al CRM |
| Landing estática sin API | Más simple | Precios duplicados fuera de Odoo |

## Consecuencias

- Costo estimado marginal (Cloud Run US$1.89/mes con el supuesto de 100 000 solicitudes; Hosting dentro de cuotas).
- Validar las reescrituras de Hosting hacia Cloud Run en southamerica-west1; alternativa: `apiBase` con CORS.
