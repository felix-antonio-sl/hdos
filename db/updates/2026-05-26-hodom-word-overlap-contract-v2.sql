-- HODOM Drive 2026 - materialized word-overlap patient matching and V2 contract.
-- This replaces expensive ad hoc fuzzy compilation with a refreshable staging table.

BEGIN;

CREATE TABLE IF NOT EXISTS staging.hodom_patient_word_overlap_match_2026 (
    route_visit_id text NOT NULL,
    patient_id text NOT NULL,
    visit_year integer NOT NULL,
    visit_month integer NOT NULL,
    route_word_count integer NOT NULL,
    patient_word_count integer NOT NULL,
    matching_route_words integer NOT NULL,
    matching_patient_words integer NOT NULL,
    match_family text NOT NULL,
    match_rank integer NOT NULL,
    confidence_tier text NOT NULL,
    generated_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (route_visit_id, patient_id)
);

CREATE INDEX IF NOT EXISTS idx_hodom_patient_word_overlap_route_2026
    ON staging.hodom_patient_word_overlap_match_2026 (route_visit_id);

CREATE INDEX IF NOT EXISTS idx_hodom_patient_word_overlap_patient_2026
    ON staging.hodom_patient_word_overlap_match_2026 (patient_id);

CREATE INDEX IF NOT EXISTS idx_hodom_patient_word_overlap_family_2026
    ON staging.hodom_patient_word_overlap_match_2026 (match_family, confidence_tier);

TRUNCATE staging.hodom_patient_word_overlap_match_2026;

INSERT INTO staging.hodom_patient_word_overlap_match_2026 (
    route_visit_id, patient_id, visit_year, visit_month,
    route_word_count, patient_word_count,
    matching_route_words, matching_patient_words,
    match_family, match_rank, confidence_tier, generated_at
)
WITH route_base AS (
    SELECT
        r.route_visit_id,
        extract(year FROM r.visit_date)::integer AS visit_year,
        extract(month FROM r.visit_date)::integer AS visit_month,
        staging.norm_text(r.patient_name) AS route_name_norm
    FROM staging.hodom_route_visit r
    WHERE r.visit_date >= '2026-01-01'
      AND r.patient_name IS NOT NULL
      AND staging.norm_text(r.patient_name) IS NOT NULL
),
route_words AS (
    SELECT
        rb.route_visit_id,
        array_agg(DISTINCT word ORDER BY word) AS route_words,
        count(DISTINCT word)::integer AS route_word_count
    FROM route_base rb
    CROSS JOIN LATERAL regexp_split_to_table(rb.route_name_norm, '\s+') AS word
    WHERE length(word) > 2
    GROUP BY rb.route_visit_id
),
patient_base AS (
    SELECT
        p.patient_id,
        staging.norm_text(p.nombre_completo) AS patient_name_norm
    FROM clinical.paciente p
    WHERE p.deleted_at IS NULL
      AND staging.norm_text(p.nombre_completo) IS NOT NULL
),
patient_words AS (
    SELECT
        pb.patient_id,
        array_agg(DISTINCT word ORDER BY word) AS patient_words,
        count(DISTINCT word)::integer AS patient_word_count
    FROM patient_base pb
    CROSS JOIN LATERAL regexp_split_to_table(pb.patient_name_norm, '\s+') AS word
    WHERE length(word) > 2
    GROUP BY pb.patient_id
),
scored AS (
    SELECT
        rb.route_visit_id,
        pb.patient_id,
        rb.visit_year,
        rb.visit_month,
        rb.route_name_norm,
        pb.patient_name_norm,
        rw.route_word_count,
        pw.patient_word_count,
        (
            SELECT count(*)::integer
            FROM unnest(rw.route_words) AS word
            WHERE pb.patient_name_norm LIKE '%' || word || '%'
        ) AS matching_route_words,
        (
            SELECT count(*)::integer
            FROM unnest(pw.patient_words) AS word
            WHERE rb.route_name_norm LIKE '%' || word || '%'
        ) AS matching_patient_words
    FROM route_base rb
    JOIN route_words rw ON rw.route_visit_id = rb.route_visit_id
    CROSS JOIN patient_base pb
    JOIN patient_words pw ON pw.patient_id = pb.patient_id
    WHERE rw.route_word_count >= 2
      AND pw.patient_word_count >= 2
),
qualified AS (
    SELECT
        s.*,
        CASE
            WHEN s.route_name_norm = s.patient_name_norm
                THEN 'EXACT_NORM'
            WHEN s.matching_route_words = s.route_word_count
                THEN 'ROUTE_WORDS_SUBSET_OF_PATIENT'
            WHEN s.matching_patient_words = s.patient_word_count
                THEN 'PATIENT_WORDS_SUBSET_OF_ROUTE'
            ELSE NULL
        END AS match_family
    FROM scored s
    WHERE s.route_name_norm = s.patient_name_norm
       OR s.matching_route_words = s.route_word_count
       OR s.matching_patient_words = s.patient_word_count
),
ranked AS (
    SELECT
        q.*,
        CASE
            WHEN q.match_family = 'EXACT_NORM' THEN 1
            WHEN greatest(q.matching_route_words, q.matching_patient_words) >= 3 THEN 2
            ELSE 3
        END AS match_rank,
        CASE
            WHEN q.match_family = 'EXACT_NORM' THEN 'EXACT'
            WHEN greatest(q.matching_route_words, q.matching_patient_words) >= 3 THEN 'HIGH'
            ELSE 'MEDIUM'
        END AS confidence_tier
    FROM qualified q
)
SELECT
    route_visit_id,
    patient_id,
    visit_year,
    visit_month,
    route_word_count,
    patient_word_count,
    matching_route_words,
    matching_patient_words,
    match_family,
    match_rank,
    confidence_tier,
    now()
