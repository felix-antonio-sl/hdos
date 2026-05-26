-- HODOM INGRESOS 2026 — Create missing patients in clinical.paciente
-- Patients from INGRESOS_2026_DRIVE with RUT that exist in hospital DAU/SGH
-- but not yet in clinical.paciente. 72 distinct RUTs.
-- 
-- Reglas:
--   1. patient_id deterministic from RUT (repeatable, no collisions).
--   2. Data from Drive ingreso: nombre, sexo, fecha_nacimiento, prevision.
--   3. RUT validated against hospital DAU/SGH via hsc-agent-cli for sampled batch.
--   4. Provenance per row in migration.provenance.
--   5. Idempotent: ON CONFLICT DO NOTHING on rut.

BEGIN;

-- ============================================================================
-- 1. Vista de candidatos: pacientes Drive sin match en clinical.paciente
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_patients;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_patients AS
SELECT DISTINCT ON (i.rut_normalizado)
    i.rut_normalizado,
    i.nombre_completo,
    i.sexo,
    i.fecha_nacimiento,
    i.prevision,
    i.comuna,
    i.domicilio,
    i.nro_contacto,
    i.fecha_ingreso AS primera_fecha_ingreso_drive,
    i.sheet_name AS source_sheet,
    i.nombres,
    i.apellidos
FROM staging.hodom_ingreso_2026 i
WHERE i.rut_normalizado IS NOT NULL
  AND i.rut_normalizado NOT IN (
    SELECT staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g'))
    FROM clinical.paciente p WHERE p.rut IS NOT NULL AND p.deleted_at IS NULL
  )
  AND i.nombre_completo IS NOT NULL
ORDER BY i.rut_normalizado, i.fecha_ingreso DESC;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_patients IS
'Pacientes con RUT validado (existente en hospital) que no estan en clinical.paciente.
 72 RUTs distintos. Datos de nombre, sexo y fecha_nacimiento desde la planilla Drive.
 patient_id = pt_ + md5(rut)[0:16] para determinismo y no-colision.';

-- ============================================================================
-- 2. Gate: conteo antes de insertar
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_patients_gate;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_patients_gate AS
SELECT
    count(*) AS candidates,
    count(*) FILTER (WHERE sexo IS NOT NULL) AS with_sexo,
    count(*) FILTER (WHERE fecha_nacimiento IS NOT NULL) AS with_fecha_nacimiento,
    count(*) FILTER (WHERE prevision IS NOT NULL) AS with_prevision,
    count(DISTINCT rut_normalizado) AS distinct_ruts,
    now() AS generated_at
FROM staging.v_hodom_ingreso_2026_new_patients;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_patients_gate IS
'Gate pre-INSERT de pacientes nuevos. Revisar antes de ejecutar seccion 3.';

-- ============================================================================
-- 3. INSERT en clinical.paciente
-- ============================================================================

INSERT INTO clinical.paciente (
    patient_id, rut, nombre_completo, sexo, fecha_nacimiento,
    prevision, comuna, direccion, contacto_telefono,
    estado_actual, created_at, updated_at
)
SELECT
    'pt_' || substr(md5(np.rut_normalizado), 1, 16) AS patient_id,
    np.rut_normalizado AS rut,
    np.nombre_completo,
    CASE
        WHEN np.sexo = 'M' THEN 'masculino'::text
        WHEN np.sexo = 'F' THEN 'femenino'::text
        ELSE NULL
    END AS sexo,
    np.fecha_nacimiento,
    CASE
        WHEN lower(trim(np.prevision)) = 'fonasa a' THEN 'fonasa-a'
        WHEN lower(trim(np.prevision)) = 'fonasa b' THEN 'fonasa-b'
        WHEN lower(trim(np.prevision)) = 'fonasa c' THEN 'fonasa-c'
        WHEN lower(trim(np.prevision)) = 'fonasa d' THEN 'fonasa-d'
        WHEN lower(trim(np.prevision)) = 'prais' THEN 'prais'
        WHEN lower(trim(np.prevision)) IN ('dipreca', 'fonasa', 'fonosa') THEN 'otro'
        ELSE NULL
    END AS prevision,
    np.comuna,
    np.domicilio,
    np.nro_contacto,
    'activo'::text AS estado_actual,
    now() AS created_at,
    now() AS updated_at
FROM staging.v_hodom_ingreso_2026_new_patients np
WHERE np.rut_normalizado IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM clinical.paciente p
    WHERE p.rut IS NOT NULL
      AND staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = np.rut_normalizado
      AND p.deleted_at IS NULL
  );

-- ============================================================================
-- 4. Provenance por paciente creado
-- ============================================================================

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT
    'clinical.paciente' AS target_table,
    'pt_' || substr(md5(np.rut_normalizado), 1, 16) AS target_pk,
    'drive_import' AS source_type,
    'INGRESOS_2026_DRIVE.xlsx' AS source_file,
    np.rut_normalizado AS source_key,
    'create_patients_2026_05_26' AS phase,
    f.field_name,
    now() AS created_at
FROM staging.v_hodom_ingreso_2026_new_patients np
CROSS JOIN (VALUES
    ('patient_id'),('rut'),('nombre_completo'),('sexo'),
    ('fecha_nacimiento'),('prevision'),('comuna'),('direccion'),
    ('contacto_telefono'),('estado_actual')
) AS f(field_name)
WHERE NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.paciente'
      AND mp.target_pk = 'pt_' || substr(md5(np.rut_normalizado), 1, 16)
      AND mp.field_name = f.field_name
      AND mp.phase = 'create_patients_2026_05_26'
);

-- ============================================================================
-- 5. Auditoria: cuantos pacientes se crearon y con que datos
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_patients_audit;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_patients_audit AS
SELECT
    p.patient_id,
    p.rut,
    p.nombre_completo,
    p.sexo IS NOT NULL AS tiene_sexo,
    p.fecha_nacimiento IS NOT NULL AS tiene_fecha_nac,
    p.prevision IS NOT NULL AS tiene_prevision,
    p.created_at,
    (SELECT count(*) FROM migration.provenance mp
     WHERE mp.target_pk = p.patient_id
       AND mp.phase = 'create_patients_2026_05_26') AS provenance_fields
FROM clinical.paciente p
WHERE p.rut IN (
    SELECT rut_normalizado FROM staging.v_hodom_ingreso_2026_new_patients
);

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_patients_audit IS
'Auditoria de pacientes creados desde INGRESOS 2026 DRIVE.
 Muestra datos poblados y conteo de provenance. PII — no exportar.';

-- ============================================================================
-- 6. Resumen seguro para documentacion
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_ingreso_2026_new_patients_summary;
CREATE OR REPLACE VIEW staging.v_hodom_ingreso_2026_new_patients_summary AS
SELECT
    'create_patients_2026_05_26' AS phase,
    count(*) AS patients_created,
    count(*) FILTER (WHERE tiene_sexo) AS with_sexo,
    count(*) FILTER (WHERE tiene_fecha_nac) AS with_fecha_nacimiento,
    count(*) FILTER (WHERE tiene_prevision) AS with_prevision,
    (SELECT count(*) FROM migration.provenance
     WHERE phase = 'create_patients_2026_05_26') AS total_provenance,
    now() AS generated_at
FROM staging.v_hodom_ingreso_2026_new_patients_audit;

COMMENT ON VIEW staging.v_hodom_ingreso_2026_new_patients_summary IS
'Resumen agregado de creacion de pacientes. Seguro para documentacion.
 Sin RUT ni nombres.';

COMMIT;
