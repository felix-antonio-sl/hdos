-- HODOM — Correccion acotada de core desde INGRESOS 2026
-- Completa clinical.paciente (fecha_nacimiento, sexo) y clinical.estadia (diagnostico_principal)
-- desde staging.hodom_ingreso_2026, solo cuando:
--   - RUT es consistente en staging (mismo valor para el campo a escribir)
--   - No hay flags de calidad que afecten el campo (EDAD_VS_NACIMIENTO_DISCREPANCIA, etc.)
--   - Maria Labrin (EDAD_VS_NACIMIENTO_DISCREPANCIA) NO se toca
--
-- Reglas:
--   1. Solo actualiza core; no inserta nuevos pacientes ni estadias.
--   2. Cada UPDATE tiene su propio gate de auditoria previo.
--   3. Provenance por paciente/campo en migration.provenance.
--   4. Idempotente: UPDATE solo donde el core es NULL/vacio y el staging tiene valor valido.

BEGIN;

-- ============================================================================
-- SECCION A: Gate pre-UPDATE — pacientes con fecha_nacimiento faltante
-- ============================================================================

DROP VIEW IF EXISTS staging.v_core_fix_dob_candidates;
CREATE OR REPLACE VIEW staging.v_core_fix_dob_candidates AS
WITH candidates AS (
  SELECT
    p.patient_id,
    p.nombre_completo,
    staging.norm_text(regexp_replace(p.rut, '[\s.,]+', '', 'g')) AS rut_norm
  FROM clinical.paciente p
  WHERE p.deleted_at IS NULL
    AND p.fecha_nacimiento IS NULL
    AND p.rut IS NOT NULL
),
staging_consistency AS (
  SELECT
    c.patient_id,
    c.nombre_completo,
    c.rut_norm,
    count(DISTINCT hi.fecha_nacimiento) AS distinct_dob,
    bool_or(hi.calidad_flags ?| ARRAY[
      'EDAD_VS_NACIMIENTO_DISCREPANCIA',
      'NACIMIENTO_FECHA_INVALIDA',
      'NACIMIENTO_FECHA_FUERA_RANGO',
      'FECHA_NACIMIENTO_POSTERIOR_INGRESO'
    ]) AS has_birth_flag,
    (SELECT hi2.fecha_nacimiento
     FROM staging.hodom_ingreso_2026 hi2
     WHERE hi2.rut_normalizado = c.rut_norm AND hi2.fecha_nacimiento IS NOT NULL
     ORDER BY hi2.fecha_ingreso DESC NULLS LAST
     LIMIT 1
    ) AS staging_dob
  FROM candidates c
  JOIN staging.hodom_ingreso_2026 hi ON hi.rut_normalizado = c.rut_norm
  WHERE hi.fecha_nacimiento IS NOT NULL
  GROUP BY c.patient_id, c.nombre_completo, c.rut_norm
)
SELECT
  patient_id,
  nombre_completo,
  rut_norm,
  staging_dob,
  distinct_dob,
  has_birth_flag,
  CASE
    WHEN distinct_dob > 1 THEN 'CONFLICTO: DOB inconsistente en staging'
    WHEN has_birth_flag THEN 'BLOQUEADO: flags de calidad en fecha_nacimiento'
    ELSE 'OK: seguro para migrar'
  END AS migration_status,
  now() AS generated_at
FROM staging_consistency
ORDER BY
  CASE
    WHEN distinct_dob > 1 THEN 2
    WHEN has_birth_flag THEN 1
    ELSE 0
  END;

COMMENT ON VIEW staging.v_core_fix_dob_candidates IS
'Candidatos para completar clinical.paciente.fecha_nacimiento desde INGRESOS 2026.
 Muestra bloqueos por inconsistencia de DOB en staging o flags de calidad.
 PII — no exportar a docs versionados.';

-- Gate: resumen seguro
DROP VIEW IF EXISTS staging.v_core_fix_dob_gate;
CREATE OR REPLACE VIEW staging.v_core_fix_dob_gate AS
SELECT
  count(*) AS total_candidates,
  count(*) FILTER (WHERE migration_status LIKE 'OK%') AS safe_to_migrate,
  count(*) FILTER (WHERE migration_status LIKE 'BLOQUEADO%') AS blocked_by_flags,
  count(*) FILTER (WHERE migration_status LIKE 'CONFLICTO%') AS blocked_by_consistency,
  now() AS generated_at
