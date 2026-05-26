-- HODOM Drive enrichment 2026: UPDATE visitas core existentes con datos operacionales del Drive
-- Fase 1 de la migracion 2026: enriquecer, no insertar.
-- Reglas:
--   1. Solo actualiza campos NULL en core que tienen dato en Drive.
--   2. provider_id: solo high_confidence_unique del match profesional.
--   3. hora_plan_inicio: desde Drive planned_time si core no lo tiene.
--   4. prestacion_id: desde reconciliacion experta si core no lo tiene.
--   5. domicilio_id: desde reconciliacion experta si core no lo tiene.
--   6. Provenance por cada campo enriquecido.
--   7. Idempotente: no pisa datos ya poblados.

BEGIN;

-- ============================================================================
-- 1. Vista de candidatos: cada pareja (ruta Drive, visita core) con brechas
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_enrichment_candidate_2026;
CREATE OR REPLACE VIEW staging.v_hodom_enrichment_candidate_2026 AS
WITH dup_routes AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        rv.planned_time,
        rv.service_text,
        rv.address_text,
        rv.source_path,
        rv.drive_id,
        rv.sheet_name,
        rv.source_row_number,
        c.matched_patient_id,
        c.matched_stay_id
    FROM staging.v_hodom_route_promotion_contract c
    JOIN staging.hodom_route_visit rv ON rv.route_visit_id = c.route_visit_id
    WHERE c.promotion_gate = 'REVIEW_DUPLICATE_PUSHOUT_REQUIRED'
      AND rv.visit_date >= '2026-01-01'
),
core_visit AS (
    SELECT DISTINCT ON (dr.route_visit_id, v.visit_id)
        dr.route_visit_id,
        v.visit_id AS core_visit_id,
        v.provider_id AS core_provider_id,
        v.prestacion_id AS core_prestacion_id,
        v.domicilio_id AS core_domicilio_id,
        v.hora_plan_inicio AS core_hora_plan_inicio,
        v.hora_plan_fin AS core_hora_plan_fin,
        v.estado AS core_estado,
        v.rem_reportable
    FROM dup_routes dr
    JOIN operational.visita v
      ON v.patient_id = dr.matched_patient_id
     AND v.stay_id = dr.matched_stay_id
     AND v.fecha = dr.visit_date
),
svc_target AS (
    SELECT DISTINCT
        source_pk AS route_visit_id,
        target_pk AS prestacion_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'service_prestacion'
      AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
),
addr_target AS (
    SELECT DISTINCT
        source_pk AS route_visit_id,
        target_pk AS domicilio_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'address_domicilio'
      AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
),
best_prof_match AS (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.route_visit_id,
        rpm.suggested_provider_id,
        rpm.db_name AS suggested_provider_name,
        rpm.match_quality
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.match_quality
)
SELECT
    dr.route_visit_id,
    dr.source_path,
    dr.visit_date,
    dr.planned_time,
    dr.service_text,
    dr.address_text,
    cv.core_visit_id,
    cv.core_provider_id,
    cv.core_prestacion_id,
    cv.core_domicilio_id,
    cv.core_hora_plan_inicio,
    cv.core_estado,
    bpm.suggested_provider_id,
    bpm.suggested_provider_name,
    bpm.match_quality AS prof_match_quality,
    s.prestacion_id AS suggested_prestacion_id,
    a.domicilio_id AS suggested_domicilio_id,
    (cv.core_provider_id IS NULL AND bpm.suggested_provider_id IS NOT NULL) AS enriquece_provider,
    (cv.core_hora_plan_inicio IS NULL AND dr.planned_time IS NOT NULL
     AND btrim(dr.planned_time) <> '') AS enriquece_hora,
    (cv.core_prestacion_id IS NULL AND s.prestacion_id IS NOT NULL) AS enriquece_prestacion,
    (cv.core_domicilio_id IS NULL AND a.domicilio_id IS NOT NULL) AS enriquece_domicilio,
    ((cv.core_provider_id IS NULL AND bpm.suggested_provider_id IS NOT NULL)
     OR (cv.core_hora_plan_inicio IS NULL AND dr.planned_time IS NOT NULL
         AND btrim(dr.planned_time) <> '')
     OR (cv.core_prestacion_id IS NULL AND s.prestacion_id IS NOT NULL)
     OR (cv.core_domicilio_id IS NULL AND a.domicilio_id IS NOT NULL)) AS any_enrichment
FROM dup_routes dr
JOIN core_visit cv ON cv.route_visit_id = dr.route_visit_id
LEFT JOIN best_prof_match bpm ON bpm.route_visit_id = dr.route_visit_id
LEFT JOIN svc_target s ON s.route_visit_id = dr.route_visit_id
LEFT JOIN addr_target a ON a.route_visit_id = dr.route_visit_id;

COMMENT ON VIEW staging.v_hodom_enrichment_candidate_2026 IS
'Parejas (ruta Drive, visita core) con brechas detectadas y sugerencias de enriquecimiento.
 enriquece_provider/hora/prestacion/domicilio indica si el campo es NULL en core y hay dato Drive.
 Solo rutas 2026 con promotion_gate = REVIEW_DUPLICATE_PUSHOUT_REQUIRED.';

