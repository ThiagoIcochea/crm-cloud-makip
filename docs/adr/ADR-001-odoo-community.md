# ADR-001: Adoptar Odoo Community como CRM

- **Estado:** Aceptada (sujeta a la PoC de la semana 2)
- **Fecha:** 2026-10-01

## Contexto

El proyecto dura como máximo 15 semanas y su valor está en la ingeniería cloud y en la medición, no en programar un CRM. Se requieren clientes, oportunidades, productos, cotizaciones, pedidos e historial.

## Decisión

Usar Odoo Community (LGPLv3) con CRM, Ventas y Contactos, priorizando configuración sobre código.

## Alternativas consideradas

| Alternativa | A favor | En contra |
|---|---|---|
| SuiteCRM | CRM maduro | Pedidos y productos menos integrados; stack PHP |
| ERPNext | ERP/CRM completo | Stack Frappe más complejo para el plazo |
| Desarrollo propio | Ajuste total | Riesgo alto de exceder el plazo |

## Consecuencias

- No se usan apps Enterprise (WhatsApp, Studio).
- Los estados operativos posteriores a la venta requieren decisión en la PoC (ADR-013).
- Fijar la versión (ADR-008) y versionar las consultas analíticas.
