#!/usr/bin/env python3
"""
CORR-16: Parsear ~1500 epicrisis medica PDFs -> poblar clinical.epicrisis en PG.

Fuentes:
  1. DAU -- EPICRISIS (ADJUNTAR) ... (File responses)/  (~1850 PDFs, ~1200 epicrisis medica)
  2. EPICRISIS CON IND MEDICA (File responses)/          (~146 PDFs, ~130 epicrisis medica)

Skips: DAU forms, solicitud de hospitalizacion, scanned images, lab results.
Only processes PDFs whose first 200 chars contain "EPICRISIS" + (MEDICA or N EGRESO).

Matching: PDF RUN -> clinical.paciente.rut -> clinical.estadia by patient_id + date overlap.
IDs: "em_" + sha256(patient_id|n_egreso|filename)[:12]

Idempotent: deletes em_* records before re-inserting. Preserves CORR-12 epi_* records.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path


# ---------------------------------------------------------------------------
# Data class
# ---------------------------------------------------------------------------

@dataclass
class EpicrisisMedica:
    filename: str
    source_dir: str  # short label for provenance
    n_egreso: str | None = None
    servicio: str | None = None
    fecha_doc: str | None = None
    nombre: str | None = None
    run: str | None = None
    run_clean: str | None = None  # no dots, e.g. "3607033-1"
    fecha_nacimiento: str | None = None
    edad: str | None = None
    genero: str | None = None
    direccion: str | None = None
    comuna: str | None = None
    prevision: str | None = None
    telefono: str | None = None
    fecha_ingreso: str | None = None
    fecha_egreso: str | None = None
    causal: str | None = None
    condicion: str | None = None  # VIVO / FALLECIDO
    destino: str | None = None    # HOSPITALIZACION DOMICILIARIA / DOMICILIO / etc.
    dx_ingreso: str | None = None
    dx_egreso: str | None = None
    dx_cie10: str | None = None   # all CIE10 lines joined
    dx_principal: str | None = None  # first CIE10 principal
    evolucion: str | None = None
    plan_manejo: str | None = None
    indicaciones_alta: str | None = None
    examenes: str | None = None
    observaciones: str | None = None
    control: str | None = None
    parse_errors: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def _clean(text: str) -> str:
    """Normalize whitespace."""
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def _clean_rut(rut: str) -> str:
    """Remove dots, keep hyphen+dv: '3.607.033-1' -> '3607033-1'"""
    return rut.replace('.', '').replace(' ', '').upper()


def _parse_date(s: str) -> date | None:
    """Parse dates like '2025-04-28', '2025-04-28 11:19:00', '02-03-1931', '05/10/2023'."""
    if not s:
        return None
    s = s.strip().split()[0]  # drop time portion
    for fmt in ('%Y-%m-%d', '%d-%m-%Y', '%d/%m/%Y'):
        try:
            from datetime import datetime
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None


def _normalize_name(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[^A-Z\s]", "", s.upper())
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _extract_section(text: str, start_pattern: str, end_patterns: list[str]) -> str | None:
    """Extract text between start_pattern and the first matching end_pattern."""
    end_re = '|'.join(end_patterns)
    m = re.search(
        rf'{start_pattern}\s*\n(.*?)(?={end_re}|\Z)',
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if m:
        content = m.group(1).strip()
        if content and len(content) > 3:
            return content
    return None


def is_epicrisis_medica(text: str) -> bool:
    """Return True if the PDF text is an epicrisis medica (not DAU, not solicitud, etc.)."""
    first300 = text[:300].upper()
    if 'EPICRISIS' not in first300:
        return False
    # Exclude DAU
    if 'DATO DE ATENCI' in first300 or 'DAU' in first300.split('\n')[0]:
        return False
    # Exclude solicitud de hospitalizacion
    if 'SOLICITUD DE HOSPITALIZACI' in first300:
        return False
    # Must have N EGRESO (epicrisis medica marker)
    if 'EGRESO' in first300:
        return True
    if 'MEDICA' in first300 or 'MÉDICA' in first300:
        return True
    return False


def parse_pdf(filepath: Path, source_label: str) -> EpicrisisMedica | None:
    """Parse a single epicrisis medica PDF. Returns None if not an epicrisis medica."""
    import fitz

    data = EpicrisisMedica(filename=filepath.name, source_dir=source_label)

    try:
        doc = fitz.open(str(filepath))
        text = ''.join(page.get_text() for page in doc)
        doc.close()
    except Exception as e:
        data.parse_errors.append(f"Cannot open: {e}")
        return None

    if not text.strip():
        return None  # scanned image, no OCR

    if not is_epicrisis_medica(text):
        return None  # DAU or other document type

    # --- Header fields ---
    m = re.search(r'N[°º]\s*EGRESO\s*:\s*(\d+)', text, re.IGNORECASE)
    if m:
        data.n_egreso = m.group(1)

    m = re.search(r'SERVICIO\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.servicio = _clean(m.group(1))

    m = re.search(r'FECHA\s*:\s*([\d\-/ :]+)', text, re.IGNORECASE)
    if m:
        data.fecha_doc = m.group(1).strip()

    # --- Patient data ---
    m = re.search(r'Nombre\s*:\s*(.+?)(?:\n|$)', text)
    if m:
        data.nombre = _clean(m.group(1))

    m = re.search(r'RUN\s*:\s*([\d][\d\.]+\-[\dkK])', text, re.IGNORECASE)
    if m:
        data.run = m.group(1)
        data.run_clean = _clean_rut(m.group(1))

    m = re.search(r'F\.?\s*Nac\s*:\s*([\d/\-]+)', text, re.IGNORECASE)
    if m:
        data.fecha_nacimiento = m.group(1).strip()

    m = re.search(r'Edad\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.edad = _clean(m.group(1))

    m = re.search(r'G[eé]nero\s*:\s*(\w+)', text, re.IGNORECASE)
    if m:
        data.genero = m.group(1).strip()

    m = re.search(r'Direcci[oó]n\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        val = _clean(m.group(1))
        if val and val != '0':
            data.direccion = val

    m = re.search(r'Comuna\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.comuna = _clean(m.group(1))

    m = re.search(r'Previsi[oó]n\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.prevision = _clean(m.group(1))

    m = re.search(r'Tel[eé]fono\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        val = _clean(m.group(1))
        if val and val != '0':
            data.telefono = val

    # --- Stay dates ---
    m = re.search(r'Fecha\s+Ingreso\s*:\s*([\d\-/ :]+)', text, re.IGNORECASE)
    if m:
        data.fecha_ingreso = m.group(1).strip()

    m = re.search(r'Fecha\s+Egreso\s*:\s*([\d\-/ :]+)', text, re.IGNORECASE)
    if m:
        data.fecha_egreso = m.group(1).strip()

    m = re.search(r'Causal\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.causal = _clean(m.group(1))

    m = re.search(r'Condici[oó]n\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m:
        data.condicion = _clean(m.group(1)).upper()

    m = re.search(r'Destino\s*:\s*(.+?)(?:\n|Derivaci|$)', text, re.IGNORECASE)
    if m:
        data.destino = _clean(m.group(1)).upper()

    # --- Diagnostics ---
    # DX INGRESO: lines between DIAGNOSTICO(S) INGRESO and DIAGNOSTICO(S) EGRESO
    dx_ing = _extract_section(
        text,
        r'DIAGNOSTICO\(S\)\s*INGRESO',
        [r'DIAGNOSTICO\(S\)\s*EGRESO', r'DIAGN[OÓ]STICOS\s+CIE10'],
    )
    if dx_ing:
        data.dx_ingreso = dx_ing

    # DX EGRESO
    dx_eg = _extract_section(
        text,
        r'DIAGNOSTICO\(S\)\s*EGRESO',
        [r'DIAGN[OÓ]STICOS\s+CIE10', r'COMENTARIO DE EVOLUCI'],
    )
    if dx_eg:
        data.dx_egreso = dx_eg

    # CIE10 block
    cie10 = _extract_section(
        text,
        r'DIAGN[OÓ]STICOS\s+CIE10',
        [r'COMENTARIO DE EVOLUCI', r'PLAN DE MANEJO', r'INDICACIONES AL ALTA'],
    )
    if cie10:
        data.dx_cie10 = cie10
        # Extract principal diagnosis
        m_princ = re.search(r'1\.\s*(.+?)\(DIAGN[OÓ]STICO PRINCIPAL\)', cie10, re.IGNORECASE)
        if m_princ:
            data.dx_principal = _clean(m_princ.group(1))

    # --- Clinical sections ---
    section_ends = [
        r'PLAN DE MANEJO',
        r'INDICACIONES AL ALTA',
        r'EX[AÁ]MENES Y RESULTADOS',
        r'OBSERVACIONES',
        r'Control en',
    ]

    data.evolucion = _extract_section(
        text,
        r'COMENTARIO DE EVOLUCI[OÓ]N\s*/?\s*COMPLICACIONES',
        section_ends,
    )

    data.plan_manejo = _extract_section(
        text,
        r'PLAN DE MANEJO\s*:?',
        [r'INDICACIONES AL ALTA', r'EX[AÁ]MENES Y RESULTADOS', r'OBSERVACIONES', r'Control en'],
    )

    data.indicaciones_alta = _extract_section(
        text,
        r'INDICACIONES AL ALTA',
        [r'EX[AÁ]MENES Y RESULTADOS', r'OBSERVACIONES', r'Control en'],
    )

    data.examenes = _extract_section(
        text,
        r'EX[AÁ]MENES Y RESULTADOS',
        [r'OBSERVACIONES', r'Control en'],
    )

    m_obs = re.search(
        r'OBSERVACIONES\s*:?\s*\n(.*?)(?=Control en|\Z)',
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if m_obs:
        obs = m_obs.group(1).strip()
        if obs and len(obs) > 3:
            data.observaciones = obs

    m_ctrl = re.search(r'Control en\s*:\s*(.+?)(?:\n|$)', text, re.IGNORECASE)
    if m_ctrl:
        data.control = _clean(m_ctrl.group(1))

    return data


# ---------------------------------------------------------------------------
# Mapping helpers
# ---------------------------------------------------------------------------

def map_condicion_egreso(data: EpicrisisMedica) -> str | None:
    """Map Condicion field to condicion_egreso CHECK values."""
    if not data.condicion:
        return None
    if 'FALLECIDO' in data.condicion:
        return 'fallecido'
    if 'VIVO' in data.condicion:
        return 'mejorado'  # default for alive patients
    return None


def map_tipo_egreso(data: EpicrisisMedica) -> str | None:
    """Map Destino/Condicion to tipo_egreso CHECK values."""
    if data.condicion and 'FALLECIDO' in data.condicion:
        return 'fallecido_esperado'
    if data.causal and 'SOLICITADA' in data.causal.upper():
        return 'renuncia_voluntaria'
    # Default for medical discharges
    return 'alta_clinica'


def build_diagnostico_ingreso(data: EpicrisisMedica) -> str | None:
    """Build diagnostico_ingreso from CIE10 principal or dx_ingreso."""
    if data.dx_principal:
        return data.dx_principal
    if data.dx_ingreso:
        return data.dx_ingreso
    return None


def build_resumen_evolucion(data: EpicrisisMedica) -> str:
    """Build resumen_evolucion (NOT NULL). Falls back to dx_egreso or filename."""
    if data.evolucion:
        return data.evolucion
    if data.dx_egreso:
        return f"Diagnostico egreso: {data.dx_egreso}"
    return f"[Epicrisis medica: {data.filename}]"


# ---------------------------------------------------------------------------
# DB load
# ---------------------------------------------------------------------------


def _sanitize(val):
    """Remove NUL bytes that PostgreSQL text fields reject."""
    if isinstance(val, str):
        return val.replace('\x00', '')
    return val


def load_to_pg(
    records: list[EpicrisisMedica],
    db_url: str,
    dry_run: bool = False,
) -> dict:
    import psycopg

    conn = psycopg.connect(db_url, autocommit=False)

    # Build RUT -> patient_id index
    rut_index: dict[str, str] = {}
    for pid, rut in conn.execute(
        "SELECT patient_id, rut FROM clinical.paciente WHERE rut IS NOT NULL"
    ).fetchall():
        rut_clean = rut.replace('.', '').replace('-', '').strip().upper()
        rut_index[rut_clean] = pid

    # Build name -> patient_id index
    name_index: dict[str, str] = {}
    for pid, nombre in conn.execute(
        "SELECT patient_id, nombre_completo FROM clinical.paciente WHERE nombre_completo IS NOT NULL"
    ).fetchall():
        name_index[_normalize_name(nombre)] = pid

    # Build patient_id -> list of stays (stay_id, fecha_ingreso, fecha_egreso)
    stay_index: dict[str, list[tuple]] = {}
    for sid, pid, fi, fe in conn.execute(
        "SELECT stay_id, patient_id, fecha_ingreso, fecha_egreso FROM clinical.estadia ORDER BY fecha_ingreso"
    ).fetchall():
        stay_index.setdefault(pid, []).append((sid, fi, fe))

    # Idempotent: delete em_* records and their provenance
    if not dry_run:
        conn.execute(
            "DELETE FROM migration.provenance "
            "WHERE target_table = 'clinical.epicrisis' AND phase = 'CORR-16'"
        )
        conn.execute(
            "ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_pe1"
        )
        conn.execute(
            "ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_sync_estadia"
        )
        conn.execute(
            "DELETE FROM clinical.epicrisis WHERE epicrisis_id LIKE 'em_%'"
        )

    stats = {
        'matched': 0,
        'inserted': 0,
        'conflict_skip': 0,
        'no_patient': 0,
        'no_stay': 0,
        'unmatched_files': [],
    }

    seen_ids: set[str] = set()

    for data in records:
        # Step 1: match patient by RUT
        patient_id = None
        match_method = None

        if data.run_clean:
            rut_digits = data.run_clean.replace('-', '').replace(' ', '')
            patient_id = rut_index.get(rut_digits)
            if patient_id:
                match_method = 'rut'

        # Step 2: fallback to name match
        if not patient_id and data.nombre:
            norm = _normalize_name(data.nombre)
            patient_id = name_index.get(norm)
            if patient_id:
                match_method = 'name_exact'
            else:
                # Fuzzy: check containment
                for idx_name, pid in name_index.items():
                    if len(norm) >= 10 and (norm in idx_name or idx_name in norm):
                        patient_id = pid
                        match_method = 'name_fuzzy'
                        break

        if not patient_id:
            stats['no_patient'] += 1
            stats['unmatched_files'].append(f"{data.filename} (no patient: RUT={data.run_clean})")
            continue

        # Step 3: match stay by date overlap
        stays = stay_index.get(patient_id, [])
        if not stays:
            stats['no_stay'] += 1
            stats['unmatched_files'].append(f"{data.filename} (no stay for {patient_id})")
            continue

        pdf_ingreso = _parse_date(data.fecha_ingreso)
        pdf_egreso = _parse_date(data.fecha_egreso)

        best_stay = None
        best_score = -1

        for sid, stay_fi, stay_fe in stays:
            score = 0
            # Exact ingreso match
            if pdf_ingreso and stay_fi and pdf_ingreso == stay_fi:
                score += 10
            # Ingreso within 3 days
            elif pdf_ingreso and stay_fi and abs((pdf_ingreso - stay_fi).days) <= 3:
                score += 5
            # Egreso match
            if pdf_egreso and stay_fe and pdf_egreso == stay_fe:
                score += 10
            elif pdf_egreso and stay_fe and abs((pdf_egreso - stay_fe).days) <= 3:
                score += 5
            # Date overlap: PDF ingreso within stay range
            if pdf_ingreso and stay_fi:
                end = stay_fe or (stay_fi + timedelta(days=365))
                if stay_fi - timedelta(days=3) <= pdf_ingreso <= end + timedelta(days=3):
                    score += 3

            if score > best_score:
                best_score = score
                best_stay = (sid, stay_fi, stay_fe)

        if not best_stay or best_score < 3:
            # Fallback: use latest stay
            best_stay = stays[-1]

        stay_id, stay_fi, stay_fe = best_stay
        stats['matched'] += 1

        # Generate deterministic ID
        raw_id = f"{patient_id}|{data.n_egreso or ''}|{data.filename}"
        epicrisis_id = "em_" + hashlib.sha256(raw_id.encode()).hexdigest()[:12]

        # Deduplicate within this batch
        if epicrisis_id in seen_ids:
            stats['conflict_skip'] += 1
            continue
        seen_ids.add(epicrisis_id)

        # Map fields
        fecha_emision = (
            _parse_date(data.fecha_doc)
            or _parse_date(data.fecha_egreso)
            or stay_fe
            or stay_fi
        )
        fecha_ingreso_db = _parse_date(data.fecha_ingreso) or stay_fi
        fecha_egreso_db = _parse_date(data.fecha_egreso) or stay_fe

        if not dry_run:
            cur = conn.execute(
                """
                INSERT INTO clinical.epicrisis
                    (epicrisis_id, stay_id, patient_id,
                     fecha_emision, fecha_ingreso, fecha_egreso,
                     tipo_egreso, servicio_origen,
                     motivo_ingreso, diagnostico_ingreso,
                     resumen_evolucion, tratamiento_realizado,
                     condicion_egreso, indicaciones_alta,
                     examenes_realizados, cuidados_especiales,
                     proximo_control)
                VALUES (%s, %s, %s,
                        %s, %s, %s,
                        %s, %s,
                        %s, %s,
                        %s, %s,
                        %s, %s,
                        %s, %s,
                        %s)
                ON CONFLICT (epicrisis_id) DO NOTHING
                """,
                tuple(_sanitize(v) for v in (
                    epicrisis_id, stay_id, patient_id,
                    fecha_emision, fecha_ingreso_db, fecha_egreso_db,
                    map_tipo_egreso(data), data.servicio,
                    data.dx_ingreso, build_diagnostico_ingreso(data),
                    build_resumen_evolucion(data), data.plan_manejo,
                    map_condicion_egreso(data), data.indicaciones_alta,
                    data.examenes, data.observaciones,
                    data.control,
                )),
            )
            if cur.rowcount > 0:
                stats['inserted'] += 1
                # Provenance
                conn.execute(
                    """
                    INSERT INTO migration.provenance
                        (target_table, target_pk, source_type, source_file, source_key, phase)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (
                        "clinical.epicrisis", epicrisis_id,
                        "pdf", f"{data.source_dir}/{data.filename}",
                        data.run_clean or data.nombre or data.filename,
                        "CORR-16",
                    ),
                )
            else:
                stats['conflict_skip'] += 1
        else:
            stats['inserted'] += 1

    if not dry_run:
        conn.execute(
            "ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_pe1"
        )
        conn.execute(
            "ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_sync_estadia"
        )
        conn.commit()

    conn.close()
    return stats


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="CORR-16: Parsear epicrisis medica PDFs -> clinical.epicrisis"
    )
    parser.add_argument(
        "--db-url",
        default="postgresql://hodom:hodom@localhost:5555/hodom",
    )
    parser.add_argument("--dry-run", action="store_true", help="Solo parsear, no escribir")
    args = parser.parse_args()

    base = Path("documentacion-legacy/drive-hodom/Formulario sin título (File responses)")

    dirs = [
        (
            base / "DAU -- EPICRISIS (ADJUNTAR) IDENTIFICAR ARCHIVO CON NOMBRE DE USUARIO (File responses)",
            "DAU-EPICRISIS",
        ),
        (
            base / "EPICRISIS CON IND MÉDICA (File responses)",
            "EPICRISIS-IND-MEDICA",
        ),
    ]

    # Parse all PDFs
    all_records: list[EpicrisisMedica] = []
    skipped = {'not_epicrisis': 0, 'empty': 0, 'not_pdf': 0}

    for dir_path, label in dirs:
        if not dir_path.exists():
            print(f"WARN: directory not found: {dir_path}")
            continue
        files = sorted(f for f in dir_path.iterdir() if f.suffix.lower() == '.pdf')
        print(f"Scanning {len(files)} PDFs in {label}...")

        for fpath in files:
            result = parse_pdf(fpath, label)
            if result is None:
                skipped['not_epicrisis'] += 1
                continue
            all_records.append(result)

    print(f"\n=== Parse results ===")
    print(f"Epicrisis medica parsed: {len(all_records)}")
    print(f"Skipped (not epicrisis/empty/other): {skipped['not_epicrisis']}")

    # Field coverage stats
    fields = {
        'n_egreso': sum(1 for r in all_records if r.n_egreso),
        'run': sum(1 for r in all_records if r.run_clean),
        'nombre': sum(1 for r in all_records if r.nombre),
        'servicio': sum(1 for r in all_records if r.servicio),
        'fecha_ingreso': sum(1 for r in all_records if r.fecha_ingreso),
        'fecha_egreso': sum(1 for r in all_records if r.fecha_egreso),
        'dx_ingreso': sum(1 for r in all_records if r.dx_ingreso),
        'dx_cie10': sum(1 for r in all_records if r.dx_cie10),
        'dx_principal': sum(1 for r in all_records if r.dx_principal),
        'evolucion': sum(1 for r in all_records if r.evolucion),
        'plan_manejo': sum(1 for r in all_records if r.plan_manejo),
        'indicaciones_alta': sum(1 for r in all_records if r.indicaciones_alta),
        'examenes': sum(1 for r in all_records if r.examenes),
        'control': sum(1 for r in all_records if r.control),
    }
    print(f"\nField coverage:")
    for fname, count in fields.items():
        pct = count / len(all_records) * 100 if all_records else 0
        print(f"  {fname:20s}: {count:5d} ({pct:5.1f}%)")

    # Destino distribution
    from collections import Counter
    destinos = Counter(r.destino for r in all_records if r.destino)
    if destinos:
        print(f"\nDestino distribution:")
        for k, v in destinos.most_common():
            print(f"  {v:5d}x {k}")

    if args.dry_run:
        # Still do the matching to show stats
        print(f"\n=== Dry-run DB matching ===")
        stats = load_to_pg(all_records, args.db_url, dry_run=True)
        print(f"Would match:  {stats['matched']}")
        print(f"Would insert: {stats['inserted']}")
        print(f"No patient:   {stats['no_patient']}")
        print(f"No stay:      {stats['no_stay']}")
        if stats['unmatched_files']:
            print(f"\nUnmatched ({len(stats['unmatched_files'])}):")
            for u in stats['unmatched_files'][:30]:
                print(f"  - {u}")
            if len(stats['unmatched_files']) > 30:
                print(f"  ... and {len(stats['unmatched_files']) - 30} more")
        print("\n[DRY RUN] No changes written.")
        return

    # Real load
    print(f"\nLoading to PostgreSQL...")
    stats = load_to_pg(all_records, args.db_url, dry_run=False)
    print(f"\n=== DB results ===")
    print(f"Matched:        {stats['matched']}")
    print(f"Inserted:       {stats['inserted']}")
    print(f"Conflict skip:  {stats['conflict_skip']}")
    print(f"No patient:     {stats['no_patient']}")
    print(f"No stay:        {stats['no_stay']}")
    if stats['unmatched_files']:
        print(f"\nUnmatched ({len(stats['unmatched_files'])}):")
        for u in stats['unmatched_files'][:30]:
            print(f"  - {u}")
        if len(stats['unmatched_files']) > 30:
            print(f"  ... and {len(stats['unmatched_files']) - 30} more")


if __name__ == "__main__":
    main()
