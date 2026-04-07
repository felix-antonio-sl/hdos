-- ============================================================
-- VISTAS OPERATIVAS Y FUNCIONES REM — HODOM HSC
-- Adaptadas a la BD existente (hodom-pg-v4, puerto 5555)
-- Fecha: 2026-04-07
-- ============================================================

-- ============================================================
-- 1. TABLERO DE COORDINACIÓN (Pantalla 1)
-- ============================================================

CREATE OR REPLACE VIEW operational.v_tablero_coordinacion AS
SELECT
    e.stay_id,
    p.patient_id,
    p.nombre_completo AS paciente,
    p.rut,
    EXTRACT(YEAR FROM age(p.fecha_nacimiento))::INT AS edad,
    p.sexo,
    p.direccion,
    p.comuna,
    p.contacto_telefono,
    e.diagnostico_principal,
    e.estado,
    e.fecha_ingreso,
    (CURRENT_DATE - e.fecha_ingreso) AS dias_estada,
    e.origen_derivacion,
    e.condicion_domicilio,
    e.establecimiento_id,
    -- Última visita realizada
    (SELECT v.fecha FROM operational.visita v
     WHERE v.stay_id = e.stay_id AND v.estado IN ('COMPLETA','DOCUMENTADA','VERIFICADA','REPORTADA_REM')
     ORDER BY v.fecha DESC, v.hora_real_fin DESC NULLS LAST LIMIT 1
    ) AS ultima_visita,
    -- Próxima visita programada
    (SELECT v.fecha FROM operational.visita v
     WHERE v.stay_id = e.stay_id AND v.estado IN ('PROGRAMADA','ASIGNADA')
       AND v.fecha >= CURRENT_DATE
     ORDER BY v.fecha, v.hora_plan_inicio LIMIT 1
    ) AS proxima_visita,
    -- Alertas activas
    (SELECT count(*) FROM clinical.alerta a
     WHERE a.stay_id = e.stay_id AND a.estado = 'activa'
    )::INT AS alertas_activas,
    -- Días sin visita
    (CURRENT_DATE - COALESCE(
        (SELECT max(v.fecha) FROM operational.visita v
         WHERE v.stay_id = e.stay_id AND v.estado IN ('COMPLETA','DOCUMENTADA','VERIFICADA','REPORTADA_REM')),
        e.fecha_ingreso
    )) AS dias_sin_visita
FROM clinical.estadia e
JOIN clinical.paciente p ON e.patient_id = p.patient_id
WHERE e.estado IN ('activo', 'admitido')
ORDER BY e.fecha_ingreso;

COMMENT ON VIEW operational.v_tablero_coordinacion IS 'Pantalla 1: tablero de coordinación con pacientes activos, alertas y próximas visitas';

-- ============================================================
-- 2. POSTULACIONES PENDIENTES (Pantalla 1, sección superior)
-- ============================================================

CREATE OR REPLACE VIEW operational.v_postulaciones_pendientes AS
SELECT
    e.stay_id,
    p.nombre_completo AS paciente,
    p.rut,
    EXTRACT(YEAR FROM age(p.fecha_nacimiento))::INT AS edad,
    e.diagnostico_principal,
    e.origen_derivacion,
    e.fecha_ingreso AS fecha_postulacion,
    e.estado,
    -- Consentimiento
    (SELECT c.decision FROM clinical.consentimiento c
     WHERE c.stay_id = e.stay_id AND c.tipo = 'hospitalizacion_domiciliaria'
     ORDER BY c.fecha DESC LIMIT 1
    ) AS consentimiento,
    -- Informe social
    (SELECT i.condicion_domicilio FROM clinical.informe_social i
     WHERE i.stay_id = e.stay_id
     ORDER BY i.fecha DESC LIMIT 1
    ) AS condicion_domicilio_eval,
    -- Checklist completado
    (SELECT count(*) FROM clinical.checklist_ingreso ci
     WHERE ci.stay_id = e.stay_id
    )::INT AS checklist_items
FROM clinical.estadia e
JOIN clinical.paciente p ON e.patient_id = p.patient_id
WHERE e.estado IN ('pendiente_evaluacion', 'elegible')
ORDER BY e.fecha_ingreso;

COMMENT ON VIEW operational.v_postulaciones_pendientes IS 'Postulaciones en proceso de evaluación de elegibilidad';

-- ============================================================
-- 3. AGENDA DEL DÍA (Pantalla 3)
-- ============================================================