FROM staging.v_core_fix_dob_candidates;

COMMENT ON VIEW staging.v_core_fix_dob_gate IS
'Resumen de candidatos para completar fecha_nacimiento. Seguro para docs.';

-- ============================================================================
-- SECCION B: UPDATE clinical.paciente.fecha_nacimiento
-- ============================================================================

UPDATE clinical.paciente p
SET
  fecha_nacimiento = cd.staging_dob,
  updated_at = now()
FROM staging.v_core_fix_dob_candidates cd
WHERE p.patient_id = cd.patient_id
  AND cd.migration_status LIKE 'OK%'
  AND p.fecha_nacimiento IS NULL;

-- ============================================================================
-- SECCION C: Gate pre-UPDATE — pacientes con sexo faltante o inconsistente
-- ============================================================================

DROP VIEW IF EXISTS staging.v_core_fix_sexo_candidates;
CREATE OR REPLACE VIEW staging.v_core_fix_sexo_candidates AS
WITH candidates AS (
  SELECT
    p.patient_id,
    p.nombre_completo,
    p.sexo AS core_sexo,
    staging.norm_text(regexp_replace(p.rut, '[\s.,]+', '', 'g')) AS rut_norm
  FROM clinical.paciente p
  WHERE p.deleted_at IS NULL
    AND p.sexo IS NULL
    AND p.rut IS NOT NULL
),
staging_consistency AS (
  SELECT
    c.patient_id,
    c.nombre_completo,
    c.rut_norm,
    count(DISTINCT hi.sexo) AS distinct_sexo,
    (SELECT hi2.sexo
     FROM staging.hodom_ingreso_2026 hi2
     WHERE hi2.rut_normalizado = c.rut_norm AND hi2.sexo IS NOT NULL
     ORDER BY hi2.fecha_ingreso DESC NULLS LAST
     LIMIT 1
    ) AS staging_sexo
  FROM candidates c
  JOIN staging.hodom_ingreso_2026 hi ON hi.rut_normalizado = c.rut_norm
  WHERE hi.sexo IS NOT NULL
  GROUP BY c.patient_id, c.nombre_completo, c.rut_norm
)
SELECT
  patient_id,
  nombre_completo,
  rut_norm,
  staging_sexo,
  distinct_sexo,
  CASE
    WHEN distinct_sexo > 1 THEN 'CONFLICTO: sexo inconsistente en staging'
    WHEN staging_sexo IS NULL THEN 'SIN_DATO: staging sin sexo para este RUT'
    ELSE 'OK: seguro para migrar'
  END AS migration_status,
  now() AS generated_at
FROM staging_consistency
ORDER BY
  CASE
    WHEN distinct_sexo > 1 THEN 2
    WHEN staging_sexo IS NULL THEN 1
    ELSE 0
  END;

COMMENT ON VIEW staging.v_core_fix_sexo_candidates IS
'Candidatos para completar clinical.paciente.sexo desde INGRESOS 2026.
 Bloquea cuando hay inconsistencia en staging (mismo RUT, distinto sexo).
 PII — no exportar a docs versionados.';

-- Gate: resumen seguro
DROP VIEW IF EXISTS staging.v_core_fix_sexo_gate;
CREATE OR REPLACE VIEW staging.v_core_fix_sexo_gate AS
SELECT
  count(*) AS total_candidates,
  count(*) FILTER (WHERE migration_status LIKE 'OK%') AS safe_to_migrate,
  count(*) FILTER (WHERE migration_status LIKE 'CONFLICTO%') AS blocked_by_consistency,
  count(*) FILTER (WHERE migration_status LIKE 'SIN_DATO%') AS sin_dato,
  now() AS generated_at
FROM staging.v_core_fix_sexo_candidates;

COMMENT ON VIEW staging.v_core_fix_sexo_gate IS
'Resumen de candidatos para completar sexo. Seguro para docs.';

-- ============================================================================
-- SECCION D: UPDATE clinical.paciente.sexo
-- ============================================================================

UPDATE clinical.paciente p
SET
  sexo = CASE
    WHEN cs.staging_sexo = 'M' THEN 'masculino'::text
    WHEN cs.staging_sexo = 'F' THEN 'femenino'::text
    ELSE NULL
  END,
  updated_at = now()
