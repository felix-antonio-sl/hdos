# Modelo de Datos Funcional MVP — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Estado: borrador v1
Dependencia: `blueprint-pantallas-hodom-hsc.md`, `backlog-mvp-hodom-hsc.md`, `modelo-integrado-hodom.md`
Motor: PostgreSQL (alineado con `hodom-integrado-pg-v4.sql`)

---

## Principio de diseño

Este modelo no es el modelo integrado completo. Es el **subconjunto funcional mínimo** que soporta las 5 pantallas del MVP y las 16 capacidades MUST HAVE de Fase 1.

Reglas:
- si la pantalla no lo necesita, no entra al MVP,
- si el modelo integrado ya lo tiene, se reutiliza,
- si el legacy lo usa y el MVP lo necesita, se normaliza,
- si la normativa lo exige, se incluye aunque el legacy no lo tenga.

---

## Diagrama de entidades MVP

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────────┐
│    Paciente      │────▶│    Episodio       │────▶│   PlanTerapeutico │
│                  │     │                  │     │                   │
│ patient_id  PK   │     │ episodio_id  PK  │     │ plan_id  PK       │
│ rut              │     │ patient_id  FK   │     │ episodio_id  FK   │
│ nombre           │     │ cuidador_id FK   │     │ objetivo          │
│ fecha_nacimiento │     │ estado           │     │ estado            │
│ sexo             │     │ diagnostico      │     │ frecuencias       │
│ direccion        │     │ origen_derivacion│     └───────────────────┘
│ comuna           │     │ fecha_ingreso    │              │
│ cesfam           │     │ fecha_egreso     │     ┌────────▼──────────┐
│ prevision        │     │ tipo_egreso      │     │ Requerimiento     │
│ telefono_1       │     │ equipo_id FK     │     │ Cuidado           │
│ telefono_2       │     │ condicion_domici.│     │                   │
│ estado_actual    │     │ exclusiones_eval │     │ req_id  PK        │
└─────────────────┘     │ consentimiento   │     │ plan_id  FK       │
         │               └──────────────────┘     │ tipo              │
         │                        │               │ frecuencia        │
┌────────▼────────┐      ┌───────▼────────┐      │ profesion_req     │
│   Cuidador      │      │    Visita      │      └───────────────────┘
│                  │      │               │
│ cuidador_id  PK  │      │ visita_id  PK │      ┌───────────────────┐
│ patient_id  FK   │      │ episodio_id FK│      │   Profesional     │
│ nombre           │      │ profesional_id│──────│                   │
│ parentesco       │      │ fecha         │      │ profesional_id PK │
│ rut              │      │ hora_programa │      │ rut               │
│ telefono         │      │ hora_real     │      │ nombre            │
└──────────────────┘      │ tipo_atencion │      │ profesion         │
                          │ estado_visita │      │ profesion_rem     │
                          │ nota_clinica  │      │ telefono          │
                          │ intervenciones│      │ estado            │
                          │ incidencia    │      └───────────────────┘
                          │ motivo_no_real│               │
                          │ ruta_id FK    │      ┌────────▼──────────┐
                          └───────────────┘      │  EquipoSalud     │
                                   │              │                   │
                          ┌────────▼────────┐    │ equipo_id  PK     │
                          │ SignosVitales   │    │ nombre            │
                          │                 │    └───────────────────┘
                          │ sv_id  PK       │             │
                          │ visita_id FK    │    ┌────────▼──────────┐
                          │ pa_sistolica    │    │EquipoProfesional  │
                          │ pa_diastolica   │    │                   │
                          │ fc              │    │ equipo_id  FK     │
                          │ fr              │    │ profesional_id FK │
                          │ temperatura     │    │ rol_en_equipo     │
                          │ saturacion      │    └───────────────────┘
                          │ hgt             │
                          │ eva             │    ┌───────────────────┐
                          │ glasgow         │    │     Ruta          │
                          │ edema           │    │                   │
                          │ diuresis        │    │ ruta_id  PK       │
                          │ deposiciones    │    │ profesional_id FK │
                          │ invasivos       │    │ vehiculo          │
                          └─────────────────┘    │ fecha             │
                                                  │ zona              │
