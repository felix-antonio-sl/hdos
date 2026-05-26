-- HODOM Drive expert reconciliation recommendations
-- Simulated specialist recommendations for concrete mapping targets. These are proposed only.

BEGIN;

WITH ready_routes AS (
    SELECT
        rv.route_visit_id,
        rv.service_text,
        rv.address_text,
        pid.target_pk AS patient_id
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    JOIN staging.hodom_reconciliation_decision pid
      ON pid.source_table = 'staging.hodom_route_visit'
     AND pid.source_pk = rv.route_visit_id
     AND pid.anchor_type = 'patient_identity'
     AND pid.relation_type = 'same_as'
     AND pid.decision_status = 'proposed'
     AND pid.decided_by = 'simulated_agent_reconciliation'
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
),
service_components AS (
    SELECT
        r.route_visit_id,
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
    FROM ready_routes r
    CROSS JOIN LATERAL regexp_split_to_table(
        staging.norm_text(r.service_text),
        '\s*(\+|/)\s*'
    ) AS component
),
service_recommendations AS (
    SELECT DISTINCT
        sc.route_visit_id,
        sc.component_norm,
        cp.prestacion_id
    FROM service_components sc
    JOIN reference.catalogo_prestacion cp
      ON cp.prestacion_id = sc.prestacion_id
    WHERE sc.prestacion_id IS NOT NULL
),
address_recommendations AS (
    SELECT DISTINCT
        r.route_visit_id,
        d.domicilio_id
    FROM ready_routes r
    JOIN clinical.domicilio d
      ON d.patient_id = r.patient_id
    JOIN territorial.localizacion l
      ON l.localizacion_id = d.localizacion_id
     AND staging.norm_text(l.direccion_texto) = staging.norm_text(r.address_text)
)
INSERT INTO staging.hodom_reconciliation_decision (
    decision_id,
    anchor_type,
    source_table,
    source_pk,
    target_table,
    target_pk,
    relation_type,
    decision_status,
    decided_by,
    decided_at,
    rationale,
    evidence,
    updated_at
)
SELECT
    'expert_svc_' || substr(md5(
        sr.route_visit_id || '|' ||
        sr.prestacion_id || '|' ||
        sr.component_norm
    ), 1, 22) AS decision_id,
    'service_prestacion' AS anchor_type,
    'staging.hodom_route_visit' AS source_table,
    sr.route_visit_id AS source_pk,
    'reference.catalogo_prestacion' AS target_table,
    sr.prestacion_id AS target_pk,
    'maps_to' AS relation_type,
    'proposed' AS decision_status,
    'simulated_expert_reconciliation' AS decided_by,
    now() AS decided_at,
    'EXPERT_RECOMMENDATION: abreviatura o componente de servicio reconocido por regla operacional; requiere revision responsable antes de promover.' AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'expert_reconciliation_2026_05_26_v1',
        'mapping_family', 'service_abbreviation_rule',
        'component_norm', sr.component_norm,
        'confidence', 'high_rule_based',
        'human_required', true
    ) AS evidence,
    now() AS updated_at
FROM service_recommendations sr
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = 'service_prestacion'
      AND d.source_table = 'staging.hodom_route_visit'
      AND d.source_pk = sr.route_visit_id
      AND d.target_table = 'reference.catalogo_prestacion'
      AND d.target_pk = sr.prestacion_id
      AND d.relation_type = 'maps_to'
);

WITH ready_routes AS (
    SELECT
        rv.route_visit_id,
        rv.address_text,
        pid.target_pk AS patient_id
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    JOIN staging.hodom_reconciliation_decision pid
      ON pid.source_table = 'staging.hodom_route_visit'
     AND pid.source_pk = rv.route_visit_id
     AND pid.anchor_type = 'patient_identity'
     AND pid.relation_type = 'same_as'
     AND pid.decision_status = 'proposed'
     AND pid.decided_by = 'simulated_agent_reconciliation'
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
),
address_recommendations AS (
    SELECT DISTINCT
        r.route_visit_id,
        d.domicilio_id
    FROM ready_routes r
    JOIN clinical.domicilio d
      ON d.patient_id = r.patient_id
    JOIN territorial.localizacion l
      ON l.localizacion_id = d.localizacion_id
     AND staging.norm_text(l.direccion_texto) = staging.norm_text(r.address_text)
)
INSERT INTO staging.hodom_reconciliation_decision (
    decision_id,
    anchor_type,
    source_table,
    source_pk,
    target_table,
    target_pk,
    relation_type,
    decision_status,
    decided_by,
    decided_at,
    rationale,
    evidence,
    updated_at
)
SELECT
    'expert_addr_' || substr(md5(
        ar.route_visit_id || '|' ||
        ar.domicilio_id
    ), 1, 21) AS decision_id,
    'address_domicilio' AS anchor_type,
    'staging.hodom_route_visit' AS source_table,
    ar.route_visit_id AS source_pk,
    'clinical.domicilio' AS target_table,
    ar.domicilio_id AS target_pk,
    'maps_to' AS relation_type,
    'proposed' AS decision_status,
    'simulated_expert_reconciliation' AS decided_by,
    now() AS decided_at,
    'EXPERT_RECOMMENDATION: domicilio exacto para paciente y localizacion; requiere revision responsable antes de promover.' AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'expert_reconciliation_2026_05_26_v1',
        'mapping_family', 'patient_localizacion_exact_address',
        'confidence', 'high_exact_patient_address',
        'human_required', true
    ) AS evidence,
    now() AS updated_at
