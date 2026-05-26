-- HODOM Drive duplicate visit review queue
-- Non-destructive review views for simulated duplicate_visit proposals.

BEGIN;

DROP VIEW IF EXISTS staging.v_hodom_duplicate_visit_review_summary;
DROP VIEW IF EXISTS staging.v_hodom_duplicate_visit_review_queue;

CREATE OR REPLACE VIEW staging.v_hodom_duplicate_visit_review_queue AS
WITH simulated_duplicates AS (
    SELECT
        decision_id,
        source_pk AS route_visit_id,
        target_pk AS target_visit_id,
        relation_type,
        decision_status,
        evidence
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type = 'duplicate_visit'
      AND relation_type = 'duplicate_of'
      AND decision_status = 'proposed'
      AND decided_by = 'simulated_agent_reconciliation'
      AND target_pk IS NOT NULL
),
target_multiplicity AS (
    SELECT
        target_visit_id,
        count(*) AS target_source_row_count
    FROM simulated_duplicates
    GROUP BY target_visit_id
)
SELECT
    d.decision_id,
    d.route_visit_id,
    d.target_visit_id,
    rv.visit_date,
    extract(year FROM rv.visit_date)::int AS visit_year,
    extract(month FROM rv.visit_date)::int AS visit_month,
    d.relation_type,
    d.decision_status,
    coalesce(v.estado, 'UNKNOWN') AS target_visit_estado,
    coalesce(v.doc_estado, 'UNKNOWN') AS target_doc_estado,
    tm.target_source_row_count,
    CASE
        WHEN tm.target_source_row_count > 1 THEN 'MANY_TO_ONE_REVIEW'
        ELSE 'ONE_TO_ONE_REVIEW'
    END AS target_multiplicity_class,
    v.fecha = rv.visit_date AS same_visit_date,
    nullif(trim(rv.service_text), '') IS NOT NULL AS source_has_service_text,
    rv.professionals IS NOT NULL
        AND rv.professionals <> 'null'::jsonb
        AND rv.professionals <> '[]'::jsonb
        AND rv.professionals <> '{}'::jsonb AS source_has_professionals,
    nullif(trim(rv.address_text), '') IS NOT NULL AS source_has_address,
    v.prestacion_id IS NOT NULL AS target_has_prestacion,
    v.provider_id IS NOT NULL AS target_has_provider,
    v.domicilio_id IS NOT NULL AS target_has_domicilio,
    (
        (v.prestacion_id IS NULL)::int +
        (v.provider_id IS NULL)::int +
        (v.domicilio_id IS NULL)::int
    ) AS target_anchor_gap_count,
    CASE
        WHEN v.prestacion_id IS NULL OR v.provider_id IS NULL OR v.domicilio_id IS NULL
            THEN 'MERGE_COMPLEMENT_CANDIDATE'
        ELSE 'MERGE_VERIFY_ONLY_CANDIDATE'
    END AS pushout_recommendation,
    CASE
        WHEN v.prestacion_id IS NULL AND v.provider_id IS NULL AND v.domicilio_id IS NULL
            THEN 'REVIEW_STRUCTURAL_GAP_BEFORE_MERGE'
        WHEN v.prestacion_id IS NULL OR v.domicilio_id IS NULL
            THEN 'REVIEW_ANCHOR_GAP_BEFORE_MERGE'
        WHEN v.provider_id IS NULL
            THEN 'REVIEW_PROVIDER_COMPLETION_BEFORE_MERGE'
        ELSE 'REVIEW_DUPLICATE_CONFIRMATION'
    END AS review_reason,
    CASE
        WHEN v.prestacion_id IS NULL OR v.domicilio_id IS NULL THEN 1
        WHEN v.provider_id IS NULL THEN 2
        ELSE 3
    END AS review_priority,
    CASE
        WHEN v.prestacion_id IS NULL OR v.domicilio_id IS NULL
            THEN 'high_anchor_gap'
        WHEN v.provider_id IS NULL
            THEN 'high_provider_gap'
        ELSE 'medium_duplicate_confirmation'
    END AS risk_class,
    jsonb_build_object(
        'simulation_run_id', d.evidence->>'simulation_run_id',
        'route_visit_id', d.route_visit_id,
        'target_visit_id', d.target_visit_id,
        'target_source_row_count', tm.target_source_row_count,
        'target_multiplicity_class', CASE
            WHEN tm.target_source_row_count > 1 THEN 'MANY_TO_ONE_REVIEW'
            ELSE 'ONE_TO_ONE_REVIEW'
        END,
        'same_visit_date', v.fecha = rv.visit_date,
        'target_anchor_gap_count', (
            (v.prestacion_id IS NULL)::int +
            (v.provider_id IS NULL)::int +
            (v.domicilio_id IS NULL)::int
        ),
        'source_has_service_text', nullif(trim(rv.service_text), '') IS NOT NULL,
        'source_has_professionals', rv.professionals IS NOT NULL
            AND rv.professionals <> 'null'::jsonb
            AND rv.professionals <> '[]'::jsonb
            AND rv.professionals <> '{}'::jsonb,
        'source_has_address', nullif(trim(rv.address_text), '') IS NOT NULL,
        'human_required', true
    ) AS review_evidence
FROM simulated_duplicates d
JOIN staging.hodom_route_visit rv
  ON rv.route_visit_id = d.route_visit_id
JOIN operational.visita v
  ON v.visit_id = d.target_visit_id
JOIN target_multiplicity tm
  ON tm.target_visit_id = d.target_visit_id;

CREATE OR REPLACE VIEW staging.v_hodom_duplicate_visit_review_summary AS
SELECT
    visit_year,
    visit_month,
    pushout_recommendation,
    review_reason,
    review_priority,
    risk_class,
    target_multiplicity_class,
    target_visit_estado,
    target_doc_estado,
    count(*) AS proposal_rows,
    count(DISTINCT target_visit_id) AS target_visit_rows,
    count(*) FILTER (WHERE same_visit_date) AS same_date_rows,
    count(*) FILTER (WHERE source_has_service_text) AS source_service_rows,
    count(*) FILTER (WHERE source_has_professionals) AS source_professional_rows,
    count(*) FILTER (WHERE source_has_address) AS source_address_rows,
    sum(target_anchor_gap_count) AS total_target_anchor_gaps
FROM staging.v_hodom_duplicate_visit_review_queue
GROUP BY
    visit_year,
    visit_month,
    pushout_recommendation,
    review_reason,
    review_priority,
    risk_class,
    target_multiplicity_class,
    target_visit_estado,
    target_doc_estado;

COMMENT ON VIEW staging.v_hodom_duplicate_visit_review_queue IS 'Queue of simulated duplicate_visit proposals for human merge/pushout review. It exposes IDs and booleans only; no names, addresses, phones, or clinical text.';
COMMENT ON VIEW staging.v_hodom_duplicate_visit_review_summary IS 'Aggregate summary of duplicate_visit merge/pushout review priorities.';

COMMIT;
