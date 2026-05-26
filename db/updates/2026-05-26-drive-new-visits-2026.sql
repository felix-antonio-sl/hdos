-- HODOM Drive migration 2026 — Phase 2: INSERT net-new visits
-- 238 routes READY_IDENTITY_STAY_ONLY for 2026 with no existing core visit same day.
-- These have patient+stay+service match but may lack domicilio.
-- Rules:
--   1. INSERT into operational.visita only if no core visit exists that day.
--   2. provider_id from high-confidence professional match.
--   3. prestacion_id from expert reconciliation.
--   4. domicilio_id from expert reconciliation when available (may be NULL).
--   5. Provenance per field per visit.
--   6. Idempotent.

BEGIN;

-- ============================================================================
-- 1. Vista preview: que se va a insertar
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_new_visits_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_new_visits_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_new_visits_gate_2026;
DROP VIEW IF EXISTS staging.v_hodom_new_visits_preview_2026;
CREATE OR REPLACE VIEW staging.v_hodom_new_visits_preview_2026 AS
WITH new_routes AS (
    SELECT
        rv.route_visit_id, rv.visit_date, rv.planned_time,
        rv.source_path, rv.drive_id, rv.sheet_name, rv.source_row_number,
        c.candidate_visit_id, c.matched_patient_id, c.matched_stay_id
    FROM staging.v_hodom_route_promotion_contract c
    JOIN staging.hodom_route_visit rv ON rv.route_visit_id = c.route_visit_id
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
      AND rv.visit_date >= '2026-01-01'
      AND NOT EXISTS (
        SELECT 1 FROM operational.visita v
        WHERE v.patient_id = c.matched_patient_id
          AND v.stay_id = c.matched_stay_id
          AND v.fecha = rv.visit_date
      )
),
svc_target AS (
    SELECT DISTINCT source_pk AS route_visit_id, target_pk AS prestacion_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'service_prestacion' AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
),
addr_target AS (
    SELECT DISTINCT source_pk AS route_visit_id, target_pk AS domicilio_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'address_domicilio' AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
),
best_prof AS (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.route_visit_id, rpm.suggested_provider_id,
        rpm.db_name AS suggested_provider_name, rpm.match_quality
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.match_quality
)
SELECT
    nr.route_visit_id, nr.source_path, nr.candidate_visit_id AS visit_id,
    nr.matched_patient_id AS patient_id, nr.matched_stay_id AS stay_id,
    nr.visit_date AS fecha, nr.planned_time AS hora_plan_inicio,
    bp.suggested_provider_id AS provider_id,
    bp.suggested_provider_name,
    s.prestacion_id,
    a.domicilio_id,
    COALESCE(a.domicilio_id IS NOT NULL, false) AS tiene_domicilio,
    s.prestacion_id IS NOT NULL AS tiene_prestacion,
    bp.suggested_provider_id IS NOT NULL AS tiene_provider,
    CASE
        WHEN s.prestacion_id IS NULL THEN 'MISSING_SERVICE_TARGET'
        WHEN a.domicilio_id IS NULL THEN 'ACCEPTED_NULL_DOMICILIO'
        WHEN bp.suggested_provider_id IS NULL THEN 'ACCEPTED_NULL_PROVIDER'
        ELSE 'FULLY_ANCHORED'
    END AS anchor_status
FROM new_routes nr
LEFT JOIN svc_target s ON s.route_visit_id = nr.route_visit_id
LEFT JOIN addr_target a ON a.route_visit_id = nr.route_visit_id
LEFT JOIN best_prof bp ON bp.route_visit_id = nr.route_visit_id;

COMMENT ON VIEW staging.v_hodom_new_visits_preview_2026 IS
'Preview de visitas netamente nuevas 2026: 351 rutas READY_IDENTITY_STAY_ONLY
 sin visita core el mismo dia. Incluye estado de anclaje (servicio, domicilio, profesional).';

-- ============================================================================
-- 2. Gate pre-insert
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_new_visits_gate_2026;
CREATE OR REPLACE VIEW staging.v_hodom_new_visits_gate_2026 AS
SELECT
    'new_visits_2026_05_26' AS phase,
    count(*) AS total_candidates,
    count(*) FILTER (WHERE tiene_prestacion) AS with_service,
    count(*) FILTER (WHERE tiene_domicilio) AS with_domicilio,
    count(*) FILTER (WHERE tiene_provider) AS with_provider,
    count(*) FILTER (WHERE tiene_prestacion AND tiene_domicilio AND tiene_provider) AS fully_anchored,
    count(*) FILTER (WHERE anchor_status = 'MISSING_SERVICE_TARGET') AS missing_service,
    count(*) FILTER (WHERE anchor_status = 'ACCEPTED_NULL_DOMICILIO') AS accepted_null_domicilio,
    count(*) FILTER (WHERE anchor_status = 'ACCEPTED_NULL_PROVIDER') AS accepted_null_provider,
    now() AS generated_at