FROM address_recommendations ar
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = 'address_domicilio'
      AND d.source_table = 'staging.hodom_route_visit'
      AND d.source_pk = ar.route_visit_id
      AND d.target_table = 'clinical.domicilio'
      AND d.target_pk = ar.domicilio_id
      AND d.relation_type = 'maps_to'
);

DROP VIEW IF EXISTS staging.v_hodom_expert_reconciliation_recommendation_summary;
DROP VIEW IF EXISTS staging.v_hodom_expert_migration_readiness_summary;
DROP VIEW IF EXISTS staging.v_hodom_expert_migration_readiness;

CREATE OR REPLACE VIEW staging.v_hodom_expert_reconciliation_recommendation_summary AS
SELECT
    anchor_type,
    target_table,
    relation_type,
    decision_status,
    decided_by,
    count(*) AS recommendation_rows,
    count(DISTINCT source_pk) AS affected_route_rows,
    count(DISTINCT target_pk) AS distinct_targets
FROM staging.hodom_reconciliation_decision
WHERE decided_by = 'simulated_expert_reconciliation'
GROUP BY
    anchor_type,
    target_table,
    relation_type,
    decision_status,
    decided_by;

CREATE OR REPLACE VIEW staging.v_hodom_expert_migration_readiness AS
WITH ready_routes AS (
    SELECT
        rv.route_visit_id
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    WHERE c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
),
expert_targets AS (
    SELECT
        source_pk AS route_visit_id,
        count(*) FILTER (WHERE anchor_type = 'service_prestacion') AS service_target_count,
        count(*) FILTER (WHERE anchor_type = 'address_domicilio') AS address_target_count,
        count(*) FILTER (WHERE anchor_type = 'professional_provider') AS professional_target_count
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND decision_status = 'proposed'
      AND source_table = 'staging.hodom_route_visit'
    GROUP BY source_pk
)
SELECT
    r.route_visit_id,
    coalesce(e.service_target_count, 0) AS service_target_count,
    coalesce(e.address_target_count, 0) AS address_target_count,
    coalesce(e.professional_target_count, 0) AS professional_target_count,
    CASE
        WHEN coalesce(e.service_target_count, 0) = 1
         AND coalesce(e.address_target_count, 0) > 0
            THEN 'EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS'
        WHEN coalesce(e.service_target_count, 0) = 1
            THEN 'EXPERT_MINIMAL_READY_SINGLE_SERVICE'
        WHEN coalesce(e.service_target_count, 0) > 1
            THEN 'EXPERT_SPLIT_SERVICE_REQUIRED'
        ELSE 'EXPERT_SERVICE_TARGET_MISSING'
    END AS expert_migration_gate,
    false AS core_insert_allowed
FROM ready_routes r
LEFT JOIN expert_targets e
  ON e.route_visit_id = r.route_visit_id;

CREATE OR REPLACE VIEW staging.v_hodom_expert_migration_readiness_summary AS
SELECT
    expert_migration_gate,
    count(*) AS route_rows,
    count(*) FILTER (WHERE address_target_count > 0) AS address_target_rows,
    count(*) FILTER (WHERE professional_target_count > 0) AS professional_target_rows,
    sum(service_target_count) AS service_target_links
FROM staging.v_hodom_expert_migration_readiness
GROUP BY expert_migration_gate;

COMMENT ON VIEW staging.v_hodom_expert_reconciliation_recommendation_summary IS 'Aggregate summary of simulated expert mapping recommendations. Recommendations remain proposed and require responsible review.';
COMMENT ON VIEW staging.v_hodom_expert_migration_readiness IS 'Route-level expert migration readiness over READY_IDENTITY_STAY_ONLY rows. Core inserts remain disabled.';
COMMENT ON VIEW staging.v_hodom_expert_migration_readiness_summary IS 'Aggregate expert readiness counts for planning a controlled migration.';

COMMIT;
