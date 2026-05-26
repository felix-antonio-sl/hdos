-- HODOM Drive pilot migration
-- Controlled pilot: 115 routes EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS.
-- Non-destructive preview first, then provenance-tracked INSERT with explicit operational debt.
--
-- Rules:
--   1. No tocar duplicate_visit.
--   2. provider_id = NULL (deuda operacional aceptada para piloto).
--   3. Provenance completa por fila promovida y por field.
--   4. Rollback por BEGIN/COMMIT atómico; si falla, no se inserta nada.

BEGIN;

-- ============================================================================
-- 1. Vista preview: no insertar sin revisar antes
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_preview AS
WITH pilot_routes AS (
    SELECT
        rv.route_visit_id,
        rv.visit_date,
        rv.planned_time,
        rv.professionals,
        rv.service_text,
        rv.address_text,
        rv.source_path,
        rv.sheet_name,
        rv.source_row_number,
        rv.drive_id,
        c.candidate_visit_id,
        c.matched_patient_id,
        c.matched_stay_id,
        c.promotion_gate,
        e.expert_migration_gate
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c
      ON c.route_visit_id = rv.route_visit_id
    JOIN staging.v_hodom_expert_migration_readiness e
      ON e.route_visit_id = rv.route_visit_id
    WHERE e.expert_migration_gate = 'EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS'
      AND c.promotion_gate = 'READY_IDENTITY_STAY_ONLY'
),
svc_target AS (
    SELECT DISTINCT
        source_pk AS route_visit_id,
        target_pk AS prestacion_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'service_prestacion'
      AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
),
addr_target AS (
    SELECT DISTINCT
        source_pk AS route_visit_id,
        target_pk AS domicilio_id
    FROM staging.hodom_reconciliation_decision
    WHERE decided_by = 'simulated_expert_reconciliation'
      AND anchor_type = 'address_domicilio'
      AND relation_type = 'maps_to'
      AND decision_status = 'proposed'
)
SELECT
    p.route_visit_id,
    p.source_path,
    p.drive_id,
    p.sheet_name,
    p.source_row_number,
    p.professionals,
    p.candidate_visit_id AS visit_id,
    p.matched_patient_id AS patient_id,
    p.matched_stay_id AS stay_id,
    p.visit_date AS fecha,
    p.planned_time AS hora_plan_inicio,
    'PROGRAMADA'::text AS estado,
    'pendiente'::text AS doc_estado,
    false AS rem_reportable,
    cp.nombre_prestacion AS prestacion_nombre,
    s.prestacion_id,
    a.domicilio_id,
    d.localizacion_id,
    d.tipo AS domicilio_tipo,
    l.direccion_texto AS domicilio_direccion,
    prof.suggested_provider_id AS provider_id,
    prof.db_name AS suggested_provider_name,
    prof.db_profesion AS suggested_provider_profesion,
    prof.match_quality AS professional_match_quality,
    prof.provider_match_note
FROM pilot_routes p
JOIN svc_target s ON s.route_visit_id = p.route_visit_id
JOIN addr_target a ON a.route_visit_id = p.route_visit_id
JOIN clinical.domicilio d
  ON d.domicilio_id = a.domicilio_id
 AND d.patient_id = p.matched_patient_id
JOIN territorial.localizacion l
  ON l.localizacion_id = d.localizacion_id
JOIN reference.catalogo_prestacion cp
  ON cp.prestacion_id = s.prestacion_id
LEFT JOIN LATERAL (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.suggested_provider_id,
        rpm.db_name,
        rpm.db_profesion,
        rpm.match_quality,
        rpm.provider_match_note
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.route_visit_id = p.route_visit_id
      AND rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.drive_role
) prof ON true;

COMMENT ON VIEW staging.v_hodom_pilot_minimal_preview IS
'Preview de migracion piloto: 115 rutas EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS.
 Muestra exactamente que se va a insertar en operational.visita (visit_id, patient_id, stay_id,
 fecha, prestacion, domicilio, localizacion, estado=PROGRAMADA, provider_id (poblado cuando hay
 match profesional high-confidence), doc_estado=pendiente).
 Los IDs de pacientes y domicilios son clinicos (no exportar como artefacto versionable).
 Revisar antes de ejecutar la seccion 3 (INSERT).';

-- ============================================================================
-- 2. Gate de verificacion: conteo exacto de rutas piloto
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_gate AS
SELECT
    (SELECT count(*) FROM staging.v_hodom_pilot_minimal_preview) AS preview_visit_count,
    (SELECT count(*)
     FROM staging.v_hodom_expert_migration_readiness
     WHERE expert_migration_gate = 'EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS'
    ) AS expected_pilot_route_count,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_preview pv
     WHERE EXISTS (
         SELECT 1 FROM operational.visita v
         WHERE v.visit_id = pv.visit_id
     )
    ) AS already_promoted_count,
    CASE
        WHEN (SELECT count(*) FROM staging.v_hodom_pilot_minimal_preview) =
             (SELECT count(*)
              FROM staging.v_hodom_expert_migration_readiness
              WHERE expert_migration_gate = 'EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS')
            THEN 'PASS: todos los candidatos estan en la vista preview'
        ELSE 'WARN: discrepancia de cardinalidad entre preview y readiness'
    END AS pilot_preview_gate;

COMMENT ON VIEW staging.v_hodom_pilot_minimal_gate IS
'Gate pre-INSERT: verifica que el conteo de la vista preview coincide con el readiness experto.
 Si already_promoted_count > 0, hay visitas ya insertadas (potencial duplicado).';

