-- CORR-13: Catálogo prestaciones REM + descomposición de visitas
-- Fuente: rem_prestacion en operational.visita (145 combinaciones → 16 atómicas)
-- Normalización: VM_ING + VM_INGRESO → VM_ING, VM_EGR + VM_EGRESO → VM_EGR

BEGIN;

-- ============================================================
-- 1. Poblar reference.catalogo_prestacion
-- ============================================================

DELETE FROM reference.catalogo_prestacion WHERE TRUE;

INSERT INTO reference.catalogo_prestacion
    (prestacion_id, codigo_mai, nombre_prestacion, macroproceso, subproceso, estamento, tipo_eph)
VALUES
    -- Enfermería
    ('ING_ENF',    NULL, 'Ingreso enfermería',           'INGRESO',      'valoracion_inicial',  'ENFERMERIA',          'EPH'),
    ('TTO_EV',     NULL, 'Tratamiento endovenoso',       'TRATAMIENTO',  'farmacoterapia',      'ENFERMERIA',          'EPH'),
    ('CA',         NULL, 'Curación avanzada',            'TRATAMIENTO',  'curaciones',          'ENFERMERIA',          'EPH'),
    ('CS',         NULL, 'Control signos vitales / curación simple', 'SEGUIMIENTO', 'control', 'ENFERMERIA',          'EPH'),
    ('EXAM',       NULL, 'Toma de exámenes',             'TRATAMIENTO',  'examenes',            'ENFERMERIA',          'EPH'),
    ('NPT',        NULL, 'Nutrición parenteral',         'TRATAMIENTO',  'farmacoterapia',      'ENFERMERIA',          'EPH'),
    ('EDUCACION',  NULL, 'Educación paciente/cuidador',  'SEGUIMIENTO',  'educacion',           'ENFERMERIA',          'EPH'),

    -- Kinesiología
    ('KTM',        NULL, 'Kinesiterapia motora',         'REHABILITACION', 'kinesiologia',      'KINESIOLOGIA',        'EPH'),
    ('KTR',        NULL, 'Kinesiterapia respiratoria',   'REHABILITACION', 'kinesiologia',      'KINESIOLOGIA',        'EPH'),
    ('ALTA_KINE',  NULL, 'Alta kinesiología',            'EGRESO',         'alta_disciplina',   'KINESIOLOGIA',        'EPH'),

    -- Fonoaudiología
    ('FONO',       NULL, 'Fonoaudiología',               'REHABILITACION', 'fonoaudiologia',    'FONOAUDIOLOGIA',      'EPH'),
    ('ALTA_FONO',  NULL, 'Alta fonoaudiología',          'EGRESO',         'alta_disciplina',   'FONOAUDIOLOGIA',      'EPH'),

    -- Médico
    ('VM_ING',     NULL, 'Visita médica de ingreso',     'INGRESO',        'visita_medica',     'MEDICO',              'EPH'),
    ('VM_EGR',     NULL, 'Visita médica de egreso',      'EGRESO',         'visita_medica',     'MEDICO',              'EPH'),

    -- Administrativo / General
    ('ALTA_HODOM', NULL, 'Alta hospitalización domiciliaria', 'EGRESO',    'alta_programa',     'ENFERMERIA',          'EPH'),
    ('OTRO',       NULL, 'Otra prestación',              'OTRO',           'otro',              NULL,                  'nueva')
;

-- ============================================================
-- 2. Normalizar rem_prestacion en visitas (VM_INGRESO→VM_ING, VM_EGRESO→VM_EGR)
-- ============================================================

UPDATE operational.visita
SET rem_prestacion = replace(replace(rem_prestacion, 'VM_INGRESO', 'VM_ING'), 'VM_EGRESO', 'VM_EGR')
WHERE rem_prestacion LIKE '%VM_INGRESO%' OR rem_prestacion LIKE '%VM_EGRESO%';

-- ============================================================
-- 3. Crear tabla de descomposición visita ↔ prestación (M:N)
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.visita_prestacion (
    visit_id       TEXT NOT NULL REFERENCES operational.visita(visit_id) ON DELETE CASCADE,
    prestacion_id  TEXT NOT NULL REFERENCES reference.catalogo_prestacion(prestacion_id),
    ordinal        INT  NOT NULL DEFAULT 1,
    PRIMARY KEY (visit_id, prestacion_id)
);

CREATE INDEX IF NOT EXISTS idx_vp_prestacion ON reporting.visita_prestacion(prestacion_id);

-- Wipe for idempotency
DELETE FROM reporting.visita_prestacion WHERE TRUE;

-- Decompose compound rem_prestacion → atomic rows
INSERT INTO reporting.visita_prestacion (visit_id, prestacion_id, ordinal)
SELECT v.visit_id, atom.code, atom.ordinal
FROM operational.visita v,
     LATERAL unnest(string_to_array(v.rem_prestacion, '+'))
         WITH ORDINALITY AS atom(code, ordinal)
WHERE v.rem_prestacion IS NOT NULL
  AND atom.code IN (SELECT prestacion_id FROM reference.catalogo_prestacion);

-- ============================================================
-- 4. Mapear visita.prestacion_id al código primario (primer atómico)
-- ============================================================

UPDATE operational.visita v
SET prestacion_id = (
    SELECT prestacion_id
    FROM reporting.visita_prestacion vp
    WHERE vp.visit_id = v.visit_id
    ORDER BY vp.ordinal
    LIMIT 1
)
WHERE v.rem_prestacion IS NOT NULL;

-- ============================================================
-- 5. Provenance
-- ============================================================

INSERT INTO migration.provenance
    (target_table, target_pk, source_type, source_file, source_key, phase)
SELECT
    'reference.catalogo_prestacion',
    prestacion_id,
    'derived',
    'operational.visita.rem_prestacion',
    prestacion_id,
    'CORR-13'
FROM reference.catalogo_prestacion
ON CONFLICT DO NOTHING;

COMMIT;
