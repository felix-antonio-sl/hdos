#!/usr/bin/env python3
"""
CORR-14: Cargar 33 encuestas de satisfacción usuaria en PG.

Fuente: documentacion-legacy/drive-hodom/RESPUESTA SATISFACCIÓN USUARIA.xlsx
Target: reporting.encuesta_satisfaccion (DDL incluido)

Vincula a paciente por nombre fuzzy. 45 columnas del formulario Google
se normalizan a campos estructurados con escalas Likert numéricas.
"""

from __future__ import annotations

import hashlib
import re
import sys
import unicodedata
from datetime import date, datetime
from pathlib import Path

import openpyxl
import psycopg


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s).strip().upper()
    return s


def _likert_to_int(val) -> int | None:
    """Convert Likert text to 1-5 scale."""
    if val is None:
        return None
    s = str(val).strip()
    m = re.match(r'^(\d)', s)
    if m:
        return int(m.group(1))
    mapping = {
        'SI': 1, 'NO': 0,
        'TOTALMENTE': 5, 'MUCHO': 4, 'ALGO': 3, 'POCO': 2, 'NADA': 1,
    }
    return mapping.get(s.upper())


def _to_date(val) -> date | None:
    if val is None:
        return None
    if isinstance(val, datetime):
        return val.date()
    if isinstance(val, date):
        return val
    return None


def _bool_from_sino(val) -> bool | None:
    if val is None:
        return None
    s = str(val).strip().upper()
    if s == 'SI' or s == 'SÍ':
        return True
    if s == 'NO':
        return False
    return None


DDL = """
CREATE TABLE IF NOT EXISTS reporting.encuesta_satisfaccion (
    encuesta_id         TEXT PRIMARY KEY,
    patient_id          TEXT REFERENCES clinical.paciente(patient_id),
    stay_id             TEXT REFERENCES clinical.estadia(stay_id),

    -- Metadata
    nombre_paciente     TEXT NOT NULL,
    nombre_encuestado   TEXT,
    parentesco          TEXT,
    rut_encuestado      TEXT,
    telefono            TEXT,
    fecha_encuesta      DATE,
    fecha_ingreso       DATE,
    fecha_alta          DATE,
    marca_temporal      TIMESTAMPTZ,

    -- Informado al ingreso (bool)
    informado_normas_ingreso  BOOLEAN,

    -- Tiempo dedicado por profesional (bool: suficiente?)
    tiempo_medico       BOOLEAN,
    tiempo_enfermeria   BOOLEAN,
    tiempo_kinesiologia BOOLEAN,
    tiempo_fonoaudiologia BOOLEAN,
    tiempo_tens         BOOLEAN,

    -- Atención completa (bool)
    atencion_examenes      BOOLEAN,
    atencion_procedimientos BOOLEAN,
    atencion_medicamentos  BOOLEAN,

    -- Satisfacción general (1-5 Likert)
    sat_conocimiento    SMALLINT CHECK (sat_conocimiento BETWEEN 1 AND 5),
    sat_informacion     SMALLINT CHECK (sat_informacion BETWEEN 1 AND 5),
    sat_confidencialidad SMALLINT CHECK (sat_confidencialidad BETWEEN 1 AND 5),
    sat_escucha         SMALLINT CHECK (sat_escucha BETWEEN 1 AND 5),
    sat_amabilidad      SMALLINT CHECK (sat_amabilidad BETWEEN 1 AND 5),

    -- Alta médico (bool)
    alta_med_tratamiento   BOOLEAN,
    alta_med_sintomas      BOOLEAN,
    alta_med_seguimiento   BOOLEAN,
    alta_med_informe       BOOLEAN,

    -- Alta enfermería (bool)
    alta_enf_indicaciones  BOOLEAN,
    alta_enf_sintomas      BOOLEAN,
    alta_enf_pasos         BOOLEAN,
    alta_enf_informe       BOOLEAN,

    -- Alta kinesiología (bool)
    alta_kine_ejercicios   BOOLEAN,
    alta_kine_sintomas     BOOLEAN,
    alta_kine_seguimiento  BOOLEAN,
    alta_kine_informe      BOOLEAN,

    -- Alta fonoaudiología (bool)
    alta_fono_tratamiento  BOOLEAN,
    alta_fono_sintomas     BOOLEAN,
    alta_fono_seguimiento  BOOLEAN,
    alta_fono_informe      BOOLEAN,

    -- Resultado percibido
    mejoria_percibida      TEXT,  -- TOTALMENTE / MUCHO / ALGO / POCO / NADA
    conformidad_fallecimiento TEXT,  -- solo si aplica

    -- Asistencia telefónica
    atencion_telefonica    TEXT,

    -- Valoración global
    volveria_hodom         TEXT,  -- Sí volvería / Probablemente no / etc.

    -- Score calculado (promedio Likert 1-5)
    score_satisfaccion     REAL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_encuesta_patient ON reporting.encuesta_satisfaccion(patient_id);
CREATE INDEX IF NOT EXISTS idx_encuesta_stay ON reporting.encuesta_satisfaccion(stay_id);
"""


