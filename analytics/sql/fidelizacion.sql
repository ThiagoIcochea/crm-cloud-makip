-- Segmentación de clientes para fidelización, leída en vivo desde la base de Odoo (Cloud SQL) con EXTERNAL_QUERY.
SELECT
  cliente,
  pedidos,
  monto_total,
  DATE(ultimo_pedido) AS ultimo_pedido,
  oportunidades_abiertas,
  CASE
    WHEN pedidos >= 2 THEN 'Cliente frecuente: 10 % por docena'
    WHEN ultimo_pedido IS NOT NULL AND DATE_DIFF(CURRENT_DATE(), DATE(ultimo_pedido), DAY) > 90 THEN 'Por reactivar: recordatorio y delivery gratis'
    WHEN oportunidades_abiertas > 0 OR monto_total >= 150 THEN 'Potencial: diseño personalizado de cortesía'
    ELSE 'Seguimiento normal'
  END AS accion_sugerida
FROM EXTERNAL_QUERY(
  'sc-45104-makip.southamerica-west1.odoo-cloudsql',
  '''
  SELECT p.name AS cliente,
         COUNT(DISTINCT so.id) AS pedidos,
         COALESCE(SUM(so.amount_total), 0)::float AS monto_total,
         MAX(so.date_order) AS ultimo_pedido,
         (SELECT COUNT(*) FROM crm_lead l JOIN crm_stage s ON s.id = l.stage_id
           WHERE l.partner_id = p.id AND l.active AND NOT s.is_won) AS oportunidades_abiertas
  FROM res_partner p
  LEFT JOIN sale_order so ON so.partner_id = p.id AND so.state = 'sale'
  WHERE p.email LIKE '%@ejemplo.pe' OR p.id IN (SELECT partner_id FROM crm_lead WHERE partner_id IS NOT NULL)
  GROUP BY p.id, p.name
  '''
)
ORDER BY monto_total DESC;
