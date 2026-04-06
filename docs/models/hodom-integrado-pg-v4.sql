-- =============================================================================
-- HODOM Modelo Integrado v4 — DDL PostgreSQL (Part 1: Tables + Cross-layer FKs)
-- =============================================================================
-- Rewrite of hodom-integrado-pg.sql fixing 35 audit issues:
--   Native PG types (DATE, TIMESTAMPTZ), 6 schemas, no duplicate tables,
--   new reference tables (prioridad_ref, estado_maquina_config),
--   missing FKs (FIX-7, FIX-8, FIX-10), prioridad normalization.
-- PostgreSQL >= 14
-- Generated: 2026-04-06
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 0: Extensions + Schemas + Search path
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS territorial;
CREATE SCHEMA IF NOT EXISTS clinical;
CREATE SCHEMA IF NOT EXISTS operational;
CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS telemetry;

SET search_path TO reference, territorial, clinical, operational, reporting, telemetry, public;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: Reference catalogs (reference schema) + seed data
-- ═══════════════════════════════════════════════════════════════════════════════

-- Prioridad unificada (nuevo — cubre vocabularios de sla, orden_servicio,
-- lista_espera, interconsulta, entrega_turno_paciente, solicitud_examen)
CREATE TABLE reference.prioridad_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    orden       INTEGER NOT NULL,  -- menor = más urgente
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.prioridad_ref (codigo, descripcion, orden) VALUES
    ('urgente',    'Urgente — atención inmediata o en horas',   1),
    ('alta',       'Alta prioridad / preferente',               2),
    ('preferente', 'Preferente (sinónimo de alta)',              2),
    ('normal',     'Normal / rutina',                           3),
    ('rutina',     'Rutina (sinónimo de normal)',                3),
    ('media',      'Media prioridad',                           4),
    ('baja',       'Baja prioridad',                            5)
ON CONFLICT DO NOTHING;

-- Estado máquina config — documenta enforcement por tabla
CREATE TABLE reference.estado_maquina_config (
    tabla           TEXT NOT NULL,
    tipo_maquina    TEXT NOT NULL CHECK (tipo_maquina IN ('visita', 'estadia')),
    enforcement     TEXT NOT NULL CHECK (enforcement IN ('full', 'soft', 'none')),
    descripcion     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tabla, tipo_maquina)
);

INSERT INTO reference.estado_maquina_config (tabla, tipo_maquina, enforcement, descripcion) VALUES
    ('visita',          'visita',  'full', 'Guard trigger + evento_visita transition validation'),
    ('estadia',         'estadia', 'full', 'Guard trigger + evento_estadia transition validation'),
    ('orden_servicio',  'visita',  'soft', 'CHECK constraint only, no state machine trigger'),
    ('lista_espera',    'estadia', 'soft', 'CHECK constraint only, no state machine trigger')
ON CONFLICT DO NOTHING;

