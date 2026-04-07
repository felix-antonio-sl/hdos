#!/usr/bin/env python3
"""CORR-08: Resolver establecimiento_id por inferencia de direccion.

Reads 123 estadias without establecimiento_id, infers comuna from patient
address/locality data, maps to the default CESFAM for that comuna, and
generates a SQL correction file.

Run: .venv/bin/python scripts/corr_08_establecimiento_por_direccion.py
"""
import unicodedata
from datetime import datetime

import psycopg

DB_URL = "postgresql://hodom:hodom@localhost:5555/hodom"
SQL_OUTPUT = "scripts/corr_08_establecimiento_por_direccion.sql"

# ── Comuna -> establecimiento_id mapping ─────────────────────────────────

COMUNA_EST = {
    # Single-CESFAM communes
    "BULNES":       "est_6efe4541285bc139",
    "COBQUECURA":   "est_ed5dfbae33da6d0c",
    "NINHUE":       "est_086461d59e37f5aa",
    "NIQUEN":       "est_fb7015e64870d8ac",
    "PEMUCO":       "est_3e320c3e3556eccd",
    "PINTO":        "est_c92092ebeee7c7e3",
    "PORTEZUELO":   "est_92c698d01303a291",
    "QUILLON":      "est_a0c8b8b02157138f",
    "RANQUIL":      "est_ff98d84e1ce6d4ea",
    "SAN FABIAN":   "est_d9f9c6839077c0b1",
    "SAN NICOLAS":  "est_f0a60ee7272ef18f",
    "TREGUACO":     "est_bd2104bf43464303",
    "YUNGAY":       "est_26e34b125b9110d7",
    # Multi-CESFAM communes (default = largest/main)
    "SAN CARLOS":   "est_4a50d9e625a5c238",
    "CHILLAN":      "est_af601fb9fd3e3d6b",
    "CHILLÁN":      "est_af601fb9fd3e3d6b",
    "CHILLÁN VIEJO": "est_dbfc0d2585da3c52",
    "CHILLAN VIEJO": "est_dbfc0d2585da3c52",
    "COIHUECO":     "est_c3a7db3128097a9f",
    "SAN IGNACIO":  "est_3fce76a075a526ca",
    "EL CARMEN":    "est_4a50d9e625a5c238",  # Falls under San Carlos health area
}

# Canonical comuna name normalization (accent-insensitive key -> canonical)
COMUNA_CANONICAL = {
    "CHILLAN": "CHILLAN",
    "CHILLÁN": "CHILLAN",
    "CHILLAN VIEJO": "CHILLAN VIEJO",
    "CHILLÁN VIEJO": "CHILLAN VIEJO",
    "NIQUEN": "NIQUEN",
    "ÑIQUEN": "NIQUEN",
    "ÑIQUÉN": "NIQUEN",
    "QUILLON": "QUILLON",
    "QUILLÓN": "QUILLON",
    "SAN NICOLAS": "SAN NICOLAS",
    "SAN NICOLÁS": "SAN NICOLAS",
    "SAN FABIAN": "SAN FABIAN",
    "SAN FABIÁN": "SAN FABIAN",
    "RANQUIL": "RANQUIL",
    "RÁNQUIL": "RANQUIL",
}

# ── Locality -> comuna mapping ───────────────────────────────────────────