FROM ranked;

COMMENT ON TABLE staging.hodom_patient_word_overlap_match_2026 IS
'Materialized 2026 Drive route-to-patient word-overlap candidates. Contains nominally-derived links in DB only; do not export.';

DROP VIEW IF EXISTS staging.v_hodom_route_promotion_contract_v2_summary;
DROP VIEW IF EXISTS staging.v_hodom_route_promotion_contract_v2;
DROP VIEW IF EXISTS staging.v_hodom_patient_word_overlap_unique_2026;
DROP VIEW IF EXISTS staging.v_hodom_patient_word_overlap_summary_2026;

CREATE OR REPLACE VIEW staging.v_hodom_patient_word_overlap_summary_2026 AS
SELECT
    match_family,
    confidence_tier,
    count(*) AS candidate_rows,
    count(DISTINCT route_visit_id) AS route_rows,
    count(DISTINCT patient_id) AS patient_rows,
    now() AS generated_at
FROM staging.hodom_patient_word_overlap_match_2026
GROUP BY match_family, confidence_tier
ORDER BY match_family, confidence_tier;

CREATE OR REPLACE VIEW staging.v_hodom_patient_word_overlap_unique_2026 AS
WITH route_counts AS (
    SELECT
        route_visit_id,
        count(DISTINCT patient_id) AS patient_candidate_count,
        min(match_rank) AS best_match_rank
    FROM staging.hodom_patient_word_overlap_match_2026
    GROUP BY route_visit_id
),
unique_candidates AS (
    SELECT m.*
    FROM staging.hodom_patient_word_overlap_match_2026 m
    JOIN route_counts rc ON rc.route_visit_id = m.route_visit_id
    WHERE rc.patient_candidate_count = 1
      AND m.match_rank = rc.best_match_rank
)
SELECT
    route_visit_id,
    patient_id,
    visit_year,
    visit_month,
    route_word_count,
    patient_word_count,
    matching_route_words,
    matching_patient_words,
    match_family,
    match_rank,
    confidence_tier,
    'UNIQUE_WORD_OVERLAP_PATIENT' AS patient_match_strategy,
    generated_at
