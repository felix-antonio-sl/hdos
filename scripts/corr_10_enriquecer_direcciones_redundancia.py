#!/usr/bin/env python3
"""CORR-10: Enriquecer direcciones desde redundancia del pipeline intermedio.

Lee variantes de dirección de patient_address.csv (stage 2 intermediate),
selecciona la mejor variante por paciente, cruza con PG actual y genera
SQL para actualizar territorial.localizacion donde hay mejora.

Tres tipos de mejora:
  new_address  — PG tiene dirección vacía, CSV tiene algo
  added_number — PG no tiene numeración, CSV sí
  more_detail  — CSV es significativamente más detallado (>10 chars)

Run: .venv/bin/python scripts/corr_10_enriquecer_direcciones_redundancia.py
"""
import csv
import re
import sys
import os
from datetime import datetime

# ── Import CORR-09 normalizer ───────────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import corr_09_normalizar_direcciones as corr09

# ── Paths ────────────────────────────────────────────────────────────────
INTERMEDIATE_CSV = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "output", "spreadsheet", "intermediate", "patient_address.csv"
)
REF_LOCALIDADES = "/tmp/hdos_ref_localidades.txt"
SQL_OUTPUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "corr_10_enriquecer_direcciones_redundancia.sql"
)


# ── Scoring: pick best variant per patient ───────────────────────────────

def score_variant(row: dict) -> int:
    """Score an address variant. Higher = more informative."""
    s = 0
    num = (row.get("house_number") or "").strip()
    # Real house number (not S/N, 0, empty) = highest value
    if num and num not in ("S/N", "0", "SIN NUMERO", ""):
        s += 100

    # Longer street text = more info
    street = (row.get("street_text") or "").strip()
    s += len(street)

    # Has territory type
    tt = (row.get("territory_type") or "").strip()
    if tt in ("RURAL", "URBANO"):
        s += 5

    # Has real CESFAM
    cesfam = (row.get("cesfam") or "").strip()
    if cesfam and cesfam != "OTRO":
        s += 10

    return s


def pick_best_variant(variants: list[dict]) -> dict:
    """Pick the variant with the highest score."""
    return max(variants, key=score_variant)


# ── Normalization via CORR-09 engine ─────────────────────────────────────

def normalize_for_pg(raw_address: str, comuna: str) -> tuple[str, str]:
    """Normalize an address using CORR-09 logic.
    Returns (direccion_texto, localidad).
    """
    result = corr09.normalize_address(raw_address, comuna)
    return result["direccion_normalizada"], result["localidad"]


# ── Improvement detection ────────────────────────────────────────────────

def has_house_number(text: str) -> bool:
    """Check if a text contains a plausible house number (2-4 digits)."""
    if not text:
        return False
    return bool(re.search(r'\b\d{2,4}\b', text))


def detect_improvement(
    pg_addr: str | None,
    pg_localidad: str | None,
    csv_normalized: str,
    csv_localidad: str,
) -> tuple[str, str, str] | None:
    """Determine if the CSV variant is an improvement over PG.

    Returns (improvement_type, new_direccion, new_localidad) or None.
    """
    pg_addr = (pg_addr or "").strip()
    pg_loc = (pg_localidad or "").strip()
    csv_norm = csv_normalized.strip()
    csv_loc = csv_localidad.strip()

    # Skip if CSV variant is empty or garbage
    if not csv_norm or csv_norm in ("S/N", "0", "SIN NUMERO"):
        return None
    # Skip if CSV is shorter than 4 chars (garbage)
    if len(csv_norm) < 4:
        return None

    # Type 1: PG has no address at all
    if not pg_addr:
        new_loc = csv_loc if csv_loc else pg_loc
        return ("new_address", csv_norm, new_loc)

    # Type 2: PG has no house number, CSV does
    if not has_house_number(pg_addr) and has_house_number(csv_norm):
        # Only if the CSV address isn't shorter (sanity check)
        if len(csv_norm) >= len(pg_addr) - 5:
            new_loc = csv_loc if csv_loc else pg_loc
            return ("added_number", csv_norm, new_loc)

    # Type 3: CSV is significantly more detailed
    if len(csv_norm) > len(pg_addr) + 10:
        # But CSV must also have at least as much structure
        # Don't replace if PG already has a house number and CSV doesn't
        if has_house_number(pg_addr) and not has_house_number(csv_norm):
            return None
        new_loc = csv_loc if csv_loc else pg_loc
        return ("more_detail", csv_norm, new_loc)

    return None


