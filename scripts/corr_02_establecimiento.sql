-- CORR-02: Resolver establecimiento_id en estadías donde es NULL
-- Fecha: 2026-04-07
-- Contexto: 224 estadías sin establecimiento_id.
--   79 resolvables via cesfam o comuna del paciente.
--   145 irresolubles (pacientes solo-SGH, cesfam desconocido) → quedan NULL.
--
-- Estrategia:
--   1. cesfam del paciente → mapeo directo a establecimiento
--   2. comuna del paciente (si es CESFAM disfrazado) → mapeo directo
--   3. comuna real → CESFAM default de esa comuna

BEGIN;

-- Mapa de variantes cesfam → establecimiento_id
-- Teresa Baldechi (SAN CARLOS)
CREATE TEMP TABLE cesfam_map (variante TEXT PRIMARY KEY, establecimiento_id TEXT NOT NULL);
INSERT INTO cesfam_map VALUES
  ('C. T. BALDECCHI',          'est_afb315ffeb72b6e0'),
  ('C. TERESA BALDECCHI',      'est_afb315ffeb72b6e0'),
  ('C. TERESA BALDECHI',       'est_afb315ffeb72b6e0'),
  ('T.BALDECHI',               'est_afb315ffeb72b6e0'),
  ('T. BALDECHI',              'est_afb315ffeb72b6e0'),
  ('C.T. BALDECHI',            'est_afb315ffeb72b6e0'),
  ('C. BALDECHI',              'est_afb315ffeb72b6e0'),
  ('TERESA BALDECCHI',         'est_afb315ffeb72b6e0'),
  ('C,T BALDECHI',             'est_afb315ffeb72b6e0'),
  ('C.T BALDECHI',             'est_afb315ffeb72b6e0'),
  ('CACHAPOAL',                'est_afb315ffeb72b6e0'),
  ('C. VALLE HONDO',           'est_afb315ffeb72b6e0'),
  ('C. CACHAPOAL',             'est_afb315ffeb72b6e0'),
  ('CECOF CACHAPOAL',          'est_afb315ffeb72b6e0'),
  -- Durán Trujillo (SAN CARLOS)
  ('C. DURÁN TRUJILLO',        'est_4a50d9e625a5c238'),
  ('C. DURAN TRUJILLO',        'est_4a50d9e625a5c238'),
  ('C.DURÁN TRUJILLO',         'est_4a50d9e625a5c238'),
  ('C.DURAN TRUJILLO',         'est_4a50d9e625a5c238'),
  ('C.D. TRUJILLO',            'est_4a50d9e625a5c238'),
  ('C. D. TRUJILLO',           'est_4a50d9e625a5c238'),
  ('DURAN TRUJILLO',           'est_4a50d9e625a5c238'),
  ('DURÁN TRUJILLO',           'est_4a50d9e625a5c238'),
  -- Ñiquén (ÑIQUÉN)
  ('C. ÑIQUÉN',                'est_fb7015e64870d8ac'),
  ('C. ÑIQUEN',                'est_fb7015e64870d8ac'),
  ('C.ÑIQUÉN',                 'est_fb7015e64870d8ac'),
  ('C.ÑIQUEN',                 'est_fb7015e64870d8ac'),
  ('C. NÑIQUEN',               'est_fb7015e64870d8ac'),
  ('SAN GREGORIO',             'est_fb7015e64870d8ac'),
  ('C. SAN GREGORIO',          'est_fb7015e64870d8ac'),
  ('C.SAN GREGORIO',           'est_fb7015e64870d8ac'),
  ('C. SAN GREGORIO/C.ÑIQUÈN', 'est_fb7015e64870d8ac'),
  ('SANGREGORIO',              'est_fb7015e64870d8ac'),
  -- San Nicolás (SAN NICOLÁS)
  ('C. SAN NICOLÁS',           'est_f0a60ee7272ef18f'),
  ('C. SAN NICOLAS',           'est_f0a60ee7272ef18f'),
  ('C.SAN NICOLÁS',            'est_f0a60ee7272ef18f'),
  ('C.SAN NICOLAS',            'est_f0a60ee7272ef18f'),
  ('C. PTE ÑUBLE',             'est_f0a60ee7272ef18f'),
  ('PUENTE ÑUBLE',             'est_f0a60ee7272ef18f'),
  ('POSTA PUENTE ÑUBLE',       'est_f0a60ee7272ef18f'),
  ('P. SAN NICOLAS',           'est_f0a60ee7272ef18f');

-- Mapa de comuna real → CESFAM default (el principal de cada comuna)
CREATE TEMP TABLE comuna_default (comuna_norm TEXT PRIMARY KEY, establecimiento_id TEXT NOT NULL);
INSERT INTO comuna_default VALUES
  ('SAN CARLOS',   'est_afb315ffeb72b6e0'),  -- Teresa Baldechi (57% del total)
  ('SAN NICOLAS',  'est_f0a60ee7272ef18f'),
  ('SAN NICOLÁS',  'est_f0a60ee7272ef18f'),
  ('NIQUEN',       'est_fb7015e64870d8ac'),
  ('ÑIQUEN',       'est_fb7015e64870d8ac'),
  ('ÑIQUÉN',       'est_fb7015e64870d8ac');

-- Paso 1: resolver via cesfam del paciente
UPDATE clinical.estadia e
SET establecimiento_id = cm.establecimiento_id,
    updated_at = NOW()
FROM clinical.paciente p
JOIN cesfam_map cm ON cm.variante = trim(p.cesfam)
WHERE e.patient_id = p.patient_id
  AND e.establecimiento_id IS NULL;

-- Paso 2: resolver via comuna del paciente (cuando comuna tiene nombre de CESFAM)
UPDATE clinical.estadia e
SET establecimiento_id = cm.establecimiento_id,
    updated_at = NOW()
FROM clinical.paciente p
JOIN cesfam_map cm ON cm.variante = trim(p.comuna)
WHERE e.patient_id = p.patient_id
  AND e.establecimiento_id IS NULL;

-- Paso 3: resolver via comuna real del paciente → CESFAM default
UPDATE clinical.estadia e
SET establecimiento_id = cd.establecimiento_id,
    updated_at = NOW()
FROM clinical.paciente p
JOIN comuna_default cd ON cd.comuna_norm = upper(trim(p.comuna))
WHERE e.patient_id = p.patient_id
  AND e.establecimiento_id IS NULL;

-- Proveniencia
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
SELECT 'clinical.estadia', e.stay_id, 'manual_correction', 'corr_02_establecimiento.sql',
  'Inferred from patient cesfam/comuna: ' || coalesce(p.cesfam, '') || ' / ' || coalesce(p.comuna, ''),
  'CORR-02', 'establecimiento_id'
FROM clinical.estadia e
JOIN clinical.paciente p ON p.patient_id = e.patient_id
WHERE e.establecimiento_id IS NOT NULL
  AND e.updated_at > NOW() - interval '10 seconds';

DROP TABLE cesfam_map;
DROP TABLE comuna_default;

COMMIT;
