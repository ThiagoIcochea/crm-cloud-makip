-- Reglas de calidad de datos (sección 11.4). Resultado esperado: 0 filas en cada control.

-- Pedido sin cliente
SELECT 'pedido_sin_cliente' AS control, pedido_id FROM makip_marts.mart_orders WHERE cliente_id IS NULL;

-- Totales negativos
SELECT 'total_negativo' AS control, pedido_id FROM makip_marts.mart_orders WHERE total < 0;

-- Fechas futuras inválidas
SELECT 'fecha_futura' AS control, pedido_id FROM makip_marts.mart_orders
WHERE fecha > CURRENT_DATE('America/Lima');

-- Estados fuera del catálogo de Odoo
SELECT 'estado_desconocido' AS control, pedido_id FROM makip_marts.mart_orders
WHERE estado_odoo NOT IN ('draft', 'sent', 'sale', 'cancel');

-- Oportunidades sin etapa
SELECT 'oportunidad_sin_etapa' AS control, oportunidad_id FROM makip_marts.mart_pipeline WHERE etapa IS NULL;
