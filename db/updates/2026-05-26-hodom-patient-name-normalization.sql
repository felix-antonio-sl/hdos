-- HODOM INGRESOS 2026 - controlled patient name normalization.
-- Enriches clinical.paciente.nombre_completo with fuller INGRESOS names only
-- when the current significant words are a subset of the INGRESOS name and
-- there is exactly one safe candidate for the patient.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_patient_name_normalization_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_patient_name_normalization_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_patient_name_normalization_preview_2026;

CREATE OR REPLACE VIEW staging.v_hodom_patient_name_normalization_preview_2026 AS
WITH ingreso_names AS (
    SELECT
        p.patient_id,
        p.nombre_completo AS current_nombre_completo,
        i.nombre_completo AS ingreso_nombre_completo,
        staging.norm_text(p.nombre_completo) AS current_name_norm,
        staging.norm_text(i.nombre_completo) AS ingreso_name_norm,
        i.ingreso_id,
        i.rut_normalizado,
        i.sheet_name,
        i.source_row_number
    FROM clinical.paciente p
    JOIN staging.hodom_ingreso_2026 i
      ON i.rut_normalizado = staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g'))
    WHERE p.deleted_at IS NULL
      AND i.nombre_completo IS NOT NULL
      AND staging.norm_text(i.nombre_completo) IS NOT NULL
),
scored AS (
    SELECT
        ingreso_names.*,
        (
            SELECT count(*)::integer
            FROM regexp_split_to_table(current_name_norm, '\s+') AS word
            WHERE length(word) > 2
        ) AS current_word_count,
        (
            SELECT count(*)::integer
            FROM regexp_split_to_table(ingreso_name_norm, '\s+') AS word
            WHERE length(word) > 2
        ) AS ingreso_word_count,
        (
            SELECT count(*)::integer
            FROM regexp_split_to_table(current_name_norm, '\s+') AS word
            WHERE length(word) > 2
              AND ingreso_name_norm LIKE '%' || word || '%'
        ) AS current_words_in_ingreso
    FROM ingreso_names
),
candidates AS (
    SELECT
        *,
        'CURRENT_WORDS_SUBSET_OF_INGRESOS' AS normalization_rule
    FROM scored
    WHERE ingreso_name_norm <> current_name_norm
      AND ingreso_word_count > current_word_count
      AND current_word_count >= 2
      AND current_words_in_ingreso = current_word_count
),
ranked AS (
    SELECT
        *,
        count(*) OVER (PARTITION BY patient_id) AS candidate_count,
        row_number() OVER (
            PARTITION BY patient_id
            ORDER BY ingreso_word_count DESC, length(ingreso_name_norm) DESC, ingreso_name_norm
        ) AS candidate_rank
    FROM candidates
)
SELECT
    patient_id,
    current_nombre_completo,
    ingreso_nombre_completo,
    current_name_norm,
    ingreso_name_norm,
    current_word_count,
    ingreso_word_count,
    current_words_in_ingreso,
    normalization_rule,
    candidate_count,
    candidate_rank,
    ingreso_id,
    rut_normalizado,
    sheet_name,
    source_row_number,
    CASE
        WHEN candidate_count = 1 AND candidate_rank = 1 THEN 'APPLY_SAFE'
        ELSE 'REVIEW_MULTIPLE_INGRESOS_NAMES'
    END AS safety_status
FROM ranked;

COMMENT ON VIEW staging.v_hodom_patient_name_normalization_preview_2026 IS
'PII-bearing preview of controlled patient name normalization from INGRESOS. Do not export.';

CREATE OR REPLACE VIEW staging.v_hodom_patient_name_normalization_summary_2026 AS
SELECT
    normalization_rule,
    safety_status,
    count(*) AS candidate_rows,
    count(DISTINCT patient_id) AS patients,
    min(current_word_count) AS min_current_words,
    max(ingreso_word_count) AS max_ingreso_words,
    now() AS generated_at
FROM staging.v_hodom_patient_name_normalization_preview_2026
GROUP BY normalization_rule, safety_status
ORDER BY normalization_rule, safety_status;

COMMENT ON VIEW staging.v_hodom_patient_name_normalization_summary_2026 IS
'Aggregate summary of patient name normalization candidates. Safe for documentation.';

CREATE TEMP TABLE _hodom_patient_name_normalization_apply ON COMMIT DROP AS
SELECT *
FROM staging.v_hodom_patient_name_normalization_preview_2026
WHERE safety_status = 'APPLY_SAFE'
  AND candidate_count = 1
  AND candidate_rank = 1;

UPDATE clinical.paciente p
SET
    nombre_completo = a.ingreso_nombre_completo,
    updated_at = now()
FROM _hodom_patient_name_normalization_apply a
WHERE a.patient_id = p.patient_id
  AND p.nombre_completo IS DISTINCT FROM a.ingreso_nombre_completo;

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (a.patient_id, f.field_name)
    'clinical.paciente',
    a.patient_id,
    'drive_import',
    'INGRESOS_2026_DRIVE.xlsx',
    a.ingreso_id || '|' || a.current_name_norm || '|' || a.ingreso_name_norm,
    'patient_name_normalization_2026_05_26',
    f.field_name,
    now()
FROM _hodom_patient_name_normalization_apply a
CROSS JOIN (VALUES
    ('nombre_completo'),
    ('normalization_rule')
) AS f(field_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.paciente'
      AND mp.target_pk = a.patient_id
      AND mp.phase = 'patient_name_normalization_2026_05_26'
      AND coalesce(mp.field_name, '') = f.field_name
);

CREATE OR REPLACE VIEW staging.v_hodom_patient_name_normalization_audit_2026 AS
SELECT
    p.patient_id,
    p.nombre_completo,
    count(mp.field_name) AS provenance_fields,
    now() AS generated_at
FROM clinical.paciente p
JOIN migration.provenance mp
  ON mp.target_table = 'clinical.paciente'
 AND mp.target_pk = p.patient_id
 AND mp.phase = 'patient_name_normalization_2026_05_26'
GROUP BY p.patient_id, p.nombre_completo;

COMMENT ON VIEW staging.v_hodom_patient_name_normalization_audit_2026 IS
'PII-bearing audit of clinical.paciente names updated from INGRESOS. Do not export.';

COMMIT;