-- ============================================================================
-- 2. Gate de verificacion pre-enriquecimiento
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_enrichment_gate_2026;
CREATE OR REPLACE VIEW staging.v_hodom_enrichment_gate_2026 AS
SELECT
    'enrichment_2026_05_26' AS phase,
    count(DISTINCT core_visit_id) AS visitas_candidatas,
    count(DISTINCT route_visit_id) AS rutas_drive_total,
    count(*) FILTER (WHERE enriquece_provider) AS brechas_provider,
    count(*) FILTER (WHERE enriquece_hora) AS brechas_hora,
    count(*) FILTER (WHERE enriquece_prestacion) AS brechas_prestacion,
    count(*) FILTER (WHERE enriquece_domicilio) AS brechas_domicilio,
    count(*) FILTER (WHERE any_enrichment) AS rutas_con_alguna_brecha,
    count(*) FILTER (WHERE NOT any_enrichment) AS rutas_sin_brecha,
    (SELECT count(*) FROM staging.v_hodom_enrichment_candidate_2026
     WHERE any_enrichment AND core_visit_id LIKE 'drv_route_%') AS incluye_visitas_piloto,
    now() AS generated_at
FROM staging.v_hodom_enrichment_candidate_2026;

COMMENT ON VIEW staging.v_hodom_enrichment_gate_2026 IS
'Gate pre-enriquecimiento: conteo de brechas detectadas antes de ejecutar UPDATEs.
 Revisar antes de ejecutar la seccion 3 (UPDATE).';

-- ============================================================================
-- 3. UPDATE provider_id: enriquecer visitas core con match profesional confiable
-- ============================================================================

WITH updates AS (
    SELECT
        core_visit_id,
        suggested_provider_id,
        route_visit_id,
        source_path
    FROM staging.v_hodom_enrichment_candidate_2026
    WHERE enriquece_provider
      AND core_visit_id NOT LIKE 'drv_route_%'  -- no tocar visitas del piloto
      AND suggested_provider_id IS NOT NULL
)
UPDATE operational.visita v
SET
    provider_id = u.suggested_provider_id,
    updated_at = now()
FROM updates u
WHERE v.visit_id = u.core_visit_id
  AND v.provider_id IS NULL;

-- ============================================================================
-- 4. Provenance para provider_id enriquecido
-- ============================================================================

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'operational.visita',
    u.core_visit_id,
    'drive_import',
    u.source_path,
    u.route_visit_id,
    'enrichment_2026_05_26',
    'provider_id',
    now()
FROM staging.v_hodom_enrichment_candidate_2026 u
WHERE u.enriquece_provider
  AND u.core_visit_id NOT LIKE 'drv_route_%'
  AND EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = u.core_visit_id
      AND v.provider_id = u.suggested_provider_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita'
      AND mp.target_pk = u.core_visit_id
      AND mp.field_name = 'provider_id'
      AND mp.phase = 'enrichment_2026_05_26'
  );

-- ============================================================================
-- 5. UPDATE hora_plan_inicio: desde Drive planned_time
-- ============================================================================

WITH updates AS (
    SELECT
        core_visit_id,
        planned_time,
        route_visit_id,
        source_path
    FROM staging.v_hodom_enrichment_candidate_2026
    WHERE enriquece_hora
      AND core_visit_id NOT LIKE 'drv_route_%'
      AND planned_time IS NOT NULL
      AND btrim(planned_time) <> ''
)
UPDATE operational.visita v
SET
    hora_plan_inicio = u.planned_time,
    updated_at = now()
FROM updates u
WHERE v.visit_id = u.core_visit_id
  AND v.hora_plan_inicio IS NULL;

-- Provenance para hora
INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'operational.visita',
    u.core_visit_id,
    'drive_import',
    u.source_path,
    u.route_visit_id,
    'enrichment_2026_05_26',
    'hora_plan_inicio',
    now()
FROM staging.v_hodom_enrichment_candidate_2026 u
WHERE u.enriquece_hora
  AND u.core_visit_id NOT LIKE 'drv_route_%'
  AND EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = u.core_visit_id
      AND v.hora_plan_inicio IS NOT NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita'
      AND mp.target_pk = u.core_visit_id
      AND mp.field_name = 'hora_plan_inicio'
      AND mp.phase = 'enrichment_2026_05_26'
  );

-- ============================================================================
-- 6. UPDATE prestacion_id: desde reconciliacion experta (solo si core no lo tiene)
-- ============================================================================

WITH updates AS (
    SELECT
        core_visit_id,
        suggested_prestacion_id,
        route_visit_id,
        source_path
    FROM staging.v_hodom_enrichment_candidate_2026
    WHERE enriquece_prestacion
      AND core_visit_id NOT LIKE 'drv_route_%'
      AND suggested_prestacion_id IS NOT NULL
)
UPDATE operational.visita v
SET
    prestacion_id = u.suggested_prestacion_id,
    updated_at = now()
