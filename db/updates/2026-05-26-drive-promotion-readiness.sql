-- HODOM Drive promotion readiness
-- Non-destructive quality and matching views before any core-table promotion.

BEGIN;

CREATE OR REPLACE FUNCTION staging.norm_text(value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT NULLIF(
        btrim(
        regexp_replace(
            translate(upper(coalesce(value, '')), 'ÁÉÍÓÚÜÑ', 'AEIOUUN'),
            '\s+',
            ' ',
            'g'
        )),
        ''
    )
$$;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_candidate AS
WITH route_base AS (
    SELECT
        r.route_visit_id,
        'drv_route_' || substr(md5(r.route_visit_id), 1, 16) AS candidate_visit_id,
        r.drive_id,
        r.source_path,
        r.sheet_name,
        r.source_row_number,
        r.visit_date,
        extract(year FROM r.visit_date)::integer AS visit_year,
        extract(month FROM r.visit_date)::integer AS visit_month,
        r.planned_time,
        r.professionals,
        r.service_text,
        r.raw_record,
        staging.norm_text(r.patient_name) AS patient_name_norm,
        staging.norm_text(r.address_text) AS address_norm,
        CASE WHEN r.patient_name IS NULL OR btrim(r.patient_name) = '' THEN true ELSE false END AS missing_patient_name,
        CASE WHEN r.address_text IS NULL OR btrim(r.address_text) = '' THEN true ELSE false END AS missing_address,
        CASE WHEN r.service_text IS NULL OR btrim(r.service_text) = '' THEN true ELSE false END AS missing_service
    FROM staging.hodom_route_visit r
),
patient_match AS (
    SELECT
        rb.route_visit_id,
        count(DISTINCT p.patient_id) AS patient_match_count,
        min(p.patient_id) AS matched_patient_id
    FROM route_base rb
    LEFT JOIN clinical.paciente p
      ON staging.norm_text(p.nombre_completo) = rb.patient_name_norm
     AND p.deleted_at IS NULL
    GROUP BY rb.route_visit_id
),
stay_match AS (
    SELECT
        rb.route_visit_id,
        count(DISTINCT e.stay_id) AS active_stay_match_count,
        min(e.stay_id) AS matched_stay_id
    FROM route_base rb
    JOIN clinical.paciente p
      ON staging.norm_text(p.nombre_completo) = rb.patient_name_norm
     AND p.deleted_at IS NULL
    JOIN clinical.estadia e
      ON e.patient_id = p.patient_id
     AND rb.visit_date IS NOT NULL
     AND rb.visit_date >= e.fecha_ingreso
     AND rb.visit_date <= coalesce(e.fecha_egreso, rb.visit_date)
    GROUP BY rb.route_visit_id
),
existing_visit AS (
    SELECT
        rb.route_visit_id,
        count(v.visit_id) AS existing_visit_count
    FROM route_base rb
    JOIN clinical.paciente p
      ON staging.norm_text(p.nombre_completo) = rb.patient_name_norm
     AND p.deleted_at IS NULL
    JOIN operational.visita v
      ON v.patient_id = p.patient_id
     AND v.fecha = rb.visit_date
    GROUP BY rb.route_visit_id
)
SELECT
    rb.route_visit_id,
    rb.candidate_visit_id,
    rb.drive_id,
    rb.source_path,
    rb.sheet_name,
    rb.source_row_number,
    rb.visit_date,
    rb.visit_year,
    rb.visit_month,
    rb.planned_time,
    rb.professionals,
    rb.service_text,
    rb.raw_record,
    rb.patient_name_norm,
    rb.address_norm,
    rb.missing_patient_name,
    rb.missing_address,
    rb.missing_service,
    coalesce(pm.patient_match_count, 0) AS patient_match_count,
    CASE WHEN coalesce(pm.patient_match_count, 0) = 1 THEN pm.matched_patient_id ELSE NULL END AS matched_patient_id,
    coalesce(sm.active_stay_match_count, 0) AS active_stay_match_count,
    CASE WHEN coalesce(sm.active_stay_match_count, 0) = 1 THEN sm.matched_stay_id ELSE NULL END AS matched_stay_id,
    coalesce(ev.existing_visit_count, 0) AS existing_visit_count,
    CASE
        WHEN rb.visit_date IS NULL THEN 'BLOCKED_MISSING_DATE'
        WHEN rb.missing_patient_name THEN 'BLOCKED_MISSING_PATIENT_NAME'
        WHEN coalesce(pm.patient_match_count, 0) = 0 THEN 'BLOCKED_NO_PATIENT_MATCH'
        WHEN coalesce(pm.patient_match_count, 0) > 1 THEN 'BLOCKED_AMBIGUOUS_PATIENT_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) = 0 THEN 'BLOCKED_NO_ACTIVE_STAY_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) > 1 THEN 'BLOCKED_AMBIGUOUS_ACTIVE_STAY_MATCH'
        WHEN coalesce(ev.existing_visit_count, 0) > 0 THEN 'REVIEW_EXISTING_CORE_VISIT_SAME_DAY'
        ELSE 'READY_CORE_VISIT'
    END AS match_status
FROM route_base rb
LEFT JOIN patient_match pm ON pm.route_visit_id = rb.route_visit_id
LEFT JOIN stay_match sm ON sm.route_visit_id = rb.route_visit_id
LEFT JOIN existing_visit ev ON ev.route_visit_id = rb.route_visit_id;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_summary AS
SELECT
    visit_year,
    visit_month,
    match_status,
    count(*) AS route_rows,
    count(*) FILTER (WHERE missing_address) AS missing_address_rows,
    count(*) FILTER (WHERE missing_service) AS missing_service_rows,
    count(*) FILTER (WHERE jsonb_typeof(professionals) = 'object' AND professionals <> '{}'::jsonb) AS rows_with_professional,
    count(DISTINCT patient_name_norm) AS distinct_patient_names_norm,
    count(DISTINCT patient_name_norm || '|' || coalesce(address_norm, '')) AS distinct_patient_address_pairs_norm
FROM staging.v_hodom_route_promotion_candidate
GROUP BY visit_year, visit_month, match_status;

CREATE OR REPLACE VIEW staging.v_hodom_handover_promotion_summary AS
SELECT
    count(*) AS total_handovers,
    count(*) FILTER (WHERE period_start IS NOT NULL AND period_end IS NOT NULL) AS with_period,
    count(*) FILTER (WHERE period_start IS NULL OR period_end IS NULL) AS missing_period,
    count(*) FILTER (WHERE text_content IS NOT NULL AND btrim(text_content) <> '') AS with_text,
    count(*) FILTER (WHERE text_content IS NULL OR btrim(text_content) = '') AS missing_text,
    min(period_start) AS min_period_start,
    max(period_end) AS max_period_end
FROM staging.hodom_shift_handover;

COMMENT ON FUNCTION staging.norm_text(text) IS 'Deterministic text normalization for staging reconciliation. Does not export nominal values.';
COMMENT ON VIEW staging.v_hodom_route_promotion_candidate IS 'Drive route row matching/readiness against patient and stay core tables. Contains normalized nominal keys in DB only; do not export.';
COMMENT ON VIEW staging.v_hodom_route_promotion_summary IS 'Aggregate route promotion readiness by period and status; safe for documentation.';
COMMENT ON VIEW staging.v_hodom_handover_promotion_summary IS 'Aggregate handover readiness; safe for documentation.';

COMMIT;
