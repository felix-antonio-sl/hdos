-- CORR-01: Corrección manual de estadías solapadas
-- Fecha: 2026-04-07
-- Contexto: 61 estadías rechazadas por EXCLUDE constraint en F3.
-- Análisis manual identificó 4 fantasmas, 2 egresos incorrectos, 5 estadías rescatables.

BEGIN;

-- Desactivar triggers de estado para correcciones manuales
ALTER TABLE clinical.estadia DISABLE TRIGGER trg_estadia_guard_insert;
ALTER TABLE clinical.estadia DISABLE TRIGGER trg_estadia_guard_estado;

-- =============================================================
-- A. CORRECCIONES EN strict.hospitalizacion
-- =============================================================

-- A1. Eliminar 4 estadías fantasma/preliminares
DELETE FROM strict.hospitalizacion
WHERE rut_paciente = '8598761-5' AND fecha_ingreso = '2025-10-21' AND fecha_egreso IS NULL;

DELETE FROM strict.hospitalizacion
WHERE rut_paciente = '9633715-9' AND fecha_ingreso = '2025-09-25' AND fecha_egreso IS NULL;

DELETE FROM strict.hospitalizacion
WHERE rut_paciente = '4699408-6' AND fecha_ingreso = '2025-10-14' AND fecha_egreso IS NULL;

DELETE FROM strict.hospitalizacion
WHERE rut_paciente = '5465758-7' AND fecha_ingreso = '2026-03-04' AND fecha_egreso IS NULL;

-- A2. Corregir egresos en strict
UPDATE strict.hospitalizacion
SET fecha_egreso = '2026-03-23'
WHERE rut_paciente = '3163330-3' AND fecha_ingreso = '2025-10-20' AND fecha_egreso = '2026-03-30';

UPDATE strict.hospitalizacion
SET fecha_egreso = '2026-03-30'
WHERE rut_paciente = '4323133-2' AND fecha_ingreso = '2026-03-25' AND fecha_egreso IS NULL;

-- =============================================================
-- B. CORRECCIONES EN clinical.estadia
-- =============================================================

-- B1. Eliminar las 3 estadías fantasma de clinical
DELETE FROM clinical.estadia WHERE stay_id = 'stay_ea0a541e723f';
DELETE FROM clinical.estadia WHERE stay_id = 'stay_fc4ccd1324e5';
DELETE FROM clinical.estadia WHERE stay_id = 'stay_6d049b16b7b3';

-- B2. Corregir egresos en clinical
UPDATE clinical.estadia
SET fecha_egreso = '2026-03-23', estado = 'egresado', updated_at = NOW()
WHERE stay_id = 'stay_dac94d22e693';

UPDATE clinical.estadia
SET fecha_egreso = '2026-03-30', estado = 'egresado', updated_at = NOW()
WHERE stay_id = 'stay_bbee6d732d04';

-- B3. Insertar las 5 estadías previamente bloqueadas

-- 8598761-5: Oct 28 → Nov 05, ACV ISQUEMICO
INSERT INTO clinical.estadia
  (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado, diagnostico_principal, tipo_egreso)
VALUES
  ('stay_2e744d2b9816', 'pt_2892565378d162ea', '2025-10-28', '2025-11-05', 'egresado',
   'I64-ACCIDENTE VASCULAR ENCEFALICO AGUDO, NO ESP.COMO HEMORRAGICO', 'alta_clinica');

-- 9633715-9: Sep 29 → Oct 06, CONVULSIONES
INSERT INTO clinical.estadia
  (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado, diagnostico_principal, tipo_egreso)
VALUES
  ('stay_81bef8bfeafc', 'pt_3c0c0a68a1ef63c2', '2025-09-29', '2025-10-06', 'egresado',
   'R56.8-OTRAS CONVULSIONES Y LAS NO ESPECIFICADAS', 'alta_clinica');

-- 4699408-6: Dec 01 → Dec 05, ITU
INSERT INTO clinical.estadia
  (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado, diagnostico_principal, tipo_egreso)
