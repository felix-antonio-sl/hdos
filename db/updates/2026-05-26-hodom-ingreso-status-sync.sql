-- HODOM INGRESOS 2026 - synchronize active/discharged status from live sheet.
-- Source: INGRESOS 2026 DRIVE, reloaded into staging.hodom_ingreso_2026.
-- Rule: only apply when RUT resolves to one patient and the episode window
-- resolves to one existing stay. Ambiguous patient/stay anchors remain review.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_ingreso_status_sync_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_ingreso_status_sync_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_ingreso_status_sync_preview_2026;

CREATE OR REPLACE VIEW staging.v_hodom_ingreso_status_sync_preview_2026 AS
WITH source_episode AS (
    SELECT
        i.rut_normalizado,
        i.fecha_ingreso,
        max(i.fecha_egreso) FILTER (
            WHERE i.fecha_egreso IS NOT NULL
              AND i.fecha_egreso >= i.fecha_ingreso
        ) AS fecha_egreso,
        bool_or(i.estado = 'ACTIVO' AND i.fecha_egreso IS NULL) AS has_active_source,
        bool_or(
            i.estado IN ('EGRESADO', 'EGRESADC')
            AND i.fecha_egreso IS NOT NULL
            AND i.fecha_egreso >= i.fecha_ingreso
        ) AS has_closed_source,
        bool_or(i.fecha_egreso IS NOT NULL AND i.fecha_egreso < i.fecha_ingreso)
            AS has_invalid_closed_date,
        (
            array_agg(i.motivo_egreso ORDER BY i.fecha_egreso DESC NULLS LAST, i.source_row_number DESC)
            FILTER (WHERE i.motivo_egreso IS NOT NULL)
        )[1] AS motivo_egreso,
        (
            array_agg(i.diagnostico_egreso ORDER BY i.fecha_egreso DESC NULLS LAST, i.source_row_number DESC)
            FILTER (WHERE i.diagnostico_egreso IS NOT NULL)
        )[1] AS diagnostico_egreso,
        count(*) AS source_rows,
        count(*) FILTER (WHERE jsonb_array_length(i.calidad_flags) > 0) AS source_rows_with_flags,
        min(i.sheet_name) AS first_sheet_name,
        min(i.source_row_number) AS first_source_row_number
    FROM staging.hodom_ingreso_2026 i
    WHERE i.rut_normalizado IS NOT NULL
      AND i.fecha_ingreso IS NOT NULL
      AND (
          i.estado IN ('ACTIVO', 'EGRESADO', 'EGRESADC')
          OR i.fecha_egreso IS NOT NULL
      )
    GROUP BY i.rut_normalizado, i.fecha_ingreso
),
classified_source AS (
    SELECT
        se.*,
        CASE
            WHEN se.has_closed_source AND se.fecha_egreso IS NOT NULL THEN 'SOURCE_EGRESADO'
            WHEN se.has_active_source THEN 'SOURCE_ACTIVO'
            ELSE 'SOURCE_REVIEW'
        END AS source_status,
        CASE
            WHEN lower(trim(se.motivo_egreso)) = 'alta' THEN 'alta_clinica'::text
            WHEN lower(trim(se.motivo_egreso)) = 'rehospitalizacion' THEN 'reingreso'::text
            WHEN lower(trim(se.motivo_egreso)) IN ('fallecido', 'fallecida')
                THEN 'fallecido_esperado'::text
            ELSE NULL::text
        END AS mapped_tipo_egreso
    FROM source_episode se
),
patient_match AS (
    SELECT
        cs.*,
        count(DISTINCT p.patient_id) AS patient_count,
        min(p.patient_id) AS patient_id
    FROM classified_source cs
    LEFT JOIN clinical.paciente p
      ON p.rut IS NOT NULL
     AND staging.norm_text(regexp_replace(p.rut, '[.\s,]+', '', 'g')) = cs.rut_normalizado
     AND p.deleted_at IS NULL
    GROUP BY
        cs.rut_normalizado, cs.fecha_ingreso, cs.fecha_egreso,
        cs.has_active_source, cs.has_closed_source, cs.has_invalid_closed_date,
        cs.motivo_egreso, cs.diagnostico_egreso, cs.source_rows,
        cs.source_rows_with_flags, cs.first_sheet_name, cs.first_source_row_number,
        cs.source_status, cs.mapped_tipo_egreso
),
stay_match AS (
    SELECT
        pm.*,
        count(DISTINCT e.stay_id) AS stay_count,
        min(e.stay_id) AS stay_id
    FROM patient_match pm
    LEFT JOIN clinical.estadia e
      ON pm.patient_count = 1
     AND e.patient_id = pm.patient_id
     AND (
         (
             pm.source_status = 'SOURCE_EGRESADO'
             AND pm.fecha_egreso IS NOT NULL
             AND daterange(pm.fecha_ingreso, pm.fecha_egreso, '[]') &&
                 daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
         )
         OR (
             pm.source_status = 'SOURCE_ACTIVO'
             AND daterange(pm.fecha_ingreso, '9999-12-31'::date, '[]') &&
                 daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
         )
     )
    GROUP BY
        pm.rut_normalizado, pm.fecha_ingreso, pm.fecha_egreso,
        pm.has_active_source, pm.has_closed_source, pm.has_invalid_closed_date,
        pm.motivo_egreso, pm.diagnostico_egreso, pm.source_rows,
        pm.source_rows_with_flags, pm.first_sheet_name, pm.first_source_row_number,
        pm.source_status, pm.mapped_tipo_egreso, pm.patient_count, pm.patient_id
),
resolved AS (
    SELECT
        sm.*,
        e.estado AS current_estado,
        e.fecha_ingreso AS current_fecha_ingreso,
        e.fecha_egreso AS current_fecha_egreso,
        e.tipo_egreso AS current_tipo_egreso,
        CASE
            WHEN sm.source_status = 'SOURCE_ACTIVO' THEN NULL::date
            WHEN sm.source_status = 'SOURCE_EGRESADO' THEN sm.fecha_egreso
            ELSE NULL::date
        END AS target_fecha_egreso,
        CASE
            WHEN sm.source_status = 'SOURCE_ACTIVO' THEN NULL::text
            WHEN sm.mapped_tipo_egreso IS NOT NULL THEN sm.mapped_tipo_egreso
            ELSE e.tipo_egreso
        END AS target_tipo_egreso,
        CASE
            WHEN sm.source_status = 'SOURCE_ACTIVO' THEN 'activo'::text
            WHEN sm.source_status = 'SOURCE_EGRESADO'
                 AND sm.mapped_tipo_egreso IN ('fallecido_esperado', 'fallecido_no_esperado')
                THEN 'fallecido'::text
            WHEN sm.source_status = 'SOURCE_EGRESADO' THEN 'egresado'::text
            ELSE NULL::text
        END AS target_estado
    FROM stay_match sm
    LEFT JOIN clinical.estadia e ON e.stay_id = sm.stay_id
),
ranked AS (
    SELECT
        r.*,
        count(*) FILTER (WHERE r.source_status IN ('SOURCE_ACTIVO', 'SOURCE_EGRESADO'))
            OVER (
                PARTITION BY coalesce(
                    r.stay_id,
                    'candidate:' || r.rut_normalizado || '|' || r.fecha_ingreso::text
                )
            ) AS stay_candidate_count,
        bool_or(r.source_status = 'SOURCE_EGRESADO')
            OVER (
                PARTITION BY coalesce(
                    r.stay_id,
                    'candidate:' || r.rut_normalizado || '|' || r.fecha_ingreso::text
                )
            ) AS stay_has_closed_source,
        row_number()
            OVER (
                PARTITION BY coalesce(
                    r.stay_id,
                    'candidate:' || r.rut_normalizado || '|' || r.fecha_ingreso::text
                )
                ORDER BY
                    CASE WHEN r.source_status = 'SOURCE_EGRESADO' THEN 0 ELSE 1 END,
                    r.target_fecha_egreso DESC NULLS LAST,
                    r.fecha_ingreso DESC,
                    r.first_source_row_number DESC
            ) AS stay_choice_rank
    FROM resolved r
)
SELECT
    'st_' || substr(md5(r.rut_normalizado || '|' || r.fecha_ingreso::text), 1, 16)
        AS sync_candidate_id,
    r.source_status,
    r.patient_id,
    r.stay_id,
    r.fecha_ingreso AS source_fecha_ingreso,
    r.fecha_egreso AS source_fecha_egreso,
    r.current_estado,
    r.target_estado,
    r.current_fecha_egreso,
    r.target_fecha_egreso,
    r.current_tipo_egreso,
    r.target_tipo_egreso,
    r.mapped_tipo_egreso,
    r.patient_count,
    r.stay_count,
    r.source_rows,
    r.source_rows_with_flags,
    r.first_sheet_name,
    r.first_source_row_number,
    r.stay_candidate_count,
    r.stay_has_closed_source,
    r.stay_choice_rank,
    CASE
        WHEN r.has_invalid_closed_date THEN 'REVIEW_INVALID_EGRESS_DATE'
        WHEN r.source_status = 'SOURCE_REVIEW' THEN 'REVIEW_SOURCE_STATUS'
        WHEN r.patient_count = 0 THEN 'BLOCKED_NO_PATIENT_MATCH'
        WHEN r.patient_count > 1 THEN 'BLOCKED_AMBIGUOUS_PATIENT_MATCH'
        WHEN r.stay_count = 0 THEN 'BLOCKED_NO_STAY_MATCH'
        WHEN r.stay_count > 1 THEN 'BLOCKED_AMBIGUOUS_STAY_MATCH'
        WHEN r.current_estado = 'fallecido' AND r.target_estado <> 'fallecido'
            THEN 'BLOCKED_DEATH_STATE_CONFLICT'
        WHEN r.source_status = 'SOURCE_ACTIVO'
             AND r.stay_has_closed_source
             AND r.stay_candidate_count > 1
            THEN 'BLOCKED_CLOSED_SOURCE_CONFLICT'
        WHEN r.stay_candidate_count > 1 AND r.stay_choice_rank > 1
            THEN 'BLOCKED_DUPLICATE_SOURCE_FOR_STAY'
        ELSE 'APPLY_SAFE'
    END AS safety_status,
    (r.current_fecha_egreso IS DISTINCT FROM r.target_fecha_egreso) AS fecha_egreso_changed,
    (r.current_tipo_egreso IS DISTINCT FROM r.target_tipo_egreso) AS tipo_egreso_changed,
    (r.current_estado IS DISTINCT FROM r.target_estado) AS estado_changed,
    now() AS generated_at