LOCALIDADES = {
    # San Carlos area
    "NINQUIHUE": "SAN CARLOS", "CACHAPOAL": "SAN CARLOS",
    "TIUQUILEMU": "SAN CARLOS", "TORREON": "SAN CARLOS",
    "EL CARBON": "SAN CARLOS", "MONTE BLANCO": "SAN CARLOS",
    "RIVERA": "SAN CARLOS", "QUILELTO": "SAN CARLOS",
    "TOQUIHUA": "SAN CARLOS", "ARIZONA": "SAN CARLOS",
    "TORRECILLAS": "SAN CARLOS", "LA PITRILLA": "SAN CARLOS",
    "LLAHUIMAVIDA": "SAN CARLOS", "MUTICURA": "SAN CARLOS",
    "SAN CAMILO": "SAN CARLOS", "MONTELEON": "SAN CARLOS",
    "LAS DUMAS": "SAN CARLOS", "EL SAUCE": "SAN CARLOS",
    "CUADRAPANGUE": "SAN CARLOS", "PUYARAL": "SAN CARLOS",
    "ITIHUE": "SAN CARLOS", "SAN PEDRO LILAHUA": "SAN CARLOS",
    "LILAHUA": "SAN CARLOS", "JUNQUILLO": "SAN CARLOS",
    "HOGAR PADRE PIO": "SAN CARLOS", "SAN AGUSTIN": "SAN CARLOS",
    "SAN JORGE": "SAN CARLOS", "EL TRANQUE": "SAN CARLOS",
    "ROBLE": "SAN CARLOS",
    # Niquen area
    "ZEMITE": "NIQUEN", "ZEMITA": "NIQUEN",
    "SAN FERNANDO DE ZEMITE": "NIQUEN", "CHACAY": "NIQUEN",
    # San Fabian area
    "EL CASTANO": "SAN FABIAN",
    # Chillan area
    "CATO": "CHILLAN", "TRES ESQUINA": "CHILLAN", "HUAPE": "CHILLAN",
    # Chillan Viejo area
    "RUCAPEQUEN": "CHILLAN VIEJO", "NEBUCO": "CHILLAN VIEJO",
}

# ── San Carlos streets/poblaciones (most HODOM patients are here) ────────

SAN_CARLOS_STREETS = [
    "FREIRE", "MATTA", "OHIGGINS", "O'HIGGINS", "VICUÑA MACKENNA",
    "VICUNA MACKENNA", "BRASIL", "RIQUELME", "CARRERA", "INDEPENDENCIA",
    "BALDOMERO SILVA", "TOMAS YAVAR", "TAMAS YAVAR",  # common typo
    "TENIENTE MERINO", "PADRE ELOY", "27 DE ABRIL",
    "LUIS ACEVEDO", "MONROY", "LLANQUIHUE",
    # Poblaciones/Villas
    "NUEVA ESPERANZA", "PUESTA DEL SOL", "VILLA LOS ANDES", "NUEVA VIDA",
    "NVA. VIDA", "NVA VIDA",  # abbreviations
    "LAS ARBOLEDAS", "VISION MUNDIAL", "ESMERALDA", "PORTAL DE LA LUNA",
    "VILLA EL BOSQUE", "VILLA LA VIRGEN", "LOS POETAS", "ARAUCANIA",
    "PERDICES", "LOS AROMOS", "LAS NUBES", "LOS NARANJOS",
    "GENERAL TENIENTE MERINO",
    # Localities that are virtually always San Carlos
    "MONTECILLO",
]

# ── Commune names to search in address text ─────────────────────────────
# Ordered longest-first to avoid "SAN" matching before "SAN CARLOS"
COMUNA_NAMES_IN_ADDRESS = sorted([
    "SAN CARLOS", "CHILLAN", "CHILLÁN", "COIHUECO", "BULNES",
    "SAN NICOLAS", "SAN NICOLÁS", "NIQUEN", "ÑIQUÉN",
    "PEMUCO", "PINTO", "QUILLON", "QUILLÓN",
    "SAN FABIAN", "SAN FABIÁN", "SAN IGNACIO", "COBQUECURA",
    "PORTEZUELO", "TREGUACO", "YUNGAY", "RANQUIL", "RÁNQUIL",
    "NINHUE", "CHILLÁN VIEJO", "CHILLAN VIEJO", "EL CARMEN",
], key=len, reverse=True)


def strip_accents(text):
    """Remove diacritics (accents) but keep Ñ."""
    out = []
    for ch in unicodedata.normalize("NFD", text):
        cat = unicodedata.category(ch)
        if cat == "Mn":  # combining mark
            # Keep the tilde on Ñ (combining tilde = U+0303 after N)
            if ch == "\u0303" and out and out[-1] == "N":
                out.append(ch)
            # Drop all other accents
            continue
        out.append(ch)
    return unicodedata.normalize("NFC", "".join(out))


def normalize(text):
    """Uppercase, strip accents (except Ñ), collapse whitespace."""
    if not text:
        return ""
    t = " ".join(text.upper().strip().split())
    return strip_accents(t)