FROM unique_candidates;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract_v2 AS
WITH route_base AS (
    SELECT
        r.route_visit_id,
        'drv_route_' || substr(md5(r.route_visit_id), 1, 16) AS candidate_visit_id,
        r.drive_id,
        r.source_path,
        r.sheet_name,
        r.source_row_number,
        r.visit_date,
        extract(year FROM r.visit_date)::integer AS visit_year,
        extract(month FROM r.visit_date)::integer AS visit_month,
        r.planned_time,
        r.professionals,
        r.service_text,
        r.raw_record,
        staging.norm_text(r.patient_name) AS patient_name_norm,
        staging.norm_text(r.address_text) AS address_norm,
        CASE WHEN r.patient_name IS NULL OR btrim(r.patient_name) = '' THEN true ELSE false END AS missing_patient_name,
        CASE WHEN r.address_text IS NULL OR btrim(r.address_text) = '' THEN true ELSE false END AS missing_address,
        CASE WHEN r.service_text IS NULL OR btrim(r.service_text) = '' THEN true ELSE false END AS missing_service
    FROM staging.hodom_route_visit r
),
patient_match AS (
    SELECT
        rb.route_visit_id,
        count(DISTINCT um.patient_id) AS patient_match_count,
        min(um.patient_id) AS matched_patient_id,
        min(um.patient_match_strategy) AS patient_match_strategy,
        min(um.match_family) AS patient_match_family,
        min(um.confidence_tier) AS patient_match_confidence
    FROM route_base rb
    LEFT JOIN staging.v_hodom_patient_word_overlap_unique_2026 um
      ON um.route_visit_id = rb.route_visit_id
    GROUP BY rb.route_visit_id
),
ambiguous_patient_match AS (
    SELECT
        route_visit_id,
        count(DISTINCT patient_id) AS ambiguous_patient_count
    FROM staging.hodom_patient_word_overlap_match_2026
    GROUP BY route_visit_id
    HAVING count(DISTINCT patient_id) > 1
),
stay_match AS (
    SELECT
        rb.route_visit_id,
        count(DISTINCT e.stay_id) AS active_stay_match_count,
        min(e.stay_id) AS matched_stay_id
    FROM route_base rb
    JOIN patient_match pm
      ON pm.route_visit_id = rb.route_visit_id
     AND pm.patient_match_count = 1
    JOIN clinical.estadia e
      ON e.patient_id = pm.matched_patient_id
     AND rb.visit_date IS NOT NULL
     AND rb.visit_date >= e.fecha_ingreso
     AND rb.visit_date <= coalesce(e.fecha_egreso, rb.visit_date)
    GROUP BY rb.route_visit_id
),
existing_visit AS (
    SELECT
        rb.route_visit_id,
        count(v.visit_id) AS existing_visit_count
    FROM route_base rb
    JOIN patient_match pm
      ON pm.route_visit_id = rb.route_visit_id
     AND pm.patient_match_count = 1
    JOIN operational.visita v
      ON v.patient_id = pm.matched_patient_id
     AND v.fecha = rb.visit_date
    GROUP BY rb.route_visit_id
)
SELECT
    rb.route_visit_id,
    rb.candidate_visit_id,
    rb.drive_id,
    rb.source_path,
    rb.sheet_name,
    rb.source_row_number,
    rb.visit_date,
    rb.visit_year,
    rb.visit_month,
    rb.planned_time,
    rb.professionals,
    rb.service_text,
    rb.raw_record,
    rb.patient_name_norm,
    rb.address_norm,
    rb.missing_patient_name,
    rb.missing_address,
    rb.missing_service,
    coalesce(pm.patient_match_count, 0) AS patient_match_count,
    CASE WHEN coalesce(pm.patient_match_count, 0) = 1 THEN pm.matched_patient_id ELSE NULL END AS matched_patient_id,
    pm.patient_match_strategy,
    pm.patient_match_family,
    pm.patient_match_confidence,
    coalesce(sm.active_stay_match_count, 0) AS active_stay_match_count,
    CASE WHEN coalesce(sm.active_stay_match_count, 0) = 1 THEN sm.matched_stay_id ELSE NULL END AS matched_stay_id,
    coalesce(ev.existing_visit_count, 0) AS existing_visit_count,
    CASE
        WHEN rb.visit_date IS NULL THEN 'BLOCKED_MISSING_DATE'
        WHEN rb.missing_patient_name THEN 'BLOCKED_MISSING_PATIENT_NAME'
        WHEN coalesce(apm.ambiguous_patient_count, 0) > 0 THEN 'BLOCKED_AMBIGUOUS_PATIENT_MATCH'
        WHEN coalesce(pm.patient_match_count, 0) = 0 THEN 'BLOCKED_NO_PATIENT_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) = 0 THEN 'BLOCKED_NO_ACTIVE_STAY_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) > 1 THEN 'BLOCKED_AMBIGUOUS_ACTIVE_STAY_MATCH'
        WHEN coalesce(ev.existing_visit_count, 0) > 0 THEN 'REVIEW_EXISTING_CORE_VISIT_SAME_DAY'
        ELSE 'READY_CORE_VISIT'
    END AS identity_match_status,
    CASE
        WHEN rb.visit_date IS NULL THEN 'BLOCKED_MISSING_DATE'
        WHEN rb.missing_patient_name THEN 'BLOCKED_MISSING_PATIENT_NAME'
        WHEN coalesce(apm.ambiguous_patient_count, 0) > 0 THEN 'BLOCKED_AMBIGUOUS_PATIENT_MATCH'
        WHEN coalesce(pm.patient_match_count, 0) = 0 THEN 'BLOCKED_NO_PATIENT_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) = 0 THEN 'BLOCKED_NO_ACTIVE_STAY_MATCH'
        WHEN coalesce(sm.active_stay_match_count, 0) > 1 THEN 'BLOCKED_AMBIGUOUS_ACTIVE_STAY_MATCH'
        WHEN coalesce(ev.existing_visit_count, 0) > 0 THEN 'REVIEW_DUPLICATE_PUSHOUT_REQUIRED'
        ELSE 'READY_IDENTITY_STAY_ONLY'
    END AS promotion_gate,
    false AS core_insert_allowed
