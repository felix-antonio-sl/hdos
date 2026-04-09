-- ============================================================================
-- CORR-19: Fix trigger event bindings (109 triggers) + drop duplicate index
--          + add PK to provenance + add 27 missing FK indexes
-- ============================================================================
-- Source: Auditoría 360° convergente (database-designer + senior-backend +
--         arquitecto-categórico) — 2026-04-09
--
-- Fixes:
--   P0-1: 56 triggers set_updated_at:  BEFORE DELETE → BEFORE UPDATE
--   P0-2: 45 triggers check_pe1:       INSERT+DELETE → INSERT OR UPDATE
--   P0-3:  8 triggers stay_coherence:  INSERT+DELETE → INSERT OR UPDATE
--   P1-1: Drop duplicate btree index on telemetry.gps_posicion (saves 8.6 MB)
--   P1-2: Promote UNIQUE to PK on migration.provenance
--   P1-3: Add 27 missing FK indexes
--
-- Properties:
--   - Idempotent (DROP IF EXISTS + CREATE; CREATE INDEX IF NOT EXISTS)
--   - No data changes, no column drops — DDL only
--   - Runs in single transaction for atomicity
--   - Functions (check_pe1, check_stay_coherence, set_updated_at) unchanged
-- ============================================================================

BEGIN;

-- ============================================================================
-- P0-1: Fix 56 set_updated_at triggers (BEFORE DELETE → BEFORE UPDATE)
-- ============================================================================
-- Bug: function uses NEW.updated_at = NOW() but NEW is NULL on DELETE.
-- Effect: updated_at never auto-set on UPDATE; DELETE may silently abort.

-- clinical (39)
DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.alerta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.alerta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.botiquin_domiciliario;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.botiquin_domiciliario
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.condicion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.condicion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.consentimiento;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.consentimiento
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_cuidador_updated_at ON clinical.cuidador;
CREATE TRIGGER trg_cuidador_updated_at BEFORE UPDATE ON clinical.cuidador
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.derivacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.derivacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_dispensacion_updated_at ON clinical.dispensacion;
CREATE TRIGGER trg_dispensacion_updated_at BEFORE UPDATE ON clinical.dispensacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.dispositivo;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.dispositivo
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.documentacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.documentacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.domicilio;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.domicilio
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_educacion_paciente_updated_at ON clinical.educacion_paciente;
CREATE TRIGGER trg_educacion_paciente_updated_at BEFORE UPDATE ON clinical.educacion_paciente
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.epicrisis;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.epicrisis
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.equipo_medico;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.equipo_medico
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.estadia;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.estadia
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.evaluacion_funcional;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_funcional
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.evaluacion_paliativa;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evaluacion_paliativa
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.evento_adverso;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.evento_adverso
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.garantia_ges;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.garantia_ges
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.herida;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.herida
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.indicacion_medica;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.indicacion_medica
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.informe_social;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.informe_social
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.interconsulta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.interconsulta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.lista_espera;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.lista_espera
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.medicacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.medicacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.meta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.meta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.nota_evolucion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.nota_evolucion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.notificacion_obligatoria;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.notificacion_obligatoria
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.oxigenoterapia_domiciliaria;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.oxigenoterapia_domiciliaria
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.paciente;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.paciente
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.plan_cuidado;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.plan_cuidado
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.prestamo_equipo;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.prestamo_equipo
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.procedimiento;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.procedimiento
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.receta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.receta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.sesion_rehabilitacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.sesion_rehabilitacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_sesion_videollamada_updated ON clinical.sesion_videollamada;
CREATE TRIGGER trg_sesion_videollamada_updated BEFORE UPDATE ON clinical.sesion_videollamada
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.solicitud_examen;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.solicitud_examen
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.teleconsulta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.teleconsulta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.valoracion_ingreso;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.valoracion_ingreso
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.voluntad_anticipada;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.voluntad_anticipada
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

-- operational (11)
DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.compra_servicio;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.compra_servicio
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.conductor;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.conductor
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.configuracion_programa;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.configuracion_programa
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.insumo;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.insumo
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.orden_servicio;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.orden_servicio
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.profesional;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.profesional
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_registro_llamada_updated_at ON operational.registro_llamada;
CREATE TRIGGER trg_registro_llamada_updated_at BEFORE UPDATE ON operational.registro_llamada
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.ruta;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.ruta
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_sla_updated_at ON operational.sla;
CREATE TRIGGER trg_sla_updated_at BEFORE UPDATE ON operational.sla
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.vehiculo;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.vehiculo
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON operational.visita;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON operational.visita
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

