#!/usr/bin/env python3
"""
CORR-12: Parsear 295 DOCX de epicrisis enfermería → poblar campos clínicos en PG.

F₈ solo cargó metadata (nombre de archivo como placeholder en resumen_evolucion).
Este script parsea el contenido real de cada DOCX y actualiza clinical.epicrisis.

Campos extraídos:
  - diagnostico_ingreso    ← DIAGNÓSTICO MÉDICO
  - resumen_evolucion      ← EVOLUCIÓN (texto libre clínico)
  - examen_fisico_ingreso  ← INVASIVOS + HERIDAS + OSTOMIAS (estructurado)
  - indicaciones_alta      ← PLAN DE ENFERMERÍA
  - derivacion_aps         ← DERIVACIÓN
  - servicio_origen        ← inferido de evolución ("derivado desde servicio de X")

Fuente: documentacion-legacy/drive-hodom/EPICRISIS ENFERMERIA /
"""

from __future__ import annotations

import os
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

from docx import Document

# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

@dataclass
class EpicrisisData:
    filename: str
    nombre: str | None = None
    rut: str | None = None
    edad: str | None = None
    cesfam: str | None = None
    fecha_ingreso: str | None = None
    fecha_egreso: str | None = None
    diagnostico: str | None = None
    evolucion: str | None = None
    invasivos: str | None = None
    heridas: str | None = None
    ostomias: str | None = None
    alergias: str | None = None
    plan_enfermeria: str | None = None
    derivacion: str | None = None
    servicio_origen: str | None = None
    parse_errors: list[str] = field(default_factory=list)


