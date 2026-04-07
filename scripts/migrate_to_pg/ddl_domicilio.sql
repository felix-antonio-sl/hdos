-- DDL: Modelo domicilio georeferenciado HODOM
-- Aplica sobre hodom-pg (postgresql://hodom:hodom@localhost:5555/hodom)
-- NO incluye BEGIN/COMMIT — la transacción la controla el runner (ComposedFunctor)

-- btree_gist ya existe (verified in hodom-integrado-pg-v4.sql)

-- 1. territorial.localizacion
CREATE TABLE IF NOT EXISTS territorial.localizacion (
    localizacion_id  TEXT PRIMARY KEY,
    direccion_texto  TEXT,
    referencia       TEXT,
    comuna           TEXT,
    localidad        TEXT,
    tipo_zona        TEXT CHECK (tipo_zona IS NULL OR tipo_zona IN (
                         'URBANO','PERIURBANO','RURAL','RURAL_AISLADO')),
    latitud          REAL NOT NULL,
    longitud         REAL NOT NULL,
    precision_geo    TEXT NOT NULL DEFAULT 'aproximada'
                     CHECK (precision_geo IN (
                         'exacta','aproximada','centroide_localidad','centroide_comuna')),
    fuente_coords    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_localizacion_comuna ON territorial.localizacion(comuna);

COMMENT ON TABLE territorial.localizacion IS
    'Obj Loc — punto geografico paciente-level. Coordenadas obligatorias (PE3).';

-- 2. clinical.domicilio
CREATE TABLE IF NOT EXISTS clinical.domicilio (
    domicilio_id     TEXT PRIMARY KEY,
    patient_id       TEXT NOT NULL REFERENCES clinical.paciente(patient_id),
    localizacion_id  TEXT NOT NULL REFERENCES territorial.localizacion(localizacion_id),
    tipo             TEXT NOT NULL CHECK (tipo IN (
                         'principal','alternativo','temporal','eleam')),
    vigente_desde    DATE NOT NULL,
    vigente_hasta    DATE,
    contacto_local   TEXT,
    notas            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PE4: at most one principal domicilio per patient at any time
-- (DO NOTHING trick: constraint is checked on table creation, idempotent via IF NOT EXISTS above)
DO $$ BEGIN
ALTER TABLE clinical.domicilio
    ADD CONSTRAINT excl_domicilio_principal_vigente
    EXCLUDE USING gist (
        patient_id WITH =,
        daterange(vigente_desde, vigente_hasta, '[)') WITH &&
    ) WHERE (tipo = 'principal');
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_domicilio_paciente ON clinical.domicilio(patient_id);
CREATE INDEX IF NOT EXISTS idx_domicilio_vigente ON clinical.domicilio(patient_id, vigente_hasta)
    WHERE vigente_hasta IS NULL;
CREATE INDEX IF NOT EXISTS idx_domicilio_localizacion ON clinical.domicilio(localizacion_id);

COMMENT ON TABLE clinical.domicilio IS
    'Morph pi: Dom -> (Pac x Loc). Binding temporal con exclusion PE4.';

-- 3. Add columns to operational.visita
ALTER TABLE operational.visita
    ADD COLUMN IF NOT EXISTS localizacion_id TEXT REFERENCES territorial.localizacion(localizacion_id),
    ADD COLUMN IF NOT EXISTS domicilio_id    TEXT REFERENCES clinical.domicilio(domicilio_id);

CREATE INDEX IF NOT EXISTS idx_visita_localizacion ON operational.visita(localizacion_id);
CREATE INDEX IF NOT EXISTS idx_visita_domicilio ON operational.visita(domicilio_id);

-- 4. PE1+PE2 trigger
CREATE OR REPLACE FUNCTION clinical.check_visita_domicilio_coherence()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_visita_domicilio_coherence ON operational.visita;
CREATE TRIGGER trg_visita_domicilio_coherence
    BEFORE INSERT OR UPDATE ON operational.visita
    FOR EACH ROW
    EXECUTE FUNCTION clinical.check_visita_domicilio_coherence();

-- 5. View: domicilios vigentes
CREATE OR REPLACE VIEW clinical.v_domicilio_vigente AS
SELECT d.domicilio_id, d.patient_id, d.tipo,
       d.vigente_desde, d.notas, d.contacto_local,
       l.direccion_texto, l.referencia, l.comuna, l.localidad,
       l.latitud, l.longitud, l.precision_geo
  FROM clinical.domicilio d
  JOIN territorial.localizacion l ON l.localizacion_id = d.localizacion_id
 WHERE d.vigente_hasta IS NULL
    OR d.vigente_hasta >= CURRENT_DATE;

-- 6. updated_at triggers for new tables (idempotent)
DROP TRIGGER IF EXISTS trg_set_updated_at ON territorial.localizacion;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON territorial.localizacion
    FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();
DROP TRIGGER IF EXISTS trg_set_updated_at ON clinical.domicilio;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON clinical.domicilio
    FOR EACH ROW EXECUTE FUNCTION reference.set_updated_at();