┌───────────────────┐                            │ hora_salida       │
│RegistroLlamada    │                            │ total_visitas     │
│                   │                            └───────────────────┘
│ llamada_id PK     │
│ episodio_id FK    │    ┌───────────────────┐
│ patient_id FK     │    │  Documento        │
│ profesional_id FK │    │                   │
│ fecha             │    │ doc_id  PK        │
│ hora              │    │ episodio_id  FK   │
│ duracion          │    │ tipo              │
│ tipo_llamada      │    │ estado            │
│ motivo            │    │ fecha             │
│ nombre_familiar   │    │ autor_id  FK      │
│ observaciones     │    │ firmado           │
│ requiere_accion   │    └───────────────────┘
└───────────────────┘
                         ┌───────────────────┐
                         │  Establecimiento  │
                         │                   │
                         │ codigo_deis  PK   │
                         │ nombre            │
                         │ tipo              │
                         │ comuna            │
                         └───────────────────┘
```

---

## DDL PostgreSQL — MVP

```sql
-- ============================================================
-- MODELO DE DATOS FUNCIONAL MVP — HODOM HSC
-- ============================================================

-- ENUMS
CREATE TYPE sexo_tipo AS ENUM ('masculino', 'femenino');
CREATE TYPE prevision_tipo AS ENUM ('fonasa_a', 'fonasa_b', 'fonasa_c', 'fonasa_d', 'prais', 'isapre', 'sin_prevision');
CREATE TYPE origen_derivacion_tipo AS ENUM ('aps', 'urgencia', 'hospitalizacion', 'ambulatorio', 'ley_urgencia', 'ugcc');
CREATE TYPE estado_episodio_tipo AS ENUM ('postulado', 'en_evaluacion', 'elegible', 'no_elegible', 'activo', 'pre_egreso', 'egresado');
CREATE TYPE tipo_egreso_tipo AS ENUM ('alta_clinica', 'fallecido_esperado', 'fallecido_no_esperado', 'reingreso', 'renuncia_voluntaria', 'alta_disciplinaria');
CREATE TYPE consentimiento_tipo AS ENUM ('pendiente', 'aceptado', 'rechazado');
CREATE TYPE profesion_tipo AS ENUM ('medico', 'enfermeria', 'tens', 'kinesiologia', 'fonoaudiologia', 'trabajo_social', 'psicologia', 'matrona', 'terapia_ocupacional', 'nutricion');
CREATE TYPE profesion_rem_tipo AS ENUM ('medico', 'enfermera', 'tecnico_enfermeria', 'matrona', 'kinesiologo', 'psicologo', 'fonoaudiologo', 'trabajador_social', 'terapeuta_ocupacional');
CREATE TYPE tipo_atencion_tipo AS ENUM ('ca', 'cs', 'ktm', 'ktr', 'vm', 'ntp', 'tto_ev', 'tto_sc', 'fono', 'examenes', 'evaluacion', 'educacion', 'control', 'ingreso', 'telesalud', 'otro');
CREATE TYPE estado_visita_tipo AS ENUM ('programada', 'en_curso', 'realizada', 'fallida', 'cancelada');
CREATE TYPE tipo_llamada_tipo AS ENUM ('emitida', 'recibida');
CREATE TYPE motivo_llamada_tipo AS ENUM ('resultado_examen', 'asistencia_social', 'consulta_clinica', 'seguimiento', 'coordinacion', 'hora_medica', 'urgencia', 'otro');
CREATE TYPE tipo_documento_tipo AS ENUM ('consentimiento_informado', 'formulario_ingreso', 'carta_derechos_deberes', 'informe_social', 'epicrisis', 'contrarreferencia', 'encuesta_satisfaccion', 'protocolo_fallecimiento', 'declaracion_retiro', 'nota_visita', 'foto_herida', 'otro');
CREATE TYPE estado_documento_tipo AS ENUM ('pendiente', 'completo', 'firmado');
CREATE TYPE estado_plan_tipo AS ENUM ('borrador', 'activo', 'completado');
CREATE TYPE categoria_paciente_tipo AS ENUM ('estable', 'mejorando', 'deteriorandose');
CREATE TYPE edema_tipo AS ENUM ('ausente', 'leve', 'moderado', 'severo');

