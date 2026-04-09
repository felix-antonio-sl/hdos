--
-- PostgreSQL database dump
--

\restrict 7D6sCWVEhLQDnfUa8CZnThmHbx6zhVRizm9yza30rdaaeoGWUYuou4TOyh3bbo8

-- Dumped from database version 14.22
-- Dumped by pg_dump version 14.22

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: clinical; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA clinical;


--
-- Name: migration; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA migration;


--
-- Name: operational; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA operational;


--
-- Name: portal; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA portal;


--
-- Name: reference; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA reference;


--
-- Name: reporting; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA reporting;


--
-- Name: strict; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA strict;


--
-- Name: telemetry; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA telemetry;


--
-- Name: territorial; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA territorial;


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: check_visita_domicilio_coherence(); Type: FUNCTION; Schema: clinical; Owner: -
--

CREATE FUNCTION clinical.check_visita_domicilio_coherence() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    dom_loc TEXT;
    dom_pac TEXT;
    vis_pac TEXT;
BEGIN
    IF NEW.domicilio_id IS NOT NULL THEN
        SELECT d.localizacion_id, d.patient_id
          INTO dom_loc, dom_pac
          FROM clinical.domicilio d
         WHERE d.domicilio_id = NEW.domicilio_id;

        IF NEW.localizacion_id IS NULL THEN
            NEW.localizacion_id := dom_loc;
        ELSIF NEW.localizacion_id != dom_loc THEN
            RAISE EXCEPTION 'PE1 violation: visita.localizacion_id (%) != domicilio.localizacion_id (%)',
                NEW.localizacion_id, dom_loc;
        END IF;

        SELECT e.patient_id INTO vis_pac
          FROM clinical.estadia e
         WHERE e.stay_id = NEW.stay_id;

        IF dom_pac != vis_pac THEN
            RAISE EXCEPTION 'PE2 violation: domicilio.patient_id (%) != estadia.patient_id (%)',
                dom_pac, vis_pac;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: prevent_chat_delete(); Type: FUNCTION; Schema: clinical; Owner: -
--

CREATE FUNCTION clinical.prevent_chat_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'Los mensajes de chat clínico no pueden ser eliminados (Ley 20.584)';
  RETURN NULL;
END;
$$;


--
-- Name: transition_estadia(text, text, text, text); Type: FUNCTION; Schema: clinical; Owner: -
--

