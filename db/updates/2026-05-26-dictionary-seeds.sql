-- HODOM Drive dictionary seeds
-- Non-destructive seed views for service, professional, and address mappings.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_dictionary_seed_summary;
DROP VIEW IF EXISTS staging.v_hodom_address_domicilio_dictionary_seed;
DROP VIEW IF EXISTS staging.v_hodom_professional_provider_dictionary_seed;
DROP VIEW IF EXISTS staging.v_hodom_service_prestacion_dictionary_seed;

CREATE OR REPLACE VIEW staging.v_hodom_service_prestacion_dictionary_seed AS
WITH ready_routes AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        staging.norm_text(rv.service_text) AS service_text_norm
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
      AND nullif(staging.norm_text(rv.service_text), '') IS NOT NULL
)
SELECT
    'service_prestacion'::text AS dictionary_type,
    'reference.catalogo_prestacion'::text AS target_table,
    'svc_' || substr(md5(service_text_norm), 1, 24) AS seed_key,
    service_text_norm AS source_value_norm,
    NULL::text AS source_role,
    'NEEDS_DICTIONARY_TARGET'::text AS review_status,
    count(*) AS route_rows,
    count(DISTINCT date_trunc('month', visit_date)) AS active_months,
    min(visit_date) AS first_seen_date,
    max(visit_date) AS last_seen_date
FROM ready_routes
GROUP BY service_text_norm;

CREATE OR REPLACE VIEW staging.v_hodom_professional_provider_dictionary_seed AS
WITH ready_routes AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        lower(trim(p.role)) AS source_role,
        staging.norm_text(p.professional_text) AS professional_text_norm
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    CROSS JOIN LATERAL jsonb_each_text(rv.professionals) AS p(role, professional_text)
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
      AND nullif(staging.norm_text(p.professional_text), '') IS NOT NULL
)
SELECT
    'professional_provider'::text AS dictionary_type,
    'operational.profesional'::text AS target_table,
    'pro_' || substr(md5(source_role || '|' || professional_text_norm), 1, 24) AS seed_key,
    professional_text_norm AS source_value_norm,
    source_role,
    'NEEDS_DICTIONARY_TARGET'::text AS review_status,
    count(*) AS route_rows,
    count(DISTINCT date_trunc('month', visit_date)) AS active_months,
    min(visit_date) AS first_seen_date,
    max(visit_date) AS last_seen_date
FROM ready_routes
GROUP BY source_role, professional_text_norm;

CREATE OR REPLACE VIEW staging.v_hodom_address_domicilio_dictionary_seed AS
WITH ready_routes AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        staging.norm_text(rv.address_text) AS address_text_norm
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
      AND nullif(staging.norm_text(rv.address_text), '') IS NOT NULL
)
SELECT
    'address_domicilio'::text AS dictionary_type,
    'clinical.domicilio'::text AS target_table,
    'addr_' || substr(md5(address_text_norm), 1, 24) AS seed_key,
    address_text_norm AS source_value_norm,
    NULL::text AS source_role,
    'NEEDS_DICTIONARY_TARGET'::text AS review_status,
    count(*) AS route_rows,
    count(DISTINCT date_trunc('month', visit_date)) AS active_months,
    min(visit_date) AS first_seen_date,
    max(visit_date) AS last_seen_date
FROM ready_routes
GROUP BY address_text_norm;

CREATE OR REPLACE VIEW staging.v_hodom_dictionary_seed_summary AS
SELECT
    dictionary_type,
    target_table,
    review_status,
    count(*) AS seed_terms,
    sum(route_rows) AS route_mentions,
    min(first_seen_date) AS first_seen_date,
    max(last_seen_date) AS last_seen_date
FROM (
    SELECT dictionary_type, target_table, review_status, route_rows, first_seen_date, last_seen_date
    FROM staging.v_hodom_service_prestacion_dictionary_seed
    UNION ALL
    SELECT dictionary_type, target_table, review_status, route_rows, first_seen_date, last_seen_date
    FROM staging.v_hodom_professional_provider_dictionary_seed
    UNION ALL
    SELECT dictionary_type, target_table, review_status, route_rows, first_seen_date, last_seen_date
    FROM staging.v_hodom_address_domicilio_dictionary_seed
) seeds
GROUP BY dictionary_type, target_table, review_status;

COMMENT ON VIEW staging.v_hodom_service_prestacion_dictionary_seed IS 'Seed terms for mapping route service text to reference.catalogo_prestacion. Values remain in DB for review and must not be exported as nominal row files.';
COMMENT ON VIEW staging.v_hodom_professional_provider_dictionary_seed IS 'Seed terms for mapping route professional text to operational.profesional. Values may identify personnel and must not be exported as nominal row files.';
COMMENT ON VIEW staging.v_hodom_address_domicilio_dictionary_seed IS 'Seed terms for mapping route address text to clinical.domicilio. Values may identify domiciles and must not be exported as nominal row files.';
COMMENT ON VIEW staging.v_hodom_dictionary_seed_summary IS 'Aggregate counts of dictionary seed terms for service, professional, and address mapping.';

COMMIT;
