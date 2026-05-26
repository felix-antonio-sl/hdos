-- HODOM Drive 2026 - safe enrichment for V2 duplicate routes.
-- Routes with same-patient/same-day core visits are not inserted. They may
-- only update missing fields on a unique existing visit when the source value
-- is unique across the duplicate routes.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_v2_duplicate_enrichment_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_v2_duplicate_enrichment_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_v2_duplicate_enrichment_preview_2026;

CREATE OR REPLACE VIEW staging.v_hodom_v2_duplicate_enrichment_preview_2026 AS
WITH duplicate_routes AS (
    SELECT
        c.route_visit_id,
        c.matched_patient_id,
        c.visit_date
    FROM staging.v_hodom_route_promotion_contract_v2 c
    WHERE c.visit_year = 2026
      AND c.promotion_gate = 'REVIEW_DUPLICATE_PUSHOUT_REQUIRED'
      AND c.matched_patient_id IS NOT NULL
      AND c.visit_date IS NOT NULL
),
core_target AS (
    SELECT
        d.route_visit_id,
        min(v.visit_id) AS core_visit_id,
        count(DISTINCT v.visit_id) AS core_visit_count
    FROM duplicate_routes d
    JOIN operational.visita v
      ON v.patient_id = d.matched_patient_id
     AND v.fecha = d.visit_date
    GROUP BY d.route_visit_id
),
best_professional AS (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.route_visit_id,
        rpm.suggested_provider_id AS provider_id
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.match_quality
),
service_target AS (
    SELECT
        source_pk AS route_visit_id,
        CASE WHEN count(DISTINCT target_pk) = 1 THEN min(target_pk) ELSE NULL END AS prestacion_id
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type = 'service_prestacion'
      AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
      AND target_pk IS NOT NULL
    GROUP BY source_pk
),
address_target AS (
    SELECT
        d.source_pk AS route_visit_id,
        CASE WHEN count(DISTINCT d.target_pk) = 1 THEN min(d.target_pk) ELSE NULL END AS domicilio_id
    FROM staging.hodom_reconciliation_decision d
    JOIN clinical.domicilio dom ON dom.domicilio_id = d.target_pk
    JOIN duplicate_routes dr
      ON dr.route_visit_id = d.source_pk
     AND dom.patient_id = dr.matched_patient_id
    WHERE d.anchor_type = 'address_domicilio'
      AND d.relation_type = 'maps_to'
      AND d.decision_status = 'proposed'
      AND d.target_pk IS NOT NULL
    GROUP BY d.source_pk
),
source_values AS (
    SELECT
        ct.core_visit_id,
        ct.core_visit_count,
        rv.route_visit_id,
        rv.planned_time,
        bp.provider_id,
        st.prestacion_id,
        at.domicilio_id
    FROM core_target ct
    JOIN staging.hodom_route_visit rv ON rv.route_visit_id = ct.route_visit_id
    LEFT JOIN best_professional bp ON bp.route_visit_id = ct.route_visit_id
    LEFT JOIN service_target st ON st.route_visit_id = ct.route_visit_id
    LEFT JOIN address_target at ON at.route_visit_id = ct.route_visit_id
    WHERE ct.core_visit_count = 1
),
field_candidates AS (
    SELECT
        core_visit_id,
        'hora_plan_inicio' AS field_name,
        min(planned_time) FILTER (WHERE planned_time IS NOT NULL) AS new_value,
        count(DISTINCT planned_time) FILTER (WHERE planned_time IS NOT NULL) AS distinct_values,
        count(*) AS source_route_count,
        string_agg(route_visit_id, ',' ORDER BY route_visit_id) AS source_route_key
    FROM source_values
    GROUP BY core_visit_id

    UNION ALL

    SELECT
        core_visit_id,
        'provider_id' AS field_name,
        min(provider_id) FILTER (WHERE provider_id IS NOT NULL) AS new_value,
        count(DISTINCT provider_id) FILTER (WHERE provider_id IS NOT NULL) AS distinct_values,
        count(*) AS source_route_count,
        string_agg(route_visit_id, ',' ORDER BY route_visit_id) AS source_route_key
    FROM source_values
    GROUP BY core_visit_id

    UNION ALL

    SELECT
        core_visit_id,
        'prestacion_id' AS field_name,
        min(prestacion_id) FILTER (WHERE prestacion_id IS NOT NULL) AS new_value,
        count(DISTINCT prestacion_id) FILTER (WHERE prestacion_id IS NOT NULL) AS distinct_values,
        count(*) AS source_route_count,
        string_agg(route_visit_id, ',' ORDER BY route_visit_id) AS source_route_key
    FROM source_values
    GROUP BY core_visit_id

    UNION ALL

    SELECT
        core_visit_id,
        'domicilio_id' AS field_name,
        min(domicilio_id) FILTER (WHERE domicilio_id IS NOT NULL) AS new_value,
        count(DISTINCT domicilio_id) FILTER (WHERE domicilio_id IS NOT NULL) AS distinct_values,
        count(*) AS source_route_count,
        string_agg(route_visit_id, ',' ORDER BY route_visit_id) AS source_route_key
    FROM source_values
    GROUP BY core_visit_id
)
SELECT
    fc.core_visit_id,
    fc.field_name,
    fc.new_value,
    fc.distinct_values,
    fc.source_route_count,
    fc.source_route_key,
    CASE
        WHEN fc.field_name = 'hora_plan_inicio' THEN v.hora_plan_inicio
        WHEN fc.field_name = 'provider_id' THEN v.provider_id
        WHEN fc.field_name = 'prestacion_id' THEN v.prestacion_id
        WHEN fc.field_name = 'domicilio_id' THEN v.domicilio_id
        ELSE NULL
    END AS current_value,
    CASE
        WHEN fc.new_value IS NULL THEN 'NO_SOURCE_VALUE'
        WHEN fc.distinct_values <> 1 THEN 'CONFLICTING_SOURCE_VALUES'
        WHEN fc.field_name = 'hora_plan_inicio' AND v.hora_plan_inicio IS NULL THEN 'UPDATE_ALLOWED'
        WHEN fc.field_name = 'provider_id' AND v.provider_id IS NULL THEN 'UPDATE_ALLOWED'
        WHEN fc.field_name = 'prestacion_id' AND v.prestacion_id IS NULL THEN 'UPDATE_ALLOWED'
        WHEN fc.field_name = 'domicilio_id' AND v.domicilio_id IS NULL THEN 'UPDATE_ALLOWED'
        ELSE 'TARGET_ALREADY_POPULATED'
    END AS enrichment_status
