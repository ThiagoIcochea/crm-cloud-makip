-- Segmentación de clientes para fidelización (BigQuery: makip_staging → makip_marts).
CREATE OR REPLACE TABLE makip_marts.segmentacion_clientes AS
SELECT
  cliente,
  pedidos,
  ROUND(monto_total, 2) AS monto_total,
  DATE(ultimo_pedido) AS ultimo_pedido,
  oportunidades_abiertas,
  CASE
    WHEN pedidos >= 2 THEN 'Cliente frecuente: 10 % por docena'
    WHEN ultimo_pedido IS NOT NULL AND DATE_DIFF(CURRENT_DATE('America/Lima'), DATE(ultimo_pedido), DAY) > 90 THEN 'Por reactivar: recordatorio y delivery gratis'
    WHEN oportunidades_abiertas > 0 OR monto_total >= 150 THEN 'Potencial: diseño personalizado de cortesía'
    ELSE 'Seguimiento normal'
  END AS accion_sugerida
FROM makip_staging.clientes_odoo;

SELECT * FROM makip_marts.segmentacion_clientes ORDER BY monto_total DESC;
