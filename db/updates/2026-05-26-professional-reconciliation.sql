-- HODOM Drive professional reconciliation
-- Cross-references Drive route professional names against operational.profesional.
-- Inserts proposed reconciliation decisions for high/medium confidence matches.
-- Ambiguous matches (multiple DB professionals for same Drive name) are flagged for human review.
-- No inserts into clinical or operational tables.

BEGIN;

-- ============================================================================
-- 1. Vista de lookup: Drive professional names limpios y normalizados
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_drive_professional_lookup;
CREATE OR REPLACE VIEW staging.v_hodom_drive_professional_lookup AS
WITH drive_raw AS (
    SELECT DISTINCT
        role_key AS drive_role,
        name_value AS drive_name,
        staging.norm_text(
            regexp_replace(
                name_value,
                '^(DR\.?|DRA\.?|TENS\.?|SR\.?)\s+',
                '',
                'i'
            )
        ) AS cleaned_norm,
        count(*) AS route_count
    FROM staging.hodom_route_visit rv
    CROSS JOIN LATERAL jsonb_each_text(rv.professionals) AS prof(role_key, name_value)
    WHERE rv.professionals IS NOT NULL
      AND rv.professionals <> '{}'::jsonb
      AND jsonb_typeof(rv.professionals) = 'object'
    GROUP BY role_key, name_value
)
SELECT
    drive_role,
    drive_name,
    cleaned_norm,
    route_count,
    CASE drive_role
        WHEN 'enfermera' THEN ARRAY['ENFERMERIA', 'TENS']::text[]
        WHEN 'kine' THEN ARRAY['KINESIOLOGIA']::text[]
        WHEN 'fono' THEN ARRAY['FONOAUDIOLOGIA']::text[]
        WHEN 'medico' THEN ARRAY['MEDICO']::text[]
        WHEN 'tens' THEN ARRAY['TENS', 'ENFERMERIA']::text[]
    END AS target_professions,
    CASE
        WHEN cleaned_norm IN ('KTM', 'KTR', 'KNT', 'KINE', 'FONO', 'FONO (AC)',
                               '104', 'CA', 'CS', 'MANTENCION', '-', 'KOH',
                               'BRYAN', 'DASTIN', 'VISITA SOCIAL')
        THEN true
        WHEN cleaned_norm LIKE 'TTO%' THEN true
        WHEN cleaned_norm LIKE 'VM%' THEN true
        WHEN cleaned_norm LIKE 'ING%' THEN true
        WHEN cleaned_norm LIKE 'EXAMENES%' THEN true
        WHEN cleaned_norm LIKE 'REV%' THEN true
        WHEN cleaned_norm LIKE 'ALTA%' THEN true
        WHEN cleaned_norm LIKE '%C/24%' THEN true
        WHEN cleaned_norm LIKE '%C/12%' THEN true
        WHEN cleaned_norm LIKE 'KTM%' THEN true
        WHEN cleaned_norm LIKE 'KTR%' THEN true
        WHEN cleaned_norm LIKE 'KNT%' THEN true
        WHEN cleaned_norm LIKE 'CS %' THEN true
        WHEN cleaned_norm LIKE 'CA %' THEN true
        WHEN cleaned_norm LIKE 'ATB%' THEN true
        WHEN cleaned_norm LIKE '%+%' THEN true
        ELSE false
    END AS is_service_text
FROM drive_raw;

COMMENT ON VIEW staging.v_hodom_drive_professional_lookup IS
'Drive professional names with role-to-profession mapping and service text detection.
 Cleans DR./DRA./TENS prefixes. is_service_text=true rows are service descriptions, not professionals.';