-- telemetry (1)
DROP TRIGGER IF EXISTS trg_set_updated_at ON telemetry.telemetria_dispositivo;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON telemetry.telemetria_dispositivo
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

-- territorial (5)
DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.establecimiento;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.establecimiento
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.localizacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.localizacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.matriz_distancia;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.matriz_distancia
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.ubicacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.ubicacion
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.zona;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.zona
  FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();


-- ============================================================================
-- P0-2: Fix 45 check_pe1 triggers (INSERT+DELETE → INSERT OR UPDATE)
-- ============================================================================
-- PE-1: T.patient_id = estadia.patient_id (path equation)
-- Must validate on INSERT (new row) and UPDATE (changed stay_id/patient_id).
-- DELETE cannot violate PE-1 — removing a row preserves commutativity.

-- clinical (38)
DROP TRIGGER IF EXISTS trg_alerta_pe1 ON clinical.alerta;
CREATE TRIGGER trg_alerta_pe1 BEFORE INSERT OR UPDATE ON clinical.alerta
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_botiquin_domiciliario_pe1 ON clinical.botiquin_domiciliario;
CREATE TRIGGER trg_botiquin_domiciliario_pe1 BEFORE INSERT OR UPDATE ON clinical.botiquin_domiciliario
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_chat_mensaje_pe1 ON clinical.chat_mensaje;
CREATE TRIGGER trg_chat_mensaje_pe1 BEFORE INSERT OR UPDATE ON clinical.chat_mensaje
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_condicion_pe1 ON clinical.condicion;
CREATE TRIGGER trg_condicion_pe1 BEFORE INSERT OR UPDATE ON clinical.condicion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_consentimiento_pe1 ON clinical.consentimiento;
CREATE TRIGGER trg_consentimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.consentimiento
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_derivacion_pe1 ON clinical.derivacion;
CREATE TRIGGER trg_derivacion_pe1 BEFORE INSERT OR UPDATE ON clinical.derivacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_dispensacion_pe1 ON clinical.dispensacion;
CREATE TRIGGER trg_dispensacion_pe1 BEFORE INSERT OR UPDATE ON clinical.dispensacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_documentacion_pe1 ON clinical.documentacion;
CREATE TRIGGER trg_documentacion_pe1 BEFORE INSERT OR UPDATE ON clinical.documentacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_educacion_paciente_pe1 ON clinical.educacion_paciente;
CREATE TRIGGER trg_educacion_paciente_pe1 BEFORE INSERT OR UPDATE ON clinical.educacion_paciente
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_encuesta_clin_pe1 ON clinical.encuesta_satisfaccion;
CREATE TRIGGER trg_encuesta_clin_pe1 BEFORE INSERT OR UPDATE ON clinical.encuesta_satisfaccion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_epicrisis_pe1 ON clinical.epicrisis;
CREATE TRIGGER trg_epicrisis_pe1 BEFORE INSERT OR UPDATE ON clinical.epicrisis
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_evaluacion_funcional_pe1 ON clinical.evaluacion_funcional;
CREATE TRIGGER trg_evaluacion_funcional_pe1 BEFORE INSERT OR UPDATE ON clinical.evaluacion_funcional
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_evaluacion_paliativa_pe1 ON clinical.evaluacion_paliativa;
CREATE TRIGGER trg_evaluacion_paliativa_pe1 BEFORE INSERT OR UPDATE ON clinical.evaluacion_paliativa
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_evento_adverso_pe1 ON clinical.evento_adverso;
CREATE TRIGGER trg_evento_adverso_pe1 BEFORE INSERT OR UPDATE ON clinical.evento_adverso
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_fotografia_clinica_pe1 ON clinical.fotografia_clinica;
CREATE TRIGGER trg_fotografia_clinica_pe1 BEFORE INSERT OR UPDATE ON clinical.fotografia_clinica
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_garantia_ges_pe1 ON clinical.garantia_ges;
CREATE TRIGGER trg_garantia_ges_pe1 BEFORE INSERT OR UPDATE ON clinical.garantia_ges
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_herida_pe1 ON clinical.herida;
CREATE TRIGGER trg_herida_pe1 BEFORE INSERT OR UPDATE ON clinical.herida
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_indicacion_medica_pe1 ON clinical.indicacion_medica;
CREATE TRIGGER trg_indicacion_medica_pe1 BEFORE INSERT OR UPDATE ON clinical.indicacion_medica
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_informe_social_pe1 ON clinical.informe_social;
CREATE TRIGGER trg_informe_social_pe1 BEFORE INSERT OR UPDATE ON clinical.informe_social
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_interconsulta_pe1 ON clinical.interconsulta;
CREATE TRIGGER trg_interconsulta_pe1 BEFORE INSERT OR UPDATE ON clinical.interconsulta
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_lista_espera_pe1 ON clinical.lista_espera;
CREATE TRIGGER trg_lista_espera_pe1 BEFORE INSERT OR UPDATE ON clinical.lista_espera
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_nota_evolucion_pe1 ON clinical.nota_evolucion;
CREATE TRIGGER trg_nota_evolucion_pe1 BEFORE INSERT OR UPDATE ON clinical.nota_evolucion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_notificacion_pe1 ON clinical.notificacion_obligatoria;
CREATE TRIGGER trg_notificacion_pe1 BEFORE INSERT OR UPDATE ON clinical.notificacion_obligatoria
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_observacion_pe1 ON clinical.observacion;
CREATE TRIGGER trg_observacion_pe1 BEFORE INSERT OR UPDATE ON clinical.observacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_observacion_portal_pe1 ON clinical.observacion_portal;
CREATE TRIGGER trg_observacion_portal_pe1 BEFORE INSERT OR UPDATE ON clinical.observacion_portal
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_oxigenoterapia_domiciliaria_pe1 ON clinical.oxigenoterapia_domiciliaria;
CREATE TRIGGER trg_oxigenoterapia_domiciliaria_pe1 BEFORE INSERT OR UPDATE ON clinical.oxigenoterapia_domiciliaria
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_plan_ejercicios_pe1 ON clinical.plan_ejercicios;
CREATE TRIGGER trg_plan_ejercicios_pe1 BEFORE INSERT OR UPDATE ON clinical.plan_ejercicios
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_portal_mensaje_pe1 ON clinical.portal_mensaje;
CREATE TRIGGER trg_portal_mensaje_pe1 BEFORE INSERT OR UPDATE ON clinical.portal_mensaje
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_prestamo_equipo_pe1 ON clinical.prestamo_equipo;
CREATE TRIGGER trg_prestamo_equipo_pe1 BEFORE INSERT OR UPDATE ON clinical.prestamo_equipo
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_procedimiento_pe1 ON clinical.procedimiento;
CREATE TRIGGER trg_procedimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.procedimiento
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_protocolo_fallecimiento_pe1 ON clinical.protocolo_fallecimiento;
CREATE TRIGGER trg_protocolo_fallecimiento_pe1 BEFORE INSERT OR UPDATE ON clinical.protocolo_fallecimiento
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_receta_pe1 ON clinical.receta;
CREATE TRIGGER trg_receta_pe1 BEFORE INSERT OR UPDATE ON clinical.receta
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_sesion_rehabilitacion_pe1 ON clinical.sesion_rehabilitacion;
CREATE TRIGGER trg_sesion_rehabilitacion_pe1 BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_sesion_videollamada_pe1 ON clinical.sesion_videollamada;
CREATE TRIGGER trg_sesion_videollamada_pe1 BEFORE INSERT OR UPDATE ON clinical.sesion_videollamada
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_solicitud_examen_pe1 ON clinical.solicitud_examen;
CREATE TRIGGER trg_solicitud_examen_pe1 BEFORE INSERT OR UPDATE ON clinical.solicitud_examen
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_teleconsulta_pe1 ON clinical.teleconsulta;
CREATE TRIGGER trg_teleconsulta_pe1 BEFORE INSERT OR UPDATE ON clinical.teleconsulta
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_valoracion_ingreso_pe1 ON clinical.valoracion_ingreso;
CREATE TRIGGER trg_valoracion_ingreso_pe1 BEFORE INSERT OR UPDATE ON clinical.valoracion_ingreso
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_voluntad_pe1 ON clinical.voluntad_anticipada;
CREATE TRIGGER trg_voluntad_pe1 BEFORE INSERT OR UPDATE ON clinical.voluntad_anticipada
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

