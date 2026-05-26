-- HODOM — Remediar hallazgos de auditoria estructural (cat-thinking)
-- Fecha: 2026-05-26
-- Migracion NO destructiva. Columnas referenciadas por hdos-app se preservan.
--
-- Secciones:
--   A. PK faltante en migration.provenance
--   B. Documentar y backfill condicion_domicilio desde API writes existentes
--   C. Documentar location_id (FK muerta pero referenciada en KPI views)
--   D. Estandarizar updated_at en tablas que lo carecen
--   E. Backfill territorial.localizacion.tipo_zona
--   F. FK en staging.domicilio_normalizado.localizacion_id

BEGIN;

-- ============================================================================
-- A. migration.provenance: agregar PK (surrogate, field_name tiene 38k NULLs)
--    No se puede usar (target_table, target_pk, field_name, phase) porque
--    field_name es NULL en 38,241/62,356 filas (filas de fase pre-field_name).
--    Solucion: surrogate provenance_id via gen_random_uuid().
-- ============================================================================

ALTER TABLE migration.provenance
  ADD COLUMN IF NOT EXISTS provenance_id text;

-- Poblar provenance_id con UUID para filas existentes que no tengan uno
UPDATE migration.provenance
SET provenance_id = 'prv_' || replace(gen_random_uuid()::text, '-', '')
WHERE provenance_id IS NULL;

-- Agregar NOT NULL y PK
ALTER TABLE migration.provenance ALTER COLUMN provenance_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'provenance_pkey'
  ) THEN
    ALTER TABLE migration.provenance ADD PRIMARY KEY (provenance_id);
  END IF;
END $$;

-- Indice para busquedas frecuentes (target_table, target_pk)
CREATE INDEX IF NOT EXISTS idx_provenance_lookup
  ON migration.provenance (target_table, target_pk, phase)
  WHERE target_table IS NOT NULL;

-- ============================================================================
-- B. clinical.estadia.condicion_domicilio: documentar estado actual
--    Columna usada por hdos-app (admision, epicrisis, ficha) para writes.
--    Actualmente 100% NULL porque las estadias migradas no tenian este dato.
--    Se mantiene la columna y su CHECK constraint; el backfill ocurre via writes de la app.
--    NOTA: No es un bug — es datos pendientes de poblacion humana via la app.
-- ============================================================================

-- Documentar en comentario de columna
COMMENT ON COLUMN clinical.estadia.condicion_domicilio IS
'Condicion del domicilio evaluada en admision: adecuada / inadecuada.
 Poblado via hdos-app (admision/evaluar). NULL en estadias migradas desde fuentes historicas.
 CHECK: {adecuada, inadecuada}.';

-- ============================================================================
-- C. operational.visita.location_id: documentar FK muerta
--    0/8986 poblado. FK → territorial.ubicacion (legacy, no poblada).
--    Referenciada en KPI views (drizzle schema: mv_telemetria_kpi_diario).
--    Cadena viva: visita → domicilio → localizacion → (lat,lng).
--    No se dropea: romperia vistas materializadas en hdos-app.
-- ============================================================================

COMMENT ON COLUMN operational.visita.location_id IS
'Legacy FK → territorial.ubicacion. NO POBLADO (0/8986).
 Cadena viva de geolocalizacion: visita → domicilio → localizacion → (lat,lng).
 Referenciado en vistas KPI (mv_telemetria_kpi_diario) via LEFT JOIN — no dropear.';

-- ============================================================================
-- D. Estandarizar updated_at en tablas transaccionales que lo carecen
--    Tablas: chat_mensaje, checklist_ingreso, derivacion_adjunto, diagnostico_egreso,
--            fotografia_clinica, observacion, observacion_portal, protocolo_fallecimiento,
--            resultado_examen, seguimiento_dispositivo, seguimiento_herida,
--            sesion_rehabilitacion_item, toma_muestra, valoracion_hallazgo
-- ============================================================================

DO $$
DECLARE
  tbl text;
  t text[] := ARRAY[
    'clinical.chat_mensaje',
    'clinical.checklist_ingreso',
    'clinical.derivacion_adjunto',
    'clinical.diagnostico_egreso',
    'clinical.fotografia_clinica',
    'clinical.observacion',
    'clinical.observacion_portal',
    'clinical.protocolo_fallecimiento',
    'clinical.resultado_examen',
    'clinical.seguimiento_dispositivo',
    'clinical.seguimiento_herida',
    'clinical.sesion_rehabilitacion_item',
    'clinical.toma_muestra',
    'clinical.valoracion_hallazgo'
  ];
