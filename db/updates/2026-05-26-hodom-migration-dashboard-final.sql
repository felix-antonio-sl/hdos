-- HODOM Drive 2026 - final dashboard refresh after stay resolution,
-- word-overlap V2 materialization, and patient name normalization.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_migration_dashboard;
CREATE OR REPLACE VIEW staging.v_hodom_migration_dashboard AS
WITH contract_v2 AS (
    SELECT promotion_gate, count(*) AS route_rows
    FROM staging.v_hodom_route_promotion_contract_v2
    WHERE visit_year = 2026
    GROUP BY promotion_gate
)
SELECT
    'Migration 2026 Dashboard' AS title,
    (SELECT count(*) FROM staging.hodom_route_visit WHERE visit_date >= '2026-01-01') AS drive_routes_2026,
    (SELECT count(*) FROM operational.visita WHERE visit_id LIKE 'drv_route_%' AND fecha >= '2026-01-01') AS drive_visits_in_core,
    (SELECT count(*) FROM clinical.paciente) AS total_patients,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance
     WHERE phase = 'create_patients_2026_05_26'
       AND target_table = 'clinical.paciente') AS patients_created_from_ingresos,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance
     WHERE phase = 'patient_name_normalization_2026_05_26'
       AND target_table = 'clinical.paciente') AS patients_name_normalized_from_ingresos,
    (SELECT count(*) FROM clinical.estadia) AS total_stays,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance
     WHERE phase IN ('create_stays_2026_05_26', 'create_stays_v2_2026_05_26')
       AND target_table = 'clinical.estadia') AS stays_created_from_ingresos,
    (SELECT count(DISTINCT target_pk) FROM migration.provenance
     WHERE phase = 'active_stay_resolution_2026_05_26'
       AND target_table = 'clinical.estadia') AS active_stays_resolved_from_ingresos,
    (SELECT count(*) FROM staging.hodom_ingreso_2026) AS ingresos_staged,
    (SELECT count(*) FROM staging.hodom_ingreso_2026 WHERE rut_normalizado IS NOT NULL) AS ingresos_with_rut,
    (SELECT count(DISTINCT rut_normalizado) FROM staging.hodom_ingreso_2026 WHERE rut_normalizado IS NOT NULL) AS distinct_ruts_ingresos,
    (SELECT count(*) FROM staging.hodom_patient_word_overlap_match_2026) AS word_overlap_materialized_rows,
    (SELECT count(*) FROM migration.provenance
     WHERE phase = 'v2_duplicate_enrichment_2026_05_26'
       AND target_table = 'operational.visita') AS v2_duplicate_enriched_fields,
    coalesce((SELECT route_rows FROM contract_v2 WHERE promotion_gate = 'BLOCKED_NO_PATIENT_MATCH'), 0) AS contract_v2_blocked_no_patient,
    coalesce((SELECT route_rows FROM contract_v2 WHERE promotion_gate = 'BLOCKED_NO_ACTIVE_STAY_MATCH'), 0) AS contract_v2_blocked_no_active_stay,
    (SELECT count(*) FROM migration.provenance
     WHERE phase LIKE '%2026%'
       AND target_table IN ('operational.visita', 'clinical.paciente', 'clinical.estadia')) AS total_provenance_migration,
    now() AS generated_at;

COMMENT ON VIEW staging.v_hodom_migration_dashboard IS
'Final consolidated dashboard for HODOM Drive 2026 migration. Includes INGRESOS-created patients/stays, active stay resolution, patient-name normalization, materialized word-overlap V2 metrics, and V2 duplicate enrichment.';

COMMIT;