FROM ranked r;

COMMENT ON VIEW staging.v_hodom_ingreso_status_sync_preview_2026 IS
'PII-bearing preview for synchronizing clinical.estadia active/discharged state from INGRESOS 2026 DRIVE. Use aggregate summary for versioned documentation.';

CREATE OR REPLACE VIEW staging.v_hodom_ingreso_status_sync_summary_2026 AS
SELECT
    source_status,
    safety_status,
    count(*) AS episode_rows,
    sum(source_rows) AS source_rows,
    count(DISTINCT patient_id) FILTER (WHERE patient_id IS NOT NULL) AS distinct_patients,
    count(*) FILTER (WHERE fecha_egreso_changed) AS fecha_egreso_changes,
    count(*) FILTER (WHERE tipo_egreso_changed) AS tipo_egreso_changes,
    count(*) FILTER (WHERE estado_changed) AS estado_changes,
    now() AS generated_at
FROM staging.v_hodom_ingreso_status_sync_preview_2026
GROUP BY source_status, safety_status
ORDER BY source_status, safety_status;

COMMENT ON VIEW staging.v_hodom_ingreso_status_sync_summary_2026 IS
'Aggregate status-sync summary from INGRESOS 2026 DRIVE. Safe for documentation: no names, RUT, addresses or phones.';