FROM field_candidates fc
JOIN operational.visita v ON v.visit_id = fc.core_visit_id;

COMMENT ON VIEW staging.v_hodom_v2_duplicate_enrichment_preview_2026 IS
'Field-level V2 duplicate enrichment preview. Updates only missing fields when core_visit_count = 1 and distinct_values = 1.';

CREATE OR REPLACE VIEW staging.v_hodom_v2_duplicate_enrichment_summary_2026 AS
SELECT
    field_name,
    enrichment_status,
    count(*) AS candidate_rows,
    count(DISTINCT core_visit_id) AS core_visits,
    now() AS generated_at
FROM staging.v_hodom_v2_duplicate_enrichment_preview_2026
GROUP BY field_name, enrichment_status
ORDER BY field_name, enrichment_status;

COMMENT ON VIEW staging.v_hodom_v2_duplicate_enrichment_summary_2026 IS
'Aggregate V2 duplicate enrichment summary. Safe for documentation.';

CREATE TEMP TABLE _hodom_v2_duplicate_enrichment_field_apply ON COMMIT DROP AS
SELECT
    core_visit_id,
    field_name,
    new_value,
    source_route_key
FROM staging.v_hodom_v2_duplicate_enrichment_preview_2026
WHERE enrichment_status = 'UPDATE_ALLOWED'
  AND distinct_values = 1;

CREATE TEMP TABLE _hodom_v2_duplicate_enrichment_apply ON COMMIT DROP AS
SELECT
    core_visit_id,
    max(new_value) FILTER (WHERE field_name = 'hora_plan_inicio') AS hora_plan_inicio,
    max(new_value) FILTER (WHERE field_name = 'provider_id') AS provider_id,
    max(new_value) FILTER (WHERE field_name = 'prestacion_id') AS prestacion_id,
    max(new_value) FILTER (WHERE field_name = 'domicilio_id') AS domicilio_id
FROM _hodom_v2_duplicate_enrichment_field_apply
GROUP BY core_visit_id;

UPDATE operational.visita v
SET
    hora_plan_inicio = coalesce(v.hora_plan_inicio, a.hora_plan_inicio),
    provider_id = coalesce(v.provider_id, a.provider_id),
    prestacion_id = coalesce(v.prestacion_id, a.prestacion_id),
    domicilio_id = coalesce(v.domicilio_id, a.domicilio_id),
    updated_at = now()
FROM _hodom_v2_duplicate_enrichment_apply a
WHERE v.visit_id = a.core_visit_id
  AND (
      (v.hora_plan_inicio IS NULL AND a.hora_plan_inicio IS NOT NULL)
      OR (v.provider_id IS NULL AND a.provider_id IS NOT NULL)
      OR (v.prestacion_id IS NULL AND a.prestacion_id IS NOT NULL)
      OR (v.domicilio_id IS NULL AND a.domicilio_id IS NOT NULL)
  );

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'operational.visita',
    a.core_visit_id,
    'drive_import',
    'HODOM_DRIVE_2026_V2_DUPLICATE',
    a.source_route_key,
    'v2_duplicate_enrichment_2026_05_26',
    a.field_name,
    now()
FROM _hodom_v2_duplicate_enrichment_field_apply a
JOIN operational.visita v ON v.visit_id = a.core_visit_id
WHERE (
      (a.field_name = 'hora_plan_inicio' AND v.hora_plan_inicio = a.new_value)
      OR (a.field_name = 'provider_id' AND v.provider_id = a.new_value)
      OR (a.field_name = 'prestacion_id' AND v.prestacion_id = a.new_value)
      OR (a.field_name = 'domicilio_id' AND v.domicilio_id = a.new_value)
  )
  AND NOT EXISTS (
      SELECT 1
      FROM migration.provenance mp
      WHERE mp.target_table = 'operational.visita'
        AND mp.target_pk = a.core_visit_id
        AND mp.phase = 'v2_duplicate_enrichment_2026_05_26'
        AND coalesce(mp.field_name, '') = a.field_name
  );

CREATE OR REPLACE VIEW staging.v_hodom_v2_duplicate_enrichment_audit_2026 AS
SELECT
    mp.target_pk AS visit_id,
    mp.field_name,
    count(*) AS provenance_rows,
    now() AS generated_at
FROM migration.provenance mp
WHERE mp.target_table = 'operational.visita'
  AND mp.phase = 'v2_duplicate_enrichment_2026_05_26'
GROUP BY mp.target_pk, mp.field_name;

COMMENT ON VIEW staging.v_hodom_v2_duplicate_enrichment_audit_2026 IS
'Audit of operational.visita fields updated by V2 duplicate enrichment. Contains IDs only.';

COMMIT;