FROM staging.v_core_fix_sexo_candidates cs
WHERE p.patient_id = cs.patient_id
  AND cs.migration_status LIKE 'OK%'
  AND cs.staging_sexo IN ('M', 'F')
  AND p.sexo IS NULL;

-- ============================================================================
-- SECCION E: Gate pre-UPDATE — estadias activas con diagnostico vacio
-- ============================================================================

DROP VIEW IF EXISTS staging.v_core_fix_diagnostico_candidates;
CREATE OR REPLACE VIEW staging.v_core_fix_diagnostico_candidates AS
SELECT
  e.stay_id,
  p.nombre_completo,
  staging.norm_text(regexp_replace(p.rut, '[\s.,]+', '', 'g')) AS rut_norm,
  e.diagnostico_principal AS core_diagnostico,
  hi.diagnostico_egreso AS staging_diagnostico,
  CASE
    WHEN hi.diagnostico_egreso IS NULL OR btrim(hi.diagnostico_egreso) = '' THEN 'SIN_DATO: staging sin diagnostico'
    ELSE 'OK: seguro para migrar'
  END AS migration_status,
  now() AS generated_at
FROM clinical.estadia e
JOIN clinical.paciente p ON e.patient_id = p.patient_id
LEFT JOIN LATERAL (
  SELECT hi2.diagnostico_egreso
  FROM staging.hodom_ingreso_2026 hi2
  WHERE hi2.rut_normalizado = staging.norm_text(regexp_replace(p.rut, '[\s.,]+', '', 'g'))
    AND hi2.estado = 'ACTIVO'
  ORDER BY hi2.fecha_ingreso DESC NULLS LAST, hi2.source_row_number DESC
  LIMIT 1
) hi ON TRUE
WHERE e.estado = 'activo'
  AND (e.diagnostico_principal IS NULL OR btrim(e.diagnostico_principal) = '')
  AND hi.diagnostico_egreso IS NOT NULL
  AND btrim(hi.diagnostico_egreso) <> '';

COMMENT ON VIEW staging.v_core_fix_diagnostico_candidates IS
'Candidatos para completar clinical.estadia.diagnostico_principal desde INGRESOS 2026.
 Solo estadias activas con diagnostico_principal vacio y respaldo INGRESOS activo.
 PII — no exportar a docs versionados.';

-- Gate: resumen seguro
DROP VIEW IF EXISTS staging.v_core_fix_diagnostico_gate;
CREATE OR REPLACE VIEW staging.v_core_fix_diagnostico_gate AS
SELECT
  count(*) AS total_candidates,
  count(*) FILTER (WHERE migration_status LIKE 'OK%') AS safe_to_migrate,
  count(*) FILTER (WHERE migration_status LIKE 'SIN_DATO%') AS sin_dato,
  now() AS generated_at
FROM staging.v_core_fix_diagnostico_candidates;

COMMENT ON VIEW staging.v_core_fix_diagnostico_gate IS
'Resumen de candidatos para completar diagnostico_principal. Seguro para docs.';

-- ============================================================================
-- SECCION F: UPDATE clinical.estadia.diagnostico_principal
-- ============================================================================

UPDATE clinical.estadia e
SET
  diagnostico_principal = cd.staging_diagnostico,
  updated_at = now()
FROM staging.v_core_fix_diagnostico_candidates cd
WHERE e.stay_id = cd.stay_id
  AND cd.migration_status LIKE 'OK%'
  AND (e.diagnostico_principal IS NULL OR btrim(e.diagnostico_principal) = '');

-- ============================================================================
-- SECCION G: Provenance por actualizacion
-- ============================================================================

-- Provenance para fecha_nacimiento
INSERT INTO migration.provenance (
  target_table, target_pk, source_type, source_file, source_key,
  phase, field_name, old_value, new_value, created_at
)
SELECT
  'clinical.paciente' AS target_table,
  cd.patient_id AS target_pk,
  'drive_import' AS source_type,
  'INGRESOS_2026_DRIVE.xlsx' AS source_file,
  cd.rut_norm AS source_key,
  'core_data_fix_2026_05_26' AS phase,
  'fecha_nacimiento' AS field_name,
  NULL AS old_value,
  cd.staging_dob::text AS new_value,
  now() AS created_at
FROM staging.v_core_fix_dob_candidates cd
WHERE cd.migration_status LIKE 'OK%'
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.paciente'
      AND mp.target_pk = cd.patient_id
      AND mp.field_name = 'fecha_nacimiento'
      AND mp.phase = 'core_data_fix_2026_05_26'
  );