-- operational (6)
DROP TRIGGER IF EXISTS trg_canasta_valorizada_pe1 ON operational.canasta_valorizada;
CREATE TRIGGER trg_canasta_valorizada_pe1 BEFORE INSERT OR UPDATE ON operational.canasta_valorizada
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_compra_servicio_pe1 ON operational.compra_servicio;
CREATE TRIGGER trg_compra_servicio_pe1 BEFORE INSERT OR UPDATE ON operational.compra_servicio
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_entrega_turno_paciente_pe1 ON operational.entrega_turno_paciente;
CREATE TRIGGER trg_entrega_turno_paciente_pe1 BEFORE INSERT OR UPDATE ON operational.entrega_turno_paciente
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_orden_servicio_pe1 ON operational.orden_servicio;
CREATE TRIGGER trg_orden_servicio_pe1 BEFORE INSERT OR UPDATE ON operational.orden_servicio
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_registro_llamada_pe1 ON operational.registro_llamada;
CREATE TRIGGER trg_registro_llamada_pe1 BEFORE INSERT OR UPDATE ON operational.registro_llamada
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

DROP TRIGGER IF EXISTS trg_visita_pe1 ON operational.visita;
CREATE TRIGGER trg_visita_pe1 BEFORE INSERT OR UPDATE ON operational.visita
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();