def load_surveys(xlsx_path: str, db_url: str, dry_run: bool = False):
    wb = openpyxl.load_workbook(xlsx_path)
    ws = wb.active

    conn = psycopg.connect(db_url, autocommit=False)

    # Create table
    if not dry_run:
        conn.execute(DDL)
        conn.execute("DELETE FROM reporting.encuesta_satisfaccion WHERE TRUE")

    # Build patient name index
    name_index = {}
    for pid, nombre in conn.execute(
        "SELECT patient_id, nombre_completo FROM clinical.paciente"
    ).fetchall():
        name_index[_normalize(nombre)] = pid

    # patient_id → latest stay
    stay_lookup = {}
    for sid, pid in conn.execute(
        "SELECT stay_id, patient_id FROM clinical.estadia ORDER BY fecha_ingreso DESC"
    ).fetchall():
        if pid not in stay_lookup:
            stay_lookup[pid] = sid

    inserted = 0
    unmatched = []

    for row in ws.iter_rows(min_row=2, values_only=True):
        if not any(v is not None for v in row):
            continue

        # Row mapping (0-indexed)
        nombre_pac = str(row[6] or '').strip()
        if not nombre_pac:
            continue

        # Match to patient
        norm = _normalize(nombre_pac)
        patient_id = name_index.get(norm)
        if not patient_id:
            for idx_name, pid in name_index.items():
                if norm in idx_name or idx_name in norm:
                    patient_id = pid
                    break

        stay_id = stay_lookup.get(patient_id) if patient_id else None

        if not patient_id:
            unmatched.append(nombre_pac)

        # Likert scores
        sat_scores = [
            _likert_to_int(row[20]),  # conocimiento
            _likert_to_int(row[21]),  # información
            _likert_to_int(row[22]),  # confidencialidad
            _likert_to_int(row[23]),  # escucha
            _likert_to_int(row[24]),  # amabilidad
        ]
        valid_scores = [s for s in sat_scores if s is not None and 1 <= s <= 5]
        score = round(sum(valid_scores) / len(valid_scores), 2) if valid_scores else None

        raw_id = f"enc|{nombre_pac}|{row[0]}"
        encuesta_id = "enc_" + hashlib.sha256(raw_id.encode()).hexdigest()[:12]

        record = (
            encuesta_id, patient_id, stay_id,
            nombre_pac,
            str(row[1] or '').strip() or None,  # nombre_encuestado
            str(row[4] or '').strip() or None,  # parentesco
            str(row[2] or '').strip() or None,  # rut_encuestado
            str(row[3] or '').strip() or None,  # telefono
            _to_date(row[5]),                    # fecha_encuesta
            _to_date(row[8]),                    # fecha_ingreso
            _to_date(row[9]),                    # fecha_alta
            row[0] if isinstance(row[0], datetime) else None,  # marca_temporal

            _bool_from_sino(row[11]),  # informado_normas

            # Tiempo profesional
            _bool_from_sino(row[12]),  # medico
            _bool_from_sino(row[13]),  # enfermeria
            _bool_from_sino(row[14]),  # kinesiologia
            _bool_from_sino(row[15]),  # fonoaudiologia
            _bool_from_sino(row[16]),  # tens

            # Atención completa
            _bool_from_sino(row[17]),  # examenes
            _bool_from_sino(row[18]),  # procedimientos
            _bool_from_sino(row[19]),  # medicamentos

            # Satisfacción Likert
            sat_scores[0], sat_scores[1], sat_scores[2], sat_scores[3], sat_scores[4],

            # Alta médico
            _bool_from_sino(row[25]),
            _bool_from_sino(row[26]),
            _bool_from_sino(row[27]),
            _bool_from_sino(row[28]),

            # Alta enfermería
            _bool_from_sino(row[29]),
            _bool_from_sino(row[30]),
            _bool_from_sino(row[31]),
            _bool_from_sino(row[32]),

            # Alta kinesiología
            _bool_from_sino(row[33]),
            _bool_from_sino(row[34]),
            _bool_from_sino(row[35]),
            _bool_from_sino(row[36]),

            # Alta fonoaudiología
            _bool_from_sino(row[37]),
            _bool_from_sino(row[38]),
            _bool_from_sino(row[39]),
            _bool_from_sino(row[40]),

            # Resultado
            str(row[41] or '').strip() or None,
            str(row[42] or '').strip() or None,
            str(row[43] or '').strip() or None,
            str(row[44] or '').strip() or None,

            score,
        )

        if not dry_run:
            conn.execute(
                """
                INSERT INTO reporting.encuesta_satisfaccion VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s, %s
                )
                ON CONFLICT (encuesta_id) DO NOTHING
                """,
                record,
            )

            if patient_id:
                conn.execute(
                    """
                    INSERT INTO migration.provenance
                        (target_table, target_pk, source_type, source_file, source_key, phase)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (
                        "reporting.encuesta_satisfaccion", encuesta_id,
                        "forms", "RESPUESTA SATISFACCIÓN USUARIA.xlsx",
                        norm, "CORR-14",
                    ),
                )

        inserted += 1

    if not dry_run:
        conn.commit()
    conn.close()

    return {'inserted': inserted, 'unmatched': unmatched}


def main():
    import argparse
    parser = argparse.ArgumentParser(description="CORR-14: Satisfacción usuaria → PG")
    parser.add_argument("--db-url", default="postgresql://hodom:hodom@localhost:5555/hodom")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--xlsx", default="documentacion-legacy/drive-hodom/RESPUESTA SATISFACCIÓN USUARIA.xlsx")
    args = parser.parse_args()

    result = load_surveys(args.xlsx, args.db_url, args.dry_run)

    print(f"Encuestas insertadas: {result['inserted']}")
    if result['unmatched']:
        print(f"\nSin match a paciente ({len(result['unmatched'])}):")
        for name in result['unmatched']:
            print(f"  - {name}")

    if not result['unmatched']:
        print("Todos los pacientes vinculados exitosamente.")

    # Quick stats
    if not args.dry_run:
        conn = psycopg.connect(args.db_url)
        stats = conn.execute("""
            SELECT
                count(*) as total,
                count(patient_id) as vinculados,
                round(avg(score_satisfaccion)::numeric, 2) as score_promedio,
                count(CASE WHEN volveria_hodom ILIKE '%%volvería%%' THEN 1 END) as volverian
            FROM reporting.encuesta_satisfaccion
        """).fetchone()
        conn.close()

        print(f"\n--- Estadísticas ---")
        print(f"Total:              {stats[0]}")
        print(f"Vinculados:         {stats[1]}")
        print(f"Score promedio:     {stats[2]}")
        print(f"Volverían a HODOM:  {stats[3]}")


if __name__ == "__main__":
    main()
