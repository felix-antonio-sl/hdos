-- HODOM Drive 2026 — resolve route rows blocked by missing active stay.
-- Uses INGRESOS as the temporal episode anchor and daterange && as the
-- only overlap test. Simulated reconciliation is not human approval.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_active_stay_resolution_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_active_stay_resolution_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_active_stay_resolution_preview_2026;

CREATE OR REPLACE VIEW staging.v_hodom_active_stay_resolution_preview_2026 AS
WITH blocked AS (
    SELECT
        c.route_visit_id,
        c.visit_date,
        c.matched_patient_id AS patient_id,
        p.rut
    FROM staging.v_hodom_route_promotion_contract c
    JOIN clinical.paciente p ON p.patient_id = c.matched_patient_id
    WHERE c.visit_year = 2026
      AND c.promotion_gate = 'BLOCKED_NO_ACTIVE_STAY_MATCH'
      AND c.matched_patient_id IS NOT NULL
      AND c.visit_date IS NOT NULL
),
ingreso_anchor AS (
    SELECT DISTINCT ON (b.route_visit_id)
        b.route_visit_id,
        b.visit_date,
        b.patient_id,
        i.ingreso_id,
        i.rut_normalizado,
        i.fecha_ingreso,
        CASE
            WHEN i.fecha_egreso IS NULL THEN NULL::date
            ELSE i.fecha_egreso
        END AS fecha_egreso,
        i.estado,
        i.motivo_egreso,
        i.servicio_origen,
        i.diagnostico_egreso,
        i.sheet_name,
        i.source_row_number,
        CASE
            WHEN i.estado = 'ACTIVO' AND i.fecha_egreso IS NULL
                THEN 'OPEN_INGRESO_ACTIVE'
            ELSE 'CLOSED_INGRESO_VALID'
        END AS ingreso_anchor_kind
    FROM blocked b
    JOIN staging.hodom_ingreso_2026 i
      ON i.rut_normalizado = staging.norm_text(regexp_replace(b.rut, '[.\s,]+', '', 'g'))
     AND i.fecha_ingreso IS NOT NULL
     AND (
        (
            i.estado = 'ACTIVO'
            AND i.fecha_egreso IS NULL
            AND b.visit_date >= i.fecha_ingreso
        )
        OR (
            i.fecha_egreso IS NOT NULL
            AND i.fecha_egreso >= i.fecha_ingreso
            AND b.visit_date <@ daterange(i.fecha_ingreso, i.fecha_egreso, '[]')
        )
     )
    ORDER BY
        b.route_visit_id,
        CASE WHEN i.estado = 'ACTIVO' AND i.fecha_egreso IS NULL THEN 0 ELSE 1 END,
        i.fecha_ingreso DESC,
        coalesce(i.fecha_egreso, '9999-12-31'::date) DESC,
        i.source_row_number
),
episode_anchor AS (
    SELECT
        patient_id,
        ingreso_id,
        rut_normalizado,
        fecha_ingreso,
        fecha_egreso,
        ingreso_anchor_kind,
        motivo_egreso,
        servicio_origen,
        diagnostico_egreso,
        sheet_name,
        source_row_number,
        min(visit_date) AS first_route_visit_date,
        max(visit_date) AS last_route_visit_date,
        count(*) AS route_rows
    FROM ingreso_anchor
    GROUP BY
        patient_id, ingreso_id, rut_normalizado, fecha_ingreso, fecha_egreso,
        ingreso_anchor_kind, motivo_egreso, servicio_origen, diagnostico_egreso,
        sheet_name, source_row_number
),
overlap AS (
    SELECT
        ea.*,
        count(e.stay_id) AS overlapping_stay_count,
        min(e.stay_id) AS overlapping_stay_id
    FROM episode_anchor ea
    LEFT JOIN clinical.estadia e
      ON e.patient_id = ea.patient_id
     AND daterange(ea.fecha_ingreso, coalesce(ea.fecha_egreso, '9999-12-31'::date), '[]') &&
         daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
    GROUP BY
        ea.patient_id, ea.ingreso_id, ea.rut_normalizado, ea.fecha_ingreso, ea.fecha_egreso,
        ea.ingreso_anchor_kind, ea.motivo_egreso, ea.servicio_origen,
        ea.diagnostico_egreso, ea.sheet_name, ea.source_row_number,
        ea.first_route_visit_date, ea.last_route_visit_date, ea.route_rows
),
extension_candidate AS (
    SELECT
        o.*,
        e.stay_id AS existing_stay_id,
        least(e.fecha_ingreso, o.fecha_ingreso) AS resolved_fecha_ingreso,
        greatest(e.fecha_egreso, o.fecha_egreso) AS resolved_fecha_egreso
    FROM overlap o
    JOIN clinical.estadia e ON e.stay_id = o.overlapping_stay_id
    WHERE o.overlapping_stay_count = 1
      AND o.fecha_egreso IS NOT NULL
),
extension_safety AS (
    SELECT
        ec.*,
        NOT EXISTS (
            SELECT 1
            FROM clinical.estadia other
            WHERE other.patient_id = ec.patient_id
              AND other.stay_id <> ec.existing_stay_id
              AND daterange(ec.resolved_fecha_ingreso, ec.resolved_fecha_egreso, '[]') &&
                  daterange(other.fecha_ingreso, coalesce(other.fecha_egreso, '9999-12-31'::date), '[]')
        ) AS extension_has_no_other_overlap
    FROM extension_candidate ec
),
episode_actions AS (
    SELECT
        'stay_' || substr(md5(o.patient_id || '|' || o.fecha_ingreso::text || '|' || coalesce(o.fecha_egreso::text, 'open')), 1, 16)
            AS stay_id,
        NULL::text AS existing_stay_id,
        o.patient_id,
        o.ingreso_id,
        o.rut_normalizado,
        o.fecha_ingreso AS resolved_fecha_ingreso,
        o.fecha_egreso AS resolved_fecha_egreso,
        o.fecha_ingreso AS ingreso_fecha_ingreso,
        o.fecha_egreso AS ingreso_fecha_egreso,
        o.motivo_egreso,
        o.servicio_origen,
        o.diagnostico_egreso,
        o.sheet_name,
        o.source_row_number,
        o.first_route_visit_date,
        o.last_route_visit_date,
        o.route_rows,
        o.overlapping_stay_count,
        o.ingreso_anchor_kind AS resolution_action,
        CASE
            WHEN o.overlapping_stay_count = 0 THEN 'APPLY_SAFE'
            ELSE 'BLOCKED_OVERLAPS_EXISTING'
        END AS safety_status
    FROM overlap o
    WHERE o.ingreso_anchor_kind = 'OPEN_INGRESO_ACTIVE'

    UNION ALL

    SELECT
        es.existing_stay_id AS stay_id,
        es.existing_stay_id,
        es.patient_id,
        es.ingreso_id,
        es.rut_normalizado,
        es.resolved_fecha_ingreso,
        es.resolved_fecha_egreso,
        es.fecha_ingreso AS ingreso_fecha_ingreso,
        es.fecha_egreso AS ingreso_fecha_egreso,
        es.motivo_egreso,
        es.servicio_origen,
        es.diagnostico_egreso,
        es.sheet_name,
        es.source_row_number,
        es.first_route_visit_date,
        es.last_route_visit_date,
        es.route_rows,
        es.overlapping_stay_count,
        'EXTEND_EXISTING_STAY_FROM_INGRESOS' AS resolution_action,
        CASE
            WHEN es.extension_has_no_other_overlap THEN 'APPLY_SAFE'
            ELSE 'BLOCKED_EXTENSION_OVERLAP'
        END AS safety_status
    FROM extension_safety es

    UNION ALL

    SELECT
        'stay_' || substr(md5(o.patient_id || '|' || o.fecha_ingreso::text || '|' || o.fecha_egreso::text), 1, 16)
            AS stay_id,
        NULL::text AS existing_stay_id,
        o.patient_id,
        o.ingreso_id,
        o.rut_normalizado,
        o.fecha_ingreso AS resolved_fecha_ingreso,
        o.fecha_egreso AS resolved_fecha_egreso,
        o.fecha_ingreso AS ingreso_fecha_ingreso,
        o.fecha_egreso AS ingreso_fecha_egreso,
        o.motivo_egreso,
        o.servicio_origen,
        o.diagnostico_egreso,
        o.sheet_name,
        o.source_row_number,
        o.first_route_visit_date,
        o.last_route_visit_date,
        o.route_rows,
        o.overlapping_stay_count,
        'CREATE_CLOSED_STAY_FROM_INGRESOS' AS resolution_action,
        CASE
            WHEN o.overlapping_stay_count = 0 THEN 'APPLY_SAFE'
            ELSE 'BLOCKED_OVERLAPS_EXISTING'
        END AS safety_status
    FROM overlap o
    WHERE o.ingreso_anchor_kind = 'CLOSED_INGRESO_VALID'
      AND o.overlapping_stay_count = 0
),
unresolved AS (
    SELECT
        NULL::text AS stay_id,
        NULL::text AS existing_stay_id,
        b.patient_id,
        NULL::text AS ingreso_id,
        staging.norm_text(regexp_replace(b.rut, '[.\s,]+', '', 'g')) AS rut_normalizado,
        NULL::date AS resolved_fecha_ingreso,
        NULL::date AS resolved_fecha_egreso,
        NULL::date AS ingreso_fecha_ingreso,
        NULL::date AS ingreso_fecha_egreso,
        NULL::text AS motivo_egreso,
        NULL::text AS servicio_origen,
        NULL::text AS diagnostico_egreso,
        NULL::text AS sheet_name,
        NULL::integer AS source_row_number,
        b.visit_date AS first_route_visit_date,
        b.visit_date AS last_route_visit_date,
        1::bigint AS route_rows,
        0::bigint AS overlapping_stay_count,
        'UNRESOLVED_NO_INGRESOS_ANCHOR' AS resolution_action,
        'REVIEW_REQUIRED' AS safety_status
    FROM blocked b
    WHERE NOT EXISTS (
        SELECT 1 FROM ingreso_anchor ia WHERE ia.route_visit_id = b.route_visit_id
    )
)
SELECT * FROM episode_actions
UNION ALL
SELECT * FROM unresolved;