def infer_comuna(row):
    """Try to infer comuna from patient data.

    Returns (comuna, method) or (None, None).
    comuna is returned in its canonical (accent-free) form.
    """
    rut, nombre, comuna, cesfam, direccion, patient_id, stay_id, fecha = row
    comuna_n = normalize(comuna)
    direccion_n = normalize(direccion)

    # 1. Use existing comuna if it's a real value (not OTRO/empty)
    if comuna_n and comuna_n != "OTRO":
        canon = COMUNA_CANONICAL.get(comuna_n, comuna_n)
        if canon in COMUNA_EST or comuna_n in COMUNA_EST:
            return canon, "existing_comuna"

    # 2. Explicit commune name in address
    for name in COMUNA_NAMES_IN_ADDRESS:
        name_n = normalize(name)
        if name_n in direccion_n:
            canon = COMUNA_CANONICAL.get(name, name)
            return canon, "address_explicit"

    # 3. Locality name in address
    for loc, com in LOCALIDADES.items():
        if normalize(loc) in direccion_n:
            return com, "locality"

    # 4. San Carlos street/villa name in address
    for street in SAN_CARLOS_STREETS:
        if normalize(street) in direccion_n:
            return "SAN CARLOS", "street"

    return None, None


def comuna_to_establecimiento(comuna):
    """Map canonical comuna name to establecimiento_id."""
    return COMUNA_EST.get(comuna)