CREATE TEMP TABLE _hodom_ingreso_status_sync_apply ON COMMIT DROP AS
SELECT *
FROM staging.v_hodom_ingreso_status_sync_preview_2026
WHERE safety_status = 'APPLY_SAFE'
  AND source_status IN ('SOURCE_ACTIVO', 'SOURCE_EGRESADO')
  AND (fecha_egreso_changed OR tipo_egreso_changed OR estado_changed);

UPDATE clinical.estadia e
SET
    fecha_egreso = a.target_fecha_egreso,
    tipo_egreso = a.target_tipo_egreso,
    updated_at = now()
FROM _hodom_ingreso_status_sync_apply a
WHERE e.stay_id = a.stay_id
  AND (a.fecha_egreso_changed OR a.tipo_egreso_changed);

-- The state machine does not allow pendiente_evaluacion -> fallecido directly.
-- For deceased discharges we first activate the stay, then discharge as death.
SELECT clinical.transition_estadia(
    a.stay_id,
    'activo',
    'patient_discharging',
    'ingreso_status_sync_2026_05_26: intermediate activation before fallecido'
)
FROM _hodom_ingreso_status_sync_apply a
JOIN clinical.estadia e ON e.stay_id = a.stay_id
WHERE a.target_estado = 'fallecido'
  AND e.estado <> 'activo';

