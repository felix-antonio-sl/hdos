-- HODOM INGRESOS 2026 — Vistas de calidad, conciliacion y cruce
-- Non-destructive views over staging.hodom_ingreso_2026.
-- No PII in aggregate views — solo vistas de auditoria internas expuestas a la DB.
-- scope: staging.hodom_ingreso_2026 loaded from INGRESOS_2026_DRIVE.xlsx

BEGIN;

-- ============================================================================
-- 1. Vista de calidad: resumen agregado de flags
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_quality_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_quality_summary AS
SELECT
    'INGRESOS_2026_DRIVE' AS source,
    count(*) AS total_rows,
    count(*) FILTER (WHERE rut_normalizado IS NOT NULL) AS rows_with_rut,
    count(*) FILTER (WHERE fecha_ingreso IS NOT NULL) AS rows_with_fecha_ingreso,
    count(*) FILTER (WHERE fecha_egreso IS NOT NULL) AS rows_with_fecha_egreso,
    count(*) FILTER (WHERE fecha_nacimiento IS NOT NULL) AS rows_with_fecha_nacimiento,
    count(*) FILTER (WHERE sexo IS NOT NULL) AS rows_with_sexo,
    count(*) FILTER (WHERE jsonb_array_length(calidad_flags) > 0) AS rows_with_flags,
    count(*) FILTER (WHERE fecha_ingreso IS NOT NULL AND fecha_egreso IS NOT NULL
                     AND fecha_ingreso > fecha_egreso) AS fecha_ingreso_posterior_egreso,
    count(*) FILTER (WHERE rut_normalizado IS NOT NULL
                     AND (char_length(rut_normalizado) < 8
                          OR NOT rut_normalizado ~ '^\d{6,8}-[\dkK]$')) AS rut_formato_irregular,
    count(*) FILTER (WHERE rut_normalizado IS NULL) AS rut_vacio,
    count(DISTINCT rut_normalizado) AS distinct_ruts,
    count(DISTINCT nombre_completo) AS distinct_nombres,
    count(*) FILTER (WHERE nombre_completo IS NULL) AS nombres_vacios,
    min(fecha_ingreso) AS min_fecha_ingreso,
    max(fecha_ingreso) AS max_fecha_ingreso,
    min(fecha_egreso) AS min_fecha_egreso,
    max(fecha_egreso) AS max_fecha_egreso,
    now() AS generated_at
FROM staging.hodom_ingreso_2026;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_quality_summary IS
'Resumen agregado de calidad de INGRESOS 2026 DRIVE. Seguro para documentacion versionable:
 sin nombres, RUT, direcciones ni telefonos.';

-- ============================================================================
-- 2. Distribucion de flags de calidad (por tipo)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_quality_flags_detail;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_quality_flags_detail AS
SELECT
    flag,
    count(*) AS row_count
FROM staging.hodom_ingreso_2026,
LATERAL jsonb_array_elements_text(calidad_flags) AS flag
GROUP BY flag
ORDER BY row_count DESC;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_quality_flags_detail IS
'Distribucion de flags de calidad detectados durante ingestion.';

-- ============================================================================
-- 3. Duplicados: rows con mismo RUT y ventana de ingreso solapada
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_duplicate_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_duplicate_summary AS
WITH rut_groups AS (
    SELECT
        rut_normalizado,
        count(*) AS row_count,
        count(DISTINCT sheet_name) AS sheet_count,
        count(*) FILTER (WHERE fecha_ingreso IS NOT NULL AND fecha_egreso IS NOT NULL
                         AND fecha_ingreso > fecha_egreso) AS rows_con_fecha_invertida
    FROM staging.hodom_ingreso_2026
    WHERE rut_normalizado IS NOT NULL
    GROUP BY rut_normalizado
    HAVING count(*) > 1
)
SELECT
    'INGRESOS_2026_DRIVE' AS source,
    count(*) AS ruts_con_duplicados,
    sum(row_count) AS total_duplicate_rows,
    sum(row_count) FILTER (WHERE sheet_count > 1) AS cross_sheet_duplicates,
    sum(row_count) FILTER (WHERE sheet_count = 1) AS intra_sheet_duplicates,
    sum(row_count) FILTER (WHERE rows_con_fecha_invertida > 0) AS rows_con_fecha_invertida
FROM rut_groups;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_duplicate_summary IS
'Agregado de duplicados: mismos RUT en multiple filas. Intra-sheet vs cross-sheet.
 Seguro para documentacion.';

-- ============================================================================
-- 4. Conciliacion RUT contra clinical.paciente
--    Match fuerte: RUT exacto
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_patient_match_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_patient_match_summary AS
WITH rut_match AS (
    SELECT
        i.rut_normalizado,
        i.ingreso_id,
        p.patient_id,
        staging.norm_text(p.nombre_completo) = staging.norm_text(i.nombre_completo)
            AS nombre_exacto
    FROM staging.hodom_ingreso_2026 i
    JOIN clinical.paciente p
      ON p.rut IS NOT NULL
     AND staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = i.rut_normalizado
     AND p.deleted_at IS NULL
    WHERE i.rut_normalizado IS NOT NULL
)
SELECT
    'INGRESOS_2026_DRIVE' AS source,
    count(DISTINCT i.ingreso_id) AS total_con_rut,
    count(DISTINCT rm.ingreso_id) AS matched_by_rut,
    count(DISTINCT rm.ingreso_id) FILTER (WHERE rm.nombre_exacto) AS matched_by_rut_y_nombre,
    count(DISTINCT rm.ingreso_id) FILTER (WHERE NOT rm.nombre_exacto) AS matched_by_rut_nombre_distinto,
    count(DISTINCT i.ingreso_id) - count(DISTINCT rm.ingreso_id) AS sin_match_en_db