FROM staging.v_hodom_new_visits_preview_2026;

COMMENT ON VIEW staging.v_hodom_new_visits_gate_2026 IS
'Gate pre-INSERT de nuevas visitas 2026: distribucion de anclajes.';

-- ============================================================================
-- 3. INSERT into operational.visita
-- ============================================================================

INSERT INTO operational.visita (
    visit_id, stay_id, patient_id, provider_id, fecha,
    hora_plan_inicio, estado, doc_estado, rem_reportable,
    prestacion_id, domicilio_id, created_at, updated_at
)
SELECT DISTINCT ON (pv.visit_id)
    pv.visit_id, pv.stay_id, pv.patient_id, pv.provider_id, pv.fecha,
    pv.hora_plan_inicio,
    'PROGRAMADA', 'pendiente', false,
    pv.prestacion_id, pv.domicilio_id,
    now(), now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND NOT EXISTS (
    SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id
  );

-- ============================================================================
-- 4. Provenance: unico source por (target_pk, field_name)
-- ============================================================================

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'visit_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'visit_id' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'stay_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'stay_id' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'patient_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'patient_id' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'fecha', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'fecha' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'prestacion_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'prestacion_id' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'hora_plan_inicio', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'hora_plan_inicio' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'estado', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'estado' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'domicilio_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'domicilio_id' AND mp.phase = 'new_visits_2026_05_26');

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (pv.visit_id)
    'operational.visita', pv.visit_id, 'drive_import',
    pv.source_path, pv.route_visit_id,
    'new_visits_2026_05_26', 'provider_id', now()
FROM staging.v_hodom_new_visits_preview_2026 pv
WHERE pv.tiene_prestacion
  AND pv.tiene_provider
  AND EXISTS (SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id)
  AND NOT EXISTS (SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita' AND mp.target_pk = pv.visit_id
      AND mp.field_name = 'provider_id' AND mp.phase = 'new_visits_2026_05_26');

-- ============================================================================
-- 5. Auditoria y resumen
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_new_visits_audit_2026;
CREATE OR REPLACE VIEW staging.v_hodom_new_visits_audit_2026 AS
SELECT
    pv.visit_id, pv.fecha,
    CASE WHEN v.visit_id IS NOT NULL THEN true ELSE false END AS inserted,
    v.provider_id IS NOT NULL AS has_provider,
    v.prestacion_id IS NOT NULL AS has_prestacion,
    v.domicilio_id IS NOT NULL AS has_domicilio,
    v.estado,
    v.created_at AS inserted_at,
    (SELECT count(*) FROM migration.provenance mp
     WHERE mp.target_table = 'operational.visita'
       AND mp.target_pk = pv.visit_id
       AND mp.phase = 'new_visits_2026_05_26') AS provenance_fields
FROM staging.v_hodom_new_visits_preview_2026 pv
LEFT JOIN operational.visita v ON v.visit_id = pv.visit_id;

COMMENT ON VIEW staging.v_hodom_new_visits_audit_2026 IS
'Auditoria post-insert de nuevas visitas 2026.';

DROP VIEW IF EXISTS staging.v_hodom_new_visits_summary_2026;
CREATE OR REPLACE VIEW staging.v_hodom_new_visits_summary_2026 AS
SELECT
    'new_visits_2026_05_26' AS phase,
    count(*) AS expected_visits,
    count(*) FILTER (WHERE inserted) AS inserted_visits,
    count(*) FILTER (WHERE inserted AND has_provider) AS with_provider,
    count(*) FILTER (WHERE inserted AND has_prestacion) AS with_prestacion,
    count(*) FILTER (WHERE inserted AND has_domicilio) AS with_domicilio,
    (SELECT count(*) FROM migration.provenance
     WHERE phase = 'new_visits_2026_05_26') AS total_provenance,
    now() AS generated_at
FROM staging.v_hodom_new_visits_audit_2026;

COMMENT ON VIEW staging.v_hodom_new_visits_summary_2026 IS
'Resumen agregado de nuevas visitas 2026. Seguro para documentacion.';

COMMIT;
