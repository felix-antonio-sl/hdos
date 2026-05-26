-- HODOM Drive migration 2026 — fuzzy review queues and safe enrichment.
-- Rules:
--   1. No INSERT into operational.visita.
--   2. No changes to clinical schema.
--   3. Enrich only NULL fields on a unique existing core visit.
--   4. Do not apply a field when multiple Drive rows suggest conflicting values.
--   5. Batch duplicates, split services and missing services remain review queues.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_existing_enrichment_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_existing_enrichment_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_existing_enrichment_preview_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_unpromoted_net_new_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_unpromoted_net_new_review_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_batch_duplicate_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_batch_duplicate_review_2026;

-- ============================================================================
-- 1. Batch duplicate review queue
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_batch_duplicate_review_2026 AS
WITH batch_rows AS (
    SELECT
        pv.route_visit_id,
        pv.visit_id,
        pv.patient_id,
        pv.stay_id,
        pv.fecha,
        pv.provider_id,
        pv.prestacion_id,
        pv.domicilio_id,
        pv.batch_day_route_count,
        EXISTS (
            SELECT 1
            FROM migration.provenance mp
            WHERE mp.target_table = 'operational.visita'
              AND mp.target_pk = pv.visit_id
              AND mp.phase = 'fuzzy_resolved_2026_05_26'
        ) AS already_promoted_by_fuzzy
    FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
    WHERE pv.fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE'
),
grouped AS (
    SELECT
        patient_id,
        stay_id,
        fecha,
        count(*) AS route_rows,
        count(*) FILTER (WHERE already_promoted_by_fuzzy) AS promoted_rows,
        count(*) FILTER (WHERE NOT already_promoted_by_fuzzy) AS not_promoted_rows,
        count(DISTINCT prestacion_id) FILTER (WHERE prestacion_id IS NOT NULL)
            AS distinct_services,
        count(*) FILTER (WHERE provider_id IS NOT NULL) AS rows_with_provider,
        count(*) FILTER (WHERE domicilio_id IS NOT NULL) AS rows_with_domicilio
    FROM batch_rows
    GROUP BY patient_id, stay_id, fecha
)
SELECT
    'fuzzy_batch_' || substr(md5(
        br.patient_id || '|' || br.stay_id || '|' || br.fecha::text
    ), 1, 16) AS batch_group_id,
    br.route_visit_id,
    br.visit_id,
    br.patient_id,
    br.stay_id,
    br.fecha,
    br.provider_id,
    br.prestacion_id,
    br.domicilio_id,
    br.already_promoted_by_fuzzy,
    g.route_rows,
    g.promoted_rows,
    g.not_promoted_rows,
    g.distinct_services,
    g.rows_with_provider,
    g.rows_with_domicilio,
    CASE
        WHEN g.promoted_rows = g.route_rows
            THEN 'REVIEW_ALREADY_PROMOTED_BATCH'
        WHEN g.promoted_rows > 0
            THEN 'REVIEW_PARTIAL_BATCH_PROMOTION'
        ELSE 'DO_NOT_INSERT_BEFORE_HUMAN_BATCH_REVIEW'
    END AS simulated_review_recommendation
FROM batch_rows br
JOIN grouped g
  ON g.patient_id = br.patient_id
 AND g.stay_id = br.stay_id
 AND g.fecha = br.fecha;

COMMENT ON VIEW staging.v_hodom_fuzzy_batch_duplicate_review_2026 IS
'Review queue for fuzzy-resolved same-patient/same-stay/same-day batches. Simulated recommendation is not human approval.';

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_batch_duplicate_summary_2026 AS
SELECT
    simulated_review_recommendation,
    count(DISTINCT batch_group_id) AS batch_groups,
    count(*) AS route_rows,
    count(*) FILTER (WHERE already_promoted_by_fuzzy) AS promoted_rows,
    count(*) FILTER (WHERE NOT already_promoted_by_fuzzy) AS not_promoted_rows,
    count(*) FILTER (WHERE provider_id IS NOT NULL) AS rows_with_provider,
    count(*) FILTER (WHERE domicilio_id IS NOT NULL) AS rows_with_domicilio
FROM staging.v_hodom_fuzzy_batch_duplicate_review_2026
GROUP BY simulated_review_recommendation
ORDER BY simulated_review_recommendation;

COMMENT ON VIEW staging.v_hodom_fuzzy_batch_duplicate_summary_2026 IS
'Aggregate batch duplicate review summary. Safe for documentation.';

