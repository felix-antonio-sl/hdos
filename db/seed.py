#!/usr/bin/env python3
"""
Seed HDOS: pacientes y hospitalizaciones desde 2025-01-01.
Solo rut, nombre, fecha_nacimiento, fecha_ingreso, fecha_egreso.
"""

import csv
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "db" / "hdos.db"
SCHEMA_PATH = PROJECT_ROOT / "db" / "schema.sql"
STAYS_CSV = PROJECT_ROOT / "output" / "spreadsheet" / "canonical" / "hospitalization_stay.csv"
PATIENTS_CSV = PROJECT_ROOT / "output" / "spreadsheet" / "canonical" / "patient_master.csv"

FECHA_CORTE = "2025-01-01"


def seed():
    # Leer stays con rut, filtrados desde 2025
    stays = []
    ruts_needed = set()
    with open(STAYS_CSV, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["fecha_ingreso"] < FECHA_CORTE:
                continue
            rut = row["rut"].strip()
            if not rut:
                continue
            stays.append({
                "rut": rut,
                "fecha_ingreso": row["fecha_ingreso"],
                "fecha_egreso": row["fecha_egreso"].strip() or None,
            })
            ruts_needed.add(rut)

    # Leer pacientes con rut que aparecen en stays
    patients = {}
    with open(PATIENTS_CSV, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rut = row["rut"].strip()
            if rut and rut in ruts_needed and rut not in patients:
                patients[rut] = {
                    "rut": rut,
                    "nombre": row["nombre_completo"].strip(),
                    "fecha_nacimiento": row["fecha_nacimiento_date"].strip() or None,
                }

    # Crear BD
    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    with open(SCHEMA_PATH, encoding="utf-8") as f:
        conn.executescript(f.read())

    conn.executemany(
        "INSERT INTO paciente (rut, nombre, fecha_nacimiento) VALUES (:rut, :nombre, :fecha_nacimiento)",
        patients.values(),
    )

    conn.executemany(
        "INSERT INTO hospitalizacion (rut_paciente, fecha_ingreso, fecha_egreso) VALUES (:rut, :fecha_ingreso, :fecha_egreso)",
        stays,
    )

    conn.commit()

    # Validar
    cur = conn.cursor()
    n_pac = cur.execute("SELECT COUNT(*) FROM paciente").fetchone()[0]
    n_hosp = cur.execute("SELECT COUNT(*) FROM hospitalizacion").fetchone()[0]
    orphans = cur.execute("""
        SELECT COUNT(*) FROM hospitalizacion h
        LEFT JOIN paciente p ON h.rut_paciente = p.rut
        WHERE p.rut IS NULL
    """).fetchone()[0]
    conn.close()

    print(f"Pacientes:          {n_pac}")
    print(f"Hospitalizaciones:  {n_hosp}")
    print(f"Huérfanos:          {orphans}")
    print(f"BD: {DB_PATH} ({DB_PATH.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    seed()