# ── SQL helpers ──────────────────────────────────────────────────────────

def esc_sql(text: str) -> str:
    """Escape single quotes for SQL string literals."""
    return text.replace("'", "''")


# ── Main ─────────────────────────────────────────────────────────────────

def main():
    import psycopg

    # ── Initialize CORR-09 normalizer ────────────────────────────────────
    if os.path.exists(REF_LOCALIDADES):
        corr09.INE_LOCALIDADES = corr09.load_ine_localidades(REF_LOCALIDADES)
        print(f"Loaded {len(corr09.INE_LOCALIDADES)} INE localidades.")
    else:
        corr09.INE_LOCALIDADES = {}
        print("WARNING: INE localidades reference not found, skipping locality matching.")

    # Build normalized manual lookup
    corr09._MANUAL_LOCALITY_NORM = {
        corr09.norm_key(k): v for k, v in corr09._MANUAL_LOCALITY.items()
    }

    # ── Load intermediate CSV ────────────────────────────────────────────
    csv_path = os.path.normpath(INTERMEDIATE_CSV)
    rows: list[dict] = []
    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    print(f"Loaded {len(rows)} address variants from intermediate CSV.")

    # Group by patient_id → pick best variant
    by_patient: dict[str, list[dict]] = {}
    for row in rows:
        pid = row["patient_id"].strip()
        if pid:
            by_patient.setdefault(pid, []).append(row)

    best_variants: dict[str, dict] = {}
    for pid, variants in by_patient.items():
        best_variants[pid] = pick_best_variant(variants)

    print(f"Unique patients in CSV: {len(best_variants)}")
    multi = sum(1 for v in by_patient.values() if len(v) > 1)
    print(f"Patients with multiple variants: {multi}")

    # ── Load PG current state ────────────────────────────────────────────
    conn = psycopg.connect("postgresql://hodom:hodom@localhost:5555/hodom")
    cur = conn.cursor()

    cur.execute("""
        SELECT p.patient_id, l.localizacion_id, l.direccion_texto,
               l.localidad, l.comuna
        FROM clinical.paciente p
        JOIN clinical.domicilio d ON d.patient_id = p.patient_id
        JOIN territorial.localizacion l ON l.localizacion_id = d.localizacion_id
    """)
    pg_data: dict[str, dict] = {}
    for row in cur.fetchall():
        pg_data[row[0]] = {
            "localizacion_id": row[1],
            "direccion_texto": row[2],
            "localidad": row[3],
            "comuna": row[4],
        }
    conn.close()

    print(f"Patients in PG with domicilio: {len(pg_data)}")
    overlap = set(best_variants.keys()) & set(pg_data.keys())
    print(f"Overlap (CSV patients in PG): {len(overlap)}")

    # ── Cross-reference and find improvements ────────────────────────────
    improvements: list[dict] = []

    for pid in sorted(overlap):
        csv_row = best_variants[pid]
        pg_row = pg_data[pid]

        raw_addr = (csv_row.get("full_address_raw") or "").strip()
        comuna = (csv_row.get("comuna") or pg_row.get("comuna") or "").strip()

        if not raw_addr or raw_addr in ("S/N", "0"):
            continue

        # Normalize via CORR-09 engine
        csv_normalized, csv_localidad = normalize_for_pg(raw_addr, comuna)

        # Detect improvement type
        result = detect_improvement(
            pg_row["direccion_texto"],
            pg_row["localidad"],
            csv_normalized,
            csv_localidad,
        )

        if result:
            imp_type, new_addr, new_loc = result
            improvements.append({
                "patient_id": pid,
                "localizacion_id": pg_row["localizacion_id"],
                "pg_current": pg_row["direccion_texto"] or "(vacío)",
                "pg_localidad": pg_row["localidad"] or "",
                "csv_raw": raw_addr,
                "csv_score": score_variant(csv_row),
                "new_direccion": new_addr,
                "new_localidad": new_loc,
                "type": imp_type,
            })

    print(f"\nImprovements found: {len(improvements)}")

    # ── Count by type ────────────────────────────────────────────────────
    type_counts: dict[str, int] = {}
    for imp in improvements:
        t = imp["type"]
        type_counts[t] = type_counts.get(t, 0) + 1

    # ── Generate SQL ─────────────────────────────────────────────────────
    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    sql: list[str] = []
    sql.append("-- CORR-10: Enriquecimiento de direcciones desde redundancia intermedia")
    sql.append(f"-- Generado: {ts}")
    sql.append(f"-- Total mejoras: {len(improvements)}")
    for t, c in sorted(type_counts.items()):
        sql.append(f"--   {t}: {c}")
    sql.append("")
    sql.append("BEGIN;")
    sql.append("")

    sql.append("-- ── Actualizaciones territorial.localizacion ────────────────────────")
    sql.append("")

    for imp in improvements:
        loc_id = imp["localizacion_id"]
        pg_current = imp["pg_current"]
        new_dir = imp["new_direccion"]
        new_loc = imp["new_localidad"]
        imp_type = imp["type"]

        sql.append(f"-- ORIG: {esc_sql(pg_current)} -> {esc_sql(new_dir)} (type: {imp_type})")

        set_parts = [f"direccion_texto = '{esc_sql(new_dir)}'"]
        if new_loc:
            set_parts.append(f"localidad = '{esc_sql(new_loc)}'")
        set_parts.append("updated_at = NOW()")

        sql.append(
            f"UPDATE territorial.localizacion SET {', '.join(set_parts)} "
            f"WHERE localizacion_id = '{loc_id}';"
        )
        sql.append("")

    sql.append("-- ── Proveniencia ────────────────────────────────────────────────────")
    sql.append("")

    for imp in improvements:
        loc_id = imp["localizacion_id"]
        fields = ["direccion_texto"]
        if imp["new_localidad"]:
            fields.append("localidad")
        for field in fields:
            sql.append(
                f"INSERT INTO migration.provenance "
                f"(target_table, target_pk, source_type, source_file, "
                f"source_key, phase, field_name, created_at) VALUES "
                f"('territorial.localizacion', '{loc_id}', 'correction', "
                f"'patient_address.csv', '{loc_id}', "
                f"'CORR-10', '{field}', NOW());"
            )
    sql.append("")
    sql.append("COMMIT;")

    sql_path = os.path.normpath(SQL_OUTPUT)
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("\n".join(sql))

    # ── Report ───────────────────────────────────────────────────────────
    print()
    print("=" * 65)
    print("  CORR-10: Enriquecimiento de direcciones desde redundancia")
    print("=" * 65)
    print(f"  Pacientes CSV con dirección:      {len(best_variants)}")
    print(f"  Pacientes en PG con domicilio:     {len(pg_data)}")
    print(f"  Cruce (CSV en PG):                 {len(overlap)}")
    print(f"  Mejoras encontradas:               {len(improvements)}")
    print()
    print("  Por tipo:")
    for t in ("new_address", "added_number", "more_detail"):
        c = type_counts.get(t, 0)
        print(f"    {t:20s}: {c}")
    print()

    # Show samples per type
    for t in ("new_address", "added_number", "more_detail"):
        type_imps = [i for i in improvements if i["type"] == t]
        if not type_imps:
            continue
        print(f"  -- {t} (showing up to 15 of {len(type_imps)}) --")
        for imp in type_imps[:15]:
            print(f"    {imp['pg_current']!r:50s} -> {imp['new_direccion']!r}")
            if imp["new_localidad"]:
                print(f"    {'':50s}    localidad={imp['new_localidad']!r}")
        print()

    print(f"  SQL escrito en: {sql_path}")
    print()


if __name__ == "__main__":
    main()
