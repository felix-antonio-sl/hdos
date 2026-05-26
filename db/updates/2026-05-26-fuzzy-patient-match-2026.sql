-- HODOM Drive fuzzy patient matching 2026
-- Phase 3: word-overlap matching for blocked patient identities.
-- Matches where ALL words of blocked name appear in DB name (subset match).
-- Inserts proposed patient_identity reconciliation decisions.

BEGIN;

-- ============================================================================
-- 1. Vista de candidatos fuzzy: blocked names con match fuerte en DB
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_patient_match_2026;
CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_patient_match_2026 AS
WITH blocked AS (
    SELECT DISTINCT
        staging.norm_text(rv.patient_name) AS blocked_name_norm,
        rv.patient_name AS original_name,
        count(*) AS route_count,
        array_agg(DISTINCT c.route_visit_id) AS route_ids
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c ON c.route_visit_id = rv.route_visit_id
    WHERE c.promotion_gate = 'BLOCKED_NO_PATIENT_MATCH'
      AND rv.visit_date >= '2026-01-01'
    GROUP BY staging.norm_text(rv.patient_name), rv.patient_name
),
blocked_words AS (
    SELECT
        blocked_name_norm,
        count(*) AS word_count,
        array_agg(word ORDER BY word) AS words_array
    FROM blocked
    CROSS JOIN LATERAL regexp_split_to_table(blocked_name_norm, '\s+') AS word
    WHERE length(word) > 2
    GROUP BY blocked_name_norm
),
db_patients AS (
    SELECT patient_id, staging.norm_text(nombre_completo) AS db_name_norm, nombre_completo
    FROM clinical.paciente WHERE deleted_at IS NULL
),
-- For each blocked name, find DB patients where ALL blocked words appear in DB name
candidates AS (
    SELECT DISTINCT
        b.blocked_name_norm, b.original_name, b.route_count, b.route_ids,
        p.patient_id, p.nombre_completo AS db_name,
        bw.word_count AS blocked_word_count,
        (SELECT count(*) FROM unnest(bw.words_array) w
         WHERE p.db_name_norm LIKE '%' || w || '%') AS matching_words,
        p.db_name_norm LIKE '%' || b.blocked_name_norm || '%' AS blocked_is_subset_of_db
    FROM blocked b
    JOIN blocked_words bw ON bw.blocked_name_norm = b.blocked_name_norm
    CROSS JOIN db_patients p
    WHERE (SELECT count(*) FROM unnest(bw.words_array) w
           WHERE p.db_name_norm LIKE '%' || w || '%') = bw.word_count
      AND bw.word_count >= 2
)
SELECT *,
    CASE
        WHEN blocked_is_subset_of_db AND matching_words >= 3
            THEN 'STRONG_SUBSET'
        WHEN blocked_is_subset_of_db AND matching_words = 2
            THEN 'SUBSET_2WORDS'
        WHEN matching_words >= 3
            THEN 'WORD_OVERLAP_3PLUS'
        ELSE 'WORD_OVERLAP_2'
    END AS match_pattern
FROM candidates;

COMMENT ON VIEW staging.v_hodom_fuzzy_patient_match_2026 IS
'Fuzzy patient identity matching: blocked Drive names where ALL significant (len>2)
 normalized words appear in a DB patient full name. STRONG_SUBSET = blocked name
 is a strict substring of DB name (missing middle names).';

-- ============================================================================
-- 2. Resumen agregado seguro para documentacion
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_patient_match_summary_2026;
CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_patient_match_summary_2026 AS
SELECT
    match_pattern,
    count(*) AS candidate_pairs,
    count(DISTINCT blocked_name_norm) AS distinct_blocked_names,
    sum(route_count) AS total_route_count
FROM staging.v_hodom_fuzzy_patient_match_2026
GROUP BY match_pattern
ORDER BY match_pattern;

COMMENT ON VIEW staging.v_hodom_fuzzy_patient_match_summary_2026 IS
'Aggregate fuzzy patient match counts. Safe for documentation.';

-- ============================================================================
-- 3. Inserta propuestas de identidad de paciente
--    Solo STRONG_SUBSET (nombre bloqueado es subcadena del nombre DB)
--    Esto captura omitidos de segundos nombres (MARIA LUZ → MARIA LUZ DEL ROSARIO)
-- ============================================================================

INSERT INTO staging.hodom_reconciliation_decision (
    decision_id, anchor_type, source_table, source_pk, target_table, target_pk,
    relation_type, decision_status, decided_by, decided_at, rationale, evidence, updated_at
)
SELECT DISTINCT ON (fm.blocked_name_norm, fm.patient_id)
    'fuzzyp' || substr(md5(fm.blocked_name_norm || '|' || fm.patient_id), 1, 20)
        AS decision_id,
    'patient_identity' AS anchor_type,
    'staging.hodom_route_visit' AS source_table,
    fm.blocked_name_norm AS source_pk,
    'clinical.paciente' AS target_table,
    fm.patient_id AS target_pk,
    'same_as' AS relation_type,
    'proposed' AS decision_status,
    'simulated_expert_reconciliation' AS decided_by,
    now() AS decided_at,
    'FUZZY_MATCH: nombre Drive es subconjunto estricto del nombre completo en clinical.paciente '
    || '(todas las ' || fm.blocked_word_count
    || ' palabras significativas matchean). Probable omision de segundos nombres o apellidos '
    || 'intermedios en la planilla Drive. Requiere confirmacion humana.' AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'fuzzy_patient_match_2026_05_26',
        'mapping_family', 'word_subset_match',
        'blocked_name_norm', fm.blocked_name_norm,
        'db_name', fm.db_name,
        'matching_words', fm.matching_words,
        'blocked_word_count', fm.blocked_word_count,
        'route_count', fm.route_count,
        'match_pattern', fm.match_pattern,
        'human_required', true
    ) AS evidence,
    now() AS updated_at
FROM staging.v_hodom_fuzzy_patient_match_2026 fm
WHERE fm.match_pattern = 'STRONG_SUBSET'
  AND NOT EXISTS (
    SELECT 1 FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = 'patient_identity'
      AND d.source_table = 'staging.hodom_route_visit'
      AND d.source_pk = fm.blocked_name_norm
      AND d.target_table = 'clinical.paciente'
      AND d.target_pk = fm.patient_id
      AND d.relation_type = 'same_as'
  );

COMMIT;
