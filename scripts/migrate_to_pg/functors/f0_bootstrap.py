# scripts/migrate_to_pg/functors/f0_bootstrap.py
"""
F0: Bootstrap — DDL execution + strict data staging.

Source:  {} (empty — DDL is the source)
Target:  PG_v4 (100 tables + strict schema + migration schema)
"""

from __future__ import annotations
import sqlite3
from pathlib import Path
import psycopg
try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import ensure_provenance_table
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import ensure_provenance_table  # type: ignore[no-redef]

_STRICT_DDL = """
CREATE SCHEMA IF NOT EXISTS strict;

CREATE TABLE IF NOT EXISTS strict.paciente (
    rut              TEXT PRIMARY KEY,
    nombre           TEXT NOT NULL,
    fecha_nacimiento DATE
);

CREATE TABLE IF NOT EXISTS strict.hospitalizacion (
    id               SERIAL PRIMARY KEY,
    rut_paciente     TEXT NOT NULL REFERENCES strict.paciente(rut),
    fecha_ingreso    DATE NOT NULL,
    fecha_egreso     DATE
);

CREATE INDEX IF NOT EXISTS idx_strict_hosp_rut ON strict.hospitalizacion(rut_paciente);
CREATE INDEX IF NOT EXISTS idx_strict_hosp_fechas ON strict.hospitalizacion(fecha_ingreso, fecha_egreso);
"""


class F0Bootstrap(Functor):
    name = "F0_bootstrap"
    depends_on = []

    def objects(self, conn: psycopg.Connection, sources) -> int:
        # 1. Execute DDL
        ddl_path = Path(sources.strict_db).resolve().parent.parent / "docs" / "models" / "hodom-integrado-pg-v4.sql"
        ddl = ddl_path.read_text(encoding="utf-8")
        conn.execute(ddl)

        # 2. Create strict schema + migration provenance
        conn.execute(_STRICT_DDL)
        ensure_provenance_table(conn)

        # 3. Load strict data from SQLite
        sqlite_conn = sqlite3.connect(sources.strict_db)
        sqlite_conn.row_factory = sqlite3.Row

        patients = sqlite_conn.execute("SELECT rut, nombre, fecha_nacimiento FROM paciente").fetchall()
        for p in patients:
            conn.execute(
                "INSERT INTO strict.paciente (rut, nombre, fecha_nacimiento) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                (p["rut"], p["nombre"], p["fecha_nacimiento"]),
            )

        hosps = sqlite_conn.execute(
            "SELECT rut_paciente, fecha_ingreso, fecha_egreso FROM hospitalizacion"
        ).fetchall()
        for h in hosps:
            conn.execute(
                "INSERT INTO strict.hospitalizacion (rut_paciente, fecha_ingreso, fecha_egreso) VALUES (%s, %s, %s)",
                (h["rut_paciente"], h["fecha_ingreso"], h["fecha_egreso"]),
            )

        sqlite_conn.close()
        return len(patients) + len(hosps)

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F0-STRICT-PAC-COUNT",
                sql="SELECT COUNT(*) FROM strict.paciente",
                expected=673,
            ),
            PathEquation(
                name="PE-F0-STRICT-HOSP-COUNT",
                sql="SELECT COUNT(*) FROM strict.hospitalizacion",
                expected=838,
            ),
            PathEquation(
                name="PE-F0-STRICT-NO-ORPHAN",
                sql="""SELECT h.id FROM strict.hospitalizacion h
                    LEFT JOIN strict.paciente p ON p.rut = h.rut_paciente
                    WHERE p.rut IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F0-DDL-SCHEMAS",
                sql="""SELECT s.expected FROM (
                    VALUES ('reference'),('territorial'),('clinical'),
                           ('operational'),('reporting'),('telemetry')
                ) AS s(expected)
                WHERE s.expected NOT IN (
                    SELECT schema_name FROM information_schema.schemata
                )""",
                expected="empty",
            ),
        ]
