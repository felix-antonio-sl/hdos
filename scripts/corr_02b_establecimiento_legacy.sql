-- CORR-02b: Resolver establecimiento_id adicionales desde fuentes legacy
-- Fecha: 2026-04-07
-- Contexto: 145 estadías sin establecimiento tras CORR-02.
--   Búsqueda en formularios HODOM (campo CESFAM INSCRITO), raw CSVs (COMUNA),
--   y domicilio del paciente para inferir comuna.
--   22 estadías adicionales resolvables. 123 quedan NULL (solo-SGH, sin CESFAM en ninguna fuente).

BEGIN;

-- 17 via legacy cesfam (formularios HODOM con CESFAM real != OTRO)
UPDATE clinical.estadia SET establecimiento_id = 'est_afb315ffeb72b6e0', updated_at = NOW()
WHERE stay_id IN ('stay_1247910a3b2d','stay_fd93df6873b5','stay_014473c47c49','stay_ea5e17a0e708',
                  'stay_b70c3093a005','stay_3716aa76cbd8','stay_c035fb63d9ad','stay_126b74ac67a6',
                  'stay_a2c674482f9a');

UPDATE clinical.estadia SET establecimiento_id = 'est_4a50d9e625a5c238', updated_at = NOW()
WHERE stay_id IN ('stay_d68c61aabc7b','stay_a255687e9809','stay_f1bf173e4136','stay_44e5db6cb77c',
                  'stay_10dd7c15d0ce','stay_3ffa1e871113','stay_40ea052803c0','stay_122d57922a54');

-- 2 via legacy comuna (raw CSVs COMUNA = SAN NICOLAS)
UPDATE clinical.estadia SET establecimiento_id = 'est_f0a60ee7272ef18f', updated_at = NOW()
WHERE stay_id IN ('stay_f554be253a2b','stay_0a54bbc92507');

-- 3 via domicilio inferido
UPDATE clinical.estadia SET establecimiento_id = 'est_f0a60ee7272ef18f', updated_at = NOW()
WHERE stay_id IN ('stay_d47e2786dc47','stay_fad8930018f5');  -- Puente Ñuble → San Nicolás

UPDATE clinical.estadia SET establecimiento_id = 'est_fb7015e64870d8ac', updated_at = NOW()
WHERE stay_id = 'stay_7ad0fa513419';  -- Torrecillas → Ñiquén

-- Proveniencia
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
VALUES
  ('clinical.estadia', 'stay_1247910a3b2d', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '10135212-9 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_fd93df6873b5', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '2626520-7 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_014473c47c49', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '2626520-7 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_ea5e17a0e708', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '3333712-4 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_b70c3093a005', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '4648808-3 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_3716aa76cbd8', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '4648808-3 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_c035fb63d9ad', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '4829567-3 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_126b74ac67a6', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '6048058-3 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_a2c674482f9a', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '6109150-5 cesfam:C. T. BALDECCHI', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_d68c61aabc7b', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '3850038-4 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_a255687e9809', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '6423143-K cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_f1bf173e4136', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '7624826-5 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_44e5db6cb77c', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '7624826-5 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_10dd7c15d0ce', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '7624826-5 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_3ffa1e871113', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '7624826-5 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_40ea052803c0', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '9732545-6 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_122d57922a54', 'manual_correction', 'formulario-hodom-2025-respuestas.csv', '9732545-6 cesfam:C. DURÁN TRUJILLO', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_f554be253a2b', 'manual_correction', 'raw_csv_exports', '3977867-K comuna:SAN NICOLAS', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_0a54bbc92507', 'manual_correction', 'raw_csv_exports', '3977867-K comuna:SAN NICOLAS', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_d47e2786dc47', 'manual_correction', 'domicilio', '13127870-5 dom:PUENTE ÑUBLE', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_fad8930018f5', 'manual_correction', 'domicilio', '3761046-1 dom:PUENTE ÑUBLE', 'CORR-02b', 'establecimiento_id'),
  ('clinical.estadia', 'stay_7ad0fa513419', 'manual_correction', 'domicilio', '20112080-2 dom:TORRECILLAS', 'CORR-02b', 'establecimiento_id');

COMMIT;
