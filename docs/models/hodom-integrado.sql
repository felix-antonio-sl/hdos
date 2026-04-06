-- =============================================================================
-- HODOM Modelo Integrado — DDL SQLite
-- =============================================================================
-- Grothendieck ∫F sobre I = {clínica, operacional, territorial, reporte}
-- 32 entidades, 8 identity keys, 10 path equations
-- Fuentes: FHIR R4/R5, Logística Delivery, OPM v2.5, Legacy Drive, REM A21
-- =============================================================================

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- =============================================================================
-- CAPA 3: TERRITORIAL (se crea primero — referenciada por las demás)
-- =============================================================================

CREATE TABLE IF NOT EXISTS establecimiento (
    establecimiento_id  TEXT PRIMARY KEY,  -- código DEIS
    nombre              TEXT NOT NULL,
    tipo                TEXT,
    comuna              TEXT,
    direccion           TEXT,
    servicio_salud      TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS zona (
    zone_id             TEXT PRIMARY KEY,
    nombre              TEXT NOT NULL,
    tipo                TEXT CHECK (tipo IN ('URBANO', 'PERIURBANO', 'RURAL', 'RURAL_AISLADO')),
    comunas             TEXT,  -- JSON array o CSV de comunas
    centroide_lat       REAL,
    centroide_lng       REAL,
    tiempo_acceso_min   INTEGER,
    conectividad        TEXT,
    capacidad_dia       INTEGER,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS ubicacion (
    location_id         TEXT PRIMARY KEY,
    nombre_oficial      TEXT,
    comuna              TEXT,
    territory_type      TEXT,
    latitud             REAL,
    longitud            REAL,
    zone_id             TEXT REFERENCES zona(zone_id),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS matriz_distancia (
    origin_zone_id      TEXT NOT NULL REFERENCES zona(zone_id),
    dest_zone_id        TEXT NOT NULL REFERENCES zona(zone_id),
    km                  REAL,
    minutos             REAL,
    via                 TEXT,
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (origin_zone_id, dest_zone_id)
);

-- Catálogo de prestaciones MAI (referencia normativa)
CREATE TABLE IF NOT EXISTS catalogo_prestacion (
    prestacion_id       TEXT PRIMARY KEY,
    codigo_mai          TEXT,
    nombre_prestacion   TEXT NOT NULL,
    macroproceso        TEXT,
    subproceso          TEXT,
    estamento           TEXT,
    tipo_eph            TEXT CHECK (tipo_eph IN ('EPH', 'nueva')),
    area_influencia     TEXT,
    compra_servicio     INTEGER DEFAULT 0,  -- boolean
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_catalogo_prestacion_mai ON catalogo_prestacion(codigo_mai);

-- =============================================================================
-- CAPA 1: CLÍNICA
-- Propietaria de: patient_id, stay_id
-- =============================================================================

CREATE TABLE IF NOT EXISTS paciente (
    patient_id          TEXT PRIMARY KEY,  -- hash determinista
    nombre_completo     TEXT NOT NULL,
    rut                 TEXT,
    sexo                TEXT CHECK (sexo IN ('masculino', 'femenino')),
    fecha_nacimiento    TEXT,  -- ISO 8601 date
    direccion           TEXT,
    comuna              TEXT,
    cesfam              TEXT,
    prevision           TEXT CHECK (prevision IN ('fonasa-a', 'fonasa-b', 'fonasa-c', 'fonasa-d', 'prais', 'otro') OR prevision IS NULL),
    contacto_telefono   TEXT,
    estado_actual       TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_paciente_rut ON paciente(rut);
CREATE INDEX IF NOT EXISTS idx_paciente_nombre ON paciente(nombre_completo);

CREATE TABLE IF NOT EXISTS cuidador (
    cuidador_id         TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    nombre              TEXT,
    parentesco          TEXT,
    contacto            TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_cuidador_paciente ON cuidador(patient_id);

CREATE TABLE IF NOT EXISTS estadia (
    stay_id             TEXT PRIMARY KEY,  -- hash determinista
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    establecimiento_id  TEXT REFERENCES establecimiento(establecimiento_id),
    fecha_ingreso       TEXT NOT NULL,  -- ISO 8601 date
    fecha_egreso        TEXT,           -- NULL = activo
    estado              TEXT CHECK (estado IN ('activo', 'egresado', 'fallecido')) DEFAULT 'activo',
    tipo_egreso         TEXT CHECK (tipo_egreso IN (
                            'alta_clinica', 'fallecido_esperado', 'fallecido_no_esperado',
                            'reingreso', 'renuncia_voluntaria', 'alta_disciplinaria'
                        ) OR tipo_egreso IS NULL),
    origen_derivacion   TEXT CHECK (origen_derivacion IN (
                            'APS', 'urgencia', 'hospitalizacion',
                            'ambulatorio', 'ley_urgencia', 'UGCC'
                        ) OR origen_derivacion IS NULL),
    diagnostico_principal TEXT,
    condicion_domicilio TEXT CHECK (condicion_domicilio IN ('adecuada', 'inadecuada') OR condicion_domicilio IS NULL),
    confidence_level    TEXT,
    source_episode_ids  TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_estadia_paciente ON estadia(patient_id);
CREATE INDEX IF NOT EXISTS idx_estadia_fechas ON estadia(fecha_ingreso, fecha_egreso);
CREATE INDEX IF NOT EXISTS idx_estadia_estado ON estadia(estado);
CREATE INDEX IF NOT EXISTS idx_estadia_establecimiento ON estadia(establecimiento_id);

CREATE TABLE IF NOT EXISTS condicion (
    condition_id        TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    codigo_cie10        TEXT,
    descripcion         TEXT,
    estado_clinico      TEXT,
    verificacion        TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_condicion_estadia ON condicion(stay_id);

CREATE TABLE IF NOT EXISTS plan_cuidado (
    plan_id             TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    estado              TEXT CHECK (estado IN ('borrador', 'activo', 'completado')) DEFAULT 'borrador',
    periodo_inicio      TEXT,
    periodo_fin         TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_plan_cuidado_estadia ON plan_cuidado(stay_id);

CREATE TABLE IF NOT EXISTS requerimiento_cuidado (
    req_id              TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    tipo                TEXT CHECK (tipo IN (
                            'CURACIONES', 'TTO_EV', 'TTO_SC', 'TOMA_MUESTRAS',
                            'ELEMENTOS_INVASIVOS', 'CSV', 'EDUCACION',
                            'REQUERIMIENTO_O2', 'MANEJO_OSTOMIAS', 'USUARIO_O2',
                            'VISITA_MEDICA', 'KINESIOLOGIA', 'FONOAUDIOLOGIA'
                        )),
    valor_normalizado   TEXT,
    activo              INTEGER DEFAULT 1,  -- boolean
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_req_cuidado_plan ON requerimiento_cuidado(plan_id);

CREATE TABLE IF NOT EXISTS necesidad_profesional (
    need_id             TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    profesion_requerida TEXT,
    nivel_necesidad     TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_nec_prof_plan ON necesidad_profesional(plan_id);

CREATE TABLE IF NOT EXISTS meta (
    meta_id             TEXT PRIMARY KEY,
    plan_id             TEXT NOT NULL REFERENCES plan_cuidado(plan_id),
    descripcion         TEXT,
    estado_ciclo        TEXT CHECK (estado_ciclo IN ('propuesta', 'aceptada', 'en_progreso', 'lograda', 'cancelada') OR estado_ciclo IS NULL),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS procedimiento (
    proc_id             TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK a capa operacional (cross-layer)
    stay_id             TEXT REFERENCES estadia(stay_id),
    codigo              TEXT,  -- código MAI o vocabulario interno
    descripcion         TEXT,
    estado              TEXT,
    realizado_en        TEXT,  -- ISO 8601 datetime
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_procedimiento_visita ON procedimiento(visit_id);
CREATE INDEX IF NOT EXISTS idx_procedimiento_estadia ON procedimiento(stay_id);

CREATE TABLE IF NOT EXISTS observacion (
    obs_id              TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK cross-layer
    categoria           TEXT,
    codigo              TEXT CHECK (codigo IN (
                            'presion_arterial', 'frecuencia_cardiaca', 'frecuencia_respiratoria',
                            'saturacion_oxigeno', 'temperatura_corporal', 'glicemia',
                            'escala_dolor', 'glasgow', 'estado_edema',
                            'diuresis', 'estado_intestinal', 'estado_dispositivo_invasivo'
                        ) OR codigo IS NULL),
    valor               TEXT,
    unidad              TEXT,
    efectivo_en         TEXT,  -- ISO 8601 datetime
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_observacion_visita ON observacion(visit_id);

CREATE TABLE IF NOT EXISTS medicacion (
    med_id              TEXT PRIMARY KEY,
    stay_id             TEXT REFERENCES estadia(stay_id),
    visit_id            TEXT,  -- FK cross-layer
    medicamento_codigo  TEXT,
    medicamento_nombre  TEXT,
    via                 TEXT CHECK (via IN ('oral', 'IV', 'SC', 'IM', 'topica') OR via IS NULL),
    estado_cadena       TEXT CHECK (estado_cadena IN ('prescrita', 'dispensada', 'administrada') OR estado_cadena IS NULL),
    dosis               TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_medicacion_estadia ON medicacion(stay_id);

CREATE TABLE IF NOT EXISTS dispositivo (
    device_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    tipo                TEXT CHECK (tipo IN ('VVP', 'SNG', 'CUP', 'DRENAJE', 'CONCENTRADOR_O2', 'BOMBA_IV', 'MONITOR', 'GLUCOMETRO', 'OTRO') OR tipo IS NULL),
    estado              TEXT,
    serial              TEXT,
    asignado_desde      TEXT,
    asignado_hasta      TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_dispositivo_paciente ON dispositivo(patient_id);

CREATE TABLE IF NOT EXISTS documentacion (
    doc_id              TEXT PRIMARY KEY,
    visit_id            TEXT,  -- FK cross-layer (puede ser NULL para docs no ligados a visita)
    stay_id             TEXT REFERENCES estadia(stay_id),
    patient_id          TEXT REFERENCES paciente(patient_id),
    tipo                TEXT CHECK (tipo IN (
                            'formulario_ingreso', 'informe_social_preliminar', 'informe_social',
                            'registro_evaluacion_clinica', 'documento_indicaciones_cuidado',
                            'registro_coordinacion_derivador', 'resumen_clinico_domiciliario',
                            'epicrisis', 'encuesta_satisfaccion', 'protocolo_fallecimiento',
                            'declaracion_retiro', 'registro_llamada_seguimiento',
                            'resultado_egreso', 'registro_curacion', 'registro_fonoaudiologia',
                            'registro_telesalud', 'registro_llamada', 'registro_movimientos',
                            'registro_entrega_turno', 'reporte_ejecucion_rutas',
                            'carta_derechos_deberes', 'consentimiento_informado',
                            'hoja_derivacion', 'foto_herida', 'nota_visita', 'dau'
                        )),
    estado              TEXT CHECK (estado IN ('pendiente', 'completo', 'verificado') OR estado IS NULL),
    fecha               TEXT,
    ruta_archivo        TEXT,  -- path relativo al archivo fuente (PDF, DOCX, JPEG)
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_documentacion_visita ON documentacion(visit_id);
CREATE INDEX IF NOT EXISTS idx_documentacion_estadia ON documentacion(stay_id);
CREATE INDEX IF NOT EXISTS idx_documentacion_paciente ON documentacion(patient_id);
CREATE INDEX IF NOT EXISTS idx_documentacion_tipo ON documentacion(tipo);

CREATE TABLE IF NOT EXISTS alerta (
    alerta_id           TEXT PRIMARY KEY,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    categoria           TEXT,
    codigo              TEXT,
    estado              TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_alerta_paciente ON alerta(patient_id);

-- Encuesta de satisfacción (OPM SD1.6: Patient Discharging yields Satisfaction Survey)
CREATE TABLE IF NOT EXISTS encuesta_satisfaccion (
    encuesta_id         TEXT PRIMARY KEY,
    patient_id          TEXT REFERENCES paciente(patient_id),
    stay_id             TEXT REFERENCES estadia(stay_id),
    marca_temporal      TEXT,
    encuestado_nombre   TEXT,
    encuestado_parentesco TEXT,
    fecha_encuesta      TEXT,
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
    valoracion_mejoria      TEXT CHECK (valoracion_mejoria IN ('TOTALMENTE', 'ALGO', 'NADA') OR valoracion_mejoria IS NULL),
    asistencia_telefonica   TEXT,
    volveria                TEXT CHECK (volveria IN ('si', 'probablemente_si', 'probablemente_no', 'no') OR volveria IS NULL),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_encuesta_estadia ON encuesta_satisfaccion(stay_id);

-- =============================================================================
-- CAPA 2: OPERACIONAL
-- Propietaria de: visit_id, provider_id, order_id
-- =============================================================================

CREATE TABLE IF NOT EXISTS profesional (
    provider_id         TEXT PRIMARY KEY,
    rut                 TEXT,
    nombre              TEXT NOT NULL,
    profesion           TEXT CHECK (profesion IN (
                            'ENFERMERIA', 'KINESIOLOGIA', 'FONOAUDIOLOGIA', 'MEDICO',
                            'TRABAJO_SOCIAL', 'TENS', 'NUTRICION', 'MATRONA',
                            'PSICOLOGIA', 'TERAPIA_OCUPACIONAL'
                        )),
    profesion_rem       TEXT CHECK (profesion_rem IN (
                            'medico', 'enfermera', 'tecnico_enfermeria', 'matrona',
                            'kinesiologo', 'psicologo', 'fonoaudiologo',
                            'trabajador_social', 'terapeuta_ocupacional'
                        ) OR profesion_rem IS NULL),
    competencias        TEXT,
    vehiculo            TEXT,
    comunas_cobertura   TEXT,
    max_visitas_dia     INTEGER,
    base_lat            REAL,
    base_lng            REAL,
    estado              TEXT,
    contrato            TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_profesional_profesion ON profesional(profesion);

CREATE TABLE IF NOT EXISTS agenda_profesional (
    schedule_id         TEXT PRIMARY KEY,
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    fecha               TEXT NOT NULL,
    hora_inicio         TEXT,
    hora_fin            TEXT,
    tipo                TEXT CHECK (tipo IN ('TURNO', 'GUARDIA', 'EXTRA', 'BLOQUEADO')),
    motivo_bloqueo      TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_agenda_provider ON agenda_profesional(provider_id);
CREATE INDEX IF NOT EXISTS idx_agenda_fecha ON agenda_profesional(fecha);

CREATE TABLE IF NOT EXISTS sla (
    sla_id              TEXT PRIMARY KEY,
    service_type        TEXT NOT NULL,
    prioridad           TEXT CHECK (prioridad IN ('urgente', 'alta', 'normal', 'baja')),
    max_hrs_primera_visita  INTEGER,
    frecuencia_minima       TEXT,
    duracion_minima_min     INTEGER,
    ventana_horaria         TEXT,
    max_perdidas_consecutivas INTEGER,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS insumo (
    item_id             TEXT PRIMARY KEY,
    nombre              TEXT NOT NULL,
    categoria           TEXT CHECK (categoria IN ('CURACION', 'MEDICAMENTO', 'EQUIPO', 'OXIGENO', 'DESCARTABLE')),
    peso_kg             REAL,
    requiere_vehiculo   INTEGER DEFAULT 0,
    stock_actual        INTEGER,
    umbral_reposicion   INTEGER,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS orden_servicio (
    order_id            TEXT PRIMARY KEY,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    service_type        TEXT,
    profesion_requerida TEXT,
    frecuencia          TEXT,
    duracion_est_min    INTEGER,
    prioridad           TEXT CHECK (prioridad IN ('urgente', 'alta', 'normal', 'baja')),
    requiere_continuidad INTEGER DEFAULT 0,
    provider_asignado   TEXT REFERENCES profesional(provider_id),
    requiere_vehiculo   INTEGER DEFAULT 0,
    ventana_preferida   TEXT,
    fecha_inicio        TEXT,
    fecha_fin           TEXT,
    estado              TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_orden_estadia ON orden_servicio(stay_id);
CREATE INDEX IF NOT EXISTS idx_orden_paciente ON orden_servicio(patient_id);
CREATE INDEX IF NOT EXISTS idx_orden_service_type ON orden_servicio(service_type);

CREATE TABLE IF NOT EXISTS ruta (
    route_id            TEXT PRIMARY KEY,
    provider_id         TEXT REFERENCES profesional(provider_id),
    fecha               TEXT NOT NULL,
    estado              TEXT,
    origen_lat          REAL,
    origen_lng          REAL,
    hora_salida_plan    TEXT,
    hora_salida_real    TEXT,
    total_visitas       INTEGER,
    km_totales          REAL,
    minutos_viaje       REAL,
    minutos_atencion    REAL,
    ratio_viaje_atencion REAL,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_ruta_provider ON ruta(provider_id);
CREATE INDEX IF NOT EXISTS idx_ruta_fecha ON ruta(fecha);

CREATE TABLE IF NOT EXISTS visita (
    visit_id            TEXT PRIMARY KEY,  -- hash determinista
    order_id            TEXT REFERENCES orden_servicio(order_id),
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    provider_id         TEXT REFERENCES profesional(provider_id),
    route_id            TEXT REFERENCES ruta(route_id),
    location_id         TEXT REFERENCES ubicacion(location_id),
    seq_en_ruta         INTEGER,
    fecha               TEXT NOT NULL,
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
    resultado           TEXT,
    motivo_no_realizada TEXT,
    doc_estado          TEXT,
    rem_reportable      INTEGER DEFAULT 0,
    rem_prestacion      TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_visita_paciente ON visita(patient_id);
CREATE INDEX IF NOT EXISTS idx_visita_estadia ON visita(stay_id);
CREATE INDEX IF NOT EXISTS idx_visita_fecha ON visita(fecha);
CREATE INDEX IF NOT EXISTS idx_visita_provider ON visita(provider_id);
CREATE INDEX IF NOT EXISTS idx_visita_ruta ON visita(route_id);
CREATE INDEX IF NOT EXISTS idx_visita_estado ON visita(estado);
CREATE INDEX IF NOT EXISTS idx_visita_rem ON visita(rem_reportable, fecha);

CREATE TABLE IF NOT EXISTS evento_visita (
    event_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    visit_id            TEXT NOT NULL REFERENCES visita(visit_id),
    timestamp           TEXT NOT NULL,
    estado_previo       TEXT,
    estado_nuevo        TEXT,
    lat                 REAL,
    lng                 REAL,
    origen              TEXT,
    detalle             TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_evento_visita ON evento_visita(visit_id);

CREATE TABLE IF NOT EXISTS decision_despacho (
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
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_despacho_visita ON decision_despacho(visit_id);

-- Registro de llamadas telefónicas (OPM: Remote Care Regulating, Follow-Up Call Executing)
CREATE TABLE IF NOT EXISTS registro_llamada (
    llamada_id          TEXT PRIMARY KEY,
    fecha               TEXT NOT NULL,
    hora                TEXT,
    duracion            TEXT,  -- HH:MM:SS
    telefono            TEXT,
    motivo              TEXT CHECK (motivo IN (
                            'resultado_examen', 'asistencia_social', 'consulta_clinica',
                            'seguimiento', 'coordinacion', 'otro'
                        ) OR motivo IS NULL),
    patient_id          TEXT REFERENCES paciente(patient_id),
    nombre_familiar     TEXT,
    parentesco_familiar TEXT,
    estado_paciente     TEXT CHECK (estado_paciente IN ('activo', 'egresado') OR estado_paciente IS NULL),
    tipo                TEXT CHECK (tipo IN ('emitida', 'recibida')),
    provider_id         TEXT REFERENCES profesional(provider_id),
    observaciones       TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_llamada_paciente ON registro_llamada(patient_id);
CREATE INDEX IF NOT EXISTS idx_llamada_fecha ON registro_llamada(fecha);
CREATE INDEX IF NOT EXISTS idx_llamada_provider ON registro_llamada(provider_id);

-- =============================================================================
-- CAPA 4: REPORTE
-- Materializada por Stage 5 del pipeline
-- =============================================================================

-- REM A21 C.1.1 — Personas Atendidas
CREATE TABLE IF NOT EXISTS rem_personas_atendidas (
    periodo             TEXT NOT NULL,  -- YYYY-MM
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    componente          TEXT NOT NULL CHECK (componente IN (
                            'ingresos', 'personas_atendidas', 'dias_persona',
                            'altas', 'fallecidos_esperados', 'fallecidos_no_esperados',
                            'reingresos'
                        )),
    total               INTEGER NOT NULL DEFAULT 0,
    menores_15          INTEGER DEFAULT 0,
    rango_15_19         INTEGER DEFAULT 0,
    rango_20_59         INTEGER DEFAULT 0,
    mayores_60          INTEGER DEFAULT 0,
    sexo_masculino      INTEGER DEFAULT 0,
    sexo_femenino       INTEGER DEFAULT 0,
    origen_aps          INTEGER DEFAULT 0,
    origen_urgencia     INTEGER DEFAULT 0,
    origen_hospitalizacion INTEGER DEFAULT 0,
    origen_ambulatorio  INTEGER DEFAULT 0,
    origen_ley_urgencia INTEGER DEFAULT 0,
    origen_ugcc         INTEGER DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (periodo, establecimiento_id, componente)
);

-- REM A21 C.1.2 — Visitas Realizadas
CREATE TABLE IF NOT EXISTS rem_visitas (
    periodo             TEXT NOT NULL,  -- YYYY-MM
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    profesion_rem       TEXT NOT NULL CHECK (profesion_rem IN (
                            'medico', 'enfermera', 'tecnico_enfermeria', 'matrona',
                            'kinesiologo', 'psicologo', 'fonoaudiologo',
                            'trabajador_social', 'terapeuta_ocupacional'
                        )),
    total_visitas       INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (periodo, establecimiento_id, profesion_rem)
);

-- REM A21 C.1.3 — Cupos Disponibles
CREATE TABLE IF NOT EXISTS rem_cupos (
    periodo             TEXT NOT NULL,  -- YYYY-MM
    establecimiento_id  TEXT NOT NULL REFERENCES establecimiento(establecimiento_id),
    componente          TEXT NOT NULL CHECK (componente IN ('programados', 'utilizados', 'disponibles')),
    total               INTEGER NOT NULL DEFAULT 0,
    campana_invierno_adicionales INTEGER DEFAULT 0,
    campana_invierno    INTEGER DEFAULT 0,
    pediatricos         INTEGER DEFAULT 0,
    adultos             INTEGER DEFAULT 0,
    salud_mental        INTEGER DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (periodo, establecimiento_id, componente)
);

-- KPIs operacionales diarios
CREATE TABLE IF NOT EXISTS kpi_diario (
    fecha               TEXT NOT NULL,
    zone_id             TEXT NOT NULL REFERENCES zona(zone_id),
    visitas_programadas INTEGER DEFAULT 0,
    visitas_completadas INTEGER DEFAULT 0,
    visitas_no_realizadas INTEGER DEFAULT 0,
    tasa_cumplimiento   REAL,
    tasa_puntualidad    REAL,
    continuidad_profesional REAL,
    eficiencia_ruta     REAL,
    tasa_documentacion  REAL,
    tasa_evv            REAL,
    carga_equitativa_stddev REAL,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (fecha, zone_id)
);

-- Descomposición temporal por visita
CREATE TABLE IF NOT EXISTS descomposicion_temporal (
    visit_id                    TEXT PRIMARY KEY REFERENCES visita(visit_id),
    orden_a_asignacion_min      REAL,
    asignacion_a_despacho_min   REAL,
    despacho_a_enruta_min       REAL,
    travel_min                  REAL,
    parking_acceso_min          REAL,
    atencion_min                REAL,
    documentacion_min           REAL,
    salida_next_min             REAL,
    created_at                  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- Reporte de cobertura por paciente y orden
CREATE TABLE IF NOT EXISTS reporte_cobertura (
    report_id           TEXT PRIMARY KEY,
    periodo             TEXT NOT NULL,
    patient_id          TEXT NOT NULL REFERENCES paciente(patient_id),
    order_id            TEXT NOT NULL REFERENCES orden_servicio(order_id),
    visitas_planificadas INTEGER DEFAULT 0,
    visitas_realizadas  INTEGER DEFAULT 0,
    tasa_cobertura      REAL,
    sla_cumplido        INTEGER DEFAULT 0,  -- boolean
    rem_incluidas       INTEGER DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_cobertura_periodo ON reporte_cobertura(periodo);
CREATE INDEX IF NOT EXISTS idx_cobertura_paciente ON reporte_cobertura(patient_id);

-- Máquina de estados de la visita (referencia)
CREATE TABLE IF NOT EXISTS maquina_estados_ref (
    from_state          TEXT NOT NULL,
    to_state            TEXT NOT NULL,
    trigger             TEXT,
    actor               TEXT,
    PRIMARY KEY (from_state, to_state)
);

-- =============================================================================
-- DATOS DE REFERENCIA: Máquina de estados de la visita (12 + CANCELADA)
-- =============================================================================

INSERT OR IGNORE INTO maquina_estados_ref (from_state, to_state, trigger, actor) VALUES
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
    ('NO_REALIZADA',  'DOCUMENTADA',   'cierre_documentacion',     'profesional');

-- =============================================================================
-- VISTAS DERIVADAS (sugar para path equations)
-- =============================================================================

-- PE-9: Consolidado diario de atenciones por profesión (para validar contra legacy)
CREATE VIEW IF NOT EXISTS v_consolidado_atenciones_diarias AS
SELECT
    v.fecha,
    p.profesion_rem,
    COUNT(*) AS total_atenciones
FROM visita v
JOIN profesional p ON v.provider_id = p.provider_id
WHERE v.rem_reportable = 1
  AND v.estado IN ('COMPLETA', 'PARCIAL', 'DOCUMENTADA', 'VERIFICADA', 'REPORTADA_REM')
GROUP BY v.fecha, p.profesion_rem;

-- Pacientes activos a una fecha dada
CREATE VIEW IF NOT EXISTS v_pacientes_activos AS
SELECT
    e.stay_id,
    e.patient_id,
    p.nombre_completo,
    p.rut,
    e.fecha_ingreso,
    e.diagnostico_principal,
    e.establecimiento_id
FROM estadia e
JOIN paciente p ON e.patient_id = p.patient_id
WHERE e.estado = 'activo';

-- PE-1 validation: visita.patient_id must match estadia.patient_id
CREATE VIEW IF NOT EXISTS v_pe1_violations AS
SELECT
    v.visit_id,
    v.patient_id AS visita_patient,
    e.patient_id AS estadia_patient
FROM visita v
JOIN estadia e ON v.stay_id = e.stay_id
WHERE v.patient_id != e.patient_id;

-- =============================================================================
-- CORRECCIONES DE AUDITORÍA CATEGORIAL (2026-04-06)
-- Issues: S1, S2, S3, S4, R4, B1, B2, B3, C1, C2, M2, Q3
-- =============================================================================

-- ── P1: Triggers PE-1/PE-2 — path equation enforcement (S1, S2) ──

CREATE TRIGGER IF NOT EXISTS trg_visita_pe1
BEFORE INSERT ON visita
FOR EACH ROW
WHEN NEW.stay_id IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'PE-1 violation: visita.patient_id != estadia.patient_id for this stay_id')
    WHERE NEW.patient_id != (SELECT patient_id FROM estadia WHERE stay_id = NEW.stay_id);
END;

CREATE TRIGGER IF NOT EXISTS trg_orden_pe2
BEFORE INSERT ON orden_servicio
FOR EACH ROW
WHEN NEW.stay_id IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'PE-2 violation: orden_servicio.patient_id != estadia.patient_id for this stay_id')
    WHERE NEW.patient_id != (SELECT patient_id FROM estadia WHERE stay_id = NEW.stay_id);
END;

-- ── P2: Trigger PE-7 — encuesta solo en altas/renuncias (S3) ──

CREATE TRIGGER IF NOT EXISTS trg_encuesta_pe7
BEFORE INSERT ON encuesta_satisfaccion
FOR EACH ROW
WHEN NEW.stay_id IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'PE-7 violation: encuesta solo permitida para tipo_egreso alta_clinica o renuncia_voluntaria')
    WHERE (SELECT tipo_egreso FROM estadia WHERE stay_id = NEW.stay_id)
          NOT IN ('alta_clinica', 'renuncia_voluntaria');
END;

-- ── P3: Junction requerimiento → orden (S4) ──

CREATE TABLE IF NOT EXISTS requerimiento_orden_mapping (
    req_id              TEXT NOT NULL REFERENCES requerimiento_cuidado(req_id),
    order_id            TEXT NOT NULL REFERENCES orden_servicio(order_id),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (req_id, order_id)
);

-- ── P5: Trigger validación transiciones de estado (R4, B2) ──

CREATE TRIGGER IF NOT EXISTS trg_evento_visita_transicion
BEFORE INSERT ON evento_visita
FOR EACH ROW
WHEN NEW.estado_previo IS NOT NULL AND NEW.estado_nuevo IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Transición de estado inválida: no existe en maquina_estados_ref')
    WHERE NOT EXISTS (
        SELECT 1 FROM maquina_estados_ref
        WHERE from_state = NEW.estado_previo AND to_state = NEW.estado_nuevo
    );
END;

-- ── P6: Lifecycle de estadía — evento_estadia (B1) ──

CREATE TABLE IF NOT EXISTS evento_estadia (
    event_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    timestamp           TEXT NOT NULL,
    estado_previo       TEXT,
    estado_nuevo        TEXT CHECK (estado_nuevo IN (
                            'pendiente_evaluacion', 'elegible', 'admitido',
                            'activo', 'egresado', 'fallecido'
                        )),
    proceso_opm         TEXT CHECK (proceso_opm IN (
                            'eligibility_evaluating', 'patient_admitting',
                            'care_planning', 'therapeutic_plan_executing',
                            'clinical_evolution_monitoring', 'patient_discharging',
                            'post_discharge_following'
                        ) OR proceso_opm IS NULL),
    detalle             TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_evento_estadia ON evento_estadia(stay_id);

-- ── P7: Sincronizar visita.estado desde evento_visita (B3) ──

CREATE TRIGGER IF NOT EXISTS trg_evento_visita_sync_estado
AFTER INSERT ON evento_visita
FOR EACH ROW
WHEN NEW.estado_nuevo IS NOT NULL
BEGIN
    UPDATE visita SET estado = NEW.estado_nuevo, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
    WHERE visit_id = NEW.visit_id;
END;

-- ── P8: Junction orden_servicio ↔ insumo (C1) ──

CREATE TABLE IF NOT EXISTS orden_servicio_insumo (
    order_id            TEXT NOT NULL REFERENCES orden_servicio(order_id),
    item_id             TEXT NOT NULL REFERENCES insumo(item_id),
    cantidad            INTEGER DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (order_id, item_id)
);

-- ── P9: Junction zona ↔ profesional — cobertura (C2) ──

CREATE TABLE IF NOT EXISTS zona_profesional (
    zone_id             TEXT NOT NULL REFERENCES zona(zone_id),
    provider_id         TEXT NOT NULL REFERENCES profesional(provider_id),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (zone_id, provider_id)
);

-- ── P11: Constraint coherencia profesion ↔ profesion_rem (Q3) ──

CREATE TRIGGER IF NOT EXISTS trg_profesional_coherencia_rem
BEFORE INSERT ON profesional
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'profesion NUTRICION debe tener profesion_rem NULL')
    WHERE NEW.profesion = 'NUTRICION' AND NEW.profesion_rem IS NOT NULL;
    SELECT RAISE(ABORT, 'profesion != NUTRICION debe tener profesion_rem NOT NULL')
    WHERE NEW.profesion != 'NUTRICION' AND NEW.profesion_rem IS NULL;
END;

-- ── P12: Junction episodios fuente — reemplaza TEXT concatenado (M2) ──

CREATE TABLE IF NOT EXISTS estadia_episodio_fuente (
    stay_id             TEXT NOT NULL REFERENCES estadia(stay_id),
    episode_id          TEXT NOT NULL,
    source_origin       TEXT,  -- raw, form_rescued, alta_rescued, merged
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (stay_id, episode_id)
);

CREATE INDEX IF NOT EXISTS idx_estadia_episodio ON estadia_episodio_fuente(stay_id);
