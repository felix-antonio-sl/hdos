-- HODOM Drive human reconciliation
-- Human-reviewed anchors for non-deterministic matching before any core promotion.

BEGIN;

CREATE TABLE IF NOT EXISTS staging.hodom_reconciliation_decision (
    decision_id text PRIMARY KEY,
    anchor_type text NOT NULL CHECK (anchor_type = ANY (ARRAY[
        'patient_identity',
        'active_stay',
        'service_prestacion',
        'professional_provider',
        'address_domicilio',
        'duplicate_visit',
        'visit_date'
    ])),
    source_table text NOT NULL,
    source_pk text NOT NULL,
    target_table text,
    target_pk text,
    relation_type text NOT NULL CHECK (relation_type = ANY (ARRAY[
        'same_as',
        'not_same_as',
        'maps_to',
        'does_not_map_to',
        'duplicate_of',
        'distinct_from',
        'not_applicable'
    ])),
    decision_status text NOT NULL DEFAULT 'proposed' CHECK (decision_status = ANY (ARRAY[
        'proposed',
        'approved',
        'rejected',
        'superseded'
    ])),
    decided_by text,
    decided_at timestamp with time zone,
    rationale text,
    evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CHECK (
        decision_status <> 'approved'
        OR (decided_by IS NOT NULL AND decided_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_hodom_reconciliation_decision_relation
    ON staging.hodom_reconciliation_decision (
        anchor_type,
        source_table,
        source_pk,
        coalesce(target_table, ''),
        coalesce(target_pk, ''),
        relation_type
    );

CREATE INDEX IF NOT EXISTS idx_hodom_reconciliation_decision_source
    ON staging.hodom_reconciliation_decision (source_table, source_pk);

CREATE INDEX IF NOT EXISTS idx_hodom_reconciliation_decision_status
    ON staging.hodom_reconciliation_decision (anchor_type, decision_status);

CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_candidate AS
WITH base AS (
    SELECT
        c.route_visit_id,
        c.candidate_visit_id,
        c.visit_date,
        c.visit_year,
        c.visit_month,
        c.identity_match_status,
        c.promotion_gate,
        c.matched_patient_id,
        c.matched_stay_id,
        c.missing_morphisms
    FROM staging.v_hodom_route_promotion_contract c
),
identity_candidates AS (
    SELECT
        b.route_visit_id,
        b.visit_year,
        b.visit_month,
        b.promotion_gate,
        'patient_identity'::text AS anchor_type,
        'staging.hodom_route_visit'::text AS source_table,
        b.route_visit_id AS source_pk,
        'clinical.paciente'::text AS target_table,
        b.matched_patient_id AS target_pk,
        'same_as'::text AS relation_type,
        'exact_name_pullback_candidate'::text AS proposal_basis,
        'NEEDS_HUMAN_CONFIRMATION'::text AS candidate_status
    FROM base b
    WHERE b.matched_patient_id IS NOT NULL
),
stay_candidates AS (
    SELECT
        b.route_visit_id,
        b.visit_year,
        b.visit_month,
        b.promotion_gate,
        'active_stay'::text AS anchor_type,
        'staging.hodom_route_visit'::text AS source_table,
        b.route_visit_id AS source_pk,
        'clinical.estadia'::text AS target_table,
        b.matched_stay_id AS target_pk,
        'same_as'::text AS relation_type,
        'patient_date_stay_pullback_candidate'::text AS proposal_basis,
        'NEEDS_HUMAN_CONFIRMATION'::text AS candidate_status
    FROM base b
    WHERE b.matched_stay_id IS NOT NULL
),
duplicate_candidates AS (
    SELECT
        b.route_visit_id,
        b.visit_year,
        b.visit_month,
        b.promotion_gate,
        'duplicate_visit'::text AS anchor_type,
        'staging.hodom_route_visit'::text AS source_table,
        b.route_visit_id AS source_pk,
        'operational.visita'::text AS target_table,
        v.visit_id AS target_pk,
        'duplicate_of'::text AS relation_type,
        'same_patient_same_day_core_visit'::text AS proposal_basis,
        'NEEDS_HUMAN_REVIEW'::text AS candidate_status
    FROM base b
    JOIN operational.visita v
      ON v.patient_id = b.matched_patient_id
     AND v.fecha = b.visit_date
    WHERE b.promotion_gate = 'REVIEW_DUPLICATE_PUSHOUT_REQUIRED'
),
missing_morphism_candidates AS (
    SELECT
        b.route_visit_id,
        b.visit_year,
        b.visit_month,
        b.promotion_gate,
        CASE m.morphism
            WHEN 'service_text_to_prestacion_id' THEN 'service_prestacion'
            WHEN 'professionals_to_provider_id' THEN 'professional_provider'
            WHEN 'address_to_domicilio_id' THEN 'address_domicilio'
            WHEN 'source_row_to_existing_visit_equivalence' THEN 'duplicate_visit'
            WHEN 'route_row_to_patient_id' THEN 'patient_identity'
            WHEN 'route_row_to_stay_id' THEN 'active_stay'
            WHEN 'unique_patient_identity' THEN 'patient_identity'
            WHEN 'unique_active_stay' THEN 'active_stay'
            WHEN 'route_row_to_visit_date' THEN 'visit_date'
            WHEN 'route_row_to_patient_name' THEN 'patient_identity'
            ELSE 'patient_identity'
        END AS anchor_type,
        'staging.hodom_route_visit'::text AS source_table,
        b.route_visit_id AS source_pk,
        CASE m.morphism
            WHEN 'service_text_to_prestacion_id' THEN 'reference.catalogo_prestacion'
            WHEN 'professionals_to_provider_id' THEN 'operational.profesional'
            WHEN 'address_to_domicilio_id' THEN 'clinical.domicilio'
            WHEN 'source_row_to_existing_visit_equivalence' THEN 'operational.visita'
            WHEN 'route_row_to_patient_id' THEN 'clinical.paciente'
            WHEN 'route_row_to_stay_id' THEN 'clinical.estadia'
            WHEN 'unique_patient_identity' THEN 'clinical.paciente'
            WHEN 'unique_active_stay' THEN 'clinical.estadia'
            ELSE NULL
        END AS target_table,
        NULL::text AS target_pk,
        CASE m.morphism
            WHEN 'source_row_to_existing_visit_equivalence' THEN 'duplicate_of'
            ELSE 'maps_to'
        END AS relation_type,
        m.morphism AS proposal_basis,
        CASE
            WHEN m.morphism IN ('service_text_to_prestacion_id', 'professionals_to_provider_id', 'address_to_domicilio_id')
                THEN 'NEEDS_MAPPING_RULE'
            ELSE 'NEEDS_HUMAN_ANCHOR'
        END AS candidate_status
    FROM base b
    CROSS JOIN LATERAL unnest(b.missing_morphisms) AS m(morphism)
)
SELECT
    'hrcand_' || substr(md5(
        anchor_type || '|' ||
        source_table || '|' ||
        source_pk || '|' ||
        coalesce(target_table, '') || '|' ||
        coalesce(target_pk, '') || '|' ||
        relation_type || '|' ||
        proposal_basis
    ), 1, 16) AS candidate_id,
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
    candidate_status,
    true AS requires_human_review
FROM (
    SELECT * FROM identity_candidates
    UNION ALL
    SELECT * FROM stay_candidates
    UNION ALL
    SELECT * FROM duplicate_candidates
    UNION ALL
    SELECT * FROM missing_morphism_candidates
) candidates;

CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_candidate_summary AS
SELECT
    anchor_type,
    candidate_status,
    target_table,
    relation_type,
    count(*) AS candidate_rows,
    count(DISTINCT source_pk) AS affected_route_rows
FROM staging.v_hodom_route_reconciliation_candidate
GROUP BY anchor_type, candidate_status, target_table, relation_type;

CREATE OR REPLACE VIEW staging.v_hodom_reconciliation_decision_effective AS
SELECT *
FROM staging.hodom_reconciliation_decision
WHERE decision_status = 'approved';

CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_human_gate AS
WITH candidate_decisions AS (
    SELECT
        c.candidate_id,
        c.route_visit_id,
        c.anchor_type,
        c.source_table,
        c.source_pk,
        c.target_table,
        c.target_pk,
        c.relation_type,
        bool_or(d.decision_status = 'approved') AS human_approved,
        bool_or(d.decision_status = 'rejected') AS human_rejected
    FROM staging.v_hodom_route_reconciliation_candidate c
    LEFT JOIN staging.hodom_reconciliation_decision d
      ON d.anchor_type = c.anchor_type
     AND d.source_table = c.source_table
     AND d.source_pk = c.source_pk
     AND (c.target_table IS NULL OR d.target_table = c.target_table)
     AND (c.target_pk IS NULL OR d.target_pk = c.target_pk)
     AND d.relation_type = c.relation_type
     AND d.decision_status IN ('approved', 'rejected')
    GROUP BY
        c.candidate_id,
        c.route_visit_id,
        c.anchor_type,
        c.source_table,
        c.source_pk,
        c.target_table,
        c.target_pk,
        c.relation_type
)
SELECT
    route_visit_id,
    count(*) AS candidate_count,
    count(*) FILTER (WHERE human_approved) AS approved_count,
    count(*) FILTER (WHERE human_rejected) AS rejected_count,
    count(*) FILTER (WHERE NOT human_approved AND NOT human_rejected) AS unresolved_count,
    bool_and(human_approved OR human_rejected) AS all_candidates_reviewed,
    false AS core_insert_allowed
FROM candidate_decisions
GROUP BY route_visit_id;

COMMENT ON TABLE staging.hodom_reconciliation_decision IS 'Human-authored relation anchors for Drive reconciliation. This table is the only place where ambiguous/non-deterministic matches become approved relations.';
COMMENT ON VIEW staging.v_hodom_route_reconciliation_candidate IS 'Non-deterministic route reconciliation candidates. Candidate rows are evidence, not truth; human review is required.';
COMMENT ON VIEW staging.v_hodom_route_reconciliation_candidate_summary IS 'Aggregate candidate counts by anchor type and status; safe for documentation.';
COMMENT ON VIEW staging.v_hodom_reconciliation_decision_effective IS 'Approved human reconciliation decisions only.';
COMMENT ON VIEW staging.v_hodom_route_reconciliation_human_gate IS 'Route-level human review gate. Core inserts remain disabled until a later promotion migration consumes approved anchors.';

COMMIT;