-- ============================================================================
-- 2. Net-new fuzzy rows not promoted
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_unpromoted_net_new_review_2026 AS
SELECT
    pv.route_visit_id,
    pv.visit_id,
    pv.patient_id,
    pv.stay_id,
    pv.fecha,
    pv.fuzzy_migration_action,
    pv.batch_day_route_count,
    pv.service_component_count,
    pv.mapped_service_component_count,
    pv.service_target_count,
    pv.provider_id IS NOT NULL AS has_provider,
    pv.domicilio_id IS NOT NULL AS has_domicilio,
    CASE
        WHEN pv.fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE'
            THEN 'DO_NOT_INSERT_BEFORE_HUMAN_BATCH_REVIEW'
        WHEN pv.fuzzy_migration_action = 'FUZZY_SPLIT_SERVICE_REQUIRED'
            THEN 'REQUIRES_SPLIT_VISIT_MODEL'
        WHEN pv.fuzzy_migration_action = 'FUZZY_SERVICE_TARGET_MISSING'
            THEN 'REQUIRES_SERVICE_DICTIONARY'
        ELSE 'REVIEW_REQUIRED'
    END AS simulated_review_recommendation
FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
WHERE pv.fuzzy_migration_action IN (
        'FUZZY_REVIEW_BATCH_DUPLICATE',
        'FUZZY_SPLIT_SERVICE_REQUIRED',
        'FUZZY_SERVICE_TARGET_MISSING'
    )
  AND NOT EXISTS (
      SELECT 1
      FROM migration.provenance mp
      WHERE mp.target_table = 'operational.visita'
        AND mp.target_pk = pv.visit_id
        AND mp.phase = 'fuzzy_resolved_2026_05_26'
  );

COMMENT ON VIEW staging.v_hodom_fuzzy_unpromoted_net_new_review_2026 IS
'Net-new fuzzy-resolved rows that remain unpromoted. Recommendations are review routing only.';

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_unpromoted_net_new_summary_2026 AS
SELECT
    fuzzy_migration_action,
    simulated_review_recommendation,
    count(*) AS route_rows,
    count(*) FILTER (WHERE has_provider) AS rows_with_provider,
    count(*) FILTER (WHERE has_domicilio) AS rows_with_domicilio,
    sum(service_component_count) AS service_components,
    sum(mapped_service_component_count) AS mapped_service_components,
    sum(service_target_count) AS service_targets
FROM staging.v_hodom_fuzzy_unpromoted_net_new_review_2026
GROUP BY fuzzy_migration_action, simulated_review_recommendation
ORDER BY fuzzy_migration_action, simulated_review_recommendation;

COMMENT ON VIEW staging.v_hodom_fuzzy_unpromoted_net_new_summary_2026 IS
'Aggregate unresolved fuzzy net-new queue. Safe for documentation.';

