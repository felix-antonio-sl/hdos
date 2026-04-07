# scripts/migrate_to_pg/functors/f8_epicrisis.py
"""
F₈: Epicrisis — legacy DOCX filenames → clinical.epicrisis (metadata only)

Source:  EPICRISIS ENFERMERIA/ (295 DOCX) + EPICRISIS ANTIGUAS/DAU/ (47 PDF)
Target:  clinical.epicrisis

We extract metadata from filenames (patient name) and match to clinical.paciente.
Full text extraction (OCR/docx parsing) is deferred to a future phase.

The match is fuzzy: filename → normalized patient name → clinical.paciente.nombre_completo.
Only documents that match a known patient AND have an active stay are loaded.
"""

from __future__ import annotations
import re
import unicodedata
from pathlib import Path
from datetime import date

import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import make_id
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import make_id  # type: ignore[no-redef]


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s).strip().upper()
    return s


def _name_from_filename(fname: str) -> str | None:
    """Extract patient name from epicrisis filename."""
    stem = Path(fname).stem
    # Remove common prefixes
    stem = re.sub(r"^(DAU\s+|2DA\s+|2|1\s+EPICRISIS.*)", "", stem, flags=re.IGNORECASE).strip()
    # Remove trailing noise
    stem = re.sub(r"\s*-\s*(GESTORAS|HSC|HODOM).*$", "", stem, flags=re.IGNORECASE).strip()
    stem = re.sub(r"\s*\(\d+\)\s*$", "", stem).strip()
    if len(stem) < 4:
        return None
    return stem


class F8Epicrisis(Functor):
    name = "F8_epicrisis"
    depends_on = ["F0_bootstrap", "F2_pacientes", "F3_estadias"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM clinical.epicrisis WHERE TRUE")

        # Disable validation triggers for bulk legacy load
        conn.execute("ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_pe1")
        conn.execute("ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_sync_estadia")

        # Build patient name index (normalized → patient_id)
        patient_index: dict[str, str] = {}
        for pid, nombre in conn.execute(
            "SELECT patient_id, nombre_completo FROM clinical.paciente"
        ).fetchall():
            norm = _normalize(nombre)
            patient_index[norm] = pid
            # Also index by apellidos only (common in filenames)
            parts = norm.split()
            if len(parts) >= 2:
                # Try last two words (apellido paterno + materno)
                patient_index[" ".join(parts[-2:])] = pid
                # Try first + last two
                if len(parts) >= 3:
                    patient_index[f"{parts[0]} {parts[-2]} {parts[-1]}"] = pid

        # Build patient_id → latest stay
        stay_lookup: dict[str, tuple[str, date, date | None]] = {}
        for stay_id, patient_id, fi, fe in conn.execute(
            "SELECT stay_id, patient_id, fecha_ingreso, fecha_egreso FROM clinical.estadia ORDER BY fecha_ingreso DESC"
        ).fetchall():
            if patient_id not in stay_lookup:
                stay_lookup[patient_id] = (stay_id, fi, fe)

        # Scan epicrisis directories
        dirs_to_scan = [
            (sources.legacy_dir / "EPICRISIS ENFERMERIA ", "enfermeria"),
            (
                sources.legacy_dir
                / "EPICRISIS ANTIGUAS"
                / "DAU -- EPICRISIS (ADJUNTAR) identificar cada archivo con nombre de usuario (File responses)",
                "dau",
            ),
        ]

        n = 0
        for dir_path, source_label in dirs_to_scan:
            if not dir_path.exists():
                continue
            for fpath in sorted(dir_path.iterdir()):
                if fpath.suffix.lower() not in (".docx", ".pdf"):
                    continue
                name = _name_from_filename(fpath.name)
                if not name:
                    continue
                norm_name = _normalize(name)

                # Fuzzy match to patient
                patient_id = patient_index.get(norm_name)
                if not patient_id:
                    # Try partial match (contains)
                    for idx_name, pid in patient_index.items():
                        if norm_name in idx_name or idx_name in norm_name:
                            patient_id = pid
                            break

                if not patient_id:
                    continue

                stay_info = stay_lookup.get(patient_id)
                if not stay_info:
                    continue
                stay_id, fi, fe = stay_info

                epicrisis_id = make_id("epi", f"{patient_id}|{fpath.name}")
                fecha_emision = fe if fe else fi

                conn.execute(
                    """
                    INSERT INTO clinical.epicrisis
                        (epicrisis_id, stay_id, patient_id, fecha_emision,
                         fecha_ingreso, fecha_egreso, resumen_evolucion)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (epicrisis_id) DO NOTHING
                    """,
                    (
                        epicrisis_id,
                        stay_id,
                        patient_id,
                        fecha_emision,
                        fi,
                        fe,
                        f"[Documento: {fpath.name}]",
                    ),
                )

                eta.record(
                    conn,
                    target_table="clinical.epicrisis",
                    target_pk=epicrisis_id,
                    source_type="legacy",
                    source_file=f"EPICRISIS {source_label}/{fpath.name}",
                    source_key=norm_name,
                    phase="F8",
                )
                n += 1

        # Re-enable triggers
        conn.execute("ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_pe1")
        conn.execute("ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_sync_estadia")

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F8-FK-STAY",
                sql="""SELECT epicrisis_id FROM clinical.epicrisis e
                    LEFT JOIN clinical.estadia s ON s.stay_id = e.stay_id
                    WHERE s.stay_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F8-FK-PATIENT",
                sql="""SELECT epicrisis_id FROM clinical.epicrisis e
                    LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
                    WHERE p.patient_id IS NULL""",
                expected="empty",
            ),
        ]