FROM updates u
WHERE v.visit_id = u.core_visit_id
  AND v.prestacion_id IS NULL;

-- Provenance para prestacion
INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'operational.visita',
    u.core_visit_id,
    'drive_import',
    u.source_path,
    u.route_visit_id,
    'enrichment_2026_05_26',
    'prestacion_id',
    now()
FROM staging.v_hodom_enrichment_candidate_2026 u
WHERE u.enriquece_prestacion
  AND u.core_visit_id NOT LIKE 'drv_route_%'
  AND EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = u.core_visit_id
      AND v.prestacion_id IS NOT NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita'
      AND mp.target_pk = u.core_visit_id
      AND mp.field_name = 'prestacion_id'
      AND mp.phase = 'enrichment_2026_05_26'
  );

-- ============================================================================
-- 7. UPDATE domicilio_id: desde reconciliacion experta
-- ============================================================================

WITH updates AS (
    SELECT
        core_visit_id,
        suggested_domicilio_id,
        route_visit_id,
        source_path
    FROM staging.v_hodom_enrichment_candidate_2026
    WHERE enriquece_domicilio
      AND core_visit_id NOT LIKE 'drv_route_%'
      AND suggested_domicilio_id IS NOT NULL
)
UPDATE operational.visita v
SET
    domicilio_id = u.suggested_domicilio_id,
    updated_at = now()
FROM updates u
WHERE v.visit_id = u.core_visit_id
  AND v.domicilio_id IS NULL;

-- Provenance para domicilio
INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'operational.visita',
    u.core_visit_id,
    'drive_import',
    u.source_path,
    u.route_visit_id,
    'enrichment_2026_05_26',
    'domicilio_id',
    now()
FROM staging.v_hodom_enrichment_candidate_2026 u
WHERE u.enriquece_domicilio
  AND u.core_visit_id NOT LIKE 'drv_route_%'
  AND EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = u.core_visit_id
      AND v.domicilio_id IS NOT NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita'
      AND mp.target_pk = u.core_visit_id
      AND mp.field_name = 'domicilio_id'
      AND mp.phase = 'enrichment_2026_05_26'
  );

-- ============================================================================
-- 8. Vista de auditoria post-enriquecimiento
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_enrichment_audit_2026;
CREATE OR REPLACE VIEW staging.v_hodom_enrichment_audit_2026 AS
SELECT
    ec.core_visit_id,
    ec.visit_date,
    ec.core_estado AS estado_pre,
    v.estado AS estado_post,
    v.provider_id IS NOT NULL AS tiene_provider_ahora,
    v.hora_plan_inicio IS NOT NULL AS tiene_hora_ahora,
    v.prestacion_id IS NOT NULL AS tiene_prestacion_ahora,
    v.domicilio_id IS NOT NULL AS tiene_domicilio_ahora,
    (v.provider_id IS NOT NULL AND v.hora_plan_inicio IS NOT NULL
     AND v.prestacion_id IS NOT NULL AND v.domicilio_id IS NOT NULL) AS visita_completa,
    (SELECT count(*)
     FROM migration.provenance mp
     WHERE mp.target_table = 'operational.visita'
       AND mp.target_pk = ec.core_visit_id
       AND mp.phase = 'enrichment_2026_05_26'
    ) AS campos_enriquecidos
FROM staging.v_hodom_enrichment_candidate_2026 ec
JOIN operational.visita v ON v.visit_id = ec.core_visit_id
WHERE ec.any_enrichment
  AND ec.core_visit_id NOT LIKE 'drv_route_%';

COMMENT ON VIEW staging.v_hodom_enrichment_audit_2026 IS
'Auditoria post-enriquecimiento: para cada visita core enriquecida,
 muestra campos poblados y conteo de provenance.';

-- ============================================================================
-- 9. Resumen agregado (seguro para documentacion)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_enrichment_summary_2026;
CREATE OR REPLACE VIEW staging.v_hodom_enrichment_summary_2026 AS
SELECT
    'enrichment_2026_05_26' AS phase,
    count(DISTINCT core_visit_id) AS visitas_enriquecidas,
    count(*) FILTER (WHERE tiene_provider_ahora) AS con_provider,
    count(*) FILTER (WHERE tiene_hora_ahora) AS con_hora,
    count(*) FILTER (WHERE tiene_prestacion_ahora) AS con_prestacion,
    count(*) FILTER (WHERE tiene_domicilio_ahora) AS con_domicilio,
    count(*) FILTER (WHERE visita_completa) AS visitas_completas,
    (SELECT count(*) FROM migration.provenance mp
     WHERE mp.phase = 'enrichment_2026_05_26') AS total_provenance_rows,
    now() AS generated_at
FROM staging.v_hodom_enrichment_audit_2026;

COMMENT ON VIEW staging.v_hodom_enrichment_summary_2026 IS
'Resumen agregado del enriquecimiento 2026. Seguro para documentacion versionable.';

COMMIT;