-- ============================================================================
-- 3. Existing core visit enrichment preview
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_existing_enrichment_preview_2026 AS
WITH core_matches AS (
    SELECT
        pv.route_visit_id,
        pv.source_path,
        pv.patient_id,
        pv.stay_id,
        pv.fecha,
        pv.provider_id,
        pv.hora_plan_inicio,
        pv.prestacion_id,
        pv.domicilio_id,
        v.visit_id AS core_visit_id,
        v.provider_id AS core_provider_id,
        v.hora_plan_inicio AS core_hora_plan_inicio,
        v.prestacion_id AS core_prestacion_id,
        v.domicilio_id AS core_domicilio_id,
        count(*) OVER (PARTITION BY pv.route_visit_id) AS core_visit_count
    FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
    JOIN operational.visita v
      ON v.patient_id = pv.patient_id
     AND v.stay_id = pv.stay_id
     AND v.fecha = pv.fecha
     AND v.visit_id <> pv.visit_id
    WHERE pv.fuzzy_migration_action = 'FUZZY_ENRICH_EXISTING'
),
field_rows AS (
    SELECT
        route_visit_id,
        source_path,
        core_visit_id,
        core_visit_count,
        'provider_id' AS field_name,
        provider_id AS candidate_value,
        core_provider_id AS current_value
    FROM core_matches
    WHERE provider_id IS NOT NULL
    UNION ALL
    SELECT
        route_visit_id,
        source_path,
        core_visit_id,
        core_visit_count,
        'hora_plan_inicio' AS field_name,
        hora_plan_inicio AS candidate_value,
        core_hora_plan_inicio AS current_value
    FROM core_matches
    WHERE hora_plan_inicio IS NOT NULL
      AND btrim(hora_plan_inicio) <> ''
    UNION ALL
    SELECT
        route_visit_id,
        source_path,
        core_visit_id,
        core_visit_count,
        'prestacion_id' AS field_name,
        prestacion_id AS candidate_value,
        core_prestacion_id AS current_value
    FROM core_matches
    WHERE prestacion_id IS NOT NULL
    UNION ALL
    SELECT
        route_visit_id,
        source_path,
        core_visit_id,
        core_visit_count,
        'domicilio_id' AS field_name,
        domicilio_id AS candidate_value,
        core_domicilio_id AS current_value
    FROM core_matches
    WHERE domicilio_id IS NOT NULL
),
field_stats AS (
    SELECT
        core_visit_id,
        field_name,
        count(DISTINCT candidate_value) AS distinct_values
    FROM field_rows
    WHERE current_value IS NULL
    GROUP BY core_visit_id, field_name
)
SELECT
    fr.route_visit_id,
    fr.source_path,
    fr.core_visit_id,
    fr.core_visit_count,
    fr.field_name,
    fr.candidate_value,
    fr.current_value,
    coalesce(fs.distinct_values, 0) AS distinct_values,
    CASE
        WHEN fr.core_visit_count > 1
            THEN 'FUZZY_ENRICH_AMBIGUOUS_CORE_VISIT'
        WHEN fr.current_value IS NOT NULL
            THEN 'FUZZY_ENRICH_ALREADY_POPULATED'
        WHEN coalesce(fs.distinct_values, 0) > 1
            THEN 'FUZZY_ENRICH_CONFLICTING_FIELD_VALUE'
        WHEN coalesce(fs.distinct_values, 0) = 1
            THEN 'FUZZY_ENRICH_SAFE_UNIQUE_CORE'
        ELSE 'FUZZY_ENRICH_NO_SOURCE_VALUE'
    END AS enrichment_action
FROM field_rows fr
LEFT JOIN field_stats fs
  ON fs.core_visit_id = fr.core_visit_id
 AND fs.field_name = fr.field_name;

COMMENT ON VIEW staging.v_hodom_fuzzy_existing_enrichment_preview_2026 IS
'Field-level fuzzy enrichment preview. Only FUZZY_ENRICH_SAFE_UNIQUE_CORE can update NULL fields.';

CREATE TEMP TABLE _hodom_fuzzy_enrichment_apply ON COMMIT DROP AS
SELECT
    core_visit_id,
    field_name,
    min(route_visit_id) AS route_visit_id,
    min(source_path) AS source_path,
    min(candidate_value) AS candidate_value,
    count(DISTINCT candidate_value) AS distinct_values
FROM staging.v_hodom_fuzzy_existing_enrichment_preview_2026
WHERE enrichment_action = 'FUZZY_ENRICH_SAFE_UNIQUE_CORE'
  AND core_visit_count = 1
  AND distinct_values = 1
GROUP BY core_visit_id, field_name;

UPDATE operational.visita v
SET
    provider_id = a.candidate_value,
    updated_at = now()
FROM _hodom_fuzzy_enrichment_apply a
WHERE a.field_name = 'provider_id'
  AND v.visit_id = a.core_visit_id
  AND v.provider_id IS NULL;

UPDATE operational.visita v
SET
    hora_plan_inicio = a.candidate_value,
    updated_at = now()
FROM _hodom_fuzzy_enrichment_apply a
WHERE a.field_name = 'hora_plan_inicio'
  AND v.visit_id = a.core_visit_id
  AND v.hora_plan_inicio IS NULL;

UPDATE operational.visita v
SET
    prestacion_id = a.candidate_value,
    updated_at = now()
FROM _hodom_fuzzy_enrichment_apply a
WHERE a.field_name = 'prestacion_id'
  AND v.visit_id = a.core_visit_id
  AND v.prestacion_id IS NULL;

UPDATE operational.visita v
SET
    domicilio_id = a.candidate_value,
    updated_at = now()
FROM _hodom_fuzzy_enrichment_apply a
WHERE a.field_name = 'domicilio_id'
  AND v.visit_id = a.core_visit_id
  AND v.domicilio_id IS NULL;

