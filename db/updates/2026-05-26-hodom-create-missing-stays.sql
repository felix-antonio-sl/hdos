-- HODOM INGRESOS 2026 — Create missing estadias from Drive data
-- 44 ingresos with patient (by RUT) but no overlapping estadia in clinical.estadia.
-- Reglas:
--   1. stay_id deterministic from patient_id + fecha_ingreso.
--   2. estado = 'egresado' (historical admissions).
--   3. tipo_egreso mapped from motivo_egreso Drive.
--   4. diagnostico_principal from Drive.
--   5. Provenance per estadia created.
--   6. No inserta si ya hay una estadia que solapa.

BEGIN;

-- ============================================================================
-- 1. Vista de candidatos
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_stays;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_stays AS
WITH ingresos_validos AS (
    SELECT DISTINCT ON (i.rut_normalizado, i.fecha_ingreso)
        i.rut_normalizado, i.fecha_ingreso, i.fecha_egreso,
        i.nombre_completo, i.diagnostico_egreso, i.motivo_egreso,
        i.servicio_origen, i.categorizacion,
        i.sheet_name, i.source_row_number,
        p.patient_id
    FROM staging.hodom_ingreso_2026 i
    JOIN clinical.paciente p
      ON staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = i.rut_normalizado
     AND p.deleted_at IS NULL
    WHERE i.rut_normalizado IS NOT NULL
      AND i.fecha_ingreso IS NOT NULL
      AND i.fecha_egreso IS NOT NULL
      AND i.fecha_egreso >= i.fecha_ingreso
    ORDER BY i.rut_normalizado, i.fecha_ingreso, i.fecha_egreso DESC
),
-- Dedup: for same patient, keep ONLY earliest fecha_ingreso to avoid overlapping stays
deduped AS (
    SELECT DISTINCT ON (patient_id)
        rut_normalizado, fecha_ingreso, fecha_egreso,
        nombre_completo, diagnostico_egreso, motivo_egreso,
        servicio_origen, categorizacion,
        sheet_name, source_row_number, patient_id
    FROM ingresos_validos
    ORDER BY patient_id, fecha_ingreso ASC
),
sin_estadia AS (
    SELECT dv.*
    FROM deduped dv
    WHERE NOT EXISTS (
        SELECT 1 FROM clinical.estadia e
        WHERE e.patient_id = dv.patient_id
          AND dv.fecha_ingreso <= coalesce(e.fecha_egreso, dv.fecha_ingreso)
          AND dv.fecha_egreso >= e.fecha_ingreso
    )
)
SELECT
    'stay_' || substr(md5(se.patient_id || '|' || se.fecha_ingreso::text), 1, 16) AS stay_id,
    se.patient_id,
    se.fecha_ingreso,
    se.fecha_egreso,
    se.diagnostico_egreso AS diagnostico_principal,
    CASE
        WHEN lower(trim(se.motivo_egreso)) = 'alta' THEN 'alta_clinica'::text
        WHEN lower(trim(se.motivo_egreso)) = 'rehospitalizacion' THEN 'reingreso'::text
        WHEN lower(trim(se.motivo_egreso)) IN ('fallecido', 'fallecida') THEN 'fallecido_esperado'::text
        ELSE NULL
    END AS tipo_egreso,
    CASE
        WHEN lower(trim(se.servicio_origen)) IN ('urgencia', 'ue', 'uti')
            THEN 'urgencia'::text
        WHEN lower(trim(se.servicio_origen)) = 'aps'
            THEN 'APS'::text
        ELSE NULL
    END AS origen_derivacion,
    se.sheet_name,
    se.source_row_number,
    se.nombre_completo,
    se.rut_normalizado
FROM sin_estadia se;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_stays IS
'Candidatos a crear estadia en clinical.estadia desde INGRESOS 2026 DRIVE.
 Solo ingresos con paciente (RUT) que no tienen estadia solapada. ~44 candidatos.';

-- ============================================================================
-- 2. INSERT en clinical.estadia
-- ============================================================================

INSERT INTO clinical.estadia (
    stay_id, patient_id, establecimiento_id,
    fecha_ingreso, fecha_egreso,
    estado, tipo_egreso, origen_derivacion,
    diagnostico_principal,
    created_at, updated_at
)
SELECT
    ns.stay_id, ns.patient_id,
    'est_4a50d9e625a5c238' AS establecimiento_id,
    ns.fecha_ingreso, ns.fecha_egreso,
    'pendiente_evaluacion'::text AS estado,
    ns.tipo_egreso,
    ns.origen_derivacion,
    ns.diagnostico_principal,
    now() AS created_at, now() AS updated_at
FROM staging.v_hodom_ingreso_2026_new_stays ns
WHERE NOT EXISTS (
    SELECT 1 FROM clinical.estadia e WHERE e.stay_id = ns.stay_id
)
AND NOT EXISTS (
    SELECT 1 FROM clinical.estadia e
    WHERE e.patient_id = ns.patient_id
      AND ns.fecha_ingreso <= coalesce(e.fecha_egreso, ns.fecha_ingreso)
      AND ns.fecha_egreso >= e.fecha_ingreso
);

-- ============================================================================
-- 3. Provenance por estadia creada
-- ============================================================================

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (ns.stay_id, f.field_name)
    'clinical.estadia', ns.stay_id, 'drive_import',
    'INGRESOS_2026_DRIVE.xlsx', ns.rut_normalizado || '|' || ns.fecha_ingreso::text,
    'create_stays_2026_05_26', f.field_name, now()
FROM staging.v_hodom_ingreso_2026_new_stays ns
CROSS JOIN (VALUES
    ('stay_id'),('patient_id'),('fecha_ingreso'),('fecha_egreso'),
    ('estado'),('tipo_egreso'),('origen_derivacion'),('diagnostico_principal')
) AS f(field_name)
WHERE NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_pk = ns.stay_id AND mp.field_name = f.field_name
      AND mp.phase = 'create_stays_2026_05_26'
);

-- ============================================================================
-- 4. Auditoria
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_stays_audit;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_stays_audit AS
SELECT
    e.stay_id, e.patient_id, e.fecha_ingreso, e.fecha_egreso,
    e.estado, e.tipo_egreso, e.diagnostico_principal,
    (SELECT count(*) FROM migration.provenance mp
     WHERE mp.target_pk = e.stay_id AND mp.phase = 'create_stays_2026_05_26') AS provenance_fields
FROM clinical.estadia e
WHERE e.stay_id IN (SELECT stay_id FROM staging.v_hodom_ingreso_2026_new_stays);

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_stays_audit IS
'Auditoria de estadias creadas desde INGRESOS 2026 DRIVE. PII — no exportar.';

COMMIT;