COMMENT ON VIEW staging.v_hodom_active_stay_resolution_preview_2026 IS
'Episode-level preview for 2026 route rows blocked by active stay. Uses INGRESOS anchors and daterange &&. Contains IDs only; do not export PII.';

CREATE OR REPLACE VIEW staging.v_hodom_active_stay_resolution_summary_2026 AS
SELECT
    resolution_action,
    safety_status,
    count(*) AS episode_rows,
    sum(route_rows) AS route_rows,
    count(DISTINCT patient_id) AS distinct_patients,
    min(first_route_visit_date) AS min_route_visit_date,
    max(last_route_visit_date) AS max_route_visit_date,
    now() AS generated_at
FROM staging.v_hodom_active_stay_resolution_preview_2026
GROUP BY resolution_action, safety_status
ORDER BY resolution_action, safety_status;

COMMENT ON VIEW staging.v_hodom_active_stay_resolution_summary_2026 IS
'Aggregate summary of active-stay resolution for Drive 2026. Safe for documentation.';

CREATE TEMP TABLE _hodom_active_stay_resolution_apply ON COMMIT DROP AS
SELECT *
FROM staging.v_hodom_active_stay_resolution_preview_2026
WHERE safety_status = 'APPLY_SAFE'
  AND resolution_action IN (
      'OPEN_INGRESO_ACTIVE',
      'CREATE_CLOSED_STAY_FROM_INGRESOS',
      'EXTEND_EXISTING_STAY_FROM_INGRESOS'
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
    'est_4a50d9e625a5c238' AS establecimiento_id,
    a.resolved_fecha_ingreso,
    a.resolved_fecha_egreso,
    'pendiente_evaluacion' AS estado,
    CASE
        WHEN lower(trim(a.motivo_egreso)) = 'alta' THEN 'alta_clinica'
        WHEN lower(trim(a.motivo_egreso)) = 'rehospitalizacion' THEN 'reingreso'
        WHEN lower(trim(a.motivo_egreso)) IN ('fallecido', 'fallecida') THEN 'fallecido_esperado'
        ELSE NULL
    END AS tipo_egreso,
    CASE
        WHEN lower(trim(a.servicio_origen)) IN ('urgencia', 'ue', 'uti') THEN 'urgencia'
        WHEN lower(trim(a.servicio_origen)) = 'aps' THEN 'APS'
        ELSE NULL
    END AS origen_derivacion,
    a.diagnostico_egreso,
    now(),
    now()
FROM _hodom_active_stay_resolution_apply a
WHERE a.existing_stay_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM clinical.estadia e WHERE e.stay_id = a.stay_id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM clinical.estadia e
      WHERE e.patient_id = a.patient_id
        AND daterange(a.resolved_fecha_ingreso, coalesce(a.resolved_fecha_egreso, '9999-12-31'::date), '[]') &&
            daterange(e.fecha_ingreso, coalesce(e.fecha_egreso, '9999-12-31'::date), '[]')
  );