BEGIN
  FOREACH tbl IN ARRAY t LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = split_part(tbl, '.', 1)
        AND table_name = split_part(tbl, '.', 2)
        AND column_name = 'updated_at'
    ) THEN
      EXECUTE format(
        'ALTER TABLE %I.%I ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now()',
        split_part(tbl, '.', 1),
        split_part(tbl, '.', 2)
      );
    END IF;
  END LOOP;
END $$;

-- ============================================================================
-- E. territorial.localizacion.tipo_zona: backfill desde precision_geo y fuente
--    Infiere URBANO/RURAL/PERIURBANO/RURAL_AISLADO:
--      - precision exacta/aproximada con fuente google/nominatim → URBANO
--      - centroide_localidad/comuna o fuente rural geonames → RURAL
--    Deja NULL lo que no se puede inferir con confianza.
-- ============================================================================

UPDATE territorial.localizacion
SET tipo_zona = CASE
    WHEN precision_geo IN ('exacta', 'aproximada')
         AND fuente_coords NOT IN ('centroide_comuna_fallback_staging_v1')
         AND latitud IS NOT NULL
         THEN 'URBANO'
    WHEN precision_geo IN ('centroide_localidad', 'centroide_comuna')
         OR fuente_coords IN ('centroide_comuna_fallback_staging_v1', 'geonames_local_rural_v1')
         THEN 'RURAL'
    ELSE NULL
  END,
  updated_at = now()
WHERE tipo_zona IS NULL;

-- ============================================================================
-- F. staging.domicilio_normalizado.localizacion_id: agregar FK
--    Previo: verificar integridad referencial (200/200 apuntan a localizacion existente).
-- ============================================================================

DO $$
DECLARE
  orphans integer;
BEGIN
  SELECT count(*) INTO orphans
  FROM staging.domicilio_normalizado dn
  WHERE dn.localizacion_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM territorial.localizacion l WHERE l.localizacion_id = dn.localizacion_id);

  IF orphans = 0 AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'domicilio_norm_localizacion_fkey'
  ) THEN
    EXECUTE 'ALTER TABLE staging.domicilio_normalizado
      ADD CONSTRAINT domicilio_norm_localizacion_fkey
      FOREIGN KEY (localizacion_id) REFERENCES territorial.localizacion(localizacion_id)';
  END IF;
END $$;

-- ============================================================================
-- G. Gate de auditoria post-fixes
-- ============================================================================

DROP VIEW IF EXISTS staging.v_audit_fixes_summary;
CREATE OR REPLACE VIEW staging.v_audit_fixes_summary AS
SELECT
  'audit_fixes_2026_05_26' AS phase,
  (SELECT count(*) = 1 FROM pg_constraint WHERE conname = 'provenance_pkey') AS provenance_has_pk,
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema = 'clinical' AND table_name IN ('chat_mensaje','checklist_ingreso','derivacion_adjunto','diagnostico_egreso','fotografia_clinica','observacion','observacion_portal','protocolo_fallecimiento','resultado_examen','seguimiento_dispositivo','seguimiento_herida','sesion_rehabilitacion_item','toma_muestra','valoracion_hallazgo')
     AND column_name = 'updated_at') AS tablas_con_updated_at,
  (SELECT count(*) FROM territorial.localizacion WHERE tipo_zona IS NOT NULL) AS localizaciones_con_tipo_zona,
  (SELECT count(*) FROM territorial.localizacion) AS total_localizaciones,
  (SELECT count(*) = 1 FROM information_schema.table_constraints WHERE constraint_name = 'domicilio_norm_localizacion_fkey') AS domicilio_norm_has_fk,
  now() AS generated_at;

COMMENT ON VIEW staging.v_audit_fixes_summary IS
'Resumen de remediacion estructural 2026-05-26. Seguro para docs.';

COMMIT;

-- ============================================================================
-- Verificacion post-migracion
-- ============================================================================
-- SELECT * FROM staging.v_audit_fixes_summary;
--
-- -- Confirmar que los 14 added_at se agregaron
-- SELECT table_schema || '.' || table_name AS tbl
-- FROM information_schema.columns
-- WHERE table_schema = 'clinical'
--   AND column_name = 'updated_at'
--   AND table_name IN ('chat_mensaje','checklist_ingreso','derivacion_adjunto','diagnostico_egreso','fotografia_clinica','observacion','observacion_portal','protocolo_fallecimiento','resultado_examen','seguimiento_dispositivo','seguimiento_herida','sesion_rehabilitacion_item','toma_muestra','valoracion_hallazgo')
-- ORDER BY table_name;