SELECT clinical.transition_estadia(
    a.stay_id,
    a.target_estado,
    CASE
        WHEN a.target_estado = 'activo' THEN 'patient_admitting'
        ELSE 'patient_discharging'
    END,
    'ingreso_status_sync_2026_05_26: status from INGRESOS 2026 DRIVE'
)
FROM _hodom_ingreso_status_sync_apply a
JOIN clinical.estadia e ON e.stay_id = a.stay_id
WHERE e.estado IS DISTINCT FROM a.target_estado;

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (a.stay_id, f.field_name)
    'clinical.estadia',
    a.stay_id,
    'drive_import',
    'INGRESOS_2026_DRIVE.xlsx',
    a.source_status || '|' || a.source_fecha_ingreso::text || '|' ||
        coalesce(a.source_fecha_egreso::text, 'open'),
    'ingreso_status_sync_2026_05_26',
    f.field_name,
    now()
FROM _hodom_ingreso_status_sync_apply a
CROSS JOIN LATERAL (VALUES
    ('fecha_egreso'::text, a.fecha_egreso_changed),
    ('tipo_egreso'::text, a.tipo_egreso_changed),
    ('estado'::text, a.estado_changed),
    ('status_sync_action'::text, true)
) AS f(field_name, changed)
WHERE f.changed
  AND NOT EXISTS (
      SELECT 1
      FROM migration.provenance mp
      WHERE mp.target_table = 'clinical.estadia'
        AND mp.target_pk = a.stay_id
        AND mp.phase = 'ingreso_status_sync_2026_05_26'
        AND coalesce(mp.field_name, '') = f.field_name
  );