CREATE OR REPLACE VIEW operational.v_agenda_dia AS
SELECT
    v.visit_id,
    v.fecha,
    v.hora_plan_inicio,
    v.estado AS estado_visita,
    v.seq_en_ruta,
    -- Profesional
    pr.provider_id,
    pr.nombre AS profesional,
    pr.profesion,
    pr.profesion_rem,
    -- Paciente
    p.nombre_completo AS paciente,
    p.rut AS paciente_rut,
    p.direccion,
    p.comuna,
    p.contacto_telefono,
    -- Episodio
    e.stay_id,
    e.diagnostico_principal,
    e.estado AS estado_episodio,
    -- Ruta
    r.route_id,
    r.estado AS estado_ruta,
    -- Prestación
    v.rem_prestacion AS tipo_atencion,
    cp.nombre_prestacion
FROM operational.visita v
JOIN clinical.estadia e ON v.stay_id = e.stay_id
JOIN clinical.paciente p ON v.patient_id = p.patient_id
LEFT JOIN operational.profesional pr ON v.provider_id = pr.provider_id
LEFT JOIN operational.ruta r ON v.route_id = r.route_id
LEFT JOIN reference.catalogo_prestacion cp ON v.prestacion_id = cp.prestacion_id
ORDER BY v.fecha, r.route_id, v.seq_en_ruta, v.hora_plan_inicio;

COMMENT ON VIEW operational.v_agenda_dia IS 'Pantalla 3: agenda de visitas por día, profesional y ruta';

-- ============================================================
-- 4. LLAMADAS DEL DÍA (Pantalla 4)
-- ============================================================

CREATE OR REPLACE VIEW operational.v_llamadas AS
SELECT
    rl.llamada_id,
    rl.fecha,
    rl.hora,
    rl.duracion,
    rl.tipo,
    rl.motivo,
    rl.observaciones,
    rl.nombre_familiar,
    rl.parentesco_familiar,
    rl.estado_paciente,
    p.nombre_completo AS paciente,
    p.rut AS paciente_rut,
    pr.nombre AS profesional,
    rl.stay_id
FROM operational.registro_llamada rl
LEFT JOIN clinical.paciente p ON rl.patient_id = p.patient_id
LEFT JOIN operational.profesional pr ON rl.provider_id = pr.provider_id
ORDER BY rl.fecha DESC, rl.hora DESC;

COMMENT ON VIEW operational.v_llamadas IS 'Pantalla 4: bandeja de llamadas';

-- ============================================================
-- 5. FICHA CLÍNICA — Timeline (Pantalla 2)
-- ============================================================

CREATE OR REPLACE VIEW clinical.v_timeline_episodio AS
SELECT
    e.stay_id,
    'nota_evolucion' AS tipo_registro,
    ne.nota_id AS registro_id,
    ne.tipo AS subtipo,
    ne.fecha,
    ne.hora,
    pr.nombre AS profesional,
    pr.profesion,
    ne.notas_clinicas AS contenido,
    ne.plan_enfermeria AS contenido_extra
FROM clinical.nota_evolucion ne
JOIN clinical.estadia e ON ne.stay_id = e.stay_id
LEFT JOIN operational.profesional pr ON ne.provider_id = pr.provider_id

UNION ALL

SELECT
    e.stay_id,
    'valoracion_ingreso' AS tipo_registro,
    vi.assessment_id AS registro_id,
    vi.tipo AS subtipo,
    vi.fecha,
    NULL AS hora,
    pr.nombre AS profesional,
    pr.profesion,
    vi.historia_ingreso AS contenido,
    vi.diagnostico_enfermeria AS contenido_extra
FROM clinical.valoracion_ingreso vi
JOIN clinical.estadia e ON vi.stay_id = e.stay_id
LEFT JOIN operational.profesional pr ON vi.provider_id = pr.provider_id

UNION ALL

SELECT
    e.stay_id,
    'epicrisis' AS tipo_registro,
    ep.epicrisis_id AS registro_id,
    ep.tipo_egreso AS subtipo,
    ep.fecha_emision AS fecha,
    NULL AS hora,
    pr.nombre AS profesional,
    'medica'::text AS profesion,
    ep.resumen_evolucion AS contenido,
    ep.indicaciones_alta AS contenido_extra
FROM clinical.epicrisis ep
JOIN clinical.estadia e ON ep.stay_id = e.stay_id
LEFT JOIN operational.profesional pr ON ep.provider_id = pr.provider_id

ORDER BY fecha DESC, hora DESC NULLS LAST;