-- reporting (1)
DROP TRIGGER IF EXISTS trg_encuesta_rep_pe1 ON reporting.encuesta_satisfaccion;
CREATE TRIGGER trg_encuesta_rep_pe1 BEFORE INSERT OR UPDATE ON reporting.encuesta_satisfaccion
  FOR EACH ROW EXECUTE FUNCTION reference.check_pe1();


-- ============================================================================
-- P0-3: Fix 8 stay_coherence triggers (INSERT+DELETE → INSERT OR UPDATE)
-- ============================================================================
-- stay_coherence: T.stay_id = visita.stay_id (via visit_id)

DROP TRIGGER IF EXISTS trg_documentacion_stay_coherence ON clinical.documentacion;
CREATE TRIGGER trg_documentacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.documentacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_educacion_paciente_stay_coherence ON clinical.educacion_paciente;
CREATE TRIGGER trg_educacion_paciente_stay_coherence BEFORE INSERT OR UPDATE ON clinical.educacion_paciente
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_evento_adverso_stay_coherence ON clinical.evento_adverso;
CREATE TRIGGER trg_evento_adverso_stay_coherence BEFORE INSERT OR UPDATE ON clinical.evento_adverso
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_medicacion_stay_coherence ON clinical.medicacion;
CREATE TRIGGER trg_medicacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.medicacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_nota_evolucion_stay_coherence ON clinical.nota_evolucion;
CREATE TRIGGER trg_nota_evolucion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.nota_evolucion
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_observacion_stay_coherence ON clinical.observacion;
CREATE TRIGGER trg_observacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.observacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_procedimiento_stay_coherence ON clinical.procedimiento;
CREATE TRIGGER trg_procedimiento_stay_coherence BEFORE INSERT OR UPDATE ON clinical.procedimiento
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();

DROP TRIGGER IF EXISTS trg_sesion_rehabilitacion_stay_coherence ON clinical.sesion_rehabilitacion;
CREATE TRIGGER trg_sesion_rehabilitacion_stay_coherence BEFORE INSERT OR UPDATE ON clinical.sesion_rehabilitacion
  FOR EACH ROW EXECUTE FUNCTION reference.check_stay_coherence();


-- ============================================================================
-- P1-1: Drop duplicate index on gps_posicion (saves 8.6 MB)
-- ============================================================================
DROP INDEX IF EXISTS telemetry.idx_gps_posicion_device_dt;


-- ============================================================================
-- P1-2: Promote UNIQUE to PK on migration.provenance — SKIPPED
-- ============================================================================
-- Provenance has legitimate duplicates on (target_table, target_pk, phase):
-- multiple field_name entries per record. PK would need to include field_name,
-- but the existing UNIQUE constraint only covers the 3-column key.
-- Defer to a dedicated provenance cleanup migration.


-- ============================================================================
-- P1-3: Add indexes to FK columns without indexes (27 unique columns)
-- ============================================================================