FROM route_base rb
LEFT JOIN patient_match pm ON pm.route_visit_id = rb.route_visit_id
LEFT JOIN ambiguous_patient_match apm ON apm.route_visit_id = rb.route_visit_id
LEFT JOIN stay_match sm ON sm.route_visit_id = rb.route_visit_id
LEFT JOIN existing_visit ev ON ev.route_visit_id = rb.route_visit_id;

CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract_v2_summary AS
SELECT
    visit_year,
    visit_month,
    identity_match_status,
    promotion_gate,
    patient_match_strategy,
    patient_match_family,
    patient_match_confidence,
    core_insert_allowed,
    count(*) AS route_rows
FROM staging.v_hodom_route_promotion_contract_v2
GROUP BY
    visit_year,
    visit_month,
    identity_match_status,
    promotion_gate,
    patient_match_strategy,
    patient_match_family,
    patient_match_confidence,
    core_insert_allowed
ORDER BY visit_year, visit_month, promotion_gate;

COMMENT ON VIEW staging.v_hodom_route_promotion_contract_v2 IS
'Flexible V2 promotion contract using materialized word-overlap patient matches. Proposed matching only; core inserts remain disabled.';
COMMENT ON VIEW staging.v_hodom_route_promotion_contract_v2_summary IS
'Aggregate V2 promotion gates using materialized word-overlap. Safe for documentation.';

COMMIT;