CREATE TEMP TABLE _hodom_ingreso_status_split_close_apply ON COMMIT DROP AS
WITH blocked AS (
    SELECT *
    FROM staging.v_hodom_ingreso_status_sync_preview_2026
    WHERE source_status = 'SOURCE_EGRESADO'
      AND safety_status = 'BLOCKED_AMBIGUOUS_STAY_MATCH'
      AND source_fecha_egreso IS NOT NULL
),
overlapping AS (
    SELECT
        b.sync_candidate_id,
        b.patient_id,
        b.source_fecha_ingreso,
        b.source_fecha_egreso,
        b.mapped_tipo_egreso,
        b.target_tipo_egreso,
        e.stay_id,
        e.fecha_ingreso AS active_fecha_ingreso,
        e.fecha_egreso AS active_fecha_egreso,
        e.estado AS active_estado,
        count(*) OVER (PARTITION BY b.sync_candidate_id) AS overlapping_stay_count,
        count(*) FILTER (WHERE e.estado = 'activo' AND e.fecha_egreso IS NULL)
            OVER (PARTITION BY b.sync_candidate_id) AS active_open_stay_count
    FROM blocked b
    JOIN clinical.estadia e
      ON e.patient_id = b.patient_id
     AND daterange(b.source_fecha_ingreso, b.source_fecha_egreso, '[]') &&
         daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
)
SELECT
    o.sync_candidate_id,
    o.patient_id,
    o.stay_id,
    o.source_fecha_ingreso,
    o.source_fecha_egreso AS target_fecha_egreso,
    o.target_tipo_egreso,
    CASE
        WHEN o.mapped_tipo_egreso IN ('fallecido_esperado', 'fallecido_no_esperado')
            THEN 'fallecido'::text
        ELSE 'egresado'::text
    END AS target_estado,
    'CLOSE_SPLIT_ACTIVE_STAY_FROM_INGRESOS'::text AS resolution_action
FROM overlapping o
WHERE o.overlapping_stay_count = 2
  AND o.active_open_stay_count = 1
  AND o.active_estado = 'activo'
  AND o.active_fecha_egreso IS NULL
  AND o.source_fecha_egreso >= o.active_fecha_ingreso
  AND NOT EXISTS (
      SELECT 1
      FROM clinical.estadia other
      WHERE other.patient_id = o.patient_id
        AND other.stay_id <> o.stay_id
        AND daterange(o.active_fecha_ingreso, o.source_fecha_egreso, '[]') &&
            daterange(other.fecha_ingreso, coalesce(other.fecha_egreso, '9999-12-31'::date), '[]')
  );

UPDATE clinical.estadia e
SET
    fecha_egreso = a.target_fecha_egreso,
    tipo_egreso = a.target_tipo_egreso,
    updated_at = now()
FROM _hodom_ingreso_status_split_close_apply a
WHERE e.stay_id = a.stay_id
  AND (
      e.fecha_egreso IS DISTINCT FROM a.target_fecha_egreso
      OR e.tipo_egreso IS DISTINCT FROM a.target_tipo_egreso
  );

SELECT clinical.transition_estadia(
    a.stay_id,
    a.target_estado,
    'patient_discharging',
    'ingreso_status_sync_2026_05_26: CLOSE_SPLIT_ACTIVE_STAY_FROM_INGRESOS'
)
FROM _hodom_ingreso_status_split_close_apply a
JOIN clinical.estadia e ON e.stay_id = a.stay_id
WHERE e.estado IS DISTINCT FROM a.target_estado;

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (a.stay_id, f.field_name)
    'clinical.estadia',
    a.stay_id,
    'drive_import',
    'INGRESOS_2026_DRIVE.xlsx',
    a.resolution_action || '|' || a.source_fecha_ingreso::text || '|' ||
        a.target_fecha_egreso::text,
    'ingreso_status_sync_2026_05_26',
    f.field_name,
    now()
FROM _hodom_ingreso_status_split_close_apply a
CROSS JOIN (VALUES
    ('fecha_egreso'),
    ('tipo_egreso'),
    ('estado'),
    ('CLOSE_SPLIT_ACTIVE_STAY_FROM_INGRESOS')
) AS f(field_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.estadia'
      AND mp.target_pk = a.stay_id
      AND mp.phase = 'ingreso_status_sync_2026_05_26'
      AND coalesce(mp.field_name, '') = f.field_name
);

CREATE TEMP TABLE _hodom_ingreso_status_active_create_apply ON COMMIT DROP AS
SELECT
    'stay_' || substr(md5(p.patient_id || '|' || p.source_fecha_ingreso::text || '|open'), 1, 16)
        AS stay_id,
    p.patient_id,
    p.source_fecha_ingreso AS fecha_ingreso,
    p.sync_candidate_id,
    p.first_sheet_name,
    p.first_source_row_number,
    'CREATE_ACTIVE_STAY_FROM_INGRESOS_STATUS'::text AS resolution_action
