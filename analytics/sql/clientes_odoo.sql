-- Extracción (se ejecuta en PostgreSQL de Odoo): resumen por cliente para BigQuery.
COPY (
  SELECT p.name AS cliente,
         COUNT(DISTINCT so.id) AS pedidos,
         COALESCE(SUM(so.amount_total), 0)::float AS monto_total,
         to_char(MAX(so.date_order), 'YYYY-MM-DD HH24:MI:SS') AS ultimo_pedido,
         (SELECT COUNT(*) FROM crm_lead l JOIN crm_stage s ON s.id = l.stage_id
           WHERE l.partner_id = p.id AND l.active AND NOT s.is_won) AS oportunidades_abiertas
  FROM res_partner p
  LEFT JOIN sale_order so ON so.partner_id = p.id AND so.state = 'sale'
  WHERE p.email LIKE '%@ejemplo.pe' OR p.id IN (SELECT partner_id FROM crm_lead WHERE partner_id IS NOT NULL)
  GROUP BY p.id, p.name
) TO STDOUT WITH CSV HEADER;
