-- HODOM Drive staging migration
-- Creates non-destructive staging tables for Drive-derived source data.

BEGIN;

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.drive_migration_registry (
    migration_id text PRIMARY KEY,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

INSERT INTO staging.drive_migration_registry (migration_id, description)
VALUES ('drive_staging_migration_2026_05_25', 'Staging structures for HODOM Drive folders, route spreadsheets, handover documents and annual metrics')
ON CONFLICT (migration_id) DO UPDATE
SET description = EXCLUDED.description;

CREATE TABLE IF NOT EXISTS staging.drive_source_file (
    drive_id text PRIMARY KEY,
    folder_url text NOT NULL,
    path text NOT NULL,
    title text NOT NULL,
    mime_type text NOT NULL,
    dataset text NOT NULL,
    year integer,
    month integer,
    period text,
    local_path text,
    sha256 text,
    size_bytes bigint,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_drive_source_file_dataset_period
    ON staging.drive_source_file (dataset, period);

CREATE INDEX IF NOT EXISTS idx_drive_source_file_year_month
    ON staging.drive_source_file (year, month);

CREATE TABLE IF NOT EXISTS staging.hodom_route_visit (
    route_visit_id text PRIMARY KEY,
    drive_id text NOT NULL REFERENCES staging.drive_source_file(drive_id),
    source_path text NOT NULL,
    sheet_name text NOT NULL,
    source_row_number integer NOT NULL,
    visit_date date,
    driver_name text,
    planned_time text,
    professionals jsonb NOT NULL DEFAULT '{}'::jsonb,
    patient_name text,
    service_text text,
    address_text text,
    phone_text text,
    raw_record jsonb NOT NULL DEFAULT '{}'::jsonb,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (drive_id, sheet_name, source_row_number)
);

CREATE INDEX IF NOT EXISTS idx_hodom_route_visit_date
    ON staging.hodom_route_visit (visit_date);

CREATE INDEX IF NOT EXISTS idx_hodom_route_visit_patient_name
    ON staging.hodom_route_visit USING gin (to_tsvector('spanish'::regconfig, coalesce(patient_name, '')));

CREATE TABLE IF NOT EXISTS staging.hodom_shift_handover (
    handover_id text PRIMARY KEY,
    drive_id text NOT NULL REFERENCES staging.drive_source_file(drive_id),
    source_path text NOT NULL,
    title text NOT NULL,
    period_start date,
    period_end date,
    text_content text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_hodom_shift_handover_period
    ON staging.hodom_shift_handover (period_start, period_end);

CREATE TABLE IF NOT EXISTS staging.hodom_annual_metric (
    metric_id text PRIMARY KEY,
    year integer NOT NULL,
    metric_name text NOT NULL,
    metric_value numeric,
    source_type text NOT NULL,
    source_detail text,
    quality_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (year, metric_name, source_type)
);

CREATE INDEX IF NOT EXISTS idx_hodom_annual_metric_year
    ON staging.hodom_annual_metric (year);

COMMENT ON SCHEMA staging IS 'Non-destructive staging area for source migration and reconciliation before promotion to clinical/operational tables.';
COMMENT ON TABLE staging.drive_source_file IS 'Drive source file inventory with provenance metadata and hashes; raw files remain outside Git.';
COMMENT ON TABLE staging.hodom_route_visit IS 'Parsed nominal route spreadsheet rows. Contains PII in the database only; do not export to versioned files.';
COMMENT ON TABLE staging.hodom_shift_handover IS 'Extracted shift handover documents. Contains clinical-operational text in the database only.';
COMMENT ON TABLE staging.hodom_annual_metric IS 'Aggregate annual metrics loaded from normative specs before clinical table promotion.';

COMMIT;