CREATE FUNCTION clinical.transition_estadia(p_stay_id text, p_new_estado text, p_proceso_opm text DEFAULT NULL::text, p_detalle text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
  v_old_estado TEXT;
  v_event_id TEXT;
  v_valid_opm BOOLEAN;
  v_opm TEXT;
  v_det TEXT;
BEGIN
  SELECT estado INTO v_old_estado FROM estadia WHERE stay_id = p_stay_id;
  IF v_old_estado IS NULL THEN
    RAISE EXCEPTION 'Estadia % not found', p_stay_id;
  END IF;
  IF v_old_estado = p_new_estado THEN
    RETURN NULL;
  END IF;
  -- Validate proceso_opm against CHECK constraint
  v_valid_opm := p_proceso_opm IS NOT NULL AND p_proceso_opm IN (
    'eligibility_evaluating','patient_admitting','care_planning',
    'therapeutic_plan_executing','clinical_evolution_monitoring',
    'patient_discharging','post_discharge_following'
  );
  v_opm := CASE WHEN v_valid_opm THEN p_proceso_opm ELSE NULL END;
  v_det := CASE WHEN v_valid_opm THEN p_detalle ELSE COALESCE(p_proceso_opm || ': ' || COALESCE(p_detalle,''), p_detalle) END;

  v_event_id := 'ev_' || substr(md5(random()::text), 1, 12);
  INSERT INTO evento_estadia (event_id, stay_id, timestamp, estado_previo, estado_nuevo, proceso_opm, detalle)
  VALUES (v_event_id, p_stay_id, NOW(), v_old_estado, p_new_estado, v_opm, v_det);
  RETURN v_event_id;
END;
$$;


--
-- Name: transition_visita(text, text, text, text); Type: FUNCTION; Schema: operational; Owner: -
--

CREATE FUNCTION operational.transition_visita(p_visit_id text, p_new_estado text, p_origen text DEFAULT 'app'::text, p_detalle text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
  v_old_estado TEXT;
  v_event_id TEXT;
BEGIN
  SELECT estado INTO v_old_estado FROM visita WHERE visit_id = p_visit_id;
  IF v_old_estado IS NULL THEN
    RAISE EXCEPTION 'Visita % not found', p_visit_id;
  END IF;
  IF v_old_estado = p_new_estado THEN
    RETURN NULL; -- no-op
  END IF;
  v_event_id := 'ev_' || substr(md5(random()::text), 1, 12);
  INSERT INTO evento_visita (event_id, visit_id, timestamp, estado_previo, estado_nuevo, origen, detalle)
  VALUES (v_event_id, p_visit_id, NOW(), v_old_estado, p_new_estado, p_origen, p_detalle);
  RETURN v_event_id;
END;
$$;


--
-- Name: check_documentacion_coherencia(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_documentacion_coherencia() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_estadia_patient TEXT;
BEGIN
    IF NEW.stay_id IS NULL OR NEW.patient_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT patient_id INTO v_estadia_patient
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_estadia_patient IS NOT NULL AND NEW.patient_id IS DISTINCT FROM v_estadia_patient THEN
        RAISE EXCEPTION 'Documentación patient_id (%) does not match estadia patient_id (%)',
            NEW.patient_id, v_estadia_patient;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_encuesta_pe7(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_encuesta_pe7() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    IF NEW.stay_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_tipo_egreso IS NULL THEN
        RAISE EXCEPTION 'PE-7: Cannot register encuesta_satisfaccion for stay_id % — estadia has no tipo_egreso (patient not yet discharged)', NEW.stay_id;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_encuesta_stay_required(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_encuesta_stay_required() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NEW.stay_id IS NULL THEN
        RAISE EXCEPTION 'encuesta_satisfaccion requires stay_id — cannot be NULL';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: check_epicrisis_sync_estadia(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_epicrisis_sync_estadia() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF v_tipo_egreso IS NOT NULL AND NEW.tipo_egreso IS DISTINCT FROM v_tipo_egreso THEN
        RAISE EXCEPTION 'Epicrisis tipo_egreso (%) does not match estadia tipo_egreso (%)',
            NEW.tipo_egreso, v_tipo_egreso;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_estadia_transition(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_estadia_transition() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM maquina_estados_estadia_ref
        WHERE from_state = NEW.estado_previo
          AND to_state   = NEW.estado_nuevo
    ) THEN
        RAISE EXCEPTION 'Invalid estadia transition: % → %',
            NEW.estado_previo, NEW.estado_nuevo;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: check_pe1(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_pe1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_patient_id TEXT;
BEGIN
    -- Skip check if stay_id is NULL (e.g. external derivaciones)
    IF NEW.stay_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT patient_id INTO v_patient_id
    FROM clinical.estadia
    WHERE stay_id = NEW.stay_id;

    IF v_patient_id IS NULL THEN
        RAISE EXCEPTION 'PE-1: stay_id % not found in estadia', NEW.stay_id;
    END IF;

    IF NEW.patient_id IS DISTINCT FROM v_patient_id THEN
        RAISE EXCEPTION 'PE-1: patient_id mismatch -- record has %, estadia has %',
            NEW.patient_id, v_patient_id;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_profesional_coherencia_rem(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_profesional_coherencia_rem() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    -- NUTRICION has no profesion_rem mapping — must be NULL
    IF NEW.profesion = 'NUTRICION' AND NEW.profesion_rem IS NOT NULL THEN
        RAISE EXCEPTION 'Profesion NUTRICION has no REM mapping — profesion_rem must be NULL, got %',
            NEW.profesion_rem;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: check_protocolo_tipo_egreso(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_protocolo_tipo_egreso() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_tipo_egreso TEXT;
BEGIN
    SELECT tipo_egreso INTO v_tipo_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    -- First check: tipo_egreso must be a fallecido type
    IF v_tipo_egreso NOT IN ('fallecido_esperado', 'fallecido_no_esperado') THEN
        RAISE EXCEPTION 'FIX-9: protocolo_fallecimiento requires estadia.tipo_egreso IN (fallecido_esperado, fallecido_no_esperado), got %',
            v_tipo_egreso;
    END IF;

    -- Then cross-validate semantic alignment
    IF NEW.tipo = 'esperado' AND v_tipo_egreso != 'fallecido_esperado' THEN
        RAISE EXCEPTION 'FIX-9: protocolo.tipo=esperado but estadia.tipo_egreso=% (expected fallecido_esperado)',
            v_tipo_egreso;
    END IF;

    IF NEW.tipo = 'no_esperado' AND v_tipo_egreso != 'fallecido_no_esperado' THEN
        RAISE EXCEPTION 'FIX-9: protocolo.tipo=no_esperado but estadia.tipo_egreso=% (expected fallecido_no_esperado)',
            v_tipo_egreso;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_rem_cupos_rc5(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_rem_cupos_rc5() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NEW.cupos_utilizados > NEW.cupos_programados THEN
        RAISE EXCEPTION 'RC-5: cupos_utilizados (%) > cupos_programados (%)',
            NEW.cupos_utilizados, NEW.cupos_programados;
    END IF;

    IF NEW.dias_cama_utilizados > NEW.dias_cama_disponibles THEN
        RAISE EXCEPTION 'RC-5: dias_cama_utilizados (%) > dias_cama_disponibles (%)',
            NEW.dias_cama_utilizados, NEW.dias_cama_disponibles;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_sesion_rehab_profesion(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_sesion_rehab_profesion() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_profesion TEXT;
BEGIN
    IF NEW.provider_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT profesion INTO v_profesion
    FROM profesional
    WHERE provider_id = NEW.provider_id;

    IF NEW.tipo IN ('kinesiologia_respiratoria', 'kinesiologia_motora')
       AND v_profesion IS DISTINCT FROM 'KINESIOLOGIA' THEN
        RAISE EXCEPTION 'Sesión tipo % requires KINESIOLOGIA, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    IF NEW.tipo = 'terapia_ocupacional'
       AND v_profesion IS DISTINCT FROM 'TERAPIA_OCUPACIONAL' THEN
        RAISE EXCEPTION 'Sesión tipo % requires TERAPIA_OCUPACIONAL, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    IF NEW.tipo = 'fonoaudiologia'
       AND v_profesion IS DISTINCT FROM 'FONOAUDIOLOGIA' THEN
        RAISE EXCEPTION 'Sesión tipo % requires FONOAUDIOLOGIA, provider has %',
            NEW.tipo, v_profesion;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_stay_coherence(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_stay_coherence() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_visit_stay_id TEXT;
BEGIN
    IF NEW.visit_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT stay_id INTO v_visit_stay_id
    FROM visita
    WHERE visit_id = NEW.visit_id;

    IF v_visit_stay_id IS NULL THEN
        RAISE EXCEPTION 'Stay coherence: visit_id % not found', NEW.visit_id;
    END IF;

    IF NEW.stay_id IS DISTINCT FROM v_visit_stay_id THEN
        RAISE EXCEPTION 'Stay coherence: stay_id mismatch — record has %, visit has %',
            NEW.stay_id, v_visit_stay_id;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_telemetria_ruta_coherence(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_telemetria_ruta_coherence() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_ruta_fecha DATE;
BEGIN
    IF NEW.route_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT fecha INTO v_ruta_fecha
    FROM ruta
    WHERE route_id = NEW.route_id;

    IF v_ruta_fecha IS NULL THEN
        RAISE EXCEPTION 'Telemetría resumen references non-existent route_id %', NEW.route_id;
    END IF;

    IF NEW.fecha != v_ruta_fecha THEN
        RAISE EXCEPTION 'Telemetría resumen fecha (%) does not match ruta fecha (%)',
            NEW.fecha, v_ruta_fecha;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_telemetria_visita_coherence(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_telemetria_visita_coherence() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_visita_fecha DATE;
BEGIN
    IF NEW.visit_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT fecha INTO v_visita_fecha
    FROM visita
    WHERE visit_id = NEW.visit_id;

    IF v_visita_fecha IS NULL THEN
        RAISE EXCEPTION 'Telemetría segmento references non-existent visit_id %', NEW.visit_id;
    END IF;

    -- Compare dates using ::date cast for TIMESTAMPTZ columns
    IF NEW.start_at::date != v_visita_fecha THEN
        RAISE EXCEPTION 'Telemetría segmento start_at date (%) does not match visita fecha (%)',
            NEW.start_at::date, v_visita_fecha;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_visita_rango_temporal(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_visita_rango_temporal() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_fecha_ingreso DATE;
    v_fecha_egreso  DATE;
BEGIN
    SELECT fecha_ingreso, fecha_egreso INTO v_fecha_ingreso, v_fecha_egreso
    FROM estadia
    WHERE stay_id = NEW.stay_id;

    IF NEW.fecha < v_fecha_ingreso THEN
        RAISE EXCEPTION 'Visita fecha (%) is before estadia fecha_ingreso (%)',
            NEW.fecha, v_fecha_ingreso;
    END IF;

    IF v_fecha_egreso IS NOT NULL AND NEW.fecha > v_fecha_egreso THEN
        RAISE EXCEPTION 'Visita fecha (%) is after estadia fecha_egreso (%)',
            NEW.fecha, v_fecha_egreso;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_visita_ruta_provider(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_visita_ruta_provider() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
DECLARE
    v_ruta_provider TEXT;
BEGIN
    IF NEW.route_id IS NULL OR NEW.provider_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT provider_id INTO v_ruta_provider
    FROM ruta
    WHERE route_id = NEW.route_id;

    IF v_ruta_provider IS NOT NULL AND v_ruta_provider IS DISTINCT FROM NEW.provider_id THEN
        RAISE EXCEPTION 'Visita provider_id (%) does not match ruta provider_id (%)',
            NEW.provider_id, v_ruta_provider;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: check_visita_transition(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.check_visita_transition() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM maquina_estados_ref
        WHERE from_state = NEW.estado_previo
          AND to_state   = NEW.estado_nuevo
    ) THEN
        RAISE EXCEPTION 'Invalid visita transition: % → %',
            NEW.estado_previo, NEW.estado_nuevo;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_estadia_estado(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.guard_estadia_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    -- Allow updates from sync triggers (depth > 0) but block direct updates
    IF pg_trigger_depth() <= 1 AND OLD.estado IS DISTINCT FROM NEW.estado THEN
        RAISE EXCEPTION 'Direct estado update on estadia is forbidden. Use evento_estadia.';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_estadia_estado_insert(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.guard_estadia_estado_insert() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NEW.estado IS DISTINCT FROM 'pendiente_evaluacion' THEN
        RAISE EXCEPTION 'FIX-5: New estadia must start as pendiente_evaluacion, got %', NEW.estado;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_visita_estado(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.guard_visita_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    -- Allow updates from sync triggers (depth > 0) but block direct updates
    IF pg_trigger_depth() <= 1 AND OLD.estado IS DISTINCT FROM NEW.estado THEN
        RAISE EXCEPTION 'Direct estado update on visita is forbidden. Use evento_visita.';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_visita_estado_insert(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.guard_visita_estado_insert() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NEW.estado IS NOT NULL AND NEW.estado != 'PROGRAMADA' THEN
        RAISE EXCEPTION 'FIX-5: New visita must start as NULL or PROGRAMADA, got %', NEW.estado;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: refresh_hodom_mvs(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.refresh_hodom_mvs() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_rem_personas_atendidas;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_kpi_diario;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_telemetria_kpi_diario;
END;
$$;


--
-- Name: FUNCTION refresh_hodom_mvs(); Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON FUNCTION reference.refresh_hodom_mvs() IS 'Refresh all HODOM materialized views. Call after data changes or on a cron schedule.';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION set_updated_at(); Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON FUNCTION reference.set_updated_at() IS 'Auto-update trigger: sets updated_at = NOW() on every UPDATE.';


--
-- Name: sync_estadia_estado(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.sync_estadia_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    UPDATE estadia SET estado = NEW.estado_nuevo, updated_at = NOW()
    WHERE stay_id = NEW.stay_id;
    RETURN NEW;
END;
$$;


--
-- Name: sync_paciente_estado(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.sync_paciente_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    IF NEW.estado = 'activo' THEN
        UPDATE paciente SET estado_actual = 'activo', updated_at = NOW()
        WHERE patient_id = NEW.patient_id;
    ELSIF NEW.estado IN ('egresado', 'fallecido') THEN
        UPDATE paciente SET
            estado_actual = CASE
                WHEN NEW.estado = 'fallecido' THEN 'fallecido'
                WHEN EXISTS (
                    SELECT 1 FROM estadia
                    WHERE patient_id = NEW.patient_id
                      AND estado = 'activo'
                      AND stay_id != NEW.stay_id
                ) THEN 'activo'
                ELSE 'egresado'
            END,
            updated_at = NOW()
        WHERE patient_id = NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: sync_visita_estado(); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.sync_visita_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'reference', 'territorial', 'clinical', 'operational', 'reporting', 'telemetry'
    AS $$
BEGIN
    UPDATE visita SET estado = NEW.estado_nuevo, updated_at = NOW()
    WHERE visit_id = NEW.visit_id;
    RETURN NEW;
END;
$$;


--
-- Name: fn_ocupacion_dia(date); Type: FUNCTION; Schema: reporting; Owner: -
--

CREATE FUNCTION reporting.fn_ocupacion_dia(p_fecha date) RETURNS TABLE(fecha date, camas_ocupadas bigint, cupos_programados integer, porcentaje_ocupacion numeric)
    LANGUAGE plpgsql STABLE
    AS $$
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
            (SELECT cp.valor::INT FROM operational.configuracion_programa cp WHERE cp.clave = 'programa.cupos_programados' LIMIT 1),
            25
        )::INT,
        ROUND(
            (SELECT count(*) FROM clinical.estadia e
             WHERE e.fecha_ingreso <= p_fecha
               AND (e.fecha_egreso IS NULL OR e.fecha_egreso >= p_fecha)
               AND e.estado IN ('activo','admitido')
            )::NUMERIC /
            GREATEST(COALESCE(
                (SELECT cp.valor::INT FROM operational.configuracion_programa cp WHERE cp.clave = 'programa.cupos_programados' LIMIT 1),
                25
            ), 1) * 100,
        1)
    ;
END;
$$;


--
-- Name: fn_rem_origen_derivacion(text); Type: FUNCTION; Schema: reporting; Owner: -
--

CREATE FUNCTION reporting.fn_rem_origen_derivacion(p_periodo text) RETURNS TABLE(origen text, total bigint)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: FUNCTION fn_rem_origen_derivacion(p_periodo text); Type: COMMENT; Schema: reporting; Owner: -
--

COMMENT ON FUNCTION reporting.fn_rem_origen_derivacion(p_periodo text) IS 'REM A21 C.1.1 desglose — Origen de derivación. Parámetro: YYYY-MM';


--
-- Name: fn_rem_personas_atendidas(text); Type: FUNCTION; Schema: reporting; Owner: -
--

CREATE FUNCTION reporting.fn_rem_personas_atendidas(p_periodo text) RETURNS TABLE(componente text, total bigint, menores_15 bigint, rango_15_19 bigint, mayores_20 bigint, sexo_masculino bigint, sexo_femenino bigint)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: FUNCTION fn_rem_personas_atendidas(p_periodo text); Type: COMMENT; Schema: reporting; Owner: -
--

COMMENT ON FUNCTION reporting.fn_rem_personas_atendidas(p_periodo text) IS 'REM A21 C.1.1 — Personas atendidas. Parámetro: YYYY-MM';


--
-- Name: fn_rem_visitas(text); Type: FUNCTION; Schema: reporting; Owner: -
--

CREATE FUNCTION reporting.fn_rem_visitas(p_periodo text) RETURNS TABLE(profesion_rem text, total_visitas bigint)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: FUNCTION fn_rem_visitas(p_periodo text); Type: COMMENT; Schema: reporting; Owner: -
--

COMMENT ON FUNCTION reporting.fn_rem_visitas(p_periodo text) IS 'REM A21 C.1.2 — Visitas por profesión. Parámetro: YYYY-MM';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alerta; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.alerta (
    alerta_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    categoria text,
    codigo text,
    estado text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT alerta_categoria_check CHECK ((categoria = ANY (ARRAY['clinica'::text, 'administrativa'::text, 'urgencia'::text, 'seguimiento'::text]))),
    CONSTRAINT alerta_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['activa'::text, 'resuelta'::text, 'ignorada'::text]))))
);


--
-- Name: botiquin_domiciliario; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.botiquin_domiciliario (
    botiquin_item_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text NOT NULL,
    medicamento text NOT NULL,
    forma_farmaceutica text,
    cantidad_actual text,
    fecha_vencimiento date,
    condicion_almacenamiento text,
    requiere_devolucion boolean DEFAULT false,
    estado text DEFAULT 'activo'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT botiquin_domiciliario_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'agotado'::text, 'devuelto'::text, 'descartado'::text])))
);


--
-- Name: chat_mensaje; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.chat_mensaje (
    chat_mensaje_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    sender_type text NOT NULL,
    sender_id text NOT NULL,
    sender_nombre text NOT NULL,
    contenido text NOT NULL,
    sesion_id text,
    leido_at timestamp with time zone,
    leido_por text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chat_mensaje_sender_type_check CHECK ((sender_type = ANY (ARRAY['profesional'::text, 'portal'::text])))
);


--
-- Name: checklist_ingreso; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.checklist_ingreso (
    checklist_item_id text NOT NULL,
    stay_id text NOT NULL,
    item text NOT NULL,
    cumplido text NOT NULL,
    observacion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT checklist_ingreso_cumplido_check CHECK ((cumplido = ANY (ARRAY['si'::text, 'no'::text, 'na'::text]))),
    CONSTRAINT checklist_ingreso_item_check CHECK ((item = ANY (ARRAY['firma_consentimiento_informado'::text, 'bienvenida_educacion_hodom'::text, 'familiar_responsable_presente'::text, 'interconsultas_horas_pendientes'::text, 'medicamentos_despachados'::text, 'portador_elementos_invasivos'::text, 'lesiones_en_piel'::text, 'tratamientos_indicados'::text])))
);


--
-- Name: condicion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.condicion (
    condition_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text,
    codigo_cie10 text,
    descripcion text,
    estado_clinico text,
    verificacion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT condicion_estado_clinico_check CHECK ((estado_clinico = ANY (ARRAY['activo'::text, 'resuelto'::text, 'controlado'::text, 'cronico'::text, 'en_tratamiento'::text]))),
    CONSTRAINT condicion_verificacion_check CHECK (((verificacion IS NULL) OR (verificacion = ANY (ARRAY['verificado'::text, 'pendiente'::text, 'descartado'::text]))))
);


--
-- Name: consentimiento; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.consentimiento (
    consent_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    tipo text NOT NULL,
    decision text NOT NULL,
    fecha date NOT NULL,
    firmante_nombre text,
    firmante_rut text,
    firmante_parentesco text,
    provider_id text,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT consentimiento_decision_check CHECK ((decision = ANY (ARRAY['aceptado'::text, 'rechazado'::text]))),
    CONSTRAINT consentimiento_tipo_check CHECK ((tipo = ANY (ARRAY['hospitalizacion_domiciliaria'::text, 'procedimiento'::text, 'retiro_voluntario'::text, 'registro_audiovisual'::text])))
);


--
-- Name: cuidador; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.cuidador (
    cuidador_id text NOT NULL,
    patient_id text NOT NULL,
    nombre text,
    parentesco text NOT NULL,
    contacto text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: derivacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.derivacion (
    derivacion_id text NOT NULL,
    stay_id text,
    patient_id text,
    tipo text NOT NULL,
    fecha date NOT NULL,
    establecimiento_origen text,
    servicio_origen text,
    profesional_origen text,
    establecimiento_destino text,
    servicio_destino text,
    profesional_destino text,
    diagnostico text,
    motivo text NOT NULL,
    resumen_clinico text,
    indicaciones text,
    examenes_pendientes text,
    medicamentos_actuales text,
    estado text DEFAULT 'emitida'::text,
    fecha_recepcion date,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    provider_id text,
    token_seguimiento text,
    email_derivador text,
    profesional_derivador text,
    profesion_derivador text,
    telefono_derivador text,
    nombre_candidato text,
    rut_candidato text,
    edad_candidato integer,
    sexo_candidato text,
    diagnostico_principal text,
    origen_derivacion text,
    observaciones text,
    red_apoyo text,
    cuidador_principal text,
    condiciones_vivienda text,
    motivo_rechazo text,
    CONSTRAINT derivacion_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'emitida'::text, 'recibida'::text, 'aceptada'::text, 'rechazada'::text]))),
    CONSTRAINT derivacion_tipo_check CHECK ((tipo = ANY (ARRAY['derivacion_ingreso'::text, 'contrarreferencia_egreso'::text, 'derivacion_interna'::text])))
);


--
-- Name: derivacion_adjunto; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.derivacion_adjunto (
    adjunto_id text NOT NULL,
    derivacion_id text NOT NULL,
    nombre_archivo text NOT NULL,
    tipo_archivo text NOT NULL,
    tamano_bytes integer NOT NULL,
    ruta_almacenamiento text NOT NULL,
    descripcion text,
    uploaded_by text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: diagnostico_egreso; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.diagnostico_egreso (
    diag_id text NOT NULL,
    epicrisis_id text NOT NULL,
    tipo text NOT NULL,
    codigo_cie10 text,
    descripcion text NOT NULL,
    codigo_snomed text,
    orden integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT diagnostico_egreso_tipo_check CHECK ((tipo = ANY (ARRAY['principal'::text, 'secundario'::text, 'complicacion'::text])))
);


--
-- Name: dispensacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.dispensacion (
    dispensacion_id text NOT NULL,
    receta_id text,
    patient_id text NOT NULL,
    stay_id text NOT NULL,
    fecha date NOT NULL,
    medicamento text NOT NULL,
    cantidad_dispensada text,
    lote text,
    fecha_vencimiento date,
    dispensador text,
    receptor text,
    receptor_parentesco text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: dispositivo; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.dispositivo (
    device_id text NOT NULL,
    patient_id text NOT NULL,
    tipo text,
    estado text,
    serial text,
    asignado_desde date,
    asignado_hasta date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT dispositivo_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'averiado'::text, 'devuelto'::text, 'extraviado'::text]))),
    CONSTRAINT dispositivo_tipo_check CHECK (((tipo IS NULL) OR (tipo = ANY (ARRAY['VVP'::text, 'SNG'::text, 'CUP'::text, 'DRENAJE'::text, 'CONCENTRADOR_O2'::text, 'BOMBA_IV'::text, 'MONITOR'::text, 'GLUCOMETRO'::text, 'OTRO'::text]))))
);


--
-- Name: documentacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.documentacion (
    doc_id text NOT NULL,
    visit_id text,
    stay_id text,
    patient_id text,
    tipo text,
    estado text,
    fecha date,
    ruta_archivo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    firma_hash text,
    firmante_id text,
    firmante_nombre text,
    fecha_firma timestamp with time zone,
    CONSTRAINT documentacion_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['pendiente'::text, 'completo'::text, 'verificado'::text]))))
);


--
-- Name: domicilio; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.domicilio (
    domicilio_id text NOT NULL,
    patient_id text NOT NULL,
    localizacion_id text NOT NULL,
    tipo text NOT NULL,
    vigente_desde date NOT NULL,
    vigente_hasta date,
    contacto_local text,
    notas text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT domicilio_tipo_check CHECK ((tipo = ANY (ARRAY['principal'::text, 'alternativo'::text, 'temporal'::text, 'eleam'::text])))
);


--
-- Name: TABLE domicilio; Type: COMMENT; Schema: clinical; Owner: -
--

COMMENT ON TABLE clinical.domicilio IS 'Morph pi: Dom -> (Pac x Loc). Binding temporal con exclusion PE4.';


--
-- Name: educacion_paciente; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.educacion_paciente (
    educacion_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    visit_id text,
    fecha date NOT NULL,
    tema text NOT NULL,
    descripcion text,
    material_entregado text,
    receptor text,
    comprension text,
    requiere_refuerzo boolean DEFAULT false,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT educacion_paciente_comprension_check CHECK (((comprension IS NULL) OR (comprension = ANY (ARRAY['adecuada'::text, 'parcial'::text, 'insuficiente'::text, 'no_evaluada'::text])))),
    CONSTRAINT educacion_paciente_receptor_check CHECK ((receptor = ANY (ARRAY['paciente'::text, 'cuidador'::text, 'ambos'::text])))
);


--
-- Name: encuesta_satisfaccion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.encuesta_satisfaccion (
    encuesta_id text NOT NULL,
    patient_id text,
    stay_id text,
    marca_temporal timestamp with time zone,
    encuestado_nombre text,
    encuestado_parentesco text,
    fecha_encuesta date,
    satisfaccion_ingreso integer,
    satisfaccion_equipo_general integer,
    satisfaccion_oportunidad integer,
    satisfaccion_informacion integer,
    satisfaccion_trato integer,
    satisfaccion_unidad integer,
    educacion_enfermera integer,
    educacion_kinesiologo integer,
    educacion_fonoaudiologo integer,
    valoracion_mejoria text,
    asistencia_telefonica boolean,
    volveria text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT encuesta_satisfaccion_valoracion_mejoria_check CHECK (((valoracion_mejoria IS NULL) OR (valoracion_mejoria = ANY (ARRAY['TOTALMENTE'::text, 'ALGO'::text, 'NADA'::text])))),
    CONSTRAINT encuesta_satisfaccion_volveria_check CHECK (((volveria IS NULL) OR (volveria = ANY (ARRAY['si'::text, 'probablemente_si'::text, 'probablemente_no'::text, 'no'::text]))))
);


--
-- Name: epicrisis; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.epicrisis (
    epicrisis_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha_emision date NOT NULL,
    fecha_ingreso date,
    fecha_egreso date,
    tipo_egreso text,
    servicio_origen text,
    motivo_ingreso text,
    diagnostico_ingreso text,
    anamnesis_resumen text,
    examen_fisico_ingreso text,
    examenes_realizados text,
    resumen_evolucion text NOT NULL,
    tratamiento_realizado text,
    complicaciones text,
    condicion_egreso text,
    indicaciones_alta text,
    medicamentos_alta text,
    dieta_alta text,
    actividad_alta text,
    cuidados_especiales text,
    signos_alarma text,
    proximo_control text,
    derivacion_aps text,
    interconsultas_pendientes text,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT epicrisis_condicion_egreso_check CHECK (((condicion_egreso IS NULL) OR (condicion_egreso = ANY (ARRAY['mejorado'::text, 'estable'::text, 'sin_cambios'::text, 'deteriorado'::text, 'fallecido'::text])))),
    CONSTRAINT epicrisis_tipo_egreso_check CHECK ((tipo_egreso = ANY (ARRAY['alta_clinica'::text, 'fallecido_esperado'::text, 'fallecido_no_esperado'::text, 'reingreso'::text, 'renuncia_voluntaria'::text, 'alta_disciplinaria'::text])))
);


--
-- Name: TABLE epicrisis; Type: COMMENT; Schema: clinical; Owner: -
--

COMMENT ON TABLE clinical.epicrisis IS 'Epicrisis por estadia. Relacion M:1 (hasta 8 por estadia). Discriminante: epicrisis_id prefix — epi_ = enfermeria (DOCX via CORR-12), em_ = medica (PDF via CORR-16). Hay 10 estadias con epicrisis enfermeria duplicadas (DOCX duplicados en drive). Multiples medicas son normales (reingresos, egreso DAU vs SGH).';


--
-- Name: equipo_medico; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.equipo_medico (
    equipo_id text NOT NULL,
    tipo text NOT NULL,
    marca text,
    modelo text,
    serial text,
    numero_inventario text,
    fecha_adquisicion date,
    proveedor text,
    estado text DEFAULT 'disponible'::text,
    ubicacion_actual text,
    proxima_mantencion date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT equipo_medico_estado_check CHECK ((estado = ANY (ARRAY['disponible'::text, 'prestado'::text, 'en_mantencion'::text, 'de_baja'::text, 'extraviado'::text]))),
    CONSTRAINT equipo_medico_tipo_check CHECK ((tipo = ANY (ARRAY['cama_clinica'::text, 'colchon_antiescaras'::text, 'concentrador_o2'::text, 'balon_o2'::text, 'bomba_infusion'::text, 'aspirador_secreciones'::text, 'nebulizador'::text, 'oximetro'::text, 'glucometro'::text, 'tensiometro'::text, 'monitor_signos'::text, 'silla_ruedas'::text, 'andador'::text, 'baston'::text, 'mesa_comer_cama'::text, 'porta_suero'::text, 'otro'::text])))
);


--
-- Name: estadia; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.estadia (
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    establecimiento_id text,
    fecha_ingreso date NOT NULL,
    fecha_egreso date,
    estado text DEFAULT 'pendiente_evaluacion'::text,
    tipo_egreso text,
    origen_derivacion text,
    diagnostico_principal text,
    condicion_domicilio text,
    confidence_level text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT estadia_check CHECK (((fecha_egreso IS NULL) OR (fecha_egreso >= fecha_ingreso))),
    CONSTRAINT estadia_condicion_domicilio_check CHECK (((condicion_domicilio IS NULL) OR (condicion_domicilio = ANY (ARRAY['adecuada'::text, 'inadecuada'::text])))),
    CONSTRAINT estadia_estado_check CHECK ((estado = ANY (ARRAY['pendiente_evaluacion'::text, 'elegible'::text, 'admitido'::text, 'activo'::text, 'egresado'::text, 'fallecido'::text]))),
    CONSTRAINT estadia_origen_derivacion_check CHECK (((origen_derivacion IS NULL) OR (origen_derivacion = ANY (ARRAY['APS'::text, 'urgencia'::text, 'hospitalizacion'::text, 'ambulatorio'::text, 'ley_urgencia'::text, 'UGCC'::text])))),
    CONSTRAINT estadia_tipo_egreso_check CHECK (((tipo_egreso IS NULL) OR (tipo_egreso = ANY (ARRAY['alta_clinica'::text, 'fallecido_esperado'::text, 'fallecido_no_esperado'::text, 'reingreso'::text, 'renuncia_voluntaria'::text, 'alta_disciplinaria'::text]))))
);


--
-- Name: evaluacion_funcional; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.evaluacion_funcional (
    eval_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    momento text NOT NULL,
    fecha date NOT NULL,
    barthel_score integer,
    barthel_categoria text,
    dependencia_motora text,
    dependencia_respiratoria text,
    hito_motor text,
    df_score text,
    autocuidado text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    braden_score integer,
    braden_categoria text,
    braden_percepcion_sensorial integer,
    braden_humedad integer,
    braden_actividad integer,
    braden_movilidad integer,
    braden_nutricion integer,
    braden_friccion integer,
    barthel_alimentacion integer,
    barthel_bano integer,
    barthel_vestido integer,
    barthel_aseo integer,
    barthel_deposiciones integer,
    barthel_miccion integer,
    barthel_retrete integer,
    barthel_traslado integer,
    barthel_deambulacion integer,
    barthel_escaleras integer,
    CONSTRAINT braden_actividad_check CHECK (((braden_actividad IS NULL) OR ((braden_actividad >= 1) AND (braden_actividad <= 4)))),
    CONSTRAINT braden_friccion_check CHECK (((braden_friccion IS NULL) OR ((braden_friccion >= 1) AND (braden_friccion <= 3)))),
    CONSTRAINT braden_humedad_check CHECK (((braden_humedad IS NULL) OR ((braden_humedad >= 1) AND (braden_humedad <= 4)))),
    CONSTRAINT braden_movilidad_check CHECK (((braden_movilidad IS NULL) OR ((braden_movilidad >= 1) AND (braden_movilidad <= 4)))),
    CONSTRAINT braden_nutricion_check CHECK (((braden_nutricion IS NULL) OR ((braden_nutricion >= 1) AND (braden_nutricion <= 4)))),
    CONSTRAINT braden_percepcion_check CHECK (((braden_percepcion_sensorial IS NULL) OR ((braden_percepcion_sensorial >= 1) AND (braden_percepcion_sensorial <= 4)))),
    CONSTRAINT eval_func_dep_motora_check CHECK (((dependencia_motora IS NULL) OR (dependencia_motora = ANY (ARRAY['total'::text, 'severa'::text, 'moderada'::text, 'leve'::text, 'independiente'::text])))),
    CONSTRAINT eval_func_dep_resp_check CHECK (((dependencia_respiratoria IS NULL) OR (dependencia_respiratoria = ANY (ARRAY['total'::text, 'severa'::text, 'moderada'::text, 'leve'::text, 'independiente'::text])))),
    CONSTRAINT evaluacion_funcional_autocuidado_check CHECK (((autocuidado IS NULL) OR (autocuidado = ANY (ARRAY['autovalente'::text, 'semidependiente'::text, 'postrado'::text])))),
    CONSTRAINT evaluacion_funcional_barthel_categoria_check CHECK (((barthel_categoria IS NULL) OR (barthel_categoria = ANY (ARRAY['independiente'::text, 'leve'::text, 'moderada'::text, 'severa'::text, 'total'::text])))),
    CONSTRAINT evaluacion_funcional_barthel_score_check CHECK (((barthel_score IS NULL) OR ((barthel_score >= 0) AND (barthel_score <= 100)))),
    CONSTRAINT evaluacion_funcional_braden_categoria_check CHECK (((braden_categoria IS NULL) OR (braden_categoria = ANY (ARRAY['muy_alto'::text, 'alto'::text, 'moderado'::text, 'leve'::text, 'sin_riesgo'::text])))),
    CONSTRAINT evaluacion_funcional_braden_score_check CHECK (((braden_score IS NULL) OR ((braden_score >= 6) AND (braden_score <= 23)))),
    CONSTRAINT evaluacion_funcional_hito_motor_check CHECK (((hito_motor IS NULL) OR (hito_motor = ANY (ARRAY['cama'::text, 'sedente_en_cama'::text, 'sedente_borde_cama'::text, 'sedente_en_silla'::text, 'bipedo'::text, 'marcha_estatica'::text, 'marcha_dinamica'::text])))),
    CONSTRAINT evaluacion_funcional_momento_check CHECK ((momento = ANY (ARRAY['ingreso'::text, 'semanal'::text, 'egreso'::text, 'seguimiento'::text])))
);


--
-- Name: evaluacion_paliativa; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.evaluacion_paliativa (
    eval_paliativa_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha date NOT NULL,
    esas_dolor integer,
    esas_fatiga integer,
    esas_nausea integer,
    esas_depresion integer,
    esas_ansiedad integer,
    esas_somnolencia integer,
    esas_apetito integer,
    esas_disnea integer,
    esas_bienestar integer,
    esas_total integer,
    karnofsky_score integer,
    pps_score integer,
    intencion_paliativa boolean DEFAULT false,
    sedacion_paliativa boolean DEFAULT false,
    plan_paliativo text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT evaluacion_paliativa_esas_ansiedad_check CHECK (((esas_ansiedad IS NULL) OR ((esas_ansiedad >= 0) AND (esas_ansiedad <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_apetito_check CHECK (((esas_apetito IS NULL) OR ((esas_apetito >= 0) AND (esas_apetito <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_bienestar_check CHECK (((esas_bienestar IS NULL) OR ((esas_bienestar >= 0) AND (esas_bienestar <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_depresion_check CHECK (((esas_depresion IS NULL) OR ((esas_depresion >= 0) AND (esas_depresion <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_disnea_check CHECK (((esas_disnea IS NULL) OR ((esas_disnea >= 0) AND (esas_disnea <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_dolor_check CHECK (((esas_dolor IS NULL) OR ((esas_dolor >= 0) AND (esas_dolor <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_fatiga_check CHECK (((esas_fatiga IS NULL) OR ((esas_fatiga >= 0) AND (esas_fatiga <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_nausea_check CHECK (((esas_nausea IS NULL) OR ((esas_nausea >= 0) AND (esas_nausea <= 10)))),
    CONSTRAINT evaluacion_paliativa_esas_somnolencia_check CHECK (((esas_somnolencia IS NULL) OR ((esas_somnolencia >= 0) AND (esas_somnolencia <= 10)))),
    CONSTRAINT evaluacion_paliativa_karnofsky_score_check CHECK (((karnofsky_score IS NULL) OR ((karnofsky_score >= 0) AND (karnofsky_score <= 100)))),
    CONSTRAINT evaluacion_paliativa_pps_score_check CHECK (((pps_score IS NULL) OR ((pps_score >= 0) AND (pps_score <= 100))))
);


--
-- Name: evento_adverso; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.evento_adverso (
    evento_id text NOT NULL,
    patient_id text,
    stay_id text,
    visit_id text,
    tipo text NOT NULL,
    severidad text NOT NULL,
    fecha_evento date NOT NULL,
    hora_evento text,
    lugar text,
    descripcion text NOT NULL,
    circunstancias text,
    detectado_por_id text,
    fecha_reporte date NOT NULL,
    accion_inmediata text,
    requirio_traslado boolean DEFAULT false,
    causa_raiz text,
    acciones_correctivas text,
    estado text DEFAULT 'reportado'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT evento_adverso_estado_check CHECK ((estado = ANY (ARRAY['reportado'::text, 'en_investigacion'::text, 'cerrado'::text]))),
    CONSTRAINT evento_adverso_severidad_check CHECK ((severidad = ANY (ARRAY['sin_daño'::text, 'leve'::text, 'moderado'::text, 'grave'::text, 'muerte'::text])))
);


--
-- Name: fotografia_clinica; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.fotografia_clinica (
    foto_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    herida_id text,
    provider_id text,
    fecha date NOT NULL,
    tipo text NOT NULL,
    descripcion text,
    ruta_almacenamiento text NOT NULL,
    tamano_bytes integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fotografia_clinica_tipo_check CHECK ((tipo = ANY (ARRAY['herida'::text, 'evolucion'::text, 'dispositivo'::text, 'otro'::text])))
);


--
-- Name: garantia_ges; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.garantia_ges (
    ges_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    numero_problema_ges integer,
    nombre_problema text NOT NULL,
    codigo_cie10 text,
    fecha_sospecha date,
    fecha_confirmacion date,
    fecha_garantia_acceso date,
    fecha_atencion date,
    estado text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT garantia_ges_estado_check CHECK ((estado = ANY (ARRAY['sospecha'::text, 'confirmado'::text, 'en_tratamiento'::text, 'alta_ges'::text, 'incumplimiento_garantia'::text])))
);


--
-- Name: herida; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.herida (
    herida_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text NOT NULL,
    tipo_herida text NOT NULL,
    ubicacion text,
    grado text,
    fecha_inicio date,
    fecha_cierre date,
    estado text DEFAULT 'activa'::text,
    tipo_curacion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT herida_check CHECK (((fecha_cierre IS NULL) OR (fecha_cierre >= fecha_inicio))),
    CONSTRAINT herida_estado_check CHECK ((estado = ANY (ARRAY['activa'::text, 'en_cicatrizacion'::text, 'cerrada'::text, 'infectada'::text]))),
    CONSTRAINT herida_grado_check CHECK (((grado IS NULL) OR (grado = ANY (ARRAY['1'::text, '2'::text, '3'::text, '4'::text, 'no_clasificable'::text, 'sospecha_profunda'::text])))),
    CONSTRAINT herida_tipo_herida_check CHECK ((tipo_herida = ANY (ARRAY['lpp'::text, 'pie_diabetico'::text, 'herida_operatoria'::text, 'ulcera_venosa'::text, 'ulcera_arterial'::text, 'quemadura'::text, 'otra'::text])))
);


--
-- Name: indicacion_medica; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.indicacion_medica (
    indicacion_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha date NOT NULL,
    hora text,
    tipo text NOT NULL,
    descripcion text NOT NULL,
    medicamento text,
    dosis text,
    via text,
    frecuencia text,
    dilucion text,
    duracion text,
    o2_flujo_lpm real,
    o2_dispositivo text,
    o2_horas_dia real,
    estado text DEFAULT 'activa'::text,
    fecha_suspension date,
    motivo_suspension text,
    indicacion_previa_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT indicacion_medica_estado_check CHECK ((estado = ANY (ARRAY['activa'::text, 'suspendida'::text, 'completada'::text, 'modificada'::text]))),
    CONSTRAINT indicacion_medica_o2_dispositivo_check CHECK (((o2_dispositivo IS NULL) OR (o2_dispositivo = ANY (ARRAY['naricera'::text, 'mascarilla_venturi'::text, 'mascarilla_alto_flujo'::text, 'concentrador'::text, 'balon'::text])))),
    CONSTRAINT indicacion_medica_tipo_check CHECK ((tipo = ANY (ARRAY['farmacologica'::text, 'dieta'::text, 'actividad'::text, 'oxigenoterapia'::text, 'curacion'::text, 'monitorizacion'::text, 'interconsulta'::text, 'examen'::text, 'procedimiento'::text, 'otra'::text]))),
    CONSTRAINT indicacion_medica_via_check CHECK (((via IS NULL) OR (via = ANY (ARRAY['oral'::text, 'IV'::text, 'SC'::text, 'IM'::text, 'topica'::text, 'inhalatoria'::text, 'SNG'::text, 'rectal'::text]))))
);


--
-- Name: informe_social; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.informe_social (
    informe_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    tipo text NOT NULL,
    fecha date NOT NULL,
    n_integrantes_hogar integer,
    composicion_familiar text,
    cuidador_principal text,
    cuidador_parentesco text,
    red_apoyo_familiar text,
    red_apoyo_comunitaria text,
    tipo_vivienda text,
    tenencia_vivienda text,
    servicios_basicos text,
    condiciones_sanitarias text,
    accesibilidad text,
    rsh_tramo text,
    prevision_social text,
    ingresos_hogar text,
    problematica_social text,
    diagnostico_social text,
    plan_intervencion text,
    derivaciones text,
    observaciones text,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT informe_red_comunitaria_check CHECK (((red_apoyo_comunitaria IS NULL) OR (red_apoyo_comunitaria = ANY (ARRAY['fuerte'::text, 'moderada'::text, 'debil'::text, 'ausente'::text])))),
    CONSTRAINT informe_red_familiar_check CHECK (((red_apoyo_familiar IS NULL) OR (red_apoyo_familiar = ANY (ARRAY['fuerte'::text, 'moderada'::text, 'debil'::text, 'ausente'::text])))),
    CONSTRAINT informe_social_rsh_tramo_check CHECK (((rsh_tramo IS NULL) OR (rsh_tramo = ANY (ARRAY['0-40'::text, '41-50'::text, '51-60'::text, '61-70'::text, '71-80'::text, '81-90'::text, '91-100'::text, 'sin_calificacion'::text])))),
    CONSTRAINT informe_social_tenencia_vivienda_check CHECK (((tenencia_vivienda IS NULL) OR (tenencia_vivienda = ANY (ARRAY['propia'::text, 'arrendada'::text, 'cedida'::text, 'allegado'::text, 'otro'::text])))),
    CONSTRAINT informe_social_tipo_check CHECK ((tipo = ANY (ARRAY['preliminar'::text, 'completo'::text]))),
    CONSTRAINT informe_social_tipo_vivienda_check CHECK (((tipo_vivienda IS NULL) OR (tipo_vivienda = ANY (ARRAY['casa'::text, 'departamento'::text, 'pieza'::text, 'mediagua'::text, 'vivienda_social'::text, 'otro'::text]))))
);


--
-- Name: interconsulta; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.interconsulta (
    interconsulta_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    solicitante_id text,
    fecha_solicitud date NOT NULL,
    prioridad text,
    especialidad_destino text NOT NULL,
    establecimiento_destino text,
    motivo text NOT NULL,
    diagnostico_actual text,
    antecedentes_relevantes text,
    pregunta_clinica text,
    examenes_adjuntos text,
    fecha_respuesta date,
    respondedor text,
    respuesta text,
    recomendaciones text,
    estado text DEFAULT 'solicitada'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT interconsulta_estado_check CHECK ((estado = ANY (ARRAY['solicitada'::text, 'aceptada'::text, 'rechazada'::text, 'respondida'::text, 'cancelada'::text])))
);


--
-- Name: lista_espera; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.lista_espera (
    espera_id text NOT NULL,
    patient_id text NOT NULL,
    fecha_solicitud date NOT NULL,
    establecimiento_origen text,
    servicio_origen text,
    profesional_solicitante text,
    diagnostico text,
    motivo_solicitud text,
    prioridad text DEFAULT 'normal'::text,
    requiere_o2 boolean DEFAULT false,
    requiere_curaciones boolean DEFAULT false,
    fecha_evaluacion date,
    evaluador_id text,
    resultado_evaluacion text,
    motivo_no_elegible text,
    estado text DEFAULT 'en_espera'::text,
    fecha_resolucion date,
    stay_id text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lista_espera_estado_check CHECK ((estado = ANY (ARRAY['en_espera'::text, 'en_evaluacion'::text, 'elegible'::text, 'ingresado'::text, 'rechazado'::text, 'desistido'::text, 'fallecido_espera'::text]))),
    CONSTRAINT lista_espera_resultado_evaluacion_check CHECK (((resultado_evaluacion IS NULL) OR (resultado_evaluacion = ANY (ARRAY['elegible'::text, 'no_elegible'::text, 'pendiente_informacion'::text, 'en_evaluacion'::text]))))
);


--
-- Name: medicacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.medicacion (
    med_id text NOT NULL,
    stay_id text,
    visit_id text,
    medicamento_codigo text,
    medicamento_nombre text,
    via text,
    estado_cadena text,
    dosis text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT medicacion_estado_cadena_check CHECK (((estado_cadena IS NULL) OR (estado_cadena = ANY (ARRAY['prescrita'::text, 'dispensada'::text, 'administrada'::text])))),
    CONSTRAINT medicacion_via_check CHECK (((via IS NULL) OR (via = ANY (ARRAY['oral'::text, 'IV'::text, 'SC'::text, 'IM'::text, 'topica'::text, 'inhalatoria'::text, 'SNG'::text, 'rectal'::text, 'sublingual'::text, 'transdermica'::text]))))
);


--
-- Name: meta; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.meta (
    meta_id text NOT NULL,
    plan_id text NOT NULL,
    descripcion text,
    estado_ciclo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT meta_estado_ciclo_check CHECK (((estado_ciclo IS NULL) OR (estado_ciclo = ANY (ARRAY['propuesta'::text, 'aceptada'::text, 'en_progreso'::text, 'lograda'::text, 'cancelada'::text]))))
);


--
-- Name: necesidad_profesional; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.necesidad_profesional (
    need_id text NOT NULL,
    plan_id text NOT NULL,
    profesion_requerida text,
    nivel_necesidad text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: nota_evolucion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.nota_evolucion (
    nota_id text NOT NULL,
    visit_id text,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    tipo text NOT NULL,
    fecha date NOT NULL,
    hora text,
    notas_clinicas text,
    plan_enfermeria text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT nota_evolucion_tipo_check CHECK ((tipo = ANY (ARRAY['enfermeria'::text, 'kinesiologia'::text, 'fonoaudiologia'::text, 'terapia_ocupacional'::text, 'medica'::text, 'trabajo_social'::text, 'tens'::text])))
);


--
-- Name: notificacion_obligatoria; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.notificacion_obligatoria (
    notificacion_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    tipo text NOT NULL,
    fecha_notificacion date NOT NULL,
    notificador_id text,
    diagnostico text NOT NULL,
    codigo_cie10 text,
    descripcion text,
    notificado_a text,
    numero_formulario text,
    estado text DEFAULT 'notificada'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notificacion_obligatoria_estado_check CHECK ((estado = ANY (ARRAY['notificada'::text, 'confirmada'::text, 'descartada'::text]))),
    CONSTRAINT notificacion_obligatoria_tipo_check CHECK ((tipo = ANY (ARRAY['eno'::text, 'iaas'::text, 'brote'::text, 'ram'::text])))
);


--
-- Name: observacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.observacion (
    obs_id text NOT NULL,
    visit_id text,
    stay_id text,
    patient_id text,
    categoria text,
    codigo text,
    valor text,
    unidad text,
    efectivo_en timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT observacion_categoria_check CHECK ((categoria = ANY (ARRAY['signo_vital'::text, 'laboratorio'::text, 'evaluacion'::text, 'clinica'::text, 'funcional'::text])))
);


--
-- Name: observacion_portal; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.observacion_portal (
    obs_portal_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    usuario_id text NOT NULL,
    tipo text NOT NULL,
    descripcion text NOT NULL,
    severidad text,
    leido_por text,
    leido_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT observacion_portal_severidad_check CHECK ((severidad = ANY (ARRAY['leve'::text, 'moderado'::text, 'severo'::text]))),
    CONSTRAINT observacion_portal_tipo_check CHECK ((tipo = ANY (ARRAY['sintoma'::text, 'observacion'::text, 'preocupacion'::text, 'mejoria'::text])))
);


--
-- Name: oxigenoterapia_domiciliaria; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.oxigenoterapia_domiciliaria (
    oxigeno_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text NOT NULL,
    flujo_lpm real NOT NULL,
    horas_dia real,
    dispositivo text,
    fuente text,
    equipo_id text,
    proveedor_o2 text,
    capacidad_litros real,
    fecha_ultimo_recambio date,
    consumo_estimado_dia real,
    estado text DEFAULT 'activo'::text,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT oxigenoterapia_domiciliaria_dispositivo_check CHECK ((dispositivo = ANY (ARRAY['naricera'::text, 'mascarilla_venturi'::text, 'mascarilla_reservorio'::text, 'mascarilla_alto_flujo'::text, 'canula_traqueostomia'::text]))),
    CONSTRAINT oxigenoterapia_domiciliaria_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'suspendido'::text, 'finalizado'::text]))),
    CONSTRAINT oxigenoterapia_domiciliaria_fuente_check CHECK ((fuente = ANY (ARRAY['concentrador'::text, 'balon_fijo'::text, 'balon_portatil'::text, 'concentrador_portatil'::text, 'oxigeno_liquido'::text])))
);


--
-- Name: paciente; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.paciente (
    patient_id text NOT NULL,
    nombre_completo text NOT NULL,
    rut text,
    sexo text,
    fecha_nacimiento date,
    direccion text,
    comuna text,
    cesfam text,
    prevision text,
    contacto_telefono text,
    estado_actual text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT paciente_estado_actual_check CHECK (((estado_actual IS NULL) OR (estado_actual = ANY (ARRAY['pre_ingreso'::text, 'activo'::text, 'egresado'::text, 'fallecido'::text])))),
    CONSTRAINT paciente_prevision_check CHECK (((prevision IS NULL) OR (prevision = ANY (ARRAY['fonasa-a'::text, 'fonasa-b'::text, 'fonasa-c'::text, 'fonasa-d'::text, 'prais'::text, 'otro'::text])))),
    CONSTRAINT paciente_sexo_check CHECK ((sexo = ANY (ARRAY['masculino'::text, 'femenino'::text])))
);


--
-- Name: plan_cuidado; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.plan_cuidado (
    plan_id text NOT NULL,
    stay_id text NOT NULL,
    estado text DEFAULT 'borrador'::text,
    periodo_inicio date,
    periodo_fin date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT plan_cuidado_check CHECK (((periodo_fin IS NULL) OR (periodo_fin >= periodo_inicio))),
    CONSTRAINT plan_cuidado_estado_check CHECK ((estado = ANY (ARRAY['borrador'::text, 'activo'::text, 'completado'::text])))
);


--
-- Name: plan_ejercicios; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.plan_ejercicios (
    plan_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha date NOT NULL,
    objetivo text,
    ejercicios jsonb DEFAULT '[]'::jsonb NOT NULL,
    frecuencia text,
    precauciones text,
    estado text DEFAULT 'activo'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT plan_ejercicios_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'completado'::text, 'suspendido'::text])))
);


--
-- Name: portal_mensaje; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.portal_mensaje (
    mensaje_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    usuario_id text,
    tipo text NOT NULL,
    asunto text,
    contenido text NOT NULL,
    estado text,
    prioridad text,
    respuesta text,
    respondido_por text,
    respondido_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT portal_mensaje_estado_check CHECK ((estado = ANY (ARRAY['abierto'::text, 'en_proceso'::text, 'resuelto'::text, 'cerrado'::text]))),
    CONSTRAINT portal_mensaje_prioridad_check CHECK ((prioridad = ANY (ARRAY['baja'::text, 'normal'::text, 'urgente'::text]))),
    CONSTRAINT portal_mensaje_tipo_check CHECK ((tipo = ANY (ARRAY['consulta'::text, 'reporte_sintoma'::text, 'reporte_signos'::text, 'solicitud_visita'::text, 'otro'::text])))
);


--
-- Name: prestamo_equipo; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.prestamo_equipo (
    prestamo_id text NOT NULL,
    equipo_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text NOT NULL,
    fecha_entrega date NOT NULL,
    entregado_por text,
    recibido_por text,
    condicion_entrega text,
    fecha_devolucion date,
    devuelto_a text,
    condicion_devolucion text,
    estado text DEFAULT 'prestado'::text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT prestamo_equipo_estado_check CHECK ((estado = ANY (ARRAY['prestado'::text, 'devuelto'::text, 'extraviado'::text, 'dañado'::text])))
);


--
-- Name: procedimiento; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.procedimiento (
    proc_id text NOT NULL,
    visit_id text,
    stay_id text,
    patient_id text,
    codigo text,
    descripcion text,
    estado text,
    realizado_en timestamp with time zone,
    prestacion_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT procedimiento_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['programado'::text, 'realizado'::text, 'cancelado'::text, 'parcial'::text]))))
);


--
-- Name: protocolo_fallecimiento; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.protocolo_fallecimiento (
    protocolo_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha_fallecimiento date NOT NULL,
    hora_fallecimiento text,
    lugar text,
    tipo text NOT NULL,
    intencion_paliativa boolean DEFAULT false,
    causa_directa text,
    causa_antecedente_1 text,
    causa_antecedente_2 text,
    causa_contribuyente text,
    codigo_cie10_causa text,
    certificado_defuncion text,
    autopsia_solicitada boolean DEFAULT false,
    familiar_notificado text,
    parentesco_notificado text,
    fecha_notificacion date,
    doc_id text,
    epicrisis_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT protocolo_fallecimiento_lugar_check CHECK (((lugar IS NULL) OR (lugar = ANY (ARRAY['domicilio'::text, 'traslado_hospital'::text, 'otro'::text])))),
    CONSTRAINT protocolo_fallecimiento_tipo_check CHECK ((tipo = ANY (ARRAY['esperado'::text, 'no_esperado'::text])))
);


--
-- Name: receta; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.receta (
    receta_id text NOT NULL,
    indicacion_id text,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text NOT NULL,
    fecha date NOT NULL,
    medicamento text NOT NULL,
    forma_farmaceutica text,
    concentracion text,
    dosis text NOT NULL,
    via text,
    frecuencia text NOT NULL,
    duracion_dias integer,
    cantidad_total text,
    tipo_receta text DEFAULT 'simple'::text,
    es_controlado boolean DEFAULT false,
    estado text DEFAULT 'vigente'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT receta_estado_check CHECK ((estado = ANY (ARRAY['vigente'::text, 'dispensada'::text, 'vencida'::text, 'anulada'::text]))),
    CONSTRAINT receta_tipo_receta_check CHECK ((tipo_receta = ANY (ARRAY['simple'::text, 'retenida'::text, 'cheque'::text]))),
    CONSTRAINT receta_via_check CHECK (((via IS NULL) OR (via = ANY (ARRAY['oral'::text, 'IV'::text, 'SC'::text, 'IM'::text, 'topica'::text, 'inhalatoria'::text, 'SNG'::text, 'rectal'::text, 'sublingual'::text, 'transdermica'::text]))))
);


--
-- Name: requerimiento_cuidado; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.requerimiento_cuidado (
    req_id text NOT NULL,
    plan_id text NOT NULL,
    tipo text,
    valor_normalizado text,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: resultado_examen; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.resultado_examen (
    resultado_id text NOT NULL,
    solicitud_id text NOT NULL,
    fecha_resultado date NOT NULL,
    examen text NOT NULL,
    valor text,
    unidad text,
    rango_referencia text,
    interpretacion text,
    informe_texto text,
    laboratorio text,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resultado_examen_interpretacion_check CHECK (((interpretacion IS NULL) OR (interpretacion = ANY (ARRAY['normal'::text, 'bajo'::text, 'alto'::text, 'critico'::text, 'indeterminado'::text]))))
);


--
-- Name: seguimiento_dispositivo; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.seguimiento_dispositivo (
    seguimiento_id text NOT NULL,
    device_id text NOT NULL,
    visit_id text,
    provider_id text,
    fecha date NOT NULL,
    cambio_realizado boolean DEFAULT false,
    fecha_instalacion date,
    signos_infeccion text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT seguimiento_dispositivo_signos_infeccion_check CHECK (((signos_infeccion IS NULL) OR (signos_infeccion = ANY (ARRAY['ausentes'::text, 'flebitis_grado_1'::text, 'flebitis_grado_2'::text, 'flebitis_grado_3'::text, 'infeccion_local'::text, 'infeccion_sistemica'::text]))))
);


--
-- Name: seguimiento_herida; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.seguimiento_herida (
    seguimiento_id text NOT NULL,
    herida_id text NOT NULL,
    visit_id text,
    provider_id text,
    fecha date NOT NULL,
    lugar_grado text,
    exudacion text,
    tipo_tejido text,
    caracteristica_tamano text,
    aposito_primario text,
    aposito_secundario text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sesion_rehabilitacion; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.sesion_rehabilitacion (
    sesion_id text NOT NULL,
    visit_id text,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    tipo text NOT NULL,
    fecha date NOT NULL,
    hora text,
    regimen text,
    ayuno text,
    csv_spo2 real,
    csv_fr real,
    csv_fc real,
    csv_pa text,
    csv_hgt real,
    csv_dolor_ena real,
    estado_general text,
    oxigenoterapia_fio2 real,
    auscultacion_mp text,
    tos text,
    resultado text,
    queda_contenido text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sesion_rehabilitacion_csv_dolor_ena_check CHECK (((csv_dolor_ena IS NULL) OR ((csv_dolor_ena >= (0)::double precision) AND (csv_dolor_ena <= (10)::double precision)))),
    CONSTRAINT sesion_rehabilitacion_queda_contenido_check CHECK (((queda_contenido IS NULL) OR (queda_contenido = ANY (ARRAY['si'::text, 'no'::text])))),
    CONSTRAINT sesion_rehabilitacion_resultado_check CHECK (((resultado IS NULL) OR (resultado = ANY (ARRAY['bien_tolerado'::text, 'aviso_a_personal'::text, 'incidentes'::text, 'finaliza_sin_incidentes'::text])))),
    CONSTRAINT sesion_rehabilitacion_tipo_check CHECK ((tipo = ANY (ARRAY['kinesiologia_respiratoria'::text, 'kinesiologia_motora'::text, 'terapia_ocupacional'::text, 'fonoaudiologia'::text])))
);


--
-- Name: sesion_rehabilitacion_item; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.sesion_rehabilitacion_item (
    sesion_item_id text NOT NULL,
    sesion_id text NOT NULL,
    categoria text NOT NULL,
    realizado boolean DEFAULT true NOT NULL,
    valor text,
    observacion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sesion_videollamada; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.sesion_videollamada (
    sesion_id text NOT NULL,
    teleconsulta_id text,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    modalidad text DEFAULT 'video'::text NOT NULL,
    estado text DEFAULT 'esperando'::text NOT NULL,
    consentimiento_otorgado boolean DEFAULT false,
    consentimiento_at timestamp with time zone,
    metodo_verificacion_identidad text,
    calidad_conexion text,
    motivo_fallback_audio text,
    inicio_at timestamp with time zone,
    fin_at timestamp with time zone,
    duracion_segundos integer,
    room_token text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sesion_videollamada_calidad_check CHECK (((calidad_conexion IS NULL) OR (calidad_conexion = ANY (ARRAY['buena'::text, 'regular'::text, 'mala'::text])))),
    CONSTRAINT sesion_videollamada_estado_check CHECK ((estado = ANY (ARRAY['esperando'::text, 'activa'::text, 'finalizada'::text, 'fallida'::text, 'cancelada'::text]))),
    CONSTRAINT sesion_videollamada_modalidad_check CHECK ((modalidad = ANY (ARRAY['video'::text, 'audio'::text]))),
    CONSTRAINT sesion_videollamada_verificacion_check CHECK (((metodo_verificacion_identidad IS NULL) OR (metodo_verificacion_identidad = ANY (ARRAY['visual_video'::text, 'rut_verificado'::text, 'pregunta_seguridad'::text]))))
);


--
-- Name: solicitud_examen; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.solicitud_examen (
    solicitud_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    solicitante_id text,
    fecha_solicitud date NOT NULL,
    tipo_examen text NOT NULL,
    examenes_solicitados text NOT NULL,
    prioridad text DEFAULT 'rutina'::text,
    diagnostico_presuntivo text,
    indicaciones_preparacion text,
    estado text DEFAULT 'solicitado'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT solicitud_examen_estado_check CHECK ((estado = ANY (ARRAY['solicitado'::text, 'muestra_tomada'::text, 'enviado_laboratorio'::text, 'resultado_disponible'::text, 'cancelado'::text]))),
    CONSTRAINT solicitud_examen_tipo_examen_check CHECK ((tipo_examen = ANY (ARRAY['laboratorio'::text, 'imagenologia'::text, 'electrocardiograma'::text, 'anatomia_patologica'::text, 'microbiologia'::text, 'otro'::text])))
);


--
-- Name: teleconsulta; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.teleconsulta (
    teleconsulta_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    fecha date NOT NULL,
    hora_inicio text,
    hora_fin text,
    modalidad text NOT NULL,
    plataforma text,
    motivo text,
    hallazgos text,
    indicaciones text,
    resultado text,
    participante_paciente boolean DEFAULT true,
    participante_cuidador boolean DEFAULT false,
    participante_otro text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT teleconsulta_modalidad_check CHECK ((modalidad = ANY (ARRAY['sincrona_video'::text, 'sincrona_telefono'::text, 'asincrona'::text, 'telemonitoreo'::text]))),
    CONSTRAINT teleconsulta_resultado_check CHECK (((resultado IS NULL) OR (resultado = ANY (ARRAY['resuelto'::text, 'requiere_visita_presencial'::text, 'derivacion'::text, 'seguimiento_telefonico'::text]))))
);


--
-- Name: toma_muestra; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.toma_muestra (
    muestra_id text NOT NULL,
    solicitud_id text NOT NULL,
    visit_id text,
    tomador_id text,
    fecha date NOT NULL,
    hora text,
    tipo_muestra text,
    condicion_paciente text,
    incidencias text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: localizacion; Type: TABLE; Schema: territorial; Owner: -
--

CREATE TABLE territorial.localizacion (
    localizacion_id text NOT NULL,
    direccion_texto text,
    referencia text,
    comuna text,
    localidad text,
    tipo_zona text,
    latitud real,
    longitud real,
    precision_geo text DEFAULT 'aproximada'::text,
    fuente_coords text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT localizacion_precision_geo_check CHECK ((precision_geo = ANY (ARRAY['exacta'::text, 'aproximada'::text, 'centroide_localidad'::text, 'centroide_comuna'::text]))),
    CONSTRAINT localizacion_tipo_zona_check CHECK (((tipo_zona IS NULL) OR (tipo_zona = ANY (ARRAY['URBANO'::text, 'PERIURBANO'::text, 'RURAL'::text, 'RURAL_AISLADO'::text]))))
);


--
-- Name: TABLE localizacion; Type: COMMENT; Schema: territorial; Owner: -
--

COMMENT ON TABLE territorial.localizacion IS 'Obj Loc — punto geografico paciente-level. Coordenadas obligatorias (PE3).';


--
-- Name: v_domicilio_vigente; Type: VIEW; Schema: clinical; Owner: -
--

CREATE VIEW clinical.v_domicilio_vigente AS
 SELECT d.domicilio_id,
    d.patient_id,
    d.tipo,
    d.vigente_desde,
    d.notas,
    d.contacto_local,
    l.direccion_texto,
    l.referencia,
    l.comuna,
    l.localidad,
    l.latitud,
    l.longitud,
    l.precision_geo
   FROM (clinical.domicilio d
     JOIN territorial.localizacion l ON ((l.localizacion_id = d.localizacion_id)))
  WHERE ((d.vigente_hasta IS NULL) OR (d.vigente_hasta >= CURRENT_DATE));


--
-- Name: encuesta_satisfaccion; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.encuesta_satisfaccion (
    encuesta_id text NOT NULL,
    patient_id text,
    stay_id text,
    nombre_paciente text NOT NULL,
    nombre_encuestado text,
    parentesco text,
    rut_encuestado text,
    telefono text,
    fecha_encuesta date,
    fecha_ingreso date,
    fecha_alta date,
    marca_temporal timestamp with time zone,
    informado_normas_ingreso boolean,
    tiempo_medico boolean,
    tiempo_enfermeria boolean,
    tiempo_kinesiologia boolean,
    tiempo_fonoaudiologia boolean,
    tiempo_tens boolean,
    atencion_examenes boolean,
    atencion_procedimientos boolean,
    atencion_medicamentos boolean,
    sat_conocimiento smallint,
    sat_informacion smallint,
    sat_confidencialidad smallint,
    sat_escucha smallint,
    sat_amabilidad smallint,
    alta_med_tratamiento boolean,
    alta_med_sintomas boolean,
    alta_med_seguimiento boolean,
    alta_med_informe boolean,
    alta_enf_indicaciones boolean,
    alta_enf_sintomas boolean,
    alta_enf_pasos boolean,
    alta_enf_informe boolean,
    alta_kine_ejercicios boolean,
    alta_kine_sintomas boolean,
    alta_kine_seguimiento boolean,
    alta_kine_informe boolean,
    alta_fono_tratamiento boolean,
    alta_fono_sintomas boolean,
    alta_fono_seguimiento boolean,
    alta_fono_informe boolean,
    mejoria_percibida text,
    conformidad_fallecimiento text,
    atencion_telefonica text,
    volveria_hodom text,
    score_satisfaccion real,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT encuesta_satisfaccion_sat_amabilidad_check CHECK (((sat_amabilidad >= 1) AND (sat_amabilidad <= 5))),
    CONSTRAINT encuesta_satisfaccion_sat_confidencialidad_check CHECK (((sat_confidencialidad >= 1) AND (sat_confidencialidad <= 5))),
    CONSTRAINT encuesta_satisfaccion_sat_conocimiento_check CHECK (((sat_conocimiento >= 1) AND (sat_conocimiento <= 5))),
    CONSTRAINT encuesta_satisfaccion_sat_escucha_check CHECK (((sat_escucha >= 1) AND (sat_escucha <= 5))),
    CONSTRAINT encuesta_satisfaccion_sat_informacion_check CHECK (((sat_informacion >= 1) AND (sat_informacion <= 5)))
);


--
-- Name: v_encuesta_unificada; Type: VIEW; Schema: clinical; Owner: -
--

CREATE VIEW clinical.v_encuesta_unificada AS
 SELECT encuesta_satisfaccion.encuesta_id,
    encuesta_satisfaccion.patient_id,
    encuesta_satisfaccion.stay_id,
    encuesta_satisfaccion.marca_temporal,
    encuesta_satisfaccion.fecha_encuesta,
    encuesta_satisfaccion.encuestado_nombre,
    encuesta_satisfaccion.encuestado_parentesco,
    encuesta_satisfaccion.satisfaccion_ingreso,
    encuesta_satisfaccion.satisfaccion_equipo_general,
    encuesta_satisfaccion.satisfaccion_oportunidad,
    encuesta_satisfaccion.satisfaccion_informacion,
    encuesta_satisfaccion.satisfaccion_trato,
    encuesta_satisfaccion.satisfaccion_unidad,
    encuesta_satisfaccion.educacion_enfermera,
    encuesta_satisfaccion.educacion_kinesiologo,
    encuesta_satisfaccion.educacion_fonoaudiologo,
    encuesta_satisfaccion.valoracion_mejoria,
    encuesta_satisfaccion.asistencia_telefonica,
    encuesta_satisfaccion.volveria,
    'clinical'::text AS source,
    encuesta_satisfaccion.created_at
   FROM clinical.encuesta_satisfaccion
UNION ALL
 SELECT encuesta_satisfaccion.encuesta_id,
    encuesta_satisfaccion.patient_id,
    encuesta_satisfaccion.stay_id,
    encuesta_satisfaccion.marca_temporal,
    encuesta_satisfaccion.fecha_encuesta,
    encuesta_satisfaccion.nombre_encuestado AS encuestado_nombre,
    encuesta_satisfaccion.parentesco AS encuestado_parentesco,
    (encuesta_satisfaccion.sat_conocimiento)::integer AS satisfaccion_ingreso,
    (encuesta_satisfaccion.sat_amabilidad)::integer AS satisfaccion_equipo_general,
    (encuesta_satisfaccion.sat_escucha)::integer AS satisfaccion_oportunidad,
    (encuesta_satisfaccion.sat_informacion)::integer AS satisfaccion_informacion,
    (encuesta_satisfaccion.sat_confidencialidad)::integer AS satisfaccion_trato,
    (round(((((((encuesta_satisfaccion.sat_conocimiento + encuesta_satisfaccion.sat_informacion) + encuesta_satisfaccion.sat_confidencialidad) + encuesta_satisfaccion.sat_escucha) + encuesta_satisfaccion.sat_amabilidad))::numeric / (5)::numeric)))::integer AS satisfaccion_unidad,
    (((
        CASE
            WHEN encuesta_satisfaccion.alta_enf_indicaciones THEN 1
            ELSE 0
        END +
        CASE
            WHEN encuesta_satisfaccion.alta_enf_sintomas THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_enf_pasos THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_enf_informe THEN 1
            ELSE 0
        END) AS educacion_enfermera,
    (((
        CASE
            WHEN encuesta_satisfaccion.alta_kine_ejercicios THEN 1
            ELSE 0
        END +
        CASE
            WHEN encuesta_satisfaccion.alta_kine_sintomas THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_kine_seguimiento THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_kine_informe THEN 1
            ELSE 0
        END) AS educacion_kinesiologo,
    (((
        CASE
            WHEN encuesta_satisfaccion.alta_fono_tratamiento THEN 1
            ELSE 0
        END +
        CASE
            WHEN encuesta_satisfaccion.alta_fono_sintomas THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_fono_seguimiento THEN 1
            ELSE 0
        END) +
        CASE
            WHEN encuesta_satisfaccion.alta_fono_informe THEN 1
            ELSE 0
        END) AS educacion_fonoaudiologo,
        CASE encuesta_satisfaccion.mejoria_percibida
            WHEN 'SI'::text THEN 'TOTALMENTE'::text
            WHEN 'PARCIALMENTE'::text THEN 'ALGO'::text
            WHEN 'NO'::text THEN 'NADA'::text
            ELSE encuesta_satisfaccion.mejoria_percibida
        END AS valoracion_mejoria,
        CASE encuesta_satisfaccion.atencion_telefonica
            WHEN 'SI'::text THEN true
            WHEN 'NO'::text THEN false
            ELSE NULL::boolean
        END AS asistencia_telefonica,
        CASE encuesta_satisfaccion.volveria_hodom
            WHEN 'SI'::text THEN 'si'::text
            WHEN 'PROBABLEMENTE SI'::text THEN 'probablemente_si'::text
            WHEN 'PROBABLEMENTE NO'::text THEN 'probablemente_no'::text
            WHEN 'NO'::text THEN 'no'::text
            ELSE lower(replace(encuesta_satisfaccion.volveria_hodom, ' '::text, '_'::text))
        END AS volveria,
    'reporting'::text AS source,
    encuesta_satisfaccion.created_at
   FROM reporting.encuesta_satisfaccion;


--
-- Name: VIEW v_encuesta_unificada; Type: COMMENT; Schema: clinical; Owner: -
--

COMMENT ON VIEW clinical.v_encuesta_unificada IS 'Coproducto: clinical.encuesta_satisfaccion UNION reporting.encuesta_satisfaccion. Estado actual: solo reporting tiene datos (33 filas de CORR-14). El coprojection clinical se activara cuando hdos-app capture encuestas clinicas.';


--
-- Name: valoracion_ingreso; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.valoracion_ingreso (
    assessment_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    tipo text NOT NULL,
    fecha date NOT NULL,
    antecedentes_morbidos text,
    medicamentos_cronicos text,
    historia_ingreso text,
    valores_examenes text,
    alergias text,
    diagnostico_enfermeria text,
    plan_atencion text,
    servicio_origen text,
    nro_postulacion text,
    funcionalidad_previa text,
    evaluacion_motora text,
    evaluacion_respiratoria text,
    dependencia_kinesica_motora text,
    dependencia_kinesica_respiratoria text,
    objetivos_kine text,
    indicacion_kine text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT valoracion_ingreso_tipo_check CHECK ((tipo = ANY (ARRAY['enfermeria'::text, 'kinesiologia'::text, 'fonoaudiologia'::text, 'terapia_ocupacional'::text, 'medica'::text, 'tens'::text])))
);


--
-- Name: profesional; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.profesional (
    provider_id text NOT NULL,
    rut text,
    nombre text NOT NULL,
    profesion text,
    profesion_rem text,
    competencias text,
    vehiculo text,
    comunas_cobertura text,
    max_visitas_dia integer,
    base_lat real,
    base_lng real,
    estado text,
    contrato text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    password_hash text,
    telefono text,
    email text,
    fecha_nacimiento date,
    CONSTRAINT profesional_contrato_check CHECK (((contrato IS NULL) OR (contrato = ANY (ARRAY['planta'::text, 'contrata'::text, 'honorario'::text, 'reemplazo'::text, 'estudiante'::text])))),
    CONSTRAINT profesional_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'licencia_medica'::text])))),
    CONSTRAINT profesional_profesion_check CHECK ((profesion = ANY (ARRAY['ENFERMERIA'::text, 'KINESIOLOGIA'::text, 'FONOAUDIOLOGIA'::text, 'MEDICO'::text, 'TRABAJO_SOCIAL'::text, 'TENS'::text, 'NUTRICION'::text, 'MATRONA'::text, 'PSICOLOGIA'::text, 'TERAPIA_OCUPACIONAL'::text]))),
    CONSTRAINT profesional_profesion_rem_check CHECK (((profesion_rem IS NULL) OR (profesion_rem = ANY (ARRAY['medico'::text, 'enfermera'::text, 'tecnico_enfermeria'::text, 'matrona'::text, 'kinesiologo'::text, 'psicologo'::text, 'fonoaudiologo'::text, 'trabajador_social'::text, 'terapeuta_ocupacional'::text]))))
);


--
-- Name: COLUMN profesional.competencias; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.profesional.competencias IS 'Debería ser TEXT[] (array). Actualmente TEXT libre con CSV implícito. 1/23 poblado.';


--
-- Name: COLUMN profesional.vehiculo; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.profesional.vehiculo IS 'NON-FUNCTORIAL: TEXT libre, debería ser FK → vehiculo.vehiculo_id. Actualmente NULL en todos los registros. Migrar a FK cuando se implemente asignación vehicular.';


--
-- Name: COLUMN profesional.comunas_cobertura; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.profesional.comunas_cobertura IS 'Debería ser TEXT[] o JSONB. Actualmente TEXT libre. No poblado.';


--
-- Name: v_timeline_episodio; Type: VIEW; Schema: clinical; Owner: -
--

CREATE VIEW clinical.v_timeline_episodio AS
 SELECT e.stay_id,
    'nota_evolucion'::text AS tipo_registro,
    ne.nota_id AS registro_id,
    ne.tipo AS subtipo,
    ne.fecha,
    ne.hora,
    pr.nombre AS profesional,
    pr.profesion,
    ne.notas_clinicas AS contenido,
    ne.plan_enfermeria AS contenido_extra
   FROM ((clinical.nota_evolucion ne
     JOIN clinical.estadia e ON ((ne.stay_id = e.stay_id)))
     LEFT JOIN operational.profesional pr ON ((ne.provider_id = pr.provider_id)))
UNION ALL
 SELECT e.stay_id,
    'valoracion_ingreso'::text AS tipo_registro,
    vi.assessment_id AS registro_id,
    vi.tipo AS subtipo,
    vi.fecha,
    NULL::text AS hora,
    pr.nombre AS profesional,
    pr.profesion,
    vi.historia_ingreso AS contenido,
    vi.diagnostico_enfermeria AS contenido_extra
   FROM ((clinical.valoracion_ingreso vi
     JOIN clinical.estadia e ON ((vi.stay_id = e.stay_id)))
     LEFT JOIN operational.profesional pr ON ((vi.provider_id = pr.provider_id)))
UNION ALL
 SELECT e.stay_id,
    'epicrisis'::text AS tipo_registro,
    ep.epicrisis_id AS registro_id,
    ep.tipo_egreso AS subtipo,
    ep.fecha_emision AS fecha,
    NULL::text AS hora,
    pr.nombre AS profesional,
    'medica'::text AS profesion,
    ep.resumen_evolucion AS contenido,
    ep.indicaciones_alta AS contenido_extra
   FROM ((clinical.epicrisis ep
     JOIN clinical.estadia e ON ((ep.stay_id = e.stay_id)))
     LEFT JOIN operational.profesional pr ON ((ep.provider_id = pr.provider_id)))
  ORDER BY 5 DESC, 6 DESC NULLS LAST;


--
-- Name: VIEW v_timeline_episodio; Type: COMMENT; Schema: clinical; Owner: -
--

COMMENT ON VIEW clinical.v_timeline_episodio IS 'Pantalla 2: timeline cronológica de la ficha clínica por episodio';


--
-- Name: valoracion_hallazgo; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.valoracion_hallazgo (
    hallazgo_id text NOT NULL,
    assessment_id text NOT NULL,
    dominio text NOT NULL,
    codigo text,
    valor text,
    valor_opciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: voluntad_anticipada; Type: TABLE; Schema: clinical; Owner: -
--

CREATE TABLE clinical.voluntad_anticipada (
    voluntad_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    fecha date NOT NULL,
    tipo text NOT NULL,
    descripcion text,
    firmante_paciente boolean DEFAULT true,
    representante_nombre text,
    representante_rut text,
    representante_parentesco text,
    testigo_1_nombre text,
    testigo_2_nombre text,
    provider_id text,
    estado text DEFAULT 'vigente'::text,
    fecha_revocacion date,
    doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT voluntad_anticipada_estado_check CHECK ((estado = ANY (ARRAY['vigente'::text, 'revocada'::text]))),
    CONSTRAINT voluntad_anticipada_tipo_check CHECK ((tipo = ANY (ARRAY['rechazo_tratamiento'::text, 'limitacion_esfuerzo_terapeutico'::text, 'orden_no_reanimar'::text, 'directiva_anticipada_general'::text, 'designacion_representante'::text])))
);


--
-- Name: provenance; Type: TABLE; Schema: migration; Owner: -
--

CREATE TABLE migration.provenance (
    target_table text NOT NULL,
    target_pk text NOT NULL,
    source_type text NOT NULL,
    source_file text NOT NULL,
    source_key text,
    phase text NOT NULL,
    field_name text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: agenda_profesional; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.agenda_profesional (
    schedule_id text NOT NULL,
    provider_id text NOT NULL,
    fecha date NOT NULL,
    hora_inicio text,
    hora_fin text,
    tipo text,
    motivo_bloqueo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT agenda_profesional_tipo_check CHECK ((tipo = ANY (ARRAY['TURNO'::text, 'GUARDIA'::text, 'EXTRA'::text, 'BLOQUEADO'::text])))
);


--
-- Name: audit_log; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.audit_log (
    log_id text NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    user_id text,
    user_name text,
    accion text NOT NULL,
    entidad text,
    entidad_id text,
    detalle jsonb,
    ip text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: canasta_valorizada; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.canasta_valorizada (
    valorizacion_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    periodo text NOT NULL,
    dias_cama integer DEFAULT 0,
    visitas_realizadas integer DEFAULT 0,
    procedimientos integer DEFAULT 0,
    examenes integer DEFAULT 0,
    costo_rrhh real DEFAULT 0,
    costo_insumos real DEFAULT 0,
    costo_medicamentos real DEFAULT 0,
    costo_oxigeno real DEFAULT 0,
    costo_transporte real DEFAULT 0,
    costo_examenes real DEFAULT 0,
    costo_total real DEFAULT 0,
    valor_canasta_mai real,
    diferencia real,
    generado_en timestamp with time zone,
    fuente_visitas integer,
    fuente_procedimientos integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: capacitacion; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.capacitacion (
    capacitacion_id text NOT NULL,
    provider_id text NOT NULL,
    nombre text NOT NULL,
    tipo text,
    fecha date NOT NULL,
    horas real,
    institucion text,
    certificado boolean DEFAULT false,
    fecha_vencimiento date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT capacitacion_tipo_check CHECK ((tipo = ANY (ARRAY['induccion_hd'::text, 'curacion_avanzada'::text, 'manejo_dispositivos'::text, 'oxigenoterapia'::text, 'cuidados_paliativos'::text, 'reanimacion_basica'::text, 'manejo_emergencias'::text, 'telemedicina'::text, 'normativa_legal'::text, 'autocuidado_equipo'::text, 'otro'::text])))
);


--
-- Name: compra_servicio; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.compra_servicio (
    compra_id text NOT NULL,
    patient_id text,
    stay_id text,
    proveedor text NOT NULL,
    tipo_servicio text NOT NULL,
    descripcion text NOT NULL,
    cantidad text,
    costo_unitario real,
    costo_total real,
    orden_compra text,
    factura text,
    fecha date NOT NULL,
    estado text DEFAULT 'solicitada'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT compra_servicio_estado_check CHECK ((estado = ANY (ARRAY['solicitada'::text, 'aprobada'::text, 'recibida'::text, 'pagada'::text]))),
    CONSTRAINT compra_servicio_tipo_servicio_check CHECK ((tipo_servicio = ANY (ARRAY['oxigeno'::text, 'insumos_curacion'::text, 'medicamentos'::text, 'equipamiento'::text, 'laboratorio'::text, 'imagenologia'::text, 'transporte'::text, 'otro'::text])))
);


--
-- Name: conductor; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.conductor (
    conductor_id text NOT NULL,
    rut text,
    nombre text NOT NULL,
    licencia_clase text,
    licencia_vencimiento date,
    telefono text,
    estado text DEFAULT 'activo'::text,
    vehiculo_asignado text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    email text,
    fecha_nacimiento date,
    CONSTRAINT conductor_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'licencia_medica'::text])))
);


--
-- Name: configuracion_programa; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.configuracion_programa (
    config_id text NOT NULL,
    clave text NOT NULL,
    valor text NOT NULL,
    descripcion text,
    tipo_dato text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT configuracion_programa_tipo_dato_check CHECK ((tipo_dato = ANY (ARRAY['texto'::text, 'numero'::text, 'fecha'::text, 'boolean'::text, 'json'::text])))
);


--
-- Name: decision_despacho; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.decision_despacho (
    decision_id text NOT NULL,
    visit_id text NOT NULL,
    provider_id text NOT NULL,
    decision text,
    score_skill real,
    score_distancia real,
    score_continuidad real,
    score_carga real,
    score_total real,
    motivo_rechazo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT decision_despacho_decision_check CHECK ((decision = ANY (ARRAY['asignado'::text, 'rechazado'::text, 'reasignado'::text])))
);


--
-- Name: entrega_turno; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.entrega_turno (
    entrega_id text NOT NULL,
    fecha date NOT NULL,
    turno_saliente_id text,
    turno_entrante_id text,
    pacientes_activos integer,
    novedades_generales text,
    pendientes text,
    alertas text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: entrega_turno_paciente; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.entrega_turno_paciente (
    entrega_paciente_id text NOT NULL,
    entrega_id text NOT NULL,
    patient_id text NOT NULL,
    stay_id text,
    estado_resumen text,
    novedades text,
    pendientes text,
    prioridad text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: estadia_episodio_fuente; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.estadia_episodio_fuente (
    stay_id text NOT NULL,
    episode_id text NOT NULL,
    source_origin text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: evento_estadia; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.evento_estadia (
    event_id text NOT NULL,
    stay_id text NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    estado_previo text,
    estado_nuevo text,
    proceso_opm text,
    detalle text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT evento_estadia_estado_nuevo_check CHECK ((estado_nuevo = ANY (ARRAY['pendiente_evaluacion'::text, 'elegible'::text, 'admitido'::text, 'activo'::text, 'egresado'::text, 'fallecido'::text]))),
    CONSTRAINT evento_estadia_proceso_opm_check CHECK (((proceso_opm IS NULL) OR (proceso_opm = ANY (ARRAY['eligibility_evaluating'::text, 'patient_admitting'::text, 'care_planning'::text, 'therapeutic_plan_executing'::text, 'clinical_evolution_monitoring'::text, 'patient_discharging'::text, 'post_discharge_following'::text]))))
);


--
-- Name: evento_visita; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.evento_visita (
    event_id text NOT NULL,
    visit_id text NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    estado_previo text,
    estado_nuevo text,
    lat real,
    lng real,
    origen text,
    detalle text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: insumo; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.insumo (
    item_id text NOT NULL,
    nombre text NOT NULL,
    categoria text,
    peso_kg real,
    requiere_vehiculo boolean DEFAULT false,
    stock_actual integer,
    umbral_reposicion integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insumo_categoria_check CHECK ((categoria = ANY (ARRAY['CURACION'::text, 'MEDICAMENTO'::text, 'EQUIPO'::text, 'OXIGENO'::text, 'DESCARTABLE'::text])))
);


--
-- Name: kb_articulo; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_articulo (
    articulo_id text NOT NULL,
    slug text NOT NULL,
    titulo text NOT NULL,
    resumen text,
    contenido text NOT NULL,
    categoria text NOT NULL,
    estado text DEFAULT 'borrador'::text NOT NULL,
    autor_id text NOT NULL,
    autor_nombre text NOT NULL,
    editor_id text,
    editor_nombre text,
    version integer DEFAULT 1 NOT NULL,
    publicado_en timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT kb_articulo_estado_check CHECK ((estado = ANY (ARRAY['borrador'::text, 'publicado'::text, 'archivado'::text])))
);


--
-- Name: kb_articulo_link; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_articulo_link (
    source_id text NOT NULL,
    target_id text NOT NULL,
    CONSTRAINT kb_articulo_link_check CHECK ((source_id <> target_id))
);


--
-- Name: kb_articulo_tag; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_articulo_tag (
    articulo_id text NOT NULL,
    tag_id text NOT NULL
);


--
-- Name: kb_articulo_version; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_articulo_version (
    version_id text NOT NULL,
    articulo_id text NOT NULL,
    version integer NOT NULL,
    titulo text NOT NULL,
    contenido text NOT NULL,
    editor_id text NOT NULL,
    editor_nombre text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: kb_documento; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_documento (
    documento_id text NOT NULL,
    nombre text NOT NULL,
    nombre_archivo text NOT NULL,
    ruta_archivo text NOT NULL,
    mime_type text NOT NULL,
    tamano_bytes bigint NOT NULL,
    categoria text NOT NULL,
    descripcion text,
    subido_por_id text NOT NULL,
    subido_por_nombre text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: kb_documento_tag; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_documento_tag (
    documento_id text NOT NULL,
    tag_id text NOT NULL
);


--
-- Name: kb_tag; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.kb_tag (
    tag_id text NOT NULL,
    nombre text NOT NULL,
    color text
);


--
-- Name: orden_servicio; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.orden_servicio (
    order_id text NOT NULL,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    service_type text,
    profesion_requerida text,
    frecuencia text,
    duracion_est_min integer,
    prioridad text,
    requiere_continuidad boolean DEFAULT false,
    provider_asignado text,
    requiere_vehiculo boolean DEFAULT false,
    ventana_preferida text,
    fecha_inicio date,
    fecha_fin date,
    estado text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT orden_servicio_check CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_inicio))),
    CONSTRAINT orden_servicio_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['borrador'::text, 'activa'::text, 'completada'::text, 'cancelada'::text, 'suspendida'::text]))))
);


--
-- Name: orden_servicio_insumo; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.orden_servicio_insumo (
    order_id text NOT NULL,
    item_id text NOT NULL,
    cantidad integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: portal_acceso_log; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.portal_acceso_log (
    log_id text NOT NULL,
    usuario_id text NOT NULL,
    ip inet,
    user_agent text,
    creado_at timestamp with time zone DEFAULT now() NOT NULL,
    accion text DEFAULT 'login'::text
);


--
-- Name: portal_invitacion; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.portal_invitacion (
    invitacion_id text NOT NULL,
    email text NOT NULL,
    patient_id text,
    rol text NOT NULL,
    token text NOT NULL,
    estado text,
    enviado_at timestamp with time zone,
    usada_at timestamp with time zone,
    expira_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT portal_invitacion_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'usada'::text, 'expirada'::text]))),
    CONSTRAINT portal_invitacion_rol_check CHECK ((rol = ANY (ARRAY['paciente'::text, 'cuidador'::text])))
);


--
-- Name: portal_usuario; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.portal_usuario (
    usuario_id text NOT NULL,
    patient_id text,
    cuidador_id text,
    rol text NOT NULL,
    email text,
    password_hash text,
    nombre text,
    estado text,
    invitado_por text,
    fecha_invitacion date,
    ultimo_acceso timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    otp_secret text,
    otp_expires timestamp with time zone,
    pin_hash text,
    pin_intentos_fallidos integer DEFAULT 0 NOT NULL,
    CONSTRAINT portal_usuario_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'invitado'::text, 'suspendido'::text, 'inactivo'::text]))),
    CONSTRAINT portal_usuario_rol_check CHECK ((rol = ANY (ARRAY['paciente'::text, 'cuidador'::text])))
);


--
-- Name: push_subscription; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.push_subscription (
    sub_id text NOT NULL,
    usuario_tipo text NOT NULL,
    usuario_id text NOT NULL,
    endpoint text NOT NULL,
    p256dh text NOT NULL,
    auth_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT push_subscription_usuario_tipo_check CHECK ((usuario_tipo = ANY (ARRAY['staff'::text, 'portal'::text])))
);


--
-- Name: registro_llamada; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.registro_llamada (
    llamada_id text NOT NULL,
    fecha date NOT NULL,
    hora text,
    duracion text,
    telefono text,
    motivo text,
    patient_id text,
    stay_id text,
    nombre_familiar text,
    parentesco_familiar text,
    estado_paciente text,
    tipo text,
    provider_id text,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT registro_llamada_estado_paciente_check CHECK (((estado_paciente IS NULL) OR (estado_paciente = ANY (ARRAY['activo'::text, 'egresado'::text])))),
    CONSTRAINT registro_llamada_motivo_check CHECK (((motivo IS NULL) OR (motivo = ANY (ARRAY['resultado_examen'::text, 'asistencia_social'::text, 'consulta_clinica'::text, 'seguimiento'::text, 'coordinacion'::text, 'seguimiento_post_egreso'::text, 'otro'::text])))),
    CONSTRAINT registro_llamada_tipo_check CHECK ((tipo = ANY (ARRAY['emitida'::text, 'recibida'::text])))
);


--
-- Name: registro_vehicular; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.registro_vehicular (
    registro_id text NOT NULL,
    route_id text,
    conductor_id text NOT NULL,
    vehiculo_id text,
    fecha date NOT NULL,
    km_inicio real,
    km_fin real,
    combustible_litros real,
    checklist_neumaticos boolean DEFAULT false,
    checklist_luces boolean DEFAULT false,
    checklist_frenos boolean DEFAULT false,
    checklist_aceite boolean DEFAULT false,
    checklist_agua boolean DEFAULT false,
    checklist_limpieza boolean DEFAULT false,
    checklist_documentos boolean DEFAULT false,
    checklist_botiquin boolean DEFAULT false,
    observaciones text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: requerimiento_orden_mapping; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.requerimiento_orden_mapping (
    req_id text NOT NULL,
    order_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reunion_equipo; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.reunion_equipo (
    reunion_id text NOT NULL,
    fecha date NOT NULL,
    tipo text,
    lugar text,
    temas_tratados text,
    acuerdos text,
    tareas_asignadas text,
    n_asistentes integer,
    asistentes text,
    acta_doc_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reunion_equipo_tipo_check CHECK ((tipo = ANY (ARRAY['clinica'::text, 'coordinacion'::text, 'comite_calidad'::text, 'capacitacion'::text, 'otra'::text])))
);


--
-- Name: ruta; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.ruta (
    route_id text NOT NULL,
    provider_id text,
    conductor_id text,
    fecha date NOT NULL,
    estado text,
    origen_lat real,
    origen_lng real,
    hora_salida_plan text,
    hora_salida_real text,
    km_totales real,
    minutos_viaje real,
    minutos_atencion real,
    ratio_viaje_atencion real,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    vehiculo_id text,
    CONSTRAINT ruta_estado_check CHECK (((estado IS NULL) OR (estado = ANY (ARRAY['planificada'::text, 'en_curso'::text, 'completada'::text, 'cancelada'::text]))))
);


--
-- Name: COLUMN ruta.vehiculo_id; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.ruta.vehiculo_id IS 'Vehículo asignado a esta ruta (asociación dinámica por ruta, no permanente por conductor)';


--
-- Name: sla; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.sla (
    sla_id text NOT NULL,
    service_type text NOT NULL,
    prioridad text,
    max_hrs_primera_visita integer,
    frecuencia_minima text,
    duracion_minima_min integer,
    ventana_horaria text,
    max_perdidas_consecutivas integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: visita; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.visita (
    visit_id text NOT NULL,
    order_id text,
    stay_id text NOT NULL,
    patient_id text NOT NULL,
    provider_id text,
    route_id text,
    seq_en_ruta integer,
    fecha date NOT NULL,
    hora_plan_inicio text,
    hora_plan_fin text,
    hora_real_inicio text,
    hora_real_fin text,
    gps_lat real,
    gps_lng real,
    estado text,
    resultado text,
    motivo_no_realizada text,
    doc_estado text,
    rem_reportable boolean DEFAULT false,
    prestacion_id text,
    rem_prestacion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    domicilio_id text,
    location_id text,
    localizacion_id text,
    CONSTRAINT visita_doc_estado_check CHECK (((doc_estado IS NULL) OR (doc_estado = ANY (ARRAY['pendiente'::text, 'completo'::text, 'verificado'::text])))),
    CONSTRAINT visita_estado_check CHECK ((estado = ANY (ARRAY['PROGRAMADA'::text, 'ASIGNADA'::text, 'DESPACHADA'::text, 'EN_RUTA'::text, 'LLEGADA'::text, 'EN_ATENCION'::text, 'COMPLETA'::text, 'PARCIAL'::text, 'NO_REALIZADA'::text, 'DOCUMENTADA'::text, 'VERIFICADA'::text, 'REPORTADA_REM'::text, 'CANCELADA'::text]))),
    CONSTRAINT visita_resultado_check CHECK (((resultado IS NULL) OR (resultado = ANY (ARRAY['satisfactorio'::text, 'parcial'::text, 'sin_cambios'::text, 'deterioro'::text, 'derivado'::text]))))
);


--
-- Name: COLUMN visita.gps_lat; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.visita.gps_lat IS 'Coordenada GPS real desde NavPro (telemetría vehicular). 176/7594 poblado via matching Haversine <150m.';


--
-- Name: COLUMN visita.domicilio_id; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.visita.domicilio_id IS 'FK canónica para geolocalización. Cadena: domicilio → localizacion → (lat,lng). 7594/7594 poblado.';


--
-- Name: COLUMN visita.location_id; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.visita.location_id IS 'Legacy FK → territorial.ubicacion. NO POBLADO (0/7594). Mantenido por compatibilidad con hdos-app vistas. Cadena canónica: visita → domicilio → localizacion → (lat,lng)';


--
-- Name: COLUMN visita.localizacion_id; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON COLUMN operational.visita.localizacion_id IS 'Redundante: derivable via domicilio.localizacion_id (100% coincidencia verificada). Mantenido porque hdos-app JOIN directamente en rutas API. Path equation: visita.localizacion_id = domicilio.localizacion_id';


--
-- Name: catalogo_prestacion; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.catalogo_prestacion (
    prestacion_id text NOT NULL,
    codigo_mai text,
    nombre_prestacion text NOT NULL,
    macroproceso text,
    subproceso text,
    estamento text,
    tipo_eph text,
    area_influencia text,
    compra_servicio boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT catalogo_prestacion_estamento_check CHECK (((estamento IS NULL) OR (estamento = ANY (ARRAY['ENFERMERIA'::text, 'KINESIOLOGIA'::text, 'FONOAUDIOLOGIA'::text, 'MEDICO'::text, 'TRABAJO_SOCIAL'::text, 'TENS'::text, 'NUTRICION'::text, 'MATRONA'::text, 'PSICOLOGIA'::text, 'TERAPIA_OCUPACIONAL'::text])))),
    CONSTRAINT catalogo_prestacion_tipo_eph_check CHECK ((tipo_eph = ANY (ARRAY['EPH'::text, 'nueva'::text])))
);


--
-- Name: v_agenda_dia; Type: VIEW; Schema: operational; Owner: -
--

CREATE VIEW operational.v_agenda_dia AS
 SELECT v.visit_id,
    v.fecha,
    v.hora_plan_inicio,
    v.estado AS estado_visita,
    v.seq_en_ruta,
    pr.provider_id,
    pr.nombre AS profesional,
    pr.profesion,
    pr.profesion_rem,
    p.nombre_completo AS paciente,
    p.rut AS paciente_rut,
    p.direccion,
    p.comuna,
    p.contacto_telefono,
    e.stay_id,
    e.diagnostico_principal,
    e.estado AS estado_episodio,
    r.route_id,
    r.estado AS estado_ruta,
    v.rem_prestacion AS tipo_atencion,
    cp.nombre_prestacion
   FROM (((((operational.visita v
     JOIN clinical.estadia e ON ((v.stay_id = e.stay_id)))
     JOIN clinical.paciente p ON ((v.patient_id = p.patient_id)))
     LEFT JOIN operational.profesional pr ON ((v.provider_id = pr.provider_id)))
     LEFT JOIN operational.ruta r ON ((v.route_id = r.route_id)))
     LEFT JOIN reference.catalogo_prestacion cp ON ((v.prestacion_id = cp.prestacion_id)))
  ORDER BY v.fecha, r.route_id, v.seq_en_ruta, v.hora_plan_inicio;


--
-- Name: VIEW v_agenda_dia; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON VIEW operational.v_agenda_dia IS 'Pantalla 3: agenda de visitas por día, profesional y ruta';


--
-- Name: v_llamadas; Type: VIEW; Schema: operational; Owner: -
--

CREATE VIEW operational.v_llamadas AS
 SELECT rl.llamada_id,
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
   FROM ((operational.registro_llamada rl
     LEFT JOIN clinical.paciente p ON ((rl.patient_id = p.patient_id)))
     LEFT JOIN operational.profesional pr ON ((rl.provider_id = pr.provider_id)))
  ORDER BY rl.fecha DESC, rl.hora DESC;


--
-- Name: VIEW v_llamadas; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON VIEW operational.v_llamadas IS 'Pantalla 4: bandeja de llamadas';


--
-- Name: v_postulaciones_pendientes; Type: VIEW; Schema: operational; Owner: -
--

CREATE VIEW operational.v_postulaciones_pendientes AS
 SELECT e.stay_id,
    p.nombre_completo AS paciente,
    p.rut,
    (EXTRACT(year FROM age((p.fecha_nacimiento)::timestamp with time zone)))::integer AS edad,
    e.diagnostico_principal,
    e.origen_derivacion,
    e.fecha_ingreso AS fecha_postulacion,
    e.estado,
    ( SELECT c.decision
           FROM clinical.consentimiento c
          WHERE ((c.stay_id = e.stay_id) AND (c.tipo = 'hospitalizacion_domiciliaria'::text))
          ORDER BY c.fecha DESC
         LIMIT 1) AS consentimiento,
    ( SELECT i.condiciones_sanitarias
           FROM clinical.informe_social i
          WHERE (i.stay_id = e.stay_id)
          ORDER BY i.fecha DESC
         LIMIT 1) AS condiciones_sanitarias,
    (( SELECT count(*) AS count
           FROM clinical.checklist_ingreso ci
          WHERE (ci.stay_id = e.stay_id)))::integer AS checklist_items
   FROM (clinical.estadia e
     JOIN clinical.paciente p ON ((e.patient_id = p.patient_id)))
  WHERE (e.estado = ANY (ARRAY['pendiente_evaluacion'::text, 'elegible'::text]))
  ORDER BY e.fecha_ingreso;


--
-- Name: VIEW v_postulaciones_pendientes; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON VIEW operational.v_postulaciones_pendientes IS 'Postulaciones en proceso de evaluación de elegibilidad';


--
-- Name: v_tablero_coordinacion; Type: VIEW; Schema: operational; Owner: -
--

CREATE VIEW operational.v_tablero_coordinacion AS
 SELECT e.stay_id,
    p.patient_id,
    p.nombre_completo AS paciente,
    p.rut,
    (EXTRACT(year FROM age((p.fecha_nacimiento)::timestamp with time zone)))::integer AS edad,
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
    ( SELECT v.fecha
           FROM operational.visita v
          WHERE ((v.stay_id = e.stay_id) AND (v.estado = ANY (ARRAY['COMPLETA'::text, 'DOCUMENTADA'::text, 'VERIFICADA'::text, 'REPORTADA_REM'::text])))
          ORDER BY v.fecha DESC, v.hora_real_fin DESC NULLS LAST
         LIMIT 1) AS ultima_visita,
    ( SELECT v.fecha
           FROM operational.visita v
          WHERE ((v.stay_id = e.stay_id) AND (v.estado = ANY (ARRAY['PROGRAMADA'::text, 'ASIGNADA'::text])) AND (v.fecha >= CURRENT_DATE))
          ORDER BY v.fecha, v.hora_plan_inicio
         LIMIT 1) AS proxima_visita,
    (( SELECT count(*) AS count
           FROM clinical.alerta a
          WHERE ((a.stay_id = e.stay_id) AND (a.estado = 'activa'::text))))::integer AS alertas_activas,
    (CURRENT_DATE - COALESCE(( SELECT max(v.fecha) AS max
           FROM operational.visita v
          WHERE ((v.stay_id = e.stay_id) AND (v.estado = ANY (ARRAY['COMPLETA'::text, 'DOCUMENTADA'::text, 'VERIFICADA'::text, 'REPORTADA_REM'::text])))), e.fecha_ingreso)) AS dias_sin_visita
   FROM (clinical.estadia e
     JOIN clinical.paciente p ON ((e.patient_id = p.patient_id)))
  WHERE (e.estado = ANY (ARRAY['activo'::text, 'admitido'::text]))
  ORDER BY e.fecha_ingreso;


--
-- Name: VIEW v_tablero_coordinacion; Type: COMMENT; Schema: operational; Owner: -
--

COMMENT ON VIEW operational.v_tablero_coordinacion IS 'Pantalla 1: tablero de coordinación con pacientes activos, alertas y próximas visitas';


--
-- Name: vehiculo; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.vehiculo (
    vehiculo_id text NOT NULL,
    patente text NOT NULL,
    marca text,
    modelo text,
    anio integer,
    tipo text,
    capacidad_pasajeros integer,
    capacidad_carga_kg real,
    estado text DEFAULT 'operativo'::text,
    km_actual real,
    proxima_revision_tecnica date,
    seguro_vigente_hasta date,
    gps_device_name text,
    gps_plataforma text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vehiculo_estado_check CHECK ((estado = ANY (ARRAY['operativo'::text, 'en_mantencion'::text, 'de_baja'::text, 'siniestrado'::text]))),
    CONSTRAINT vehiculo_tipo_check CHECK ((tipo = ANY (ARRAY['auto'::text, 'furgon'::text, 'ambulancia'::text, 'otro'::text])))
);


--
-- Name: zona_profesional; Type: TABLE; Schema: operational; Owner: -
--

CREATE TABLE operational.zona_profesional (
    zone_id text NOT NULL,
    provider_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: v_mi_episodio; Type: VIEW; Schema: portal; Owner: -
--

CREATE VIEW portal.v_mi_episodio AS
 SELECT e.stay_id,
    e.patient_id,
    e.diagnostico_principal,
    e.fecha_ingreso,
    e.fecha_egreso,
    e.estado,
    e.tipo_egreso,
    p.nombre_completo AS paciente,
    p.rut,
    p.sexo,
    p.fecha_nacimiento,
    p.direccion,
    p.comuna,
    p.cesfam,
    p.prevision,
    ( SELECT ((((c.nombre || ' ('::text) || c.parentesco) || ') - '::text) || c.contacto)
           FROM clinical.cuidador c
          WHERE (c.patient_id = e.patient_id)
          ORDER BY c.created_at DESC
         LIMIT 1) AS cuidador_principal,
    ( SELECT ((v.fecha || ' '::text) || COALESCE(v.hora_plan_inicio, ''::text))
           FROM operational.visita v
          WHERE ((v.stay_id = e.stay_id) AND (v.estado = ANY (ARRAY['PROGRAMADA'::text, 'ASIGNADA'::text])) AND (v.fecha >= CURRENT_DATE))
          ORDER BY v.fecha, v.hora_plan_inicio
         LIMIT 1) AS proxima_visita,
    ( SELECT configuracion_programa.valor
           FROM operational.configuracion_programa
          WHERE (configuracion_programa.clave = 'telefono_hodom'::text)
         LIMIT 1) AS telefono_hodom
   FROM (clinical.estadia e
     JOIN clinical.paciente p ON ((e.patient_id = p.patient_id)))
  WHERE (e.estado = ANY (ARRAY['activo'::text, 'admitido'::text]));


--
-- Name: VIEW v_mi_episodio; Type: COMMENT; Schema: portal; Owner: -
--

COMMENT ON VIEW portal.v_mi_episodio IS 'Resumen del episodio activo para el portal paciente';


--
-- Name: v_mi_documento_emergencia; Type: VIEW; Schema: portal; Owner: -
--

CREATE VIEW portal.v_mi_documento_emergencia AS
 SELECT v_mi_episodio.stay_id,
    v_mi_episodio.patient_id,
    v_mi_episodio.diagnostico_principal,
    v_mi_episodio.fecha_ingreso,
    v_mi_episodio.telefono_hodom,
    ( SELECT configuracion_programa.valor
           FROM operational.configuracion_programa
          WHERE (configuracion_programa.clave = 'telefono_emergencia'::text)
         LIMIT 1) AS telefono_emergencia,
    ( SELECT configuracion_programa.valor
           FROM operational.configuracion_programa
          WHERE (configuracion_programa.clave = 'horario_visitas'::text)
         LIMIT 1) AS horario_visitas,
    ( SELECT configuracion_programa.valor
           FROM operational.configuracion_programa
          WHERE (configuracion_programa.clave = 'horario_telefono'::text)
         LIMIT 1) AS horario_telefono
   FROM portal.v_mi_episodio
  WHERE (v_mi_episodio.estado = ANY (ARRAY['activo'::text, 'admitido'::text]));


--
-- Name: VIEW v_mi_documento_emergencia; Type: COMMENT; Schema: portal; Owner: -
--

COMMENT ON VIEW portal.v_mi_documento_emergencia IS 'Documento de emergencia para el paciente';


--
-- Name: v_mis_indicaciones; Type: VIEW; Schema: portal; Owner: -
--

CREATE VIEW portal.v_mis_indicaciones AS
 SELECT im.indicacion_id,
    im.fecha,
    im.hora,
    im.tipo,
    im.descripcion,
    im.medicamento,
    im.dosis,
    im.via,
    im.frecuencia,
    im.dilucion,
    im.duracion,
    im.o2_flujo_lpm,
    im.o2_dispositivo,
    im.o2_horas_dia,
    im.estado,
    im.fecha_suspension,
    pr.nombre AS profesional_que_indico
   FROM (clinical.indicacion_medica im
     LEFT JOIN operational.profesional pr ON ((im.provider_id = pr.provider_id)))
  WHERE (im.estado = ANY (ARRAY['activa'::text, 'modificada'::text]));


--
-- Name: VIEW v_mis_indicaciones; Type: COMMENT; Schema: portal; Owner: -
--

COMMENT ON VIEW portal.v_mis_indicaciones IS 'Indicaciones activas para el portal';


--
-- Name: categoria_rehabilitacion_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.categoria_rehabilitacion_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    tipo_sesion text NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: codigo_observacion_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.codigo_observacion_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    unidad text,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dominio_hallazgo_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.dominio_hallazgo_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    profesion_origen text,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: estado_maquina_config; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.estado_maquina_config (
    tabla text NOT NULL,
    tipo_maquina text NOT NULL,
    enforcement text NOT NULL,
    descripcion text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT estado_maquina_config_enforcement_check CHECK ((enforcement = ANY (ARRAY['full'::text, 'soft'::text, 'none'::text]))),
    CONSTRAINT estado_maquina_config_tipo_maquina_check CHECK ((tipo_maquina = ANY (ARRAY['visita'::text, 'estadia'::text])))
);


--
-- Name: kb_categoria_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.kb_categoria_ref (
    codigo text NOT NULL,
    nombre text NOT NULL,
    descripcion text,
    icon text,
    orden smallint DEFAULT 0
);


--
-- Name: maquina_estados_estadia_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.maquina_estados_estadia_ref (
    from_state text NOT NULL,
    to_state text NOT NULL,
    proceso_opm text,
    descripcion text
);


--
-- Name: maquina_estados_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.maquina_estados_ref (
    from_state text NOT NULL,
    to_state text NOT NULL,
    trigger text,
    actor text
);


--
-- Name: ubicacion; Type: TABLE; Schema: territorial; Owner: -
--

CREATE TABLE territorial.ubicacion (
    location_id text NOT NULL,
    nombre_oficial text,
    comuna text,
    tipo text,
    latitud real,
    longitud real,
    zone_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ubicacion_tipo_check CHECK (((tipo IS NULL) OR (tipo = ANY (ARRAY['URBANO'::text, 'PERIURBANO'::text, 'RURAL'::text, 'RURAL_AISLADO'::text]))))
);


--
-- Name: mv_kpi_diario; Type: MATERIALIZED VIEW; Schema: reference; Owner: -
--

CREATE MATERIALIZED VIEW reference.mv_kpi_diario AS
 SELECT v.fecha,
    u.zone_id,
    e.establecimiento_id,
    count(DISTINCT v.visit_id) AS total_visitas,
    count(DISTINCT v.visit_id) FILTER (WHERE (v.estado = ANY (ARRAY['COMPLETA'::text, 'DOCUMENTADA'::text, 'VERIFICADA'::text, 'REPORTADA_REM'::text]))) AS visitas_realizadas,
    count(DISTINCT v.visit_id) FILTER (WHERE (v.estado = 'CANCELADA'::text)) AS visitas_canceladas,
    count(DISTINCT v.patient_id) AS pacientes_atendidos,
    count(DISTINCT v.stay_id) AS estadias_atendidas
   FROM ((operational.visita v
     JOIN clinical.estadia e ON ((v.stay_id = e.stay_id)))
     LEFT JOIN territorial.ubicacion u ON ((v.location_id = u.location_id)))
  WHERE (v.rem_reportable = true)
  GROUP BY v.fecha, u.zone_id, e.establecimiento_id
  WITH NO DATA;


--
-- Name: mv_rem_personas_atendidas; Type: MATERIALIZED VIEW; Schema: reference; Owner: -
--

CREATE MATERIALIZED VIEW reference.mv_rem_personas_atendidas AS
 SELECT to_char((v.fecha)::timestamp with time zone, 'YYYY-MM'::text) AS periodo,
    e.establecimiento_id,
    pr.profesion_rem,
    count(DISTINCT v.visit_id) AS total_visitas,
    count(DISTINCT v.patient_id) AS personas_atendidas,
    count(DISTINCT v.stay_id) AS estadias_atendidas,
    count(DISTINCT
        CASE
            WHEN (to_char((e.fecha_ingreso)::timestamp with time zone, 'YYYY-MM'::text) = to_char((v.fecha)::timestamp with time zone, 'YYYY-MM'::text)) THEN e.stay_id
            ELSE NULL::text
        END) AS total_ingresos,
    count(DISTINCT
        CASE
            WHEN ((e.fecha_egreso IS NOT NULL) AND (to_char((e.fecha_egreso)::timestamp with time zone, 'YYYY-MM'::text) = to_char((v.fecha)::timestamp with time zone, 'YYYY-MM'::text))) THEN e.stay_id
            ELSE NULL::text
        END) AS total_egresos
   FROM ((operational.visita v
     JOIN clinical.estadia e ON ((v.stay_id = e.stay_id)))
     LEFT JOIN operational.profesional pr ON ((v.provider_id = pr.provider_id)))
  WHERE (v.rem_reportable = true)
  GROUP BY (to_char((v.fecha)::timestamp with time zone, 'YYYY-MM'::text)), e.establecimiento_id, pr.profesion_rem
  WITH NO DATA;


--
-- Name: telemetria_dispositivo; Type: TABLE; Schema: telemetry; Owner: -
--

CREATE TABLE telemetry.telemetria_dispositivo (
    device_id text NOT NULL,
    vehiculo_id text,
    nombre text,
    plataforma text,
    imei text,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: telemetria_resumen_diario; Type: TABLE; Schema: telemetry; Owner: -
--

CREATE TABLE telemetry.telemetria_resumen_diario (
    resumen_id text NOT NULL,
    device_id text NOT NULL,
    route_id text,
    provider_id text,
    conductor_id text,
    fecha date NOT NULL,
    km_totales real DEFAULT 0,
    minutos_drive real DEFAULT 0,
    minutos_stop real DEFAULT 0,
    n_segmentos_drive integer DEFAULT 0,
    n_segmentos_stop integer DEFAULT 0,
    n_stops_significativos integer DEFAULT 0,
    velocidad_max_kmh real,
    primer_movimiento timestamp with time zone,
    ultimo_movimiento timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: telemetria_segmento; Type: TABLE; Schema: telemetry; Owner: -
--

CREATE TABLE telemetry.telemetria_segmento (
    segment_id text NOT NULL,
    device_id text NOT NULL,
    route_id text,
    visit_id text,
    tipo text NOT NULL,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone,
    start_lat real,
    start_lng real,
    end_lat real,
    end_lng real,
    distancia_km real,
    duracion_seg integer,
    velocidad_max_kmh real,
    geofences_in jsonb,
    correlacion_score real,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT telemetria_segmento_tipo_check CHECK ((tipo = ANY (ARRAY['drive'::text, 'stop'::text])))
);


--
-- Name: mv_telemetria_kpi_diario; Type: MATERIALIZED VIEW; Schema: reference; Owner: -
--

CREATE MATERIALIZED VIEW reference.mv_telemetria_kpi_diario AS
 SELECT trd.fecha,
    trd.device_id,
    td.vehiculo_id,
    trd.provider_id,
    trd.km_totales,
    trd.minutos_drive,
    trd.minutos_stop,
    trd.n_segmentos_drive,
    trd.n_segmentos_stop,
    trd.n_stops_significativos,
    trd.velocidad_max_kmh,
    ( SELECT count(*) AS count
           FROM (operational.visita v
             JOIN operational.ruta r ON ((v.route_id = r.route_id)))
          WHERE ((r.route_id = trd.route_id) AND (v.rem_reportable = true))) AS visitas_rem_ruta,
    ( SELECT count(*) AS count
           FROM telemetry.telemetria_segmento ts
          WHERE ((ts.device_id = trd.device_id) AND ((ts.start_at)::date = trd.fecha) AND (ts.tipo = 'stop'::text) AND (ts.visit_id IS NOT NULL))) AS stops_correlacionados
   FROM (telemetry.telemetria_resumen_diario trd
     LEFT JOIN telemetry.telemetria_dispositivo td ON ((trd.device_id = td.device_id)))
  WITH NO DATA;


--
-- Name: prioridad_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.prioridad_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    orden integer NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: service_type_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.service_type_ref (
    service_type text NOT NULL,
    descripcion text NOT NULL,
    profesion_requerida text,
    rem_reportable boolean DEFAULT true,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT service_type_ref_profesion_requerida_check CHECK (((profesion_requerida IS NULL) OR (profesion_requerida = ANY (ARRAY['ENFERMERIA'::text, 'KINESIOLOGIA'::text, 'FONOAUDIOLOGIA'::text, 'MEDICO'::text, 'TRABAJO_SOCIAL'::text, 'TENS'::text, 'NUTRICION'::text, 'MATRONA'::text, 'PSICOLOGIA'::text, 'TERAPIA_OCUPACIONAL'::text]))))
);


--
-- Name: tema_educacion_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.tema_educacion_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_documento_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.tipo_documento_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_evento_adverso_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.tipo_evento_adverso_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    notificable boolean DEFAULT false,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_requerimiento_ref; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.tipo_requerimiento_ref (
    codigo text NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: v_consolidado_atenciones_diarias; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_consolidado_atenciones_diarias AS
 SELECT v.fecha,
    v.stay_id,
    v.patient_id,
    p.nombre_completo,
    p.rut,
    v.provider_id,
    pr.nombre AS profesional_nombre,
    pr.profesion,
    pr.profesion_rem,
    v.estado,
    v.resultado,
    v.hora_real_inicio,
    v.hora_real_fin,
    v.location_id,
    v.route_id,
    v.rem_reportable,
    v.prestacion_id
   FROM ((operational.visita v
     JOIN clinical.paciente p ON ((v.patient_id = p.patient_id)))
     LEFT JOIN operational.profesional pr ON ((v.provider_id = pr.provider_id)))
  WHERE (v.rem_reportable = true);


--
-- Name: v_egresos_sin_epicrisis; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_egresos_sin_epicrisis AS
 SELECT e.stay_id,
    e.patient_id,
    p.nombre_completo,
    e.fecha_ingreso,
    e.fecha_egreso,
    e.tipo_egreso,
    e.estado
   FROM ((clinical.estadia e
     JOIN clinical.paciente p ON ((e.patient_id = p.patient_id)))
     LEFT JOIN clinical.epicrisis ep ON ((e.stay_id = ep.stay_id)))
  WHERE ((e.estado = ANY (ARRAY['egresado'::text, 'fallecido'::text])) AND (ep.epicrisis_id IS NULL));


--
-- Name: v_pacientes_activos; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_pacientes_activos AS
 SELECT p.patient_id,
    p.nombre_completo,
    p.rut,
    p.sexo,
    p.fecha_nacimiento,
    p.comuna,
    p.cesfam,
    p.estado_actual,
    e.stay_id,
    e.fecha_ingreso,
    e.estado AS estado_estadia,
    e.diagnostico_principal,
    e.establecimiento_id,
    e.origen_derivacion,
    (CURRENT_DATE - e.fecha_ingreso) AS dias_estadia
   FROM (clinical.paciente p
     JOIN clinical.estadia e ON ((p.patient_id = e.patient_id)))
  WHERE (e.estado = 'activo'::text);


--
-- Name: v_pe1_violations; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_pe1_violations AS
 SELECT 'visita'::text AS tabla,
    v.visit_id AS record_id,
    v.patient_id AS record_patient_id,
    e.patient_id AS estadia_patient_id,
    v.stay_id
   FROM (operational.visita v
     JOIN clinical.estadia e ON ((v.stay_id = e.stay_id)))
  WHERE (v.patient_id IS DISTINCT FROM e.patient_id)
UNION ALL
 SELECT 'orden_servicio'::text AS tabla,
    os.order_id AS record_id,
    os.patient_id AS record_patient_id,
    e.patient_id AS estadia_patient_id,
    os.stay_id
   FROM (operational.orden_servicio os
     JOIN clinical.estadia e ON ((os.stay_id = e.stay_id)))
  WHERE (os.patient_id IS DISTINCT FROM e.patient_id)
UNION ALL
 SELECT 'epicrisis'::text AS tabla,
    ep.epicrisis_id AS record_id,
    ep.patient_id AS record_patient_id,
    e.patient_id AS estadia_patient_id,
    ep.stay_id
   FROM (clinical.epicrisis ep
     JOIN clinical.estadia e ON ((ep.stay_id = e.stay_id)))
  WHERE (ep.patient_id IS DISTINCT FROM e.patient_id);


--
-- Name: v_telemetria_ruta_comparacion; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_telemetria_ruta_comparacion AS
 SELECT r.route_id,
    r.fecha,
    r.provider_id,
    pr.nombre AS profesional_nombre,
    r.km_totales AS ruta_km,
    r.minutos_viaje AS ruta_min_viaje,
    r.minutos_atencion AS ruta_min_atencion,
    trd.km_totales AS gps_km,
    trd.minutos_drive AS gps_min_drive,
    trd.minutos_stop AS gps_min_stop,
    trd.n_stops_significativos,
        CASE
            WHEN (r.km_totales > (0)::double precision) THEN round((((trd.km_totales / r.km_totales) * (100)::double precision))::numeric, 1)
            ELSE NULL::numeric
        END AS pct_km_match
   FROM ((operational.ruta r
     LEFT JOIN telemetry.telemetria_resumen_diario trd ON ((r.route_id = trd.route_id)))
     LEFT JOIN operational.profesional pr ON ((r.provider_id = pr.provider_id)));


--
-- Name: v_telemetria_stops_correlacionados; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_telemetria_stops_correlacionados AS
 SELECT ts.segment_id,
    ts.device_id,
    ts.start_at,
    ts.end_at,
    ts.duracion_seg,
    ts.start_lat,
    ts.start_lng,
    ts.visit_id,
    v.patient_id,
    v.provider_id,
    v.fecha AS visita_fecha,
    v.estado AS visita_estado,
    ts.correlacion_score
   FROM (telemetry.telemetria_segmento ts
     JOIN operational.visita v ON ((ts.visit_id = v.visit_id)))
  WHERE ((ts.tipo = 'stop'::text) AND (ts.visit_id IS NOT NULL));


--
-- Name: v_telemetria_stops_sin_match; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.v_telemetria_stops_sin_match AS
 SELECT ts.segment_id,
    ts.device_id,
    ts.start_at,
    ts.end_at,
    ts.duracion_seg,
    ts.start_lat,
    ts.start_lng,
    ts.route_id,
    ts.geofences_in
   FROM telemetry.telemetria_segmento ts
  WHERE ((ts.tipo = 'stop'::text) AND (ts.visit_id IS NULL) AND (ts.duracion_seg > 300));


--
-- Name: actividad_profesional_diaria; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.actividad_profesional_diaria (
    fecha date NOT NULL,
    enfermeria integer DEFAULT 0,
    kinesiologia integer DEFAULT 0,
    fonoaudiologia integer DEFAULT 0,
    medico integer DEFAULT 0,
    tens integer DEFAULT 0,
    total integer GENERATED ALWAYS AS (((((enfermeria + kinesiologia) + fonoaudiologia) + medico) + tens)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: descomposicion_temporal; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.descomposicion_temporal (
    visit_id text NOT NULL,
    minutos_desplazamiento real,
    minutos_espera real,
    minutos_atencion real,
    minutos_documentacion real,
    minutos_total real,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: kpi_diario; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.kpi_diario (
    fecha date NOT NULL,
    zone_id text NOT NULL,
    establecimiento_id text,
    pacientes_activos integer DEFAULT 0,
    visitas_programadas integer DEFAULT 0,
    visitas_realizadas integer DEFAULT 0,
    visitas_canceladas integer DEFAULT 0,
    tasa_realizacion real,
    km_totales real DEFAULT 0,
    minutos_viaje real DEFAULT 0,
    minutos_atencion real DEFAULT 0,
    ratio_viaje_atencion real,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: rem_cupos; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.rem_cupos (
    periodo text NOT NULL,
    establecimiento_id text NOT NULL,
    componente text NOT NULL,
    cupos_programados integer DEFAULT 0,
    cupos_utilizados integer DEFAULT 0,
    porcentaje_uso real,
    dias_cama_disponibles integer DEFAULT 0,
    dias_cama_utilizados integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: rem_personas_atendidas; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.rem_personas_atendidas (
    periodo text NOT NULL,
    establecimiento_id text NOT NULL,
    componente text NOT NULL,
    total_ingresos integer DEFAULT 0,
    total_egresos integer DEFAULT 0,
    dias_cama integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: rem_visitas; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.rem_visitas (
    periodo text NOT NULL,
    establecimiento_id text NOT NULL,
    profesion_rem text NOT NULL,
    total_visitas integer DEFAULT 0,
    visitas_realizadas integer DEFAULT 0,
    visitas_canceladas integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reporte_cobertura; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.reporte_cobertura (
    cobertura_id text NOT NULL,
    patient_id text,
    order_id text,
    periodo text,
    visitas_planificadas integer DEFAULT 0,
    visitas_realizadas integer DEFAULT 0,
    visitas_canceladas integer DEFAULT 0,
    tasa_cobertura real,
    gap_identificado boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: v_resumen_mes; Type: VIEW; Schema: reporting; Owner: -
--

CREATE VIEW reporting.v_resumen_mes AS
 SELECT (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date AS periodo_inicio,
    (((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval) - '1 day'::interval))::date AS periodo_fin,
    (( SELECT count(*) AS count
           FROM clinical.estadia
          WHERE ((estadia.fecha_ingreso >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (estadia.fecha_ingreso < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)))))::integer AS ingresos,
    (( SELECT count(*) AS count
           FROM clinical.estadia
          WHERE ((estadia.fecha_egreso >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (estadia.fecha_egreso < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)) AND (estadia.tipo_egreso = ANY (ARRAY['alta_clinica'::text, 'renuncia_voluntaria'::text, 'alta_disciplinaria'::text])))))::integer AS altas,
    (( SELECT count(*) AS count
           FROM clinical.estadia
          WHERE ((estadia.fecha_egreso >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (estadia.fecha_egreso < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)) AND (estadia.tipo_egreso = ANY (ARRAY['fallecido_esperado'::text, 'fallecido_no_esperado'::text])))))::integer AS fallecidos,
    (( SELECT count(*) AS count
           FROM clinical.estadia
          WHERE ((estadia.fecha_egreso >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (estadia.fecha_egreso < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)) AND (estadia.tipo_egreso = 'reingreso'::text))))::integer AS reingresos,
    (( SELECT count(*) AS count
           FROM clinical.estadia
          WHERE (estadia.estado = ANY (ARRAY['activo'::text, 'admitido'::text]))))::integer AS activos_hoy,
    (( SELECT count(*) AS count
           FROM operational.visita
          WHERE ((visita.fecha >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (visita.fecha < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)) AND (visita.estado = ANY (ARRAY['COMPLETA'::text, 'DOCUMENTADA'::text, 'VERIFICADA'::text, 'REPORTADA_REM'::text])))))::integer AS visitas_mes;


--
-- Name: VIEW v_resumen_mes; Type: COMMENT; Schema: reporting; Owner: -
--

COMMENT ON VIEW reporting.v_resumen_mes IS 'Pantalla 1: resumen operacional del mes corriente';


--
-- Name: visita_prestacion; Type: TABLE; Schema: reporting; Owner: -
--

CREATE TABLE reporting.visita_prestacion (
    visit_id text NOT NULL,
    prestacion_id text NOT NULL,
    ordinal integer DEFAULT 1 NOT NULL
);


--
-- Name: hospitalizacion; Type: TABLE; Schema: strict; Owner: -
--

CREATE TABLE strict.hospitalizacion (
    id integer NOT NULL,
    rut_paciente text NOT NULL,
    fecha_ingreso date NOT NULL,
    fecha_egreso date
);


--
-- Name: hospitalizacion_id_seq; Type: SEQUENCE; Schema: strict; Owner: -
--

CREATE SEQUENCE strict.hospitalizacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hospitalizacion_id_seq; Type: SEQUENCE OWNED BY; Schema: strict; Owner: -
--

ALTER SEQUENCE strict.hospitalizacion_id_seq OWNED BY strict.hospitalizacion.id;


--
-- Name: paciente; Type: TABLE; Schema: strict; Owner: -
--

CREATE TABLE strict.paciente (
    rut text NOT NULL,
    nombre text NOT NULL,
    fecha_nacimiento date
);


--
-- Name: gps_posicion; Type: TABLE; Schema: telemetry; Owner: -
--

CREATE TABLE telemetry.gps_posicion (
    posicion_id text NOT NULL,
    device_id text NOT NULL,
    dt timestamp with time zone NOT NULL,
    latitud real NOT NULL,
    longitud real NOT NULL,
    altitude real,
    course real,
    speed real,
    distance real,
    total_distance real,
    motion boolean,
    ignition boolean,
    event text,
    accuracy real,
    alarm text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: posicion_actual; Type: TABLE; Schema: telemetry; Owner: -
--

CREATE TABLE telemetry.posicion_actual (
    device_id text NOT NULL,
    dt timestamp with time zone NOT NULL,
    latitud real NOT NULL,
    longitud real NOT NULL,
    speed real,
    course real,
    online text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: establecimiento; Type: TABLE; Schema: territorial; Owner: -
--

CREATE TABLE territorial.establecimiento (
    establecimiento_id text NOT NULL,
    nombre text NOT NULL,
    tipo text,
    comuna text,
    direccion text,
    servicio_salud text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT establecimiento_tipo_check CHECK (((tipo IS NULL) OR (tipo = ANY (ARRAY['hospital'::text, 'cesfam'::text, 'cecosf'::text, 'cec'::text, 'postas'::text, 'sapu'::text, 'sar'::text, 'cosam'::text, 'otro'::text]))))
);


--
-- Name: matriz_distancia; Type: TABLE; Schema: territorial; Owner: -
--

CREATE TABLE territorial.matriz_distancia (
    origin_zone_id text NOT NULL,
    dest_zone_id text NOT NULL,
    km real,
    minutos real,
    via text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: zona; Type: TABLE; Schema: territorial; Owner: -
--

CREATE TABLE territorial.zona (
    zone_id text NOT NULL,
    nombre text NOT NULL,
    tipo text,
    comunas jsonb,
    centroide_lat real,
    centroide_lng real,
    tiempo_acceso_min integer,
    conectividad text,
    capacidad_dia integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT zona_tipo_check CHECK ((tipo = ANY (ARRAY['URBANO'::text, 'PERIURBANO'::text, 'RURAL'::text, 'RURAL_AISLADO'::text])))
);


--
-- Name: hospitalizacion id; Type: DEFAULT; Schema: strict; Owner: -
--

ALTER TABLE ONLY strict.hospitalizacion ALTER COLUMN id SET DEFAULT nextval('strict.hospitalizacion_id_seq'::regclass);


--
-- Name: alerta alerta_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.alerta
    ADD CONSTRAINT alerta_pkey PRIMARY KEY (alerta_id);


--
-- Name: botiquin_domiciliario botiquin_domiciliario_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.botiquin_domiciliario
    ADD CONSTRAINT botiquin_domiciliario_pkey PRIMARY KEY (botiquin_item_id);


--
-- Name: chat_mensaje chat_mensaje_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.chat_mensaje
    ADD CONSTRAINT chat_mensaje_pkey PRIMARY KEY (chat_mensaje_id);


--
-- Name: checklist_ingreso checklist_ingreso_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.checklist_ingreso
    ADD CONSTRAINT checklist_ingreso_pkey PRIMARY KEY (checklist_item_id);


--
-- Name: condicion condicion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.condicion
    ADD CONSTRAINT condicion_pkey PRIMARY KEY (condition_id);


--
-- Name: consentimiento consentimiento_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.consentimiento
    ADD CONSTRAINT consentimiento_pkey PRIMARY KEY (consent_id);


--
-- Name: cuidador cuidador_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.cuidador
    ADD CONSTRAINT cuidador_pkey PRIMARY KEY (cuidador_id);


--
-- Name: derivacion_adjunto derivacion_adjunto_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion_adjunto
    ADD CONSTRAINT derivacion_adjunto_pkey PRIMARY KEY (adjunto_id);


--
-- Name: derivacion derivacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion
    ADD CONSTRAINT derivacion_pkey PRIMARY KEY (derivacion_id);


--
-- Name: derivacion derivacion_token_seguimiento_key; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion
    ADD CONSTRAINT derivacion_token_seguimiento_key UNIQUE (token_seguimiento);


--
-- Name: diagnostico_egreso diagnostico_egreso_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.diagnostico_egreso
    ADD CONSTRAINT diagnostico_egreso_pkey PRIMARY KEY (diag_id);


--
-- Name: dispensacion dispensacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispensacion
    ADD CONSTRAINT dispensacion_pkey PRIMARY KEY (dispensacion_id);


--
-- Name: dispositivo dispositivo_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispositivo
    ADD CONSTRAINT dispositivo_pkey PRIMARY KEY (device_id);


--
-- Name: documentacion documentacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.documentacion
    ADD CONSTRAINT documentacion_pkey PRIMARY KEY (doc_id);


--
-- Name: domicilio domicilio_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.domicilio
    ADD CONSTRAINT domicilio_pkey PRIMARY KEY (domicilio_id);


--
-- Name: educacion_paciente educacion_paciente_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT educacion_paciente_pkey PRIMARY KEY (educacion_id);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_pkey PRIMARY KEY (encuesta_id);


--
-- Name: epicrisis epicrisis_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.epicrisis
    ADD CONSTRAINT epicrisis_pkey PRIMARY KEY (epicrisis_id);


--
-- Name: equipo_medico equipo_medico_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.equipo_medico
    ADD CONSTRAINT equipo_medico_pkey PRIMARY KEY (equipo_id);


--
-- Name: estadia estadia_patient_id_daterange_excl; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.estadia
    ADD CONSTRAINT estadia_patient_id_daterange_excl EXCLUDE USING gist (patient_id WITH =, daterange(fecha_ingreso, COALESCE(fecha_egreso, '9999-12-31'::date), '[]'::text) WITH &&);


--
-- Name: estadia estadia_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.estadia
    ADD CONSTRAINT estadia_pkey PRIMARY KEY (stay_id);


--
-- Name: evaluacion_funcional evaluacion_funcional_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_funcional
    ADD CONSTRAINT evaluacion_funcional_pkey PRIMARY KEY (eval_id);


--
-- Name: evaluacion_paliativa evaluacion_paliativa_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_paliativa
    ADD CONSTRAINT evaluacion_paliativa_pkey PRIMARY KEY (eval_paliativa_id);


--
-- Name: evento_adverso evento_adverso_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT evento_adverso_pkey PRIMARY KEY (evento_id);


--
-- Name: domicilio excl_domicilio_principal_vigente; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.domicilio
    ADD CONSTRAINT excl_domicilio_principal_vigente EXCLUDE USING gist (patient_id WITH =, daterange(vigente_desde, vigente_hasta, '[)'::text) WITH &&) WHERE ((tipo = 'principal'::text));


--
-- Name: fotografia_clinica fotografia_clinica_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.fotografia_clinica
    ADD CONSTRAINT fotografia_clinica_pkey PRIMARY KEY (foto_id);


--
-- Name: garantia_ges garantia_ges_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.garantia_ges
    ADD CONSTRAINT garantia_ges_pkey PRIMARY KEY (ges_id);


--
-- Name: herida herida_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.herida
    ADD CONSTRAINT herida_pkey PRIMARY KEY (herida_id);


--
-- Name: indicacion_medica indicacion_medica_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.indicacion_medica
    ADD CONSTRAINT indicacion_medica_pkey PRIMARY KEY (indicacion_id);


--
-- Name: informe_social informe_social_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.informe_social
    ADD CONSTRAINT informe_social_pkey PRIMARY KEY (informe_id);


--
-- Name: interconsulta interconsulta_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.interconsulta
    ADD CONSTRAINT interconsulta_pkey PRIMARY KEY (interconsulta_id);


--
-- Name: lista_espera lista_espera_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT lista_espera_pkey PRIMARY KEY (espera_id);


--
-- Name: medicacion medicacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.medicacion
    ADD CONSTRAINT medicacion_pkey PRIMARY KEY (med_id);


--
-- Name: meta meta_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.meta
    ADD CONSTRAINT meta_pkey PRIMARY KEY (meta_id);


--
-- Name: necesidad_profesional necesidad_profesional_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.necesidad_profesional
    ADD CONSTRAINT necesidad_profesional_pkey PRIMARY KEY (need_id);


--
-- Name: nota_evolucion nota_evolucion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.nota_evolucion
    ADD CONSTRAINT nota_evolucion_pkey PRIMARY KEY (nota_id);


--
-- Name: notificacion_obligatoria notificacion_obligatoria_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.notificacion_obligatoria
    ADD CONSTRAINT notificacion_obligatoria_pkey PRIMARY KEY (notificacion_id);


--
-- Name: observacion observacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion
    ADD CONSTRAINT observacion_pkey PRIMARY KEY (obs_id);


--
-- Name: observacion_portal observacion_portal_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion_portal
    ADD CONSTRAINT observacion_portal_pkey PRIMARY KEY (obs_portal_id);


--
-- Name: oxigenoterapia_domiciliaria oxigenoterapia_domiciliaria_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.oxigenoterapia_domiciliaria
    ADD CONSTRAINT oxigenoterapia_domiciliaria_pkey PRIMARY KEY (oxigeno_id);


--
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (patient_id);


--
-- Name: plan_cuidado plan_cuidado_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.plan_cuidado
    ADD CONSTRAINT plan_cuidado_pkey PRIMARY KEY (plan_id);


--
-- Name: plan_ejercicios plan_ejercicios_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.plan_ejercicios
    ADD CONSTRAINT plan_ejercicios_pkey PRIMARY KEY (plan_id);


--
-- Name: portal_mensaje portal_mensaje_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.portal_mensaje
    ADD CONSTRAINT portal_mensaje_pkey PRIMARY KEY (mensaje_id);


--
-- Name: prestamo_equipo prestamo_equipo_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.prestamo_equipo
    ADD CONSTRAINT prestamo_equipo_pkey PRIMARY KEY (prestamo_id);


--
-- Name: procedimiento procedimiento_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.procedimiento
    ADD CONSTRAINT procedimiento_pkey PRIMARY KEY (proc_id);


--
-- Name: protocolo_fallecimiento protocolo_fallecimiento_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT protocolo_fallecimiento_pkey PRIMARY KEY (protocolo_id);


--
-- Name: receta receta_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (receta_id);


--
-- Name: requerimiento_cuidado requerimiento_cuidado_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.requerimiento_cuidado
    ADD CONSTRAINT requerimiento_cuidado_pkey PRIMARY KEY (req_id);


--
-- Name: resultado_examen resultado_examen_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.resultado_examen
    ADD CONSTRAINT resultado_examen_pkey PRIMARY KEY (resultado_id);


--
-- Name: seguimiento_dispositivo seguimiento_dispositivo_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_dispositivo
    ADD CONSTRAINT seguimiento_dispositivo_pkey PRIMARY KEY (seguimiento_id);


--
-- Name: seguimiento_herida seguimiento_herida_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_herida
    ADD CONSTRAINT seguimiento_herida_pkey PRIMARY KEY (seguimiento_id);


--
-- Name: sesion_rehabilitacion_item sesion_rehabilitacion_item_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion_item
    ADD CONSTRAINT sesion_rehabilitacion_item_pkey PRIMARY KEY (sesion_item_id);


--
-- Name: sesion_rehabilitacion sesion_rehabilitacion_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion
    ADD CONSTRAINT sesion_rehabilitacion_pkey PRIMARY KEY (sesion_id);


--
-- Name: sesion_videollamada sesion_videollamada_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_pkey PRIMARY KEY (sesion_id);


--
-- Name: sesion_videollamada sesion_videollamada_room_token_key; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_room_token_key UNIQUE (room_token);


--
-- Name: solicitud_examen solicitud_examen_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.solicitud_examen
    ADD CONSTRAINT solicitud_examen_pkey PRIMARY KEY (solicitud_id);


--
-- Name: teleconsulta teleconsulta_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.teleconsulta
    ADD CONSTRAINT teleconsulta_pkey PRIMARY KEY (teleconsulta_id);


--
-- Name: toma_muestra toma_muestra_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.toma_muestra
    ADD CONSTRAINT toma_muestra_pkey PRIMARY KEY (muestra_id);


--
-- Name: valoracion_hallazgo valoracion_hallazgo_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_hallazgo
    ADD CONSTRAINT valoracion_hallazgo_pkey PRIMARY KEY (hallazgo_id);


--
-- Name: valoracion_ingreso valoracion_ingreso_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_ingreso
    ADD CONSTRAINT valoracion_ingreso_pkey PRIMARY KEY (assessment_id);


--
-- Name: voluntad_anticipada voluntad_anticipada_pkey; Type: CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.voluntad_anticipada
    ADD CONSTRAINT voluntad_anticipada_pkey PRIMARY KEY (voluntad_id);


--
-- Name: agenda_profesional agenda_profesional_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.agenda_profesional
    ADD CONSTRAINT agenda_profesional_pkey PRIMARY KEY (schedule_id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (log_id);


--
-- Name: canasta_valorizada canasta_valorizada_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.canasta_valorizada
    ADD CONSTRAINT canasta_valorizada_pkey PRIMARY KEY (valorizacion_id);


--
-- Name: capacitacion capacitacion_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.capacitacion
    ADD CONSTRAINT capacitacion_pkey PRIMARY KEY (capacitacion_id);


--
-- Name: compra_servicio compra_servicio_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.compra_servicio
    ADD CONSTRAINT compra_servicio_pkey PRIMARY KEY (compra_id);


--
-- Name: conductor conductor_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.conductor
    ADD CONSTRAINT conductor_pkey PRIMARY KEY (conductor_id);


--
-- Name: configuracion_programa configuracion_programa_clave_key; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.configuracion_programa
    ADD CONSTRAINT configuracion_programa_clave_key UNIQUE (clave);


--
-- Name: configuracion_programa configuracion_programa_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.configuracion_programa
    ADD CONSTRAINT configuracion_programa_pkey PRIMARY KEY (config_id);


--
-- Name: decision_despacho decision_despacho_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.decision_despacho
    ADD CONSTRAINT decision_despacho_pkey PRIMARY KEY (decision_id);


--
-- Name: entrega_turno_paciente entrega_turno_paciente_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno_paciente
    ADD CONSTRAINT entrega_turno_paciente_pkey PRIMARY KEY (entrega_paciente_id);


--
-- Name: entrega_turno entrega_turno_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno
    ADD CONSTRAINT entrega_turno_pkey PRIMARY KEY (entrega_id);


--
-- Name: estadia_episodio_fuente estadia_episodio_fuente_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.estadia_episodio_fuente
    ADD CONSTRAINT estadia_episodio_fuente_pkey PRIMARY KEY (stay_id, episode_id);


--
-- Name: evento_estadia evento_estadia_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.evento_estadia
    ADD CONSTRAINT evento_estadia_pkey PRIMARY KEY (event_id);


--
-- Name: evento_visita evento_visita_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.evento_visita
    ADD CONSTRAINT evento_visita_pkey PRIMARY KEY (event_id);


--
-- Name: insumo insumo_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (item_id);


--
-- Name: kb_articulo_link kb_articulo_link_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_link
    ADD CONSTRAINT kb_articulo_link_pkey PRIMARY KEY (source_id, target_id);


--
-- Name: kb_articulo kb_articulo_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo
    ADD CONSTRAINT kb_articulo_pkey PRIMARY KEY (articulo_id);


--
-- Name: kb_articulo kb_articulo_slug_key; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo
    ADD CONSTRAINT kb_articulo_slug_key UNIQUE (slug);


--
-- Name: kb_articulo_tag kb_articulo_tag_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_tag
    ADD CONSTRAINT kb_articulo_tag_pkey PRIMARY KEY (articulo_id, tag_id);


--
-- Name: kb_articulo_version kb_articulo_version_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_version
    ADD CONSTRAINT kb_articulo_version_pkey PRIMARY KEY (version_id);


--
-- Name: kb_documento kb_documento_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_documento
    ADD CONSTRAINT kb_documento_pkey PRIMARY KEY (documento_id);


--
-- Name: kb_documento_tag kb_documento_tag_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_documento_tag
    ADD CONSTRAINT kb_documento_tag_pkey PRIMARY KEY (documento_id, tag_id);


--
-- Name: kb_tag kb_tag_nombre_key; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_tag
    ADD CONSTRAINT kb_tag_nombre_key UNIQUE (nombre);


--
-- Name: kb_tag kb_tag_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_tag
    ADD CONSTRAINT kb_tag_pkey PRIMARY KEY (tag_id);


--
-- Name: orden_servicio_insumo orden_servicio_insumo_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio_insumo
    ADD CONSTRAINT orden_servicio_insumo_pkey PRIMARY KEY (order_id, item_id);


--
-- Name: orden_servicio orden_servicio_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_pkey PRIMARY KEY (order_id);


--
-- Name: portal_acceso_log portal_acceso_log_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_acceso_log
    ADD CONSTRAINT portal_acceso_log_pkey PRIMARY KEY (log_id);


--
-- Name: portal_invitacion portal_invitacion_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_invitacion
    ADD CONSTRAINT portal_invitacion_pkey PRIMARY KEY (invitacion_id);


--
-- Name: portal_invitacion portal_invitacion_token_key; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_invitacion
    ADD CONSTRAINT portal_invitacion_token_key UNIQUE (token);


--
-- Name: portal_usuario portal_usuario_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_usuario
    ADD CONSTRAINT portal_usuario_pkey PRIMARY KEY (usuario_id);


--
-- Name: profesional profesional_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.profesional
    ADD CONSTRAINT profesional_pkey PRIMARY KEY (provider_id);


--
-- Name: push_subscription push_subscription_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.push_subscription
    ADD CONSTRAINT push_subscription_pkey PRIMARY KEY (sub_id);


--
-- Name: push_subscription push_subscription_usuario_id_endpoint_key; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.push_subscription
    ADD CONSTRAINT push_subscription_usuario_id_endpoint_key UNIQUE (usuario_id, endpoint);


--
-- Name: registro_llamada registro_llamada_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_llamada
    ADD CONSTRAINT registro_llamada_pkey PRIMARY KEY (llamada_id);


--
-- Name: registro_vehicular registro_vehicular_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_vehicular
    ADD CONSTRAINT registro_vehicular_pkey PRIMARY KEY (registro_id);


--
-- Name: requerimiento_orden_mapping requerimiento_orden_mapping_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.requerimiento_orden_mapping
    ADD CONSTRAINT requerimiento_orden_mapping_pkey PRIMARY KEY (req_id, order_id);


--
-- Name: reunion_equipo reunion_equipo_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.reunion_equipo
    ADD CONSTRAINT reunion_equipo_pkey PRIMARY KEY (reunion_id);


--
-- Name: ruta ruta_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.ruta
    ADD CONSTRAINT ruta_pkey PRIMARY KEY (route_id);


--
-- Name: sla sla_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.sla
    ADD CONSTRAINT sla_pkey PRIMARY KEY (sla_id);


--
-- Name: vehiculo vehiculo_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.vehiculo
    ADD CONSTRAINT vehiculo_pkey PRIMARY KEY (vehiculo_id);


--
-- Name: visita visita_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_pkey PRIMARY KEY (visit_id);


--
-- Name: zona_profesional zona_profesional_pkey; Type: CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.zona_profesional
    ADD CONSTRAINT zona_profesional_pkey PRIMARY KEY (zone_id, provider_id);


--
-- Name: catalogo_prestacion catalogo_prestacion_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.catalogo_prestacion
    ADD CONSTRAINT catalogo_prestacion_pkey PRIMARY KEY (prestacion_id);


--
-- Name: categoria_rehabilitacion_ref categoria_rehabilitacion_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.categoria_rehabilitacion_ref
    ADD CONSTRAINT categoria_rehabilitacion_ref_pkey PRIMARY KEY (codigo);


--
-- Name: codigo_observacion_ref codigo_observacion_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.codigo_observacion_ref
    ADD CONSTRAINT codigo_observacion_ref_pkey PRIMARY KEY (codigo);


--
-- Name: dominio_hallazgo_ref dominio_hallazgo_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.dominio_hallazgo_ref
    ADD CONSTRAINT dominio_hallazgo_ref_pkey PRIMARY KEY (codigo);


--
-- Name: estado_maquina_config estado_maquina_config_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.estado_maquina_config
    ADD CONSTRAINT estado_maquina_config_pkey PRIMARY KEY (tabla, tipo_maquina);


--
-- Name: kb_categoria_ref kb_categoria_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.kb_categoria_ref
    ADD CONSTRAINT kb_categoria_ref_pkey PRIMARY KEY (codigo);


--
-- Name: maquina_estados_estadia_ref maquina_estados_estadia_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.maquina_estados_estadia_ref
    ADD CONSTRAINT maquina_estados_estadia_ref_pkey PRIMARY KEY (from_state, to_state);


--
-- Name: maquina_estados_ref maquina_estados_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.maquina_estados_ref
    ADD CONSTRAINT maquina_estados_ref_pkey PRIMARY KEY (from_state, to_state);


--
-- Name: prioridad_ref prioridad_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.prioridad_ref
    ADD CONSTRAINT prioridad_ref_pkey PRIMARY KEY (codigo);


--
-- Name: service_type_ref service_type_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.service_type_ref
    ADD CONSTRAINT service_type_ref_pkey PRIMARY KEY (service_type);


--
-- Name: tema_educacion_ref tema_educacion_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.tema_educacion_ref
    ADD CONSTRAINT tema_educacion_ref_pkey PRIMARY KEY (codigo);


--
-- Name: tipo_documento_ref tipo_documento_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.tipo_documento_ref
    ADD CONSTRAINT tipo_documento_ref_pkey PRIMARY KEY (codigo);


--
-- Name: tipo_evento_adverso_ref tipo_evento_adverso_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.tipo_evento_adverso_ref
    ADD CONSTRAINT tipo_evento_adverso_ref_pkey PRIMARY KEY (codigo);


--
-- Name: tipo_requerimiento_ref tipo_requerimiento_ref_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.tipo_requerimiento_ref
    ADD CONSTRAINT tipo_requerimiento_ref_pkey PRIMARY KEY (codigo);


--
-- Name: actividad_profesional_diaria actividad_profesional_diaria_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.actividad_profesional_diaria
    ADD CONSTRAINT actividad_profesional_diaria_pkey PRIMARY KEY (fecha);


--
-- Name: descomposicion_temporal descomposicion_temporal_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.descomposicion_temporal
    ADD CONSTRAINT descomposicion_temporal_pkey PRIMARY KEY (visit_id);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_pkey PRIMARY KEY (encuesta_id);


--
-- Name: kpi_diario kpi_diario_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.kpi_diario
    ADD CONSTRAINT kpi_diario_pkey PRIMARY KEY (fecha, zone_id);


--
-- Name: rem_cupos rem_cupos_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_cupos
    ADD CONSTRAINT rem_cupos_pkey PRIMARY KEY (periodo, establecimiento_id, componente);


--
-- Name: rem_personas_atendidas rem_personas_atendidas_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_personas_atendidas
    ADD CONSTRAINT rem_personas_atendidas_pkey PRIMARY KEY (periodo, establecimiento_id, componente);


--
-- Name: rem_visitas rem_visitas_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_visitas
    ADD CONSTRAINT rem_visitas_pkey PRIMARY KEY (periodo, establecimiento_id, profesion_rem);


--
-- Name: reporte_cobertura reporte_cobertura_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.reporte_cobertura
    ADD CONSTRAINT reporte_cobertura_pkey PRIMARY KEY (cobertura_id);


--
-- Name: visita_prestacion visita_prestacion_pkey; Type: CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.visita_prestacion
    ADD CONSTRAINT visita_prestacion_pkey PRIMARY KEY (visit_id, prestacion_id);


--
-- Name: hospitalizacion hospitalizacion_pkey; Type: CONSTRAINT; Schema: strict; Owner: -
--

ALTER TABLE ONLY strict.hospitalizacion
    ADD CONSTRAINT hospitalizacion_pkey PRIMARY KEY (id);


--
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: strict; Owner: -
--

ALTER TABLE ONLY strict.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (rut);


--
-- Name: gps_posicion gps_posicion_pkey; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.gps_posicion
    ADD CONSTRAINT gps_posicion_pkey PRIMARY KEY (posicion_id);


--
-- Name: posicion_actual posicion_actual_pkey; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.posicion_actual
    ADD CONSTRAINT posicion_actual_pkey PRIMARY KEY (device_id);


--
-- Name: telemetria_dispositivo telemetria_dispositivo_pkey; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_dispositivo
    ADD CONSTRAINT telemetria_dispositivo_pkey PRIMARY KEY (device_id);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_device_id_fecha_key; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_device_id_fecha_key UNIQUE (device_id, fecha);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_pkey; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_pkey PRIMARY KEY (resumen_id);


--
-- Name: telemetria_segmento telemetria_segmento_pkey; Type: CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_segmento
    ADD CONSTRAINT telemetria_segmento_pkey PRIMARY KEY (segment_id);


--
-- Name: establecimiento establecimiento_pkey; Type: CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.establecimiento
    ADD CONSTRAINT establecimiento_pkey PRIMARY KEY (establecimiento_id);


--
-- Name: localizacion localizacion_pkey; Type: CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.localizacion
    ADD CONSTRAINT localizacion_pkey PRIMARY KEY (localizacion_id);


--
-- Name: matriz_distancia matriz_distancia_pkey; Type: CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.matriz_distancia
    ADD CONSTRAINT matriz_distancia_pkey PRIMARY KEY (origin_zone_id, dest_zone_id);


--
-- Name: ubicacion ubicacion_pkey; Type: CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.ubicacion
    ADD CONSTRAINT ubicacion_pkey PRIMARY KEY (location_id);


--
-- Name: zona zona_pkey; Type: CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.zona
    ADD CONSTRAINT zona_pkey PRIMARY KEY (zone_id);


--
-- Name: idx_alerta_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_alerta_paciente ON clinical.alerta USING btree (patient_id);


--
-- Name: idx_alerta_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_alerta_stay ON clinical.alerta USING btree (stay_id);


--
-- Name: idx_botiquin_domiciliario_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_botiquin_domiciliario_stay_id ON clinical.botiquin_domiciliario USING btree (stay_id);


--
-- Name: idx_botiquin_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_botiquin_paciente ON clinical.botiquin_domiciliario USING btree (patient_id);


--
-- Name: idx_chat_mensaje_created; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_chat_mensaje_created ON clinical.chat_mensaje USING btree (created_at DESC);


--
-- Name: idx_chat_mensaje_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_chat_mensaje_patient ON clinical.chat_mensaje USING btree (patient_id);


--
-- Name: idx_chat_mensaje_sesion; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_chat_mensaje_sesion ON clinical.chat_mensaje USING btree (sesion_id);


--
-- Name: idx_chat_mensaje_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_chat_mensaje_stay ON clinical.chat_mensaje USING btree (stay_id);


--
-- Name: idx_checklist_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_checklist_estadia ON clinical.checklist_ingreso USING btree (stay_id);


--
-- Name: idx_condicion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_condicion_estadia ON clinical.condicion USING btree (stay_id);


--
-- Name: idx_condicion_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_condicion_patient ON clinical.condicion USING btree (patient_id);


--
-- Name: idx_consentimiento_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_consentimiento_doc ON clinical.consentimiento USING btree (doc_id);


--
-- Name: idx_consentimiento_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_consentimiento_estadia ON clinical.consentimiento USING btree (stay_id);


--
-- Name: idx_consentimiento_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_consentimiento_paciente ON clinical.consentimiento USING btree (patient_id);


--
-- Name: idx_cuidador_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_cuidador_paciente ON clinical.cuidador USING btree (patient_id);


--
-- Name: idx_derivacion_adjunto_derivacion; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_adjunto_derivacion ON clinical.derivacion_adjunto USING btree (derivacion_id);


--
-- Name: idx_derivacion_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_doc ON clinical.derivacion USING btree (doc_id);


--
-- Name: idx_derivacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_estadia ON clinical.derivacion USING btree (stay_id);


--
-- Name: idx_derivacion_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_patient_id ON clinical.derivacion USING btree (patient_id);


--
-- Name: idx_derivacion_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_tipo ON clinical.derivacion USING btree (tipo);


--
-- Name: idx_derivacion_token; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_derivacion_token ON clinical.derivacion USING btree (token_seguimiento) WHERE (token_seguimiento IS NOT NULL);


--
-- Name: idx_diag_egreso_cie10; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_diag_egreso_cie10 ON clinical.diagnostico_egreso USING btree (codigo_cie10);


--
-- Name: idx_diag_egreso_epicrisis; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_diag_egreso_epicrisis ON clinical.diagnostico_egreso USING btree (epicrisis_id);


--
-- Name: idx_dispensacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_dispensacion_estadia ON clinical.dispensacion USING btree (stay_id);


--
-- Name: idx_dispensacion_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_dispensacion_patient_id ON clinical.dispensacion USING btree (patient_id);


--
-- Name: idx_dispensacion_receta; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_dispensacion_receta ON clinical.dispensacion USING btree (receta_id);


--
-- Name: idx_dispositivo_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_dispositivo_paciente ON clinical.dispositivo USING btree (patient_id);


--
-- Name: idx_documentacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_documentacion_estadia ON clinical.documentacion USING btree (stay_id);


--
-- Name: idx_documentacion_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_documentacion_paciente ON clinical.documentacion USING btree (patient_id);


--
-- Name: idx_documentacion_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_documentacion_tipo ON clinical.documentacion USING btree (tipo);


--
-- Name: idx_documentacion_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_documentacion_visita ON clinical.documentacion USING btree (visit_id);


--
-- Name: idx_domicilio_localizacion; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_domicilio_localizacion ON clinical.domicilio USING btree (localizacion_id);


--
-- Name: idx_domicilio_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_domicilio_paciente ON clinical.domicilio USING btree (patient_id);


--
-- Name: idx_domicilio_vigente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_domicilio_vigente ON clinical.domicilio USING btree (patient_id, vigente_hasta) WHERE (vigente_hasta IS NULL);


--
-- Name: idx_educacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_educacion_estadia ON clinical.educacion_paciente USING btree (stay_id);


--
-- Name: idx_educacion_paciente_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_educacion_paciente_patient_id ON clinical.educacion_paciente USING btree (patient_id);


--
-- Name: idx_educacion_tema; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_educacion_tema ON clinical.educacion_paciente USING btree (tema);


--
-- Name: idx_enc_clin_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_enc_clin_patient ON clinical.encuesta_satisfaccion USING btree (patient_id);


--
-- Name: idx_enc_clin_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_enc_clin_stay ON clinical.encuesta_satisfaccion USING btree (stay_id);


--
-- Name: idx_epicrisis_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_epicrisis_doc ON clinical.epicrisis USING btree (doc_id);


--
-- Name: idx_epicrisis_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_epicrisis_estadia ON clinical.epicrisis USING btree (stay_id);


--
-- Name: idx_epicrisis_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_epicrisis_paciente ON clinical.epicrisis USING btree (patient_id);


--
-- Name: idx_epicrisis_provider_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_epicrisis_provider_id ON clinical.epicrisis USING btree (provider_id);


--
-- Name: idx_equipo_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_equipo_estado ON clinical.equipo_medico USING btree (estado);


--
-- Name: idx_equipo_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_equipo_tipo ON clinical.equipo_medico USING btree (tipo);


--
-- Name: idx_estadia_activos; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_activos ON clinical.estadia USING btree (patient_id) WHERE (estado = 'activo'::text);


--
-- Name: idx_estadia_diagnostico_fts; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_diagnostico_fts ON clinical.estadia USING gin (to_tsvector('spanish'::regconfig, COALESCE(diagnostico_principal, ''::text)));


--
-- Name: idx_estadia_establecimiento; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_establecimiento ON clinical.estadia USING btree (establecimiento_id);


--
-- Name: idx_estadia_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_estado ON clinical.estadia USING btree (estado);


--
-- Name: idx_estadia_fechas; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_fechas ON clinical.estadia USING btree (fecha_ingreso, fecha_egreso);


--
-- Name: idx_estadia_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_estadia_paciente ON clinical.estadia USING btree (patient_id);


--
-- Name: idx_eval_func_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_eval_func_estadia ON clinical.evaluacion_funcional USING btree (stay_id);


--
-- Name: idx_eval_func_momento; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_eval_func_momento ON clinical.evaluacion_funcional USING btree (momento);


--
-- Name: idx_eval_paliativa_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_eval_paliativa_estadia ON clinical.evaluacion_paliativa USING btree (stay_id);


--
-- Name: idx_evaluacion_funcional_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evaluacion_funcional_patient_id ON clinical.evaluacion_funcional USING btree (patient_id);


--
-- Name: idx_evaluacion_paliativa_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evaluacion_paliativa_patient_id ON clinical.evaluacion_paliativa USING btree (patient_id);


--
-- Name: idx_evento_adverso_detectado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evento_adverso_detectado ON clinical.evento_adverso USING btree (detectado_por_id);


--
-- Name: idx_evento_adverso_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evento_adverso_paciente ON clinical.evento_adverso USING btree (patient_id);


--
-- Name: idx_evento_adverso_severidad; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evento_adverso_severidad ON clinical.evento_adverso USING btree (severidad);


--
-- Name: idx_evento_adverso_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evento_adverso_stay ON clinical.evento_adverso USING btree (stay_id);


--
-- Name: idx_evento_adverso_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_evento_adverso_tipo ON clinical.evento_adverso USING btree (tipo);


--
-- Name: idx_foto_clinica_herida; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_foto_clinica_herida ON clinical.fotografia_clinica USING btree (herida_id);


--
-- Name: idx_foto_clinica_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_foto_clinica_patient ON clinical.fotografia_clinica USING btree (patient_id);


--
-- Name: idx_foto_clinica_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_foto_clinica_stay ON clinical.fotografia_clinica USING btree (stay_id);


--
-- Name: idx_garantia_ges_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_garantia_ges_stay_id ON clinical.garantia_ges USING btree (stay_id);


--
-- Name: idx_ges_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_ges_paciente ON clinical.garantia_ges USING btree (patient_id);


--
-- Name: idx_hallazgo_assessment; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_hallazgo_assessment ON clinical.valoracion_hallazgo USING btree (assessment_id);


--
-- Name: idx_hallazgo_dominio; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_hallazgo_dominio ON clinical.valoracion_hallazgo USING btree (dominio);


--
-- Name: idx_herida_activas; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_herida_activas ON clinical.herida USING btree (patient_id) WHERE (estado = 'activa'::text);


--
-- Name: idx_herida_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_herida_estadia ON clinical.herida USING btree (stay_id);


--
-- Name: idx_herida_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_herida_estado ON clinical.herida USING btree (estado);


--
-- Name: idx_herida_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_herida_paciente ON clinical.herida USING btree (patient_id);


--
-- Name: idx_ic_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_ic_estadia ON clinical.interconsulta USING btree (stay_id);


--
-- Name: idx_ic_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_ic_estado ON clinical.interconsulta USING btree (estado);


--
-- Name: idx_indicacion_activas; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_activas ON clinical.indicacion_medica USING btree (stay_id) WHERE (estado = 'activa'::text);


--
-- Name: idx_indicacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_estadia ON clinical.indicacion_medica USING btree (stay_id);


--
-- Name: idx_indicacion_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_estado ON clinical.indicacion_medica USING btree (estado);


--
-- Name: idx_indicacion_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_patient ON clinical.indicacion_medica USING btree (patient_id);


--
-- Name: idx_indicacion_previa; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_previa ON clinical.indicacion_medica USING btree (indicacion_previa_id);


--
-- Name: idx_indicacion_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_indicacion_tipo ON clinical.indicacion_medica USING btree (tipo);


--
-- Name: idx_informe_social_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_informe_social_doc ON clinical.informe_social USING btree (doc_id);


--
-- Name: idx_informe_social_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_informe_social_estadia ON clinical.informe_social USING btree (stay_id);


--
-- Name: idx_informe_social_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_informe_social_patient_id ON clinical.informe_social USING btree (patient_id);


--
-- Name: idx_interconsulta_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_interconsulta_patient_id ON clinical.interconsulta USING btree (patient_id);


--
-- Name: idx_interconsulta_solicitante; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_interconsulta_solicitante ON clinical.interconsulta USING btree (solicitante_id);


--
-- Name: idx_lista_espera_establecimiento; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_establecimiento ON clinical.lista_espera USING btree (establecimiento_origen);


--
-- Name: idx_lista_espera_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_estado ON clinical.lista_espera USING btree (estado);


--
-- Name: idx_lista_espera_evaluador; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_evaluador ON clinical.lista_espera USING btree (evaluador_id);


--
-- Name: idx_lista_espera_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_patient_id ON clinical.lista_espera USING btree (patient_id);


--
-- Name: idx_lista_espera_prioridad; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_prioridad ON clinical.lista_espera USING btree (prioridad);


--
-- Name: idx_lista_espera_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_lista_espera_stay ON clinical.lista_espera USING btree (stay_id);


--
-- Name: idx_medicacion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_medicacion_estadia ON clinical.medicacion USING btree (stay_id);


--
-- Name: idx_meta_plan; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_meta_plan ON clinical.meta USING btree (plan_id);


--
-- Name: idx_muestra_solicitud; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_muestra_solicitud ON clinical.toma_muestra USING btree (solicitud_id);


--
-- Name: idx_nec_prof_plan; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_nec_prof_plan ON clinical.necesidad_profesional USING btree (plan_id);


--
-- Name: idx_nota_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_nota_estadia ON clinical.nota_evolucion USING btree (stay_id);


--
-- Name: idx_nota_evolucion_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_nota_evolucion_patient_id ON clinical.nota_evolucion USING btree (patient_id);


--
-- Name: idx_nota_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_nota_tipo ON clinical.nota_evolucion USING btree (tipo);


--
-- Name: idx_nota_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_nota_visita ON clinical.nota_evolucion USING btree (visit_id);


--
-- Name: idx_notificacion_notificador; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_notificacion_notificador ON clinical.notificacion_obligatoria USING btree (notificador_id);


--
-- Name: idx_notificacion_obligatoria_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_notificacion_obligatoria_patient_id ON clinical.notificacion_obligatoria USING btree (patient_id);


--
-- Name: idx_notificacion_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_notificacion_stay ON clinical.notificacion_obligatoria USING btree (stay_id);


--
-- Name: idx_notificacion_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_notificacion_tipo ON clinical.notificacion_obligatoria USING btree (tipo);


--
-- Name: idx_o2_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_o2_estado ON clinical.oxigenoterapia_domiciliaria USING btree (estado);


--
-- Name: idx_o2_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_o2_paciente ON clinical.oxigenoterapia_domiciliaria USING btree (patient_id);


--
-- Name: idx_obs_portal_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_obs_portal_patient ON clinical.observacion_portal USING btree (patient_id);


--
-- Name: idx_obs_portal_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_obs_portal_stay ON clinical.observacion_portal USING btree (stay_id);


--
-- Name: idx_observacion_codigo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_observacion_codigo ON clinical.observacion USING btree (codigo);


--
-- Name: idx_observacion_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_observacion_patient_id ON clinical.observacion USING btree (patient_id);


--
-- Name: idx_observacion_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_observacion_stay_id ON clinical.observacion USING btree (stay_id);


--
-- Name: idx_observacion_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_observacion_visita ON clinical.observacion USING btree (visit_id);


--
-- Name: idx_oxigenoterapia_domiciliaria_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_oxigenoterapia_domiciliaria_stay_id ON clinical.oxigenoterapia_domiciliaria USING btree (stay_id);


--
-- Name: idx_oxigenoterapia_equipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_oxigenoterapia_equipo ON clinical.oxigenoterapia_domiciliaria USING btree (equipo_id);


--
-- Name: idx_paciente_active; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_paciente_active ON clinical.paciente USING btree (patient_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_paciente_nombre; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_paciente_nombre ON clinical.paciente USING btree (nombre_completo);


--
-- Name: idx_paciente_nombre_fts; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_paciente_nombre_fts ON clinical.paciente USING gin (to_tsvector('spanish'::regconfig, nombre_completo));


--
-- Name: idx_paciente_rut; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_paciente_rut ON clinical.paciente USING btree (rut);


--
-- Name: idx_plan_cuidado_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_plan_cuidado_estadia ON clinical.plan_cuidado USING btree (stay_id);


--
-- Name: idx_plan_ejercicios_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_plan_ejercicios_patient ON clinical.plan_ejercicios USING btree (patient_id);


--
-- Name: idx_plan_ejercicios_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_plan_ejercicios_stay ON clinical.plan_ejercicios USING btree (stay_id);


--
-- Name: idx_portal_mensaje_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_portal_mensaje_estado ON clinical.portal_mensaje USING btree (estado);


--
-- Name: idx_portal_mensaje_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_portal_mensaje_patient ON clinical.portal_mensaje USING btree (patient_id);


--
-- Name: idx_portal_mensaje_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_portal_mensaje_stay ON clinical.portal_mensaje USING btree (stay_id);


--
-- Name: idx_prestamo_activos; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_activos ON clinical.prestamo_equipo USING btree (patient_id) WHERE (estado = 'prestado'::text);


--
-- Name: idx_prestamo_entregado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_entregado ON clinical.prestamo_equipo USING btree (entregado_por);


--
-- Name: idx_prestamo_equipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_equipo ON clinical.prestamo_equipo USING btree (equipo_id);


--
-- Name: idx_prestamo_equipo_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_equipo_stay_id ON clinical.prestamo_equipo USING btree (stay_id);


--
-- Name: idx_prestamo_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_estado ON clinical.prestamo_equipo USING btree (estado);


--
-- Name: idx_prestamo_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_prestamo_paciente ON clinical.prestamo_equipo USING btree (patient_id);


--
-- Name: idx_procedimiento_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_procedimiento_estadia ON clinical.procedimiento USING btree (stay_id);


--
-- Name: idx_procedimiento_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_procedimiento_patient_id ON clinical.procedimiento USING btree (patient_id);


--
-- Name: idx_procedimiento_prestacion; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_procedimiento_prestacion ON clinical.procedimiento USING btree (prestacion_id);


--
-- Name: idx_procedimiento_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_procedimiento_visita ON clinical.procedimiento USING btree (visit_id);


--
-- Name: idx_protocolo_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_protocolo_doc ON clinical.protocolo_fallecimiento USING btree (doc_id);


--
-- Name: idx_protocolo_epicrisis; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_protocolo_epicrisis ON clinical.protocolo_fallecimiento USING btree (epicrisis_id);


--
-- Name: idx_protocolo_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_protocolo_estadia ON clinical.protocolo_fallecimiento USING btree (stay_id);


--
-- Name: idx_protocolo_fallecimiento_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_protocolo_fallecimiento_patient_id ON clinical.protocolo_fallecimiento USING btree (patient_id);


--
-- Name: idx_receta_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_receta_estadia ON clinical.receta USING btree (stay_id);


--
-- Name: idx_receta_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_receta_estado ON clinical.receta USING btree (estado);


--
-- Name: idx_receta_indicacion; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_receta_indicacion ON clinical.receta USING btree (indicacion_id);


--
-- Name: idx_receta_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_receta_patient_id ON clinical.receta USING btree (patient_id);


--
-- Name: idx_req_cuidado_plan; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_req_cuidado_plan ON clinical.requerimiento_cuidado USING btree (plan_id);


--
-- Name: idx_resultado_examen_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_resultado_examen_doc ON clinical.resultado_examen USING btree (doc_id);


--
-- Name: idx_resultado_solicitud; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_resultado_solicitud ON clinical.resultado_examen USING btree (solicitud_id);


--
-- Name: idx_seg_dispositivo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seg_dispositivo ON clinical.seguimiento_dispositivo USING btree (device_id);


--
-- Name: idx_seg_dispositivo_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seg_dispositivo_visita ON clinical.seguimiento_dispositivo USING btree (visit_id);


--
-- Name: idx_seg_herida; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seg_herida ON clinical.seguimiento_herida USING btree (herida_id);


--
-- Name: idx_seg_herida_fecha; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seg_herida_fecha ON clinical.seguimiento_herida USING btree (fecha);


--
-- Name: idx_seguimiento_dispositivo_provider_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seguimiento_dispositivo_provider_id ON clinical.seguimiento_dispositivo USING btree (provider_id);


--
-- Name: idx_seguimiento_herida_visit_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_seguimiento_herida_visit_id ON clinical.seguimiento_herida USING btree (visit_id);


--
-- Name: idx_sesion_item; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_item ON clinical.sesion_rehabilitacion_item USING btree (sesion_id);


--
-- Name: idx_sesion_rehab_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_rehab_estadia ON clinical.sesion_rehabilitacion USING btree (stay_id);


--
-- Name: idx_sesion_rehab_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_rehab_tipo ON clinical.sesion_rehabilitacion USING btree (tipo);


--
-- Name: idx_sesion_rehab_visita; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_rehab_visita ON clinical.sesion_rehabilitacion USING btree (visit_id);


--
-- Name: idx_sesion_rehabilitacion_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_rehabilitacion_patient_id ON clinical.sesion_rehabilitacion USING btree (patient_id);


--
-- Name: idx_sesion_video_telecons; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_video_telecons ON clinical.sesion_videollamada USING btree (teleconsulta_id);


--
-- Name: idx_sesion_videollamada_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_videollamada_estado ON clinical.sesion_videollamada USING btree (estado);


--
-- Name: idx_sesion_videollamada_patient; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_videollamada_patient ON clinical.sesion_videollamada USING btree (patient_id);


--
-- Name: idx_sesion_videollamada_room; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_videollamada_room ON clinical.sesion_videollamada USING btree (room_token);


--
-- Name: idx_sesion_videollamada_stay; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_sesion_videollamada_stay ON clinical.sesion_videollamada USING btree (stay_id);


--
-- Name: idx_solicitud_examen_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_solicitud_examen_estadia ON clinical.solicitud_examen USING btree (stay_id);


--
-- Name: idx_solicitud_examen_estado; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_solicitud_examen_estado ON clinical.solicitud_examen USING btree (estado);


--
-- Name: idx_solicitud_examen_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_solicitud_examen_patient_id ON clinical.solicitud_examen USING btree (patient_id);


--
-- Name: idx_solicitud_examen_solicitante; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_solicitud_examen_solicitante ON clinical.solicitud_examen USING btree (solicitante_id);


--
-- Name: idx_teleconsulta_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_teleconsulta_estadia ON clinical.teleconsulta USING btree (stay_id);


--
-- Name: idx_teleconsulta_fecha; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_teleconsulta_fecha ON clinical.teleconsulta USING btree (fecha);


--
-- Name: idx_teleconsulta_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_teleconsulta_patient_id ON clinical.teleconsulta USING btree (patient_id);


--
-- Name: idx_toma_muestra_tomador; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_toma_muestra_tomador ON clinical.toma_muestra USING btree (tomador_id);


--
-- Name: idx_valoracion_estadia; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_valoracion_estadia ON clinical.valoracion_ingreso USING btree (stay_id);


--
-- Name: idx_valoracion_ingreso_patient_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_valoracion_ingreso_patient_id ON clinical.valoracion_ingreso USING btree (patient_id);


--
-- Name: idx_valoracion_tipo; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_valoracion_tipo ON clinical.valoracion_ingreso USING btree (tipo);


--
-- Name: idx_voluntad_anticipada_stay_id; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_voluntad_anticipada_stay_id ON clinical.voluntad_anticipada USING btree (stay_id);


--
-- Name: idx_voluntad_doc; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_voluntad_doc ON clinical.voluntad_anticipada USING btree (doc_id);


--
-- Name: idx_voluntad_paciente; Type: INDEX; Schema: clinical; Owner: -
--

CREATE INDEX idx_voluntad_paciente ON clinical.voluntad_anticipada USING btree (patient_id);


--
-- Name: uq_provenance_key; Type: INDEX; Schema: migration; Owner: -
--

CREATE UNIQUE INDEX uq_provenance_key ON migration.provenance USING btree (target_table, target_pk, phase, COALESCE(field_name, ''::text));


--
-- Name: idx_agenda_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_agenda_fecha ON operational.agenda_profesional USING btree (fecha);


--
-- Name: idx_agenda_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_agenda_provider ON operational.agenda_profesional USING btree (provider_id);


--
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_audit_log_entidad ON operational.audit_log USING btree (entidad);


--
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_audit_log_timestamp ON operational.audit_log USING btree ("timestamp");


--
-- Name: idx_audit_log_user; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_audit_log_user ON operational.audit_log USING btree (user_id);


--
-- Name: idx_canasta_estadia; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_canasta_estadia ON operational.canasta_valorizada USING btree (stay_id);


--
-- Name: idx_canasta_periodo; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_canasta_periodo ON operational.canasta_valorizada USING btree (periodo);


--
-- Name: idx_canasta_valorizada_patient_id; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_canasta_valorizada_patient_id ON operational.canasta_valorizada USING btree (patient_id);


--
-- Name: idx_capacitacion_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_capacitacion_provider ON operational.capacitacion USING btree (provider_id);


--
-- Name: idx_compra_tipo; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_compra_tipo ON operational.compra_servicio USING btree (tipo_servicio);


--
-- Name: idx_conductor_vehiculo_asignado; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_conductor_vehiculo_asignado ON operational.conductor USING btree (vehiculo_asignado);


--
-- Name: idx_decision_despacho_prov; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_decision_despacho_prov ON operational.decision_despacho USING btree (provider_id);


--
-- Name: idx_despacho_visita; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_despacho_visita ON operational.decision_despacho USING btree (visit_id);


--
-- Name: idx_entrega_paciente; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_paciente ON operational.entrega_turno_paciente USING btree (entrega_id);


--
-- Name: idx_entrega_turno_entrante; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_turno_entrante ON operational.entrega_turno USING btree (turno_entrante_id);


--
-- Name: idx_entrega_turno_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_turno_fecha ON operational.entrega_turno USING btree (fecha);


--
-- Name: idx_entrega_turno_paciente_patient_id; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_turno_paciente_patient_id ON operational.entrega_turno_paciente USING btree (patient_id);


--
-- Name: idx_entrega_turno_paciente_stay_id; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_turno_paciente_stay_id ON operational.entrega_turno_paciente USING btree (stay_id);


--
-- Name: idx_entrega_turno_saliente; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_entrega_turno_saliente ON operational.entrega_turno USING btree (turno_saliente_id);


--
-- Name: idx_estadia_episodio; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_estadia_episodio ON operational.estadia_episodio_fuente USING btree (stay_id);


--
-- Name: idx_evento_estadia; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_evento_estadia ON operational.evento_estadia USING btree (stay_id);


--
-- Name: idx_evento_visita; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_evento_visita ON operational.evento_visita USING btree (visit_id);


--
-- Name: idx_kb_art_tag_tag; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_art_tag_tag ON operational.kb_articulo_tag USING btree (tag_id);


--
-- Name: idx_kb_articulo_busqueda; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_articulo_busqueda ON operational.kb_articulo USING gin (to_tsvector('spanish'::regconfig, ((((titulo || ' '::text) || COALESCE(resumen, ''::text)) || ' '::text) || contenido)));


--
-- Name: idx_kb_articulo_categoria; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_articulo_categoria ON operational.kb_articulo USING btree (categoria);


--
-- Name: idx_kb_articulo_estado; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_articulo_estado ON operational.kb_articulo USING btree (estado) WHERE (deleted_at IS NULL);


--
-- Name: idx_kb_doc_tag_tag; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_doc_tag_tag ON operational.kb_documento_tag USING btree (tag_id);


--
-- Name: idx_kb_documento_busqueda; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_documento_busqueda ON operational.kb_documento USING gin (to_tsvector('spanish'::regconfig, ((nombre || ' '::text) || COALESCE(descripcion, ''::text))));


--
-- Name: idx_kb_documento_categoria; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_documento_categoria ON operational.kb_documento USING btree (categoria);


--
-- Name: idx_kb_link_target; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_link_target ON operational.kb_articulo_link USING btree (target_id);


--
-- Name: idx_kb_version_articulo; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_kb_version_articulo ON operational.kb_articulo_version USING btree (articulo_id, version DESC);


--
-- Name: idx_llamada_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_llamada_fecha ON operational.registro_llamada USING btree (fecha);


--
-- Name: idx_llamada_paciente; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_llamada_paciente ON operational.registro_llamada USING btree (patient_id);


--
-- Name: idx_llamada_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_llamada_provider ON operational.registro_llamada USING btree (provider_id);


--
-- Name: idx_orden_estadia; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_orden_estadia ON operational.orden_servicio USING btree (stay_id);


--
-- Name: idx_orden_paciente; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_orden_paciente ON operational.orden_servicio USING btree (patient_id);


--
-- Name: idx_orden_service_type; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_orden_service_type ON operational.orden_servicio USING btree (service_type);


--
-- Name: idx_orden_servicio_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_orden_servicio_provider ON operational.orden_servicio USING btree (provider_asignado);


--
-- Name: idx_os_insumo_item; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_os_insumo_item ON operational.orden_servicio_insumo USING btree (item_id);


--
-- Name: idx_portal_acceso_usuario; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_portal_acceso_usuario ON operational.portal_acceso_log USING btree (usuario_id);


--
-- Name: idx_portal_invitacion_token; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_portal_invitacion_token ON operational.portal_invitacion USING btree (token);


--
-- Name: idx_portal_usr_invitado; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_portal_usr_invitado ON operational.portal_usuario USING btree (invitado_por);


--
-- Name: idx_portal_usuario_email; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_portal_usuario_email ON operational.portal_usuario USING btree (email);


--
-- Name: idx_portal_usuario_email_unique; Type: INDEX; Schema: operational; Owner: -
--

CREATE UNIQUE INDEX idx_portal_usuario_email_unique ON operational.portal_usuario USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: idx_portal_usuario_patient; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_portal_usuario_patient ON operational.portal_usuario USING btree (patient_id);


--
-- Name: idx_profesional_active; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_profesional_active ON operational.profesional USING btree (provider_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_profesional_profesion; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_profesional_profesion ON operational.profesional USING btree (profesion);


--
-- Name: idx_push_sub_usuario; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_push_sub_usuario ON operational.push_subscription USING btree (usuario_id);


--
-- Name: idx_reg_vehicular_route; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_reg_vehicular_route ON operational.registro_vehicular USING btree (route_id);


--
-- Name: idx_registro_vehicular_conductor; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_registro_vehicular_conductor ON operational.registro_vehicular USING btree (conductor_id);


--
-- Name: idx_registro_vehicular_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_registro_vehicular_fecha ON operational.registro_vehicular USING btree (fecha);


--
-- Name: idx_req_orden_order; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_req_orden_order ON operational.requerimiento_orden_mapping USING btree (order_id);


--
-- Name: idx_reunion_acta_doc; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_reunion_acta_doc ON operational.reunion_equipo USING btree (acta_doc_id);


--
-- Name: idx_reunion_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_reunion_fecha ON operational.reunion_equipo USING btree (fecha);


--
-- Name: idx_ruta_conductor; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_ruta_conductor ON operational.ruta USING btree (conductor_id);


--
-- Name: idx_ruta_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_ruta_fecha ON operational.ruta USING btree (fecha);


--
-- Name: idx_ruta_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_ruta_provider ON operational.ruta USING btree (provider_id);


--
-- Name: idx_ruta_vehiculo; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_ruta_vehiculo ON operational.ruta USING btree (vehiculo_id);


--
-- Name: idx_sla_lookup; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_sla_lookup ON operational.sla USING btree (service_type, prioridad);


--
-- Name: idx_visita_domicilio; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_domicilio ON operational.visita USING btree (domicilio_id);


--
-- Name: idx_visita_estadia; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_estadia ON operational.visita USING btree (stay_id);


--
-- Name: idx_visita_estado; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_estado ON operational.visita USING btree (estado);


--
-- Name: idx_visita_fecha; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_fecha ON operational.visita USING btree (fecha);


--
-- Name: idx_visita_order; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_order ON operational.visita USING btree (order_id);


--
-- Name: idx_visita_paciente; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_paciente ON operational.visita USING btree (patient_id);


--
-- Name: idx_visita_pendientes; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_pendientes ON operational.visita USING btree (fecha, stay_id) WHERE (estado = ANY (ARRAY['PROGRAMADA'::text, 'ASIGNADA'::text]));


--
-- Name: idx_visita_prestacion; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_prestacion ON operational.visita USING btree (prestacion_id);


--
-- Name: idx_visita_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_provider ON operational.visita USING btree (provider_id);


--
-- Name: idx_visita_rem; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_rem ON operational.visita USING btree (rem_reportable, fecha);


--
-- Name: idx_visita_ruta; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_visita_ruta ON operational.visita USING btree (route_id);


--
-- Name: idx_zona_prof_provider; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_zona_prof_provider ON operational.zona_profesional USING btree (provider_id);


--
-- Name: idx_zona_profesional_zone; Type: INDEX; Schema: operational; Owner: -
--

CREATE INDEX idx_zona_profesional_zone ON operational.zona_profesional USING btree (zone_id);


--
-- Name: idx_catalogo_prestacion_mai; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_catalogo_prestacion_mai ON reference.catalogo_prestacion USING btree (codigo_mai);


--
-- Name: idx_mv_kpi_diario; Type: INDEX; Schema: reference; Owner: -
--

CREATE UNIQUE INDEX idx_mv_kpi_diario ON reference.mv_kpi_diario USING btree (fecha, zone_id, establecimiento_id);


--
-- Name: idx_mv_rem_personas; Type: INDEX; Schema: reference; Owner: -
--

CREATE UNIQUE INDEX idx_mv_rem_personas ON reference.mv_rem_personas_atendidas USING btree (periodo, establecimiento_id, profesion_rem);


--
-- Name: idx_mv_telemetria_kpi; Type: INDEX; Schema: reference; Owner: -
--

CREATE UNIQUE INDEX idx_mv_telemetria_kpi ON reference.mv_telemetria_kpi_diario USING btree (fecha, device_id);


--
-- Name: idx_encuesta_patient; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_encuesta_patient ON reporting.encuesta_satisfaccion USING btree (patient_id);


--
-- Name: idx_encuesta_stay; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_encuesta_stay ON reporting.encuesta_satisfaccion USING btree (stay_id);


--
-- Name: idx_kpi_diario_establecimiento; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_kpi_diario_establecimiento ON reporting.kpi_diario USING btree (establecimiento_id);


--
-- Name: idx_kpi_diario_zone; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_kpi_diario_zone ON reporting.kpi_diario USING btree (zone_id);


--
-- Name: idx_rem_cupos_periodo; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_rem_cupos_periodo ON reporting.rem_cupos USING btree (periodo);


--
-- Name: idx_rem_personas_periodo; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_rem_personas_periodo ON reporting.rem_personas_atendidas USING btree (periodo);


--
-- Name: idx_rem_visitas_periodo; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_rem_visitas_periodo ON reporting.rem_visitas USING btree (periodo);


--
-- Name: idx_reporte_cobertura_paciente; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_reporte_cobertura_paciente ON reporting.reporte_cobertura USING btree (patient_id);


--
-- Name: idx_vp_prestacion; Type: INDEX; Schema: reporting; Owner: -
--

CREATE INDEX idx_vp_prestacion ON reporting.visita_prestacion USING btree (prestacion_id);


--
-- Name: idx_strict_hosp_fechas; Type: INDEX; Schema: strict; Owner: -
--

CREATE INDEX idx_strict_hosp_fechas ON strict.hospitalizacion USING btree (fecha_ingreso, fecha_egreso);


--
-- Name: idx_strict_hosp_rut; Type: INDEX; Schema: strict; Owner: -
--

CREATE INDEX idx_strict_hosp_rut ON strict.hospitalizacion USING btree (rut_paciente);


--
-- Name: idx_resumen_diario_device; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_resumen_diario_device ON telemetry.telemetria_resumen_diario USING btree (device_id);


--
-- Name: idx_resumen_diario_fecha; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_resumen_diario_fecha ON telemetry.telemetria_resumen_diario USING btree (fecha);


--
-- Name: idx_resumen_diario_ruta; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_resumen_diario_ruta ON telemetry.telemetria_resumen_diario USING btree (route_id);


--
-- Name: idx_segmento_device; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_device ON telemetry.telemetria_segmento USING btree (device_id);


--
-- Name: idx_segmento_geofences; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_geofences ON telemetry.telemetria_segmento USING gin (geofences_in);


--
-- Name: idx_segmento_ruta; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_ruta ON telemetry.telemetria_segmento USING btree (route_id);


--
-- Name: idx_segmento_start; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_start ON telemetry.telemetria_segmento USING btree (start_at);


--
-- Name: idx_segmento_stops_significativos; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_stops_significativos ON telemetry.telemetria_segmento USING btree (device_id, start_at) WHERE ((tipo = 'stop'::text) AND (duracion_seg > 300));


--
-- Name: idx_segmento_tipo; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_tipo ON telemetry.telemetria_segmento USING btree (tipo);


--
-- Name: idx_segmento_visita; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_segmento_visita ON telemetry.telemetria_segmento USING btree (visit_id);


--
-- Name: idx_telemetria_dispositivo_vehiculo; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_telemetria_dispositivo_vehiculo ON telemetry.telemetria_dispositivo USING btree (vehiculo_id);


--
-- Name: idx_telemetria_resumen_conductor; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_telemetria_resumen_conductor ON telemetry.telemetria_resumen_diario USING btree (conductor_id);


--
-- Name: idx_telemetria_resumen_provider; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE INDEX idx_telemetria_resumen_provider ON telemetry.telemetria_resumen_diario USING btree (provider_id);


--
-- Name: uq_gps_pos_device_dt; Type: INDEX; Schema: telemetry; Owner: -
--

CREATE UNIQUE INDEX uq_gps_pos_device_dt ON telemetry.gps_posicion USING btree (device_id, dt);


--
-- Name: idx_localizacion_comuna; Type: INDEX; Schema: territorial; Owner: -
--

CREATE INDEX idx_localizacion_comuna ON territorial.localizacion USING btree (comuna);


--
-- Name: idx_matriz_dist_dest; Type: INDEX; Schema: territorial; Owner: -
--

CREATE INDEX idx_matriz_dist_dest ON territorial.matriz_distancia USING btree (dest_zone_id);


--
-- Name: idx_ubicacion_zone; Type: INDEX; Schema: territorial; Owner: -
--

CREATE INDEX idx_ubicacion_zone ON territorial.ubicacion USING btree (zone_id);


--
-- Name: alerta trg_alerta_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_alerta_pe1 BEFORE INSERT OR UPDATE ON clinical.alerta FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: botiquin_domiciliario trg_botiquin_domiciliario_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_botiquin_domiciliario_pe1 BEFORE INSERT OR UPDATE ON clinical.botiquin_domiciliario FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: chat_mensaje trg_chat_mensaje_no_delete; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_chat_mensaje_no_delete BEFORE DELETE ON clinical.chat_mensaje FOR EACH ROW EXECUTE FUNCTION clinical.prevent_chat_delete();


--
-- Name: chat_mensaje trg_chat_mensaje_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_chat_mensaje_pe1 BEFORE INSERT OR UPDATE ON clinical.chat_mensaje FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: condicion trg_condicion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_condicion_pe1 BEFORE INSERT OR UPDATE ON clinical.condicion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: consentimiento trg_consentimiento_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_consentimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.consentimiento FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: cuidador trg_cuidador_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_cuidador_updated_at BEFORE UPDATE ON clinical.cuidador FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: derivacion trg_derivacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_derivacion_pe1 BEFORE INSERT OR UPDATE ON clinical.derivacion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: dispensacion trg_dispensacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_dispensacion_pe1 BEFORE INSERT OR UPDATE ON clinical.dispensacion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: dispensacion trg_dispensacion_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_dispensacion_updated_at BEFORE UPDATE ON clinical.dispensacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: documentacion trg_documentacion_coherencia; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_documentacion_coherencia BEFORE INSERT OR UPDATE ON clinical.documentacion FOR EACH ROW EXECUTE FUNCTION reference.check_documentacion_coherencia();


--
-- Name: documentacion trg_documentacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_documentacion_pe1 BEFORE INSERT OR UPDATE ON clinical.documentacion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: documentacion trg_documentacion_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_documentacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.documentacion FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: educacion_paciente trg_educacion_paciente_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_educacion_paciente_pe1 BEFORE INSERT OR UPDATE ON clinical.educacion_paciente FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: educacion_paciente trg_educacion_paciente_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_educacion_paciente_stay_coherence BEFORE INSERT OR UPDATE ON clinical.educacion_paciente FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: educacion_paciente trg_educacion_paciente_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_educacion_paciente_updated_at BEFORE UPDATE ON clinical.educacion_paciente FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: encuesta_satisfaccion trg_encuesta_clin_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_encuesta_clin_pe1 BEFORE INSERT OR UPDATE ON clinical.encuesta_satisfaccion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: epicrisis trg_epicrisis_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_epicrisis_pe1 BEFORE INSERT OR UPDATE ON clinical.epicrisis FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: epicrisis trg_epicrisis_sync_estadia; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_epicrisis_sync_estadia BEFORE INSERT OR UPDATE ON clinical.epicrisis FOR EACH ROW EXECUTE FUNCTION reference.check_epicrisis_sync_estadia();


--
-- Name: estadia trg_estadia_guard_estado; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_estadia_guard_estado BEFORE UPDATE ON clinical.estadia FOR EACH ROW EXECUTE FUNCTION reference.guard_estadia_estado();


--
-- Name: estadia trg_estadia_guard_insert; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_estadia_guard_insert BEFORE INSERT ON clinical.estadia FOR EACH ROW EXECUTE FUNCTION reference.guard_estadia_estado_insert();


--
-- Name: estadia trg_estadia_sync_paciente; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_estadia_sync_paciente AFTER UPDATE OF estado ON clinical.estadia FOR EACH ROW EXECUTE FUNCTION reference.sync_paciente_estado();


--
-- Name: evaluacion_funcional trg_evaluacion_funcional_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_evaluacion_funcional_pe1 BEFORE INSERT OR UPDATE ON clinical.evaluacion_funcional FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: evaluacion_paliativa trg_evaluacion_paliativa_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_evaluacion_paliativa_pe1 BEFORE INSERT OR UPDATE ON clinical.evaluacion_paliativa FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: evento_adverso trg_evento_adverso_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_evento_adverso_pe1 BEFORE INSERT OR UPDATE ON clinical.evento_adverso FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: evento_adverso trg_evento_adverso_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_evento_adverso_stay_coherence BEFORE INSERT OR UPDATE ON clinical.evento_adverso FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: fotografia_clinica trg_fotografia_clinica_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_fotografia_clinica_pe1 BEFORE INSERT OR UPDATE ON clinical.fotografia_clinica FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: garantia_ges trg_garantia_ges_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_garantia_ges_pe1 BEFORE INSERT OR UPDATE ON clinical.garantia_ges FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: herida trg_herida_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_herida_pe1 BEFORE INSERT OR UPDATE ON clinical.herida FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: indicacion_medica trg_indicacion_medica_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_indicacion_medica_pe1 BEFORE INSERT OR UPDATE ON clinical.indicacion_medica FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: informe_social trg_informe_social_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_informe_social_pe1 BEFORE INSERT OR UPDATE ON clinical.informe_social FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: interconsulta trg_interconsulta_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_interconsulta_pe1 BEFORE INSERT OR UPDATE ON clinical.interconsulta FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: lista_espera trg_lista_espera_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_lista_espera_pe1 BEFORE INSERT OR UPDATE ON clinical.lista_espera FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: medicacion trg_medicacion_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_medicacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.medicacion FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: nota_evolucion trg_nota_evolucion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_nota_evolucion_pe1 BEFORE INSERT OR UPDATE ON clinical.nota_evolucion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: nota_evolucion trg_nota_evolucion_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_nota_evolucion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.nota_evolucion FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: notificacion_obligatoria trg_notificacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_notificacion_pe1 BEFORE INSERT OR UPDATE ON clinical.notificacion_obligatoria FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: observacion trg_observacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_observacion_pe1 BEFORE INSERT OR UPDATE ON clinical.observacion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: observacion_portal trg_observacion_portal_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_observacion_portal_pe1 BEFORE INSERT OR UPDATE ON clinical.observacion_portal FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: observacion trg_observacion_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_observacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.observacion FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: oxigenoterapia_domiciliaria trg_oxigenoterapia_domiciliaria_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_oxigenoterapia_domiciliaria_pe1 BEFORE INSERT OR UPDATE ON clinical.oxigenoterapia_domiciliaria FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: plan_ejercicios trg_plan_ejercicios_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_plan_ejercicios_pe1 BEFORE INSERT OR UPDATE ON clinical.plan_ejercicios FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: portal_mensaje trg_portal_mensaje_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_portal_mensaje_pe1 BEFORE INSERT OR UPDATE ON clinical.portal_mensaje FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: prestamo_equipo trg_prestamo_equipo_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_prestamo_equipo_pe1 BEFORE INSERT OR UPDATE ON clinical.prestamo_equipo FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: procedimiento trg_procedimiento_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_procedimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.procedimiento FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: procedimiento trg_procedimiento_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_procedimiento_stay_coherence BEFORE INSERT OR UPDATE ON clinical.procedimiento FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: protocolo_fallecimiento trg_protocolo_fallecimiento_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_protocolo_fallecimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.protocolo_fallecimiento FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: protocolo_fallecimiento trg_protocolo_tipo_egreso; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_protocolo_tipo_egreso BEFORE INSERT OR UPDATE ON clinical.protocolo_fallecimiento FOR EACH ROW EXECUTE FUNCTION reference.check_protocolo_tipo_egreso();


--
-- Name: receta trg_receta_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_receta_pe1 BEFORE INSERT OR UPDATE ON clinical.receta FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: sesion_rehabilitacion trg_sesion_rehab_profesion; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_sesion_rehab_profesion BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion FOR EACH ROW EXECUTE FUNCTION reference.check_sesion_rehab_profesion();


--
-- Name: sesion_rehabilitacion trg_sesion_rehabilitacion_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_sesion_rehabilitacion_pe1 BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: sesion_rehabilitacion trg_sesion_rehabilitacion_stay_coherence; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_sesion_rehabilitacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


--
-- Name: sesion_videollamada trg_sesion_videollamada_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_sesion_videollamada_pe1 BEFORE INSERT OR UPDATE ON clinical.sesion_videollamada FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: sesion_videollamada trg_sesion_videollamada_updated; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_sesion_videollamada_updated BEFORE UPDATE ON clinical.sesion_videollamada FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: alerta trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.alerta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: botiquin_domiciliario trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.botiquin_domiciliario FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: condicion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.condicion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: consentimiento trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.consentimiento FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: derivacion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.derivacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: dispositivo trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.dispositivo FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: documentacion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.documentacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: domicilio trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.domicilio FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: epicrisis trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.epicrisis FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: equipo_medico trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.equipo_medico FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: estadia trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.estadia FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: evaluacion_funcional trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_funcional FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: evaluacion_paliativa trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_paliativa FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: evento_adverso trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evento_adverso FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: garantia_ges trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.garantia_ges FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: herida trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.herida FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: indicacion_medica trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.indicacion_medica FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: informe_social trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.informe_social FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: interconsulta trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.interconsulta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: lista_espera trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.lista_espera FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: medicacion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.medicacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: meta trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.meta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: nota_evolucion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.nota_evolucion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: notificacion_obligatoria trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.notificacion_obligatoria FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: oxigenoterapia_domiciliaria trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.oxigenoterapia_domiciliaria FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: paciente trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.paciente FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: plan_cuidado trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.plan_cuidado FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: prestamo_equipo trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.prestamo_equipo FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: procedimiento trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.procedimiento FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: receta trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.receta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: sesion_rehabilitacion trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.sesion_rehabilitacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: solicitud_examen trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.solicitud_examen FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: teleconsulta trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.teleconsulta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: valoracion_ingreso trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.valoracion_ingreso FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: voluntad_anticipada trg_set_updated_at; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.voluntad_anticipada FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: solicitud_examen trg_solicitud_examen_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_solicitud_examen_pe1 BEFORE INSERT OR UPDATE ON clinical.solicitud_examen FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: teleconsulta trg_teleconsulta_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_teleconsulta_pe1 BEFORE INSERT OR UPDATE ON clinical.teleconsulta FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: valoracion_ingreso trg_valoracion_ingreso_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_valoracion_ingreso_pe1 BEFORE INSERT OR UPDATE ON clinical.valoracion_ingreso FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: voluntad_anticipada trg_voluntad_pe1; Type: TRIGGER; Schema: clinical; Owner: -
--

CREATE TRIGGER trg_voluntad_pe1 BEFORE INSERT OR UPDATE ON clinical.voluntad_anticipada FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: canasta_valorizada trg_canasta_valorizada_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_canasta_valorizada_pe1 BEFORE INSERT OR UPDATE ON operational.canasta_valorizada FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: compra_servicio trg_compra_servicio_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_compra_servicio_pe1 BEFORE INSERT OR UPDATE ON operational.compra_servicio FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: entrega_turno_paciente trg_entrega_turno_paciente_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_entrega_turno_paciente_pe1 BEFORE INSERT OR UPDATE ON operational.entrega_turno_paciente FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: evento_estadia trg_evento_estadia_sync; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_evento_estadia_sync AFTER INSERT ON operational.evento_estadia FOR EACH ROW EXECUTE FUNCTION reference.sync_estadia_estado();


--
-- Name: evento_estadia trg_evento_estadia_transition; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_evento_estadia_transition BEFORE INSERT ON operational.evento_estadia FOR EACH ROW EXECUTE FUNCTION reference.check_estadia_transition();


--
-- Name: evento_visita trg_evento_visita_sync; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_evento_visita_sync AFTER INSERT ON operational.evento_visita FOR EACH ROW EXECUTE FUNCTION reference.sync_visita_estado();


--
-- Name: evento_visita trg_evento_visita_transition; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_evento_visita_transition BEFORE INSERT ON operational.evento_visita FOR EACH ROW EXECUTE FUNCTION reference.check_visita_transition();


--
-- Name: orden_servicio trg_orden_servicio_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_orden_servicio_pe1 BEFORE INSERT OR UPDATE ON operational.orden_servicio FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: profesional trg_profesional_coherencia_rem; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_profesional_coherencia_rem BEFORE INSERT OR UPDATE ON operational.profesional FOR EACH ROW EXECUTE FUNCTION reference.check_profesional_coherencia_rem();


--
-- Name: registro_llamada trg_registro_llamada_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_registro_llamada_pe1 BEFORE INSERT OR UPDATE ON operational.registro_llamada FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: registro_llamada trg_registro_llamada_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_registro_llamada_updated_at BEFORE UPDATE ON operational.registro_llamada FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: compra_servicio trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.compra_servicio FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: conductor trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.conductor FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: configuracion_programa trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.configuracion_programa FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: insumo trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.insumo FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: orden_servicio trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.orden_servicio FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: profesional trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.profesional FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: ruta trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.ruta FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: vehiculo trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.vehiculo FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: visita trg_set_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: sla trg_sla_updated_at; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_sla_updated_at BEFORE UPDATE ON operational.sla FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: visita trg_visita_domicilio_coherence; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_domicilio_coherence BEFORE INSERT OR UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION clinical.check_visita_domicilio_coherence();


--
-- Name: visita trg_visita_guard_estado; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_guard_estado BEFORE UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.guard_visita_estado();


--
-- Name: visita trg_visita_guard_insert; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_guard_insert BEFORE INSERT ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.guard_visita_estado_insert();


--
-- Name: visita trg_visita_pe1; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_pe1 BEFORE INSERT OR UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: visita trg_visita_rango_temporal; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_rango_temporal BEFORE INSERT OR UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.check_visita_rango_temporal();


--
-- Name: visita trg_visita_ruta_provider; Type: TRIGGER; Schema: operational; Owner: -
--

CREATE TRIGGER trg_visita_ruta_provider BEFORE INSERT OR UPDATE ON operational.visita FOR EACH ROW EXECUTE FUNCTION reference.check_visita_ruta_provider();


--
-- Name: encuesta_satisfaccion trg_encuesta_rep_pe1; Type: TRIGGER; Schema: reporting; Owner: -
--

CREATE TRIGGER trg_encuesta_rep_pe1 BEFORE INSERT OR UPDATE ON reporting.encuesta_satisfaccion FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


--
-- Name: rem_cupos trg_rem_cupos_rc5; Type: TRIGGER; Schema: reporting; Owner: -
--

CREATE TRIGGER trg_rem_cupos_rc5 BEFORE INSERT OR UPDATE ON reporting.rem_cupos FOR EACH ROW EXECUTE FUNCTION reference.check_rem_cupos_rc5();


--
-- Name: telemetria_dispositivo trg_set_updated_at; Type: TRIGGER; Schema: telemetry; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON telemetry.telemetria_dispositivo FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: telemetria_resumen_diario trg_telemetria_resumen_ruta; Type: TRIGGER; Schema: telemetry; Owner: -
--

CREATE TRIGGER trg_telemetria_resumen_ruta BEFORE INSERT OR UPDATE ON telemetry.telemetria_resumen_diario FOR EACH ROW EXECUTE FUNCTION reference.check_telemetria_ruta_coherence();


--
-- Name: telemetria_segmento trg_telemetria_segmento_visita; Type: TRIGGER; Schema: telemetry; Owner: -
--

CREATE TRIGGER trg_telemetria_segmento_visita BEFORE INSERT OR UPDATE ON telemetry.telemetria_segmento FOR EACH ROW EXECUTE FUNCTION reference.check_telemetria_visita_coherence();


--
-- Name: establecimiento trg_set_updated_at; Type: TRIGGER; Schema: territorial; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.establecimiento FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: localizacion trg_set_updated_at; Type: TRIGGER; Schema: territorial; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.localizacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: matriz_distancia trg_set_updated_at; Type: TRIGGER; Schema: territorial; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.matriz_distancia FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: ubicacion trg_set_updated_at; Type: TRIGGER; Schema: territorial; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.ubicacion FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: zona trg_set_updated_at; Type: TRIGGER; Schema: territorial; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.zona FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


--
-- Name: alerta alerta_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.alerta
    ADD CONSTRAINT alerta_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: alerta alerta_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.alerta
    ADD CONSTRAINT alerta_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: botiquin_domiciliario botiquin_domiciliario_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.botiquin_domiciliario
    ADD CONSTRAINT botiquin_domiciliario_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: botiquin_domiciliario botiquin_domiciliario_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.botiquin_domiciliario
    ADD CONSTRAINT botiquin_domiciliario_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: chat_mensaje chat_mensaje_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.chat_mensaje
    ADD CONSTRAINT chat_mensaje_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: chat_mensaje chat_mensaje_sesion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.chat_mensaje
    ADD CONSTRAINT chat_mensaje_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES clinical.sesion_videollamada(sesion_id);


--
-- Name: chat_mensaje chat_mensaje_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.chat_mensaje
    ADD CONSTRAINT chat_mensaje_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: checklist_ingreso checklist_ingreso_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.checklist_ingreso
    ADD CONSTRAINT checklist_ingreso_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id) ON DELETE CASCADE;


--
-- Name: condicion condicion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.condicion
    ADD CONSTRAINT condicion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: condicion condicion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.condicion
    ADD CONSTRAINT condicion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: consentimiento consentimiento_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.consentimiento
    ADD CONSTRAINT consentimiento_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: consentimiento consentimiento_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.consentimiento
    ADD CONSTRAINT consentimiento_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: consentimiento consentimiento_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.consentimiento
    ADD CONSTRAINT consentimiento_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: cuidador cuidador_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.cuidador
    ADD CONSTRAINT cuidador_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: derivacion_adjunto derivacion_adjunto_derivacion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion_adjunto
    ADD CONSTRAINT derivacion_adjunto_derivacion_id_fkey FOREIGN KEY (derivacion_id) REFERENCES clinical.derivacion(derivacion_id) ON DELETE CASCADE;


--
-- Name: derivacion derivacion_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion
    ADD CONSTRAINT derivacion_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: derivacion derivacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion
    ADD CONSTRAINT derivacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: derivacion derivacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.derivacion
    ADD CONSTRAINT derivacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: diagnostico_egreso diagnostico_egreso_epicrisis_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.diagnostico_egreso
    ADD CONSTRAINT diagnostico_egreso_epicrisis_id_fkey FOREIGN KEY (epicrisis_id) REFERENCES clinical.epicrisis(epicrisis_id) ON DELETE CASCADE;


--
-- Name: dispensacion dispensacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispensacion
    ADD CONSTRAINT dispensacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: dispensacion dispensacion_receta_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispensacion
    ADD CONSTRAINT dispensacion_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES clinical.receta(receta_id);


--
-- Name: dispensacion dispensacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispensacion
    ADD CONSTRAINT dispensacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: dispositivo dispositivo_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.dispositivo
    ADD CONSTRAINT dispositivo_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: documentacion documentacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.documentacion
    ADD CONSTRAINT documentacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: documentacion documentacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.documentacion
    ADD CONSTRAINT documentacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: documentacion documentacion_tipo_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.documentacion
    ADD CONSTRAINT documentacion_tipo_fkey FOREIGN KEY (tipo) REFERENCES reference.tipo_documento_ref(codigo);


--
-- Name: domicilio domicilio_localizacion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.domicilio
    ADD CONSTRAINT domicilio_localizacion_id_fkey FOREIGN KEY (localizacion_id) REFERENCES territorial.localizacion(localizacion_id);


--
-- Name: domicilio domicilio_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.domicilio
    ADD CONSTRAINT domicilio_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: educacion_paciente educacion_paciente_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT educacion_paciente_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: educacion_paciente educacion_paciente_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT educacion_paciente_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: educacion_paciente educacion_paciente_tema_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT educacion_paciente_tema_fkey FOREIGN KEY (tema) REFERENCES reference.tema_educacion_ref(codigo);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: epicrisis epicrisis_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.epicrisis
    ADD CONSTRAINT epicrisis_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: epicrisis epicrisis_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.epicrisis
    ADD CONSTRAINT epicrisis_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: epicrisis epicrisis_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.epicrisis
    ADD CONSTRAINT epicrisis_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: estadia estadia_establecimiento_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.estadia
    ADD CONSTRAINT estadia_establecimiento_id_fkey FOREIGN KEY (establecimiento_id) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: estadia estadia_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.estadia
    ADD CONSTRAINT estadia_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: evaluacion_funcional evaluacion_funcional_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_funcional
    ADD CONSTRAINT evaluacion_funcional_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: evaluacion_funcional evaluacion_funcional_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_funcional
    ADD CONSTRAINT evaluacion_funcional_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: evaluacion_paliativa evaluacion_paliativa_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_paliativa
    ADD CONSTRAINT evaluacion_paliativa_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: evaluacion_paliativa evaluacion_paliativa_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_paliativa
    ADD CONSTRAINT evaluacion_paliativa_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: evento_adverso evento_adverso_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT evento_adverso_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: evento_adverso evento_adverso_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT evento_adverso_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: evento_adverso evento_adverso_tipo_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT evento_adverso_tipo_fkey FOREIGN KEY (tipo) REFERENCES reference.tipo_evento_adverso_ref(codigo);


--
-- Name: consentimiento fk_consentimiento_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.consentimiento
    ADD CONSTRAINT fk_consentimiento_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: documentacion fk_documentacion_visita; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.documentacion
    ADD CONSTRAINT fk_documentacion_visita FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: educacion_paciente fk_educacion_paciente_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT fk_educacion_paciente_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: educacion_paciente fk_educacion_paciente_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.educacion_paciente
    ADD CONSTRAINT fk_educacion_paciente_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: epicrisis fk_epicrisis_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.epicrisis
    ADD CONSTRAINT fk_epicrisis_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: evaluacion_funcional fk_evaluacion_funcional_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_funcional
    ADD CONSTRAINT fk_evaluacion_funcional_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: evaluacion_paliativa fk_evaluacion_paliativa_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evaluacion_paliativa
    ADD CONSTRAINT fk_evaluacion_paliativa_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: evento_adverso fk_evento_adverso_detectado_por_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT fk_evento_adverso_detectado_por_id FOREIGN KEY (detectado_por_id) REFERENCES operational.profesional(provider_id);


--
-- Name: evento_adverso fk_evento_adverso_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.evento_adverso
    ADD CONSTRAINT fk_evento_adverso_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: indicacion_medica fk_indicacion_medica_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.indicacion_medica
    ADD CONSTRAINT fk_indicacion_medica_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: informe_social fk_informe_social_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.informe_social
    ADD CONSTRAINT fk_informe_social_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: interconsulta fk_interconsulta_solicitante_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.interconsulta
    ADD CONSTRAINT fk_interconsulta_solicitante_id FOREIGN KEY (solicitante_id) REFERENCES operational.profesional(provider_id);


--
-- Name: lista_espera fk_lista_espera_evaluador_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT fk_lista_espera_evaluador_id FOREIGN KEY (evaluador_id) REFERENCES operational.profesional(provider_id);


--
-- Name: medicacion fk_medicacion_visita; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.medicacion
    ADD CONSTRAINT fk_medicacion_visita FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: nota_evolucion fk_nota_evolucion_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.nota_evolucion
    ADD CONSTRAINT fk_nota_evolucion_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: nota_evolucion fk_nota_evolucion_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.nota_evolucion
    ADD CONSTRAINT fk_nota_evolucion_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: notificacion_obligatoria fk_notificacion_obligatoria_notificador_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.notificacion_obligatoria
    ADD CONSTRAINT fk_notificacion_obligatoria_notificador_id FOREIGN KEY (notificador_id) REFERENCES operational.profesional(provider_id);


--
-- Name: observacion fk_observacion_visita; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion
    ADD CONSTRAINT fk_observacion_visita FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: prestamo_equipo fk_prestamo_equipo_entregado_por; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.prestamo_equipo
    ADD CONSTRAINT fk_prestamo_equipo_entregado_por FOREIGN KEY (entregado_por) REFERENCES operational.profesional(provider_id);


--
-- Name: procedimiento fk_procedimiento_visita; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.procedimiento
    ADD CONSTRAINT fk_procedimiento_visita FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: protocolo_fallecimiento fk_protocolo_fallecimiento_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT fk_protocolo_fallecimiento_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: receta fk_receta_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.receta
    ADD CONSTRAINT fk_receta_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: seguimiento_dispositivo fk_seguimiento_dispositivo_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_dispositivo
    ADD CONSTRAINT fk_seguimiento_dispositivo_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: seguimiento_dispositivo fk_seguimiento_dispositivo_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_dispositivo
    ADD CONSTRAINT fk_seguimiento_dispositivo_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: seguimiento_herida fk_seguimiento_herida_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_herida
    ADD CONSTRAINT fk_seguimiento_herida_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: seguimiento_herida fk_seguimiento_herida_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_herida
    ADD CONSTRAINT fk_seguimiento_herida_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: sesion_rehabilitacion fk_sesion_rehabilitacion_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion
    ADD CONSTRAINT fk_sesion_rehabilitacion_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: sesion_rehabilitacion fk_sesion_rehabilitacion_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion
    ADD CONSTRAINT fk_sesion_rehabilitacion_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: solicitud_examen fk_solicitud_examen_solicitante_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.solicitud_examen
    ADD CONSTRAINT fk_solicitud_examen_solicitante_id FOREIGN KEY (solicitante_id) REFERENCES operational.profesional(provider_id);


--
-- Name: teleconsulta fk_teleconsulta_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.teleconsulta
    ADD CONSTRAINT fk_teleconsulta_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: toma_muestra fk_toma_muestra_tomador_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.toma_muestra
    ADD CONSTRAINT fk_toma_muestra_tomador_id FOREIGN KEY (tomador_id) REFERENCES operational.profesional(provider_id);


--
-- Name: toma_muestra fk_toma_muestra_visit_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.toma_muestra
    ADD CONSTRAINT fk_toma_muestra_visit_id FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: valoracion_ingreso fk_valoracion_ingreso_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_ingreso
    ADD CONSTRAINT fk_valoracion_ingreso_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: voluntad_anticipada fk_voluntad_anticipada_provider_id; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.voluntad_anticipada
    ADD CONSTRAINT fk_voluntad_anticipada_provider_id FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: fotografia_clinica fotografia_clinica_herida_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.fotografia_clinica
    ADD CONSTRAINT fotografia_clinica_herida_id_fkey FOREIGN KEY (herida_id) REFERENCES clinical.herida(herida_id);


--
-- Name: fotografia_clinica fotografia_clinica_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.fotografia_clinica
    ADD CONSTRAINT fotografia_clinica_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: fotografia_clinica fotografia_clinica_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.fotografia_clinica
    ADD CONSTRAINT fotografia_clinica_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: garantia_ges garantia_ges_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.garantia_ges
    ADD CONSTRAINT garantia_ges_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: garantia_ges garantia_ges_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.garantia_ges
    ADD CONSTRAINT garantia_ges_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: herida herida_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.herida
    ADD CONSTRAINT herida_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: herida herida_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.herida
    ADD CONSTRAINT herida_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: indicacion_medica indicacion_medica_indicacion_previa_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.indicacion_medica
    ADD CONSTRAINT indicacion_medica_indicacion_previa_id_fkey FOREIGN KEY (indicacion_previa_id) REFERENCES clinical.indicacion_medica(indicacion_id);


--
-- Name: indicacion_medica indicacion_medica_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.indicacion_medica
    ADD CONSTRAINT indicacion_medica_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: indicacion_medica indicacion_medica_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.indicacion_medica
    ADD CONSTRAINT indicacion_medica_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: informe_social informe_social_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.informe_social
    ADD CONSTRAINT informe_social_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: informe_social informe_social_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.informe_social
    ADD CONSTRAINT informe_social_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: informe_social informe_social_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.informe_social
    ADD CONSTRAINT informe_social_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: interconsulta interconsulta_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.interconsulta
    ADD CONSTRAINT interconsulta_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: interconsulta interconsulta_prioridad_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.interconsulta
    ADD CONSTRAINT interconsulta_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: interconsulta interconsulta_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.interconsulta
    ADD CONSTRAINT interconsulta_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: lista_espera lista_espera_establecimiento_origen_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT lista_espera_establecimiento_origen_fkey FOREIGN KEY (establecimiento_origen) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: lista_espera lista_espera_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT lista_espera_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: lista_espera lista_espera_prioridad_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT lista_espera_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: lista_espera lista_espera_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.lista_espera
    ADD CONSTRAINT lista_espera_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: medicacion medicacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.medicacion
    ADD CONSTRAINT medicacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: meta meta_plan_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.meta
    ADD CONSTRAINT meta_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES clinical.plan_cuidado(plan_id) ON DELETE CASCADE;


--
-- Name: necesidad_profesional necesidad_profesional_plan_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.necesidad_profesional
    ADD CONSTRAINT necesidad_profesional_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES clinical.plan_cuidado(plan_id) ON DELETE CASCADE;


--
-- Name: nota_evolucion nota_evolucion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.nota_evolucion
    ADD CONSTRAINT nota_evolucion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: nota_evolucion nota_evolucion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.nota_evolucion
    ADD CONSTRAINT nota_evolucion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: notificacion_obligatoria notificacion_obligatoria_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.notificacion_obligatoria
    ADD CONSTRAINT notificacion_obligatoria_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: notificacion_obligatoria notificacion_obligatoria_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.notificacion_obligatoria
    ADD CONSTRAINT notificacion_obligatoria_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: observacion observacion_codigo_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion
    ADD CONSTRAINT observacion_codigo_fkey FOREIGN KEY (codigo) REFERENCES reference.codigo_observacion_ref(codigo);


--
-- Name: observacion observacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion
    ADD CONSTRAINT observacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: observacion_portal observacion_portal_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion_portal
    ADD CONSTRAINT observacion_portal_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: observacion_portal observacion_portal_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion_portal
    ADD CONSTRAINT observacion_portal_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: observacion_portal observacion_portal_usuario_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion_portal
    ADD CONSTRAINT observacion_portal_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES operational.portal_usuario(usuario_id);


--
-- Name: observacion observacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.observacion
    ADD CONSTRAINT observacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: oxigenoterapia_domiciliaria oxigenoterapia_domiciliaria_equipo_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.oxigenoterapia_domiciliaria
    ADD CONSTRAINT oxigenoterapia_domiciliaria_equipo_id_fkey FOREIGN KEY (equipo_id) REFERENCES clinical.equipo_medico(equipo_id);


--
-- Name: oxigenoterapia_domiciliaria oxigenoterapia_domiciliaria_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.oxigenoterapia_domiciliaria
    ADD CONSTRAINT oxigenoterapia_domiciliaria_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: oxigenoterapia_domiciliaria oxigenoterapia_domiciliaria_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.oxigenoterapia_domiciliaria
    ADD CONSTRAINT oxigenoterapia_domiciliaria_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: plan_cuidado plan_cuidado_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.plan_cuidado
    ADD CONSTRAINT plan_cuidado_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: plan_ejercicios plan_ejercicios_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.plan_ejercicios
    ADD CONSTRAINT plan_ejercicios_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: plan_ejercicios plan_ejercicios_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.plan_ejercicios
    ADD CONSTRAINT plan_ejercicios_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: portal_mensaje portal_mensaje_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.portal_mensaje
    ADD CONSTRAINT portal_mensaje_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: portal_mensaje portal_mensaje_respondido_por_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.portal_mensaje
    ADD CONSTRAINT portal_mensaje_respondido_por_fkey FOREIGN KEY (respondido_por) REFERENCES operational.profesional(provider_id);


--
-- Name: portal_mensaje portal_mensaje_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.portal_mensaje
    ADD CONSTRAINT portal_mensaje_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: portal_mensaje portal_mensaje_usuario_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.portal_mensaje
    ADD CONSTRAINT portal_mensaje_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES operational.portal_usuario(usuario_id);


--
-- Name: prestamo_equipo prestamo_equipo_equipo_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.prestamo_equipo
    ADD CONSTRAINT prestamo_equipo_equipo_id_fkey FOREIGN KEY (equipo_id) REFERENCES clinical.equipo_medico(equipo_id);


--
-- Name: prestamo_equipo prestamo_equipo_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.prestamo_equipo
    ADD CONSTRAINT prestamo_equipo_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: prestamo_equipo prestamo_equipo_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.prestamo_equipo
    ADD CONSTRAINT prestamo_equipo_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: procedimiento procedimiento_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.procedimiento
    ADD CONSTRAINT procedimiento_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: procedimiento procedimiento_prestacion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.procedimiento
    ADD CONSTRAINT procedimiento_prestacion_id_fkey FOREIGN KEY (prestacion_id) REFERENCES reference.catalogo_prestacion(prestacion_id);


--
-- Name: procedimiento procedimiento_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.procedimiento
    ADD CONSTRAINT procedimiento_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: protocolo_fallecimiento protocolo_fallecimiento_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT protocolo_fallecimiento_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: protocolo_fallecimiento protocolo_fallecimiento_epicrisis_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT protocolo_fallecimiento_epicrisis_id_fkey FOREIGN KEY (epicrisis_id) REFERENCES clinical.epicrisis(epicrisis_id);


--
-- Name: protocolo_fallecimiento protocolo_fallecimiento_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT protocolo_fallecimiento_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: protocolo_fallecimiento protocolo_fallecimiento_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.protocolo_fallecimiento
    ADD CONSTRAINT protocolo_fallecimiento_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: receta receta_indicacion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.receta
    ADD CONSTRAINT receta_indicacion_id_fkey FOREIGN KEY (indicacion_id) REFERENCES clinical.indicacion_medica(indicacion_id);


--
-- Name: receta receta_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.receta
    ADD CONSTRAINT receta_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: receta receta_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.receta
    ADD CONSTRAINT receta_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: requerimiento_cuidado requerimiento_cuidado_plan_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.requerimiento_cuidado
    ADD CONSTRAINT requerimiento_cuidado_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES clinical.plan_cuidado(plan_id) ON DELETE CASCADE;


--
-- Name: requerimiento_cuidado requerimiento_cuidado_tipo_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.requerimiento_cuidado
    ADD CONSTRAINT requerimiento_cuidado_tipo_fkey FOREIGN KEY (tipo) REFERENCES reference.tipo_requerimiento_ref(codigo);


--
-- Name: resultado_examen resultado_examen_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.resultado_examen
    ADD CONSTRAINT resultado_examen_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: resultado_examen resultado_examen_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.resultado_examen
    ADD CONSTRAINT resultado_examen_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES clinical.solicitud_examen(solicitud_id) ON DELETE CASCADE;


--
-- Name: seguimiento_dispositivo seguimiento_dispositivo_device_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_dispositivo
    ADD CONSTRAINT seguimiento_dispositivo_device_id_fkey FOREIGN KEY (device_id) REFERENCES clinical.dispositivo(device_id) ON DELETE CASCADE;


--
-- Name: seguimiento_herida seguimiento_herida_herida_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.seguimiento_herida
    ADD CONSTRAINT seguimiento_herida_herida_id_fkey FOREIGN KEY (herida_id) REFERENCES clinical.herida(herida_id) ON DELETE CASCADE;


--
-- Name: sesion_rehabilitacion_item sesion_rehabilitacion_item_categoria_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion_item
    ADD CONSTRAINT sesion_rehabilitacion_item_categoria_fkey FOREIGN KEY (categoria) REFERENCES reference.categoria_rehabilitacion_ref(codigo);


--
-- Name: sesion_rehabilitacion_item sesion_rehabilitacion_item_sesion_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion_item
    ADD CONSTRAINT sesion_rehabilitacion_item_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES clinical.sesion_rehabilitacion(sesion_id) ON DELETE CASCADE;


--
-- Name: sesion_rehabilitacion sesion_rehabilitacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion
    ADD CONSTRAINT sesion_rehabilitacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: sesion_rehabilitacion sesion_rehabilitacion_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_rehabilitacion
    ADD CONSTRAINT sesion_rehabilitacion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: sesion_videollamada sesion_videollamada_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: sesion_videollamada sesion_videollamada_provider_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: sesion_videollamada sesion_videollamada_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: sesion_videollamada sesion_videollamada_teleconsulta_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.sesion_videollamada
    ADD CONSTRAINT sesion_videollamada_teleconsulta_id_fkey FOREIGN KEY (teleconsulta_id) REFERENCES clinical.teleconsulta(teleconsulta_id);


--
-- Name: solicitud_examen solicitud_examen_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.solicitud_examen
    ADD CONSTRAINT solicitud_examen_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: solicitud_examen solicitud_examen_prioridad_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.solicitud_examen
    ADD CONSTRAINT solicitud_examen_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: solicitud_examen solicitud_examen_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.solicitud_examen
    ADD CONSTRAINT solicitud_examen_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: teleconsulta teleconsulta_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.teleconsulta
    ADD CONSTRAINT teleconsulta_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: teleconsulta teleconsulta_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.teleconsulta
    ADD CONSTRAINT teleconsulta_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: toma_muestra toma_muestra_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.toma_muestra
    ADD CONSTRAINT toma_muestra_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES clinical.solicitud_examen(solicitud_id) ON DELETE CASCADE;


--
-- Name: valoracion_hallazgo valoracion_hallazgo_assessment_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_hallazgo
    ADD CONSTRAINT valoracion_hallazgo_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES clinical.valoracion_ingreso(assessment_id) ON DELETE CASCADE;


--
-- Name: valoracion_hallazgo valoracion_hallazgo_dominio_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_hallazgo
    ADD CONSTRAINT valoracion_hallazgo_dominio_fkey FOREIGN KEY (dominio) REFERENCES reference.dominio_hallazgo_ref(codigo);


--
-- Name: valoracion_ingreso valoracion_ingreso_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_ingreso
    ADD CONSTRAINT valoracion_ingreso_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: valoracion_ingreso valoracion_ingreso_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.valoracion_ingreso
    ADD CONSTRAINT valoracion_ingreso_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: voluntad_anticipada voluntad_anticipada_doc_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.voluntad_anticipada
    ADD CONSTRAINT voluntad_anticipada_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: voluntad_anticipada voluntad_anticipada_patient_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.voluntad_anticipada
    ADD CONSTRAINT voluntad_anticipada_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: voluntad_anticipada voluntad_anticipada_stay_id_fkey; Type: FK CONSTRAINT; Schema: clinical; Owner: -
--

ALTER TABLE ONLY clinical.voluntad_anticipada
    ADD CONSTRAINT voluntad_anticipada_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: agenda_profesional agenda_profesional_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.agenda_profesional
    ADD CONSTRAINT agenda_profesional_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES operational.profesional(provider_id);


--
-- Name: canasta_valorizada canasta_valorizada_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.canasta_valorizada
    ADD CONSTRAINT canasta_valorizada_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: canasta_valorizada canasta_valorizada_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.canasta_valorizada
    ADD CONSTRAINT canasta_valorizada_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: capacitacion capacitacion_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.capacitacion
    ADD CONSTRAINT capacitacion_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: compra_servicio compra_servicio_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.compra_servicio
    ADD CONSTRAINT compra_servicio_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: compra_servicio compra_servicio_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.compra_servicio
    ADD CONSTRAINT compra_servicio_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: conductor conductor_vehiculo_asignado_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.conductor
    ADD CONSTRAINT conductor_vehiculo_asignado_fkey FOREIGN KEY (vehiculo_asignado) REFERENCES operational.vehiculo(vehiculo_id);


--
-- Name: decision_despacho decision_despacho_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.decision_despacho
    ADD CONSTRAINT decision_despacho_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: decision_despacho decision_despacho_visit_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.decision_despacho
    ADD CONSTRAINT decision_despacho_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id) ON DELETE CASCADE;


--
-- Name: entrega_turno_paciente entrega_turno_paciente_entrega_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno_paciente
    ADD CONSTRAINT entrega_turno_paciente_entrega_id_fkey FOREIGN KEY (entrega_id) REFERENCES operational.entrega_turno(entrega_id) ON DELETE CASCADE;


--
-- Name: entrega_turno_paciente entrega_turno_paciente_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno_paciente
    ADD CONSTRAINT entrega_turno_paciente_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: entrega_turno_paciente entrega_turno_paciente_prioridad_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno_paciente
    ADD CONSTRAINT entrega_turno_paciente_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: entrega_turno_paciente entrega_turno_paciente_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno_paciente
    ADD CONSTRAINT entrega_turno_paciente_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: entrega_turno entrega_turno_turno_entrante_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno
    ADD CONSTRAINT entrega_turno_turno_entrante_id_fkey FOREIGN KEY (turno_entrante_id) REFERENCES operational.profesional(provider_id);


--
-- Name: entrega_turno entrega_turno_turno_saliente_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.entrega_turno
    ADD CONSTRAINT entrega_turno_turno_saliente_id_fkey FOREIGN KEY (turno_saliente_id) REFERENCES operational.profesional(provider_id);


--
-- Name: estadia_episodio_fuente estadia_episodio_fuente_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.estadia_episodio_fuente
    ADD CONSTRAINT estadia_episodio_fuente_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: evento_estadia evento_estadia_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.evento_estadia
    ADD CONSTRAINT evento_estadia_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id) ON DELETE CASCADE;


--
-- Name: evento_visita evento_visita_visit_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.evento_visita
    ADD CONSTRAINT evento_visita_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id) ON DELETE CASCADE;


--
-- Name: kb_articulo kb_articulo_categoria_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo
    ADD CONSTRAINT kb_articulo_categoria_fkey FOREIGN KEY (categoria) REFERENCES reference.kb_categoria_ref(codigo);


--
-- Name: kb_articulo_link kb_articulo_link_source_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_link
    ADD CONSTRAINT kb_articulo_link_source_id_fkey FOREIGN KEY (source_id) REFERENCES operational.kb_articulo(articulo_id) ON DELETE CASCADE;


--
-- Name: kb_articulo_link kb_articulo_link_target_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_link
    ADD CONSTRAINT kb_articulo_link_target_id_fkey FOREIGN KEY (target_id) REFERENCES operational.kb_articulo(articulo_id) ON DELETE CASCADE;


--
-- Name: kb_articulo_tag kb_articulo_tag_articulo_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_tag
    ADD CONSTRAINT kb_articulo_tag_articulo_id_fkey FOREIGN KEY (articulo_id) REFERENCES operational.kb_articulo(articulo_id) ON DELETE CASCADE;


--
-- Name: kb_articulo_tag kb_articulo_tag_tag_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_tag
    ADD CONSTRAINT kb_articulo_tag_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES operational.kb_tag(tag_id) ON DELETE CASCADE;


--
-- Name: kb_articulo_version kb_articulo_version_articulo_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_articulo_version
    ADD CONSTRAINT kb_articulo_version_articulo_id_fkey FOREIGN KEY (articulo_id) REFERENCES operational.kb_articulo(articulo_id) ON DELETE CASCADE;


--
-- Name: kb_documento kb_documento_categoria_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_documento
    ADD CONSTRAINT kb_documento_categoria_fkey FOREIGN KEY (categoria) REFERENCES reference.kb_categoria_ref(codigo);


--
-- Name: kb_documento_tag kb_documento_tag_documento_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_documento_tag
    ADD CONSTRAINT kb_documento_tag_documento_id_fkey FOREIGN KEY (documento_id) REFERENCES operational.kb_documento(documento_id) ON DELETE CASCADE;


--
-- Name: kb_documento_tag kb_documento_tag_tag_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.kb_documento_tag
    ADD CONSTRAINT kb_documento_tag_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES operational.kb_tag(tag_id) ON DELETE CASCADE;


--
-- Name: orden_servicio_insumo orden_servicio_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio_insumo
    ADD CONSTRAINT orden_servicio_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES operational.insumo(item_id) ON DELETE RESTRICT;


--
-- Name: orden_servicio_insumo orden_servicio_insumo_order_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio_insumo
    ADD CONSTRAINT orden_servicio_insumo_order_id_fkey FOREIGN KEY (order_id) REFERENCES operational.orden_servicio(order_id) ON DELETE CASCADE;


--
-- Name: orden_servicio orden_servicio_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: orden_servicio orden_servicio_prioridad_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: orden_servicio orden_servicio_provider_asignado_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_provider_asignado_fkey FOREIGN KEY (provider_asignado) REFERENCES operational.profesional(provider_id);


--
-- Name: orden_servicio orden_servicio_service_type_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_service_type_fkey FOREIGN KEY (service_type) REFERENCES reference.service_type_ref(service_type);


--
-- Name: orden_servicio orden_servicio_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.orden_servicio
    ADD CONSTRAINT orden_servicio_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: portal_acceso_log portal_acceso_log_usuario_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_acceso_log
    ADD CONSTRAINT portal_acceso_log_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES operational.portal_usuario(usuario_id);


--
-- Name: portal_invitacion portal_invitacion_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_invitacion
    ADD CONSTRAINT portal_invitacion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: portal_usuario portal_usuario_cuidador_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_usuario
    ADD CONSTRAINT portal_usuario_cuidador_id_fkey FOREIGN KEY (cuidador_id) REFERENCES clinical.cuidador(cuidador_id);


--
-- Name: portal_usuario portal_usuario_invitado_por_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_usuario
    ADD CONSTRAINT portal_usuario_invitado_por_fkey FOREIGN KEY (invitado_por) REFERENCES operational.profesional(provider_id);


--
-- Name: portal_usuario portal_usuario_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.portal_usuario
    ADD CONSTRAINT portal_usuario_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: registro_llamada registro_llamada_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_llamada
    ADD CONSTRAINT registro_llamada_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: registro_llamada registro_llamada_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_llamada
    ADD CONSTRAINT registro_llamada_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: registro_llamada registro_llamada_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_llamada
    ADD CONSTRAINT registro_llamada_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: registro_vehicular registro_vehicular_route_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.registro_vehicular
    ADD CONSTRAINT registro_vehicular_route_id_fkey FOREIGN KEY (route_id) REFERENCES operational.ruta(route_id);


--
-- Name: requerimiento_orden_mapping requerimiento_orden_mapping_order_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.requerimiento_orden_mapping
    ADD CONSTRAINT requerimiento_orden_mapping_order_id_fkey FOREIGN KEY (order_id) REFERENCES operational.orden_servicio(order_id) ON DELETE CASCADE;


--
-- Name: requerimiento_orden_mapping requerimiento_orden_mapping_req_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.requerimiento_orden_mapping
    ADD CONSTRAINT requerimiento_orden_mapping_req_id_fkey FOREIGN KEY (req_id) REFERENCES clinical.requerimiento_cuidado(req_id) ON DELETE CASCADE;


--
-- Name: reunion_equipo reunion_equipo_acta_doc_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.reunion_equipo
    ADD CONSTRAINT reunion_equipo_acta_doc_id_fkey FOREIGN KEY (acta_doc_id) REFERENCES clinical.documentacion(doc_id);


--
-- Name: ruta ruta_conductor_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.ruta
    ADD CONSTRAINT ruta_conductor_id_fkey FOREIGN KEY (conductor_id) REFERENCES operational.conductor(conductor_id);


--
-- Name: ruta ruta_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.ruta
    ADD CONSTRAINT ruta_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: ruta ruta_vehiculo_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.ruta
    ADD CONSTRAINT ruta_vehiculo_id_fkey FOREIGN KEY (vehiculo_id) REFERENCES operational.vehiculo(vehiculo_id);


--
-- Name: sla sla_prioridad_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.sla
    ADD CONSTRAINT sla_prioridad_fkey FOREIGN KEY (prioridad) REFERENCES reference.prioridad_ref(codigo);


--
-- Name: sla sla_service_type_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.sla
    ADD CONSTRAINT sla_service_type_fkey FOREIGN KEY (service_type) REFERENCES reference.service_type_ref(service_type);


--
-- Name: visita visita_domicilio_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_domicilio_id_fkey FOREIGN KEY (domicilio_id) REFERENCES clinical.domicilio(domicilio_id);


--
-- Name: visita visita_localizacion_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_localizacion_id_fkey FOREIGN KEY (localizacion_id) REFERENCES territorial.localizacion(localizacion_id);


--
-- Name: visita visita_location_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_location_id_fkey FOREIGN KEY (location_id) REFERENCES territorial.ubicacion(location_id);


--
-- Name: visita visita_order_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_order_id_fkey FOREIGN KEY (order_id) REFERENCES operational.orden_servicio(order_id);


--
-- Name: visita visita_patient_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: visita visita_prestacion_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_prestacion_id_fkey FOREIGN KEY (prestacion_id) REFERENCES reference.catalogo_prestacion(prestacion_id);


--
-- Name: visita visita_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: visita visita_route_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_route_id_fkey FOREIGN KEY (route_id) REFERENCES operational.ruta(route_id);


--
-- Name: visita visita_stay_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.visita
    ADD CONSTRAINT visita_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: zona_profesional zona_profesional_provider_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.zona_profesional
    ADD CONSTRAINT zona_profesional_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id) ON DELETE CASCADE;


--
-- Name: zona_profesional zona_profesional_zone_id_fkey; Type: FK CONSTRAINT; Schema: operational; Owner: -
--

ALTER TABLE ONLY operational.zona_profesional
    ADD CONSTRAINT zona_profesional_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES territorial.zona(zone_id) ON DELETE CASCADE;


--
-- Name: descomposicion_temporal descomposicion_temporal_visit_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.descomposicion_temporal
    ADD CONSTRAINT descomposicion_temporal_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_patient_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: encuesta_satisfaccion encuesta_satisfaccion_stay_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.encuesta_satisfaccion
    ADD CONSTRAINT encuesta_satisfaccion_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES clinical.estadia(stay_id);


--
-- Name: kpi_diario kpi_diario_establecimiento_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.kpi_diario
    ADD CONSTRAINT kpi_diario_establecimiento_id_fkey FOREIGN KEY (establecimiento_id) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: kpi_diario kpi_diario_zone_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.kpi_diario
    ADD CONSTRAINT kpi_diario_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES territorial.zona(zone_id);


--
-- Name: rem_cupos rem_cupos_establecimiento_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_cupos
    ADD CONSTRAINT rem_cupos_establecimiento_id_fkey FOREIGN KEY (establecimiento_id) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: rem_personas_atendidas rem_personas_atendidas_establecimiento_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_personas_atendidas
    ADD CONSTRAINT rem_personas_atendidas_establecimiento_id_fkey FOREIGN KEY (establecimiento_id) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: rem_visitas rem_visitas_establecimiento_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.rem_visitas
    ADD CONSTRAINT rem_visitas_establecimiento_id_fkey FOREIGN KEY (establecimiento_id) REFERENCES territorial.establecimiento(establecimiento_id);


--
-- Name: reporte_cobertura reporte_cobertura_order_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.reporte_cobertura
    ADD CONSTRAINT reporte_cobertura_order_id_fkey FOREIGN KEY (order_id) REFERENCES operational.orden_servicio(order_id);


--
-- Name: reporte_cobertura reporte_cobertura_patient_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.reporte_cobertura
    ADD CONSTRAINT reporte_cobertura_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinical.paciente(patient_id);


--
-- Name: visita_prestacion visita_prestacion_prestacion_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.visita_prestacion
    ADD CONSTRAINT visita_prestacion_prestacion_id_fkey FOREIGN KEY (prestacion_id) REFERENCES reference.catalogo_prestacion(prestacion_id);


--
-- Name: visita_prestacion visita_prestacion_visit_id_fkey; Type: FK CONSTRAINT; Schema: reporting; Owner: -
--

ALTER TABLE ONLY reporting.visita_prestacion
    ADD CONSTRAINT visita_prestacion_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id) ON DELETE CASCADE;


--
-- Name: hospitalizacion hospitalizacion_rut_paciente_fkey; Type: FK CONSTRAINT; Schema: strict; Owner: -
--

ALTER TABLE ONLY strict.hospitalizacion
    ADD CONSTRAINT hospitalizacion_rut_paciente_fkey FOREIGN KEY (rut_paciente) REFERENCES strict.paciente(rut);


--
-- Name: gps_posicion gps_posicion_device_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.gps_posicion
    ADD CONSTRAINT gps_posicion_device_id_fkey FOREIGN KEY (device_id) REFERENCES telemetry.telemetria_dispositivo(device_id);


--
-- Name: posicion_actual posicion_actual_device_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.posicion_actual
    ADD CONSTRAINT posicion_actual_device_id_fkey FOREIGN KEY (device_id) REFERENCES telemetry.telemetria_dispositivo(device_id);


--
-- Name: telemetria_dispositivo telemetria_dispositivo_vehiculo_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_dispositivo
    ADD CONSTRAINT telemetria_dispositivo_vehiculo_id_fkey FOREIGN KEY (vehiculo_id) REFERENCES operational.vehiculo(vehiculo_id);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_conductor_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_conductor_id_fkey FOREIGN KEY (conductor_id) REFERENCES operational.conductor(conductor_id);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_device_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_device_id_fkey FOREIGN KEY (device_id) REFERENCES telemetry.telemetria_dispositivo(device_id);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_provider_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES operational.profesional(provider_id);


--
-- Name: telemetria_resumen_diario telemetria_resumen_diario_route_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_resumen_diario
    ADD CONSTRAINT telemetria_resumen_diario_route_id_fkey FOREIGN KEY (route_id) REFERENCES operational.ruta(route_id);


--
-- Name: telemetria_segmento telemetria_segmento_device_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_segmento
    ADD CONSTRAINT telemetria_segmento_device_id_fkey FOREIGN KEY (device_id) REFERENCES telemetry.telemetria_dispositivo(device_id);


--
-- Name: telemetria_segmento telemetria_segmento_route_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_segmento
    ADD CONSTRAINT telemetria_segmento_route_id_fkey FOREIGN KEY (route_id) REFERENCES operational.ruta(route_id);


--
-- Name: telemetria_segmento telemetria_segmento_visit_id_fkey; Type: FK CONSTRAINT; Schema: telemetry; Owner: -
--

ALTER TABLE ONLY telemetry.telemetria_segmento
    ADD CONSTRAINT telemetria_segmento_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES operational.visita(visit_id);


--
-- Name: matriz_distancia matriz_distancia_dest_zone_id_fkey; Type: FK CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.matriz_distancia
    ADD CONSTRAINT matriz_distancia_dest_zone_id_fkey FOREIGN KEY (dest_zone_id) REFERENCES territorial.zona(zone_id);


--
-- Name: matriz_distancia matriz_distancia_origin_zone_id_fkey; Type: FK CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.matriz_distancia
    ADD CONSTRAINT matriz_distancia_origin_zone_id_fkey FOREIGN KEY (origin_zone_id) REFERENCES territorial.zona(zone_id);


--
-- Name: ubicacion ubicacion_zone_id_fkey; Type: FK CONSTRAINT; Schema: territorial; Owner: -
--

ALTER TABLE ONLY territorial.ubicacion
    ADD CONSTRAINT ubicacion_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES territorial.zona(zone_id);


--
-- Name: estadia; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.estadia ENABLE ROW LEVEL SECURITY;

--
-- Name: estadia estadia_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY estadia_establecimiento ON clinical.estadia USING (((establecimiento_id = current_setting('app.establecimiento_id'::text, true)) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: evaluacion_paliativa; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.evaluacion_paliativa ENABLE ROW LEVEL SECURITY;

--
-- Name: evaluacion_paliativa evaluacion_paliativa_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY evaluacion_paliativa_establecimiento ON clinical.evaluacion_paliativa USING (((stay_id IN ( SELECT estadia.stay_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: medicacion; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.medicacion ENABLE ROW LEVEL SECURITY;

--
-- Name: medicacion medicacion_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY medicacion_establecimiento ON clinical.medicacion USING (((stay_id IN ( SELECT estadia.stay_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: nota_evolucion; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.nota_evolucion ENABLE ROW LEVEL SECURITY;

--
-- Name: nota_evolucion nota_evolucion_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY nota_evolucion_establecimiento ON clinical.nota_evolucion USING (((stay_id IN ( SELECT estadia.stay_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: paciente; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.paciente ENABLE ROW LEVEL SECURITY;

--
-- Name: paciente paciente_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY paciente_establecimiento ON clinical.paciente USING (((patient_id IN ( SELECT estadia.patient_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: voluntad_anticipada; Type: ROW SECURITY; Schema: clinical; Owner: -
--

ALTER TABLE clinical.voluntad_anticipada ENABLE ROW LEVEL SECURITY;

--
-- Name: voluntad_anticipada voluntad_anticipada_establecimiento; Type: POLICY; Schema: clinical; Owner: -
--

CREATE POLICY voluntad_anticipada_establecimiento ON clinical.voluntad_anticipada USING (((stay_id IN ( SELECT estadia.stay_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- Name: visita; Type: ROW SECURITY; Schema: operational; Owner: -
--

ALTER TABLE operational.visita ENABLE ROW LEVEL SECURITY;

--
-- Name: visita visita_establecimiento; Type: POLICY; Schema: operational; Owner: -
--

CREATE POLICY visita_establecimiento ON operational.visita USING (((stay_id IN ( SELECT estadia.stay_id
   FROM clinical.estadia
  WHERE (estadia.establecimiento_id = current_setting('app.establecimiento_id'::text, true)))) OR (current_setting('app.establecimiento_id'::text, true) IS NULL)));


--
-- PostgreSQL database dump complete
--

\unrestrict 7D6sCWVEhLQDnfUa8CZnThmHbx6zhVRizm9yza30rdaaeoGWUYuou4TOyh3bbo8

