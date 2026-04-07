# scripts/migrate_to_pg/functors/f11_entregas_turno.py
"""
F₁₁: Entregas de turno — legacy DOCX → clinical.nota_evolucion + clinical.dispositivo

Source:  ENTREGA TURNO/ (109 DOCX, Sep 2025 - Mar 2026)
Target:
  - clinical.nota_evolucion: one note per patient-date with clinical status snapshot
  - clinical.dispositivo: active devices per patient (VVP, SNG, CUP, PICC, CVC, O2)

Each DOCX contains a table with columns:
  [NOMBRE PACIENTE, EDAD/DIAGNÓSTICO, TTO EV/CS/CA, INVASIVOS/O2, RHB, OBSERVACIONES, PENDIENTES]

The date is extracted from the filename pattern: "ENTREGA TURNO DD-DD MES YYYY.docx"

This functor is an observational coalgebra:
  next_state: Patient × Date → (TTO, Devices, RHB, Obs, Pendientes)
capturing the observable clinical state at each shift handoff.
"""

from __future__ import annotations
import re
import unicodedata
import zipfile
import xml.etree.ElementTree as ET
import glob
from datetime import datetime, date
from pathlib import Path

import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import make_id
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import make_id  # type: ignore[no-redef]


_NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

_MONTH_MAP = {
    "ENERO": 1, "FEBRERO": 2, "MARZO": 3, "ABRIL": 4, "MAYO": 5, "JUNIO": 6,
    "JULIO": 7, "AGOSTO": 8, "SEPTIEMBRE": 9, "SEPT": 9, "OCTUBRE": 10, "OCT": 10,
    "NOVIEMBRE": 11, "NOV": 11, "DICIEMBRE": 12, "DIC": 12,
}

_DEVICE_MAP = {
    "VVP": "VVP",
    "SNG": "SNG",
    "CUP": "CUP",
    "PICC": "OTRO",  # PICC line → OTRO (not in CHECK enum as separate type)
    "CVC": "OTRO",
    "O2": "CONCENTRADOR_O2",
}