-- ============================================================================
-- 3. Promocion: INSERT en operational.visita CON provenance completa
-- ============================================================================

INSERT INTO operational.visita (
    visit_id,
    stay_id,
    patient_id,
    provider_id,
    fecha,
    hora_plan_inicio,
    estado,
    doc_estado,
    rem_reportable,
    prestacion_id,
    domicilio_id,
    localizacion_id,
    created_at,
    updated_at
)
SELECT
    pv.visit_id,
    pv.stay_id,
    pv.patient_id,
    pv.provider_id,
    pv.fecha,
    pv.hora_plan_inicio,
    'PROGRAMADA'::text AS estado,
    'pendiente'::text AS doc_estado,
    false AS rem_reportable,
    pv.prestacion_id,
    pv.domicilio_id,
    pv.localizacion_id,
    now() AS created_at,
    now() AS updated_at
FROM staging.v_hodom_pilot_minimal_preview pv
WHERE NOT EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = pv.visit_id
);

-- ============================================================================
-- 4. Provenance: registro por fila y por field promovido
-- ============================================================================

INSERT INTO migration.provenance (
    target_table,
    target_pk,
    source_type,
    source_file,
    source_key,
    phase,
    field_name,
    created_at
)
SELECT
    'operational.visita' AS target_table,
    pv.visit_id AS target_pk,
    'drive_import' AS source_type,
    pv.source_path AS source_file,
    pv.route_visit_id AS source_key,
    'pilot_minimal_2026_05_26' AS phase,
    field.field_name,
    now() AS created_at
FROM staging.v_hodom_pilot_minimal_preview pv
CROSS JOIN (
    VALUES
        ('visit_id'),
        ('stay_id'),
        ('patient_id'),
        ('provider_id'),
        ('fecha'),
        ('hora_plan_inicio'),
        ('estado'),
        ('doc_estado'),
        ('prestacion_id'),
        ('domicilio_id'),
        ('localizacion_id')
) AS field(field_name)
WHERE NOT EXISTS (
    SELECT 1 FROM migration.provenance mp
    WHERE mp.target_table = 'operational.visita'
      AND mp.target_pk = pv.visit_id
      AND mp.field_name = field.field_name
      AND mp.phase = 'pilot_minimal_2026_05_26'
)
AND EXISTS (
    SELECT 1 FROM operational.visita v
    WHERE v.visit_id = pv.visit_id
);

-- ============================================================================
-- 5. Vista de auditoria post-promocion
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_audit AS
SELECT
    pv.visit_id,
    pv.fecha,
    CASE WHEN v.visit_id IS NOT NULL THEN true ELSE false END AS promoted,
    CASE WHEN v.provider_id IS NOT NULL THEN v.provider_id ELSE NULL END AS provider_id_assigned,
    pv.suggested_provider_name,
    pv.professional_match_quality,
    v.prestacion_id AS promoted_prestacion_id,
    v.domicilio_id AS promoted_domicilio_id,
    v.localizacion_id AS promoted_localizacion_id,
    v.estado AS promoted_estado,
    v.created_at AS promoted_at,
    (SELECT count(*)
     FROM migration.provenance mp
     WHERE mp.target_table = 'operational.visita'
       AND mp.target_pk = pv.visit_id
       AND mp.phase = 'pilot_minimal_2026_05_26'
    ) AS provenance_field_count
FROM staging.v_hodom_pilot_minimal_preview pv
LEFT JOIN operational.visita v
  ON v.visit_id = pv.visit_id;

COMMENT ON VIEW staging.v_hodom_pilot_minimal_audit IS
'Auditoria post-promocion: cada fila esperada muestra si fue promovida,
 provider_id (poblado si hay match profesional), prestacion, domicilio, localizacion,
 estado y conteo de provenance por field (11 campos).';

-- ============================================================================
-- 6. Promocion summary (seguro para documentacion, sin IDs clinicos)
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_promotion_summary AS
SELECT
    'pilot_minimal_2026_05_26' AS migration_phase,
    (SELECT count(*) FROM staging.v_hodom_pilot_minimal_preview) AS expected_visits,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_audit
     WHERE promoted
    ) AS promoted_visits,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_preview pv
     JOIN operational.visita v ON v.visit_id = pv.visit_id
     WHERE v.provider_id IS NOT NULL
    ) AS rows_with_provider_assigned,
    (SELECT count(*)
     FROM migration.provenance mp
     WHERE mp.phase = 'pilot_minimal_2026_05_26'
    ) AS provenance_rows_total,
    (SELECT count(DISTINCT mp.target_pk)
     FROM migration.provenance mp
     WHERE mp.phase = 'pilot_minimal_2026_05_26'
    ) AS provenance_visits_with_provenance,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_preview pv
     JOIN operational.visita v ON v.visit_id = pv.visit_id
    ) AS matching_visits_in_core,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_preview pv
     JOIN operational.visita v ON v.visit_id = pv.visit_id
     WHERE v.prestacion_id IS NOT NULL
    ) AS rows_with_prestacion,
    (SELECT count(*)
     FROM staging.v_hodom_pilot_minimal_preview pv
     JOIN operational.visita v ON v.visit_id = pv.visit_id
     WHERE v.domicilio_id IS NOT NULL
    ) AS rows_with_domicilio,
    now() AS generated_at;

COMMENT ON VIEW staging.v_hodom_pilot_minimal_promotion_summary IS
'Resumen agregado de la migracion piloto. Seguro para documentacion versionable:
 sin IDs clinicos, solo conteos y estado de deuda operacional.';

COMMIT;
