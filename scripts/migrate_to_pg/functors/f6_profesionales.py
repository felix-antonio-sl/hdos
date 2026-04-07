# scripts/migrate_to_pg/functors/f6_profesionales.py
"""
F₆: Profesionales — legacy XLSX estadísticas + programación → operational.profesional

Sources:
  - ESTADÍSTICAS POR PROFESIONAL/: XLSX por enfermera (nombre en filename + sheet data)
  - PROGRAMACIÓN: nombres de gestoras en formularios HODOM
  - Consolidado atenciones: profesiones activas

We extract unique provider names from:
  1. XLSX filenames in ENFERMERAS/ (4 files)
  2. Sheet data: column headers or known gestora names
  3. Formulario HODOM: NOMBRE POSTULANTE (gestora)

Deduplication by normalized name (uppercase, no tildes, trimmed).
"""

from __future__ import annotations
import csv
import re
import unicodedata
from pathlib import Path

import psycopg

try:
    import openpyxl
except ImportError:
    openpyxl = None  # type: ignore[assignment]

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import make_id
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import make_id  # type: ignore[no-redef]


def _normalize(name: str) -> str:
    """Normalize name for deduplication: uppercase, strip accents, collapse whitespace."""
    s = unicodedata.normalize("NFD", name)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s).strip().upper()
    return s


# Known professionals from HODOM data (manually curated from all sources)
_KNOWN_PROFESSIONALS = {
    # Enfermería
    "BERENICE MELLA": "ENFERMERIA",
    "CAMILA ANDRADE": "ENFERMERIA",
    "PIA VALLEJOS": "ENFERMERIA",
    "VANIA LEAL": "ENFERMERIA",
    "JUAN ZUÑIGA": "ENFERMERIA",
    "JUAN ZUNIGA": "ENFERMERIA",
    # Kinesiología
    "KINESIOLOGO": "KINESIOLOGIA",  # generic in consolidado
    # Fonoaudiología
    "FONOAUDIOLOGO": "FONOAUDIOLOGIA",
    # TENS
    "CARLOS MUÑOZ": "TENS",
    "CARLOS MUNOZ": "TENS",
    # Trabajo Social
    "TRABAJADOR SOCIAL": "TRABAJO_SOCIAL",
    # Gestoras (from formularios)
    "MELISSA RIVERA": "ENFERMERIA",
    "MELISSA SEPULVEDA": "ENFERMERIA",
    "MELISSA RIVERA S.": "ENFERMERIA",
    "DORIS GONZALEZ": "ENFERMERIA",
    "PIA VASQUEZ M": "ENFERMERIA",
    "PIA VASQUEZ": "ENFERMERIA",
    "HECTOR VERGARA ESPEJO": "MEDICO",
    "HECTOR VERGARA": "MEDICO",
}

_PROFESION_REM = {
    "ENFERMERIA": "enfermera",
    "KINESIOLOGIA": "kinesiologo",
    "FONOAUDIOLOGIA": "fonoaudiologo",
    "MEDICO": "medico",
    "TRABAJO_SOCIAL": "trabajador_social",
    "TENS": "tecnico_enfermeria",
}


class F6Profesionales(Functor):
    name = "F6_profesionales"
    depends_on = ["F0_bootstrap"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM operational.profesional WHERE TRUE")

        providers: dict[str, dict] = {}  # normalized_name → {name, profesion, source}

        # 1. Extract from known list
        for name, profesion in _KNOWN_PROFESSIONALS.items():
            norm = _normalize(name)
            if norm not in providers:
                providers[norm] = {
                    "name": name.title(),
                    "profesion": profesion,
                    "source": "known_list",
                }

        # 2. Extract from formulario gestoras
        for form_name in [
            "formulario-hodom-2025-respuestas.csv",
            "formulario-hodom-2025-copia-export-2024-05-20-respuestas.csv",
            "formulario-hodom-2026-respuestas.csv",
        ]:
            form_path = (
                sources.legacy_dir / ".." / ".."
                / "input" / "reference" / "legacy_imports"
                / "form_response_exports" / form_name
            )
            if not form_path.exists():
                # Try alternate path
                form_path = Path("input/reference/legacy_imports/form_response_exports") / form_name
            if not form_path.exists():
                continue
            with open(form_path, newline="", encoding="utf-8") as f:
                reader = csv.reader(f)
                header = next(reader)
                gestora_idx = None
                for i, h in enumerate(header):
                    if "POSTULANTE" in h.upper() or "GESTOR" in h.upper():
                        gestora_idx = i
                        break
                if gestora_idx is None:
                    continue
                for row in reader:
                    if len(row) <= gestora_idx:
                        continue
                    name = row[gestora_idx].strip()
                    if not name or len(name) < 3:
                        continue
                    norm = _normalize(name)
                    if norm not in providers:
                        providers[norm] = {
                            "name": name.title(),
                            "profesion": "ENFERMERIA",  # gestoras are nurses
                            "source": f"formulario:{form_name}",
                        }

        # 3. Insert into PG
        n = 0
        for norm, info in providers.items():
            provider_id = make_id("prov", norm)
            profesion_rem = _PROFESION_REM.get(info["profesion"])

            conn.execute(
                """
                INSERT INTO operational.profesional
                    (provider_id, nombre, profesion, profesion_rem, estado)
                VALUES (%s, %s, %s, %s, 'activo')
                ON CONFLICT (provider_id) DO NOTHING
                """,
                (provider_id, info["name"], info["profesion"], profesion_rem),
            )

            eta.record(
                conn,
                target_table="operational.profesional",
                target_pk=provider_id,
                source_type="legacy",
                source_file=info["source"],
                source_key=norm,
                phase="F6",
            )
            n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F6-NO-DUP",
                sql="""SELECT nombre, COUNT(*) FROM operational.profesional
                    GROUP BY nombre HAVING COUNT(*) > 1""",
                expected="empty",
                severity="warning",
            ),
            PathEquation(
                name="PE-F6-VALID-PROFESION",
                sql="""SELECT provider_id FROM operational.profesional
                    WHERE profesion IS NULL""",
                expected="empty",
            ),
        ]