INSERT INTO migration.provenance (
    target_table,
    target_pk,
    source_type,
    source_file,
    source_key,
    phase,
    field_name,
    created_at
)
SELECT
    'operational.visita',
    a.core_visit_id,
    'drive_import',
    a.source_path,
    a.route_visit_id,
    'fuzzy_enrichment_2026_05_26',
    a.field_name,
    now()
FROM _hodom_fuzzy_enrichment_apply a
JOIN operational.visita v ON v.visit_id = a.core_visit_id
WHERE CASE a.field_name
        WHEN 'provider_id' THEN v.provider_id
        WHEN 'hora_plan_inicio' THEN v.hora_plan_inicio
        WHEN 'prestacion_id' THEN v.prestacion_id
        WHEN 'domicilio_id' THEN v.domicilio_id
      END = a.candidate_value
  AND NOT EXISTS (
      SELECT 1
      FROM migration.provenance mp
      WHERE mp.target_table = 'operational.visita'
        AND mp.target_pk = a.core_visit_id
        AND mp.phase = 'fuzzy_enrichment_2026_05_26'
        AND coalesce(mp.field_name, '') = a.field_name
  );

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_existing_enrichment_audit_2026 AS
SELECT
    mp.target_pk AS core_visit_id,
    mp.field_name,
    count(*) AS provenance_rows,
    min(mp.source_key) AS sample_route_visit_id,
    min(mp.created_at) AS first_recorded_at,
    max(mp.created_at) AS last_recorded_at
FROM migration.provenance mp
WHERE mp.target_table = 'operational.visita'
  AND mp.phase = 'fuzzy_enrichment_2026_05_26'
GROUP BY mp.target_pk, mp.field_name;

COMMENT ON VIEW staging.v_hodom_fuzzy_existing_enrichment_audit_2026 IS
'Audit of field-level updates applied by fuzzy_enrichment_2026_05_26.';

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_existing_enrichment_summary_2026 AS
WITH route_core_counts AS (
    SELECT
        pv.route_visit_id,
        count(DISTINCT v.visit_id) AS core_visit_count
    FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
    JOIN operational.visita v
      ON v.patient_id = pv.patient_id
     AND v.stay_id = pv.stay_id
     AND v.fecha = pv.fecha
     AND v.visit_id <> pv.visit_id
    WHERE pv.fuzzy_migration_action = 'FUZZY_ENRICH_EXISTING'
    GROUP BY pv.route_visit_id
),
action_counts AS (
    SELECT
        enrichment_action,
        field_name,
        count(*) AS field_rows,
        count(DISTINCT core_visit_id) AS core_visits
    FROM staging.v_hodom_fuzzy_existing_enrichment_preview_2026
    GROUP BY enrichment_action, field_name
)
SELECT
    'fuzzy_enrichment_2026_05_26' AS phase,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_resolved_route_preview_2026
     WHERE fuzzy_migration_action = 'FUZZY_ENRICH_EXISTING')
        AS fuzzy_enrich_routes,
    (SELECT count(*) FROM route_core_counts WHERE core_visit_count = 1)
        AS unique_core_routes,
    (SELECT count(*) FROM route_core_counts WHERE core_visit_count > 1)
        AS ambiguous_core_routes,
    (SELECT coalesce(sum(field_rows), 0) FROM action_counts
     WHERE enrichment_action = 'FUZZY_ENRICH_SAFE_UNIQUE_CORE')
        AS remaining_safe_field_rows,
    (SELECT coalesce(sum(field_rows), 0) FROM action_counts
     WHERE enrichment_action = 'FUZZY_ENRICH_CONFLICTING_FIELD_VALUE')
        AS conflicting_field_rows,
    (SELECT count(DISTINCT core_visit_id)
     FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026)
        AS enriched_core_visits,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026)
        AS enriched_field_rows,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026
     WHERE field_name = 'provider_id')
        AS enriched_provider_rows,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026
     WHERE field_name = 'hora_plan_inicio')
        AS enriched_hora_rows,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026
     WHERE field_name = 'prestacion_id')
        AS enriched_prestacion_rows,
    (SELECT count(*) FROM staging.v_hodom_fuzzy_existing_enrichment_audit_2026
     WHERE field_name = 'domicilio_id')
        AS enriched_domicilio_rows,
    now() AS generated_at;

COMMENT ON VIEW staging.v_hodom_fuzzy_existing_enrichment_summary_2026 IS
'Aggregate fuzzy enrichment summary. Safe for documentation.';

COMMIT;
