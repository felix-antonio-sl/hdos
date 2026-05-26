-- HODOM Drive INGRESOS 2026 — Staging DDL
-- Non-destructive nominal table for hospital admissions from INGRESOS_2026_DRIVE.xlsx
-- Source: drive_id 1qynoVzgF5a5qMdTVXhfM35zQC4QCtVqh0MNaSHD2_aQ
-- 5 sheets: INGRESOS, EGRESOS ENERO, EGRESOS FEBRERO, EGRESOS MARZO, EGRESO ABRIL
-- 
-- Reglas:
--   1. No insertar en clinical todavia.
--   2. Nombres, RUT, direcciones y telefonos son PII — no exportar a docs versionados.
--   3. provenance por fila con drive_id, sheet_name, source_row_number, source_hash.

BEGIN;

CREATE TABLE IF NOT EXISTS staging.hodom_ingreso_2026 (
    ingreso_id text PRIMARY KEY,
    drive_id text NOT NULL REFERENCES staging.drive_source_file(drive_id),
    sheet_name text NOT NULL,
    source_row_number integer NOT NULL,
    estado text,
    fecha_ingreso date,
    fecha_egreso date,
    dias_estada_declarado text,
    dias_estada_calculado integer,
    motivo_egreso text,
    nombres text,
    apellidos text,
    nombre_completo text GENERATED ALWAYS AS (
        CASE
            WHEN nombres IS NOT NULL AND apellidos IS NOT NULL
            THEN trim(nombres || ' ' || apellidos)
            WHEN nombres IS NOT NULL THEN nombres
            WHEN apellidos IS NOT NULL THEN apellidos
            ELSE NULL
        END
    ) STORED,
    sexo char(1),
    edad integer,
    fecha_nacimiento date,
    fecha_nacimiento_raw text,
    rut_raw text,
    rut_normalizado text,
    prevision text,
    servicio_origen text,
    usuario_o2 boolean,
    requerimiento_hodom_o2 boolean,
    categorizacion text,
    diagnostico_egreso text,
    domicilio text,
    comuna text,
    cesfam text,
    nro_contacto text,
    nacionalidad text,
    requiere_enfermeria boolean,
    requiere_kinesiologia boolean,
    requiere_fonoaudiologia boolean,
    raw_record jsonb NOT NULL DEFAULT '{}'::jsonb,
    calidad_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
    source_hash text NOT NULL,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (drive_id, sheet_name, source_row_number)
);

CREATE INDEX IF NOT EXISTS idx_hodom_ingreso_2026_rut
    ON staging.hodom_ingreso_2026 (rut_normalizado) WHERE rut_normalizado IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_hodom_ingreso_2026_fecha_ingreso
    ON staging.hodom_ingreso_2026 (fecha_ingreso);

CREATE INDEX IF NOT EXISTS idx_hodom_ingreso_2026_nombre
    ON staging.hodom_ingreso_2026 USING gin (to_tsvector('spanish'::regconfig, coalesce(nombre_completo, '')));

COMMENT ON TABLE staging.hodom_ingreso_2026 IS
'Staging nominal for INGRESOS 2026 DRIVE spreadsheet.
 Contains PII (names, RUT, addresses, phones) — do not export to versioned docs.
 Calendar scope: ingresos 2026 with some late-2025 origin dates.
 provenance via drive_id + sheet_name + source_row_number.';

COMMENT ON COLUMN staging.hodom_ingreso_2026.estado IS 'Raw value from spreadsheet (EGRESADO, EGRESADC, etc. — has typos).';
COMMENT ON COLUMN staging.hodom_ingreso_2026.dias_estada_declarado IS 'Raw cell value — may be formula (=D2-C2) or numeric string.';
COMMENT ON COLUMN staging.hodom_ingreso_2026.dias_estada_calculado IS 'Computed: fecha_egreso - fecha_ingreso when both dates are valid.';
COMMENT ON COLUMN staging.hodom_ingreso_2026.rut_raw IS 'Raw RUT from spreadsheet — may include dots, commas, extra spaces.';
COMMENT ON COLUMN staging.hodom_ingreso_2026.rut_normalizado IS 'Normalized RUT (digits + K + hyphen + verifier, no dots).';
COMMENT ON COLUMN staging.hodom_ingreso_2026.fecha_nacimiento_raw IS 'Raw cell value — may be a date, a string like dd-mm-yyyy, or garbled.';
COMMENT ON COLUMN staging.hodom_ingreso_2026.source_hash IS 'SHA256 of the raw_record JSON for dedup/traceability.';
COMMENT ON COLUMN staging.hodom_ingreso_2026.calidad_flags IS 'JSON array of quality flags detected during ingestion (RUT invalido, fecha improbable, typo, etc.).';

COMMIT;