-- ============================================================
-- ENTIDADES BASE
-- ============================================================

CREATE TABLE establecimiento (
    codigo_deis TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    tipo TEXT,
    comuna TEXT,
    direccion TEXT,
    servicio_salud TEXT
);

CREATE TABLE profesional (
    profesional_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    rut TEXT UNIQUE NOT NULL,
    nombre TEXT NOT NULL,
    profesion profesion_tipo NOT NULL,
    profesion_rem profesion_rem_tipo, -- NULL si no reportable (ej: nutricion)
    telefono TEXT,
    estado TEXT DEFAULT 'activo',
    max_visitas_dia INT DEFAULT 12,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE equipo_salud (
    equipo_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    nombre TEXT NOT NULL,
    establecimiento_id TEXT REFERENCES establecimiento(codigo_deis),
    activo BOOLEAN DEFAULT true
);

CREATE TABLE equipo_profesional (
    equipo_id TEXT REFERENCES equipo_salud(equipo_id),
    profesional_id TEXT REFERENCES profesional(profesional_id),
    rol_en_equipo TEXT, -- 'titular', 'reemplazo', 'apoyo'
    PRIMARY KEY (equipo_id, profesional_id)
);

-- ============================================================
-- PACIENTE Y CUIDADOR
-- ============================================================

CREATE TABLE paciente (
    patient_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    rut TEXT UNIQUE NOT NULL,
    nombre TEXT NOT NULL,
    fecha_nacimiento DATE,
    sexo sexo_tipo,
    direccion TEXT,
    comuna TEXT,
    cesfam TEXT,
    prevision prevision_tipo,
    telefono_1 TEXT,
    telefono_2 TEXT,
    latitud REAL,
    longitud REAL,
    estado_actual TEXT DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE cuidador (
    cuidador_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id TEXT REFERENCES paciente(patient_id),
    nombre TEXT NOT NULL,
    rut TEXT,
    parentesco TEXT,
    telefono TEXT,
    es_principal BOOLEAN DEFAULT true
);

-- ============================================================
-- EPISODIO HODOM (núcleo)
-- ============================================================

CREATE TABLE episodio (
    episodio_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id TEXT NOT NULL REFERENCES paciente(patient_id),
    cuidador_id TEXT REFERENCES cuidador(cuidador_id),
    equipo_id TEXT REFERENCES equipo_salud(equipo_id),
    establecimiento_id TEXT REFERENCES establecimiento(codigo_deis),

    -- Admisión
    estado estado_episodio_tipo NOT NULL DEFAULT 'postulado',
    origen_derivacion origen_derivacion_tipo,
    servicio_origen TEXT, -- texto libre legacy: 'MEDICINA', 'UE', 'CIRUGÍA', 'TMT'
    diagnostico_principal TEXT,
    diagnosticos_secundarios TEXT[],
    fecha_postulacion DATE,
    fecha_ingreso DATE,
    consentimiento consentimiento_tipo DEFAULT 'pendiente',

    -- Elegibilidad (OPM SD1.1)
    condicion_domicilio TEXT, -- 'adecuado', 'inadecuado', 'pendiente'
    exclusiones_evaluadas JSONB, -- {inestabilidad: false, salud_mental: false, ...}

    -- Estado clínico
    categoria_paciente categoria_paciente_tipo,

    -- Egreso
    fecha_egreso DATE,
    tipo_egreso tipo_egreso_tipo,
    dias_estada INT GENERATED ALWAYS AS (
        CASE WHEN fecha_egreso IS NOT NULL AND fecha_ingreso IS NOT NULL
             THEN fecha_egreso - fecha_ingreso
             ELSE NULL END
    ) STORED,

    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- Constraints
    CONSTRAINT ck_egreso_requiere_tipo CHECK (
        (estado != 'egresado') OR (tipo_egreso IS NOT NULL)
    ),
    CONSTRAINT ck_egreso_requiere_fecha CHECK (
        (estado != 'egresado') OR (fecha_egreso IS NOT NULL)
    ),
    CONSTRAINT ck_fechas_coherentes CHECK (
        fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso
    )
);

CREATE INDEX idx_episodio_estado ON episodio(estado);
CREATE INDEX idx_episodio_patient ON episodio(patient_id);
CREATE INDEX idx_episodio_fechas ON episodio(fecha_ingreso, fecha_egreso);

-- ============================================================
-- PLAN TERAPÉUTICO Y REQUERIMIENTOS
-- ============================================================

CREATE TABLE plan_terapeutico (
    plan_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    episodio_id TEXT NOT NULL REFERENCES episodio(episodio_id),
    estado estado_plan_tipo NOT NULL DEFAULT 'borrador',
    objetivo TEXT,
    criterios_alta TEXT,
    fecha_inicio DATE,
    fecha_fin DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE requerimiento_cuidado (
    req_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    plan_id TEXT NOT NULL REFERENCES plan_terapeutico(plan_id),
    tipo tipo_atencion_tipo NOT NULL,
    frecuencia TEXT, -- '1x/dia', '3x/semana', 'c/72h'
    profesion_requerida profesion_tipo,
    activo BOOLEAN DEFAULT true,
    notas TEXT
);

-- ============================================================
-- RUTA Y VISITA
-- ============================================================

CREATE TABLE ruta (
    ruta_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    profesional_id TEXT REFERENCES profesional(profesional_id),
    vehiculo TEXT, -- nombre del móvil: 'SERVANDO', 'HUGO', 'ANDRES'
    fecha DATE NOT NULL,
    zona TEXT,
    hora_salida TIME,
    total_visitas INT DEFAULT 0
);

CREATE INDEX idx_ruta_fecha ON ruta(fecha);

CREATE TABLE visita (
    visita_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    episodio_id TEXT NOT NULL REFERENCES episodio(episodio_id),
    profesional_id TEXT NOT NULL REFERENCES profesional(profesional_id),
    ruta_id TEXT REFERENCES ruta(ruta_id),

    -- Programación
    fecha DATE NOT NULL,
    hora_programada TIME,
    tipo_atencion tipo_atencion_tipo NOT NULL,
    seq_en_ruta INT,

    -- Ejecución
    hora_real_inicio TIMESTAMPTZ,
    hora_real_fin TIMESTAMPTZ,
    estado estado_visita_tipo NOT NULL DEFAULT 'programada',

    -- Registro clínico
    nota_clinica TEXT,
    intervenciones TEXT[], -- array de intervenciones realizadas
    incidencia TEXT, -- 'sin_incidencia', 'ausente', 'rechazo', 'evento_adverso', 'otra'
    motivo_no_realizada TEXT,

    -- REM
    rem_reportable BOOLEAN DEFAULT true,

    -- Metadatos
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_visita_fecha ON visita(fecha);
CREATE INDEX idx_visita_episodio ON visita(episodio_id);
CREATE INDEX idx_visita_profesional ON visita(profesional_id, fecha);
CREATE INDEX idx_visita_estado ON visita(estado);

-- ============================================================
-- SIGNOS VITALES (15 columnas del registro real)
-- ============================================================

CREATE TABLE signos_vitales (
    sv_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    visita_id TEXT NOT NULL REFERENCES visita(visita_id),

    pa_sistolica INT,
    pa_diastolica INT,
    frecuencia_cardiaca INT,
    frecuencia_respiratoria INT,
    temperatura NUMERIC(4,1),
    saturacion_o2 INT,
    hgt INT, -- hemoglucotest mg/dL
    eva INT CHECK (eva BETWEEN 0 AND 10), -- escala dolor
    glasgow INT CHECK (glasgow BETWEEN 3 AND 15),
    edema edema_tipo,
    diuresis TEXT,
    deposiciones TEXT,
    invasivos TEXT, -- descripción de dispositivos invasivos presentes

    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- REGISTRO DE LLAMADAS
-- ============================================================

CREATE TABLE registro_llamada (
    llamada_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    episodio_id TEXT REFERENCES episodio(episodio_id),
    patient_id TEXT REFERENCES paciente(patient_id),
    profesional_id TEXT REFERENCES profesional(profesional_id),

    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    duracion INTERVAL,
    telefono TEXT,

    tipo tipo_llamada_tipo NOT NULL,
    motivo motivo_llamada_tipo NOT NULL,

    nombre_familiar TEXT,
    parentesco_familiar TEXT,
    observaciones TEXT,
    requiere_accion BOOLEAN DEFAULT false,
    accion_requerida TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_llamada_fecha ON registro_llamada(fecha);
CREATE INDEX idx_llamada_episodio ON registro_llamada(episodio_id);

-- ============================================================
-- DOCUMENTOS
-- ============================================================

CREATE TABLE documento (
    doc_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    episodio_id TEXT NOT NULL REFERENCES episodio(episodio_id),
    tipo tipo_documento_tipo NOT NULL,
    estado estado_documento_tipo NOT NULL DEFAULT 'pendiente',
    fecha DATE,
    autor_id TEXT REFERENCES profesional(profesional_id),
    firmado BOOLEAN DEFAULT false,
    contenido TEXT, -- texto o referencia a archivo
    url_archivo TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_documento_episodio ON documento(episodio_id);

-- ============================================================
-- USUARIOS Y AUTENTICACIÓN (RBAC)
-- ============================================================

CREATE TYPE rol_sistema_tipo AS ENUM (
    'medico_hodom', 'medico_regulador', 'enfermera_clinica',
    'enfermera_coordinadora', 'tens', 'kinesiologo', 'fonoaudiologo',
    'trabajo_social', 'psicologo', 'terapeuta_ocupacional', 'matrona',
    'administrativo', 'gestor_rutas', 'estadistico',
    'direccion_tecnica', 'conductor', 'superadmin'
);

CREATE TABLE usuario (
    usuario_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    profesional_id TEXT REFERENCES profesional(profesional_id),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol rol_sistema_tipo NOT NULL,
    activo BOOLEAN DEFAULT true,
    ultimo_acceso TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- VISTAS PARA PANTALLAS
-- ============================================================

-- Vista: Tablero de Coordinación (Pantalla 1)
CREATE OR REPLACE VIEW v_tablero_coordinacion AS
SELECT
    e.episodio_id,
    p.nombre AS paciente,
    p.rut,
    EXTRACT(YEAR FROM age(p.fecha_nacimiento))::INT AS edad,
    e.diagnostico_principal,
    e.estado,
    e.categoria_paciente,
    e.fecha_ingreso,
    CURRENT_DATE - e.fecha_ingreso AS dias_estada,
    e.origen_derivacion,
    (SELECT v.fecha FROM visita v WHERE v.episodio_id = e.episodio_id
     AND v.estado = 'realizada' ORDER BY v.fecha DESC, v.hora_real_fin DESC LIMIT 1) AS ultima_visita,
    (SELECT v.fecha FROM visita v WHERE v.episodio_id = e.episodio_id
     AND v.estado = 'programada' AND v.fecha >= CURRENT_DATE
     ORDER BY v.fecha, v.hora_programada LIMIT 1) AS proxima_visita
FROM episodio e
JOIN paciente p ON e.patient_id = p.patient_id
WHERE e.estado IN ('activo', 'pre_egreso')
ORDER BY e.fecha_ingreso;

-- Vista: Postulaciones pendientes
CREATE OR REPLACE VIEW v_postulaciones_pendientes AS
SELECT
    e.episodio_id,
    p.nombre AS paciente,
    EXTRACT(YEAR FROM age(p.fecha_nacimiento))::INT AS edad,
    e.diagnostico_principal,
    e.origen_derivacion,
    e.fecha_postulacion,
    e.estado,
    e.consentimiento
FROM episodio e
JOIN paciente p ON e.patient_id = p.patient_id
WHERE e.estado IN ('postulado', 'en_evaluacion', 'elegible')
ORDER BY e.fecha_postulacion;

-- Vista: Agenda del día (Pantalla 3)
CREATE OR REPLACE VIEW v_agenda_dia AS
SELECT
    v.visita_id,
    v.fecha,
    v.hora_programada,
    v.tipo_atencion,
    v.estado AS estado_visita,
    v.seq_en_ruta,
    pr.nombre AS profesional,
    pr.profesion,
    pa.nombre AS paciente,
    pa.direccion,
    pa.telefono_1,
    r.vehiculo AS movil,
    r.ruta_id,
    e.episodio_id,
    e.diagnostico_principal
FROM visita v
JOIN profesional pr ON v.profesional_id = pr.profesional_id
JOIN episodio e ON v.episodio_id = e.episodio_id
JOIN paciente pa ON e.patient_id = pa.patient_id
LEFT JOIN ruta r ON v.ruta_id = r.ruta_id
ORDER BY v.fecha, r.vehiculo, v.seq_en_ruta, v.hora_programada;

-- Vista: Llamadas del día (Pantalla 4)
CREATE OR REPLACE VIEW v_llamadas_dia AS
SELECT
    rl.llamada_id,
    rl.fecha,
    rl.hora,
    rl.duracion,
    rl.tipo,
    rl.motivo,
    rl.observaciones,
    rl.nombre_familiar,
    rl.requiere_accion,
    pa.nombre AS paciente,
    pr.nombre AS profesional
FROM registro_llamada rl
LEFT JOIN paciente pa ON rl.patient_id = pa.patient_id
LEFT JOIN profesional pr ON rl.profesional_id = pr.profesional_id
ORDER BY rl.fecha DESC, rl.hora DESC;

-- ============================================================
-- FUNCIONES REM (Pantalla 5)
-- ============================================================

-- REM C.1.1: Personas atendidas por periodo
CREATE OR REPLACE FUNCTION fn_rem_personas_atendidas(p_periodo TEXT)
RETURNS TABLE (
    componente TEXT,
    total BIGINT,
    menores_15 BIGINT,
    rango_15_19 BIGINT,
    mayores_20 BIGINT,
    sexo_masculino BIGINT,
    sexo_femenino BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    -- Ingresos
    RETURN QUERY
    SELECT
        'ingresos'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM episodio e
    JOIN paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_ingreso BETWEEN v_inicio AND v_fin;

    -- Personas atendidas (activas en el periodo)
    RETURN QUERY
    SELECT
        'personas_atendidas'::TEXT,
        COUNT(DISTINCT e.patient_id)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM episodio e
    JOIN paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_ingreso <= v_fin
      AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= v_inicio)
      AND e.estado NOT IN ('postulado', 'en_evaluacion', 'no_elegible');

    -- Días persona
    RETURN QUERY
    SELECT
        'dias_persona'::TEXT,
        SUM(
            LEAST(v_fin, COALESCE(e.fecha_egreso, v_fin))
            - GREATEST(v_inicio, e.fecha_ingreso)
            + 1
        )::BIGINT,
        0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT -- desglose no aplica a sum
    FROM episodio e
    WHERE e.fecha_ingreso <= v_fin
      AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= v_inicio)
      AND e.estado NOT IN ('postulado', 'en_evaluacion', 'no_elegible');

    -- Altas
    RETURN QUERY
    SELECT
        'altas'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM episodio e
    JOIN paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin
      AND e.tipo_egreso IN ('alta_clinica', 'renuncia_voluntaria', 'alta_disciplinaria');

    -- Fallecidos esperados
    RETURN QUERY
    SELECT 'fallecidos_esperados'::TEXT,
        COUNT(*)::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM episodio e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin
      AND e.tipo_egreso = 'fallecido_esperado';

    -- Fallecidos no esperados
    RETURN QUERY
    SELECT 'fallecidos_no_esperados'::TEXT,
        COUNT(*)::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM episodio e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin
      AND e.tipo_egreso = 'fallecido_no_esperado';

    -- Reingresos
    RETURN QUERY
    SELECT 'reingresos'::TEXT,
        COUNT(*)::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM episodio e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin
      AND e.tipo_egreso = 'reingreso';
END;
$$ LANGUAGE plpgsql;

-- REM C.1.2: Visitas por profesión
CREATE OR REPLACE FUNCTION fn_rem_visitas(p_periodo TEXT)
RETURNS TABLE (
    profesion_rem profesion_rem_tipo,
    total_visitas BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    RETURN QUERY
    SELECT
        pr.profesion_rem,
        COUNT(*)::BIGINT
    FROM visita v
    JOIN profesional pr ON v.profesional_id = pr.profesional_id
    WHERE v.fecha BETWEEN v_inicio AND v_fin
      AND v.estado = 'realizada'
      AND v.rem_reportable = true
      AND pr.profesion_rem IS NOT NULL
    GROUP BY pr.profesion_rem
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;

-- REM C.1.1 Origen derivación
CREATE OR REPLACE FUNCTION fn_rem_origen_derivacion(p_periodo TEXT)
RETURNS TABLE (
    origen origen_derivacion_tipo,
    total BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    RETURN QUERY
    SELECT
        e.origen_derivacion,
        COUNT(*)::BIGINT
    FROM episodio e
    WHERE e.fecha_ingreso BETWEEN v_inicio AND v_fin
      AND e.origen_derivacion IS NOT NULL
    GROUP BY e.origen_derivacion;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- DATOS DE REFERENCIA INICIALES
-- ============================================================

INSERT INTO establecimiento (codigo_deis, nombre, tipo, comuna, servicio_salud) VALUES
('112100', 'Hospital de San Carlos Dr. Benicio Arzola Medina', 'hospital_alta_complejidad', 'San Carlos', 'Servicio de Salud Ñuble');

-- ============================================================
-- CONSTRAINTS DE NEGOCIO (path equations)
-- ============================================================

-- PE-1: Consistencia temporal ya como CHECK en episodio
-- PE-2: Tipo egreso requerido ya como CHECK en episodio
-- PE-3: Origen derivación debe existir para ingresos
-- (se valida a nivel aplicación para no bloquear postulaciones incompletas)

COMMENT ON TABLE episodio IS 'Núcleo del sistema. Un episodio = un ingreso-estancia-egreso de hospitalización domiciliaria. Relación 1:N con paciente.';
COMMENT ON COLUMN episodio.exclusiones_evaluadas IS 'JSON con 5 causales: {inestabilidad_clinica, salud_mental_descompensada, prestacion_no_disponible, alta_disciplinaria_previa, sin_diagnostico}';
COMMENT ON COLUMN episodio.condicion_domicilio IS 'Evaluación OPM SD1.1: servicios básicos, telefonía, acceso vial';
COMMENT ON COLUMN visita.intervenciones IS 'Array de códigos: administracion_medicamento, curacion, toma_muestra, educacion, cambio_invasivo, terapia_motora, terapia_respiratoria, eval_fono, intervencion_social';
COMMENT ON FUNCTION fn_rem_personas_atendidas IS 'Genera REM A21 C.1.1. Parámetro: periodo YYYY-MM';
COMMENT ON FUNCTION fn_rem_visitas IS 'Genera REM A21 C.1.2. Parámetro: periodo YYYY-MM';
```

---

## Mapeo pantalla → entidades

| Pantalla | Entidades principales | Vistas/Funciones |
|----------|----------------------|------------------|
| 1. Tablero | episodio, paciente, visita | `v_tablero_coordinacion`, `v_postulaciones_pendientes` |
| 2. Ficha clínica | episodio, paciente, cuidador, plan_terapeutico, requerimiento_cuidado, visita, signos_vitales, documento | — |
| 3. Agenda y rutas | visita, ruta, profesional, paciente, episodio | `v_agenda_dia` |
| 4. Llamadas | registro_llamada, paciente, profesional | `v_llamadas_dia` |
| 5. REM y analítica | episodio, visita, profesional | `fn_rem_personas_atendidas()`, `fn_rem_visitas()`, `fn_rem_origen_derivacion()` |

---

## Entidades MVP vs modelo integrado completo

| Entidad MVP | Origen en modelo integrado | Simplificación |
|-------------|---------------------------|----------------|
| paciente | Paciente (Capa Clínica) | Sin `confidence_level`, sin `source_episode_ids` |
| cuidador | Cuidador (Capa Clínica) | Sin cambios |
| episodio | Estadia (Capa Clínica) | Renombrado. +postulación, +elegibilidad, +consentimiento |
| plan_terapeutico | PlanCuidado | Simplificado |
| requerimiento_cuidado | RequerimientoCuidado + NecesidadProfesional | Fusionados |
| profesional | Profesional (Capa Operacional) | Sin `comunas_cobertura`, sin `base_lat/lng` |
| equipo_salud | Nuevo | Agrega estructura de equipo |
| visita | Visita (Capa Operacional) | Sin `gps_lat/lng`, sin `doc_estado`, sin máquina de estados completa |
| signos_vitales | Observacion (Capa Clínica) | Tabla dedicada con 15 columnas del registro real |
| ruta | Ruta (Capa Operacional) | Sin `km_totales`, sin `ratio_viaje_atencion` |
| registro_llamada | RegistroLlamada (nueva legacy) | Sin cambios |
| documento | Documentacion (Capa Clínica) | Simplificado |
| usuario | Nuevo | RBAC mínimo |

**Total: 14 tablas + 4 vistas + 3 funciones REM**

---

## Qué NO entra al MVP (se agrega en Fase 2-3)

| Entidad/Capacidad | Fase | Razón de exclusión |
|-------------------|------|--------------------|
| OrdenServicio + SLA | F2 | MVP programa visitas directo, sin motor de órdenes |
| DecisionDespacho + scoring | F2 | MVP asigna manualmente |
| EventoVisita (máquina de estados) | F2 | MVP usa estado simple |
| MatrizDistancia + Zona | F2 | MVP usa dirección texto |
| Insumo + stock | F2 | MVP no gestiona inventario |
| Medicacion (cadena prescripción→administración) | F2 | MVP registra en nota clínica |
| Condicion (CIE-10 separado) | F2 | MVP usa texto en episodio |
| EncuestaSatisfaccion | F2 | MVP registra como documento |
| CatalogoPrestacion | F2 | MVP usa enum tipo_atencion |
| KPIDiario + DescomposicionTemporal | F3 | Analítica avanzada |
| ReporteCobertura | F3 | Analítica avanzada |
| Dispositivo | F2 | MVP registra en signos_vitales.invasivos |

---

## Siguiente paso

1. Crear `hodom-mvp.sql` ejecutable en PostgreSQL.
2. Poblar con datos de prueba desde legacy (10 pacientes, 30 visitas, 5 llamadas).
3. Validar que las funciones REM producen números consistentes con el REM real de julio 2023.
4. Conectar con stack de aplicación (recomendación: Next.js + Prisma o similar).
