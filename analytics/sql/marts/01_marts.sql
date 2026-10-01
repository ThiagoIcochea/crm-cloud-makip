-- Data marts mínimos (sección 11.2 del documento).

CREATE OR REPLACE TABLE makip_marts.mart_orders AS
SELECT
  pedido_id,
  pedido_ref,
  cliente_id,
  responsable_id,
  DATE(fecha_pedido) AS fecha,
  estado_odoo,
  total,
  DATE_DIFF(CURRENT_DATE('America/Lima'), DATE(fecha_registro), DAY) AS dias_desde_registro,
  fecha_compromiso IS NOT NULL
    AND DATE(fecha_compromiso) < CURRENT_DATE('America/Lima')
    AND estado_odoo NOT IN ('cancel') AS atrasado
FROM makip_staging.stg_sale_orders;

CREATE OR REPLACE TABLE makip_marts.mart_customers AS
SELECT
  c.cliente_id,
  DATE(c.fecha_alta) AS fecha_alta,
  COUNTIF(o.estado_odoo = 'sale') AS pedidos,
  SUM(IF(o.estado_odoo = 'sale', o.total, 0)) AS monto_total,
  MAX(IF(o.estado_odoo = 'sale', DATE(o.fecha_pedido), NULL)) AS ultima_compra,
  COUNTIF(o.estado_odoo = 'sale') > 1 AS recurrente
FROM makip_staging.stg_customers c
LEFT JOIN makip_staging.stg_sale_orders o USING (cliente_id)
GROUP BY c.cliente_id, fecha_alta;

CREATE OR REPLACE TABLE makip_marts.mart_pipeline AS
SELECT
  oportunidad_id,
  etapa,
  etapa_orden,
  probabilidad,
  valor,
  responsable_id,
  DATE_DIFF(CURRENT_DATE('America/Lima'), DATE(fecha_registro), DAY) AS edad_dias,
  proxima_actividad IS NULL AND activa AS sin_actividad
FROM makip_staging.stg_leads;