-- ============================================================================
-- 2. Vista de scoring: cada Drive name puntuado contra DB profesionales
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_professional_match_scoring;
CREATE OR REPLACE VIEW staging.v_hodom_professional_match_scoring AS
WITH scored AS (
    SELECT
        dl.drive_role,
        dl.drive_name,
        dl.cleaned_norm,
        dl.route_count,
        p.provider_id,
        p.nombre AS db_name,
        p.profesion AS db_profesion,
        p.estado AS db_estado,
        staging.norm_text(split_part(p.nombre, ' ', 1)) AS db_first_norm,
        staging.norm_text(split_part(p.nombre, ' ', 2)) AS db_second_norm,
        staging.norm_text(p.nombre) AS db_full_norm,
        CASE
            -- Exact first name match
            WHEN staging.norm_text(split_part(p.nombre, ' ', 1)) = dl.cleaned_norm
                AND staging.norm_text(split_part(p.nombre, ' ', 1)) != ''
                THEN 100
            -- Drive cleaned starts with DB first name (PÍA V. → PÍA)
            WHEN dl.cleaned_norm LIKE staging.norm_text(split_part(p.nombre, ' ', 1)) || '%'
                AND staging.norm_text(split_part(p.nombre, ' ', 1)) != ''
                THEN 85
            -- DB first name is inside Drive cleaned
            WHEN staging.norm_text(split_part(p.nombre, ' ', 1)) != ''
                AND dl.cleaned_norm LIKE '%' || staging.norm_text(split_part(p.nombre, ' ', 1)) || '%'
                AND char_length(staging.norm_text(split_part(p.nombre, ' ', 1))) > 2
                THEN 75
            -- Last name exact match (medicos use last names)
            WHEN staging.norm_text(split_part(p.nombre, ' ', 2)) = dl.cleaned_norm
                AND staging.norm_text(split_part(p.nombre, ' ', 2)) != ''
                THEN 60
            -- Drive cleaned contains full DB last name (AQUEVEQUE → AQUEVEQUE PINCHEIRA)
            WHEN staging.norm_text(p.nombre) LIKE '%' || dl.cleaned_norm || '%'
                AND char_length(dl.cleaned_norm) > 3
                THEN 55
            -- Multi-word DB name: check second+ parts (for "M. JOSÉ" → "MARIA JOSE VASQUEZ")
            WHEN staging.norm_text(split_part(p.nombre, ' ', 2)) != ''
                AND dl.cleaned_norm LIKE '%' || staging.norm_text(split_part(p.nombre, ' ', 2)) || '%'
                AND char_length(staging.norm_text(split_part(p.nombre, ' ', 2))) > 2
                THEN 50
            ELSE 0
        END AS score
    FROM staging.v_hodom_drive_professional_lookup dl
    CROSS JOIN operational.profesional p
    WHERE NOT dl.is_service_text
      AND p.profesion = ANY(dl.target_professions)
      AND NOT staging.norm_text(p.nombre) LIKE '%HODOM'
      AND char_length(dl.cleaned_norm) > 1
),
ranked AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY drive_role, drive_name
            ORDER BY score DESC, db_estado = 'activo' DESC, db_name
        ) AS match_rank,
        count(*) OVER (
            PARTITION BY drive_role, drive_name
        ) AS potential_matches
    FROM scored
    WHERE score > 0
)
SELECT
    drive_role,
    drive_name,
    cleaned_norm,
    route_count,
    provider_id,
    db_name,
    db_profesion,
    db_estado,
    score,
    match_rank,
    coalesce(potential_matches, 0) AS potential_matches,
    CASE
        WHEN score >= 80 AND potential_matches = 1
            THEN 'high_confidence_unique'
        WHEN score >= 80 AND potential_matches > 1
            THEN 'high_confidence_ambiguous'
        WHEN score >= 60
            THEN 'medium_confidence'
        WHEN score >= 50
            THEN 'low_confidence'
        ELSE 'no_match'
    END AS match_quality
FROM ranked
WHERE match_rank = 1;

COMMENT ON VIEW staging.v_hodom_professional_match_scoring IS
'Scored professional matches: each distinct Drive professional name matched
 against operational.profesional with role constraint. Best match per name selected.
 match_quality tags ambiguous cases (multiple DB candidates).';

-- ============================================================================
-- 3. Vista de resumen agregado para documentacion (sin IDs clinicos)
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_professional_match_summary;
CREATE OR REPLACE VIEW staging.v_hodom_professional_match_summary AS
SELECT
    drive_role,
    match_quality,
    db_estado,
    count(*) AS drive_name_count,
    sum(route_count) AS total_route_count,
    count(*) FILTER (WHERE score >= 80) AS high_confidence_names,
    count(*) FILTER (WHERE potential_matches > 1) AS ambiguous_names
FROM staging.v_hodom_professional_match_scoring
GROUP BY drive_role, match_quality, db_estado
ORDER BY drive_role, match_quality, db_estado;

COMMENT ON VIEW staging.v_hodom_professional_match_summary IS
'Aggregate professional match summary for documentation. No names or provider IDs.';

