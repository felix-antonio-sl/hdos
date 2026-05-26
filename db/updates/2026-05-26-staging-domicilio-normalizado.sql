-- HODOM — Staging: domicilio_normalizado para geocodificacion batch
-- Tabla intermedia entre staging.hodom_ingreso_2026 y territorial.localizacion.
-- Normaliza, estandariza y desduplica direcciones antes de geocodificar.
--
-- Reglas:
--   1. Una fila por direccion normalizada unica (clave: hash de direccion + comuna).
--   2. Vincula con localizacion existente si la direccion ya fue geocodificada.
--   3. Agrupa todos los ingreso_id del staging que comparten la misma direccion normalizada.
--   4. Sin PII exportable directamente (los domicilios crudos son direcciones, no nombres/RUT).

BEGIN;

DROP TABLE IF EXISTS staging.domicilio_normalizado;
CREATE TABLE staging.domicilio_normalizado (
    domicilio_norm_id   text PRIMARY KEY,
    direccion_original  text NOT NULL,
    direccion_normalizada text NOT NULL,
    comuna              text,
    comuna_normalizada  text NOT NULL,
    frecuencia          integer NOT NULL DEFAULT 1,
    staging_ids         text[] NOT NULL DEFAULT '{}',
    localizacion_id     text,
    ya_geocodificado    boolean NOT NULL DEFAULT false,
    calidad_notas       text,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_domicilio_norm_comuna
    ON staging.domicilio_normalizado (comuna_normalizada);

CREATE INDEX IF NOT EXISTS idx_domicilio_norm_localizacion
    ON staging.domicilio_normalizado (localizacion_id) WHERE localizacion_id IS NOT NULL;

COMMENT ON TABLE staging.domicilio_normalizado IS
'Direcciones normalizadas desde staging.hodom_ingreso_2026 listas para geocodificar.
 Una fila por direccion normalizada unica. Vincula con territorial.localizacion si ya existe.
 Sin nombres ni RUT — las direcciones pueden contener referencias geograficas pero no PII.';

COMMENT ON COLUMN staging.domicilio_normalizado.direccion_original IS
'Direccion tal como aparece en staging.hodom_ingreso_2026 (primera ocurrencia encontrada).';

COMMENT ON COLUMN staging.domicilio_normalizado.direccion_normalizada IS
'Direccion tras normalizacion: uppercase, espacios normalizados, abreviaturas expandidas,
 comuna removida del texto, formato KM/S/N estandarizado.';

COMMENT ON COLUMN staging.domicilio_normalizado.comuna IS
'Comuna original del staging (puede tener typos como SANCARLOS, SAN  NICOLAS).';

COMMENT ON COLUMN staging.domicilio_normalizado.comuna_normalizada IS
'Comuna normalizada (SAN CARLOS, NIQUEN, SAN NICOLAS, SAN GREGORIO, etc.).';

COMMENT ON COLUMN staging.domicilio_normalizado.staging_ids IS
'Array de ingreso_id en staging.hodom_ingreso_2026 que comparten esta direccion normalizada.';

COMMENT ON COLUMN staging.domicilio_normalizado.localizacion_id IS
'FK a territorial.localizacion si la direccion ya fue geocodificada (match por texto + comuna).';

COMMIT;
