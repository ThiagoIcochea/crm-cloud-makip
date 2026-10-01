# Pipeline comercial y operativo

Flujo real de Makip Te Crea registrado en Odoo Community (secciones 6.2 y 8.4 del documento).

## Tramo comercial (CRM → etapas de oportunidad)

1. Nueva consulta
2. Cotizado
3. Confirmado – pendiente de adelanto
4. Adelanto recibido → oportunidad **ganada** y pedido de venta confirmado

## Tramo operativo (pedido)

5. Diseño
6. Diseño en revisión del cliente
7. Aprobado para producción *(diseño congelado)*
8. Producción
9. Empaquetado
10. Pendiente de saldo
11. Listo para entrega/recojo
12. Entregado

Las etapas están en `app/seed/etapas_pipeline.csv`.

## Reglas de negocio

| ID | Regla |
|---|---|
| RN-01 | El diseño personalizado se trabaja solo después del adelanto del 50 %. |
| RN-02 | El diseño se envía al cliente para revisión antes de producir. |
| RN-03 | Tras aprobar el diseño y autorizar producción, no se modifica el diseño. Registrar fecha y evidencia en el historial. |
| RN-04 | El saldo se cancela después del empaquetado y antes de la entrega. |
| RN-05 | Delivery/envío con costo adicional (producto de servicio `SERV-DEL`); recojo sin costo. |
| RN-06 | Precios y productos publicados provienen de Odoo. |
| RN-07 | Las imágenes del catálogo son referenciales. |
| RN-08 | WhatsApp es canal de contacto, no checkout. |

## Opciones para el tramo operativo (decidir en la PoC, semana 2)

| Opción | Tipo | Ventaja | Costo |
|---|---|---|---|
| A. App **Proyecto** (Community): una tarea por pedido con etapas Kanban | Configuración | Sin código | Dos pantallas (pedido y tarea) |
| B. Campo «estado operativo» en `sale.order` | Extensión ligera en `app/addons/` | Todo en el pedido | Requiere módulo y ADR |

Registrar la decisión como ADR-013.
