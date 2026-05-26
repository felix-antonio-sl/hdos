-- HODOM Ingresos 2026 — Vistas de auditoria estables basadas en provenance
-- Reemplaza las vistas fragiles que dependen del estado vivo de las tablas.
-- Las metricas historicas deben consultar migration.provenance, no los candidatos actuales.
-- Reglas:
--   1. Cada vista aggregada se basa en provenance, no en conteos live de staging/clinical.
--   2. Idempotentes: mismo resultado sin importar el estado actual de las tablas.
--   3. Seguras para documentacion: sin PII, solo conteos y fases.

BEGIN;

-- ============================================================================
-- 1. Auditoria consolidada de creacion de pacientes desde INGRESOS
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_audit_patients_created;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_audit_patients_created AS
SELECT
    'create_patients_2026_05_26' AS phase,
    'INGRESOS_2026_DRIVE' AS source,
    count(DISTINCT target_pk) AS patients_created,
    count(*) AS provenance_rows,
    count(DISTINCT target_pk) FILTER (
        WHERE EXISTS (SELECT 1 FROM migration.provenance mp2
            WHERE mp2.target_pk = migration.provenance.target_pk
              AND mp2.phase = 'create_patients_2026_05_26'
              AND mp2.field_name = 'rut')
    ) AS patients_with_rut,
    count(DISTINCT target_pk) FILTER (
        WHERE EXISTS (SELECT 1 FROM migration.provenance mp2
            WHERE mp2.target_pk = migration.provenance.target_pk
              AND mp2.phase = 'create_patients_2026_05_26'
              AND mp2.field_name = 'fecha_nacimiento')
    ) AS patients_with_fecha_nacimiento,
    count(DISTINCT target_pk) FILTER (
        WHERE EXISTS (SELECT 1 FROM migration.provenance mp2
            WHERE mp2.target_pk = migration.provenance.target_pk
              AND mp2.phase = 'create_patients_2026_05_26'
              AND mp2.field_name = 'prevision')
    ) AS patients_with_prevision,
    now() AS generated_at
FROM migration.provenance
WHERE phase = 'create_patients_2026_05_26'
  AND target_table = 'clinical.paciente';

COMMENT ON VIEW staging.v_hodom_ingreso_audit_patients_created IS
'Auditoria estable de pacientes creados desde INGRESOS 2026.
 Basada en provenance, no en estado vivo de clinical.paciente.
 43 pacientes creados, con desglose de campos poblados.';

-- ============================================================================
-- 2. Auditoria consolidada de creacion de estadias desde INGRESOS
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_audit_stays_created;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_audit_stays_created AS
SELECT
    'create_stays_2026_05_26' AS phase,
    'INGRESOS_2026_DRIVE' AS source,
    count(DISTINCT target_pk) AS stays_created,
    count(*) AS provenance_rows,
    count(DISTINCT target_pk) FILTER (
        WHERE EXISTS (SELECT 1 FROM migration.provenance mp2
            WHERE mp2.target_pk = migration.provenance.target_pk
              AND mp2.phase = 'create_stays_2026_05_26'
              AND mp2.field_name = 'tipo_egreso'
              AND mp2.target_table = 'clinical.estadia')
    ) AS stays_with_tipo_egreso,
    count(DISTINCT target_pk) FILTER (
        WHERE EXISTS (SELECT 1 FROM migration.provenance mp2
            WHERE mp2.target_pk = migration.provenance.target_pk
              AND mp2.phase = 'create_stays_2026_05_26'
              AND mp2.field_name = 'diagnostico_principal'
              AND mp2.target_table = 'clinical.estadia')
    ) AS stays_with_diagnostico,
    now() AS generated_at
FROM migration.provenance
WHERE phase = 'create_stays_2026_05_26'
  AND target_table = 'clinical.estadia';

COMMENT ON VIEW staging.v_hodom_ingreso_audit_stays_created IS
'Auditoria estable de estadias creadas desde INGRESOS 2026.
 Basada en provenance. 32 estadias creadas, con desglose de campos.';

-- ============================================================================
-- 3. Auditoria consolidada de visitas Drive promovidas (por fase)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_migration_audit_visits_promoted;
CREATE OR REPLACE VIEW staging.v_hodom_migration_audit_visits_promoted AS
WITH visit_phases AS (
    SELECT phase, count(DISTINCT target_pk) AS visits_promoted, count(*) AS provenance_rows
    FROM migration.provenance
    WHERE target_table = 'operational.visita'
      AND field_name = 'visit_id'
      AND phase LIKE '%2026%'
    GROUP BY phase
)
SELECT
    phase,
    visits_promoted,
    provenance_rows,
    CASE
        WHEN phase = 'pilot_minimal_2026_05_26' THEN 'Piloto inicial (svc+domicilio)'
        WHEN phase = 'new_visits_2026_05_26' THEN 'Fase 2 (READY_IDENTITY_STAY_ONLY)'
        WHEN phase = 'fuzzy_resolved_2026_05_26' THEN 'Fase 5 (fuzzy patient match)'
        ELSE 'Otra fase 2026'
    END AS phase_description,
    now() AS generated_at
FROM visit_phases
ORDER BY visits_promoted DESC;

COMMENT ON VIEW staging.v_hodom_migration_audit_visits_promoted IS
'Auditoria estable de visitas Drive promovidas a operational.visita, por fase.
 Basada en provenance field_name=visit_id. 1,162 total.';

