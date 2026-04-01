CREATE TABLE IF NOT EXISTS raw_form_submission (
    form_submission_id TEXT PRIMARY KEY,
    source_file TEXT NOT NULL,
    source_sheet TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    raw_json JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_discharge_sheet (
    discharge_row_id TEXT PRIMARY KEY,
    source_file TEXT NOT NULL,
    source_sheet TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    raw_json JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_reference_snapshot (
    reference_snapshot_id TEXT PRIMARY KEY,
    reference_type TEXT NOT NULL,
    source_url TEXT NOT NULL,
    fetched_at TIMESTAMP NOT NULL,
    status TEXT NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS normalized_form_submission (
    form_submission_id TEXT PRIMARY KEY,
    dedupe_key TEXT NOT NULL,
    form_source_count INTEGER NOT NULL,
    source_files TEXT NOT NULL,
    source_rows TEXT NOT NULL,
    submission_timestamp TIMESTAMP,
    rut_raw TEXT,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    fecha_nacimiento DATE,
    edad_reportada INTEGER,
    sexo TEXT,
    servicio_origen_solicitud TEXT,
    diagnostico TEXT,
    direccion TEXT,
    nro_casa TEXT,
    cesfam TEXT,
    celular_1 TEXT,
    celular_2 TEXT,
    prevision TEXT,
    request_prestacion TEXT,
    antecedentes TEXT,
    gestora TEXT,
    attachment_url TEXT,
    usuario_o2 TEXT,
    source_authority TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS normalized_discharge_event (
    discharge_event_id TEXT PRIMARY KEY,
    dedupe_key TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_sheet TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    fecha_ingreso DATE,
    fecha_egreso DATE,
    motivo_egreso TEXT,
    diagnostico TEXT,
    nombre_completo TEXT,
    rut_raw TEXT,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    comuna TEXT,
    direccion_o_comuna TEXT,
    source_authority TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS episode_master (
    episode_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    source_episode_key TEXT NOT NULL,
    record_uid TEXT NOT NULL,
    estado TEXT,
    tipo_flujo TEXT,
    fecha_ingreso DATE,
    fecha_egreso DATE,
    dias_estadia_reportados INTEGER,
    dias_estadia_calculados INTEGER,
    motivo_egreso TEXT,
    motivo_derivacion TEXT,
    servicio_origen TEXT,
    prevision TEXT,
    barthel TEXT,
    categorizacion TEXT,
    usuario_o2 TEXT,
    requerimiento_o2 TEXT,
    diagnostico_principal_texto TEXT,
    episode_status_quality TEXT,
    duplicate_count INTEGER,
    episode_origin TEXT,
    resolution_status TEXT,
    match_status TEXT,
    match_score NUMERIC,
    requested_at TIMESTAMP,
    request_prestacion TEXT,
    gestora TEXT,
    form_source_count INTEGER,
    codigo_deis TEXT,
    establishment_id TEXT,
    locality_id TEXT,
    rescue_priority TEXT
);