UPDATE clinical.estadia e
SET
    fecha_ingreso = a.resolved_fecha_ingreso,
    fecha_egreso = a.resolved_fecha_egreso,
    updated_at = now()
FROM _hodom_active_stay_resolution_apply a
WHERE a.existing_stay_id = e.stay_id
  AND a.resolution_action = 'EXTEND_EXISTING_STAY_FROM_INGRESOS'
  AND (
      e.fecha_ingreso IS DISTINCT FROM a.resolved_fecha_ingreso
      OR e.fecha_egreso IS DISTINCT FROM a.resolved_fecha_egreso
  )
  AND NOT EXISTS (
      SELECT 1
      FROM clinical.estadia other
      WHERE other.patient_id = e.patient_id
        AND other.stay_id <> e.stay_id
        AND daterange(a.resolved_fecha_ingreso, coalesce(a.resolved_fecha_egreso, '9999-12-31'::date), '[]') &&
            daterange(other.fecha_ingreso, coalesce(other.fecha_egreso, '9999-12-31'::date), '[]')
  );

INSERT INTO migration.provenance (
    target_table, target_pk, source_type, source_file, source_key,
    phase, field_name, created_at
)
SELECT DISTINCT ON (a.stay_id, f.field_name)
    'clinical.estadia',
    a.stay_id,
    'drive_import',
    'INGRESOS_2026_DRIVE.xlsx',
    coalesce(a.ingreso_id, a.rut_normalizado || '|' || a.ingreso_fecha_ingreso::text),
    'active_stay_resolution_2026_05_26',
    f.field_name,
    now()