def _clean(text: str) -> str:
    """Normalize whitespace, remove filler dots/underscores."""
    text = re.sub(r'[…\.]{3,}', '', text)
    text = re.sub(r'_{3,}', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def _normalize_name(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s).strip().upper()
    return s


def parse_epicrisis_docx(filepath: str | Path) -> EpicrisisData:
    """Parse a single epicrisis DOCX file into structured data."""
    filepath = Path(filepath)
    data = EpicrisisData(filename=filepath.name)

    try:
        doc = Document(str(filepath))
    except Exception as e:
        data.parse_errors.append(f"Cannot open: {e}")
        return data

    paragraphs = [p.text.strip() for p in doc.paragraphs]
    full_text = "\n".join(paragraphs)

    # --- NOMBRE ---
    m = re.search(r'NOMBRE[:\s]+(.+?)(?:EDAD|\n|$)', full_text)
    if m:
        data.nombre = _clean(m.group(1))

    # --- RUT ---
    m = re.search(r'RUT[:\s]+([\d][\d\.]+\-[\dkK])', full_text)
    if m:
        data.rut = m.group(1).replace('.', '')

    # --- EDAD ---
    m = re.search(r'EDAD[:\s]+(\d+)\s*A[ÑN]OS', full_text, re.IGNORECASE)
    if m:
        data.edad = m.group(1)

    # --- CESFAM ---
    m = re.search(r'(?:CESFAM|APS|CECOF)[:\s]+(.+?)(?:\n|$)', full_text, re.IGNORECASE)
    if m:
        data.cesfam = _clean(m.group(1))

    # --- FECHAS ---
    m = re.search(r'FECHA\s+INGRESO\s+HODOM[:\s]+([\d/\-]+)', full_text, re.IGNORECASE)
    if m:
        data.fecha_ingreso = m.group(1).strip()

    m = re.search(r'FECHA\s+(?:EGRESO|ALTA)[^:]*[:\s]+([\d/\-]+)', full_text, re.IGNORECASE)
    if m:
        data.fecha_egreso = m.group(1).strip()

    # --- DIAGNÓSTICO ---
    m = re.search(r'DIAGN[OÓ]STICO\s+M[EÉ]DICO[:\s]+(.+?)(?:\n|$)', full_text, re.IGNORECASE)
    if m:
        data.diagnostico = _clean(m.group(1))

    # --- EVOLUCIÓN (main clinical text) ---
    # Text between "EVOLUCIÓN:" and "INVASIVOS:" (or PLAN DE ENFERMERÍA if no INVASIVOS)
    m = re.search(
        r'EVOLUCI[OÓ]N[:\s]*\n(.*?)(?=\nINVASIVOS|\nPLAN DE ENFERMER|\nDERIVACI[OÓ]N|\nFIRMA|$)',
        full_text,
        re.DOTALL | re.IGNORECASE,
    )
    if m:
        evol = m.group(1).strip()
        # Clean up but preserve paragraph structure
        evol = re.sub(r'\n{3,}', '\n\n', evol)
        data.evolucion = evol if len(evol) > 10 else None

    # --- SERVICIO ORIGEN (inferido de evolución) ---
    if data.evolucion:
        m = re.search(
            r'derivad[oa]\s+desde\s+(?:el\s+)?servicio\s+de\s+(\w[\w\s]*?)(?:\s+(?:con|para|por|HSC|de\s+HSC))',
            data.evolucion,
            re.IGNORECASE,
        )
        if m:
            raw = _clean(m.group(1)).upper()
            # Normalize service names
            SERVICIO_MAP = {
                'CIRUGIA': 'CIRUGIA', 'CIRUGÍA': 'CIRUGIA', 'CIRUGÌA': 'CIRUGIA',
                'CIRUGÍA DE': 'CIRUGIA',
                'MEDICINA': 'MEDICINA', 'MEDICINA A HODOM': 'MEDICINA',
                'TRAUMATOLOGÍA': 'TRAUMATOLOGIA', 'TRAUMATOLOGIA': 'TRAUMATOLOGIA',
                'UE': 'URGENCIA', 'URGENCIA': 'URGENCIA',
                'TMT': 'TRAUMATOLOGIA',
                'GINECOLOGÍA Y OBSTETRICIA': 'GINECOLOGIA',
                'CIRUGÍA TRAS': 'CIRUGIA',
            }
            # Truncate to first 2 words max (avoid capturing trailing diagnosis text)
            words = raw.split()
            if len(words) > 3:
                raw = ' '.join(words[:2])
            data.servicio_origen = SERVICIO_MAP.get(raw, raw)

    # --- INVASIVOS section ---
    invasivos_parts = []
    inv_block = re.search(
        r'(INVASIVOS.*?)(?=\nHERIDAS|\nOSTOMIAS|\nALERGIAS|\nPLAN DE|\n\n|$)',
        full_text,
        re.DOTALL | re.IGNORECASE,
    )
    if inv_block:
        block = inv_block.group(1)
        for device, label in [
            (r'V[VP]P\s+SI', 'VVP'),
            (r'SNG\s+SI', 'SNG'),
            (r'CUP\s+SI', 'CUP'),
            (r'DRENAJES\s+SI', 'DRENAJE'),
        ]:
            if re.search(device, block, re.IGNORECASE):
                invasivos_parts.append(label)
    if invasivos_parts:
        data.invasivos = ', '.join(invasivos_parts)

    # --- HERIDAS ---
    # Match the form line "HERIDAS: SI" (not the title "VALORACIÓN FINAL DE HERIDAS...")
    herida_line = re.search(r'HERIDAS[:\s]+SI\b', full_text, re.IGNORECASE)
    if herida_line:
        # Extract block from HERIDAS: SI to OSTOMIAS
        herida_block = re.search(
            r'HERIDAS[:\s]+SI\b(.*?)(?=\nOSTOMIAS|\nALERGIAS|\nPLAN DE|$)',
            full_text,
            re.DOTALL | re.IGNORECASE,
        )
        if herida_block:
            block = herida_block.group(1)
            parts = []
            # Localización (standalone line after HERIDAS)
            loc_m = re.search(r'LOCALIZACI[OÓ]N[:\s]+(.+?)(?:\n|$)', block, re.IGNORECASE)
            if loc_m:
                loc = _clean(loc_m.group(1))
                if loc:
                    parts.append(f"Localización: {loc}")
            # Grado LPP (only if a specific grade is marked, not just the blank form)
            lpp_m = re.search(r'GRADO\s+LPP[:\s]+(.+?)(?:\n|$)', block, re.IGNORECASE)
            if lpp_m:
                raw = lpp_m.group(1).strip()
                # Only capture if a specific grade seems selected (more spaces before one option)
                # For now just capture if it has content
            if parts:
                data.heridas = '; '.join(parts)

    # --- OSTOMIAS ---
    ost_m = re.search(r'OSTOMIAS\s+SI\b.*?LOCALIZACI[OÓ]N[:\s]+(.+?)(?:\n|$)', full_text, re.IGNORECASE)
    if ost_m:
        loc = _clean(ost_m.group(1))
        if loc and len(loc) > 2:
            data.ostomias = loc
        else:
            data.ostomias = None

    # --- ALERGIAS ---
    m = re.search(r'ALERGIAS[:\s]+SI.*?ESPECIFICAR[:\s]+(.+?)(?:\n|$)', full_text, re.IGNORECASE)
    if m:
        alergia = _clean(m.group(1))
        if alergia:
            data.alergias = alergia

    # --- PLAN DE ENFERMERÍA ---
    # Content between "PLAN DE ENFERMERÍA:" and "DERIVACIÓN:" line
    m = re.search(
        r'PLAN DE ENFERMER[IÍ]A[:\s]*\n(.*?)(?=DERIVACI[OÓ]N[:\s]|FIRMA\s+TUTOR|……|$)',
        full_text,
        re.DOTALL | re.IGNORECASE,
    )
    if m:
        plan = _clean(m.group(1))
        # Filter out form-only lines (labels without actual content)
        if plan and len(plan) > 10 and not re.match(r'^(DERIVACI|POSTRADO|APS\s+CURAC)', plan, re.IGNORECASE):
            data.plan_enfermeria = plan

    # --- DERIVACIÓN ---
    # The form line is: "DERIVACIÓN:   POSTRADO:   APS CURACIONES:"
    # Real derivation data would be between these labels
    m = re.search(
        r'DERIVACI[OÓ]N[:\s]+(.+?)(?:\s+POSTRADO|\s+APS\s+CURACIONES|\n|$)',
        full_text,
        re.IGNORECASE,
    )
    if m:
        deriv = _clean(m.group(1))
        # Filter out form labels that leaked through
        if (deriv and len(deriv) > 3
                and not re.match(r'^(POSTRADO|APS\s+CURAC)', deriv, re.IGNORECASE)):
            data.derivacion = deriv

    return data


def build_examen_fisico(data: EpicrisisData) -> str | None:
    """Compose examen_fisico_ingreso from invasivos + heridas + ostomias."""
    parts = []
    if data.invasivos:
        parts.append(f"Dispositivos invasivos: {data.invasivos}")
    if data.heridas:
        parts.append(f"Heridas: {data.heridas}")
    if data.ostomias:
        parts.append(f"Ostomías: {data.ostomias}")
    if data.alergias:
        parts.append(f"Alergias: {data.alergias}")
    return '; '.join(parts) if parts else None


# ---------------------------------------------------------------------------
# DB update
# ---------------------------------------------------------------------------

def update_epicrisis_pg(parsed: list[EpicrisisData], db_url: str, dry_run: bool = False):
    """Idempotent: delete all epicrisis, re-insert from DOCX data + patient matching."""
    import hashlib
    import psycopg

    conn = psycopg.connect(db_url, autocommit=False)

    # Build RUT → patient_id
    rut_index = {}
    for pid, rut in conn.execute(
        "SELECT patient_id, rut FROM clinical.paciente WHERE rut IS NOT NULL"
    ).fetchall():
        rut_clean = rut.replace('.', '').replace('-', '').strip()
        rut_index[rut_clean] = pid

    # Build patient name index
    name_index = {}
    for pid, nombre in conn.execute(
        "SELECT patient_id, nombre_completo FROM clinical.paciente"
    ).fetchall():
        name_index[_normalize_name(nombre)] = pid

    # patient_id → latest stay
    stay_lookup = {}
    for sid, pid, fi, fe in conn.execute(
        "SELECT stay_id, patient_id, fecha_ingreso, fecha_egreso "
        "FROM clinical.estadia ORDER BY fecha_ingreso DESC"
    ).fetchall():
        if pid not in stay_lookup:
            stay_lookup[pid] = (sid, fi, fe)

    # Idempotent wipe
    if not dry_run:
        conn.execute("DELETE FROM migration.provenance WHERE target_table = 'clinical.epicrisis'")
        conn.execute("ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_pe1")
        conn.execute("ALTER TABLE clinical.epicrisis DISABLE TRIGGER trg_epicrisis_sync_estadia")
        conn.execute("DELETE FROM clinical.epicrisis WHERE TRUE")

    inserted = 0
    skipped = 0
    unmatched = []

    for data in parsed:
        examen = build_examen_fisico(data)

        # Match DOCX to patient by RUT then by name
        patient_id = None
        if data.rut:
            rut_clean = data.rut.replace('.', '').replace('-', '').strip()
            patient_id = rut_index.get(rut_clean)

        if not patient_id and data.nombre:
            norm = _normalize_name(data.nombre)
            patient_id = name_index.get(norm)
            if not patient_id:
                for idx_name, pid in name_index.items():
                    if norm in idx_name or idx_name in norm:
                        patient_id = pid
                        break

        if not patient_id:
            unmatched.append(data.filename)
            skipped += 1
            continue

        stay_info = stay_lookup.get(patient_id)
        if not stay_info:
            unmatched.append(f"{data.filename} (sin estadía)")
            skipped += 1
            continue

        stay_id, fi, fe = stay_info
        fecha_emision = fe if fe else fi

        raw = f"epi|{patient_id}|{data.filename}"
        epicrisis_id = "epi_" + hashlib.sha256(raw.encode()).hexdigest()[:12]

        if not dry_run:
            conn.execute(
                """
                INSERT INTO clinical.epicrisis
                    (epicrisis_id, stay_id, patient_id, fecha_emision,
                     fecha_ingreso, fecha_egreso,
                     diagnostico_ingreso, resumen_evolucion,
                     examen_fisico_ingreso, servicio_origen,
                     indicaciones_alta, derivacion_aps)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (epicrisis_id) DO NOTHING
                """,
                (
                    epicrisis_id, stay_id, patient_id, fecha_emision,
                    fi, fe,
                    data.diagnostico,
                    data.evolucion or f"[Documento: {data.filename}]",
                    examen, data.servicio_origen,
                    data.plan_enfermeria, data.derivacion,
                ),
            )
            conn.execute(
                """
                INSERT INTO migration.provenance
                    (target_table, target_pk, source_type, source_file, source_key, phase)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING
                """,
                (
                    "clinical.epicrisis", epicrisis_id,
                    "legacy", f"EPICRISIS ENFERMERIA/{data.filename}",
                    _normalize_name(data.nombre) if data.nombre else data.filename,
                    "CORR-12",
                ),
            )
        inserted += 1

    if not dry_run:
        conn.execute("ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_pe1")
        conn.execute("ALTER TABLE clinical.epicrisis ENABLE TRIGGER trg_epicrisis_sync_estadia")
        conn.commit()

    conn.close()

    return {
        'inserted': inserted,
        'skipped': skipped,
        'unmatched': unmatched,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    import argparse
    parser = argparse.ArgumentParser(description="CORR-12: Parsear epicrisis DOCX → PG")
    parser.add_argument("--db-url", default="postgresql://hodom:hodom@localhost:5555/hodom")
    parser.add_argument("--dry-run", action="store_true", help="Solo parsear, no escribir")
    parser.add_argument("--dir", default="documentacion-legacy/drive-hodom/EPICRISIS ENFERMERIA ",
                        help="Directorio con los DOCX")
    args = parser.parse_args()

    docx_dir = Path(args.dir)
    if not docx_dir.exists():
        print(f"ERROR: directorio no existe: {docx_dir}")
        sys.exit(1)

    # Parse all DOCX
    files = sorted(f for f in docx_dir.iterdir() if f.suffix.lower() == '.docx')
    print(f"Parseando {len(files)} archivos DOCX...")

    parsed = []
    errors = []
    for fpath in files:
        data = parse_epicrisis_docx(fpath)
        parsed.append(data)
        if data.parse_errors:
            errors.append((fpath.name, data.parse_errors))

    # Stats
    with_evol = sum(1 for d in parsed if d.evolucion)
    with_diag = sum(1 for d in parsed if d.diagnostico)
    with_rut = sum(1 for d in parsed if d.rut)
    with_inv = sum(1 for d in parsed if d.invasivos)
    with_herida = sum(1 for d in parsed if d.heridas)
    with_ostomia = sum(1 for d in parsed if d.ostomias)
    with_servicio = sum(1 for d in parsed if d.servicio_origen)

    print(f"\n--- Parsing results ---")
    print(f"Total:              {len(parsed)}")
    print(f"Con evolución:      {with_evol}")
    print(f"Con diagnóstico:    {with_diag}")
    print(f"Con RUT:            {with_rut}")
    print(f"Con invasivos:      {with_inv}")
    print(f"Con heridas:        {with_herida}")
    print(f"Con ostomías:       {with_ostomia}")
    print(f"Con servicio origen:{with_servicio}")
    print(f"Errores parse:      {len(errors)}")

    if errors:
        print("\nErrores:")
        for fname, errs in errors:
            print(f"  {fname}: {errs}")

    # Show service_origen distribution
    servicios = {}
    for d in parsed:
        if d.servicio_origen:
            servicios[d.servicio_origen] = servicios.get(d.servicio_origen, 0) + 1
    if servicios:
        print("\nServicios de origen:")
        for s, n in sorted(servicios.items(), key=lambda x: -x[1]):
            print(f"  {n:3d}x {s}")

    if args.dry_run:
        print("\n[DRY RUN] No se escribió nada en la base de datos.")
        return

    # Update PG
    print(f"\nActualizando PostgreSQL...")
    result = update_epicrisis_pg(parsed, args.db_url)
    print(f"\n--- DB results ---")
    print(f"Insertados:   {result['inserted']}")
    print(f"Omitidos:     {result['skipped']}")
    if result['unmatched']:
        print(f"\nSin match ({len(result['unmatched'])}):")
        for u in result['unmatched']:
            print(f"  - {u}")


if __name__ == "__main__":
    main()