def _normalize_name(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", s).strip().upper()


def _parse_date_from_filename(fname: str) -> date | None:
    """Extract date from 'ENTREGA TURNO 01-02 MARZO 2026.docx'."""
    upper = fname.upper()
    m = re.search(
        r"(\d{1,2})\s*[-–]\s*(\d{1,2})\s+"
        r"(ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|SEPT|OCTUBRE|OCT|NOVIEMBRE|NOV|DICIEMBRE|DIC)"
        r"\s+(\d{4})",
        upper,
    )
    if m:
        day = int(m.group(1))
        month = _MONTH_MAP.get(m.group(3))
        year = int(m.group(4))
        if month:
            try:
                return date(year, month, day)
            except ValueError:
                pass
    # Try 'DD DICIEMBRE YYYY' without range
    m = re.search(
        r"(\d{1,2})\s+"
        r"(ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|SEPT|OCTUBRE|OCT|NOVIEMBRE|NOV|DICIEMBRE|DIC)"
        r"\s+(\d{4})",
        upper,
    )
    if m:
        day = int(m.group(1))
        month = _MONTH_MAP.get(m.group(2))
        year = int(m.group(3))
        if month:
            try:
                return date(year, month, day)
            except ValueError:
                pass
    return None


def _extract_table_rows(docx_path: Path) -> list[list[str]]:
    """Extract all data rows from tables in a DOCX file."""
    rows_out = []
    try:
        with zipfile.ZipFile(docx_path) as z:
            doc = z.read("word/document.xml")
            root = ET.fromstring(doc)
            for tbl in root.findall(".//w:tbl", _NS):
                for tr in tbl.findall(".//w:tr", _NS)[1:]:  # skip header
                    cells = tr.findall(".//w:tc", _NS)
                    cell_texts = []
                    for cell in cells:
                        texts = [
                            t.text
                            for t in cell.iter("{%s}t" % _NS["w"])
                            if t.text
                        ]
                        cell_texts.append(" ".join(texts).strip())
                    if cell_texts and len(cell_texts[0]) > 3:
                        rows_out.append(cell_texts)
    except Exception:
        pass
    return rows_out


class F11EntregasTurno(Functor):
    name = "F11_entregas_turno"
    depends_on = ["F0_bootstrap", "F2_pacientes", "F3_estadias"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM clinical.nota_evolucion WHERE tipo = 'enfermeria'")
        conn.execute("DELETE FROM clinical.dispositivo WHERE TRUE")

        # Patient name index
        patient_index: dict[str, str] = {}
        for pid, nombre in conn.execute(
            "SELECT patient_id, nombre_completo FROM clinical.paciente"
        ).fetchall():
            norm = _normalize_name(nombre)
            patient_index[norm] = pid
            parts = norm.split()
            if len(parts) >= 2:
                patient_index[" ".join(parts[-2:])] = pid

        # Stay index
        stay_index: dict[str, list[tuple[str, date, date | None]]] = {}
        for stay_id, patient_id, fi, fe in conn.execute(
            "SELECT stay_id, patient_id, fecha_ingreso, fecha_egreso FROM clinical.estadia ORDER BY fecha_ingreso"
        ).fetchall():
            stay_index.setdefault(patient_id, []).append((stay_id, fi, fe))

        # Disable triggers for bulk insert
        conn.execute("ALTER TABLE clinical.nota_evolucion DISABLE TRIGGER ALL")
        conn.execute("ALTER TABLE clinical.dispositivo DISABLE TRIGGER ALL")

        docx_dir = sources.legacy_dir / "ENTREGA TURNO "
        if not docx_dir.exists():
            return 0

        n_notas = 0
        n_devices = 0
        seen_devices: set[tuple[str, str]] = set()  # (patient_id, tipo) dedup

        for docx_path in sorted(docx_dir.glob("*.docx")):
            fecha = _parse_date_from_filename(docx_path.name)
            if not fecha or fecha.year < 2025:
                continue

            rows = _extract_table_rows(docx_path)

            for row in rows:
                nombre_raw = row[0].strip()
                if not nombre_raw or len(nombre_raw) < 4:
                    continue

                norm_name = _normalize_name(nombre_raw)
                patient_id = patient_index.get(norm_name)
                if not patient_id:
                    for idx_name, pid in patient_index.items():
                        if norm_name in idx_name or idx_name in norm_name:
                            patient_id = pid
                            break
                if not patient_id:
                    continue

                # Find stay
                stays = stay_index.get(patient_id, [])
                stay_id = None
                for sid, fi, fe in stays:
                    if fi <= fecha and (fe is None or fe >= fecha):
                        stay_id = sid
                        break
                if not stay_id:
                    continue

                # Parse columns: [nombre, edad/dx, tto_ev, invasivos, rhb, obs, pendientes]
                tto_ev = row[2].strip() if len(row) > 2 else ""
                invasivos = row[3].strip() if len(row) > 3 else ""
                rhb = row[4].strip() if len(row) > 4 else ""
                obs = row[5].strip() if len(row) > 5 else ""
                pendientes = row[6].strip() if len(row) > 6 else ""

                # Build clinical note
                note_parts = []
                if tto_ev and tto_ev != "-":
                    note_parts.append(f"TTO: {tto_ev}")
                if invasivos and invasivos != "-":
                    note_parts.append(f"Invasivos: {invasivos}")
                if rhb and rhb != "-":
                    note_parts.append(f"RHB: {rhb}")
                if obs and obs != "-":
                    note_parts.append(f"Obs: {obs}")

                plan = pendientes if pendientes and pendientes != "-" else None
                notas = " | ".join(note_parts) if note_parts else None

                if notas or plan:
                    nota_id = make_id("et", f"{patient_id}|{fecha}|{docx_path.name}")
                    conn.execute(
                        """INSERT INTO clinical.nota_evolucion
                            (nota_id, stay_id, patient_id, tipo, fecha, notas_clinicas, plan_enfermeria)
                           VALUES (%s, %s, %s, 'enfermeria', %s, %s, %s)
                           ON CONFLICT (nota_id) DO NOTHING""",
                        (nota_id, stay_id, patient_id, fecha, notas, plan),
                    )
                    eta.record(
                        conn,
                        target_table="clinical.nota_evolucion",
                        target_pk=nota_id,
                        source_type="legacy",
                        source_file=docx_path.name,
                        source_key=f"{fecha}|{norm_name}",
                        phase="F11",
                    )
                    n_notas += 1

                # Extract devices
                if invasivos and invasivos != "-":
                    for dev_key, dev_tipo in _DEVICE_MAP.items():
                        if dev_key in invasivos.upper():
                            dedup_key = (patient_id, dev_tipo)
                            if dedup_key in seen_devices:
                                continue
                            seen_devices.add(dedup_key)

                            device_id = make_id("dev", f"{patient_id}|{dev_tipo}")
                            conn.execute(
                                """INSERT INTO clinical.dispositivo
                                    (device_id, patient_id, tipo, estado, asignado_desde)
                                   VALUES (%s, %s, %s, 'activo', %s)
                                   ON CONFLICT (device_id) DO NOTHING""",
                                (device_id, patient_id, dev_tipo, fecha),
                            )
                            eta.record(
                                conn,
                                target_table="clinical.dispositivo",
                                target_pk=device_id,
                                source_type="legacy",
                                source_file=docx_path.name,
                                source_key=f"{norm_name}|{dev_key}",
                                phase="F11",
                            )
                            n_devices += 1

        # Re-enable triggers
        conn.execute("ALTER TABLE clinical.nota_evolucion ENABLE TRIGGER ALL")
        conn.execute("ALTER TABLE clinical.dispositivo ENABLE TRIGGER ALL")

        return n_notas + n_devices

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F11-NOTA-FK-STAY",
                sql="""SELECT nota_id FROM clinical.nota_evolucion
                    WHERE stay_id NOT IN (SELECT stay_id FROM clinical.estadia)""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F11-NOTA-FK-PATIENT",
                sql="""SELECT nota_id FROM clinical.nota_evolucion
                    WHERE patient_id NOT IN (SELECT patient_id FROM clinical.paciente)""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F11-DEVICE-FK-PATIENT",
                sql="""SELECT device_id FROM clinical.dispositivo
                    WHERE patient_id NOT IN (SELECT patient_id FROM clinical.paciente)""",
                expected="empty",
            ),
        ]