FROM staging.hodom_ingreso_2026 i
LEFT JOIN rut_match rm ON rm.ingreso_id = i.ingreso_id
WHERE i.rut_normalizado IS NOT NULL;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_patient_match_summary IS
'Conciliacion de RUT contra clinical.paciente. Muestra cuantos ingresos tienen
 paciente en DB via RUT exacto, y cuantos de esos matchean tambien por nombre.
 Seguro para documentacion.';

-- ============================================================================
-- 5. Conciliacion contra clinical.estadia: ingreso + paciente + ventana
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_stay_match_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_stay_match_summary AS
WITH stay_match AS (
    SELECT DISTINCT i.ingreso_id, e.stay_id
    FROM staging.hodom_ingreso_2026 i
    JOIN clinical.paciente p
      ON p.rut IS NOT NULL
     AND staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = i.rut_normalizado
     AND p.deleted_at IS NULL
    JOIN clinical.estadia e
      ON e.patient_id = p.patient_id
     AND i.fecha_ingreso IS NOT NULL
     AND i.fecha_egreso IS NOT NULL
     AND i.fecha_ingreso <= coalesce(e.fecha_egreso, i.fecha_ingreso)
     AND i.fecha_egreso >= e.fecha_ingreso
    WHERE i.rut_normalizado IS NOT NULL
)
SELECT
    'INGRESOS_2026_DRIVE' AS source,
    count(DISTINCT i.ingreso_id) AS total_con_rut_y_fechas,
    count(DISTINCT sm.ingreso_id) AS matched_by_patient_stay,
    count(DISTINCT i.ingreso_id) - count(DISTINCT sm.ingreso_id) AS sin_estadia_en_db,
    count(DISTINCT sm.stay_id) AS distinct_core_stays_matched
FROM staging.hodom_ingreso_2026 i
LEFT JOIN stay_match sm ON sm.ingreso_id = i.ingreso_id
WHERE i.rut_normalizado IS NOT NULL
  AND i.fecha_ingreso IS NOT NULL
  AND i.fecha_egreso IS NOT NULL;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_stay_match_summary IS
'Conciliacion contra clinical.estadia via RUT→paciente + solapamiento de fechas.
 Muestra cuantos ingresos tienen una estadia core solapada.';

-- ============================================================================
-- 6. Cruce con visitas 2026 ya migradas
--    Ingresos con/sin visitas. Pacientes con visitas pero sin ingreso.
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_visitas_cross_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_visitas_cross_summary AS
WITH ingresos_con_paciente AS (
    SELECT DISTINCT i.ingreso_id, i.rut_normalizado, p.patient_id,
           i.fecha_ingreso, i.fecha_egreso
    FROM staging.hodom_ingreso_2026 i
    JOIN clinical.paciente p
      ON p.rut IS NOT NULL
     AND staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = i.rut_normalizado
     AND p.deleted_at IS NULL
    WHERE i.rut_normalizado IS NOT NULL
      AND i.fecha_ingreso IS NOT NULL
),
ingresos_con_visitas AS (
    SELECT DISTINCT ic.ingreso_id, v.visit_id
    FROM ingresos_con_paciente ic
    JOIN operational.visita v
      ON v.patient_id = ic.patient_id
     AND v.fecha >= '2026-01-01'
     AND v.fecha >= ic.fecha_ingreso
     AND v.fecha <= coalesce(ic.fecha_egreso, v.fecha)
),
pacientes_con_ingreso AS (
    SELECT DISTINCT p.patient_id FROM ingresos_con_paciente ic
    JOIN clinical.paciente p ON p.patient_id = ic.patient_id
),
pacientes_con_visitas AS (
    SELECT DISTINCT v.patient_id FROM operational.visita v
    WHERE v.fecha >= '2026-01-01'
)
SELECT
    'INGRESOS_2026_DRIVE' AS source,
    count(DISTINCT ic.ingreso_id) AS ingresos_con_paciente_en_db,
    count(DISTINCT iv.ingreso_id) AS ingresos_con_visitas_2026,
    count(DISTINCT ic.ingreso_id) - count(DISTINCT iv.ingreso_id)
        AS ingresos_sin_visitas_2026,
    (SELECT count(DISTINCT v.patient_id) FROM pacientes_con_visitas v)
        AS pacientes_con_visitas_2026,
    (SELECT count(DISTINCT v.patient_id) FROM pacientes_con_visitas v
     WHERE v.patient_id NOT IN (SELECT patient_id FROM pacientes_con_ingreso))
        AS pacientes_con_visitas_sin_ingreso,
    now() AS generated_at
FROM ingresos_con_paciente ic
LEFT JOIN ingresos_con_visitas iv ON iv.ingreso_id = ic.ingreso_id;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_visitas_cross_summary IS
'Cruce entre ingresos 2026 y visitas 2026 ya migradas a operational.visita.
 Detecta ingresos sin visitas y pacientes con visitas pero sin registro de ingreso.
 Seguro para documentacion.';

COMMIT;