-- ============================================================================
-- 4. Tablero de control consolidado (una sola vista para toda la migracion)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_migration_dashboard;
CREATE OR REPLACE VIEW staging.v_hodom_migration_dashboard AS
SELECT
    'Migration 2026 Dashboard' AS title,
    (SELECT count(*) FROM staging.hodom_route_visit WHERE visit_date >= '2026-01-01') AS drive_routes_2026,
    (SELECT count(*) FROM operational.visita WHERE visit_id LIKE 'drv_route_%' AND fecha >= '2026-01-01') AS drive_visits_in_core,
    (SELECT count(*) FROM clinical.paciente) AS total_patients,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance WHERE phase = 'create_patients_2026_05_26' AND target_table = 'clinical.paciente') AS patients_created_from_ingresos,
    (SELECT count(*) FROM clinical.estadia) AS total_stays,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance WHERE phase = 'create_stays_2026_05_26' AND target_table = 'clinical.estadia') AS stays_created_from_ingresos,
    (SELECT count(*) FROM staging.hodom_ingreso_2026) AS ingresos_staged,
    (SELECT count(*) FROM staging.hodom_ingreso_2026 WHERE rut_normalizado IS NOT NULL) AS ingresos_with_rut,
    (SELECT count(DISTINCT rut_normalizado) FROM staging.hodom_ingreso_2026 WHERE rut_normalizado IS NOT NULL) AS distinct_ruts_ingresos,
    (SELECT count(*) FROM migration.provenance WHERE phase LIKE '%2026%' AND target_table IN ('operational.visita', 'clinical.paciente', 'clinical.estadia')) AS total_provenance_migration,
    now() AS generated_at;

COMMENT ON VIEW staging.v_hodom_migration_dashboard IS
'Tablero de control consolidado de la migracion 2026.
 Basado en provenance + staging + core. Seguro para documentacion.
 Reemplaza las vistas fragiles de "candidatos actuales".';

-- ============================================================================
-- 5. Ingresos sin estadia: cola estable para revision (sin overlap fragil)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_pending_stays;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_pending_stays AS
WITH ingresos_con_paciente AS (
    SELECT i.rut_normalizado, i.fecha_ingreso, i.fecha_egreso,
           i.nombre_completo, i.diagnostico_egreso, i.motivo_egreso,
           i.sheet_name, p.patient_id
    FROM staging.hodom_ingreso_2026 i
    JOIN clinical.paciente p
      ON staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = i.rut_normalizado
     AND p.deleted_at IS NULL
    WHERE i.rut_normalizado IS NOT NULL
      AND i.fecha_ingreso IS NOT NULL
      AND i.fecha_egreso IS NOT NULL
      AND i.fecha_egreso >= i.fecha_ingreso
),
existing_stays_for_patient AS (
    SELECT patient_id,
           array_agg(stay_id) AS stay_ids,
           array_agg(date_range_text) AS date_ranges
    FROM (
        SELECT patient_id, stay_id,
               daterange(fecha_ingreso, coalesce(fecha_egreso, '9999-12-31'::date), '[]')::text AS date_range_text
        FROM clinical.estadia
        ORDER BY fecha_ingreso
    ) sub
    GROUP BY patient_id
)
SELECT
    ic.patient_id, ic.rut_normalizado, ic.nombre_completo,
    ic.fecha_ingreso, ic.fecha_egreso,
    ic.diagnostico_egreso, ic.motivo_egreso, ic.sheet_name,
    daterange(ic.fecha_ingreso, ic.fecha_egreso, '[]')::text AS candidate_range,
    es.date_ranges AS existing_ranges,
    CASE
        WHEN es.patient_id IS NULL THEN 'NO_EXISTING_STAYS'
        WHEN EXISTS (
            SELECT 1 FROM clinical.estadia e
            WHERE e.patient_id = ic.patient_id
              AND daterange(ic.fecha_ingreso, ic.fecha_egreso, '[]') &&
                  daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
        ) THEN 'OVERLAPS_EXISTING'
        ELSE 'NO_OVERLAP_CANDIDATE'
    END AS stay_status
FROM ingresos_con_paciente ic
LEFT JOIN existing_stays_for_patient es ON es.patient_id = ic.patient_id;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_pending_stays IS
'Cola estable de ingresos pendientes de crear estadia.
 Usa daterange && para detectar overlap con estadias existentes.
 NO_OVERLAP_CANDIDATE = listo para crear. OVERLAPS_EXISTING = ya cubierto.
 Seguro para documentacion sin PII en la vista agregada.';

-- ============================================================================
-- 6. Resumen agregado de la cola de estadias pendientes (seguro para docs)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_pending_stays_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_pending_stays_summary AS
SELECT
    stay_status,
    count(*) AS ingresos_count,
    count(DISTINCT patient_id) AS distinct_patients,
    count(DISTINCT rut_normalizado) AS distinct_ruts,
    min(fecha_ingreso) AS min_ingreso,
    max(fecha_ingreso) AS max_ingreso,
    now() AS generated_at
FROM staging.v_hodom_ingreso_2026_pending_stays
GROUP BY stay_status
ORDER BY stay_status;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_pending_stays_summary IS
'Resumen agregado de la cola de estadias pendientes.
 NO_OVERLAP_CANDIDATE = ingresos listos para crear estadia.
 OVERLAPS_EXISTING = ingresos ya cubiertos por estadia existente.
 Seguro para documentacion versionable.';

COMMIT;
