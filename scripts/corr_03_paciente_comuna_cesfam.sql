-- CORR-03: Limpiar comuna y cesfam en clinical.paciente
-- Fecha: 2026-04-07
-- Contexto: clinical.paciente.comuna tiene nombres de CESFAM en vez de comunas reales.
--   Se resuelve derivando la comuna desde el establecimiento más frecuente del paciente.
--   También se normaliza el cesfam al nombre oficial del establecimiento.

BEGIN;

-- Paso 1: Crear tabla temporal con el establecimiento más frecuente por paciente
CREATE TEMP TABLE patient_best_estab AS
WITH ranked AS (
  SELECT e.patient_id, t.establecimiento_id, t.nombre AS estab_nombre, t.comuna AS comuna_real,
    ROW_NUMBER() OVER (
      PARTITION BY e.patient_id
      ORDER BY count(*) DESC, max(e.fecha_ingreso) DESC
    ) AS rn
  FROM clinical.estadia e
  JOIN territorial.establecimiento t ON t.establecimiento_id = e.establecimiento_id
  GROUP BY e.patient_id, t.establecimiento_id, t.nombre, t.comuna
)
SELECT patient_id, establecimiento_id, estab_nombre, comuna_real
FROM ranked WHERE rn = 1;

-- Paso 2: Actualizar comuna del paciente
UPDATE clinical.paciente p
SET comuna = pbe.comuna_real,
    cesfam = pbe.estab_nombre,
    updated_at = NOW()
FROM patient_best_estab pbe
WHERE p.patient_id = pbe.patient_id
  AND (p.comuna IS DISTINCT FROM pbe.comuna_real
       OR p.cesfam IS DISTINCT FROM pbe.estab_nombre);

-- Paso 3: Los 114 pacientes sin establecimiento en ninguna estadía
-- Si su comuna actual es basura (nombre de CESFAM, ALTA, etc), la limpiamos
-- usando el mapa de CESFAM → comuna
UPDATE clinical.paciente
SET comuna = 'SAN CARLOS', updated_at = NOW()
WHERE patient_id NOT IN (SELECT patient_id FROM patient_best_estab)
  AND upper(trim(comuna)) IN (
    'C. TERESA BALDECHI','C. TERESA BALDECCHI','C. T. BALDECCHI','C. T. BALDECHI',
    'C.T. BALDECHI','C.T BALDECHI','C,T BALDECHI','T.BALDECHI','T. BALDECHI',
    'TERESA BALDECCHI','C. BALDECHI','C.TERESA BALDECHI',
    'C. DURAN TRUJILLO','C. DURÁN TRUJILLO','C.D. TRUJILLO','C. D. TRUJILLO',
    'DURAN TRUJILLO','DURÁN TRUJILLO','C.DURAN TRUJILLO',
    'CACHAPOAL','C. CACHAPOAL','CECOF CACHAPOAL','C. VALLE HONDO',
    'ALTA','FALLECIDO','NO','SANGREGORIO','SAN CARRLOS'
  );

UPDATE clinical.paciente
SET comuna = 'NIQUEN', updated_at = NOW()
WHERE patient_id NOT IN (SELECT patient_id FROM patient_best_estab)
  AND upper(trim(comuna)) IN (
    'C. ÑIQUEN','C. ÑIQUÉN','C.ÑIQUEN','C.ÑIQUÉN','C. NÑIQUEN',
    'C. SAN GREGORIO','C.SAN GREGORIO','SAN GREGORIO',
    'C. SAN GREGORIO /ÑIQUEN','C. SAN GREGORIO/C.ÑIQUÈN'
  );

UPDATE clinical.paciente
SET comuna = 'SAN NICOLAS', updated_at = NOW()
WHERE patient_id NOT IN (SELECT patient_id FROM patient_best_estab)
  AND upper(trim(comuna)) IN (
    'C. SAN NICOLAS','C. SAN NICOLÁS','C.SAN NICOLAS','C.SAN NICOLÁS',
    'C. PTE ÑUBLE','PUENTE ÑUBLE','P. SAN NICOLAS'
  );

-- Paso 4: Proveniencia
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
SELECT 'clinical.paciente', p.patient_id, 'manual_correction',
  'corr_03_paciente_comuna_cesfam.sql',
  'comuna=' || coalesce(p.comuna,'NULL') || ' cesfam=' || coalesce(p.cesfam,'NULL'),
  'CORR-03', 'comuna+cesfam'
FROM clinical.paciente p
WHERE p.updated_at > NOW() - interval '10 seconds';

DROP TABLE patient_best_estab;

COMMIT;
