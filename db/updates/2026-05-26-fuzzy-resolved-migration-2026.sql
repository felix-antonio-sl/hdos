-- HODOM Drive migration 2026 — fuzzy-resolved controlled promotion.
-- Inserts only net-new routes with unique fuzzy patient, unique active stay and
-- exactly one recognized service. Existing same-day visits remain enrichment debt.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_route_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_route_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_route_gate_2026;
DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_route_preview_2026;

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_route_preview_2026 AS
WITH unique_fuzzy_identity AS (
    SELECT
        source_pk AS blocked_name_norm,
        min(target_pk) AS patient_id,
        count(*) AS proposal_rows
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type = 'patient_identity'
      AND source_table = 'staging.hodom_route_visit'
      AND target_table = 'clinical.paciente'
      AND relation_type = 'same_as'
      AND decision_status = 'proposed'
      AND decided_by = 'simulated_expert_reconciliation'
      AND evidence->>'simulation_run_id' = 'fuzzy_patient_match_2026_05_26'
    GROUP BY source_pk
    HAVING count(DISTINCT target_pk) = 1
),
route_base AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        rv.planned_time,
        rv.service_text,
        rv.address_text,
        rv.source_path,
        rv.drive_id,
        rv.sheet_name,
        rv.source_row_number,
        c.candidate_visit_id,
        ufi.patient_id,
        ufi.blocked_name_norm
    FROM unique_fuzzy_identity ufi
    JOIN staging.hodom_route_visit rv
      ON staging.norm_text(rv.patient_name) = ufi.blocked_name_norm
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    WHERE c.promotion_gate = 'BLOCKED_NO_PATIENT_MATCH'
      AND rv.visit_date >= '2026-01-01'
),
stay_candidates AS (
    SELECT
        rb.*,
        e.stay_id,
        count(*) OVER (PARTITION BY rb.route_visit_id) AS stay_candidate_count
    FROM route_base rb
    JOIN clinical.estadia e
      ON e.patient_id = rb.patient_id
     AND rb.visit_date >= e.fecha_ingreso
     AND rb.visit_date <= coalesce(e.fecha_egreso, '9999-12-31'::date)
),
unique_stay AS (
    SELECT *
    FROM stay_candidates
    WHERE stay_candidate_count = 1
),
service_components AS (
    SELECT
        us.route_visit_id,
        trim(component) AS component_norm,
        CASE
            WHEN trim(component) = 'KTM' THEN 'KTM'
            WHEN trim(component) = 'KTR' THEN 'KTR'
            WHEN trim(component) = 'FONO' THEN 'FONO'
            WHEN trim(component) = 'CA' THEN 'CA'
            WHEN trim(component) = 'CS' THEN 'CS'
            WHEN trim(component) IN ('NTP', 'NPT', 'RETIRO NTP') THEN 'NPT'
            WHEN trim(component) = 'EXAMENES' THEN 'EXAM'
            WHEN trim(component) LIKE 'TTO EV%' THEN 'TTO_EV'
            WHEN trim(component) = 'VM EGRESO' THEN 'VM_EGR'
            WHEN trim(component) = 'VM INGRESO' THEN 'VM_ING'
            WHEN trim(component) = 'ING ENF' THEN 'ING_ENF'
            WHEN trim(component) IN ('KTM ALTA', 'ALTA KTM') THEN 'ALTA_KINE'
            WHEN trim(component) = 'FONO ALTA' THEN 'ALTA_FONO'
            ELSE NULL
        END AS prestacion_id
    FROM unique_stay us
    CROSS JOIN LATERAL regexp_split_to_table(
        coalesce(staging.norm_text(us.service_text), ''),
        '\s*(\+|/)\s*'
    ) AS component
    WHERE trim(component) <> ''
),
service_targets AS (
    SELECT
        sc.route_visit_id,
        count(*) AS service_component_count,
        count(sc.prestacion_id) AS mapped_service_component_count,
        count(DISTINCT cp.prestacion_id) AS service_target_count,
        min(cp.prestacion_id) FILTER (WHERE cp.prestacion_id IS NOT NULL)
            AS prestacion_id
    FROM service_components sc
    LEFT JOIN reference.catalogo_prestacion cp
      ON cp.prestacion_id = sc.prestacion_id
    GROUP BY sc.route_visit_id
),
address_targets AS (
    SELECT
        us.route_visit_id,
        min(d.domicilio_id) AS domicilio_id,
        count(DISTINCT d.domicilio_id) AS address_target_count
    FROM unique_stay us
    JOIN clinical.domicilio d
      ON d.patient_id = us.patient_id
    JOIN territorial.localizacion l
      ON l.localizacion_id = d.localizacion_id
     AND staging.norm_text(l.direccion_texto) = staging.norm_text(us.address_text)
    GROUP BY us.route_visit_id
),
best_professional AS (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.route_visit_id,
        rpm.suggested_provider_id AS provider_id,
        rpm.db_name AS suggested_provider_name,
        rpm.match_quality AS provider_match_quality
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.score DESC NULLS LAST, rpm.db_name
),
preview_base AS (
    SELECT
        us.route_visit_id,
        us.source_path,
        us.candidate_visit_id AS visit_id,
        us.patient_id,
        us.stay_id,
        us.visit_date AS fecha,
        us.planned_time AS hora_plan_inicio,
        bp.provider_id,
        bp.suggested_provider_name,
        bp.provider_match_quality,
        st.prestacion_id,
        at.domicilio_id,
        coalesce(st.service_component_count, 0) AS service_component_count,
        coalesce(st.mapped_service_component_count, 0)
            AS mapped_service_component_count,
        coalesce(st.service_target_count, 0) AS service_target_count,
        coalesce(at.address_target_count, 0) AS address_target_count,
        count(*) OVER (
            PARTITION BY us.patient_id, us.stay_id, us.visit_date
        ) AS batch_day_route_count,
        EXISTS (
            SELECT 1
            FROM operational.visita v
            WHERE v.patient_id = us.patient_id
              AND v.stay_id = us.stay_id
              AND v.fecha = us.visit_date
              AND v.visit_id <> us.candidate_visit_id
              AND NOT EXISTS (
                  SELECT 1
                  FROM unique_stay us2
                  WHERE us2.patient_id = us.patient_id
                    AND us2.stay_id = us.stay_id
                    AND us2.visit_date = us.visit_date
                    AND us2.candidate_visit_id = v.visit_id
              )
        ) AS has_existing_visit
    FROM unique_stay us
    LEFT JOIN service_targets st ON st.route_visit_id = us.route_visit_id
    LEFT JOIN address_targets at ON at.route_visit_id = us.route_visit_id
    LEFT JOIN best_professional bp ON bp.route_visit_id = us.route_visit_id
)
SELECT
    *,
    CASE
        WHEN has_existing_visit THEN 'FUZZY_ENRICH_EXISTING'
        WHEN batch_day_route_count > 1 THEN 'FUZZY_REVIEW_BATCH_DUPLICATE'
        WHEN service_target_count > 1 OR service_component_count > 1
            THEN 'FUZZY_SPLIT_SERVICE_REQUIRED'
        WHEN service_target_count = 1
         AND service_component_count = 1
         AND mapped_service_component_count = 1
            THEN 'FUZZY_INSERT_SINGLE_SERVICE'
        ELSE 'FUZZY_SERVICE_TARGET_MISSING'
    END AS fuzzy_migration_action