FROM _hodom_active_stay_resolution_apply a
CROSS JOIN (VALUES
    ('stay_id'),
    ('patient_id'),
    ('fecha_ingreso'),
    ('fecha_egreso'),
    ('estado'),
    ('tipo_egreso'),
    ('origen_derivacion'),
    ('diagnostico_principal'),
    ('resolution_action')
) AS f(field_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM migration.provenance mp
    WHERE mp.target_table = 'clinical.estadia'
      AND mp.target_pk = a.stay_id
      AND mp.phase = 'active_stay_resolution_2026_05_26'
      AND coalesce(mp.field_name, '') = f.field_name
);

CREATE OR REPLACE VIEW staging.v_hodom_active_stay_resolution_audit_2026 AS
SELECT
    e.stay_id,
    e.patient_id,
    e.fecha_ingreso,
    e.fecha_egreso,
    e.estado,
    count(mp.field_name) AS provenance_fields,
    now() AS generated_at
FROM clinical.estadia e
JOIN migration.provenance mp
  ON mp.target_table = 'clinical.estadia'
 AND mp.target_pk = e.stay_id
 AND mp.phase = 'active_stay_resolution_2026_05_26'
GROUP BY e.stay_id, e.patient_id, e.fecha_ingreso, e.fecha_egreso, e.estado;

COMMENT ON VIEW staging.v_hodom_active_stay_resolution_audit_2026 IS
'PII-bearing audit of stays inserted or extended by active_stay_resolution_2026_05_26. Do not export.';

COMMIT;
