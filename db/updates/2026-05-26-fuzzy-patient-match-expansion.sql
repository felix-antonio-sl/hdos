-- HODOM Drive fuzzy patient match expansion 2026.
-- Restores reproducibility for all all-words fuzzy proposals observed in DB state.
-- Proposals remain non-authoritative: human_required=true and no core promotion.

BEGIN;

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
    'FUZZY_MATCH: todas las palabras significativas del nombre Drive aparecen en clinical.paciente. '
    || 'Es una propuesta de conciliacion humana simulada, no aprobacion humana.' AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'fuzzy_patient_match_2026_05_26',
        'mapping_family', 'all_words_match',
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
WHERE fm.match_pattern IN ('WORD_OVERLAP_2', 'WORD_OVERLAP_3PLUS', 'SUBSET_2WORDS')
  AND NOT EXISTS (
      SELECT 1
      FROM staging.hodom_reconciliation_decision d
      WHERE d.anchor_type = 'patient_identity'
        AND d.source_table = 'staging.hodom_route_visit'
        AND d.source_pk = fm.blocked_name_norm
        AND d.target_table = 'clinical.paciente'
        AND d.target_pk = fm.patient_id
        AND d.relation_type = 'same_as'
  );

WITH fuzzy_matches AS (
    SELECT
        fm.blocked_name_norm,
        fm.patient_id,
        fm.match_pattern
    FROM staging.v_hodom_fuzzy_patient_match_2026 fm
)
UPDATE staging.hodom_reconciliation_decision d
SET
    evidence = jsonb_set(
        d.evidence,
        '{match_pattern}',
        to_jsonb(fm.match_pattern),
        true
    ) || jsonb_build_object(
        'mapping_family',
        coalesce(d.evidence->>'mapping_family', 'all_words_match'),
        'human_required',
        true
    ),
    updated_at = now()
FROM fuzzy_matches fm
WHERE d.anchor_type = 'patient_identity'
  AND d.source_table = 'staging.hodom_route_visit'
  AND d.source_pk = fm.blocked_name_norm
  AND d.target_table = 'clinical.paciente'
  AND d.target_pk = fm.patient_id
  AND d.relation_type = 'same_as'
  AND d.decided_by = 'simulated_expert_reconciliation'
  AND d.evidence->>'simulation_run_id' = 'fuzzy_patient_match_2026_05_26'
  AND NOT (d.evidence ? 'match_pattern');

COMMIT;
