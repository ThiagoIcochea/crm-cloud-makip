-- KPIs del dashboard (sección 11.3). Cada consulta alimenta un gráfico de Data Studio.
DECLARE n_dias INT64 DEFAULT 90;

-- Pedidos por semana
SELECT DATE_TRUNC(fecha, WEEK(MONDAY)) AS semana, COUNT(*) AS pedidos
FROM makip_marts.mart_orders WHERE estado_odoo = 'sale'
GROUP BY semana ORDER BY semana;

-- Tasa de conversión (oportunidades ganadas / registradas)
SELECT SAFE_DIVIDE(COUNTIF(probabilidad = 100), COUNT(*)) AS tasa_conversion
FROM makip_marts.mart_pipeline;

-- % pedidos atrasados sobre abiertos
SELECT SAFE_DIVIDE(COUNTIF(atrasado), COUNTIF(estado_odoo IN ('draft', 'sent', 'sale'))) AS pct_atrasados
FROM makip_marts.mart_orders;

-- Clientes recurrentes
SELECT SAFE_DIVIDE(COUNTIF(recurrente), COUNTIF(pedidos > 0)) AS pct_recurrentes
FROM makip_marts.mart_customers;

-- Clientes inactivos (N días a definir con la empresa; 90 como parámetro inicial)
SELECT cliente_id, ultima_compra
FROM makip_marts.mart_customers
WHERE pedidos > 0 AND DATE_DIFF(CURRENT_DATE('America/Lima'), ultima_compra, DAY) > n_dias;

-- Ticket promedio
SELECT SAFE_DIVIDE(SUM(total), COUNT(*)) AS ticket_promedio
FROM makip_marts.mart_orders WHERE estado_odoo = 'sale';

-- Oportunidades sin próxima actividad
SELECT COUNTIF(sin_actividad) AS oportunidades_sin_actividad FROM makip_marts.mart_pipeline;

-- Distribución por etapa
SELECT etapa, COUNT(*) AS cantidad FROM makip_marts.mart_pipeline GROUP BY etapa ORDER BY MIN(etapa_orden);