FROM preview_base;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_route_preview_2026 IS
'Preview fuzzy-resolved 2026: unique fuzzy identity + unique active stay. Only FUZZY_INSERT_SINGLE_SERVICE is promoted.';

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_route_gate_2026 AS
SELECT
    'fuzzy_resolved_2026_05_26' AS phase,
    count(*) AS total_fuzzy_resolved_routes,
    count(DISTINCT patient_id) AS distinct_patients,
    count(*) FILTER (WHERE has_existing_visit) AS existing_visit_routes,
    count(*) FILTER (WHERE NOT has_existing_visit) AS net_new_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_INSERT_SINGLE_SERVICE')
        AS insert_single_service_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_ENRICH_EXISTING')
        AS enrich_existing_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_SPLIT_SERVICE_REQUIRED')
        AS split_service_required_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_SERVICE_TARGET_MISSING')
        AS service_target_missing_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE')
        AS batch_duplicate_review_routes,
    count(*) FILTER (WHERE provider_id IS NOT NULL) AS with_provider,
    count(*) FILTER (WHERE domicilio_id IS NOT NULL) AS with_domicilio,
    now() AS generated_at
FROM staging.v_hodom_fuzzy_resolved_route_preview_2026;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_route_gate_2026 IS
'Gate agregado antes de promover rutas fuzzy-resolved. Seguro para documentacion.';

INSERT INTO operational.visita (
    visit_id,
    stay_id,
    patient_id,
    provider_id,
    fecha,
    hora_plan_inicio,
    estado,
    doc_estado,
    rem_reportable,
    prestacion_id,
    domicilio_id,
    created_at,
    updated_at
)
SELECT DISTINCT ON (pv.visit_id)
    pv.visit_id,
    pv.stay_id,
    pv.patient_id,
    pv.provider_id,
    pv.fecha,
    pv.hora_plan_inicio,
    'PROGRAMADA',
    'pendiente',
    false,
    pv.prestacion_id,
    pv.domicilio_id,
    now(),
    now()
FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
WHERE pv.fuzzy_migration_action = 'FUZZY_INSERT_SINGLE_SERVICE'
  AND NOT EXISTS (
      SELECT 1
      FROM operational.visita v
      WHERE v.visit_id = pv.visit_id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM operational.visita v
      WHERE v.patient_id = pv.patient_id
        AND v.stay_id = pv.stay_id
        AND v.fecha = pv.fecha
        AND v.visit_id <> pv.visit_id
  );

INSERT INTO migration.provenance (
    target_table,
    target_pk,
    source_type,
    source_file,
    source_key,
    phase,
    field_name,
    created_at
)
SELECT DISTINCT
    'operational.visita',
    pv.visit_id,
    'drive_import',
    pv.source_path,
    pv.route_visit_id,
    'fuzzy_resolved_2026_05_26',
    f.field_name,
    now()
FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
CROSS JOIN LATERAL (
    VALUES
        ('visit_id'::text, true),
        ('stay_id'::text, true),
        ('patient_id'::text, true),
        ('fecha'::text, true),
        ('prestacion_id'::text, true),
        ('hora_plan_inicio'::text, pv.hora_plan_inicio IS NOT NULL),
        ('estado'::text, true),
        ('domicilio_id'::text, pv.domicilio_id IS NOT NULL),
        ('provider_id'::text, pv.provider_id IS NOT NULL)
) AS f(field_name, include_field)
WHERE (
      pv.fuzzy_migration_action = 'FUZZY_INSERT_SINGLE_SERVICE'
      OR (
          pv.fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE'
          AND EXISTS (
              SELECT 1
              FROM operational.visita v
              WHERE v.visit_id = pv.visit_id
          )
      )
  )
  AND f.include_field
  AND EXISTS (
      SELECT 1
      FROM operational.visita v
      WHERE v.visit_id = pv.visit_id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM migration.provenance mp
      WHERE mp.target_table = 'operational.visita'
        AND mp.target_pk = pv.visit_id
        AND mp.phase = 'fuzzy_resolved_2026_05_26'
        AND coalesce(mp.field_name, '') = f.field_name
  );

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_route_audit_2026 AS
SELECT
    pv.route_visit_id,
    pv.visit_id,
    pv.fecha,
    pv.fuzzy_migration_action,
    CASE WHEN v.visit_id IS NOT NULL THEN true ELSE false END AS inserted,
    v.provider_id IS NOT NULL AS has_provider,
    v.prestacion_id IS NOT NULL AS has_prestacion,
    v.domicilio_id IS NOT NULL AS has_domicilio,
    (
        SELECT count(*)
        FROM migration.provenance mp
        WHERE mp.target_table = 'operational.visita'
          AND mp.target_pk = pv.visit_id
          AND mp.phase = 'fuzzy_resolved_2026_05_26'
    ) AS provenance_fields
FROM staging.v_hodom_fuzzy_resolved_route_preview_2026 pv
LEFT JOIN operational.visita v ON v.visit_id = pv.visit_id;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_route_audit_2026 IS
'Auditoria post-promocion fuzzy-resolved. No contiene nombres ni direcciones.';

CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_route_summary_2026 AS
SELECT
    'fuzzy_resolved_2026_05_26' AS phase,
    count(*) AS preview_routes,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_INSERT_SINGLE_SERVICE')
        AS expected_insertable_visits,
    count(*) FILTER (WHERE fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE')
        AS batch_duplicate_review_routes,
    count(*) FILTER (WHERE inserted) AS inserted_visits,
    count(*) FILTER (
        WHERE inserted
          AND fuzzy_migration_action = 'FUZZY_REVIEW_BATCH_DUPLICATE'
    ) AS inserted_batch_duplicate_review_routes,
    count(*) FILTER (WHERE inserted AND has_provider) AS inserted_with_provider,
    count(*) FILTER (WHERE inserted AND has_prestacion) AS inserted_with_prestacion,
    count(*) FILTER (WHERE inserted AND has_domicilio) AS inserted_with_domicilio,
    (SELECT count(*) FROM migration.provenance
     WHERE phase = 'fuzzy_resolved_2026_05_26') AS total_provenance,
    now() AS generated_at
FROM staging.v_hodom_fuzzy_resolved_route_audit_2026;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_route_summary_2026 IS
'Resumen agregado de promocion fuzzy-resolved. Seguro para documentacion.';

COMMIT;