FROM staging.v_hodom_ingreso_status_sync_preview_2026 p
WHERE p.source_status = 'SOURCE_ACTIVO'
  AND p.safety_status = 'BLOCKED_NO_STAY_MATCH'
  AND p.patient_count = 1
  AND p.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM clinical.estadia e
      WHERE e.patient_id = p.patient_id
        AND daterange(p.source_fecha_ingreso, '9999-12-31'::date, '[]') &&
            daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
  );

INSERT INTO clinical.estadia (
    stay_id, patient_id, establecimiento_id,
    fecha_ingreso, fecha_egreso,
    estado, tipo_egreso, origen_derivacion,
    diagnostico_principal,
    created_at, updated_at
)
SELECT
    a.stay_id,
    a.patient_id,
    'est_4a50d9e625a5c238',
    a.fecha_ingreso,
    NULL::date,
    'pendiente_evaluacion',
    NULL::text,
    NULL::text,
    NULL::text,
    now(),
    now()
FROM _hodom_ingreso_status_active_create_apply a
WHERE NOT EXISTS (
    SELECT 1 FROM clinical.estadia e WHERE e.stay_id = a.stay_id
)
AND NOT EXISTS (
    SELECT 1
    FROM clinical.estadia e
    WHERE e.patient_id = a.patient_id
      AND daterange(a.fecha_ingreso, '9999-12-31'::date, '[]') &&
          daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
);

SELECT clinical.transition_estadia(
    a.stay_id,
    'activo',
    'patient_admitting',
    'ingreso_status_sync_2026_05_26: CREATE_ACTIVE_STAY_FROM_INGRESOS_STATUS'
)
FROM _hodom_ingreso_status_active_create_apply a
JOIN clinical.estadia e ON e.stay_id = a.stay_id
WHERE e.estado IS DISTINCT FROM 'activo';

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (a.stay_id, f.field_name)
    'clinical.estadia',
    a.stay_id,
    'drive_import',
    'INGRESOS_2026_DRIVE.xlsx',
    a.resolution_action || '|' || a.fecha_ingreso::text,
    'ingreso_status_sync_2026_05_26',
    f.field_name,
    now()
FROM _hodom_ingreso_status_active_create_apply a
CROSS JOIN (VALUES
    ('stay_id'),
    ('patient_id'),
    ('fecha_ingreso'),
    ('estado'),
    ('CREATE_ACTIVE_STAY_FROM_INGRESOS_STATUS')
) AS f(field_name)
WHERE EXISTS (
    SELECT 1 FROM clinical.estadia e WHERE e.stay_id = a.stay_id
)
AND NOT EXISTS (
    SELECT 1
    FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.estadia'
      AND mp.target_pk = a.stay_id
      AND mp.phase = 'ingreso_status_sync_2026_05_26'
      AND coalesce(mp.field_name, '') = f.field_name
);

CREATE OR REPLACE VIEW staging.v_hodom_ingreso_status_sync_audit_2026 AS
SELECT
    e.stay_id,
    e.patient_id,
    e.fecha_ingreso,
    e.fecha_egreso,
    e.estado,
    e.tipo_egreso,
    count(mp.field_name) AS provenance_fields,
    now() AS generated_at
FROM clinical.estadia e
JOIN migration.provenance mp
  ON mp.target_table = 'clinical.estadia'
 AND mp.target_pk = e.stay_id
 AND mp.phase = 'ingreso_status_sync_2026_05_26'
GROUP BY e.stay_id, e.patient_id, e.fecha_ingreso, e.fecha_egreso, e.estado, e.tipo_egreso;

COMMENT ON VIEW staging.v_hodom_ingreso_status_sync_audit_2026 IS
'PII-bearing audit of clinical.estadia status changes from INGRESOS 2026 DRIVE. Do not export.';

COMMIT;