COMMENT ON VIEW clinical.v_timeline_episodio IS 'Pantalla 2: timeline cronológica de la ficha clínica por episodio';

-- ============================================================
-- 6. RESUMEN MES (Pantalla 1, sección inferior)
-- ============================================================

CREATE OR REPLACE VIEW reporting.v_resumen_mes AS
SELECT
    date_trunc('month', CURRENT_DATE)::DATE AS periodo_inicio,
    (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::DATE AS periodo_fin,
    -- Ingresos del mes
    (SELECT count(*) FROM clinical.estadia
     WHERE fecha_ingreso >= date_trunc('month', CURRENT_DATE)
       AND fecha_ingreso < date_trunc('month', CURRENT_DATE) + interval '1 month'
    )::INT AS ingresos,
    -- Egresos del mes (altas + disciplinarias + renuncias)
    (SELECT count(*) FROM clinical.estadia
     WHERE fecha_egreso >= date_trunc('month', CURRENT_DATE)
       AND fecha_egreso < date_trunc('month', CURRENT_DATE) + interval '1 month'
       AND tipo_egreso IN ('alta_clinica','renuncia_voluntaria','alta_disciplinaria')
    )::INT AS altas,
    -- Fallecidos
    (SELECT count(*) FROM clinical.estadia
     WHERE fecha_egreso >= date_trunc('month', CURRENT_DATE)
       AND fecha_egreso < date_trunc('month', CURRENT_DATE) + interval '1 month'
       AND tipo_egreso IN ('fallecido_esperado','fallecido_no_esperado')
    )::INT AS fallecidos,
    -- Reingresos
    (SELECT count(*) FROM clinical.estadia
     WHERE fecha_egreso >= date_trunc('month', CURRENT_DATE)
       AND fecha_egreso < date_trunc('month', CURRENT_DATE) + interval '1 month'
       AND tipo_egreso = 'reingreso'
    )::INT AS reingresos,
    -- Pacientes activos ahora
    (SELECT count(*) FROM clinical.estadia WHERE estado IN ('activo','admitido'))::INT AS activos_hoy,
    -- Visitas del mes
    (SELECT count(*) FROM operational.visita
     WHERE fecha >= date_trunc('month', CURRENT_DATE)
       AND fecha < date_trunc('month', CURRENT_DATE) + interval '1 month'
       AND estado IN ('COMPLETA','DOCUMENTADA','VERIFICADA','REPORTADA_REM')
    )::INT AS visitas_mes;

COMMENT ON VIEW reporting.v_resumen_mes IS 'Pantalla 1: resumen operacional del mes corriente';

-- ============================================================
-- 7. FUNCIONES REM A21 (Pantalla 5)
-- ============================================================

-- REM C.1.1: Personas atendidas por período
CREATE OR REPLACE FUNCTION reporting.fn_rem_personas_atendidas(p_periodo TEXT)
RETURNS TABLE (
    componente TEXT,
    total BIGINT,
    menores_15 BIGINT,
    rango_15_19 BIGINT,
    mayores_20 BIGINT,
    sexo_masculino BIGINT,
    sexo_femenino BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    -- Ingresos
    RETURN QUERY
    SELECT 'ingresos'::TEXT, COUNT(*)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM clinical.estadia e
    JOIN clinical.paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_ingreso BETWEEN v_inicio AND v_fin
      AND e.estado NOT IN ('pendiente_evaluacion');

    -- Personas atendidas (activas en el periodo)
    RETURN QUERY
    SELECT 'personas_atendidas'::TEXT, COUNT(DISTINCT e.patient_id)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE EXTRACT(YEAR FROM age(v_inicio, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(DISTINCT e.patient_id) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM clinical.estadia e
    JOIN clinical.paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_ingreso <= v_fin
      AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= v_inicio)
      AND e.estado NOT IN ('pendiente_evaluacion');

    -- Días persona
    RETURN QUERY
    SELECT 'dias_persona'::TEXT,
        COALESCE(SUM(
            LEAST(v_fin, COALESCE(e.fecha_egreso, v_fin)) - GREATEST(v_inicio, e.fecha_ingreso) + 1
        ), 0)::BIGINT,
        0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM clinical.estadia e
    WHERE e.fecha_ingreso <= v_fin
      AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= v_inicio)
      AND e.estado NOT IN ('pendiente_evaluacion');

    -- Altas
    RETURN QUERY
    SELECT 'altas'::TEXT, COUNT(*)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) < 15)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) BETWEEN 15 AND 19)::BIGINT,
        COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM age(e.fecha_egreso, p.fecha_nacimiento)) >= 20)::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'masculino')::BIGINT,
        COUNT(*) FILTER (WHERE p.sexo = 'femenino')::BIGINT
    FROM clinical.estadia e
    JOIN clinical.paciente p ON e.patient_id = p.patient_id
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin
      AND e.tipo_egreso IN ('alta_clinica', 'renuncia_voluntaria', 'alta_disciplinaria');

    -- Fallecidos esperados
    RETURN QUERY
    SELECT 'fallecidos_esperados'::TEXT, COUNT(*)::BIGINT,
        0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM clinical.estadia e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin AND e.tipo_egreso = 'fallecido_esperado';

    -- Fallecidos no esperados
    RETURN QUERY
    SELECT 'fallecidos_no_esperados'::TEXT, COUNT(*)::BIGINT,
        0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM clinical.estadia e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin AND e.tipo_egreso = 'fallecido_no_esperado';

    -- Reingresos
    RETURN QUERY
    SELECT 'reingresos'::TEXT, COUNT(*)::BIGINT,
        0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT, 0::BIGINT
    FROM clinical.estadia e
    WHERE e.fecha_egreso BETWEEN v_inicio AND v_fin AND e.tipo_egreso = 'reingreso';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reporting.fn_rem_personas_atendidas IS 'REM A21 C.1.1 — Personas atendidas. Parámetro: YYYY-MM';