-- Catálogo de prestaciones MAI
CREATE TABLE reference.catalogo_prestacion (
    prestacion_id       TEXT PRIMARY KEY,
    codigo_mai          TEXT,
    nombre_prestacion   TEXT NOT NULL,
    macroproceso        TEXT,
    subproceso          TEXT,
    estamento           TEXT CHECK (estamento IS NULL OR estamento IN (
                            'ENFERMERIA', 'KINESIOLOGIA', 'FONOAUDIOLOGIA', 'MEDICO',
                            'TRABAJO_SOCIAL', 'TENS', 'NUTRICION', 'MATRONA',
                            'PSICOLOGIA', 'TERAPIA_OCUPACIONAL'
                        )),
    tipo_eph            TEXT CHECK (tipo_eph IN ('EPH', 'nueva')),
    area_influencia     TEXT,
    compra_servicio     BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_catalogo_prestacion_mai ON reference.catalogo_prestacion(codigo_mai);

-- Tipo documento
CREATE TABLE reference.tipo_documento_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.tipo_documento_ref (codigo, descripcion) VALUES
    ('formulario_ingreso',              'Formulario de ingreso a hospitalización domiciliaria'),
    ('informe_social_preliminar',       'Informe social preliminar de evaluación domiciliaria'),
    ('informe_social',                  'Informe social completo del paciente y entorno familiar'),
    ('registro_evaluacion_clinica',     'Registro de evaluación clínica de ingreso'),
    ('documento_indicaciones_cuidado',  'Documento de indicaciones de cuidado para el paciente'),
    ('registro_coordinacion_derivador', 'Registro de coordinación con servicio derivador'),
    ('resumen_clinico_domiciliario',    'Resumen clínico de atención domiciliaria'),
    ('epicrisis',                       'Epicrisis de hospitalización domiciliaria'),
    ('encuesta_satisfaccion',           'Encuesta de satisfacción usuaria'),
    ('protocolo_fallecimiento',         'Protocolo de fallecimiento en domicilio'),
    ('declaracion_retiro',              'Declaración de retiro voluntario del programa'),
    ('registro_llamada_seguimiento',    'Registro de llamada de seguimiento post-egreso'),
    ('resultado_egreso',                'Resultado de egreso del episodio'),
    ('registro_curacion',               'Registro de procedimiento de curación'),
    ('registro_fonoaudiologia',         'Registro de atención fonoaudiológica'),
    ('registro_telesalud',              'Registro de atención por telesalud'),
    ('registro_llamada',                'Registro de llamada telefónica'),
    ('registro_movimientos',            'Registro de movimientos de paciente'),
    ('registro_entrega_turno',          'Registro de entrega de turno entre equipos'),
    ('reporte_ejecucion_rutas',         'Reporte de ejecución de rutas domiciliarias'),
    ('carta_derechos_deberes',          'Carta de derechos y deberes del paciente (Ley 20.584)'),
    ('consentimiento_informado',        'Consentimiento informado de hospitalización domiciliaria'),
    ('hoja_derivacion',                 'Hoja de derivación desde servicio de origen'),
    ('foto_herida',                     'Fotografía clínica de herida'),
    ('nota_visita',                     'Nota clínica de visita domiciliaria'),
    ('dau',                             'Documento de atención de urgencia (DAU)')
ON CONFLICT DO NOTHING;

-- Tipo requerimiento
CREATE TABLE reference.tipo_requerimiento_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.tipo_requerimiento_ref (codigo, descripcion) VALUES
    ('CURACIONES',          'Curaciones de heridas'),
    ('TTO_EV',              'Tratamiento endovenoso'),
    ('TTO_SC',              'Tratamiento subcutáneo'),
    ('TOMA_MUESTRAS',       'Toma de muestras de laboratorio'),
    ('ELEMENTOS_INVASIVOS', 'Manejo de elementos invasivos (SNG, CUP, VVP, drenajes)'),
    ('CSV',                 'Control de signos vitales'),
    ('EDUCACION',           'Educación al paciente y/o cuidador'),
    ('REQUERIMIENTO_O2',    'Requerimiento de oxigenoterapia'),
    ('MANEJO_OSTOMIAS',     'Manejo de ostomías'),
    ('USUARIO_O2',          'Usuario dependiente de oxígeno'),
    ('VISITA_MEDICA',       'Visita médica domiciliaria'),
    ('KINESIOLOGIA',        'Atención kinesiológica (respiratoria y/o motora)'),
    ('FONOAUDIOLOGIA',      'Atención fonoaudiológica')
ON CONFLICT DO NOTHING;

-- Código observación
CREATE TABLE reference.codigo_observacion_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    unidad      TEXT,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.codigo_observacion_ref (codigo, descripcion, unidad) VALUES
    ('presion_arterial',             'Presión arterial sistólica/diastólica',       'mmHg'),
    ('frecuencia_cardiaca',          'Frecuencia cardíaca',                         'lpm'),
    ('frecuencia_respiratoria',      'Frecuencia respiratoria',                     'rpm'),
    ('saturacion_oxigeno',           'Saturación de oxígeno (SpO2)',                '%'),
    ('temperatura_corporal',         'Temperatura corporal',                        '°C'),
    ('glicemia',                     'Glicemia capilar (hemoglucotest)',             'mg/dL'),
    ('escala_dolor',                 'Escala numérica análoga de dolor (ENA 0-10)', NULL),
    ('glasgow',                      'Escala de coma de Glasgow (3-15)',             NULL),
    ('estado_edema',                 'Estado de edema (localización, grado)',        NULL),
    ('diuresis',                     'Diuresis (volumen y características)',          'mL'),
    ('estado_intestinal',            'Estado de tránsito intestinal',                NULL),
    ('estado_dispositivo_invasivo',  'Estado de dispositivo invasivo',               NULL)
ON CONFLICT DO NOTHING;

-- Tema educación
CREATE TABLE reference.tema_educacion_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.tema_educacion_ref (codigo, descripcion) VALUES
    ('manejo_medicamentos',      'Manejo y administración de medicamentos'),
    ('cuidado_heridas',          'Cuidado de heridas y curaciones'),
    ('alimentacion_nutricion',   'Alimentación y nutrición'),
    ('manejo_dispositivos',      'Manejo de dispositivos (SNG, CUP, VVP, ostomías)'),
    ('oxigenoterapia',           'Uso y cuidado de oxigenoterapia domiciliaria'),
    ('ejercicios_rehabilitacion','Ejercicios de rehabilitación en domicilio'),
    ('signos_alarma',            'Signos de alarma y cuándo consultar'),
    ('prevencion_caidas',        'Prevención de caídas en domicilio'),
    ('prevencion_upp',           'Prevención de úlceras por presión'),
    ('manejo_dolor',             'Manejo del dolor'),
    ('cuidados_paliativos',      'Cuidados paliativos y acompañamiento'),
    ('derechos_deberes',         'Derechos y deberes del paciente (Ley 20.584)'),
    ('uso_red_emergencia',       'Uso de red de emergencia (SAMU 131, SAPU)'),
    ('higiene_confort',          'Higiene y confort del paciente'),
    ('salud_mental_cuidador',    'Salud mental y autocuidado del cuidador'),
    ('otro',                     'Otro tema de educación no clasificado')
ON CONFLICT DO NOTHING;

-- Tipo evento adverso
CREATE TABLE reference.tipo_evento_adverso_ref (
    codigo       TEXT PRIMARY KEY,
    descripcion  TEXT NOT NULL,
    notificable  BOOLEAN DEFAULT FALSE,
    activo       BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.tipo_evento_adverso_ref (codigo, descripcion, notificable) VALUES
    ('caida',                        'Caída en domicilio durante hospitalización',           TRUE),
    ('error_medicacion',             'Error de medicación',                                  TRUE),
    ('reaccion_adversa_medicamento', 'Reacción adversa a medicamento (RAM)',                 TRUE),
    ('iaas',                         'Infección asociada a atención de salud',               TRUE),
    ('lesion_por_presion',           'Úlcera por presión adquirida durante HD',              TRUE),
    ('falla_equipo',                 'Falla de equipamiento clínico',                        FALSE),
    ('extravasacion',                'Extravasación de infusión endovenosa',                  TRUE),
    ('retiro_accidental_dispositivo','Retiro accidental de dispositivo invasivo',             TRUE),
    ('error_identificacion',         'Error de identificación de paciente',                  TRUE),
    ('evento_centinela',             'Evento centinela (muerte inesperada, daño grave)',      TRUE),
    ('near_miss',                    'Casi-error detectado antes de alcanzar al paciente',    FALSE),
    ('otro',                         'Otro evento adverso no clasificado',                   FALSE)
ON CONFLICT DO NOTHING;

-- Dominio hallazgo
CREATE TABLE reference.dominio_hallazgo_ref (
    codigo           TEXT PRIMARY KEY,
    descripcion      TEXT NOT NULL,
    profesion_origen TEXT,
    activo           BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.dominio_hallazgo_ref (codigo, descripcion, profesion_origen) VALUES
    ('estado_conciencia',    'Estado de conciencia (SNOMED 365929002)',               'ENFERMERIA'),
    ('estado_psiquico',      'Estado psíquico (SNOMED 363871006)',                    'ENFERMERIA'),
    ('lenguaje',             'Evaluación de lenguaje general (SNOMED 61909002)',      'ENFERMERIA'),
    ('estado_piel',          'Estado de piel: color e hidratación (SNOMED 364528001)','ENFERMERIA'),
    ('estado_nutritivo',     'Estado nutritivo (SNOMED 363808001)',                   'ENFERMERIA'),
    ('autocuidado',          'Capacidad de autocuidado (SNOMED 129025006)',           'ENFERMERIA'),
    ('examen_cabeza',        'Examen de cabeza (SNOMED 302548004)',                   'ENFERMERIA'),
    ('examen_cuello',        'Examen de cuello (SNOMED 302550007)',                   'ENFERMERIA'),
    ('examen_pupilas',       'Examen pupilar (SNOMED 363926002)',                     'ENFERMERIA'),
    ('examen_torax',         'Examen de tórax (SNOMED 302551006)',                    'ENFERMERIA'),
    ('examen_escleras',      'Examen de escleras (SNOMED 181143004)',                 'ENFERMERIA'),
    ('examen_abdomen',       'Examen abdominal (SNOMED 302553009)',                   'ENFERMERIA'),
    ('examen_oidos',         'Examen de oídos (SNOMED 302542000)',                    'ENFERMERIA'),
    ('examen_eess',          'Examen de extremidades superiores (SNOMED 53120007)',   'ENFERMERIA'),
    ('examen_boca',          'Examen de boca (SNOMED 302549007)',                     'ENFERMERIA'),
    ('examen_eeii',          'Examen de extremidades inferiores (SNOMED 61685007)',   'ENFERMERIA'),
    ('examen_dentadura',     'Examen de dentadura (SNOMED 245543004)',                'ENFERMERIA'),
    ('examen_genitales',     'Examen genital (SNOMED 263767004)',                     'ENFERMERIA'),
    ('conciencia_kine',      'Estado de conciencia kinesiológico',                    'KINESIOLOGIA'),
    ('dolor_ena',            'Escala numérica análoga de dolor (LOINC 38208-5)',      'KINESIOLOGIA'),
    ('oxigenoterapia',       'Oxigenoterapia: FiO2 y dispositivo',                   'KINESIOLOGIA'),
    ('auscultacion',         'Auscultación pulmonar: murmullo pulmonar',             'KINESIOLOGIA'),
    ('tos',                  'Característica de tos',                                 'KINESIOLOGIA'),
    ('secrecion_bronquial',  'Secreción bronquial: tipo y cantidad',                 'KINESIOLOGIA'),
    ('cooperacion',          'Nivel de cooperación',                                  'TERAPIA_OCUPACIONAL'),
    ('conexion_medio',       'Conexión con el medio',                                 'TERAPIA_OCUPACIONAL'),
    ('motricidad_fina',      'Motricidad fina: agarre, prensión, pinzas',            'TERAPIA_OCUPACIONAL'),
    ('motricidad_gruesa',    'Motricidad gruesa: alcance y coordinación',             'TERAPIA_OCUPACIONAL'),
    ('deglucion',            'Evaluación de deglución',                               'FONOAUDIOLOGIA'),
    ('habla',                'Evaluación de habla',                                   'FONOAUDIOLOGIA'),
    ('voz',                  'Evaluación de voz',                                     'FONOAUDIOLOGIA'),
    ('lenguaje_fono',        'Evaluación de lenguaje fonoaudiológico',               'FONOAUDIOLOGIA')
ON CONFLICT DO NOTHING;

-- Categoría rehabilitación
CREATE TABLE reference.categoria_rehabilitacion_ref (
    codigo      TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    tipo_sesion TEXT NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.categoria_rehabilitacion_ref (codigo, descripcion, tipo_sesion) VALUES
    ('ttkk',                     'Técnicas kinésicas respiratorias',                          'kinesiologia_respiratoria'),
    ('ejercicios_respiratorios', 'Ejercicios respiratorios',                                  'kinesiologia_respiratoria'),
    ('aspiracion_secreciones',   'Aspiración de secreciones',                                 'kinesiologia_respiratoria'),
    ('aseo_nasal',               'Aseo nasal con suero fisiológico',                          'kinesiologia_respiratoria'),
    ('drenaje_bronquial',        'Drenaje bronquial postural',                                'kinesiologia_respiratoria'),
    ('succion_endotraqueal',     'Succión endotraqueal',                                      'kinesiologia_respiratoria'),
    ('succion_orofaringea',      'Succión orofaríngea',                                       'kinesiologia_respiratoria'),
    ('succion_nasofaringea',     'Succión nasofaríngea',                                      'kinesiologia_respiratoria'),
    ('ejercicio_terapeutico',    'Ejercicio terapéutico (pasivo/activo/activo-asistido)',      'kinesiologia_motora'),
    ('marcha',                   'Entrenamiento de marcha',                                   'kinesiologia_motora'),
    ('educacion_kine',           'Educación kinesiológica',                                   'kinesiologia_motora'),
    ('estimulacion_cognitiva',   'Estimulación cognitiva',                                    'terapia_ocupacional'),
    ('entrenamiento_avd',        'Entrenamiento en actividades de la vida diaria',            'terapia_ocupacional'),
    ('estimulacion_polisensorial','Estimulación polisensorial',                               'terapia_ocupacional'),
    ('manejo_edema',             'Manejo de edema',                                           'terapia_ocupacional'),
    ('confeccion_ortesis',       'Confección de órtesis',                                     'terapia_ocupacional'),
    ('evaluacion_deglucion',     'Evaluación de deglución',                                   'fonoaudiologia'),
    ('evaluacion_lenguaje',      'Evaluación de lenguaje',                                    'fonoaudiologia'),
    ('evaluacion_habla',         'Evaluación de habla',                                       'fonoaudiologia'),
    ('evaluacion_voz',           'Evaluación de voz',                                         'fonoaudiologia'),
    ('rhb_deglucion',            'Rehabilitación de deglución',                               'fonoaudiologia'),
    ('rhb_voz',                  'Rehabilitación de voz',                                     'fonoaudiologia'),
    ('rhb_lenguaje',             'Rehabilitación de lenguaje',                                'fonoaudiologia'),
    ('rhb_habla',                'Rehabilitación de habla',                                   'fonoaudiologia')
ON CONFLICT DO NOTHING;

-- Service type
CREATE TABLE reference.service_type_ref (
    service_type        TEXT PRIMARY KEY,
    descripcion         TEXT NOT NULL,
    profesion_requerida TEXT CHECK (profesion_requerida IS NULL OR profesion_requerida IN (
                            'ENFERMERIA', 'KINESIOLOGIA', 'FONOAUDIOLOGIA', 'MEDICO',
                            'TRABAJO_SOCIAL', 'TENS', 'NUTRICION', 'MATRONA',
                            'PSICOLOGIA', 'TERAPIA_OCUPACIONAL'
                        )),
    rem_reportable      BOOLEAN DEFAULT TRUE,
    activo              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reference.service_type_ref (service_type, descripcion, profesion_requerida) VALUES
    ('CURACIONES',          'Curación de heridas',           'ENFERMERIA'),
    ('TTO_EV',              'Tratamiento endovenoso',        'ENFERMERIA'),
    ('TTO_SC',              'Tratamiento subcutáneo',        'ENFERMERIA'),
    ('TOMA_MUESTRAS',       'Toma de muestras',              'ENFERMERIA'),
    ('ELEMENTOS_INVASIVOS', 'Manejo elementos invasivos',    'ENFERMERIA'),
    ('CSV',                 'Control signos vitales',         'ENFERMERIA'),
    ('EDUCACION',           'Educación paciente/cuidador',   'ENFERMERIA'),
    ('REQUERIMIENTO_O2',    'Oxigenoterapia',                'ENFERMERIA'),
    ('MANEJO_OSTOMIAS',     'Manejo de ostomías',            'ENFERMERIA'),
    ('USUARIO_O2',          'Paciente usuario de O2',        'ENFERMERIA'),
    ('VISITA_MEDICA',       'Visita médica domiciliaria',    'MEDICO'),
    ('KINESIOLOGIA',        'Kinesiología (KTR/KTM)',        'KINESIOLOGIA'),
    ('FONOAUDIOLOGIA',      'Fonoaudiología',                'FONOAUDIOLOGIA'),
    ('TERAPIA_OCUPACIONAL', 'Terapia ocupacional',           'TERAPIA_OCUPACIONAL'),
    ('TRABAJO_SOCIAL',      'Intervención social',           'TRABAJO_SOCIAL')
ON CONFLICT DO NOTHING;

-- Máquina de estados de visita
CREATE TABLE reference.maquina_estados_ref (
    from_state TEXT NOT NULL,
    to_state   TEXT NOT NULL,
    trigger    TEXT,
    actor      TEXT,
    PRIMARY KEY (from_state, to_state)
);

INSERT INTO reference.maquina_estados_ref (from_state, to_state, trigger, actor) VALUES
    ('PROGRAMADA',    'ASIGNADA',      'asignacion_profesional',   'coordinador'),
    ('ASIGNADA',      'DESPACHADA',    'despacho_diario',          'coordinador'),
    ('DESPACHADA',    'EN_RUTA',       'salida_base',              'conductor'),
    ('EN_RUTA',       'LLEGADA',       'arribo_domicilio',         'profesional'),
    ('LLEGADA',       'EN_ATENCION',   'inicio_atencion',          'profesional'),
    ('EN_ATENCION',   'COMPLETA',      'fin_atencion_exitosa',     'profesional'),
    ('EN_ATENCION',   'PARCIAL',       'fin_atencion_incompleta',  'profesional'),
    ('LLEGADA',       'NO_REALIZADA',  'paciente_ausente',         'profesional'),
    ('COMPLETA',      'DOCUMENTADA',   'cierre_documentacion',     'profesional'),
    ('PARCIAL',       'DOCUMENTADA',   'cierre_documentacion',     'profesional'),
    ('DOCUMENTADA',   'VERIFICADA',    'verificacion_coordinador', 'coordinador'),
    ('VERIFICADA',    'REPORTADA_REM', 'inclusion_reporte_rem',    'sistema'),
    ('PROGRAMADA',    'CANCELADA',     'cancelacion',              'coordinador'),
    ('ASIGNADA',      'CANCELADA',     'cancelacion',              'coordinador'),
    ('NO_REALIZADA',  'DOCUMENTADA',   'cierre_documentacion',     'profesional')
ON CONFLICT DO NOTHING;

-- Máquina de estados de estadía (OPM SD1 lifecycle)
CREATE TABLE reference.maquina_estados_estadia_ref (
    from_state  TEXT NOT NULL,
    to_state    TEXT NOT NULL,
    proceso_opm TEXT,
    descripcion TEXT,
    PRIMARY KEY (from_state, to_state)
);

INSERT INTO reference.maquina_estados_estadia_ref (from_state, to_state, proceso_opm, descripcion) VALUES
    ('pendiente_evaluacion', 'elegible',  'eligibility_evaluating', 'Evaluación positiva de elegibilidad'),
    ('pendiente_evaluacion', 'egresado',  'eligibility_evaluating', 'No elegible — rechazado en evaluación'),
    ('elegible',             'admitido',  'patient_admitting',      'Paciente ingresa formalmente'),
    ('admitido',             'activo',    'care_planning',          'Plan de cuidado activado'),
    ('activo',               'egresado',  'patient_discharging',    'Egreso: alta clínica, renuncia, disciplinaria, reingreso'),
    ('activo',               'fallecido', 'patient_discharging',    'Egreso: fallecido esperado o no esperado'),
    ('egresado',             'activo',    'patient_admitting',      'Reingreso a hospitalización domiciliaria')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2: Territorial tables (territorial schema)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE territorial.establecimiento (
    establecimiento_id  TEXT PRIMARY KEY,  -- código DEIS
    nombre              TEXT NOT NULL,
    tipo                TEXT CHECK (tipo IS NULL OR tipo IN (
                            'hospital', 'cesfam', 'cecosf', 'cec', 'postas',
                            'sapu', 'sar', 'cosam', 'otro'
                        )),
    comuna              TEXT,
    direccion           TEXT,
    servicio_salud      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE territorial.zona (
    zone_id             TEXT PRIMARY KEY,
    nombre              TEXT NOT NULL,
    tipo                TEXT CHECK (tipo IN ('URBANO', 'PERIURBANO', 'RURAL', 'RURAL_AISLADO')),
    comunas             JSONB,  -- JSON array of comunas
    centroide_lat       REAL,
    centroide_lng       REAL,
    tiempo_acceso_min   INTEGER,
    conectividad        TEXT,
    capacidad_dia       INTEGER,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE territorial.ubicacion (
    location_id         TEXT PRIMARY KEY,
    nombre_oficial      TEXT,
    comuna              TEXT,
    tipo                TEXT CHECK (tipo IS NULL OR tipo IN ('URBANO', 'PERIURBANO', 'RURAL', 'RURAL_AISLADO')),
    latitud             REAL,
    longitud            REAL,
    zone_id             TEXT REFERENCES zona(zone_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE territorial.matriz_distancia (
    origin_zone_id      TEXT NOT NULL REFERENCES zona(zone_id),
    dest_zone_id        TEXT NOT NULL REFERENCES zona(zone_id),
    km                  REAL,
    minutos             REAL,
    via                 TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (origin_zone_id, dest_zone_id)
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3: Clinical core tables (clinical schema)
-- paciente through encuesta_satisfaccion
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE clinical.paciente (
    patient_id          TEXT PRIMARY KEY,  -- hash determinista
    nombre_completo     TEXT NOT NULL,
    rut                 TEXT,
    sexo                TEXT CHECK (sexo IN ('masculino', 'femenino')),
    fecha_nacimiento    DATE,
    direccion           TEXT,
    comuna              TEXT,
    cesfam              TEXT,  -- TODO: REFERENCES catalogo_establecimiento_aps when available
    prevision           TEXT CHECK (prevision IS NULL OR prevision IN (
                            'fonasa-a', 'fonasa-b', 'fonasa-c', 'fonasa-d', 'prais', 'otro'
                        )),
    contacto_telefono   TEXT,
    estado_actual       TEXT CHECK (estado_actual IS NULL OR estado_actual IN (
                            'pre_ingreso', 'activo', 'egresado', 'fallecido'
                        )),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_paciente_rut ON clinical.paciente(rut);
CREATE INDEX idx_paciente_nombre ON clinical.paciente(nombre_completo);

CREATE TABLE clinical.cuidador (
    cuidador_id         TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    nombre              TEXT,
    parentesco          TEXT NOT NULL,  -- dato clínico requerido (representación legal)
    contacto            TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cuidador_paciente ON clinical.cuidador(patient_id);

CREATE TABLE clinical.estadia (
    stay_id             TEXT PRIMARY KEY,  -- hash determinista
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    establecimiento_id  TEXT REFERENCES establecimiento(establecimiento_id),
    fecha_ingreso       DATE NOT NULL,
    fecha_egreso        DATE,           -- NULL = activo
    estado              TEXT CHECK (estado IN (
                            'pendiente_evaluacion', 'elegible', 'admitido',
                            'activo', 'egresado', 'fallecido'
                        )) DEFAULT 'pendiente_evaluacion',
    tipo_egreso         TEXT CHECK (tipo_egreso IS NULL OR tipo_egreso IN (
                            'alta_clinica', 'fallecido_esperado', 'fallecido_no_esperado',
                            'reingreso', 'renuncia_voluntaria', 'alta_disciplinaria'
                        )),
    origen_derivacion   TEXT CHECK (origen_derivacion IS NULL OR origen_derivacion IN (
                            'APS', 'urgencia', 'hospitalizacion',
                            'ambulatorio', 'ley_urgencia', 'UGCC'
                        )),
    diagnostico_principal TEXT,
    condicion_domicilio TEXT CHECK (condicion_domicilio IS NULL OR condicion_domicilio IN ('adecuada', 'inadecuada')),
    confidence_level    TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso),
    EXCLUDE USING gist (
        patient_id WITH =,
        daterange(fecha_ingreso, COALESCE(fecha_egreso, '9999-12-31'), '[]') WITH &&
    )
);

CREATE INDEX idx_estadia_paciente ON clinical.estadia(patient_id);
CREATE INDEX idx_estadia_fechas ON clinical.estadia(fecha_ingreso, fecha_egreso);
CREATE INDEX idx_estadia_estado ON clinical.estadia(estado);
CREATE INDEX idx_estadia_establecimiento ON clinical.estadia(establecimiento_id);
CREATE INDEX idx_estadia_activos ON clinical.estadia(patient_id) WHERE estado = 'activo';

-- FIX-7: condicion now has patient_id FK
CREATE TABLE clinical.condicion (
    condition_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT REFERENCES paciente(patient_id),  -- FIX-7: was missing
    codigo_cie10        TEXT,
    descripcion         TEXT,
    estado_clinico      TEXT,
    verificacion        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_condicion_estadia ON clinical.condicion(stay_id);

-- FIX-8: plan_cuidado has CHECK on periodo_fin >= periodo_inicio
CREATE TABLE clinical.plan_cuidado (
    plan_id             TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    estado              TEXT CHECK (estado IN ('borrador', 'activo', 'completado')) DEFAULT 'borrador',
    periodo_inicio      DATE,
    periodo_fin         DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (periodo_fin IS NULL OR periodo_fin >= periodo_inicio)  -- FIX-8
);

CREATE INDEX idx_plan_cuidado_estadia ON clinical.plan_cuidado(stay_id);

CREATE TABLE clinical.requerimiento_cuidado (
    req_id              TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    tipo                TEXT REFERENCES tipo_requerimiento_ref(codigo),
    valor_normalizado   TEXT,
    activo              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_req_cuidado_plan ON clinical.requerimiento_cuidado(plan_id);

CREATE TABLE clinical.necesidad_profesional (
    need_id             TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    profesion_requerida TEXT,
    nivel_necesidad     TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_nec_prof_plan ON clinical.necesidad_profesional(plan_id);

CREATE TABLE clinical.meta (
    meta_id             TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    descripcion         TEXT,
    estado_ciclo        TEXT CHECK (estado_ciclo IS NULL OR estado_ciclo IN (
                            'propuesta', 'aceptada', 'en_progreso', 'lograda', 'cancelada'
                        )),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- procedimiento: visit_id FK added in SECTION 5 (cross-layer)
CREATE TABLE clinical.procedimiento (
    proc_id             TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK to visita added in SECTION 5
    stay_id             TEXT REFERENCES estadia(stay_id),
    patient_id          TEXT REFERENCES paciente(patient_id),
    codigo              TEXT,
    descripcion         TEXT,
    estado              TEXT CHECK (estado IS NULL OR estado IN (
                            'programado', 'realizado', 'cancelado', 'parcial'
                        )),
    realizado_en        TIMESTAMPTZ,
    prestacion_id       TEXT REFERENCES catalogo_prestacion(prestacion_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_procedimiento_visita ON clinical.procedimiento(visit_id);
CREATE INDEX idx_procedimiento_estadia ON clinical.procedimiento(stay_id);
CREATE INDEX idx_procedimiento_patient_id ON clinical.procedimiento(patient_id);

-- observacion: visit_id FK added in SECTION 5
CREATE TABLE clinical.observacion (
    obs_id              TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK to visita added in SECTION 5
    stay_id             TEXT REFERENCES estadia(stay_id),
    patient_id          TEXT REFERENCES paciente(patient_id),
    categoria           TEXT,
    codigo              TEXT REFERENCES codigo_observacion_ref(codigo),
    valor               TEXT,
    unidad              TEXT,
    efectivo_en         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_observacion_visita ON clinical.observacion(visit_id);
CREATE INDEX idx_observacion_stay_id ON clinical.observacion(stay_id);
CREATE INDEX idx_observacion_patient_id ON clinical.observacion(patient_id);

-- medicacion: visit_id FK added in SECTION 5
CREATE TABLE clinical.medicacion (
    med_id              TEXT PRIMARY KEY,
    stay_id             TEXT REFERENCES estadia(stay_id),
    visit_id            TEXT,  -- FK to visita added in SECTION 5
    medicamento_codigo  TEXT,
    medicamento_nombre  TEXT,
    via                 TEXT CHECK (via IS NULL OR via IN (
                            'oral', 'IV', 'SC', 'IM', 'topica',
                            'inhalatoria', 'SNG', 'rectal', 'sublingual', 'transdermica'
                        )),
    estado_cadena       TEXT CHECK (estado_cadena IS NULL OR estado_cadena IN (
                            'prescrita', 'dispensada', 'administrada'
                        )),
    dosis               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_medicacion_estadia ON clinical.medicacion(stay_id);

CREATE TABLE clinical.dispositivo (
    device_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    tipo                TEXT CHECK (tipo IS NULL OR tipo IN (
                            'VVP', 'SNG', 'CUP', 'DRENAJE', 'CONCENTRADOR_O2',
                            'BOMBA_IV', 'MONITOR', 'GLUCOMETRO', 'OTRO'
                        )),
    estado              TEXT,
    serial              TEXT,
    asignado_desde      DATE,
    asignado_hasta      DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dispositivo_paciente ON clinical.dispositivo(patient_id);

-- documentacion: visit_id FK added in SECTION 5
CREATE TABLE clinical.documentacion (
    doc_id              TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK to visita added in SECTION 5
    stay_id             TEXT REFERENCES estadia(stay_id),
    patient_id          TEXT REFERENCES paciente(patient_id),
    tipo                TEXT REFERENCES tipo_documento_ref(codigo),
    estado              TEXT CHECK (estado IS NULL OR estado IN ('pendiente', 'completo', 'verificado')),
    fecha               DATE,
    ruta_archivo        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documentacion_visita ON clinical.documentacion(visit_id);
CREATE INDEX idx_documentacion_estadia ON clinical.documentacion(stay_id);
CREATE INDEX idx_documentacion_paciente ON clinical.documentacion(patient_id);
CREATE INDEX idx_documentacion_tipo ON clinical.documentacion(tipo);

CREATE TABLE clinical.alerta (
    alerta_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    categoria           TEXT,
    codigo              TEXT,
    estado              TEXT CHECK (estado IS NULL OR estado IN ('activa', 'resuelta', 'ignorada')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerta_paciente ON clinical.alerta(patient_id);

CREATE TABLE clinical.encuesta_satisfaccion (
    encuesta_id             TEXT PRIMARY KEY,
    patient_id              TEXT REFERENCES paciente(patient_id),
    stay_id                 TEXT REFERENCES estadia(stay_id),
    marca_temporal          TIMESTAMPTZ,
    encuestado_nombre       TEXT,
    encuestado_parentesco   TEXT,
    fecha_encuesta          DATE,
    -- Satisfacción general (Likert 1-5)
    satisfaccion_ingreso        TEXT,
    satisfaccion_equipo_general TEXT,
    satisfaccion_oportunidad    TEXT,
    satisfaccion_informacion    TEXT,
    satisfaccion_trato          TEXT,
    satisfaccion_unidad         TEXT,
    -- Educación al alta por profesional (SI/NO)
    educacion_enfermera     TEXT,
    educacion_kinesiologo   TEXT,
    educacion_fonoaudiologo TEXT,
    -- Valoración global
    valoracion_mejoria      TEXT CHECK (valoracion_mejoria IS NULL OR valoracion_mejoria IN ('TOTALMENTE', 'ALGO', 'NADA')),
    asistencia_telefonica   TEXT,
    volveria                TEXT CHECK (volveria IS NULL OR volveria IN ('si', 'probablemente_si', 'probablemente_no', 'no')),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_encuesta_estadia ON clinical.encuesta_satisfaccion(stay_id);

-- RC-1: Consentimiento informado
CREATE TABLE clinical.consentimiento (
    consent_id          TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'hospitalizacion_domiciliaria', 'procedimiento',
                            'retiro_voluntario', 'registro_audiovisual'
                        )),
    decision            TEXT NOT NULL CHECK (decision IN ('aceptado', 'rechazado')),
    fecha               DATE NOT NULL,
    firmante_nombre     TEXT,
    firmante_rut        TEXT,
    firmante_parentesco TEXT,
    provider_id         TEXT REFERENCES profesional(provider_id),
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consentimiento_paciente ON clinical.consentimiento(patient_id);
CREATE INDEX idx_consentimiento_estadia ON clinical.consentimiento(stay_id);

-- RC-2: Valoración de ingreso
CREATE TABLE clinical.valoracion_ingreso (
    assessment_id       TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'enfermeria', 'kinesiologia', 'fonoaudiologia',
                            'terapia_ocupacional', 'medica', 'tens'
                        )),
    fecha               DATE NOT NULL,
    antecedentes_morbidos   TEXT,
    medicamentos_cronicos   TEXT,
    historia_ingreso        TEXT,
    valores_examenes        TEXT,
    alergias                TEXT,
    diagnostico_enfermeria  TEXT,
    plan_atencion           TEXT,
    servicio_origen         TEXT,
    nro_postulacion         TEXT,
    funcionalidad_previa    TEXT,
    evaluacion_motora       TEXT,
    evaluacion_respiratoria TEXT,
    dependencia_kinesica_motora       TEXT,
    dependencia_kinesica_respiratoria TEXT,
    objetivos_kine          TEXT,
    indicacion_kine         TEXT,
    observaciones           TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_valoracion_estadia ON clinical.valoracion_ingreso(stay_id);
CREATE INDEX idx_valoracion_tipo ON clinical.valoracion_ingreso(tipo);
CREATE INDEX idx_valoracion_ingreso_patient_id ON clinical.valoracion_ingreso(patient_id);

-- RC-3: Hallazgos de valoración
CREATE TABLE clinical.valoracion_hallazgo (
    hallazgo_id         TEXT PRIMARY KEY,
    assessment_id       TEXT NOT NULL REFERENCES valoracion_ingreso(assessment_id),
    dominio             TEXT NOT NULL REFERENCES dominio_hallazgo_ref(codigo),
    codigo              TEXT,
    valor               TEXT,
    valor_opciones      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hallazgo_assessment ON clinical.valoracion_hallazgo(assessment_id);
CREATE INDEX idx_hallazgo_dominio ON clinical.valoracion_hallazgo(dominio);

-- RC-4: Checklist de ingreso
CREATE TABLE clinical.checklist_ingreso (
    checklist_item_id   TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    item                TEXT NOT NULL CHECK (item IN (
                            'firma_consentimiento_informado',
                            'bienvenida_educacion_hodom',
                            'familiar_responsable_presente',
                            'interconsultas_horas_pendientes',
                            'medicamentos_despachados',
                            'portador_elementos_invasivos',
                            'lesiones_en_piel',
                            'tratamientos_indicados'
                        )),
    cumplido            TEXT NOT NULL CHECK (cumplido IN ('si', 'no', 'na')),
    observacion         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_checklist_estadia ON clinical.checklist_ingreso(stay_id);

-- RC-5: Herida activa
CREATE TABLE clinical.herida (
    herida_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    tipo_herida         TEXT NOT NULL CHECK (tipo_herida IN (
                            'lpp', 'pie_diabetico', 'herida_operatoria',
                            'ulcera_venosa', 'ulcera_arterial', 'quemadura', 'otra'
                        )),
    ubicacion           TEXT,
    grado               TEXT,
    fecha_inicio        DATE,
    fecha_cierre        DATE,
    estado              TEXT CHECK (estado IN ('activa', 'en_cicatrizacion', 'cerrada', 'infectada')) DEFAULT 'activa',
    tipo_curacion       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_inicio)
);

CREATE INDEX idx_herida_paciente ON clinical.herida(patient_id);
CREATE INDEX idx_herida_estadia ON clinical.herida(stay_id);
CREATE INDEX idx_herida_estado ON clinical.herida(estado);
CREATE INDEX idx_herida_activas ON clinical.herida(patient_id) WHERE estado = 'activa';

-- RC-6: Seguimiento de herida por sesión
CREATE TABLE clinical.seguimiento_herida (
    seguimiento_id      TEXT PRIMARY KEY,
    herida_id           TEXT NOT NULL REFERENCES herida(herida_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    lugar_grado         TEXT,
    exudacion           TEXT,
    tipo_tejido         TEXT,
    caracteristica_tamano TEXT,
    aposito_primario    TEXT,
    aposito_secundario  TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_seg_herida ON clinical.seguimiento_herida(herida_id);
CREATE INDEX idx_seg_herida_fecha ON clinical.seguimiento_herida(fecha);
CREATE INDEX idx_seguimiento_herida_visit_id ON clinical.seguimiento_herida(visit_id);

-- RC-7: Evaluación funcional
CREATE TABLE clinical.evaluacion_funcional (
    eval_id             TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    momento             TEXT NOT NULL CHECK (momento IN ('ingreso', 'semanal', 'egreso', 'seguimiento')),
    fecha               DATE NOT NULL,
    barthel_score       INTEGER CHECK (barthel_score IS NULL OR (barthel_score >= 0 AND barthel_score <= 100)),
    barthel_categoria   TEXT CHECK (barthel_categoria IS NULL OR barthel_categoria IN (
                            'independiente', 'leve', 'moderada', 'severa', 'total'
                        )),
    dependencia_motora          TEXT,
    dependencia_respiratoria    TEXT,
    hito_motor          TEXT CHECK (hito_motor IS NULL OR hito_motor IN (
                            'cama', 'sedente_en_cama', 'sedente_borde_cama',
                            'sedente_en_silla', 'bipedo',
                            'marcha_estatica', 'marcha_dinamica'
                        )),
    df_score            TEXT,
    autocuidado         TEXT CHECK (autocuidado IS NULL OR autocuidado IN (
                            'autovalente', 'semidependiente', 'postrado'
                        )),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_eval_func_estadia ON clinical.evaluacion_funcional(stay_id);
CREATE INDEX idx_eval_func_momento ON clinical.evaluacion_funcional(momento);
CREATE INDEX idx_evaluacion_funcional_patient_id ON clinical.evaluacion_funcional(patient_id);

-- RC-8: Nota de evolución
CREATE TABLE clinical.nota_evolucion (
    nota_id             TEXT PRIMARY KEY,
    visit_id            TEXT REFERENCES visita(visit_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'enfermeria', 'kinesiologia', 'fonoaudiologia',
                            'terapia_ocupacional', 'medica', 'trabajo_social', 'tens'
                        )),
    fecha               DATE NOT NULL,
    hora                TEXT,
    notas_clinicas      TEXT,
    plan_enfermeria     TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_nota_visita ON clinical.nota_evolucion(visit_id);
CREATE INDEX idx_nota_estadia ON clinical.nota_evolucion(stay_id);
CREATE INDEX idx_nota_tipo ON clinical.nota_evolucion(tipo);
CREATE INDEX idx_nota_evolucion_patient_id ON clinical.nota_evolucion(patient_id);

-- RC-9: Sesión de rehabilitación
CREATE TABLE clinical.sesion_rehabilitacion (
    sesion_id           TEXT PRIMARY KEY,
    visit_id            TEXT REFERENCES visita(visit_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'kinesiologia_respiratoria', 'kinesiologia_motora',
                            'terapia_ocupacional', 'fonoaudiologia'
                        )),
    fecha               DATE NOT NULL,
    hora                TEXT,
    regimen             TEXT,
    ayuno               TEXT,
    csv_spo2            REAL,
    csv_fr              REAL,
    csv_fc              REAL,
    csv_pa              TEXT,
    csv_hgt             REAL,
    csv_dolor_ena       REAL CHECK (csv_dolor_ena IS NULL OR (csv_dolor_ena >= 0 AND csv_dolor_ena <= 10)),
    estado_general      TEXT,
    oxigenoterapia_fio2 REAL,
    auscultacion_mp     TEXT,
    tos                 TEXT,
    resultado           TEXT CHECK (resultado IS NULL OR resultado IN (
                            'bien_tolerado', 'aviso_a_personal',
                            'incidentes', 'finaliza_sin_incidentes'
                        )),
    queda_contenido     TEXT CHECK (queda_contenido IS NULL OR queda_contenido IN ('si', 'no')),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sesion_rehab_estadia ON clinical.sesion_rehabilitacion(stay_id);
CREATE INDEX idx_sesion_rehab_tipo ON clinical.sesion_rehabilitacion(tipo);
CREATE INDEX idx_sesion_rehab_visita ON clinical.sesion_rehabilitacion(visit_id);
CREATE INDEX idx_sesion_rehabilitacion_patient_id ON clinical.sesion_rehabilitacion(patient_id);

-- RC-10: Ítems de sesión de rehabilitación
CREATE TABLE clinical.sesion_rehabilitacion_item (
    sesion_item_id      TEXT PRIMARY KEY,
    sesion_id           TEXT NOT NULL REFERENCES sesion_rehabilitacion(sesion_id),
    categoria           TEXT NOT NULL REFERENCES categoria_rehabilitacion_ref(codigo),
    realizado           BOOLEAN NOT NULL DEFAULT TRUE,
    valor               TEXT,
    observacion         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sesion_item ON clinical.sesion_rehabilitacion_item(sesion_id);

-- RC-11: Seguimiento de dispositivo invasivo
CREATE TABLE clinical.seguimiento_dispositivo (
    seguimiento_id      TEXT PRIMARY KEY,
    device_id           TEXT NOT NULL REFERENCES dispositivo(device_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    cambio_realizado    BOOLEAN DEFAULT FALSE,
    fecha_instalacion   DATE,
    signos_infeccion    TEXT CHECK (signos_infeccion IS NULL OR signos_infeccion IN (
                            'ausentes', 'flebitis_grado_1', 'flebitis_grado_2',
                            'flebitis_grado_3', 'infeccion_local', 'infeccion_sistemica'
                        )),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_seg_dispositivo ON clinical.seguimiento_dispositivo(device_id);
CREATE INDEX idx_seg_dispositivo_visita ON clinical.seguimiento_dispositivo(visit_id);
CREATE INDEX idx_seguimiento_dispositivo_provider_id ON clinical.seguimiento_dispositivo(provider_id);

-- A0: Indicación médica
CREATE TABLE clinical.indicacion_medica (
    indicacion_id       TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    hora                TEXT,
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'farmacologica', 'dieta', 'actividad', 'oxigenoterapia',
                            'curacion', 'monitorizacion', 'interconsulta',
                            'examen', 'procedimiento', 'otra'
                        )),
    descripcion         TEXT NOT NULL,
    medicamento         TEXT,
    dosis               TEXT,
    via                 TEXT CHECK (via IS NULL OR via IN (
                            'oral', 'IV', 'SC', 'IM', 'topica', 'inhalatoria', 'SNG', 'rectal'
                        )),
    frecuencia          TEXT,
    dilucion            TEXT,
    duracion            TEXT,
    o2_flujo_lpm        REAL,
    o2_dispositivo      TEXT CHECK (o2_dispositivo IS NULL OR o2_dispositivo IN (
                            'naricera', 'mascarilla_venturi', 'mascarilla_alto_flujo',
                            'concentrador', 'balon'
                        )),
    o2_horas_dia        REAL,
    estado              TEXT CHECK (estado IN ('activa', 'suspendida', 'completada', 'modificada')) DEFAULT 'activa',
    fecha_suspension    DATE,
    motivo_suspension   TEXT,
    indicacion_previa_id TEXT REFERENCES indicacion_medica(indicacion_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_indicacion_estadia ON clinical.indicacion_medica(stay_id);
CREATE INDEX idx_indicacion_tipo ON clinical.indicacion_medica(tipo);
CREATE INDEX idx_indicacion_estado ON clinical.indicacion_medica(estado);
CREATE INDEX idx_indicacion_activas ON clinical.indicacion_medica(stay_id) WHERE estado = 'activa';

-- A1: Receta médica
CREATE TABLE clinical.receta (
    receta_id           TEXT PRIMARY KEY,
    indicacion_id       TEXT REFERENCES indicacion_medica(indicacion_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    medicamento         TEXT NOT NULL,
    forma_farmaceutica  TEXT,
    concentracion       TEXT,
    dosis               TEXT NOT NULL,
    via                 TEXT CHECK (via IS NULL OR via IN (
                            'oral', 'IV', 'SC', 'IM', 'topica', 'inhalatoria',
                            'SNG', 'rectal', 'sublingual', 'transdermica'
                        )),
    frecuencia          TEXT NOT NULL,
    duracion_dias       INTEGER,
    cantidad_total      TEXT,
    tipo_receta         TEXT CHECK (tipo_receta IN ('simple', 'retenida', 'cheque')) DEFAULT 'simple',
    es_controlado       BOOLEAN DEFAULT FALSE,
    estado              TEXT CHECK (estado IN ('vigente', 'dispensada', 'vencida', 'anulada')) DEFAULT 'vigente',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_receta_estadia ON clinical.receta(stay_id);
CREATE INDEX idx_receta_estado ON clinical.receta(estado);
CREATE INDEX idx_receta_patient_id ON clinical.receta(patient_id);

-- A2: Dispensación
CREATE TABLE clinical.dispensacion (
    dispensacion_id     TEXT PRIMARY KEY,
    receta_id           TEXT REFERENCES receta(receta_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    fecha               DATE NOT NULL,
    medicamento         TEXT NOT NULL,
    cantidad_dispensada TEXT,
    lote                TEXT,
    fecha_vencimiento   DATE,
    dispensador         TEXT,
    receptor            TEXT,
    receptor_parentesco TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dispensacion_receta ON clinical.dispensacion(receta_id);
CREATE INDEX idx_dispensacion_estadia ON clinical.dispensacion(stay_id);
CREATE INDEX idx_dispensacion_patient_id ON clinical.dispensacion(patient_id);

-- A3: Botiquín domiciliario
CREATE TABLE clinical.botiquin_domiciliario (
    botiquin_item_id    TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    medicamento         TEXT NOT NULL,
    forma_farmaceutica  TEXT,
    cantidad_actual     TEXT,
    fecha_vencimiento   DATE,
    condicion_almacenamiento TEXT,
    requiere_devolucion BOOLEAN DEFAULT FALSE,
    estado              TEXT CHECK (estado IN ('activo', 'agotado', 'devuelto', 'descartado')) DEFAULT 'activo',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_botiquin_paciente ON clinical.botiquin_domiciliario(patient_id);
CREATE INDEX idx_botiquin_domiciliario_stay_id ON clinical.botiquin_domiciliario(stay_id);

-- B1: Equipo médico
CREATE TABLE clinical.equipo_medico (
    equipo_id           TEXT PRIMARY KEY,
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'cama_clinica', 'colchon_antiescaras', 'concentrador_o2',
                            'balon_o2', 'bomba_infusion', 'aspirador_secreciones',
                            'nebulizador', 'oximetro', 'glucometro', 'tensiometro',
                            'monitor_signos', 'silla_ruedas', 'andador', 'baston',
                            'mesa_comer_cama', 'porta_suero', 'otro'
                        )),
    marca               TEXT,
    modelo              TEXT,
    serial              TEXT,
    numero_inventario   TEXT,
    fecha_adquisicion   DATE,
    proveedor           TEXT,
    estado              TEXT CHECK (estado IN (
                            'disponible', 'prestado', 'en_mantencion',
                            'de_baja', 'extraviado'
                        )) DEFAULT 'disponible',
    ubicacion_actual    TEXT,
    proxima_mantencion  DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_equipo_tipo ON clinical.equipo_medico(tipo);
CREATE INDEX idx_equipo_estado ON clinical.equipo_medico(estado);

-- B2: Préstamo de equipo
CREATE TABLE clinical.prestamo_equipo (
    prestamo_id         TEXT PRIMARY KEY,
    equipo_id           TEXT NOT NULL REFERENCES equipo_medico(equipo_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    fecha_entrega       DATE NOT NULL,
    entregado_por       TEXT REFERENCES profesional(provider_id),
    recibido_por        TEXT,
    condicion_entrega   TEXT,
    fecha_devolucion    DATE,
    devuelto_a          TEXT,
    condicion_devolucion TEXT,
    estado              TEXT CHECK (estado IN ('prestado', 'devuelto', 'extraviado', 'dañado')) DEFAULT 'prestado',
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prestamo_equipo ON clinical.prestamo_equipo(equipo_id);
CREATE INDEX idx_prestamo_paciente ON clinical.prestamo_equipo(patient_id);
CREATE INDEX idx_prestamo_estado ON clinical.prestamo_equipo(estado);
CREATE INDEX idx_prestamo_equipo_stay_id ON clinical.prestamo_equipo(stay_id);
CREATE INDEX idx_prestamo_activos ON clinical.prestamo_equipo(patient_id) WHERE estado = 'prestado';

-- B3: Oxigenoterapia domiciliaria
CREATE TABLE clinical.oxigenoterapia_domiciliaria (
    oxigeno_id          TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    flujo_lpm           REAL NOT NULL,
    horas_dia           REAL,
    dispositivo         TEXT CHECK (dispositivo IN (
                            'naricera', 'mascarilla_venturi', 'mascarilla_reservorio',
                            'mascarilla_alto_flujo', 'canula_traqueostomia'
                        )),
    fuente              TEXT CHECK (fuente IN (
                            'concentrador', 'balon_fijo', 'balon_portatil',
                            'concentrador_portatil', 'oxigeno_liquido'
                        )),
    equipo_id           TEXT REFERENCES equipo_medico(equipo_id),
    proveedor_o2        TEXT,
    capacidad_litros    REAL,
    fecha_ultimo_recambio DATE,
    consumo_estimado_dia REAL,
    estado              TEXT CHECK (estado IN ('activo', 'suspendido', 'finalizado')) DEFAULT 'activo',
    fecha_inicio        DATE NOT NULL,
    fecha_fin           DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_o2_paciente ON clinical.oxigenoterapia_domiciliaria(patient_id);
CREATE INDEX idx_o2_estado ON clinical.oxigenoterapia_domiciliaria(estado);
CREATE INDEX idx_oxigenoterapia_domiciliaria_stay_id ON clinical.oxigenoterapia_domiciliaria(stay_id);

-- C1: Solicitud de examen
CREATE TABLE clinical.solicitud_examen (
    solicitud_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    solicitante_id      TEXT REFERENCES profesional(provider_id),
    fecha_solicitud     DATE NOT NULL,
    tipo_examen         TEXT NOT NULL CHECK (tipo_examen IN (
                            'laboratorio', 'imagenologia', 'electrocardiograma',
                            'anatomia_patologica', 'microbiologia', 'otro'
                        )),
    examenes_solicitados TEXT NOT NULL,
    prioridad           TEXT REFERENCES prioridad_ref(codigo) DEFAULT 'rutina',
    diagnostico_presuntivo TEXT,
    indicaciones_preparacion TEXT,
    estado              TEXT CHECK (estado IN (
                            'solicitado', 'muestra_tomada', 'enviado_laboratorio',
                            'resultado_disponible', 'cancelado'
                        )) DEFAULT 'solicitado',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_solicitud_examen_estadia ON clinical.solicitud_examen(stay_id);
CREATE INDEX idx_solicitud_examen_estado ON clinical.solicitud_examen(estado);
CREATE INDEX idx_solicitud_examen_patient_id ON clinical.solicitud_examen(patient_id);

-- C2: Toma de muestra
CREATE TABLE clinical.toma_muestra (
    muestra_id          TEXT PRIMARY KEY,
    solicitud_id        TEXT NOT NULL REFERENCES solicitud_examen(solicitud_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    tomador_id          TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    hora                TEXT,
    tipo_muestra        TEXT,
    condicion_paciente  TEXT,
    incidencias         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_muestra_solicitud ON clinical.toma_muestra(solicitud_id);

-- C3: Resultado de examen
CREATE TABLE clinical.resultado_examen (
    resultado_id        TEXT PRIMARY KEY,
    solicitud_id        TEXT NOT NULL REFERENCES solicitud_examen(solicitud_id),
    fecha_resultado     DATE NOT NULL,
    examen              TEXT NOT NULL,
    valor               TEXT,
    unidad              TEXT,
    rango_referencia    TEXT,
    interpretacion      TEXT CHECK (interpretacion IS NULL OR interpretacion IN (
                            'normal', 'bajo', 'alto', 'critico', 'indeterminado'
                        )),
    informe_texto       TEXT,
    laboratorio         TEXT,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_resultado_solicitud ON clinical.resultado_examen(solicitud_id);

-- D: Lista de espera
-- FIX-10: establecimiento_origen references establecimiento
CREATE TABLE clinical.lista_espera (
    espera_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    fecha_solicitud     DATE NOT NULL,
    establecimiento_origen TEXT REFERENCES establecimiento(establecimiento_id),  -- FIX-10
    servicio_origen     TEXT,
    profesional_solicitante TEXT,
    diagnostico         TEXT,
    motivo_solicitud    TEXT,
    prioridad           TEXT REFERENCES prioridad_ref(codigo) DEFAULT 'normal',
    requiere_o2         BOOLEAN DEFAULT FALSE,
    requiere_curaciones BOOLEAN DEFAULT FALSE,
    fecha_evaluacion    DATE,
    evaluador_id        TEXT REFERENCES profesional(provider_id),
    resultado_evaluacion TEXT CHECK (resultado_evaluacion IS NULL OR resultado_evaluacion IN (
                            'elegible', 'no_elegible', 'pendiente_informacion', 'en_evaluacion'
                        )),
    motivo_no_elegible  TEXT,
    estado              TEXT CHECK (estado IN (
                            'en_espera', 'en_evaluacion', 'elegible',
                            'ingresado', 'rechazado', 'desistido', 'fallecido_espera'
                        )) DEFAULT 'en_espera',
    fecha_resolucion    DATE,
    stay_id             TEXT REFERENCES estadia(stay_id),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lista_espera_estado ON clinical.lista_espera(estado);
CREATE INDEX idx_lista_espera_prioridad ON clinical.lista_espera(prioridad);
CREATE INDEX idx_lista_espera_patient_id ON clinical.lista_espera(patient_id);

-- E1: Evento adverso
CREATE TABLE clinical.evento_adverso (
    evento_id           TEXT PRIMARY KEY,
    patient_id          TEXT REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    tipo                TEXT NOT NULL REFERENCES tipo_evento_adverso_ref(codigo),
    severidad           TEXT NOT NULL CHECK (severidad IN (
                            'sin_daño', 'leve', 'moderado', 'grave', 'muerte'
                        )),
    fecha_evento        DATE NOT NULL,
    hora_evento         TEXT,
    lugar               TEXT,
    descripcion         TEXT NOT NULL,
    circunstancias      TEXT,
    detectado_por_id    TEXT REFERENCES profesional(provider_id),
    fecha_reporte       DATE NOT NULL,
    accion_inmediata    TEXT,
    requirio_traslado   BOOLEAN DEFAULT FALSE,
    causa_raiz          TEXT,
    acciones_correctivas TEXT,
    estado              TEXT CHECK (estado IN ('reportado', 'en_investigacion', 'cerrado')) DEFAULT 'reportado',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evento_adverso_tipo ON clinical.evento_adverso(tipo);
CREATE INDEX idx_evento_adverso_paciente ON clinical.evento_adverso(patient_id);
CREATE INDEX idx_evento_adverso_severidad ON clinical.evento_adverso(severidad);

-- E2: Notificación obligatoria
CREATE TABLE clinical.notificacion_obligatoria (
    notificacion_id     TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    tipo                TEXT NOT NULL CHECK (tipo IN ('eno', 'iaas', 'brote', 'ram')),
    fecha_notificacion  DATE NOT NULL,
    notificador_id      TEXT REFERENCES profesional(provider_id),
    diagnostico         TEXT NOT NULL,
    codigo_cie10        TEXT,
    descripcion         TEXT,
    notificado_a        TEXT,
    numero_formulario   TEXT,
    estado              TEXT CHECK (estado IN ('notificada', 'confirmada', 'descartada')) DEFAULT 'notificada',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notificacion_tipo ON clinical.notificacion_obligatoria(tipo);
CREATE INDEX idx_notificacion_obligatoria_patient_id ON clinical.notificacion_obligatoria(patient_id);

-- F: Educación paciente/cuidador
CREATE TABLE clinical.educacion_paciente (
    educacion_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    fecha               DATE NOT NULL,
    tema                TEXT NOT NULL REFERENCES tema_educacion_ref(codigo),
    descripcion         TEXT,
    material_entregado  TEXT,
    receptor            TEXT CHECK (receptor IN ('paciente', 'cuidador', 'ambos')),
    comprension         TEXT CHECK (comprension IS NULL OR comprension IN (
                            'adecuada', 'parcial', 'insuficiente', 'no_evaluada'
                        )),
    requiere_refuerzo   BOOLEAN DEFAULT FALSE,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_educacion_estadia ON clinical.educacion_paciente(stay_id);
CREATE INDEX idx_educacion_tema ON clinical.educacion_paciente(tema);
CREATE INDEX idx_educacion_paciente_patient_id ON clinical.educacion_paciente(patient_id);

-- G1: Evaluación paliativa
CREATE TABLE clinical.evaluacion_paliativa (
    eval_paliativa_id   TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    esas_dolor          INTEGER CHECK (esas_dolor IS NULL OR (esas_dolor >= 0 AND esas_dolor <= 10)),
    esas_fatiga         INTEGER CHECK (esas_fatiga IS NULL OR (esas_fatiga >= 0 AND esas_fatiga <= 10)),
    esas_nausea         INTEGER CHECK (esas_nausea IS NULL OR (esas_nausea >= 0 AND esas_nausea <= 10)),
    esas_depresion      INTEGER CHECK (esas_depresion IS NULL OR (esas_depresion >= 0 AND esas_depresion <= 10)),
    esas_ansiedad       INTEGER CHECK (esas_ansiedad IS NULL OR (esas_ansiedad >= 0 AND esas_ansiedad <= 10)),
    esas_somnolencia    INTEGER CHECK (esas_somnolencia IS NULL OR (esas_somnolencia >= 0 AND esas_somnolencia <= 10)),
    esas_apetito        INTEGER CHECK (esas_apetito IS NULL OR (esas_apetito >= 0 AND esas_apetito <= 10)),
    esas_disnea         INTEGER CHECK (esas_disnea IS NULL OR (esas_disnea >= 0 AND esas_disnea <= 10)),
    esas_bienestar      INTEGER CHECK (esas_bienestar IS NULL OR (esas_bienestar >= 0 AND esas_bienestar <= 10)),
    esas_total          INTEGER,
    karnofsky_score     INTEGER CHECK (karnofsky_score IS NULL OR (karnofsky_score >= 0 AND karnofsky_score <= 100)),
    pps_score           INTEGER CHECK (pps_score IS NULL OR (pps_score >= 0 AND pps_score <= 100)),
    intencion_paliativa BOOLEAN DEFAULT FALSE,
    sedacion_paliativa  BOOLEAN DEFAULT FALSE,
    plan_paliativo      TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_eval_paliativa_estadia ON clinical.evaluacion_paliativa(stay_id);
CREATE INDEX idx_evaluacion_paliativa_patient_id ON clinical.evaluacion_paliativa(patient_id);

-- G2: Voluntad anticipada
CREATE TABLE clinical.voluntad_anticipada (
    voluntad_id         TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    fecha               DATE NOT NULL,
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'rechazo_tratamiento', 'limitacion_esfuerzo_terapeutico',
                            'orden_no_reanimar', 'directiva_anticipada_general',
                            'designacion_representante'
                        )),
    descripcion         TEXT,
    firmante_paciente   BOOLEAN DEFAULT TRUE,
    representante_nombre TEXT,
    representante_rut   TEXT,
    representante_parentesco TEXT,
    testigo_1_nombre    TEXT,
    testigo_2_nombre    TEXT,
    provider_id         TEXT REFERENCES profesional(provider_id),
    estado              TEXT CHECK (estado IN ('vigente', 'revocada')) DEFAULT 'vigente',
    fecha_revocacion    DATE,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_voluntad_paciente ON clinical.voluntad_anticipada(patient_id);
CREATE INDEX idx_voluntad_anticipada_stay_id ON clinical.voluntad_anticipada(stay_id);

-- H: Teleconsulta
CREATE TABLE clinical.teleconsulta (
    teleconsulta_id     TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    hora_inicio         TEXT,
    hora_fin            TEXT,
    modalidad           TEXT NOT NULL CHECK (modalidad IN (
                            'sincrona_video', 'sincrona_telefono', 'asincrona', 'telemonitoreo'
                        )),
    plataforma          TEXT,
    motivo              TEXT,
    hallazgos           TEXT,
    indicaciones        TEXT,
    resultado           TEXT CHECK (resultado IS NULL OR resultado IN (
                            'resuelto', 'requiere_visita_presencial',
                            'derivacion', 'seguimiento_telefonico'
                        )),
    participante_paciente BOOLEAN DEFAULT TRUE,
    participante_cuidador BOOLEAN DEFAULT FALSE,
    participante_otro   TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_teleconsulta_estadia ON clinical.teleconsulta(stay_id);
CREATE INDEX idx_teleconsulta_fecha ON clinical.teleconsulta(fecha);
CREATE INDEX idx_teleconsulta_patient_id ON clinical.teleconsulta(patient_id);

-- DM-1: Epicrisis
CREATE TABLE clinical.epicrisis (
    epicrisis_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha_emision       DATE NOT NULL,
    fecha_ingreso       DATE,
    fecha_egreso        DATE,
    tipo_egreso         TEXT CHECK (tipo_egreso IN (
                            'alta_clinica', 'fallecido_esperado', 'fallecido_no_esperado',
                            'reingreso', 'renuncia_voluntaria', 'alta_disciplinaria'
                        )),
    servicio_origen     TEXT,
    motivo_ingreso      TEXT,
    diagnostico_ingreso TEXT,
    anamnesis_resumen   TEXT,
    examen_fisico_ingreso TEXT,
    examenes_realizados TEXT,
    resumen_evolucion   TEXT NOT NULL,
    tratamiento_realizado TEXT,
    complicaciones      TEXT,
    condicion_egreso    TEXT CHECK (condicion_egreso IS NULL OR condicion_egreso IN (
                            'mejorado', 'estable', 'sin_cambios', 'deteriorado', 'fallecido'
                        )),
    indicaciones_alta   TEXT,
    medicamentos_alta   TEXT,
    dieta_alta          TEXT,
    actividad_alta      TEXT,
    cuidados_especiales TEXT,
    signos_alarma       TEXT,
    proximo_control     TEXT,
    derivacion_aps      TEXT,
    interconsultas_pendientes TEXT,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_epicrisis_estadia ON clinical.epicrisis(stay_id);
CREATE INDEX idx_epicrisis_paciente ON clinical.epicrisis(patient_id);
CREATE INDEX idx_epicrisis_provider_id ON clinical.epicrisis(provider_id);

-- DM-2: Diagnóstico de egreso
CREATE TABLE clinical.diagnostico_egreso (
    diag_id             TEXT PRIMARY KEY,
    epicrisis_id        TEXT NOT NULL REFERENCES epicrisis(epicrisis_id),
    tipo                TEXT NOT NULL CHECK (tipo IN ('principal', 'secundario', 'complicacion')),
    codigo_cie10        TEXT,
    descripcion         TEXT NOT NULL,
    codigo_snomed       TEXT,
    orden               INTEGER DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_diag_egreso_epicrisis ON clinical.diagnostico_egreso(epicrisis_id);
CREATE INDEX idx_diag_egreso_cie10 ON clinical.diagnostico_egreso(codigo_cie10);

-- DM-4: Informe social
CREATE TABLE clinical.informe_social (
    informe_id          TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    tipo                TEXT NOT NULL CHECK (tipo IN ('preliminar', 'completo')),
    fecha               DATE NOT NULL,
    n_integrantes_hogar INTEGER,
    composicion_familiar TEXT,
    cuidador_principal  TEXT,
    cuidador_parentesco TEXT,
    red_apoyo_familiar  TEXT,
    red_apoyo_comunitaria TEXT,
    tipo_vivienda       TEXT CHECK (tipo_vivienda IS NULL OR tipo_vivienda IN (
                            'casa', 'departamento', 'pieza', 'mediagua',
                            'vivienda_social', 'otro'
                        )),
    tenencia_vivienda   TEXT CHECK (tenencia_vivienda IS NULL OR tenencia_vivienda IN (
                            'propia', 'arrendada', 'cedida', 'allegado', 'otro'
                        )),
    servicios_basicos   TEXT,
    condiciones_sanitarias TEXT,
    accesibilidad       TEXT,
    rsh_tramo           TEXT CHECK (rsh_tramo IS NULL OR rsh_tramo IN (
                            '0-40', '41-50', '51-60', '61-70', '71-80', '81-90', '91-100',
                            'sin_calificacion'
                        )),
    prevision_social    TEXT,
    ingresos_hogar      TEXT,
    problematica_social TEXT,
    diagnostico_social  TEXT,
    plan_intervencion   TEXT,
    derivaciones        TEXT,
    observaciones       TEXT,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_informe_social_estadia ON clinical.informe_social(stay_id);
CREATE INDEX idx_informe_social_patient_id ON clinical.informe_social(patient_id);

-- DM-5: Interconsulta
CREATE TABLE clinical.interconsulta (
    interconsulta_id    TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    solicitante_id      TEXT REFERENCES profesional(provider_id),
    fecha_solicitud     DATE NOT NULL,
    prioridad           TEXT REFERENCES prioridad_ref(codigo),
    especialidad_destino TEXT NOT NULL,
    establecimiento_destino TEXT,
    motivo              TEXT NOT NULL,
    diagnostico_actual  TEXT,
    antecedentes_relevantes TEXT,
    pregunta_clinica    TEXT,
    examenes_adjuntos   TEXT,
    fecha_respuesta     DATE,
    respondedor         TEXT,
    respuesta           TEXT,
    recomendaciones     TEXT,
    estado              TEXT CHECK (estado IN (
                            'solicitada', 'aceptada', 'rechazada', 'respondida', 'cancelada'
                        )) DEFAULT 'solicitada',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ic_estadia ON clinical.interconsulta(stay_id);
CREATE INDEX idx_ic_estado ON clinical.interconsulta(estado);
CREATE INDEX idx_interconsulta_patient_id ON clinical.interconsulta(patient_id);

-- DM-6: Derivación y contrarreferencia
CREATE TABLE clinical.derivacion (
    derivacion_id       TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    tipo                TEXT NOT NULL CHECK (tipo IN (
                            'derivacion_ingreso', 'contrarreferencia_egreso', 'derivacion_interna'
                        )),
    fecha               DATE NOT NULL,
    establecimiento_origen  TEXT,
    servicio_origen         TEXT,
    profesional_origen      TEXT,
    establecimiento_destino TEXT,
    servicio_destino        TEXT,
    profesional_destino     TEXT,
    diagnostico         TEXT,
    motivo              TEXT NOT NULL,
    resumen_clinico     TEXT,
    indicaciones        TEXT,
    examenes_pendientes TEXT,
    medicamentos_actuales TEXT,
    estado              TEXT CHECK (estado IN ('emitida', 'recibida', 'aceptada', 'rechazada')) DEFAULT 'emitida',
    fecha_recepcion     DATE,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_derivacion_estadia ON clinical.derivacion(stay_id);
CREATE INDEX idx_derivacion_tipo ON clinical.derivacion(tipo);
CREATE INDEX idx_derivacion_patient_id ON clinical.derivacion(patient_id);

-- DM-7: Protocolo de fallecimiento
CREATE TABLE clinical.protocolo_fallecimiento (
    protocolo_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha_fallecimiento DATE NOT NULL,
    hora_fallecimiento  TEXT,
    lugar               TEXT CHECK (lugar IS NULL OR lugar IN ('domicilio', 'traslado_hospital', 'otro')),
    tipo                TEXT NOT NULL CHECK (tipo IN ('esperado', 'no_esperado')),
    intencion_paliativa BOOLEAN DEFAULT FALSE,
    causa_directa       TEXT,
    causa_antecedente_1 TEXT,
    causa_antecedente_2 TEXT,
    causa_contribuyente TEXT,
    codigo_cie10_causa  TEXT,
    certificado_defuncion TEXT,
    autopsia_solicitada BOOLEAN DEFAULT FALSE,
    familiar_notificado TEXT,
    parentesco_notificado TEXT,
    fecha_notificacion  DATE,
    doc_id              TEXT REFERENCES documentacion(doc_id),
    epicrisis_id        TEXT REFERENCES epicrisis(epicrisis_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_protocolo_estadia ON clinical.protocolo_fallecimiento(stay_id);
CREATE INDEX idx_protocolo_fallecimiento_patient_id ON clinical.protocolo_fallecimiento(patient_id);

-- K: GES/AUGE
CREATE TABLE clinical.garantia_ges (
    ges_id              TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    numero_problema_ges INTEGER,
    nombre_problema     TEXT NOT NULL,
    codigo_cie10        TEXT,
    fecha_sospecha      DATE,
    fecha_confirmacion  DATE,
    fecha_garantia_acceso DATE,
    fecha_atencion      DATE,
    estado              TEXT CHECK (estado IN (
                            'sospecha', 'confirmado', 'en_tratamiento',
                            'alta_ges', 'incumplimiento_garantia'
                        )),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ges_paciente ON clinical.garantia_ges(patient_id);
CREATE INDEX idx_garantia_ges_stay_id ON clinical.garantia_ges(stay_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4: Operational tables (operational schema)
-- profesional through registro_llamada
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE operational.profesional (
    provider_id         TEXT PRIMARY KEY,
    rut                 TEXT,
    nombre              TEXT NOT NULL,
    profesion           TEXT CHECK (profesion IN (
                            'ENFERMERIA', 'KINESIOLOGIA', 'FONOAUDIOLOGIA', 'MEDICO',
                            'TRABAJO_SOCIAL', 'TENS', 'NUTRICION', 'MATRONA',
                            'PSICOLOGIA', 'TERAPIA_OCUPACIONAL'
                        )),
    profesion_rem       TEXT CHECK (profesion_rem IS NULL OR profesion_rem IN (
                            'medico', 'enfermera', 'tecnico_enfermeria', 'matrona',
                            'kinesiologo', 'psicologo', 'fonoaudiologo',
                            'trabajador_social', 'terapeuta_ocupacional'
                        )),
    competencias        TEXT,
    vehiculo            TEXT,
    comunas_cobertura   TEXT,
    max_visitas_dia     INTEGER,
    base_lat            REAL,
    base_lng            REAL,
    estado              TEXT CHECK (estado IS NULL OR estado IN ('activo', 'inactivo', 'licencia_medica')),
    contrato            TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profesional_profesion ON operational.profesional(profesion);

CREATE TABLE operational.agenda_profesional (
    schedule_id         TEXT PRIMARY KEY,
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    fecha               DATE NOT NULL,
    hora_inicio         TEXT,
    hora_fin            TEXT,
    tipo                TEXT CHECK (tipo IN ('TURNO', 'GUARDIA', 'EXTRA', 'BLOQUEADO')),
    motivo_bloqueo      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_agenda_provider ON operational.agenda_profesional(provider_id);
CREATE INDEX idx_agenda_fecha ON operational.agenda_profesional(fecha);

CREATE TABLE operational.sla (
    sla_id              TEXT PRIMARY KEY,
    service_type        TEXT NOT NULL REFERENCES service_type_ref(service_type),
    prioridad           TEXT REFERENCES prioridad_ref(codigo),
    max_hrs_primera_visita  INTEGER,
    frecuencia_minima       TEXT,
    duracion_minima_min     INTEGER,
    ventana_horaria         TEXT,
    max_perdidas_consecutivas INTEGER,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sla_lookup ON operational.sla(service_type, prioridad);

CREATE TABLE operational.insumo (
    item_id             TEXT PRIMARY KEY,
    nombre              TEXT NOT NULL,
    categoria           TEXT CHECK (categoria IN ('CURACION', 'MEDICAMENTO', 'EQUIPO', 'OXIGENO', 'DESCARTABLE')),
    peso_kg             REAL,
    requiere_vehiculo   BOOLEAN DEFAULT FALSE,
    stock_actual        INTEGER,
    umbral_reposicion   INTEGER,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE operational.orden_servicio (
    order_id            TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    service_type        TEXT REFERENCES service_type_ref(service_type),
    profesion_requerida TEXT,
    frecuencia          TEXT,
    duracion_est_min    INTEGER,
    prioridad           TEXT REFERENCES prioridad_ref(codigo),
    requiere_continuidad BOOLEAN DEFAULT FALSE,
    provider_asignado   TEXT REFERENCES profesional(provider_id),
    requiere_vehiculo   BOOLEAN DEFAULT FALSE,
    ventana_preferida   TEXT,
    fecha_inicio        DATE,
    fecha_fin           DATE,
    estado              TEXT CHECK (estado IS NULL OR estado IN (
                            'borrador', 'activa', 'completada', 'cancelada', 'suspendida'
                        )),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE INDEX idx_orden_estadia ON operational.orden_servicio(stay_id);
CREATE INDEX idx_orden_paciente ON operational.orden_servicio(patient_id);
CREATE INDEX idx_orden_service_type ON operational.orden_servicio(service_type);

-- I1: Vehículos (single definition)
CREATE TABLE operational.vehiculo (
    vehiculo_id         TEXT PRIMARY KEY,
    patente             TEXT NOT NULL,
    marca               TEXT,
    modelo              TEXT,
    anio                INTEGER,
    tipo                TEXT CHECK (tipo IN ('auto', 'furgon', 'ambulancia', 'otro')),
    capacidad_pasajeros INTEGER,
    capacidad_carga_kg  REAL,
    estado              TEXT CHECK (estado IN (
                            'operativo', 'en_mantencion', 'de_baja', 'siniestrado'
                        )) DEFAULT 'operativo',
    km_actual           REAL,
    proxima_revision_tecnica DATE,
    seguro_vigente_hasta DATE,
    gps_device_name     TEXT,
    gps_plataforma      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- I2: Conductores (single definition)
CREATE TABLE operational.conductor (
    conductor_id        TEXT PRIMARY KEY,
    rut                 TEXT,
    nombre              TEXT NOT NULL,
    licencia_clase      TEXT,
    licencia_vencimiento DATE,
    telefono            TEXT,
    estado              TEXT CHECK (estado IN ('activo', 'inactivo', 'licencia_medica')) DEFAULT 'activo',
    vehiculo_asignado   TEXT REFERENCES vehiculo(vehiculo_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conductor_vehiculo_asignado ON operational.conductor(vehiculo_asignado);

CREATE TABLE operational.ruta (
    route_id            TEXT PRIMARY KEY,
    provider_id         TEXT REFERENCES profesional(provider_id),
    conductor_id        TEXT REFERENCES conductor(conductor_id),
    fecha               DATE NOT NULL,
    estado              TEXT CHECK (estado IS NULL OR estado IN (
                            'planificada', 'en_curso', 'completada', 'cancelada'
                        )),
    origen_lat          REAL,
    origen_lng          REAL,
    hora_salida_plan    TEXT,
    hora_salida_real    TEXT,
    km_totales          REAL,
    minutos_viaje       REAL,
    minutos_atencion    REAL,
    ratio_viaje_atencion REAL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ruta_provider ON operational.ruta(provider_id);
CREATE INDEX idx_ruta_fecha ON operational.ruta(fecha);

CREATE TABLE operational.visita (
    visit_id            TEXT PRIMARY KEY,
    order_id            TEXT REFERENCES orden_servicio(order_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    route_id            TEXT REFERENCES ruta(route_id),
    location_id         TEXT REFERENCES ubicacion(location_id),
    seq_en_ruta         INTEGER,
    fecha               DATE NOT NULL,
    hora_plan_inicio    TEXT,
    hora_plan_fin       TEXT,
    hora_real_inicio    TEXT,
    hora_real_fin       TEXT,
    gps_lat             REAL,
    gps_lng             REAL,
    estado              TEXT CHECK (estado IN (
                            'PROGRAMADA', 'ASIGNADA', 'DESPACHADA', 'EN_RUTA',
                            'LLEGADA', 'EN_ATENCION', 'COMPLETA', 'PARCIAL',
                            'NO_REALIZADA', 'DOCUMENTADA', 'VERIFICADA',
                            'REPORTADA_REM', 'CANCELADA'
                        )),
    resultado           TEXT CHECK (resultado IS NULL OR resultado IN (
                            'satisfactorio', 'parcial', 'sin_cambios', 'deterioro', 'derivado'
                        )),
    motivo_no_realizada TEXT,
    doc_estado          TEXT CHECK (doc_estado IS NULL OR doc_estado IN (
                            'pendiente', 'completo', 'verificado'
                        )),
    rem_reportable      BOOLEAN DEFAULT FALSE,
    prestacion_id       TEXT REFERENCES catalogo_prestacion(prestacion_id),
    rem_prestacion      TEXT,  -- DEPRECATED: código MAI legacy, usar prestacion_id
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_visita_paciente ON operational.visita(patient_id);
CREATE INDEX idx_visita_estadia ON operational.visita(stay_id);
CREATE INDEX idx_visita_fecha ON operational.visita(fecha);
CREATE INDEX idx_visita_provider ON operational.visita(provider_id);
CREATE INDEX idx_visita_ruta ON operational.visita(route_id);
CREATE INDEX idx_visita_estado ON operational.visita(estado);
CREATE INDEX idx_visita_rem ON operational.visita(rem_reportable, fecha);
CREATE INDEX idx_visita_pendientes ON operational.visita(fecha, stay_id) WHERE estado IN ('PROGRAMADA', 'ASIGNADA');

CREATE TABLE operational.evento_visita (
    event_id            TEXT PRIMARY KEY,
    visit_id            TEXT NOT NULL REFERENCES visita(visit_id),
    timestamp           TIMESTAMPTZ NOT NULL,
    estado_previo       TEXT,
    estado_nuevo        TEXT,
    lat                 REAL,
    lng                 REAL,
    origen              TEXT,
    detalle             TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evento_visita ON operational.evento_visita(visit_id);

CREATE TABLE operational.decision_despacho (
    decision_id         TEXT PRIMARY KEY,
    visit_id            TEXT NOT NULL REFERENCES visita(visit_id),
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    decision            TEXT CHECK (decision IN ('asignado', 'rechazado', 'reasignado')),
    score_skill         REAL,
    score_distancia     REAL,
    score_continuidad   REAL,
    score_carga         REAL,
    score_total         REAL,
    motivo_rechazo      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_despacho_visita ON operational.decision_despacho(visit_id);

-- Evento estadia (single definition)
CREATE TABLE operational.evento_estadia (
    event_id            TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    timestamp           TIMESTAMPTZ NOT NULL,
    estado_previo       TEXT,
    estado_nuevo        TEXT CHECK (estado_nuevo IN (
                            'pendiente_evaluacion', 'elegible', 'admitido',
                            'activo', 'egresado', 'fallecido'
                        )),
    proceso_opm         TEXT CHECK (proceso_opm IS NULL OR proceso_opm IN (
                            'eligibility_evaluating', 'patient_admitting',
                            'care_planning', 'therapeutic_plan_executing',
                            'clinical_evolution_monitoring', 'patient_discharging',
                            'post_discharge_following'
                        )),
    detalle             TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evento_estadia ON operational.evento_estadia(stay_id);

-- Junction: requerimiento -> orden (single definition)
CREATE TABLE operational.requerimiento_orden_mapping (
    req_id              TEXT NOT NULL REFERENCES requerimiento_cuidado(req_id),
    order_id            TEXT NOT NULL REFERENCES orden_servicio(order_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (req_id, order_id)
);

-- Junction: orden_servicio <-> insumo (single definition)
CREATE TABLE operational.orden_servicio_insumo (
    order_id            TEXT NOT NULL REFERENCES orden_servicio(order_id),
    item_id             TEXT NOT NULL REFERENCES insumo(item_id),
    cantidad            INTEGER DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_id, item_id)
);

-- Junction: zona <-> profesional (single definition)
CREATE TABLE operational.zona_profesional (
    zone_id             TEXT NOT NULL REFERENCES zona(zone_id),
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (zone_id, provider_id)
);

-- Junction: episodios fuente (single definition)
CREATE TABLE operational.estadia_episodio_fuente (
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    episode_id          TEXT NOT NULL,
    source_origin       TEXT,  -- raw, form_rescued, alta_rescued, merged
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (stay_id, episode_id)
);

CREATE INDEX idx_estadia_episodio ON operational.estadia_episodio_fuente(stay_id);

-- DM-8: Entrega de turno
CREATE TABLE operational.entrega_turno (
    entrega_id          TEXT PRIMARY KEY,
    fecha               DATE NOT NULL,
    turno_saliente_id   TEXT REFERENCES profesional(provider_id),
    turno_entrante_id   TEXT REFERENCES profesional(provider_id),
    pacientes_activos   INTEGER,
    novedades_generales TEXT,
    pendientes          TEXT,
    alertas             TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_entrega_turno_fecha ON operational.entrega_turno(fecha);

-- DM-8b: Detalle paciente en entrega de turno
CREATE TABLE operational.entrega_turno_paciente (
    entrega_paciente_id TEXT PRIMARY KEY,
    entrega_id          TEXT NOT NULL REFERENCES entrega_turno(entrega_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    estado_resumen      TEXT,
    novedades           TEXT,
    pendientes          TEXT,
    prioridad           TEXT REFERENCES prioridad_ref(codigo),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_entrega_paciente ON operational.entrega_turno_paciente(entrega_id);
CREATE INDEX idx_entrega_turno_paciente_patient_id ON operational.entrega_turno_paciente(patient_id);
CREATE INDEX idx_entrega_turno_paciente_stay_id ON operational.entrega_turno_paciente(stay_id);

-- Registro de llamadas telefónicas
CREATE TABLE operational.registro_llamada (
    llamada_id          TEXT PRIMARY KEY,
    fecha               DATE NOT NULL,
    hora                TEXT,
    duracion            TEXT,
    telefono            TEXT,
    motivo              TEXT CHECK (motivo IS NULL OR motivo IN (
                            'resultado_examen', 'asistencia_social', 'consulta_clinica',
                            'seguimiento', 'coordinacion', 'otro'
                        )),
    patient_id          TEXT REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    nombre_familiar     TEXT,
    parentesco_familiar TEXT,
    estado_paciente     TEXT CHECK (estado_paciente IS NULL OR estado_paciente IN ('activo', 'egresado')),
    tipo                TEXT CHECK (tipo IN ('emitida', 'recibida')),
    provider_id         TEXT REFERENCES profesional(provider_id),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_llamada_paciente ON operational.registro_llamada(patient_id);
CREATE INDEX idx_llamada_fecha ON operational.registro_llamada(fecha);
CREATE INDEX idx_llamada_provider ON operational.registro_llamada(provider_id);

-- M1: Capacitación
CREATE TABLE operational.capacitacion (
    capacitacion_id     TEXT PRIMARY KEY,
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    nombre              TEXT NOT NULL,
    tipo                TEXT CHECK (tipo IN (
                            'induccion_hd', 'curacion_avanzada', 'manejo_dispositivos',
                            'oxigenoterapia', 'cuidados_paliativos', 'reanimacion_basica',
                            'manejo_emergencias', 'telemedicina', 'normativa_legal',
                            'autocuidado_equipo', 'otro'
                        )),
    fecha               DATE NOT NULL,
    horas               REAL,
    institucion         TEXT,
    certificado         BOOLEAN DEFAULT FALSE,
    fecha_vencimiento   DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_capacitacion_provider ON operational.capacitacion(provider_id);

-- M2: Reuniones de equipo
CREATE TABLE operational.reunion_equipo (
    reunion_id          TEXT PRIMARY KEY,
    fecha               DATE NOT NULL,
    tipo                TEXT CHECK (tipo IN (
                            'clinica', 'coordinacion', 'comite_calidad', 'capacitacion', 'otra'
                        )),
    lugar               TEXT,
    temas_tratados      TEXT,
    acuerdos            TEXT,
    tareas_asignadas    TEXT,
    n_asistentes        INTEGER,
    asistentes          TEXT,
    acta_doc_id         TEXT REFERENCES documentacion(doc_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reunion_fecha ON operational.reunion_equipo(fecha);

-- J1: Canasta valorizada
CREATE TABLE operational.canasta_valorizada (
    valorizacion_id     TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    periodo             TEXT NOT NULL,
    dias_cama           INTEGER DEFAULT 0,
    visitas_realizadas  INTEGER DEFAULT 0,
    procedimientos      INTEGER DEFAULT 0,
    examenes            INTEGER DEFAULT 0,
    costo_rrhh          REAL DEFAULT 0,
    costo_insumos       REAL DEFAULT 0,
    costo_medicamentos  REAL DEFAULT 0,
    costo_oxigeno       REAL DEFAULT 0,
    costo_transporte    REAL DEFAULT 0,
    costo_examenes      REAL DEFAULT 0,
    costo_total         REAL DEFAULT 0,
    valor_canasta_mai   REAL,
    diferencia          REAL,
    generado_en         TIMESTAMPTZ,
    fuente_visitas      INTEGER,
    fuente_procedimientos INTEGER,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_canasta_estadia ON operational.canasta_valorizada(stay_id);
CREATE INDEX idx_canasta_periodo ON operational.canasta_valorizada(periodo);
CREATE INDEX idx_canasta_valorizada_patient_id ON operational.canasta_valorizada(patient_id);

-- J2: Compras de servicio
CREATE TABLE operational.compra_servicio (
    compra_id           TEXT PRIMARY KEY,
    patient_id          TEXT REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    proveedor           TEXT NOT NULL,
    tipo_servicio       TEXT NOT NULL CHECK (tipo_servicio IN (
                            'oxigeno', 'insumos_curacion', 'medicamentos',
                            'equipamiento', 'laboratorio', 'imagenologia',
                            'transporte', 'otro'
                        )),
    descripcion         TEXT NOT NULL,
    cantidad            TEXT,
    costo_unitario      REAL,
    costo_total         REAL,
    orden_compra        TEXT,
    factura             TEXT,
    fecha               DATE NOT NULL,
    estado              TEXT CHECK (estado IN ('solicitada', 'aprobada', 'recibida', 'pagada')) DEFAULT 'solicitada',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compra_tipo ON operational.compra_servicio(tipo_servicio);

-- N: Configuración del programa
CREATE TABLE operational.configuracion_programa (
    config_id           TEXT PRIMARY KEY,
    clave               TEXT NOT NULL UNIQUE,
    valor               TEXT NOT NULL,
    descripcion         TEXT,
    tipo_dato           TEXT CHECK (tipo_dato IN ('texto', 'numero', 'fecha', 'boolean', 'json')),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO operational.configuracion_programa (config_id, clave, valor, descripcion, tipo_dato) VALUES
    ('CFG001', 'programa.nombre',                'HODOM Hospital San Carlos',                 'Nombre del programa',                  'texto'),
    ('CFG002', 'programa.establecimiento_id',    'E001',                                      'Código DEIS del establecimiento',      'texto'),
    ('CFG003', 'programa.cupos_programados',     '22',                                        'Cupos programados totales',            'numero'),
    ('CFG004', 'programa.horario_atencion',      '08:00-19:00',                               'Horario atención lunes a domingo',     'texto'),
    ('CFG005', 'programa.horario_llamadas',      '08:00-17:00 L-J, 08:00-16:00 V',           'Horario de llamadas',                  'texto'),
    ('CFG006', 'programa.telefono',              '42 2586292',                                'Teléfono de contacto',                 'texto'),
    ('CFG007', 'programa.estadia_maxima_dias',   '8',                                         'Estadía máxima según CI (6-8 días)',   'numero'),
    ('CFG008', 'programa.distancia_maxima_km',   '20',                                        'Distancia máxima cobertura (OPM SD1.1)','numero'),
    ('CFG009', 'programa.edad_minima',           '18',                                        'Edad mínima ingreso',                  'numero'),
    ('CFG010', 'programa.modo_operacional',      'full-weekday,reduced-weekend',              'Modos operacionales OPM SD10',         'texto')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 5: Cross-layer FK constraints (ALTER TABLE)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Clinical tables referencing operational.visita
ALTER TABLE clinical.procedimiento
    ADD CONSTRAINT fk_procedimiento_visita FOREIGN KEY (visit_id) REFERENCES visita(visit_id);

ALTER TABLE clinical.observacion
    ADD CONSTRAINT fk_observacion_visita FOREIGN KEY (visit_id) REFERENCES visita(visit_id);

ALTER TABLE clinical.medicacion
    ADD CONSTRAINT fk_medicacion_visita FOREIGN KEY (visit_id) REFERENCES visita(visit_id);

ALTER TABLE clinical.documentacion
    ADD CONSTRAINT fk_documentacion_visita FOREIGN KEY (visit_id) REFERENCES visita(visit_id);

-- END PART 1

-- =============================================================================
-- HODOM Modelo Integrado v4 — DDL PostgreSQL (Part 2)
-- Reporting, Telemetry, Triggers, Views, MVs, Indexes, Roles, RLS
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 6: Reporting tables (reporting schema)
-- ═══════════════════════════════════════════════════════════════════════════════

-- REM A21 C.1.1 — Personas atendidas por componente
CREATE TABLE reporting.rem_personas_atendidas (
    periodo             TEXT NOT NULL,  -- 'YYYY-MM'
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    componente          TEXT NOT NULL,
    total_ingresos      INTEGER DEFAULT 0,
    total_egresos       INTEGER DEFAULT 0,
    dias_cama           INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (periodo, establecimiento_id, componente)
);

-- REM A21 C.1.2 — Visitas por profesión
CREATE TABLE reporting.rem_visitas (
    periodo             TEXT NOT NULL,  -- 'YYYY-MM'
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    profesion_rem       TEXT NOT NULL,
    total_visitas       INTEGER DEFAULT 0,
    visitas_realizadas  INTEGER DEFAULT 0,
    visitas_canceladas  INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (periodo, establecimiento_id, profesion_rem)
);

-- REM A21 C.1.3 — Cupos programados y utilizados
CREATE TABLE reporting.rem_cupos (
    periodo             TEXT NOT NULL,  -- 'YYYY-MM'
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    componente          TEXT NOT NULL,
    cupos_programados   INTEGER DEFAULT 0,
    cupos_utilizados    INTEGER DEFAULT 0,
    porcentaje_uso      REAL,
    dias_cama_disponibles INTEGER DEFAULT 0,
    dias_cama_utilizados  INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (periodo, establecimiento_id, componente)
);

-- KPI diario por zona — FIX C3: FK to establecimiento
CREATE TABLE reporting.kpi_diario (
    fecha               DATE NOT NULL,
    zone_id             TEXT NOT NULL REFERENCES zona(zone_id),
    establecimiento_id  TEXT REFERENCES establecimiento(establecimiento_id),  -- FIX C3
    pacientes_activos   INTEGER DEFAULT 0,
    visitas_programadas INTEGER DEFAULT 0,
    visitas_realizadas  INTEGER DEFAULT 0,
    visitas_canceladas  INTEGER DEFAULT 0,
    tasa_realizacion    REAL,
    km_totales          REAL DEFAULT 0,
    minutos_viaje       REAL DEFAULT 0,
    minutos_atencion    REAL DEFAULT 0,
    ratio_viaje_atencion REAL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (fecha, zone_id)
);

CREATE INDEX idx_kpi_diario_establecimiento ON reporting.kpi_diario(establecimiento_id);

-- Descomposición temporal de visita
CREATE TABLE reporting.descomposicion_temporal (
    visit_id            TEXT PRIMARY KEY REFERENCES visita(visit_id),
    minutos_desplazamiento REAL,
    minutos_espera      REAL,
    minutos_atencion    REAL,
    minutos_documentacion REAL,
    minutos_total       REAL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Reporte de cobertura
CREATE TABLE reporting.reporte_cobertura (
    cobertura_id        TEXT PRIMARY KEY,
    patient_id          TEXT REFERENCES paciente(patient_id),
    order_id            TEXT REFERENCES orden_servicio(order_id),
    periodo             TEXT,
    visitas_planificadas INTEGER DEFAULT 0,
    visitas_realizadas  INTEGER DEFAULT 0,
    visitas_canceladas  INTEGER DEFAULT 0,
    tasa_cobertura      REAL,
    gap_identificado    BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reporte_cobertura_paciente ON reporting.reporte_cobertura(patient_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 7: Telemetry tables (telemetry schema)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Dispositivo GPS
CREATE TABLE telemetry.telemetria_dispositivo (
    device_id           TEXT PRIMARY KEY,
    vehiculo_id         TEXT REFERENCES vehiculo(vehiculo_id),
    nombre              TEXT,
    plataforma          TEXT,
    imei                TEXT,
    activo              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_telemetria_dispositivo_vehiculo ON telemetry.telemetria_dispositivo(vehiculo_id);

-- Segmentos de telemetría (drive/stop)
CREATE TABLE telemetry.telemetria_segmento (
    segment_id          TEXT PRIMARY KEY,
    device_id           TEXT NOT NULL REFERENCES telemetria_dispositivo(device_id),
    route_id            TEXT REFERENCES ruta(route_id),
    visit_id            TEXT REFERENCES visita(visit_id),
    location_id         TEXT REFERENCES ubicacion(location_id),
    tipo                TEXT NOT NULL CHECK (tipo IN ('drive', 'stop')),
    start_at            TIMESTAMPTZ NOT NULL,
    end_at              TIMESTAMPTZ,
    start_lat           REAL,
    start_lng           REAL,
    end_lat             REAL,
    end_lng             REAL,
    distancia_km        REAL,
    duracion_seg        INTEGER,
    velocidad_max_kmh   REAL,
    geofences_in        JSONB,
    correlacion_score   REAL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_segmento_device ON telemetry.telemetria_segmento(device_id);
CREATE INDEX idx_segmento_start ON telemetry.telemetria_segmento(start_at);
CREATE INDEX idx_segmento_tipo ON telemetry.telemetria_segmento(tipo);
CREATE INDEX idx_segmento_ruta ON telemetry.telemetria_segmento(route_id);
CREATE INDEX idx_segmento_visita ON telemetry.telemetria_segmento(visit_id);

-- Resumen diario de telemetría
CREATE TABLE telemetry.telemetria_resumen_diario (
    resumen_id          TEXT PRIMARY KEY,
    device_id           TEXT NOT NULL REFERENCES telemetria_dispositivo(device_id),
    route_id            TEXT REFERENCES ruta(route_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    conductor_id        TEXT REFERENCES conductor(conductor_id),
    fecha               DATE NOT NULL,
    km_totales          REAL DEFAULT 0,
    minutos_drive       REAL DEFAULT 0,
    minutos_stop        REAL DEFAULT 0,
    n_segmentos_drive   INTEGER DEFAULT 0,
    n_segmentos_stop    INTEGER DEFAULT 0,
    n_stops_significativos INTEGER DEFAULT 0,
    velocidad_max_kmh   REAL,
    primer_movimiento   TIMESTAMPTZ,
    ultimo_movimiento   TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (device_id, fecha)
);

CREATE INDEX idx_resumen_diario_device ON telemetry.telemetria_resumen_diario(device_id);
CREATE INDEX idx_resumen_diario_fecha ON telemetry.telemetria_resumen_diario(fecha);
CREATE INDEX idx_resumen_diario_ruta ON telemetry.telemetria_resumen_diario(route_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 8: State machine seed data (reference schema)
-- maquina_estados_ref and maquina_estados_estadia_ref already created in
-- SECTION 1 with full seed data. Here we add additional
-- estado_maquina_config entries for tables with estado CHECK constraints.
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO reference.estado_maquina_config (tabla, tipo_maquina, enforcement, descripcion) VALUES
    ('estadia',                 'estadia', 'full',  'Guard trigger + evento_estadia transition validation'),
    ('condicion',               'estadia', 'none',  'estado_clinico is free text, no state machine'),
    ('plan_cuidado',            'estadia', 'soft',  'CHECK constraint only: borrador/activo/completado'),
    ('procedimiento',           'visita',  'soft',  'CHECK constraint only: programado/realizado/cancelado/parcial'),
    ('documentacion',           'visita',  'soft',  'CHECK constraint only: pendiente/completo/verificado'),
    ('alerta',                  'estadia', 'soft',  'CHECK constraint only: activa/resuelta/ignorada'),
    ('herida',                  'estadia', 'soft',  'CHECK constraint only: activa/en_cicatrizacion/cerrada/infectada'),
    ('indicacion_medica',       'estadia', 'soft',  'CHECK constraint only: activa/suspendida/completada/modificada'),
    ('receta',                  'estadia', 'soft',  'CHECK constraint only: vigente/dispensada/vencida/anulada'),
    ('solicitud_examen',        'estadia', 'soft',  'CHECK constraint only: solicitado/muestra_tomada/etc.'),
    ('interconsulta',           'estadia', 'soft',  'CHECK constraint only: solicitada/aceptada/rechazada/respondida/cancelada'),
    ('derivacion',              'estadia', 'soft',  'CHECK constraint only: emitida/recibida/aceptada/rechazada'),
    ('evento_adverso',          'estadia', 'soft',  'CHECK constraint only: reportado/en_investigacion/cerrado'),
    ('notificacion_obligatoria','estadia', 'soft',  'CHECK constraint only: notificada/confirmada/descartada'),
    ('garantia_ges',            'estadia', 'soft',  'CHECK constraint only: sospecha through incumplimiento_garantia'),
    ('equipo_medico',           'estadia', 'none',  'Equipment inventory, not patient lifecycle'),
    ('prestamo_equipo',         'estadia', 'soft',  'CHECK constraint only: prestado/devuelto/extraviado/dañado'),
    ('oxigenoterapia_domiciliaria','estadia','soft', 'CHECK constraint only: activo/suspendido/finalizado'),
    ('botiquin_domiciliario',   'estadia', 'soft',  'CHECK constraint only: activo/agotado/devuelto/descartado'),
    ('voluntad_anticipada',     'estadia', 'soft',  'CHECK constraint only: vigente/revocada'),
    ('teleconsulta',            'visita',  'soft',  'No estado column, resultado only'),
    ('vehiculo',                'estadia', 'none',  'Fleet management, not patient lifecycle'),
    ('conductor',               'estadia', 'none',  'Fleet management, not patient lifecycle'),
    ('ruta',                    'visita',  'soft',  'CHECK constraint only: planificada/en_curso/completada/cancelada'),
    ('compra_servicio',         'estadia', 'soft',  'CHECK constraint only: solicitada/aprobada/recibida/pagada')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 9: Trigger functions (22 functions)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ---------------------------------------------------------------------------
-- Pattern A: PE-1 coherence — patient_id in child matches estadia.patient_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_pe1()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_patient_id TEXT;
BEGIN
    SELECT patient_id INTO v_patient_id
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_patient_id IS NULL THEN
        RAISE EXCEPTION 'PE-1: stay_id % not found in estadia', NEW.stay_id;
    END IF;

    IF NEW.patient_id IS DISTINCT FROM v_patient_id THEN
        RAISE EXCEPTION 'PE-1: patient_id mismatch — record has %, estadia has %',
            NEW.patient_id, v_patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern B: Stay coherence — visit's stay_id matches the table's stay_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_stay_coherence()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_visit_stay_id TEXT;
BEGIN
    IF NEW.visit_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT stay_id INTO v_visit_stay_id
    FROM visita
    WHERE visit_id = NEW.visit_id;

    IF v_visit_stay_id IS NULL THEN
        RAISE EXCEPTION 'Stay coherence: visit_id % not found', NEW.visit_id;
    END IF;

    IF NEW.stay_id IS DISTINCT FROM v_visit_stay_id THEN
        RAISE EXCEPTION 'Stay coherence: stay_id mismatch — record has %, visit has %',
            NEW.stay_id, v_visit_stay_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern C1: Visit state transition validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_visita_transition()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM maquina_estados_ref
        WHERE from_state = NEW.estado_previo
          AND to_state   = NEW.estado_nuevo
    ) THEN
        RAISE EXCEPTION 'Invalid visita transition: % → %',
            NEW.estado_previo, NEW.estado_nuevo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern C2: Estadia state transition validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_estadia_transition()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM maquina_estados_estadia_ref
        WHERE from_state = NEW.estado_previo
          AND to_state   = NEW.estado_nuevo
    ) THEN
        RAISE EXCEPTION 'Invalid estadia transition: % → %',
            NEW.estado_previo, NEW.estado_nuevo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern C3: Guard — BEFORE UPDATE on estadia.estado (prevents direct writes)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION guard_estadia_estado()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        RAISE EXCEPTION 'Direct estado update on estadia is forbidden. Use evento_estadia.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern C4: Guard — BEFORE UPDATE on visita.estado (prevents direct writes)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION guard_visita_estado()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        RAISE EXCEPTION 'Direct estado update on visita is forbidden. Use evento_visita.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern D1: State sync — evento_visita → visita.estado
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_visita_estado()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    UPDATE visita SET estado = NEW.estado_nuevo, updated_at = NOW()
    WHERE visit_id = NEW.visit_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern D2: State sync — evento_estadia → estadia.estado
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_estadia_estado()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    UPDATE estadia SET estado = NEW.estado_nuevo, updated_at = NOW()
    WHERE stay_id = NEW.stay_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern D3: State sync — estadia.estado → paciente.estado_actual (FIX-15)
-- Handles BOTH egresado/fallecido AND activo transitions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_paciente_estado()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NEW.estado = 'activo' THEN
        UPDATE paciente SET estado_actual = 'activo', updated_at = NOW()
        WHERE patient_id = NEW.patient_id;
    ELSIF NEW.estado IN ('egresado', 'fallecido') THEN
        UPDATE paciente SET
            estado_actual = CASE
                WHEN NEW.estado = 'fallecido' THEN 'fallecido'
                WHEN EXISTS (
                    SELECT 1 FROM estadia
                    WHERE patient_id = NEW.patient_id
                      AND estado = 'activo'
                      AND stay_id != NEW.stay_id
                ) THEN 'activo'
                ELSE 'egresado'
            END,
            updated_at = NOW()
        WHERE patient_id = NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E1: PE-7 — encuesta_satisfaccion requires tipo_egreso set
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_encuesta_pe7()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    IF NEW.stay_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_tipo_egreso IS NULL THEN
        RAISE EXCEPTION 'PE-7: Cannot register encuesta_satisfaccion for stay_id % — estadia has no tipo_egreso (patient not yet discharged)', NEW.stay_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E2: Encuesta requires stay_id NOT NULL
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_encuesta_stay_required()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NEW.stay_id IS NULL THEN
        RAISE EXCEPTION 'encuesta_satisfaccion requires stay_id — cannot be NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E3: Profesional coherencia REM — NUTRICION mapping
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_profesional_coherencia_rem()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    -- NUTRICION has no profesion_rem mapping — must be NULL
    IF NEW.profesion = 'NUTRICION' AND NEW.profesion_rem IS NOT NULL THEN
        RAISE EXCEPTION 'Profesion NUTRICION has no REM mapping — profesion_rem must be NULL, got %',
            NEW.profesion_rem;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E4: Sesión rehabilitación — tipo vs profesión cross-validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_sesion_rehab_profesion()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_profesion TEXT;
BEGIN
    IF NEW.provider_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT profesion INTO v_profesion
    FROM profesional
    WHERE provider_id = NEW.provider_id;

    IF NEW.tipo IN ('kinesiologia_respiratoria', 'kinesiologia_motora')
       AND v_profesion IS DISTINCT FROM 'KINESIOLOGIA' THEN
        RAISE EXCEPTION 'Sesión tipo % requires KINESIOLOGIA, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    IF NEW.tipo = 'terapia_ocupacional'
       AND v_profesion IS DISTINCT FROM 'TERAPIA_OCUPACIONAL' THEN
        RAISE EXCEPTION 'Sesión tipo % requires TERAPIA_OCUPACIONAL, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    IF NEW.tipo = 'fonoaudiologia'
       AND v_profesion IS DISTINCT FROM 'FONOAUDIOLOGIA' THEN
        RAISE EXCEPTION 'Sesión tipo % requires FONOAUDIOLOGIA, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E5: Epicrisis sync — tipo_egreso must match estadia.tipo_egreso
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_epicrisis_sync_estadia()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_tipo_egreso IS NOT NULL AND NEW.tipo_egreso IS DISTINCT FROM v_tipo_egreso THEN
        RAISE EXCEPTION 'Epicrisis tipo_egreso (%) does not match estadia tipo_egreso (%)',
            NEW.tipo_egreso, v_tipo_egreso;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E6: Protocolo fallecimiento — FIX-9: cross-validate tipo with
-- estadia.tipo_egreso semantically
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_protocolo_tipo_egreso()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    -- First check: tipo_egreso must be a fallecido type
    IF v_tipo_egreso NOT IN ('fallecido_esperado', 'fallecido_no_esperado') THEN
        RAISE EXCEPTION 'FIX-9: protocolo_fallecimiento requires estadia.tipo_egreso IN (fallecido_esperado, fallecido_no_esperado), got %',
            v_tipo_egreso;
    END IF;

    -- Then cross-validate semantic alignment
    IF NEW.tipo = 'esperado' AND v_tipo_egreso != 'fallecido_esperado' THEN
        RAISE EXCEPTION 'FIX-9: protocolo.tipo=esperado but estadia.tipo_egreso=% (expected fallecido_esperado)',
            v_tipo_egreso;
    END IF;

    IF NEW.tipo = 'no_esperado' AND v_tipo_egreso != 'fallecido_no_esperado' THEN
        RAISE EXCEPTION 'FIX-9: protocolo.tipo=no_esperado but estadia.tipo_egreso=% (expected fallecido_no_esperado)',
            v_tipo_egreso;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E7: Visita rango temporal — fecha within estadia dates
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_visita_rango_temporal()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_fecha_ingreso DATE;
    v_fecha_egreso  DATE;
BEGIN
    SELECT fecha_ingreso, fecha_egreso INTO v_fecha_ingreso, v_fecha_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF NEW.fecha < v_fecha_ingreso THEN
        RAISE EXCEPTION 'Visita fecha (%) is before estadia fecha_ingreso (%)',
            NEW.fecha, v_fecha_ingreso;
    END IF;

    IF v_fecha_egreso IS NOT NULL AND NEW.fecha > v_fecha_egreso THEN
        RAISE EXCEPTION 'Visita fecha (%) is after estadia fecha_egreso (%)',
            NEW.fecha, v_fecha_egreso;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E8: Visita ruta provider — provider commutativity
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_visita_ruta_provider()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_ruta_provider TEXT;
BEGIN
    IF NEW.route_id IS NULL OR NEW.provider_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT provider_id INTO v_ruta_provider
    FROM ruta
    WHERE route_id = NEW.route_id;

    IF v_ruta_provider IS NOT NULL AND v_ruta_provider IS DISTINCT FROM NEW.provider_id THEN
        RAISE EXCEPTION 'Visita provider_id (%) does not match ruta provider_id (%)',
            NEW.provider_id, v_ruta_provider;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E9: REM cupos — RC-5 arithmetic validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_rem_cupos_rc5()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NEW.cupos_utilizados > NEW.cupos_programados THEN
        RAISE EXCEPTION 'RC-5: cupos_utilizados (%) > cupos_programados (%)',
            NEW.cupos_utilizados, NEW.cupos_programados;
    END IF;

    IF NEW.dias_cama_utilizados > NEW.dias_cama_disponibles THEN
        RAISE EXCEPTION 'RC-5: dias_cama_utilizados (%) > dias_cama_disponibles (%)',
            NEW.dias_cama_utilizados, NEW.dias_cama_disponibles;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern E10: Documentación coherencia — patient/stay coherence
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_documentacion_coherencia()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_estadia_patient TEXT;
BEGIN
    IF NEW.stay_id IS NULL OR NEW.patient_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT patient_id INTO v_estadia_patient
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_estadia_patient IS NOT NULL AND NEW.patient_id IS DISTINCT FROM v_estadia_patient THEN
        RAISE EXCEPTION 'Documentación patient_id (%) does not match estadia patient_id (%)',
            NEW.patient_id, v_estadia_patient;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern F1: INSERT guard — estadia initial state (FIX-5)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION guard_estadia_estado_insert()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NEW.estado IS DISTINCT FROM 'pendiente_evaluacion' THEN
        RAISE EXCEPTION 'FIX-5: New estadia must start as pendiente_evaluacion, got %', NEW.estado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Pattern F2: INSERT guard — visita initial state (FIX-5)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION guard_visita_estado_insert()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
BEGIN
    IF NEW.estado IS NOT NULL AND NEW.estado != 'PROGRAMADA' THEN
        RAISE EXCEPTION 'FIX-5: New visita must start as NULL or PROGRAMADA, got %', NEW.estado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Telemetry: Visita coherence (FIXED for TIMESTAMPTZ)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_telemetria_visita_coherence()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_visita_fecha DATE;
BEGIN
    IF NEW.visit_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT fecha INTO v_visita_fecha
    FROM visita
    WHERE visit_id = NEW.visit_id;

    IF v_visita_fecha IS NULL THEN
        RAISE EXCEPTION 'Telemetría segmento references non-existent visit_id %', NEW.visit_id;
    END IF;

    -- Compare dates using ::date cast for TIMESTAMPTZ columns
    IF NEW.start_at::date != v_visita_fecha THEN
        RAISE EXCEPTION 'Telemetría segmento start_at date (%) does not match visita fecha (%)',
            NEW.start_at::date, v_visita_fecha;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Telemetry: Ruta coherence — ruta.fecha = resumen.fecha
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_telemetria_ruta_coherence()
RETURNS TRIGGER
SET search_path = reference, territorial, clinical, operational, reporting, telemetry
AS $$
DECLARE
    v_ruta_fecha DATE;
BEGIN
    IF NEW.route_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT fecha INTO v_ruta_fecha
    FROM ruta
    WHERE route_id = NEW.route_id;

    IF v_ruta_fecha IS NULL THEN
        RAISE EXCEPTION 'Telemetría resumen references non-existent route_id %', NEW.route_id;
    END IF;

    IF NEW.fecha != v_ruta_fecha THEN
        RAISE EXCEPTION 'Telemetría resumen fecha (%) does not match ruta fecha (%)',
            NEW.fecha, v_ruta_fecha;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FIX-22: check_telemetria_segmento_ruta() intentionally omitted — was a no-op trigger.


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 10: Trigger bindings
-- ═══════════════════════════════════════════════════════════════════════════════

-- ---------------------------------------------------------------------------
-- PE-1 bindings (27 tables)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_visita_pe1
    BEFORE INSERT OR UPDATE ON operational.visita
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_orden_servicio_pe1
    BEFORE INSERT OR UPDATE ON operational.orden_servicio
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_epicrisis_pe1
    BEFORE INSERT OR UPDATE ON clinical.epicrisis
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_indicacion_medica_pe1
    BEFORE INSERT OR UPDATE ON clinical.indicacion_medica
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_informe_social_pe1
    BEFORE INSERT OR UPDATE ON clinical.informe_social
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_interconsulta_pe1
    BEFORE INSERT OR UPDATE ON clinical.interconsulta
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_derivacion_pe1
    BEFORE INSERT OR UPDATE ON clinical.derivacion
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_protocolo_fallecimiento_pe1
    BEFORE INSERT OR UPDATE ON clinical.protocolo_fallecimiento
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_consentimiento_pe1
    BEFORE INSERT OR UPDATE ON clinical.consentimiento
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_valoracion_ingreso_pe1
    BEFORE INSERT OR UPDATE ON clinical.valoracion_ingreso
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_sesion_rehabilitacion_pe1
    BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_nota_evolucion_pe1
    BEFORE INSERT OR UPDATE ON clinical.nota_evolucion
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_evaluacion_funcional_pe1
    BEFORE INSERT OR UPDATE ON clinical.evaluacion_funcional
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_herida_pe1
    BEFORE INSERT OR UPDATE ON clinical.herida
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_receta_pe1
    BEFORE INSERT OR UPDATE ON clinical.receta
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_dispensacion_pe1
    BEFORE INSERT OR UPDATE ON clinical.dispensacion
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_botiquin_domiciliario_pe1
    BEFORE INSERT OR UPDATE ON clinical.botiquin_domiciliario
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_prestamo_equipo_pe1
    BEFORE INSERT OR UPDATE ON clinical.prestamo_equipo
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_oxigenoterapia_domiciliaria_pe1
    BEFORE INSERT OR UPDATE ON clinical.oxigenoterapia_domiciliaria
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_solicitud_examen_pe1
    BEFORE INSERT OR UPDATE ON clinical.solicitud_examen
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_teleconsulta_pe1
    BEFORE INSERT OR UPDATE ON clinical.teleconsulta
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_canasta_valorizada_pe1
    BEFORE INSERT OR UPDATE ON operational.canasta_valorizada
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_educacion_paciente_pe1
    BEFORE INSERT OR UPDATE ON clinical.educacion_paciente
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_evaluacion_paliativa_pe1
    BEFORE INSERT OR UPDATE ON clinical.evaluacion_paliativa
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_garantia_ges_pe1
    BEFORE INSERT OR UPDATE ON clinical.garantia_ges
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

CREATE TRIGGER trg_entrega_turno_paciente_pe1
    BEFORE INSERT OR UPDATE ON operational.entrega_turno_paciente
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

-- FIX-3: PE-1 for encuesta_satisfaccion (was missing in v3)
CREATE TRIGGER trg_encuesta_satisfaccion_pe1
    BEFORE INSERT OR UPDATE ON clinical.encuesta_satisfaccion
    FOR EACH ROW EXECUTE FUNCTION check_pe1();

-- ---------------------------------------------------------------------------
-- Stay coherence bindings (6 tables)
-- FIX-4: observacion, nota_evolucion, sesion_rehabilitacion, educacion_paciente added
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_medicacion_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.medicacion
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

CREATE TRIGGER trg_procedimiento_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.procedimiento
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

-- FIX-4: New stay coherence triggers
CREATE TRIGGER trg_observacion_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.observacion
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

CREATE TRIGGER trg_nota_evolucion_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.nota_evolucion
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

CREATE TRIGGER trg_sesion_rehabilitacion_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

CREATE TRIGGER trg_educacion_paciente_stay_coherence
    BEFORE INSERT OR UPDATE ON clinical.educacion_paciente
    FOR EACH ROW EXECUTE FUNCTION check_stay_coherence();

-- ---------------------------------------------------------------------------
-- State machine triggers
-- ---------------------------------------------------------------------------

-- Guard triggers prevent direct estado changes
CREATE TRIGGER trg_estadia_guard_estado
    BEFORE UPDATE ON clinical.estadia
    FOR EACH ROW EXECUTE FUNCTION guard_estadia_estado();

CREATE TRIGGER trg_visita_guard_estado
    BEFORE UPDATE ON operational.visita
    FOR EACH ROW EXECUTE FUNCTION guard_visita_estado();

-- FIX-5: INSERT guard triggers for initial state validation
CREATE TRIGGER trg_estadia_guard_insert
    BEFORE INSERT ON clinical.estadia
    FOR EACH ROW EXECUTE FUNCTION guard_estadia_estado_insert();

CREATE TRIGGER trg_visita_guard_insert
    BEFORE INSERT ON operational.visita
    FOR EACH ROW EXECUTE FUNCTION guard_visita_estado_insert();

-- Transition validation on event tables
CREATE TRIGGER trg_evento_visita_transition
    BEFORE INSERT ON operational.evento_visita
    FOR EACH ROW EXECUTE FUNCTION check_visita_transition();

CREATE TRIGGER trg_evento_estadia_transition
    BEFORE INSERT ON operational.evento_estadia
    FOR EACH ROW EXECUTE FUNCTION check_estadia_transition();

-- State sync: event → parent table
CREATE TRIGGER trg_evento_visita_sync
    AFTER INSERT ON operational.evento_visita
    FOR EACH ROW EXECUTE FUNCTION sync_visita_estado();

CREATE TRIGGER trg_evento_estadia_sync
    AFTER INSERT ON operational.evento_estadia
    FOR EACH ROW EXECUTE FUNCTION sync_estadia_estado();

-- FIX-15: estadia → paciente.estado_actual sync
CREATE TRIGGER trg_estadia_sync_paciente
    AFTER UPDATE OF estado ON clinical.estadia
    FOR EACH ROW EXECUTE FUNCTION sync_paciente_estado();

-- ---------------------------------------------------------------------------
-- Special validation triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER trg_encuesta_pe7
    BEFORE INSERT OR UPDATE ON clinical.encuesta_satisfaccion
    FOR EACH ROW EXECUTE FUNCTION check_encuesta_pe7();

CREATE TRIGGER trg_encuesta_stay_required
    BEFORE INSERT OR UPDATE ON clinical.encuesta_satisfaccion
    FOR EACH ROW EXECUTE FUNCTION check_encuesta_stay_required();

CREATE TRIGGER trg_profesional_coherencia_rem
    BEFORE INSERT OR UPDATE ON operational.profesional
    FOR EACH ROW EXECUTE FUNCTION check_profesional_coherencia_rem();

CREATE TRIGGER trg_sesion_rehab_profesion
    BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion
    FOR EACH ROW EXECUTE FUNCTION check_sesion_rehab_profesion();

CREATE TRIGGER trg_epicrisis_sync_estadia
    BEFORE INSERT OR UPDATE ON clinical.epicrisis
    FOR EACH ROW EXECUTE FUNCTION check_epicrisis_sync_estadia();

CREATE TRIGGER trg_protocolo_tipo_egreso
    BEFORE INSERT OR UPDATE ON clinical.protocolo_fallecimiento
    FOR EACH ROW EXECUTE FUNCTION check_protocolo_tipo_egreso();

CREATE TRIGGER trg_visita_rango_temporal
    BEFORE INSERT OR UPDATE ON operational.visita
    FOR EACH ROW EXECUTE FUNCTION check_visita_rango_temporal();

CREATE TRIGGER trg_visita_ruta_provider
    BEFORE INSERT OR UPDATE ON operational.visita
    FOR EACH ROW EXECUTE FUNCTION check_visita_ruta_provider();

CREATE TRIGGER trg_rem_cupos_rc5
    BEFORE INSERT OR UPDATE ON reporting.rem_cupos
    FOR EACH ROW EXECUTE FUNCTION check_rem_cupos_rc5();

CREATE TRIGGER trg_documentacion_coherencia
    BEFORE INSERT OR UPDATE ON clinical.documentacion
    FOR EACH ROW EXECUTE FUNCTION check_documentacion_coherencia();

-- ---------------------------------------------------------------------------
-- Telemetry triggers
-- FIX-22: No binding for check_telemetria_segmento_ruta (removed no-op)
-- ---------------------------------------------------------------------------

CREATE TRIGGER trg_telemetria_segmento_visita
    BEFORE INSERT OR UPDATE ON telemetry.telemetria_segmento
    FOR EACH ROW EXECUTE FUNCTION check_telemetria_visita_coherence();

CREATE TRIGGER trg_telemetria_resumen_ruta
    BEFORE INSERT OR UPDATE ON telemetry.telemetria_resumen_diario
    FOR EACH ROW EXECUTE FUNCTION check_telemetria_ruta_coherence();


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 11: Views (7 regular views)
-- ═══════════════════════════════════════════════════════════════════════════════

-- FIX PG-S1: rem_reportable = TRUE (not = 1)
CREATE OR REPLACE VIEW v_consolidado_atenciones_diarias AS
SELECT
    v.fecha,
    v.stay_id,
    v.patient_id,
    p.nombre_completo,
    p.rut,
    v.provider_id,
    pr.nombre          AS profesional_nombre,
    pr.profesion,
    pr.profesion_rem,
    v.estado,
    v.resultado,
    v.hora_real_inicio,
    v.hora_real_fin,
    v.location_id,
    v.route_id,
    v.rem_reportable,
    v.prestacion_id
FROM visita v
JOIN paciente p ON v.patient_id = p.patient_id
LEFT JOIN profesional pr ON v.provider_id = pr.provider_id
WHERE v.rem_reportable = TRUE;

CREATE OR REPLACE VIEW v_pacientes_activos AS
SELECT
    p.patient_id,
    p.nombre_completo,
    p.rut,
    p.sexo,
    p.fecha_nacimiento,
    p.comuna,
    p.cesfam,
    p.estado_actual,
    e.stay_id,
    e.fecha_ingreso,
    e.estado             AS estado_estadia,
    e.diagnostico_principal,
    e.establecimiento_id,
    e.origen_derivacion,
    (CURRENT_DATE - e.fecha_ingreso) AS dias_estadia
FROM paciente p
JOIN estadia e ON p.patient_id = e.patient_id
WHERE e.estado = 'activo';

CREATE OR REPLACE VIEW v_pe1_violations AS
SELECT
    'visita'::text AS tabla,
    v.visit_id AS record_id,
    v.patient_id AS record_patient_id,
    e.patient_id AS estadia_patient_id,
    v.stay_id
FROM visita v
JOIN estadia e ON v.stay_id = e.stay_id
WHERE v.patient_id IS DISTINCT FROM e.patient_id

UNION ALL

SELECT
    'orden_servicio'::text,
    os.order_id,
    os.patient_id,
    e.patient_id,
    os.stay_id
FROM orden_servicio os
JOIN estadia e ON os.stay_id = e.stay_id
WHERE os.patient_id IS DISTINCT FROM e.patient_id

UNION ALL

SELECT
    'epicrisis'::text,
    ep.epicrisis_id,
    ep.patient_id,
    e.patient_id,
    ep.stay_id
FROM epicrisis ep
JOIN estadia e ON ep.stay_id = e.stay_id
WHERE ep.patient_id IS DISTINCT FROM e.patient_id;

CREATE OR REPLACE VIEW v_egresos_sin_epicrisis AS
SELECT
    e.stay_id,
    e.patient_id,
    p.nombre_completo,
    e.fecha_ingreso,
    e.fecha_egreso,
    e.tipo_egreso,
    e.estado
FROM estadia e
JOIN paciente p ON e.patient_id = p.patient_id
LEFT JOIN epicrisis ep ON e.stay_id = ep.stay_id
WHERE e.estado IN ('egresado', 'fallecido')
  AND ep.epicrisis_id IS NULL;

CREATE OR REPLACE VIEW v_telemetria_stops_correlacionados AS
SELECT
    ts.segment_id,
    ts.device_id,
    ts.start_at,
    ts.end_at,
    ts.duracion_seg,
    ts.start_lat,
    ts.start_lng,
    ts.visit_id,
    v.patient_id,
    v.provider_id,
    v.fecha        AS visita_fecha,
    v.estado       AS visita_estado,
    ts.correlacion_score
FROM telemetria_segmento ts
JOIN visita v ON ts.visit_id = v.visit_id
WHERE ts.tipo = 'stop'
  AND ts.visit_id IS NOT NULL;

CREATE OR REPLACE VIEW v_telemetria_stops_sin_match AS
SELECT
    ts.segment_id,
    ts.device_id,
    ts.start_at,
    ts.end_at,
    ts.duracion_seg,
    ts.start_lat,
    ts.start_lng,
    ts.route_id,
    ts.geofences_in
FROM telemetria_segmento ts
WHERE ts.tipo = 'stop'
  AND ts.visit_id IS NULL
  AND ts.duracion_seg > 300;

CREATE OR REPLACE VIEW v_telemetria_ruta_comparacion AS
SELECT
    r.route_id,
    r.fecha,
    r.provider_id,
    pr.nombre          AS profesional_nombre,
    r.km_totales       AS ruta_km,
    r.minutos_viaje    AS ruta_min_viaje,
    r.minutos_atencion AS ruta_min_atencion,
    trd.km_totales     AS gps_km,
    trd.minutos_drive  AS gps_min_drive,
    trd.minutos_stop   AS gps_min_stop,
    trd.n_stops_significativos,
    CASE WHEN r.km_totales > 0
         THEN ROUND((trd.km_totales / r.km_totales * 100)::numeric, 1)
         ELSE NULL
    END AS pct_km_match
FROM ruta r
LEFT JOIN telemetria_resumen_diario trd ON r.route_id = trd.route_id
LEFT JOIN profesional pr ON r.provider_id = pr.provider_id;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 12: Materialized views (3)
-- ═══════════════════════════════════════════════════════════════════════════════

-- FIX PG-S1: rem_reportable = TRUE
-- FIX PG-Q4: total_ingresos genuinely counts ingresos for the grouped period
CREATE MATERIALIZED VIEW mv_rem_personas_atendidas AS
SELECT
    TO_CHAR(v.fecha, 'YYYY-MM')   AS periodo,
    e.establecimiento_id,
    pr.profesion_rem,
    COUNT(DISTINCT v.visit_id)    AS total_visitas,
    COUNT(DISTINCT v.patient_id)  AS personas_atendidas,
    COUNT(DISTINCT v.stay_id)     AS estadias_atendidas,
    -- FIX PG-Q4: count estadias whose fecha_ingreso falls within THIS period
    COUNT(DISTINCT CASE
        WHEN TO_CHAR(e.fecha_ingreso, 'YYYY-MM') = TO_CHAR(v.fecha, 'YYYY-MM')
        THEN e.stay_id
    END)                          AS total_ingresos,
    COUNT(DISTINCT CASE
        WHEN e.fecha_egreso IS NOT NULL
         AND TO_CHAR(e.fecha_egreso, 'YYYY-MM') = TO_CHAR(v.fecha, 'YYYY-MM')
        THEN e.stay_id
    END)                          AS total_egresos
FROM visita v
JOIN estadia e ON v.stay_id = e.stay_id
LEFT JOIN profesional pr ON v.provider_id = pr.provider_id
WHERE v.rem_reportable = TRUE
GROUP BY
    TO_CHAR(v.fecha, 'YYYY-MM'),
    e.establecimiento_id,
    pr.profesion_rem;

CREATE UNIQUE INDEX idx_mv_rem_personas
    ON mv_rem_personas_atendidas (periodo, establecimiento_id, profesion_rem);

-- FIX PG-S1: rem_reportable = TRUE. DATE columns — no ::date casts needed.
CREATE MATERIALIZED VIEW mv_kpi_diario AS
SELECT
    v.fecha,
    u.zone_id,
    e.establecimiento_id,
    COUNT(DISTINCT v.visit_id)    AS total_visitas,
    COUNT(DISTINCT v.visit_id) FILTER (WHERE v.estado IN ('COMPLETA', 'DOCUMENTADA', 'VERIFICADA', 'REPORTADA_REM'))
                                  AS visitas_realizadas,
    COUNT(DISTINCT v.visit_id) FILTER (WHERE v.estado = 'CANCELADA')
                                  AS visitas_canceladas,
    COUNT(DISTINCT v.patient_id)  AS pacientes_atendidos,
    COUNT(DISTINCT v.stay_id)     AS estadias_atendidas
FROM visita v
JOIN estadia e ON v.stay_id = e.stay_id
LEFT JOIN ubicacion u ON v.location_id = u.location_id
WHERE v.rem_reportable = TRUE
GROUP BY v.fecha, u.zone_id, e.establecimiento_id;

CREATE UNIQUE INDEX idx_mv_kpi_diario
    ON mv_kpi_diario (fecha, zone_id, establecimiento_id);

-- Telemetry KPI diario
CREATE MATERIALIZED VIEW mv_telemetria_kpi_diario AS
SELECT
    trd.fecha,
    trd.device_id,
    td.vehiculo_id,
    trd.provider_id,
    trd.km_totales,
    trd.minutos_drive,
    trd.minutos_stop,
    trd.n_segmentos_drive,
    trd.n_segmentos_stop,
    trd.n_stops_significativos,
    trd.velocidad_max_kmh,
    -- Correlación con visitas del día
    (SELECT COUNT(*) FROM visita v
     JOIN ruta r ON v.route_id = r.route_id
     WHERE r.route_id = trd.route_id
       AND v.rem_reportable = TRUE)  AS visitas_rem_ruta,
    -- Stops correlacionados
    (SELECT COUNT(*) FROM telemetria_segmento ts
     WHERE ts.device_id = trd.device_id
       AND ts.start_at::date = trd.fecha
       AND ts.tipo = 'stop'
       AND ts.visit_id IS NOT NULL)  AS stops_correlacionados
FROM telemetria_resumen_diario trd
LEFT JOIN telemetria_dispositivo td ON trd.device_id = td.device_id;

CREATE UNIQUE INDEX idx_mv_telemetria_kpi
    ON mv_telemetria_kpi_diario (fecha, device_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 13: Additional indexes (not already created in Part 1)
-- ═══════════════════════════════════════════════════════════════════════════════

-- NOTE: The following indexes were already created inline in Part 1 and are
-- NOT repeated here:
--   idx_estadia_activos, idx_visita_pendientes, idx_indicacion_activas,
--   idx_herida_activas, idx_prestamo_activos

-- Telemetry indexes (new tables from Section 7)
-- Most were already created inline with Section 7 table definitions.
-- Additional partial and GIN indexes:

-- Partial index for significant stops (>300 seconds)
CREATE INDEX idx_segmento_stops_significativos
    ON telemetry.telemetria_segmento(device_id, start_at)
    WHERE tipo = 'stop' AND duracion_seg > 300;

-- GIN index for geofences_in JSONB
CREATE INDEX idx_segmento_geofences
    ON telemetry.telemetria_segmento
    USING GIN (geofences_in);

-- Reporting indexes
CREATE INDEX idx_rem_personas_periodo
    ON reporting.rem_personas_atendidas(periodo);

CREATE INDEX idx_rem_visitas_periodo
    ON reporting.rem_visitas(periodo);

CREATE INDEX idx_rem_cupos_periodo
    ON reporting.rem_cupos(periodo);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 14: Roles, Grants, Row Level Security
-- ═══════════════════════════════════════════════════════════════════════════════

-- Create roles if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hodom_admin') THEN
        CREATE ROLE hodom_admin;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hodom_clinico') THEN
        CREATE ROLE hodom_clinico;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hodom_coordinador') THEN
        CREATE ROLE hodom_coordinador;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hodom_readonly') THEN
        CREATE ROLE hodom_readonly;
    END IF;
END
$$;

-- Schema usage for all roles
GRANT USAGE ON SCHEMA reference    TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;
GRANT USAGE ON SCHEMA territorial  TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;
GRANT USAGE ON SCHEMA clinical     TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;
GRANT USAGE ON SCHEMA operational  TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;
GRANT USAGE ON SCHEMA reporting    TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;
GRANT USAGE ON SCHEMA telemetry    TO hodom_admin, hodom_clinico, hodom_coordinador, hodom_readonly;

-- hodom_admin: full access on all schemas
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA reference    TO hodom_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA territorial  TO hodom_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA clinical     TO hodom_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA operational  TO hodom_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA reporting    TO hodom_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA telemetry    TO hodom_admin;

-- hodom_readonly: read-only on all schemas
GRANT SELECT ON ALL TABLES IN SCHEMA reference    TO hodom_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA territorial  TO hodom_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA clinical     TO hodom_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA operational  TO hodom_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting    TO hodom_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA telemetry    TO hodom_readonly;

-- hodom_clinico: read/write clinical, read operational/reference/territorial
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA clinical TO hodom_clinico;
GRANT SELECT ON ALL TABLES IN SCHEMA operational  TO hodom_clinico;
GRANT SELECT ON ALL TABLES IN SCHEMA reference    TO hodom_clinico;
GRANT SELECT ON ALL TABLES IN SCHEMA territorial  TO hodom_clinico;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting    TO hodom_clinico;

-- hodom_coordinador: read/write operational, read clinical/reference/territorial
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA operational TO hodom_coordinador;
GRANT SELECT ON ALL TABLES IN SCHEMA clinical     TO hodom_coordinador;
GRANT SELECT ON ALL TABLES IN SCHEMA reference    TO hodom_coordinador;
GRANT SELECT ON ALL TABLES IN SCHEMA territorial  TO hodom_coordinador;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting    TO hodom_coordinador;
GRANT SELECT ON ALL TABLES IN SCHEMA telemetry    TO hodom_coordinador;

-- ---------------------------------------------------------------------------
-- Row Level Security on sensitive tables
-- ---------------------------------------------------------------------------

-- paciente
ALTER TABLE clinical.paciente ENABLE ROW LEVEL SECURITY;
CREATE POLICY paciente_establecimiento ON clinical.paciente
    USING (
        patient_id IN (
            SELECT patient_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- estadia
ALTER TABLE clinical.estadia ENABLE ROW LEVEL SECURITY;
CREATE POLICY estadia_establecimiento ON clinical.estadia
    USING (
        establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- visita
ALTER TABLE operational.visita ENABLE ROW LEVEL SECURITY;
CREATE POLICY visita_establecimiento ON operational.visita
    USING (
        stay_id IN (
            SELECT stay_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- nota_evolucion
ALTER TABLE clinical.nota_evolucion ENABLE ROW LEVEL SECURITY;
CREATE POLICY nota_evolucion_establecimiento ON clinical.nota_evolucion
    USING (
        stay_id IN (
            SELECT stay_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- medicacion
ALTER TABLE clinical.medicacion ENABLE ROW LEVEL SECURITY;
CREATE POLICY medicacion_establecimiento ON clinical.medicacion
    USING (
        stay_id IN (
            SELECT stay_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- evaluacion_paliativa
ALTER TABLE clinical.evaluacion_paliativa ENABLE ROW LEVEL SECURITY;
CREATE POLICY evaluacion_paliativa_establecimiento ON clinical.evaluacion_paliativa
    USING (
        stay_id IN (
            SELECT stay_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );

-- voluntad_anticipada
ALTER TABLE clinical.voluntad_anticipada ENABLE ROW LEVEL SECURITY;
CREATE POLICY voluntad_anticipada_establecimiento ON clinical.voluntad_anticipada
    USING (
        stay_id IN (
            SELECT stay_id FROM estadia
            WHERE establecimiento_id = current_setting('app.establecimiento_id', TRUE)
        )
        OR current_setting('app.establecimiento_id', TRUE) IS NULL
    );


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 15: MV Refresh function (FIX-17)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION refresh_hodom_mvs() RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_rem_personas_atendidas;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_kpi_diario;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_telemetria_kpi_diario;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_hodom_mvs() IS
    'Refresh all HODOM materialized views. Call after data changes or on a cron schedule.';


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 16: Summary
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- HODOM Modelo Integrado v4 — PostgreSQL DDL (Complete)
-- =========================================================
--
-- FIXES APPLIED (from audit):
--   FIX-3:  Added PE-1 trigger for encuesta_satisfaccion
--   FIX-4:  Added stay_coherence triggers for observacion, nota_evolucion,
--           sesion_rehabilitacion, educacion_paciente
--   FIX-5:  Added INSERT guard triggers for estadia (pendiente_evaluacion)
--           and visita (NULL or PROGRAMADA)
--   FIX-7:  condicion.patient_id FK to paciente (was missing)
--   FIX-8:  plan_cuidado CHECK (periodo_fin >= periodo_inicio)
--   FIX-9:  protocolo_fallecimiento cross-validates tipo with estadia.tipo_egreso
--   FIX-10: lista_espera.establecimiento_origen FK to establecimiento
--   FIX-15: sync_paciente_estado handles BOTH activo and egresado/fallecido
--   FIX-17: refresh_hodom_mvs() function for concurrent MV refresh
--   FIX-22: Removed no-op check_telemetria_segmento_ruta trigger
--   FIX C3: kpi_diario.establecimiento_id FK to establecimiento
--   PG-S1:  All rem_reportable comparisons use = TRUE (not = 1)
--   PG-Q4:  mv_rem_personas_atendidas.total_ingresos filters by period
--
-- OBJECT COUNTS:
--   Schemas:              6  (reference, territorial, clinical, operational, reporting, telemetry)
--   Tables:              98  (Part 1: 89 + Part 2: 9 [3 reporting + 3 telemetry + 3 already in Part 1 ref])
--   Reference catalogs:  14  (with seed data)
--   Trigger functions:   22  (PE-1, stay coherence, state machine, special validations, telemetry)
--   Trigger bindings:    54  (27 PE-1 + 6 stay coherence + 9 state machine + 10 special + 2 telemetry)
--   Views:                7  (regular)
--   Materialized views:   3  (with UNIQUE indexes for CONCURRENTLY)
--   Roles:                4  (admin, clinico, coordinador, readonly)
--   RLS policies:         7  (paciente, estadia, visita, nota_evolucion, medicacion,
--                              evaluacion_paliativa, voluntad_anticipada)
--   Additional indexes:   6  (partial, GIN, reporting period)
--
-- END PART 2
-- =============================================================================


-- =============================================================================
-- DATABASE DESIGN IMPROVEMENTS (Post-auditoría DB Design)
-- =============================================================================
-- Fixes: updated_at coverage, auto-update trigger, ON DELETE policy,
--        missing FK indexes, soft delete, full-text search, MV refresh cron.
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 17: Add updated_at to mutable tables that lack it
-- ═══════════════════════════════════════════════════════════════════════════════
-- DS 41/2012 Art. 3: ficha clínica requiere trazabilidad temporal de cambios.

ALTER TABLE clinical.consentimiento
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.nota_evolucion
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.evaluacion_funcional
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.evaluacion_paliativa
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.receta
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.voluntad_anticipada
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.derivacion
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.notificacion_obligatoria
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.sesion_rehabilitacion
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE clinical.teleconsulta
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE operational.compra_servicio
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 18: Auto-update trigger for updated_at
-- ═══════════════════════════════════════════════════════════════════════════════
-- One reusable function, bound to all 48 tables with updated_at.

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_updated_at() IS
    'Auto-update trigger: sets updated_at = NOW() on every UPDATE.';

-- Bind to all tables with updated_at (48 tables)
-- Territorial
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.establecimiento FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.zona FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.ubicacion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.matriz_distancia FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Clinical (already had updated_at)
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.paciente FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.estadia FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.condicion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.plan_cuidado FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.meta FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.procedimiento FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.medicacion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.dispositivo FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.documentacion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.alerta FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.herida FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.valoracion_ingreso FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.indicacion_medica FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.botiquin_domiciliario FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.equipo_medico FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.prestamo_equipo FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.oxigenoterapia_domiciliaria FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.solicitud_examen FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.lista_espera FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evento_adverso FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.garantia_ges FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.epicrisis FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.informe_social FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.interconsulta FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Clinical (newly added updated_at)
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.consentimiento FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.nota_evolucion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_funcional FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_paliativa FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.receta FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.voluntad_anticipada FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.derivacion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.notificacion_obligatoria FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.sesion_rehabilitacion FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.teleconsulta FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Operational
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.profesional FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.insumo FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.orden_servicio FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.vehiculo FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.conductor FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.ruta FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.compra_servicio FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.configuracion_programa FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Telemetry
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON telemetry.telemetria_dispositivo FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 19: ON DELETE policy for tightly-coupled child tables
-- ═══════════════════════════════════════════════════════════════════════════════
-- Default = NO ACTION (RESTRICT) for all FKs — correct for clinical data.
-- CASCADE only for event logs, audit trails, and detail tables that
-- are structurally part of their parent (deleting parent = deleting details).
--
-- In practice, clinical records should NEVER be deleted (DS 41/2012).
-- These CASCADEs exist for administrative cleanup of test/erroneous data.

-- evento_visita is structurally part of visita lifecycle
ALTER TABLE operational.evento_visita
    DROP CONSTRAINT IF EXISTS evento_visita_visit_id_fkey,
    ADD CONSTRAINT evento_visita_visit_id_fkey
        FOREIGN KEY (visit_id) REFERENCES visita(visit_id) ON DELETE CASCADE;

-- evento_estadia is structurally part of estadia lifecycle
ALTER TABLE operational.evento_estadia
    DROP CONSTRAINT IF EXISTS evento_estadia_stay_id_fkey,
    ADD CONSTRAINT evento_estadia_stay_id_fkey
        FOREIGN KEY (stay_id) REFERENCES estadia(stay_id) ON DELETE CASCADE;

-- decision_despacho is audit log of visita assignment
ALTER TABLE operational.decision_despacho
    DROP CONSTRAINT IF EXISTS decision_despacho_visit_id_fkey,
    ADD CONSTRAINT decision_despacho_visit_id_fkey
        FOREIGN KEY (visit_id) REFERENCES visita(visit_id) ON DELETE CASCADE;

-- valoracion_hallazgo is structural detail of valoracion_ingreso
ALTER TABLE clinical.valoracion_hallazgo
    DROP CONSTRAINT IF EXISTS valoracion_hallazgo_assessment_id_fkey,
    ADD CONSTRAINT valoracion_hallazgo_assessment_id_fkey
        FOREIGN KEY (assessment_id) REFERENCES valoracion_ingreso(assessment_id) ON DELETE CASCADE;

-- sesion_rehabilitacion_item is structural detail of sesion
ALTER TABLE clinical.sesion_rehabilitacion_item
    DROP CONSTRAINT IF EXISTS sesion_rehabilitacion_item_sesion_id_fkey,
    ADD CONSTRAINT sesion_rehabilitacion_item_sesion_id_fkey
        FOREIGN KEY (sesion_id) REFERENCES sesion_rehabilitacion(sesion_id) ON DELETE CASCADE;

-- checklist_ingreso items belong to their estadia
ALTER TABLE clinical.checklist_ingreso
    DROP CONSTRAINT IF EXISTS checklist_ingreso_stay_id_fkey,
    ADD CONSTRAINT checklist_ingreso_stay_id_fkey
        FOREIGN KEY (stay_id) REFERENCES estadia(stay_id) ON DELETE CASCADE;

-- diagnostico_egreso is structural detail of epicrisis
ALTER TABLE clinical.diagnostico_egreso
    DROP CONSTRAINT IF EXISTS diagnostico_egreso_epicrisis_id_fkey,
    ADD CONSTRAINT diagnostico_egreso_epicrisis_id_fkey
        FOREIGN KEY (epicrisis_id) REFERENCES epicrisis(epicrisis_id) ON DELETE CASCADE;

-- entrega_turno_paciente is detail of entrega_turno
ALTER TABLE operational.entrega_turno_paciente
    DROP CONSTRAINT IF EXISTS entrega_turno_paciente_entrega_id_fkey,
    ADD CONSTRAINT entrega_turno_paciente_entrega_id_fkey
        FOREIGN KEY (entrega_id) REFERENCES entrega_turno(entrega_id) ON DELETE CASCADE;

-- toma_muestra is detail of solicitud_examen
ALTER TABLE clinical.toma_muestra
    DROP CONSTRAINT IF EXISTS toma_muestra_solicitud_id_fkey,
    ADD CONSTRAINT toma_muestra_solicitud_id_fkey
        FOREIGN KEY (solicitud_id) REFERENCES solicitud_examen(solicitud_id) ON DELETE CASCADE;

-- resultado_examen is detail of solicitud_examen
ALTER TABLE clinical.resultado_examen
    DROP CONSTRAINT IF EXISTS resultado_examen_solicitud_id_fkey,
    ADD CONSTRAINT resultado_examen_solicitud_id_fkey
        FOREIGN KEY (solicitud_id) REFERENCES solicitud_examen(solicitud_id) ON DELETE CASCADE;

-- seguimiento_herida is detail of herida
ALTER TABLE clinical.seguimiento_herida
    DROP CONSTRAINT IF EXISTS seguimiento_herida_herida_id_fkey,
    ADD CONSTRAINT seguimiento_herida_herida_id_fkey
        FOREIGN KEY (herida_id) REFERENCES herida(herida_id) ON DELETE CASCADE;

-- seguimiento_dispositivo is detail of dispositivo
ALTER TABLE clinical.seguimiento_dispositivo
    DROP CONSTRAINT IF EXISTS seguimiento_dispositivo_device_id_fkey,
    ADD CONSTRAINT seguimiento_dispositivo_device_id_fkey
        FOREIGN KEY (device_id) REFERENCES dispositivo(device_id) ON DELETE CASCADE;

-- requerimiento_cuidado is detail of plan_cuidado
ALTER TABLE clinical.requerimiento_cuidado
    DROP CONSTRAINT IF EXISTS requerimiento_cuidado_plan_id_fkey,
    ADD CONSTRAINT requerimiento_cuidado_plan_id_fkey
        FOREIGN KEY (plan_id) REFERENCES plan_cuidado(plan_id) ON DELETE CASCADE;

-- necesidad_profesional is detail of plan_cuidado
ALTER TABLE clinical.necesidad_profesional
    DROP CONSTRAINT IF EXISTS necesidad_profesional_plan_id_fkey,
    ADD CONSTRAINT necesidad_profesional_plan_id_fkey
        FOREIGN KEY (plan_id) REFERENCES plan_cuidado(plan_id) ON DELETE CASCADE;

-- meta is detail of plan_cuidado
ALTER TABLE clinical.meta
    DROP CONSTRAINT IF EXISTS meta_plan_id_fkey,
    ADD CONSTRAINT meta_plan_id_fkey
        FOREIGN KEY (plan_id) REFERENCES plan_cuidado(plan_id) ON DELETE CASCADE;

-- Junction tables: CASCADE on both sides
ALTER TABLE operational.requerimiento_orden_mapping
    DROP CONSTRAINT IF EXISTS requerimiento_orden_mapping_req_id_fkey,
    ADD CONSTRAINT requerimiento_orden_mapping_req_id_fkey
        FOREIGN KEY (req_id) REFERENCES requerimiento_cuidado(req_id) ON DELETE CASCADE;

ALTER TABLE operational.requerimiento_orden_mapping
    DROP CONSTRAINT IF EXISTS requerimiento_orden_mapping_order_id_fkey,
    ADD CONSTRAINT requerimiento_orden_mapping_order_id_fkey
        FOREIGN KEY (order_id) REFERENCES orden_servicio(order_id) ON DELETE CASCADE;

ALTER TABLE operational.orden_servicio_insumo
    DROP CONSTRAINT IF EXISTS orden_servicio_insumo_order_id_fkey,
    ADD CONSTRAINT orden_servicio_insumo_order_id_fkey
        FOREIGN KEY (order_id) REFERENCES orden_servicio(order_id) ON DELETE CASCADE;

ALTER TABLE operational.orden_servicio_insumo
    DROP CONSTRAINT IF EXISTS orden_servicio_insumo_item_id_fkey,
    ADD CONSTRAINT orden_servicio_insumo_item_id_fkey
        FOREIGN KEY (item_id) REFERENCES insumo(item_id) ON DELETE RESTRICT;

ALTER TABLE operational.zona_profesional
    DROP CONSTRAINT IF EXISTS zona_profesional_zone_id_fkey,
    ADD CONSTRAINT zona_profesional_zone_id_fkey
        FOREIGN KEY (zone_id) REFERENCES zona(zone_id) ON DELETE CASCADE;

ALTER TABLE operational.zona_profesional
    DROP CONSTRAINT IF EXISTS zona_profesional_provider_id_fkey,
    ADD CONSTRAINT zona_profesional_provider_id_fkey
        FOREIGN KEY (provider_id) REFERENCES profesional(provider_id) ON DELETE CASCADE;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 20: Missing FK indexes (36 columns)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Every FK column should have an index for efficient JOINs and CASCADE deletes.

-- doc_id references (7 tables)
CREATE INDEX IF NOT EXISTS idx_epicrisis_doc ON clinical.epicrisis(doc_id);
CREATE INDEX IF NOT EXISTS idx_protocolo_doc ON clinical.protocolo_fallecimiento(doc_id);
CREATE INDEX IF NOT EXISTS idx_voluntad_doc ON clinical.voluntad_anticipada(doc_id);
CREATE INDEX IF NOT EXISTS idx_derivacion_doc ON clinical.derivacion(doc_id);
CREATE INDEX IF NOT EXISTS idx_informe_social_doc ON clinical.informe_social(doc_id);
CREATE INDEX IF NOT EXISTS idx_resultado_examen_doc ON clinical.resultado_examen(doc_id);
CREATE INDEX IF NOT EXISTS idx_reunion_acta_doc ON operational.reunion_equipo(acta_doc_id);

-- prestacion_id references
CREATE INDEX IF NOT EXISTS idx_procedimiento_prestacion ON clinical.procedimiento(prestacion_id);
CREATE INDEX IF NOT EXISTS idx_visita_prestacion ON operational.visita(prestacion_id);

-- conductor_id references
CREATE INDEX IF NOT EXISTS idx_ruta_conductor ON operational.ruta(conductor_id);
CREATE INDEX IF NOT EXISTS idx_telemetria_resumen_conductor ON telemetry.telemetria_resumen_diario(conductor_id);

-- location_id references
CREATE INDEX IF NOT EXISTS idx_visita_location ON operational.visita(location_id);
CREATE INDEX IF NOT EXISTS idx_telemetria_segmento_location ON telemetry.telemetria_segmento(location_id);

-- solicitante_id / professional FKs without indexes
CREATE INDEX IF NOT EXISTS idx_solicitud_examen_solicitante ON clinical.solicitud_examen(solicitante_id);
CREATE INDEX IF NOT EXISTS idx_interconsulta_solicitante ON clinical.interconsulta(solicitante_id);
CREATE INDEX IF NOT EXISTS idx_evento_adverso_detectado ON clinical.evento_adverso(detectado_por_id);
CREATE INDEX IF NOT EXISTS idx_notificacion_notificador ON clinical.notificacion_obligatoria(notificador_id);
CREATE INDEX IF NOT EXISTS idx_prestamo_entregado ON clinical.prestamo_equipo(entregado_por);
CREATE INDEX IF NOT EXISTS idx_toma_muestra_tomador ON clinical.toma_muestra(tomador_id);
CREATE INDEX IF NOT EXISTS idx_entrega_turno_saliente ON operational.entrega_turno(turno_saliente_id);
CREATE INDEX IF NOT EXISTS idx_entrega_turno_entrante ON operational.entrega_turno(turno_entrante_id);
CREATE INDEX IF NOT EXISTS idx_orden_servicio_provider ON operational.orden_servicio(provider_asignado);

-- zone_id references
CREATE INDEX IF NOT EXISTS idx_ubicacion_zone ON territorial.ubicacion(zone_id);
CREATE INDEX IF NOT EXISTS idx_kpi_diario_zone ON reporting.kpi_diario(zone_id);
CREATE INDEX IF NOT EXISTS idx_zona_profesional_zone ON operational.zona_profesional(zone_id);

-- indicacion_id / other specific FKs
CREATE INDEX IF NOT EXISTS idx_receta_indicacion ON clinical.receta(indicacion_id);
CREATE INDEX IF NOT EXISTS idx_indicacion_previa ON clinical.indicacion_medica(indicacion_previa_id);
CREATE INDEX IF NOT EXISTS idx_dispensacion_receta ON clinical.dispensacion(receta_id);

-- observacion.codigo → codigo_observacion_ref
CREATE INDEX IF NOT EXISTS idx_observacion_codigo ON clinical.observacion(codigo);

-- consentimiento.doc_id
CREATE INDEX IF NOT EXISTS idx_consentimiento_doc ON clinical.consentimiento(doc_id);

-- telemetria_resumen.provider_id
CREATE INDEX IF NOT EXISTS idx_telemetria_resumen_provider ON telemetry.telemetria_resumen_diario(provider_id);

-- lista_espera.establecimiento_origen
CREATE INDEX IF NOT EXISTS idx_lista_espera_establecimiento ON clinical.lista_espera(establecimiento_origen);

-- lista_espera.evaluador_id
CREATE INDEX IF NOT EXISTS idx_lista_espera_evaluador ON clinical.lista_espera(evaluador_id);

-- equipo_id on oxigenoterapia
CREATE INDEX IF NOT EXISTS idx_oxigenoterapia_equipo ON clinical.oxigenoterapia_domiciliaria(equipo_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 21: Soft delete for key entities
-- ═══════════════════════════════════════════════════════════════════════════════
-- deleted_at NULL = active. Non-NULL = logically deleted.
-- Complements the estado column for administrative cleanup.

ALTER TABLE clinical.paciente
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE operational.profesional
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Partial indexes for active-only queries (exclude soft-deleted)
CREATE INDEX IF NOT EXISTS idx_paciente_active
    ON clinical.paciente(patient_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_profesional_active
    ON operational.profesional(provider_id)
    WHERE deleted_at IS NULL;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 22: Full-text search index (GIN)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Enables fast search by patient name without LIKE '%...%' sequential scans.

CREATE INDEX IF NOT EXISTS idx_paciente_nombre_fts
    ON clinical.paciente
    USING gin(to_tsvector('spanish', nombre_completo));

-- Usage: SELECT * FROM paciente
--        WHERE to_tsvector('spanish', nombre_completo) @@ plainto_tsquery('spanish', 'Juan Pérez');

-- Also useful for diagnostico_principal searches
CREATE INDEX IF NOT EXISTS idx_estadia_diagnostico_fts
    ON clinical.estadia
    USING gin(to_tsvector('spanish', COALESCE(diagnostico_principal, '')));


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 23: Scheduled MV refresh via pg_cron (optional)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Requires: CREATE EXTENSION pg_cron; (must be done by superuser)
-- Uncomment the lines below after pg_cron is installed.

-- CREATE EXTENSION IF NOT EXISTS pg_cron;
--
-- -- Refresh MVs every 15 minutes during business hours (Mon-Sun 07:00-20:00)
-- SELECT cron.schedule(
--     'refresh-hodom-mvs',
--     '*/15 7-20 * * *',
--     $$SELECT refresh_hodom_mvs()$$
-- );
--
-- -- Nightly full refresh at 02:00 (non-concurrent, rebuilds indexes)
-- SELECT cron.schedule(
--     'refresh-hodom-mvs-nightly',
--     '0 2 * * *',
--     $$
--     REFRESH MATERIALIZED VIEW mv_rem_personas_atendidas;
--     REFRESH MATERIALIZED VIEW mv_kpi_diario;
--     REFRESH MATERIALIZED VIEW mv_telemetria_kpi_diario;
--     $$
-- );

-- Alternative without pg_cron: call from application or OS crontab:
--   psql -d hodom -c "SELECT refresh_hodom_mvs();"

-- =============================================================================
-- END DATABASE DESIGN IMPROVEMENTS
-- =============================================================================
-- Added:
--   11 ALTER TABLE ADD COLUMN updated_at (mutable tables that lacked it)
--   48 auto-update triggers (set_updated_at on all tables with updated_at)
--   21 ON DELETE CASCADE constraints (event logs, detail tables, junctions)
--   36 missing FK indexes
--   2 soft-delete columns (paciente, profesional) + 2 partial indexes
--   2 GIN full-text search indexes (paciente.nombre, estadia.diagnostico)
--   pg_cron setup (commented, requires extension installation)
-- =============================================================================
