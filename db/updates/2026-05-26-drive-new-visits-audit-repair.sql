-- HODOM Drive migration 2026 — repair aggregate views for Phase 2.
-- View-only repair: recreates gate, audit and summary views without touching core data.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_new_visits_summary_2026;
DROP VIEW IF EXISTS staging.v_hodom_new_visits_audit_2026;
DROP VIEW IF EXISTS staging.v_hodom_new_visits_gate_2026;

CREATE OR REPLACE VIEW staging.v_hodom_new_visits_gate_2026 AS
SELECT
    'new_visits_2026_05_26' AS phase,
    count(*) AS total_candidates,
    count(*) FILTER (WHERE tiene_prestacion) AS with_service,
    count(*) FILTER (WHERE domicilio_id IS NOT NULL) AS with_domicilio,
    count(*) FILTER (WHERE provider_id IS NOT NULL) AS with_provider,
    count(*) FILTER (
        WHERE tiene_prestacion
          AND domicilio_id IS NOT NULL
          AND provider_id IS NOT NULL
    )
        AS fully_anchored,
    count(*) FILTER (WHERE NOT tiene_prestacion)
        AS missing_service,
    count(*) FILTER (WHERE tiene_prestacion AND domicilio_id IS NULL)
        AS accepted_null_domicilio,
    count(*) FILTER (
        WHERE tiene_prestacion
          AND domicilio_id IS NOT NULL
          AND provider_id IS NULL
    )
        AS accepted_null_provider,
    now() AS generated_at
FROM staging.v_hodom_new_visits_preview_2026;

COMMENT ON VIEW staging.v_hodom_new_visits_gate_2026 IS
'Gate agregado de nuevas visitas Drive 2026. Reparacion view-only.';

CREATE OR REPLACE VIEW staging.v_hodom_new_visits_audit_2026 AS
WITH provenance_targets AS (
    SELECT
        target_pk AS visit_id,
        min(source_key) AS route_visit_id,
        min(source_file) AS source_path,
        count(*) AS provenance_fields
    FROM migration.provenance
    WHERE target_table = 'operational.visita'
      AND phase = 'new_visits_2026_05_26'
    GROUP BY target_pk
)
SELECT
    pt.route_visit_id,
    pt.visit_id,
    v.fecha,
    CASE
        WHEN v.visit_id IS NULL THEN 'NOT_FOUND_IN_CORE'
        WHEN v.prestacion_id IS NULL THEN 'MISSING_SERVICE_TARGET'
        WHEN v.domicilio_id IS NULL THEN 'ACCEPTED_NULL_DOMICILIO'
        WHEN v.provider_id IS NULL THEN 'ACCEPTED_NULL_PROVIDER'
        ELSE 'FULLY_ANCHORED'
    END AS anchor_status,
    CASE WHEN v.visit_id IS NOT NULL THEN true ELSE false END AS inserted,
    v.provider_id IS NOT NULL AS has_provider,
    v.prestacion_id IS NOT NULL AS has_prestacion,
    v.domicilio_id IS NOT NULL AS has_domicilio,
    v.estado,
    v.created_at AS inserted_at,
    pt.provenance_fields
FROM provenance_targets pt
LEFT JOIN operational.visita v ON v.visit_id = pt.visit_id;

COMMENT ON VIEW staging.v_hodom_new_visits_audit_2026 IS
'Auditoria agregada de Phase 2 Drive new visits. No contiene nombres ni direcciones.';

CREATE OR REPLACE VIEW staging.v_hodom_new_visits_summary_2026 AS
WITH new_targets AS (
    SELECT DISTINCT target_pk AS visit_id
    FROM migration.provenance
    WHERE target_table = 'operational.visita'
      AND phase = 'new_visits_2026_05_26'
),
pilot_targets AS (
    SELECT DISTINCT target_pk AS visit_id
    FROM migration.provenance
    WHERE target_table = 'operational.visita'
      AND phase = 'pilot_minimal_2026_05_26'
),
drive_targets AS (
    SELECT visit_id FROM new_targets
    UNION
    SELECT visit_id FROM pilot_targets
)
SELECT
    'new_visits_2026_05_26' AS phase,
    (SELECT count(*) FROM staging.v_hodom_new_visits_preview_2026)
        AS remaining_preview_candidate_visits,
    (SELECT count(*) FROM staging.v_hodom_new_visits_audit_2026 WHERE inserted)
        AS inserted_visits,
    (SELECT count(*) FROM staging.v_hodom_new_visits_audit_2026
     WHERE inserted AND has_provider)
        AS with_provider,
    (SELECT count(*) FROM staging.v_hodom_new_visits_audit_2026
     WHERE inserted AND has_prestacion)
        AS with_prestacion,
    (SELECT count(*) FROM staging.v_hodom_new_visits_audit_2026
     WHERE inserted AND has_domicilio)
        AS with_domicilio,
    (SELECT count(*) FROM new_targets) AS phase_provenance_visits,
    (SELECT count(*) FROM pilot_targets) AS pilot_provenance_visits,
    (
        SELECT count(*)
        FROM new_targets nt
        JOIN pilot_targets pt ON pt.visit_id = nt.visit_id
    ) AS overlap_with_pilot,
    (
        SELECT count(*)
        FROM new_targets nt
        WHERE NOT EXISTS (
            SELECT 1 FROM pilot_targets pt WHERE pt.visit_id = nt.visit_id
        )
    ) AS new_phase_not_pilot,
    (
        SELECT count(*)
        FROM pilot_targets pt
        WHERE NOT EXISTS (
            SELECT 1 FROM new_targets nt WHERE nt.visit_id = pt.visit_id
        )
    ) AS pilot_only,
    (SELECT count(*) FROM drive_targets) AS drive_sourced_visits,
    (
        SELECT count(*)
        FROM migration.provenance
        WHERE phase = 'new_visits_2026_05_26'
    ) AS total_provenance,
    now() AS generated_at;

COMMENT ON VIEW staging.v_hodom_new_visits_summary_2026 IS
'Resumen agregado Phase 2. Distingue cobertura de provenance, solapamiento con piloto y visitas Drive-sourced.';

COMMIT;