-- Provenance para sexo
INSERT INTO migration.provenance (
  target_table, target_pk, source_type, source_file, source_key,
  phase, field_name, old_value, new_value, created_at
)
SELECT
  'clinical.paciente' AS target_table,
  cs.patient_id AS target_pk,
  'drive_import' AS source_type,
  'INGRESOS_2026_DRIVE.xlsx' AS source_file,
  cs.rut_norm AS source_key,
  'core_data_fix_2026_05_26' AS phase,
  'sexo' AS field_name,
  NULL AS old_value,
  CASE WHEN cs.staging_sexo = 'M' THEN 'masculino' WHEN cs.staging_sexo = 'F' THEN 'femenino' END AS new_value,
  now() AS created_at
FROM staging.v_core_fix_sexo_candidates cs
WHERE cs.migration_status LIKE 'OK%'
  AND cs.staging_sexo IN ('M', 'F')
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.paciente'
      AND mp.target_pk = cs.patient_id
      AND mp.field_name = 'sexo'
      AND mp.phase = 'core_data_fix_2026_05_26'
  );

-- Provenance para diagnostico_principal
INSERT INTO migration.provenance (
  target_table, target_pk, source_type, source_file, source_key,
  phase, field_name, old_value, new_value, created_at
)
SELECT
  'clinical.estadia' AS target_table,
  cd.stay_id AS target_pk,
  'drive_import' AS source_type,
  'INGRESOS_2026_DRIVE.xlsx' AS source_file,
  cd.rut_norm AS source_key,
  'core_data_fix_2026_05_26' AS phase,
  'diagnostico_principal' AS field_name,
  NULL AS old_value,
  cd.staging_diagnostico AS new_value,
  now() AS created_at
FROM staging.v_core_fix_diagnostico_candidates cd
WHERE cd.migration_status LIKE 'OK%'
  AND NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.estadia'
      AND mp.target_pk = cd.stay_id
      AND mp.field_name = 'diagnostico_principal'
      AND mp.phase = 'core_data_fix_2026_05_26'
  );

-- ============================================================================
-- SECCION H: Resumen de auditoria post-migracion (seguro para docs)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_core_fix_summary;
CREATE OR REPLACE VIEW staging.v_core_fix_summary AS
SELECT
  'core_data_fix_2026_05_26' AS phase,
  (SELECT count(*) FROM staging.v_core_fix_dob_candidates WHERE migration_status LIKE 'OK%') AS dob_updated,
  (SELECT count(*) FROM staging.v_core_fix_sexo_candidates WHERE migration_status LIKE 'OK%' AND staging_sexo IN ('M','F')) AS sexo_updated,
  (SELECT count(*) FROM staging.v_core_fix_diagnostico_candidates WHERE migration_status LIKE 'OK%') AS diagnostico_updated,
  (SELECT count(*) FROM staging.v_core_fix_dob_candidates WHERE migration_status NOT LIKE 'OK%') AS dob_skipped,
  (SELECT count(*) FROM staging.v_core_fix_sexo_candidates WHERE migration_status NOT LIKE 'OK%') AS sexo_skipped,
  (SELECT count(*) FROM migration.provenance WHERE phase = 'core_data_fix_2026_05_26') AS total_provenance,
  now() AS generated_at;

COMMENT ON VIEW staging.v_core_fix_summary IS
'Resumen agregado de la migracion core_data_fix. Cantidad de campos actualizados y omitidos.
 Seguro para documentacion versionable.';

COMMIT;

-- ============================================================================
-- Verificacion rapida post-migracion (ejecutar fuera de la transaccion si se desea)
-- ============================================================================
-- SELECT * FROM staging.v_core_fix_summary;
--
-- SELECT p.nombre_completo, p.rut, p.fecha_nacimiento, p.sexo
-- FROM clinical.paciente p
-- WHERE p.rut IN ('6888648-1','12145608-7','11444532-0','6646308-7')
-- ORDER BY p.rut;
--
-- SELECT e.stay_id, p.nombre_completo, e.diagnostico_principal
-- FROM clinical.estadia e
-- JOIN clinical.paciente p ON e.patient_id = p.patient_id
-- WHERE e.estado = 'activo'
--   AND p.rut IN ('11444532-0','12145608-7')
-- ORDER BY p.rut;
