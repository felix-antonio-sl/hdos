CREATE TABLE IF NOT EXISTS raw_source_file (
    source_file_id TEXT PRIMARY KEY,
    file_name TEXT NOT NULL,
    file_family TEXT NOT NULL,
    source_pattern TEXT NOT NULL,
    header_rows INTEGER NOT NULL,
    included_in_normalized BOOLEAN NOT NULL,
    header_fingerprint TEXT NOT NULL,
    file_sha256 TEXT NOT NULL,
    row_count INTEGER NOT NULL,
    data_row_count INTEGER NOT NULL,
    imported_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_source_row (
    source_row_id TEXT PRIMARY KEY,
    source_file_id TEXT NOT NULL REFERENCES raw_source_file(source_file_id),
    file_name TEXT NOT NULL,
    row_number INTEGER NOT NULL,
    has_payload BOOLEAN NOT NULL,
    row_hash TEXT NOT NULL,
    raw_json JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS normalized_row (
    normalized_row_id TEXT PRIMARY KEY,
    source_file_id TEXT NOT NULL REFERENCES raw_source_file(source_file_id),
    source_row_id TEXT NOT NULL REFERENCES raw_source_row(source_row_id),
    parse_status TEXT NOT NULL,
    quality_score INTEGER NOT NULL,
    record_uid TEXT NOT NULL,
    dedupe_key TEXT NOT NULL,
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_family TEXT NOT NULL,
    source_pattern TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    duplicate_count INTEGER,
    duplicate_rank INTEGER,
    duplicate_files TEXT,
    estado TEXT,
    fecha_ingreso_raw TEXT,
    fecha_ingreso DATE,
    fecha_egreso_raw TEXT,
    fecha_egreso DATE,
    dias_estadia_reportados INTEGER,
    motivo_egreso TEXT,
    motivo_derivacion TEXT,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    sexo TEXT,
    edad_reportada INTEGER,
    fecha_nacimiento_raw TEXT,
    fecha_nacimiento DATE,
    rut_raw TEXT,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    barthel TEXT,
    prevision TEXT,
    nro_ficha TEXT,
    servicio_origen TEXT,
    usuario_o2 TEXT,
    requerimiento_o2 TEXT,
    categorizacion TEXT,
    diagnostico_egreso TEXT,
    domicilio TEXT,
    nro_casa TEXT,
    domicilio_completo TEXT,
    comuna TEXT,
    cesfam TEXT,
    urbano_rural TEXT,
    nro_contacto TEXT,
    nacionalidad TEXT,
    enfermeria TEXT,
    kinesiologia TEXT,
    fonoaudiologia TEXT,
    tto_ev TEXT,
    tto_sc TEXT,
    tto_im TEXT,
    curaciones TEXT,
    toma_muestras TEXT,
    manejo_ostomias TEXT,
    elementos_invasivos TEXT,
    csv_flag TEXT,
    educacion TEXT,
    medico TEXT,
    knt TEXT,
    fono TEXT,
    trabajo_social TEXT,
    normalization_notes TEXT,
    non_empty_fields INTEGER
);

CREATE TABLE IF NOT EXISTS patient_master (
    patient_id TEXT PRIMARY KEY,
    canonical_patient_key TEXT NOT NULL,
    identity_resolution_status TEXT NOT NULL,
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    rut TEXT,
    rut_valido BOOLEAN,
    rut_raw TEXT,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    sexo TEXT,
    fecha_nacimiento DATE,
    fecha_nacimiento_raw TEXT,
    edad_reportada INTEGER,
    nacionalidad TEXT,
    nro_contacto TEXT,
    domicilio TEXT,
    comuna TEXT,
    cesfam TEXT,
    episode_count INTEGER,
    source_files TEXT
);

CREATE TABLE IF NOT EXISTS patient_identity_candidate (
    identity_candidate_id TEXT PRIMARY KEY,
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    episode_id TEXT NOT NULL,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    identity_confidence NUMERIC(4,2) NOT NULL,
    review_required BOOLEAN NOT NULL,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    nombre_completo_norm TEXT,
    fecha_nacimiento DATE,
    contacto_norm TEXT
);

CREATE TABLE IF NOT EXISTS patient_identity_link (
    patient_identity_link_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    identity_candidate_id TEXT NOT NULL REFERENCES patient_identity_candidate(identity_candidate_id),
    link_type TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode (
    episode_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
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
    duplicate_count INTEGER
);

CREATE TABLE IF NOT EXISTS episode_source_link (
    episode_source_link_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    record_uid TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    duplicate_rank INTEGER,
    is_retained_row BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode_diagnosis (
    episode_diagnosis_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    diagnosis_role TEXT NOT NULL,
    diagnosis_text_raw TEXT NOT NULL,
    diagnosis_text_norm TEXT NOT NULL,
    coding_status TEXT NOT NULL,
    cie10_code TEXT
);

CREATE TABLE IF NOT EXISTS episode_care_requirement (
    episode_requirement_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    requirement_type TEXT NOT NULL,
    requirement_value_raw TEXT NOT NULL,
    requirement_value_norm TEXT NOT NULL,
    is_active BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode_professional_need (
    episode_professional_need_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    professional_type TEXT NOT NULL,
    need_level TEXT NOT NULL,
    source_column TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_contact_point (
    contact_point_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    source_episode_id TEXT REFERENCES episode(episode_id),
    contact_type TEXT NOT NULL,
    contact_value_raw TEXT NOT NULL,
    contact_value_norm TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_address (
    address_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    full_address_raw TEXT NOT NULL,
    street_text TEXT,
    house_number TEXT,
    comuna TEXT,
    cesfam TEXT,
    territory_type TEXT,
    address_quality_status TEXT NOT NULL,
    first_seen_episode_id TEXT REFERENCES episode(episode_id)
);

CREATE TABLE IF NOT EXISTS episode_location_snapshot (
    episode_location_snapshot_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    address_id TEXT NOT NULL REFERENCES patient_address(address_id),
    snapshot_full_address TEXT,
    snapshot_comuna TEXT,
    snapshot_cesfam TEXT,
    snapshot_territory_type TEXT
);

CREATE TABLE IF NOT EXISTS data_quality_issue (
    quality_issue_id TEXT PRIMARY KEY,
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    episode_id TEXT REFERENCES episode(episode_id),
    issue_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    raw_value TEXT,
    suggested_value TEXT,
    status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_value (
    catalog_value_id TEXT PRIMARY KEY,
    catalog_type TEXT NOT NULL,
    code TEXT NOT NULL,
    label TEXT NOT NULL,
    label_normalized TEXT NOT NULL,
    source_count INTEGER NOT NULL
);
