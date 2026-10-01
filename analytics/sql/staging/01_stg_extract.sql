-- Staging: extracción federada de Cloud SQL (solo columnas necesarias).
-- Reemplazar ${CONN} por el valor de `terraform output bq_connection`
-- (formato proyecto.region.conexion). Se ejecuta como consulta programada.
-- Nota: desde Odoo 16, los nombres traducibles (p. ej. crm_stage.name) son JSONB.

CREATE OR REPLACE TABLE makip_staging.stg_sale_orders AS
SELECT * FROM EXTERNAL_QUERY("${CONN}", """
  SELECT so.id            AS pedido_id,
         so.name          AS pedido_ref,
         so.partner_id    AS cliente_id,
         so.user_id       AS responsable_id,
         so.state         AS estado_odoo,
         so.date_order    AS fecha_pedido,
         so.create_date   AS fecha_registro,
         so.commitment_date AS fecha_compromiso,
         so.amount_total  AS total
  FROM sale_order so
""");

CREATE OR REPLACE TABLE makip_staging.stg_customers AS
SELECT * FROM EXTERNAL_QUERY("${CONN}", """
  SELECT p.id AS cliente_id, p.create_date AS fecha_alta, p.active AS activo
  FROM res_partner p
  WHERE p.type = 'contact'
""");

CREATE OR REPLACE TABLE makip_staging.stg_leads AS
SELECT * FROM EXTERNAL_QUERY("${CONN}", """
  SELECT l.id AS oportunidad_id,
         l.partner_id AS cliente_id,
         l.user_id AS responsable_id,
         COALESCE(s.name->>'es_PE', s.name->>'en_US') AS etapa,
         s.sequence AS etapa_orden,
         l.probability AS probabilidad,
         l.expected_revenue AS valor,
         l.create_date AS fecha_registro,
         l.date_closed AS fecha_cierre,
         l.active AS activa,
         (SELECT MIN(a.date_deadline) FROM mail_activity a
           WHERE a.res_model = 'crm.lead' AND a.res_id = l.id) AS proxima_actividad
  FROM crm_lead l
  LEFT JOIN crm_stage s ON s.id = l.stage_id
  WHERE l.type = 'opportunity'
""");
