-- HODOM Drive simulated reconciliation proposals
-- Agent-generated review hypotheses. They are not human validation and do not open core promotion.

BEGIN;

WITH unique_target_candidates AS (
    SELECT
        anchor_type,
        source_table,
        source_pk,
        relation_type
    FROM staging.v_hodom_route_reconciliation_candidate
    WHERE target_pk IS NOT NULL
    GROUP BY
        anchor_type,
        source_table,
        source_pk,
        relation_type
    HAVING count(DISTINCT target_pk) = 1
),
proposal_candidates AS (
    SELECT c.*
    FROM staging.v_hodom_route_reconciliation_candidate c
    JOIN unique_target_candidates u
      ON u.anchor_type = c.anchor_type
     AND u.source_table = c.source_table
     AND u.source_pk = c.source_pk
     AND u.relation_type = c.relation_type
    WHERE c.target_pk IS NOT NULL
      AND c.anchor_type = ANY (ARRAY[
          'patient_identity',
          'active_stay',
          'duplicate_visit'
      ])
      AND c.candidate_status = ANY (ARRAY[
          'NEEDS_HUMAN_CONFIRMATION',
          'NEEDS_HUMAN_REVIEW'
      ])
),
deduplicated_proposals AS (
    SELECT DISTINCT ON (
        anchor_type,
        source_table,
        source_pk,
        target_table,
        target_pk,
        relation_type
    )
        candidate_id,
        route_visit_id,
        visit_year,
        visit_month,
        promotion_gate,
        anchor_type,
        source_table,
        source_pk,
        target_table,
        target_pk,
        relation_type,
        proposal_basis,
        candidate_status
    FROM proposal_candidates
    ORDER BY
        anchor_type,
        source_table,
        source_pk,
        target_table,
        target_pk,
        relation_type,
        candidate_id
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
    'simprop_' || substr(md5(
        p.anchor_type || '|' ||
        p.source_table || '|' ||
        p.source_pk || '|' ||
        coalesce(p.target_table, '') || '|' ||
        coalesce(p.target_pk, '') || '|' ||
        p.relation_type
    ), 1, 24) AS decision_id,
    p.anchor_type,
    p.source_table,
    p.source_pk,
    p.target_table,
    p.target_pk,
    p.relation_type,
    'proposed' AS decision_status,
    'simulated_agent_reconciliation' AS decided_by,
    now() AS decided_at,
    CASE p.anchor_type
        WHEN 'patient_identity' THEN 'SIMULATED_PROPOSAL: target unico por pullback nominal exacto; requiere revision humana antes de promover.'
        WHEN 'active_stay' THEN 'SIMULATED_PROPOSAL: estadia unica por paciente-fecha; requiere revision humana antes de promover.'
        WHEN 'duplicate_visit' THEN 'SIMULATED_PROPOSAL: visita core unica mismo paciente-mismo dia; requiere decision humana de deduplicacion.'
        ELSE 'SIMULATED_PROPOSAL: candidato unico con target concreto; requiere revision humana.'
    END AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'sim_reconciliation_2026_05_26_v1',
        'simulated', true,
        'human_required', true,
        'candidate_id', p.candidate_id,
        'route_visit_id', p.route_visit_id,
        'proposal_basis', p.proposal_basis,
        'candidate_status', p.candidate_status,
        'promotion_gate', p.promotion_gate,
        'visit_year', p.visit_year,
        'visit_month', p.visit_month,
        'risk_class', CASE p.anchor_type
            WHEN 'duplicate_visit' THEN 'high_requires_merge_decision'
            ELSE 'medium_requires_confirmation'
        END,
        'heuristics', jsonb_build_array(
            'target_pk_concrete',
            'single_distinct_target_for_anchor_source_relation',
            'no_nominal_evidence_exported'
        )
    ) AS evidence,
    now() AS updated_at
FROM deduplicated_proposals p
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = p.anchor_type
      AND d.source_table = p.source_table
      AND d.source_pk = p.source_pk
      AND coalesce(d.target_table, '') = coalesce(p.target_table, '')
      AND coalesce(d.target_pk, '') = coalesce(p.target_pk, '')
      AND d.relation_type = p.relation_type
)
ON CONFLICT (decision_id) DO UPDATE
SET
    decision_status = EXCLUDED.decision_status,
    decided_by = EXCLUDED.decided_by,
    decided_at = EXCLUDED.decided_at,
    rationale = EXCLUDED.rationale,
    evidence = EXCLUDED.evidence,
    updated_at = EXCLUDED.updated_at
WHERE staging.hodom_reconciliation_decision.decision_status = 'proposed'
  AND staging.hodom_reconciliation_decision.decided_by = 'simulated_agent_reconciliation';

CREATE OR REPLACE VIEW staging.v_hodom_reconciliation_simulated_proposal_summary AS
SELECT
    evidence->>'simulation_run_id' AS simulation_run_id,
    anchor_type,
    relation_type,
    target_table,
    decision_status,
    evidence->>'risk_class' AS risk_class,
    count(*) AS proposal_rows,
    count(DISTINCT source_pk) AS affected_route_rows
FROM staging.hodom_reconciliation_decision
WHERE decided_by = 'simulated_agent_reconciliation'
GROUP BY
    evidence->>'simulation_run_id',
    anchor_type,
    relation_type,
    target_table,
    decision_status,
    evidence->>'risk_class';

COMMENT ON VIEW staging.v_hodom_reconciliation_simulated_proposal_summary IS 'Aggregate summary of simulated reconciliation proposals. These rows are hypotheses for human review, not core-promotion authority.';

COMMIT;
