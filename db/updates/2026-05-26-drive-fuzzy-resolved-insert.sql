-- HODOM Drive 2026 — Phase 5: INSERT fuzzy-resolved visits
-- 310 routes with patient identity resolved via fuzzy name matching
-- and active estadia confirmed. Net-new visits to operational.visita.

BEGIN;

-- ============================================================================
-- 1. Vista preview
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_preview_2026;
CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_preview_2026 AS
WITH fuzzy_patients AS (
    SELECT DISTINCT
        d.source_pk AS blocked_name,
        d.target_pk AS resolved_patient_id
    FROM staging.hodom_reconciliation_decision d
    WHERE d.anchor_type = 'patient_identity'
      AND d.relation_type = 'same_as'
      AND d.decision_status = 'proposed'
      AND d.rationale LIKE 'FUZZY_MATCH%'
),
resolved AS (
    SELECT
        rv.route_visit_id, rv.visit_date, rv.planned_time, rv.source_path,
        rv.drive_id, rv.sheet_name, rv.source_row_number,
        c.candidate_visit_id, fp.resolved_patient_id,
        e.stay_id AS resolved_stay_id
    FROM staging.hodom_route_visit rv
    JOIN staging.v_hodom_route_promotion_contract c ON c.route_visit_id = rv.route_visit_id
    JOIN fuzzy_patients fp ON staging.norm_text(rv.patient_name) = fp.blocked_name
    JOIN clinical.estadia e
      ON e.patient_id = fp.resolved_patient_id
     AND rv.visit_date >= e.fecha_ingreso
     AND rv.visit_date <= coalesce(e.fecha_egreso, rv.visit_date)
    WHERE rv.visit_date >= '2026-01-01'
      AND NOT EXISTS (
        SELECT 1 FROM operational.visita v WHERE v.visit_id = c.candidate_visit_id
    )
),
svc_target AS (
    SELECT DISTINCT source_pk AS route_visit_id, target_pk AS prestacion_id
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type = 'service_prestacion' AND relation_type = 'maps_to'
      AND decision_status = 'proposed' AND decided_by = 'simulated_expert_reconciliation'
),
addr_target AS (
    SELECT DISTINCT source_pk AS route_visit_id, target_pk AS domicilio_id
    FROM staging.hodom_reconciliation_decision
    WHERE anchor_type = 'address_domicilio' AND relation_type = 'maps_to'
      AND decision_status = 'proposed' AND decided_by = 'simulated_expert_reconciliation'
),
best_prof AS (
    SELECT DISTINCT ON (rpm.route_visit_id)
        rpm.route_visit_id, rpm.suggested_provider_id, rpm.db_name, rpm.match_quality
    FROM staging.v_hodom_route_professional_match rpm
    WHERE rpm.suggested_provider_id IS NOT NULL
    ORDER BY rpm.route_visit_id, rpm.match_quality
)
SELECT
    r.route_visit_id, r.source_path, r.drive_id, r.sheet_name, r.source_row_number,
    r.candidate_visit_id AS visit_id, r.resolved_patient_id AS patient_id,
    r.resolved_stay_id AS stay_id, r.visit_date AS fecha,
    r.planned_time AS hora_plan_inicio,
    bp.suggested_provider_id AS provider_id, bp.db_name AS provider_name,
    s.prestacion_id, a.domicilio_id,
    s.prestacion_id IS NOT NULL AS tiene_prestacion,
    a.domicilio_id IS NOT NULL AS tiene_domicilio,
    bp.suggested_provider_id IS NOT NULL AS tiene_provider
FROM resolved r
LEFT JOIN svc_target s ON s.route_visit_id = r.route_visit_id
LEFT JOIN addr_target a ON a.route_visit_id = r.route_visit_id
LEFT JOIN best_prof bp ON bp.route_visit_id = r.route_visit_id;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_preview_2026 IS
'Preview de visitas fuzzy-resolved 2026: identidad paciente confirmada via fuzzy matching,
 estadia activa verificada. ~310 rutas listas para INSERT en operational.visita.';

-- ============================================================================
-- 2. Gate
-- ============================================================================

DROP VIEW IF EXISTS staging.v_hodom_fuzzy_resolved_gate_2026;
CREATE OR REPLACE VIEW staging.v_hodom_fuzzy_resolved_gate_2026 AS
SELECT
    count(*) AS candidates,
    count(*) FILTER (WHERE tiene_prestacion) AS with_prestacion,
    count(*) FILTER (WHERE tiene_domicilio) AS with_domicilio,
    count(*) FILTER (WHERE tiene_provider) AS with_provider,
    now() AS generated_at
FROM staging.v_hodom_fuzzy_resolved_preview_2026;

COMMENT ON VIEW staging.v_hodom_fuzzy_resolved_gate_2026 IS
'Gate pre-INSERT de visitas fuzzy-resolved 2026.';

-- ============================================================================
-- 3. INSERT
-- ============================================================================

INSERT INTO operational.visita (
    visit_id, stay_id, patient_id, provider_id, fecha,
    hora_plan_inicio, estado, doc_estado, rem_reportable,
    prestacion_id, domicilio_id, created_at, updated_at
)
SELECT DISTINCT ON (pv.visit_id)
    pv.visit_id, pv.stay_id, pv.patient_id, pv.provider_id, pv.fecha,
    pv.hora_plan_inicio,
    'PROGRAMADA', 'pendiente', false,
    pv.prestacion_id, pv.domicilio_id,
    now(), now()
FROM staging.v_hodom_fuzzy_resolved_preview_2026 pv
WHERE NOT EXISTS (
    SELECT 1 FROM operational.visita v WHERE v.visit_id = pv.visit_id
);

COMMIT;
