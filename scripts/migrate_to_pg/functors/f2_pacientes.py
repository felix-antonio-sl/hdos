# scripts/migrate_to_pg/functors/f2_pacientes.py
"""
F2: Pacientes — strict ⊕ canonical -> clinical.paciente

Source:  strict.paciente (673, trust=1.0) ⊕ canonical/patient_master.csv (trust=0.8)
Target:  clinical.paciente (673)

The pushout over the pullback by RUT:
  - strict provides: rut, nombre, fecha_nacimiento (ALWAYS wins)
  - canonical enriches: sexo, comuna, cesfam, prevision, contacto, estado_actual
"""

from __future__ import annotations
import csv
import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import patient_id_from_rut
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import patient_id_from_rut  # type: ignore[no-redef]

_SEXO_MAP = {
    "M": "masculino",
    "F": "femenino",
    "masculino": "masculino",
    "femenino": "femenino",
}

_PREVISION_MAP = {
    "FONASA A": "fonasa-a",
    "FONASA B": "fonasa-b",
    "FONASA C": "fonasa-c",
    "FONASA D": "fonasa-d",
    "PRAIS": "prais",
}

_VALID_ESTADOS = {"pre_ingreso", "activo", "egresado", "fallecido"}


class F2Pacientes(Functor):
    name = "F2_pacientes"
    depends_on = ["F0_bootstrap", "F1_territorial"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency: clean previous
        conn.execute("DELETE FROM clinical.paciente WHERE TRUE")

        # Load canonical enrichment index by RUT
        canonical_by_rut: dict[str, dict] = {}
        canon_path = sources.canonical_dir / "patient_master.csv"
        with open(canon_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                rut = row.get("rut", "").strip()
                if rut:
                    canonical_by_rut[rut] = row

        # For each strict patient
        strict_patients = conn.execute(
            "SELECT rut, nombre, fecha_nacimiento FROM strict.paciente"
        ).fetchall()

        n = 0
        for rut, nombre, fdn in strict_patients:
            pid = patient_id_from_rut(rut)
            canon = canonical_by_rut.get(rut, {})

            sexo_raw = canon.get("sexo", "").strip()
            sexo = _SEXO_MAP.get(sexo_raw)

            comuna = canon.get("comuna", "").strip() or None
            cesfam = canon.get("cesfam", "").strip() or None

            prevision_raw = canon.get("prevision", "").strip().upper()
            prevision = _PREVISION_MAP.get(prevision_raw)

            contacto = canon.get("contacto_telefono", "").strip() or None

            estado_raw = canon.get("estado_actual", "").strip().lower()
            estado = estado_raw if estado_raw in _VALID_ESTADOS else None

            conn.execute(
                """
                INSERT INTO clinical.paciente
                    (patient_id, nombre_completo, rut, sexo, fecha_nacimiento,
                     comuna, cesfam, prevision, contacto_telefono, estado_actual)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (pid, nombre, rut, sexo, fdn, comuna, cesfam, prevision, contacto, estado),
            )

            # Provenance: row-level from strict
            eta.record(
                conn,
                target_table="clinical.paciente",
                target_pk=pid,
                source_type="strict",
                source_file="db/hdos.db",
                source_key=rut,
                phase="F2",
            )

            # Provenance: field-level from canonical enrichment
            for fname, fval in {
                "sexo": sexo,
                "comuna": comuna,
                "cesfam": cesfam,
                "prevision": prevision,
                "contacto_telefono": contacto,
                "estado_actual": estado,
            }.items():
                if fval is not None:
                    eta.record(
                        conn,
                        target_table="clinical.paciente",
                        target_pk=pid,
                        source_type="canonical",
                        source_file="patient_master.csv",
                        source_key=rut,
                        phase="F2",
                        field_name=fname,
                    )

            n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F2-IDENTITY",
                sql="SELECT rut FROM clinical.paciente WHERE rut NOT IN (SELECT rut FROM strict.paciente)",
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-SURJECTION",
                sql="SELECT rut FROM strict.paciente WHERE rut NOT IN (SELECT rut FROM clinical.paciente)",
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-NAME-PRESERVE",
                sql="""SELECT p.rut FROM clinical.paciente p
                    JOIN strict.paciente s ON s.rut = p.rut
                    WHERE p.nombre_completo != s.nombre""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-COUNT",
                sql="SELECT COUNT(*) FROM clinical.paciente",
                expected=673,
            ),
        ]
