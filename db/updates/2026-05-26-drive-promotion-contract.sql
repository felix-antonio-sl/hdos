-- HODOM Drive promotion contract
-- Categorical gate over readiness: identity/stay matching is not enough for core inserts.

BEGIN;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract AS
SELECT
    c.route_visit_id,
    c.candidate_visit_id,
    c.drive_id,
    c.source_path,
    c.sheet_name,
    c.source_row_number,
    c.visit_date,
    c.visit_year,
    c.visit_month,
    c.match_status AS identity_match_status,
    c.patient_match_count,
    c.active_stay_match_count,
    c.existing_visit_count,
    c.matched_patient_id,
    c.matched_stay_id,
    CASE
        WHEN c.match_status = 'READY_CORE_VISIT' THEN 'READY_IDENTITY_STAY_ONLY'
        WHEN c.match_status = 'REVIEW_EXISTING_CORE_VISIT_SAME_DAY' THEN 'REVIEW_DUPLICATE_PUSHOUT_REQUIRED'
        ELSE c.match_status
    END AS promotion_gate,
    CASE
        WHEN c.match_status = 'READY_CORE_VISIT'
            THEN ARRAY[
                'service_text_to_prestacion_id',
                'professionals_to_provider_id',
                'address_to_domicilio_id'
            ]::text[]
        WHEN c.match_status = 'REVIEW_EXISTING_CORE_VISIT_SAME_DAY'
            THEN ARRAY['source_row_to_existing_visit_equivalence']::text[]
        WHEN c.match_status = 'BLOCKED_NO_PATIENT_MATCH'
            THEN ARRAY['route_row_to_patient_id']::text[]
        WHEN c.match_status = 'BLOCKED_NO_ACTIVE_STAY_MATCH'
            THEN ARRAY['route_row_to_stay_id']::text[]
        WHEN c.match_status = 'BLOCKED_AMBIGUOUS_PATIENT_MATCH'
            THEN ARRAY['unique_patient_identity']::text[]
        WHEN c.match_status = 'BLOCKED_AMBIGUOUS_ACTIVE_STAY_MATCH'
            THEN ARRAY['unique_active_stay']::text[]
        WHEN c.match_status = 'BLOCKED_MISSING_DATE'
            THEN ARRAY['route_row_to_visit_date']::text[]
        WHEN c.match_status = 'BLOCKED_MISSING_PATIENT_NAME'
            THEN ARRAY['route_row_to_patient_name']::text[]
        ELSE ARRAY['manual_review']::text[]
    END AS missing_morphisms,
    false AS core_insert_allowed
FROM staging.v_hodom_route_promotion_candidate c;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract_summary AS
SELECT
    visit_year,
    visit_month,
    identity_match_status,
    promotion_gate,
    missing_morphisms,
    core_insert_allowed,
    count(*) AS route_rows
FROM staging.v_hodom_route_promotion_contract
GROUP BY
    visit_year,
    visit_month,
    identity_match_status,
    promotion_gate,
    missing_morphisms,
    core_insert_allowed;

COMMENT ON VIEW staging.v_hodom_route_promotion_contract IS 'Categorical promotion contract: Drive route rows are partial Kleisli candidates, not core inserts. Contains only IDs/statuses, not exported nominal fields.';
COMMENT ON VIEW staging.v_hodom_route_promotion_contract_summary IS 'Aggregate categorical promotion gates for Drive route rows; safe for documentation.';

COMMIT;