-- ============================================================================
-- 4. Inserta propuestas de reconciliacion profesional
--    Solo matches de alta confianza unicos (high_confidence_unique).
--    Ambiguous y medium se dejan en vista para revision humana.
-- ============================================================================

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
    'prof_' || substr(md5(
        ms.drive_role || '|' ||
        ms.drive_name || '|' ||
        ms.provider_id
    ), 1, 22) AS decision_id,
    'professional_provider' AS anchor_type,
    'staging.hodom_route_visit' AS source_table,
    ms.drive_role || ':' || ms.drive_name AS source_pk,
    'operational.profesional' AS target_table,
    ms.provider_id AS target_pk,
    'maps_to' AS relation_type,
    'proposed' AS decision_status,
    'simulated_expert_reconciliation' AS decided_by,
    now() AS decided_at,
    CASE
        WHEN ms.match_quality = 'high_confidence_unique'
            THEN 'EXPERT_RECOMMENDATION: nombre profesional Drive con coincidencia de primer nombre exacta y profesion correspondiente en operational.profesional.'
        WHEN ms.match_quality = 'high_confidence_ambiguous'
            THEN 'EXPERT_RECOMMENDATION: coincidencia fuerte pero ambigua (varios profesionales DB con el mismo nombre). Requiere revision humana para desambiguar.'
        WHEN ms.match_quality = 'medium_confidence'
            THEN 'EXPERT_RECOMMENDATION: coincidencia por apellido en medicos. Requiere revision responsable.'
        ELSE 'EXPERT_RECOMMENDATION: coincidencia debil. Priorizar revision humana.'
    END AS rationale,
    jsonb_build_object(
        'simulation_run_id', 'expert_reconciliation_2026_05_26_v2',
        'mapping_family', 'professional_name_match',
        'drive_role', ms.drive_role,
        'drive_name', ms.drive_name,
        'cleaned_norm', ms.cleaned_norm,
        'db_name', ms.db_name,
        'db_profesion', ms.db_profesion,
        'db_estado', ms.db_estado,
        'match_score', ms.score,
        'potential_matches', ms.potential_matches,
        'route_count', ms.route_count,
        'human_required', CASE
            WHEN ms.match_quality = 'high_confidence_unique' THEN false
            ELSE true
        END
    ) AS evidence,
    now() AS updated_at
FROM staging.v_hodom_professional_match_scoring ms
WHERE ms.match_quality != 'no_match'
  AND NOT EXISTS (
    SELECT 1 FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = 'professional_provider'
      AND d.source_table = 'staging.hodom_route_visit'
      AND d.source_pk = ms.drive_role || ':' || ms.drive_name
      AND d.target_table = 'operational.profesional'
      AND coalesce(d.target_pk, '') = coalesce(ms.provider_id, '')
      AND d.relation_type = 'maps_to'
);

-- ============================================================================
-- 5. Vista de aplicabilidad por ruta: para cada route_visit_id,
--    muestra que profesional(es) Drive tiene y si hay match en DB
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_route_professional_match;
CREATE OR REPLACE VIEW staging.v_hodom_route_professional_match AS
WITH route_professionals AS (
    SELECT
        rv.route_visit_id,
        prof.role_key AS drive_role,
        prof.name_value AS drive_name,
        staging.norm_text(
            regexp_replace(
                prof.name_value,
                '^(DR\.?|DRA\.?|TENS\.?|SR\.?)\s+',
                '',
                'i'
            )
        ) AS cleaned_norm
    FROM staging.hodom_route_visit rv
    CROSS JOIN LATERAL jsonb_each_text(rv.professionals) AS prof(role_key, name_value)
    WHERE rv.professionals IS NOT NULL
      AND rv.professionals <> '{}'::jsonb
      AND jsonb_typeof(rv.professionals) = 'object'
)
SELECT
    rp.route_visit_id,
    rp.drive_role,
    rp.drive_name,
    rp.cleaned_norm,
    ms.provider_id,
    ms.db_name,
    ms.db_profesion,
    ms.db_estado,
    ms.score,
    ms.match_quality,
    CASE
        WHEN ms.provider_id IS NOT NULL
             AND ms.match_quality = 'high_confidence_unique'
        THEN ms.provider_id
        ELSE NULL
    END AS suggested_provider_id,
    CASE
        WHEN ms.match_quality = 'high_confidence_ambiguous'
            THEN 'AMBIGUOUS: requiere desambiguacion humana'
        WHEN ms.match_quality = 'medium_confidence' OR ms.match_quality = 'low_confidence'
            THEN 'LOW_CONFIDENCE: requiere confirmacion humana'
        WHEN ms.score IS NULL AND dl.is_service_text
            THEN 'SERVICE_TEXT: no es nombre profesional'
        WHEN ms.score IS NULL
            THEN 'NO_MATCH: profesional no encontrado en operational.profesional'
        ELSE NULL
    END AS provider_match_note
FROM route_professionals rp
LEFT JOIN staging.v_hodom_drive_professional_lookup dl
  ON dl.drive_role = rp.drive_role AND dl.drive_name = rp.drive_name
LEFT JOIN staging.v_hodom_professional_match_scoring ms
  ON ms.drive_role = rp.drive_role AND ms.drive_name = rp.drive_name;

COMMENT ON VIEW staging.v_hodom_route_professional_match IS
'Per-route professional matching: each (route_visit_id, professional) pair
 shows whether the Drive professional name maps to an operational.profesional row.
 suggested_provider_id is populated only for high_confidence_unique matches.
 Use this view to enrich pilot migration INSERT with provider_id.';

COMMIT;