-- REM C.1.2: Visitas por profesión
CREATE OR REPLACE FUNCTION reporting.fn_rem_visitas(p_periodo TEXT)
RETURNS TABLE (
    profesion_rem TEXT,
    total_visitas BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    RETURN QUERY
    SELECT pr.profesion_rem, COUNT(*)::BIGINT
    FROM operational.visita v
    JOIN operational.profesional pr ON v.provider_id = pr.provider_id
    WHERE v.fecha BETWEEN v_inicio AND v_fin
      AND v.estado IN ('COMPLETA','DOCUMENTADA','VERIFICADA','REPORTADA_REM')
      AND v.rem_reportable = true
      AND pr.profesion_rem IS NOT NULL
    GROUP BY pr.profesion_rem
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reporting.fn_rem_visitas IS 'REM A21 C.1.2 — Visitas por profesión. Parámetro: YYYY-MM';

-- REM C.1.1 desglose por origen de derivación
CREATE OR REPLACE FUNCTION reporting.fn_rem_origen_derivacion(p_periodo TEXT)
RETURNS TABLE (
    origen TEXT,
    total BIGINT
) AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
BEGIN
    v_inicio := (p_periodo || '-01')::DATE;
    v_fin := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    RETURN QUERY
    SELECT e.origen_derivacion, COUNT(*)::BIGINT
    FROM clinical.estadia e
    WHERE e.fecha_ingreso BETWEEN v_inicio AND v_fin
      AND e.origen_derivacion IS NOT NULL
      AND e.estado NOT IN ('pendiente_evaluacion')
    GROUP BY e.origen_derivacion;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reporting.fn_rem_origen_derivacion IS 'REM A21 C.1.1 desglose — Origen de derivación. Parámetro: YYYY-MM';

-- ============================================================
-- 8. OCUPACIÓN (para Tablero y REM C.1.3)
-- ============================================================

CREATE OR REPLACE FUNCTION reporting.fn_ocupacion_dia(p_fecha DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    fecha DATE,
    activos BIGINT,
    cupos_programados INT,
    ocupacion_pct NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p_fecha,
        (SELECT count(*) FROM clinical.estadia e
         WHERE e.fecha_ingreso <= p_fecha
           AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= p_fecha)
           AND e.estado IN ('activo','admitido')
        )::BIGINT,
        COALESCE(
            (SELECT cp.cupos_permanentes FROM operational.configuracion_programa cp LIMIT 1),
            25 -- default HSC
        )::INT,
        ROUND(
            (SELECT count(*) FROM clinical.estadia e
             WHERE e.fecha_ingreso <= p_fecha
               AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= p_fecha)
               AND e.estado IN ('activo','admitido')
            )::NUMERIC /
            GREATEST(COALESCE(
                (SELECT cp.cupos_permanentes FROM operational.configuracion_programa cp LIMIT 1),
                25
            ), 1) * 100,
        1)
    ;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reporting.fn_ocupacion_dia IS 'Ocupación diaria: activos / cupos programados';
