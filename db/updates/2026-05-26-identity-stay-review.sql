-- HODOM Drive patient identity and stay composition review
-- Non-destructive review views for simulated patient_identity and active_stay proposals.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_identity_stay_review_summary;
DROP VIEW IF EXISTS staging.v_hodom_identity_stay_review_queue;

CREATE OR REPLACE VIEW staging.v_hodom_identity_stay_review_queue AS
WITH simulated_anchor_proposals AS (
    SELECT
        decision_id,
        anchor_type,
        source_pk AS route_visit_id,
        target_pk,
        decision_status,
        evidence
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type IN ('patient_identity', 'active_stay')
      AND relation_type = 'same_as'
      AND decision_status = 'proposed'
      AND decided_by = 'simulated_agent_reconciliation'
      AND target_pk IS NOT NULL
),
paired AS (
    SELECT
        route_visit_id,
        max(decision_id) FILTER (WHERE anchor_type = 'patient_identity') AS patient_decision_id,
        max(decision_id) FILTER (WHERE anchor_type = 'active_stay') AS stay_decision_id,
        max(target_pk) FILTER (WHERE anchor_type = 'patient_identity') AS proposed_patient_id,
        max(target_pk) FILTER (WHERE anchor_type = 'active_stay') AS proposed_stay_id,
        count(*) FILTER (WHERE anchor_type = 'patient_identity') AS patient_proposal_count,
        count(*) FILTER (WHERE anchor_type = 'active_stay') AS stay_proposal_count,
        max(evidence->>'simulation_run_id') AS simulation_run_id
    FROM simulated_anchor_proposals
    GROUP BY route_visit_id
)
SELECT
    p.route_visit_id,
    p.patient_decision_id,
    p.stay_decision_id,
    p.proposed_patient_id,
    p.proposed_stay_id,
    rv.visit_date,
    extract(year FROM rv.visit_date)::int AS visit_year,
    extract(month FROM rv.visit_date)::int AS visit_month,
    p.patient_proposal_count,
    p.stay_proposal_count,
    CASE
        WHEN p.proposed_patient_id IS NOT NULL AND p.proposed_stay_id IS NOT NULL THEN 'BOTH_ANCHORS'
        WHEN p.proposed_patient_id IS NOT NULL THEN 'PATIENT_ONLY'
        WHEN p.proposed_stay_id IS NOT NULL THEN 'STAY_ONLY'
        ELSE 'NO_ANCHOR'
    END AS anchor_pair_status,
    e.estado AS stay_estado,
    e.fecha_ingreso AS stay_fecha_ingreso,
    e.fecha_egreso AS stay_fecha_egreso,
    e.patient_id AS stay_patient_id,
    e.patient_id = p.proposed_patient_id AS stay_patient_matches_identity,
    rv.visit_date >= e.fecha_ingreso
        AND (e.fecha_egreso IS NULL OR rv.visit_date <= e.fecha_egreso) AS visit_within_stay_window,
    CASE
        WHEN p.proposed_patient_id IS NULL OR p.proposed_stay_id IS NULL
            THEN 'PAIR_MISSING_ANCHOR'
        WHEN e.patient_id IS DISTINCT FROM p.proposed_patient_id
            THEN 'COMPOSITION_MISMATCH'
        WHEN NOT (
            rv.visit_date >= e.fecha_ingreso
            AND (e.fecha_egreso IS NULL OR rv.visit_date <= e.fecha_egreso)
        )
            THEN 'TEMPORAL_WINDOW_MISMATCH'
        ELSE 'IDENTITY_STAY_COMPOSES'
    END AS composition_status,
    CASE
        WHEN p.proposed_patient_id IS NULL OR p.proposed_stay_id IS NULL THEN 1
        WHEN e.patient_id IS DISTINCT FROM p.proposed_patient_id THEN 1
        WHEN NOT (
            rv.visit_date >= e.fecha_ingreso
            AND (e.fecha_egreso IS NULL OR rv.visit_date <= e.fecha_egreso)
        ) THEN 1
        ELSE 3
    END AS review_priority,
    CASE
        WHEN p.proposed_patient_id IS NULL OR p.proposed_stay_id IS NULL
            THEN 'high_missing_anchor'
        WHEN e.patient_id IS DISTINCT FROM p.proposed_patient_id
            THEN 'high_composition_mismatch'
        WHEN NOT (
            rv.visit_date >= e.fecha_ingreso
            AND (e.fecha_egreso IS NULL OR rv.visit_date <= e.fecha_egreso)
        )
            THEN 'high_temporal_mismatch'
        ELSE 'medium_identity_stay_confirmation'
    END AS risk_class,
    jsonb_build_object(
        'simulation_run_id', p.simulation_run_id,
        'route_visit_id', p.route_visit_id,
        'has_patient_identity_proposal', p.proposed_patient_id IS NOT NULL,
        'has_active_stay_proposal', p.proposed_stay_id IS NOT NULL,
        'stay_patient_matches_identity', e.patient_id = p.proposed_patient_id,
        'visit_within_stay_window', rv.visit_date >= e.fecha_ingreso
            AND (e.fecha_egreso IS NULL OR rv.visit_date <= e.fecha_egreso),
        'human_required', true
    ) AS review_evidence
FROM paired p
JOIN staging.hodom_route_visit rv
  ON rv.route_visit_id = p.route_visit_id
LEFT JOIN clinical.estadia e
  ON e.stay_id = p.proposed_stay_id;

CREATE OR REPLACE VIEW staging.v_hodom_identity_stay_review_summary AS
SELECT
    visit_year,
    visit_month,
    anchor_pair_status,
    composition_status,
    review_priority,
    risk_class,
    coalesce(stay_estado, 'NO_STAY') AS stay_estado,
    count(*) AS route_rows,
    count(*) FILTER (WHERE stay_patient_matches_identity) AS stay_patient_match_rows,
    count(*) FILTER (WHERE visit_within_stay_window) AS temporal_window_match_rows
FROM staging.v_hodom_identity_stay_review_queue
GROUP BY
    visit_year,
    visit_month,
    anchor_pair_status,
    composition_status,
    review_priority,
    risk_class,
    coalesce(stay_estado, 'NO_STAY');

COMMENT ON VIEW staging.v_hodom_identity_stay_review_queue IS 'Queue of simulated patient_identity and active_stay proposals, reviewed as a compositional pair. It exposes IDs and booleans only; no names, addresses, phones, or clinical text.';
COMMENT ON VIEW staging.v_hodom_identity_stay_review_summary IS 'Aggregate summary of identity/stay composition status for simulated reconciliation proposals.';

COMMIT;