VALUES
  ('stay_54d1760ce2de', 'pt_74737433f27b156e', '2025-12-01', '2025-12-05', 'egresado',
   'ITU', 'alta_clinica');

-- 3163330-3: Mar 24 → NULL, NEUMONIA (reingreso)
INSERT INTO clinical.estadia
  (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado, diagnostico_principal)
VALUES
  ('stay_592a294cf10c', 'pt_84dc4b5e5d272146', '2026-03-24', NULL, 'activo',
   'J18-NEUMONIA, ORGANISMO NO ESPECIFICADO');

-- 4323133-2: Mar 31 → NULL, HEMORRAGIA GI (reingreso)
INSERT INTO clinical.estadia
  (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado, diagnostico_principal)
VALUES
  ('stay_0ccde0059602', 'pt_f8665241652134c7', '2026-03-31', NULL, 'activo',
   'K92.2-HEMORRAGIA GASTROINTESTINAL, NO ESPECIFICADA');

-- =============================================================
-- C. PROVENIENCIA
-- =============================================================

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
VALUES
  ('strict.hospitalizacion', 'DELETE:8598761-5|2025-10-21', 'manual_correction', 'handoff-2026-04-06.md', 'Registro preliminar SGH #357663 sin egreso, supersedido por #358576', 'CORR-01', 'delete_phantom'),
  ('strict.hospitalizacion', 'DELETE:9633715-9|2025-09-25', 'manual_correction', 'handoff-2026-04-06.md', 'Registro preliminar SGH #354192 sin egreso, supersedido por #354867', 'CORR-01', 'delete_phantom'),
  ('strict.hospitalizacion', 'DELETE:4699408-6|2025-10-14', 'manual_correction', 'handoff-2026-04-06.md', 'Estadía fantasma confidence low, sin fuente rastreable', 'CORR-01', 'delete_phantom'),
  ('strict.hospitalizacion', 'DELETE:5465758-7|2026-03-04', 'manual_correction', 'handoff-2026-04-06.md', 'Registro SGH #375643 interno durante Stay Feb 27-Mar 09', 'CORR-01', 'delete_phantom'),
  ('strict.hospitalizacion', 'UPDATE:3163330-3|2025-10-20', 'manual_correction', 'handoff-2026-04-06.md', 'Egreso ajustado Mar 30 a Mar 23: reingreso Mar 24 por neumonia', 'CORR-01', 'fecha_egreso'),
  ('strict.hospitalizacion', 'UPDATE:4323133-2|2026-03-25', 'manual_correction', 'handoff-2026-04-06.md', 'Egreso fijado Mar 30: reingreso Mar 31 por hemorragia GI', 'CORR-01', 'fecha_egreso'),
  ('clinical.estadia', 'stay_2e744d2b9816', 'manual_correction', 'SGH #358576', '8598761-5|2025-10-28 ACV', 'CORR-01', 'insert_rescued'),
  ('clinical.estadia', 'stay_81bef8bfeafc', 'manual_correction', 'SGH #354867', '9633715-9|2025-09-29 CONVULSIONES', 'CORR-01', 'insert_rescued'),
  ('clinical.estadia', 'stay_54d1760ce2de', 'manual_correction', 'Planilla Altas 26', '4699408-6|2025-12-01 ITU', 'CORR-01', 'insert_rescued'),
  ('clinical.estadia', 'stay_592a294cf10c', 'manual_correction', 'INGRESOS.csv #133', '3163330-3|2026-03-24 NEUMONIA reingreso', 'CORR-01', 'insert_rescued'),
  ('clinical.estadia', 'stay_0ccde0059602', 'manual_correction', 'SGH #378913', '4323133-2|2026-03-31 HEMORRAGIA GI reingreso', 'CORR-01', 'insert_rescued');

-- Reactivar triggers
ALTER TABLE clinical.estadia ENABLE TRIGGER trg_estadia_guard_insert;
ALTER TABLE clinical.estadia ENABLE TRIGGER trg_estadia_guard_estado;

COMMIT;