def main():
    conn = psycopg.connect(DB_URL)
    cur = conn.cursor()

    cur.execute("""
        SELECT p.rut, p.nombre_completo, p.comuna, p.cesfam, p.direccion,
               p.patient_id, e.stay_id, e.fecha_ingreso
        FROM clinical.estadia e
        JOIN clinical.paciente p ON p.patient_id = e.patient_id
        WHERE e.establecimiento_id IS NULL
        ORDER BY p.rut
    """)
    rows = cur.fetchall()
    total = len(rows)

    resolved = []
    unresolved = []
    method_counts = {}

    for row in rows:
        rut, nombre, comuna, cesfam, direccion, patient_id, stay_id, fecha = row
        inferred_comuna, method = infer_comuna(row)

        if inferred_comuna:
            est_id = comuna_to_establecimiento(inferred_comuna)
            if est_id:
                resolved.append({
                    "rut": rut,
                    "nombre": nombre,
                    "patient_id": patient_id,
                    "stay_id": stay_id,
                    "fecha": fecha,
                    "est_id": est_id,
                    "comuna": inferred_comuna,
                    "method": method,
                    "old_comuna": comuna,
                    "old_cesfam": cesfam,
                    "direccion": direccion,
                })
                method_counts[method] = method_counts.get(method, 0) + 1
            else:
                unresolved.append(row)
        else:
            unresolved.append(row)

    conn.close()

    # ── Generate SQL ─────────────────────────────────────────────────────
    now = datetime.now().isoformat(timespec="seconds")
    sql = []
    sql.append(f"-- CORR-08: Establecimiento por inferencia de direccion")
    sql.append(f"-- Generated: {now}")
    sql.append(f"-- Resolved {len(resolved)} / {total} estadias")
    sql.append(f"-- Methods: {method_counts}")
    sql.append("")
    sql.append("BEGIN;")
    sql.append("")

    # Track distinct patients whose comuna/cesfam we'll update
    patient_updates = {}  # patient_id -> (comuna, est_id, nombre, rut, method)

    for r in resolved:
        sql.append(f"-- {r['nombre']} ({r['rut']}) fecha={r['fecha']} method={r['method']}")
        sql.append(
            f"UPDATE clinical.estadia "
            f"SET establecimiento_id = '{r['est_id']}' "
            f"WHERE stay_id = '{r['stay_id']}';"
        )
        sql.append("")

        # Track patient-level updates (deduplicate by patient_id)
        pid = r["patient_id"]
        if pid not in patient_updates:
            patient_updates[pid] = r

    # Update paciente.comuna and paciente.cesfam where currently OTRO/NULL
    sql.append("-- ── Patient-level comuna/cesfam updates ──")
    sql.append("")

    # Look up CESFAM names for the SQL comments
    CESFAM_NAMES = {
        "est_6efe4541285bc139": "Santa Clara",
        "est_ed5dfbae33da6d0c": "Cobquecura",
        "est_086461d59e37f5aa": "Dr. David Benavente",
        "est_fb7015e64870d8ac": "Niquen",
        "est_3e320c3e3556eccd": "Pemuco",
        "est_c92092ebeee7c7e3": "Pinto",
        "est_92c698d01303a291": "Portezuelo",
        "est_a0c8b8b02157138f": "Quillon",
        "est_ff98d84e1ce6d4ea": "Nipas",
        "est_d9f9c6839077c0b1": "San Fabian",
        "est_f0a60ee7272ef18f": "San Nicolas",
        "est_bd2104bf43464303": "Treguaco",
        "est_26e34b125b9110d7": "Campanario",
        "est_4a50d9e625a5c238": "Dr. Jose Duran Trujillo",
        "est_af601fb9fd3e3d6b": "Los Volcanes",
        "est_dbfc0d2585da3c52": "Dr. Federico Puga",
        "est_c3a7db3128097a9f": "Coihueco",
        "est_3fce76a075a526ca": "San Ignacio",
    }

    for pid, r in patient_updates.items():
        old_c = normalize(r["old_comuna"])
        old_csf = normalize(r["old_cesfam"])
        cesfam_name = CESFAM_NAMES.get(r["est_id"], "?")
        sets = []
        if not old_c or old_c == "OTRO":
            sets.append(f"comuna = '{r['comuna']}'")
        if not old_csf or old_csf == "OTRO":
            sets.append(f"cesfam = '{cesfam_name}'")
        if sets:
            sql.append(f"-- {r['nombre']} ({r['rut']}) -> {r['comuna']} / {cesfam_name}")
            sql.append(
                f"UPDATE clinical.paciente SET {', '.join(sets)} "
                f"WHERE patient_id = '{pid}';"
            )
            sql.append("")

    # Provenance records
    sql.append("-- ── Provenance records ──")
    sql.append("")
    for r in resolved:
        sql.append(
            f"INSERT INTO migration.provenance "
            f"(target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) "
            f"VALUES ('clinical.estadia', '{r['stay_id']}', 'correction', "
            f"'corr_08_establecimiento_por_direccion', '{r['patient_id']}', "
            f"'CORR-08', 'establecimiento_id', NOW());"
        )

    for pid, r in patient_updates.items():
        old_c = normalize(r["old_comuna"])
        old_csf = normalize(r["old_cesfam"])
        if not old_c or old_c == "OTRO":
            sql.append(
                f"INSERT INTO migration.provenance "
                f"(target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) "
                f"VALUES ('clinical.paciente', '{pid}', 'correction', "
                f"'corr_08_establecimiento_por_direccion', '{r['stay_id']}', "
                f"'CORR-08', 'comuna', NOW());"
            )
        if not old_csf or old_csf == "OTRO":
            sql.append(
                f"INSERT INTO migration.provenance "
                f"(target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) "
                f"VALUES ('clinical.paciente', '{pid}', 'correction', "
                f"'corr_08_establecimiento_por_direccion', '{r['stay_id']}', "
                f"'CORR-08', 'cesfam', NOW());"
            )

    sql.append("")
    sql.append("COMMIT;")

    with open(SQL_OUTPUT, "w") as f:
        f.write("\n".join(sql))

    # ── Report ───────────────────────────────────────────────────────────
    print(f"=== CORR-08: Establecimiento por inferencia de direccion ===")
    print(f"Total estadias sin establecimiento: {total}")
    print(f"Resolved: {len(resolved)}")
    print(f"Unresolved: {len(unresolved)}")
    print(f"Distinct patients updated: {len(patient_updates)}")
    print()
    print("By method:")
    for method, count in sorted(method_counts.items(), key=lambda x: -x[1]):
        print(f"  {method}: {count}")
    print()

    if unresolved:
        print(f"--- Unresolved ({len(unresolved)}) ---")
        for row in unresolved:
            rut, nombre, comuna, cesfam, direccion, patient_id, stay_id, fecha = row
            print(f"  {rut:14s} {nombre:40s} com={comuna!r:15s} dir={direccion!r}")
    print()
    print(f"SQL written to: {SQL_OUTPUT}")


if __name__ == "__main__":
    main()