-- clinical
CREATE INDEX IF NOT EXISTS idx_alerta_stay          ON clinical.alerta (stay_id);
CREATE INDEX IF NOT EXISTS idx_chat_mensaje_sesion   ON clinical.chat_mensaje (sesion_id);
CREATE INDEX IF NOT EXISTS idx_condicion_patient     ON clinical.condicion (patient_id);
CREATE INDEX IF NOT EXISTS idx_enc_clin_patient      ON clinical.encuesta_satisfaccion (patient_id);
CREATE INDEX IF NOT EXISTS idx_enc_clin_stay         ON clinical.encuesta_satisfaccion (stay_id);
CREATE INDEX IF NOT EXISTS idx_evento_adverso_stay   ON clinical.evento_adverso (stay_id);
CREATE INDEX IF NOT EXISTS idx_foto_clinica_patient  ON clinical.fotografia_clinica (patient_id);
CREATE INDEX IF NOT EXISTS idx_indicacion_patient    ON clinical.indicacion_medica (patient_id);
CREATE INDEX IF NOT EXISTS idx_lista_espera_stay     ON clinical.lista_espera (stay_id);
CREATE INDEX IF NOT EXISTS idx_meta_plan             ON clinical.meta (plan_id);
CREATE INDEX IF NOT EXISTS idx_notificacion_stay     ON clinical.notificacion_obligatoria (stay_id);
CREATE INDEX IF NOT EXISTS idx_portal_mensaje_stay   ON clinical.portal_mensaje (stay_id);
CREATE INDEX IF NOT EXISTS idx_protocolo_epicrisis   ON clinical.protocolo_fallecimiento (epicrisis_id);
CREATE INDEX IF NOT EXISTS idx_sesion_video_telecons ON clinical.sesion_videollamada (teleconsulta_id);

-- operational
CREATE INDEX IF NOT EXISTS idx_audit_log_user        ON operational.audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_decision_despacho_prov ON operational.decision_despacho (provider_id);
CREATE INDEX IF NOT EXISTS idx_kb_link_target        ON operational.kb_articulo_link (target_id);
CREATE INDEX IF NOT EXISTS idx_kb_art_tag_tag        ON operational.kb_articulo_tag (tag_id);
CREATE INDEX IF NOT EXISTS idx_kb_doc_tag_tag        ON operational.kb_documento_tag (tag_id);
CREATE INDEX IF NOT EXISTS idx_os_insumo_item        ON operational.orden_servicio_insumo (item_id);
CREATE INDEX IF NOT EXISTS idx_portal_acceso_usuario ON operational.portal_acceso_log (usuario_id);
CREATE INDEX IF NOT EXISTS idx_portal_usr_invitado   ON operational.portal_usuario (invitado_por);
CREATE INDEX IF NOT EXISTS idx_reg_vehicular_route   ON operational.registro_vehicular (route_id);
CREATE INDEX IF NOT EXISTS idx_req_orden_order       ON operational.requerimiento_orden_mapping (order_id);
CREATE INDEX IF NOT EXISTS idx_visita_order          ON operational.visita (order_id);
CREATE INDEX IF NOT EXISTS idx_zona_prof_provider    ON operational.zona_profesional (provider_id);

-- territorial
CREATE INDEX IF NOT EXISTS idx_matriz_dist_dest      ON territorial.matriz_distancia (dest_zone_id);


-- ============================================================================
-- Verification queries (run after COMMIT to confirm)
-- ============================================================================
-- SELECT 'updated_at' AS fix, count(*) AS n
-- FROM pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid
-- WHERE NOT t.tgisinternal AND p.proname = 'set_updated_at'
--   AND t.tgtype & 8 > 0 AND t.tgtype & 16 = 0;  -- fires UPDATE, not DELETE
--
-- SELECT 'pe1' AS fix, count(*) AS n
-- FROM pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid
-- WHERE NOT t.tgisinternal AND p.proname = 'check_pe1'
--   AND t.tgtype & 4 > 0 AND t.tgtype & 8 > 0 AND t.tgtype & 16 = 0;  -- I+U, not D
--
-- SELECT 'stay_coherence' AS fix, count(*) AS n
-- FROM pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid
-- WHERE NOT t.tgisinternal AND p.proname = 'check_stay_coherence'
--   AND t.tgtype & 4 > 0 AND t.tgtype & 8 > 0 AND t.tgtype & 16 = 0;  -- I+U, not D
--
-- SELECT 'gps_dup_gone' AS fix,
--   NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_gps_posicion_device_dt') AS ok;

COMMIT;
