#!/usr/bin/env python3
"""Normalizar, estandarizar y desduplicar domicilios desde staging.hodom_ingreso_2026.

Pipeline:
  1. Lee todas las direcciones con comuna desde staging.hodom_ingreso_2026.
  2. Normaliza cada direccion: uppercase, espacios, abreviaturas, formato KM, S/N.
  3. Agrupa por direccion normalizada + comuna normalizada.
  4. Cruza con territorial.localizacion existente para marcar ya_geocodificado.
  5. Escribe en staging.domicilio_normalizado.

Uso:
  python normalize_staging_addresses.py [--dry-run] [--verbose]
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from collections import defaultdict
from typing import Any

import psycopg
from psycopg.rows import dict_row

DB_URL = "postgresql://hodom:hodom@localhost:5555/hodom"

# ---------------------------------------------------------------------------
# Comuna normalization: map raw → canonical
# ---------------------------------------------------------------------------

COMUNA_MAP: dict[str, str] = {
    "SAN CARLOS": "SAN CARLOS",
    "SANCARLOS": "SAN CARLOS",
    "SAN  NICOLAS": "SAN NICOLAS",
    "SAN NICOLAS": "SAN NICOLAS",
    "ÑIQUEN": "NIQUEN",
    "NIQUEN": "NIQUEN",
    "SAN GREGORIO": "SAN GREGORIO",
    "SAN FABIAN": "SAN FABIAN",
    "CHILLAN": "CHILLAN",
    "BULNES": "BULNES",
    "OTRO": "OTRO",
}

# ---------------------------------------------------------------------------
# Abbreviation expansion: word → canonical form
# ---------------------------------------------------------------------------

ABBREV_MAP: dict[str, str] = {
    "PSJE": "PASAJE",
    "PJE": "PASAJE",
    "PSJ": "PASAJE",
    "AV": "AVENIDA",
    "FCO": "FRANCISCO",
    "POB": "POBLACION",
    "PBL": "POBLACION",
    "STA": "SANTA",
    "GNRAL": "GENERAL",
    "GRAL": "GENERAL",
    "INT": "INTERIOR",
    "SECT": "SECTOR",
    "LCDA": "LOCALIDAD",
    "NRO": "NUMERO",
    "N°": "NUMERO",
    "Nº": "NUMERO",
    "NRO.": "NUMERO",
    "#": "NUMERO",
    "V.": None,  # ambiguous: V. Alessandri vs Villa
    "C.": None,  # ambiguous: C. Ortiz vs Calle
}

# Special multi-word abbreviations
MULTI_ABBREV: dict[str, str] = {
    "P DEL SUR": "PORTAL DEL SUR",
    "P. DEL SUR": "PORTAL DEL SUR",
    "P DEL NORTE": "PORTAL DEL NORTE",
    "11 DE SEPT": "11 DE SEPTIEMBRE",
    "11 DE SEP": "11 DE SEPTIEMBRE",
    "11 SEPT": "11 DE SEPTIEMBRE",
    "11 SEPTIEMBRE": "11 DE SEPTIEMBRE",
    "V. ALESSANDRI": "VICUNA MACKENNA",  # probable typo
}


# ---------------------------------------------------------------------------
# Address normalization
# ---------------------------------------------------------------------------

def normalize_calle_numero(segment: str) -> str:
    """Detect 'Calle 123' pattern and remove leading zeros from number."""
    m = re.match(r"^(.+?)\s+0?(\d+)\s*$", segment)
    if m and m.group(2).isdigit():
        name_part = m.group(1).strip()
        num_part = m.group(2).lstrip("0") or "0"
        return f"{name_part} {num_part}"
    return segment


def normalize_km(text: str) -> str:
    """Normalize KM notations: 'KM 1.6', 'KM 1,6', 'KILOMETRO 1.6' → 'KM 1.6'."""
    # Replace comma decimal with dot
    text = re.sub(r"(\d),(\d)", r"\1.\2", text)
    # Normalize "KM" variants
    text = re.sub(r"\bKILOMETRO\b", "KM", text, flags=re.IGNORECASE)
    text = re.sub(r"\bKMS?\b", "KM", text, flags=re.IGNORECASE)
    # Ensure space after KM
    text = re.sub(r"\bKM(\d)", r"KM \1", text)
    return text


def normalize_sn(text: str) -> str:
    """Normalize 'S/N', 'S N', 'SIN NUMERO' → 'S/N'."""
    text = re.sub(r"\bS[/\s]?N\b", "S/N", text)
    text = re.sub(r"\bSIN\s+NUMERO\b", "S/N", text, flags=re.IGNORECASE)
    return text


def strip_comuna(text: str, comuna_norm: str) -> str:
    """Remove comuna name from end of address if present as suffix."""
    comuna_words = comuna_norm.split()
    # Try removing "SAN CARLOS" at end
    pattern = r",?\s*" + r"\s+".join(re.escape(w) for w in comuna_words) + r"\s*$"
    text = re.sub(pattern, "", text, flags=re.IGNORECASE).strip()
    return text


def expand_abbrev(segment: str) -> str:
    """Expand known abbreviation if it's a standalone token."""
    upper = segment.upper()
    if upper in ABBREV_MAP:
        expanded = ABBREV_MAP[upper]
        if expanded is not None:
            return expanded
    return segment


def normalize_address(raw: str, comuna_norm: str) -> str:
    """Full normalization pipeline for a single address string."""
    if not raw or not raw.strip():
        return ""

    text = raw.strip().upper()

    # Remove garbage suffixes
    text = re.sub(r"//+$", "", text).strip()
    text = re.sub(r";;+$", "", text).strip()
    text = re.sub(r",\s*$", "", text).strip()

    # Normalize whitespace
    text = re.sub(r"\s+", " ", text).strip()

    # Remove comuna from end
    text = strip_comuna(text, comuna_norm)

    # Normalize KM
    text = normalize_km(text)

    # Normalize S/N
    text = normalize_sn(text)

    # Apply multi-word abbreviations
    for abbrev, full in MULTI_ABBREV.items():
        pattern = r"\b" + re.escape(abbrev) + r"\b"
        if re.search(pattern, text):
            text = re.sub(pattern, full, text)

    # Token-level abbreviation expansion (only standalone tokens)
    tokens = text.split()
    tokens = [expand_abbrev(t) for t in tokens]
    text = " ".join(tokens)

    # Remove leading zeros from standalone numbers (street numbers)
    text = normalize_calle_numero(text)

    # Normalize parentheses spacing
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)

    # Remove duplicate commas
    text = re.sub(r",\s*,", ",", text)

    # Final whitespace cleanup
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"\s+,", ",", text)
    text = re.sub(r",\s+", ", ", text)

    return text


# ---------------------------------------------------------------------------
# Fuzzy grouping helpers
# ---------------------------------------------------------------------------

def tokenize(addr: str) -> set[str]:
    """Split address into token set for Jaccard comparison."""
    return set(re.findall(r"[A-Z0-9]+", addr.upper()))


def jaccard(a: set[str], b: set[str]) -> float:
    if not a and not b:
        return 1.0
    return len(a & b) / len(a | b)


def levenshtein_ratio(s1: str, s2: str) -> float:
    """Simple character-level Levenshtein ratio (0.0-1.0)."""
    if not s1 and not s2:
        return 1.0
    if not s1 or not s2:
        return 0.0
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            cost = 0 if s1[i - 1] == s2[j - 1] else 1
            dp[i][j] = min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost)
    return 1.0 - (dp[m][n] / max(m, n))


def is_similar(addr1: str, addr2: str, token_threshold: float = 0.65, lev_threshold: float = 0.75) -> bool:
    """Two addresses are similar if Jaccard OR Levenshtein passes threshold."""
    t1, t2 = tokenize(addr1), tokenize(addr2)
    if jaccard(t1, t2) >= token_threshold:
        return True
    if levenshtein_ratio(addr1, addr2) >= lev_threshold:
        return True
    return False


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def load_staging_addresses(conn) -> list[dict[str, Any]]:
    rows = conn.execute("""
        SELECT ingreso_id, rut_normalizado, domicilio, comuna
        FROM staging.hodom_ingreso_2026
        WHERE domicilio IS NOT NULL AND btrim(domicilio) <> ''
          AND comuna IS NOT NULL AND btrim(comuna) <> ''
        ORDER BY comuna, domicilio
    """).fetchall()
    return [
        {
            "ingreso_id": r[0],
            "rut": r[1],
            "domicilio": r[2].strip(),
            "comuna_raw": r[3].strip(),
        }
        for r in rows
    ]


def run(conn, dry_run: bool = False, verbose: bool = False):
    print("Cargando direcciones desde staging.hodom_ingreso_2026...")
    rows = load_staging_addresses(conn)
    print(f"  {len(rows)} registros con domicilio + comuna")

    # Normalize all
    print("Normalizando direcciones...")
    normalized: defaultdict[str, dict[str, Any]] = defaultdict(lambda: {
        "original": "",
        "normalizada": "",
        "comuna_raw": "",
        "comuna_norm": "",
        "staging_ids": [],
        "frecuencia": 0,
        "ya_geocodificado": False,
        "localizacion_id": None,
        "calidad_notas": None,
    })

    skipped_bad_comuna = 0
    for row in rows:
        comuna_raw = row["comuna_raw"].upper()
        comuna_norm = COMUNA_MAP.get(comuna_raw)
        if comuna_norm is None:
            skipped_bad_comuna += 1
            continue

        norm = normalize_address(row["domicilio"], comuna_norm)
        if not norm:
            continue

        key = f"{norm}|{comuna_norm}"

        n = normalized[key]
        n["original"] = row["domicilio"]
        n["normalizada"] = norm
        n["comuna_raw"] = comuna_raw
        n["comuna_norm"] = comuna_norm
        n["staging_ids"].append(row["ingreso_id"])
        n["frecuencia"] += 1

    print(f"  {len(normalized)} direcciones normalizadas unicas")
    if skipped_bad_comuna:
        print(f"  {skipped_bad_comuna} registros omitidos (comuna no reconocida)")

    # Cross with existing localizacion
    print("Cruzando con territorial.localizacion existente...")
    loc_map: dict[str, str] = {}
    loc_rows = conn.execute("""
        SELECT localizacion_id, direccion_texto, comuna
        FROM territorial.localizacion
        WHERE direccion_texto IS NOT NULL AND comuna IS NOT NULL
    """).fetchall()

    for loc_id, dir_texto, comuna in loc_rows:
        if dir_texto and comuna:
            loc_key = f"{dir_texto.strip().upper()}|{comuna.strip().upper()}"
            loc_map[loc_key] = loc_id

    matched = 0
    for key, info in normalized.items():
        norm = info["normalizada"]
        comuna = info["comuna_norm"]
        # Try exact match
        loc_key = f"{norm}|{comuna}"
        if loc_key in loc_map:
            info["localizacion_id"] = loc_map[loc_key]
            info["ya_geocodificado"] = True
            matched += 1
        else:
            # Try fuzzy match against existing localizaciones in same comuna
            for loc_key_candidate, loc_id in loc_map.items():
                if comuna in loc_key_candidate:
                    candidate_addr = loc_key_candidate.split("|")[0]
                    if is_similar(norm, candidate_addr):
                        info["localizacion_id"] = loc_id
                        info["ya_geocodificado"] = True
                        info["calidad_notas"] = f"fuzzy_match: '{norm}' ≈ '{candidate_addr}'"
                        matched += 1
                        break

    print(f"  {matched} ya geocodificadas (match con localizacion existente)")

    # Fuzzy dedup: merge very similar normalized addresses within same comuna
    print("Desduplicando direcciones similares...")
    by_comuna: dict[str, list[tuple[str, dict]]] = defaultdict(list)
    for key, info in normalized.items():
        by_comuna[info["comuna_norm"]].append((key, info))

    merged: dict[str, dict] = {}
    seen_keys: set[str] = set()

    for comuna, entries in by_comuna.items():
        entries.sort(key=lambda x: -x[1]["frecuencia"])  # most frequent first
        for key, info in entries:
            if key in seen_keys:
                continue
            # Check similarity with already-kept entries in same comuna
            merged_with = None
            for other_key in list(merged.keys()):
                other = merged[other_key]
                if other["comuna_norm"] != comuna:
                    continue
                if is_similar(info["normalizada"], other["normalizada"]):
                    merged_with = other_key
                    break

            if merged_with:
                # Merge into existing
                m = merged[merged_with]
                m["staging_ids"].extend(info["staging_ids"])
                m["frecuencia"] += info["frecuencia"]
                if info.get("localizacion_id") and not m.get("localizacion_id"):
                    m["localizacion_id"] = info["localizacion_id"]
                    m["ya_geocodificado"] = True
                seen_keys.add(key)
            else:
                merged[key] = info
                seen_keys.add(key)

    dedup_count = len(normalized) - len(merged)
    print(f"  {dedup_count} direcciones fusionadas por similitud")
    print(f"  {len(merged)} direcciones finales unicas")

    # Write to staging.domicilio_normalizado
    print("Escribiendo en staging.domicilio_normalizado...")
    if dry_run:
        print("  DRY RUN — no se escribe en DB. Muestra:")
        for key, info in sorted(merged.items(), key=lambda x: -x[1]["frecuencia"])[:20]:
            status = "GEOREF" if info.get("ya_geocodificado") else "PENDIENTE"
            print(f"    [{status}] {info['comuna_norm']:15s} | {info['normalizada'][:60]} ({info['frecuencia']}x)")
    else:
        # Ensure table exists
        conn.execute("""
            CREATE TABLE IF NOT EXISTS staging.domicilio_normalizado (
                domicilio_norm_id   text PRIMARY KEY,
                direccion_original  text NOT NULL,
                direccion_normalizada text NOT NULL,
                comuna              text,
                comuna_normalizada  text NOT NULL,
                frecuencia          integer NOT NULL DEFAULT 1,
                staging_ids         text[] NOT NULL DEFAULT '{}',
                localizacion_id     text,
                ya_geocodificado    boolean NOT NULL DEFAULT false,
                calidad_notas       text,
                created_at          timestamptz NOT NULL DEFAULT now(),
                updated_at          timestamptz NOT NULL DEFAULT now()
            )
        """)

        written = 0
        for key, info in merged.items():
            norm_id = "dn_" + hashlib.sha256(key.encode()).hexdigest()[:16]
            conn.execute("""
                INSERT INTO staging.domicilio_normalizado
                    (domicilio_norm_id, direccion_original, direccion_normalizada,
                     comuna, comuna_normalizada, frecuencia, staging_ids,
                     localizacion_id, ya_geocodificado, calidad_notas,
                     created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, now(), now())
                ON CONFLICT (domicilio_norm_id) DO UPDATE SET
                    direccion_original = EXCLUDED.direccion_original,
                    direccion_normalizada = EXCLUDED.direccion_normalizada,
                    comuna = EXCLUDED.comuna,
                    comuna_normalizada = EXCLUDED.comuna_normalizada,
                    frecuencia = EXCLUDED.frecuencia,
                    staging_ids = EXCLUDED.staging_ids,
                    localizacion_id = COALESCE(staging.domicilio_normalizado.localizacion_id, EXCLUDED.localizacion_id),
                    ya_geocodificado = EXCLUDED.ya_geocodificado,
                    calidad_notas = EXCLUDED.calidad_notas,
                    updated_at = now()
            """, (
                norm_id,
                info["original"],
                info["normalizada"],
                info["comuna_raw"],
                info["comuna_norm"],
                info["frecuencia"],
                info["staging_ids"],
                info.get("localizacion_id"),
                info["ya_geocodificado"],
                info.get("calidad_notas"),
            ))
            written += 1

        conn.commit()
        print(f"  {written} filas escritas en staging.domicilio_normalizado")

    # Summary
    pendientes = sum(1 for info in merged.values() if not info["ya_geocodificado"])
    georef = sum(1 for info in merged.values() if info["ya_geocodificado"])
    print(f"\nResumen: {len(merged)} direcciones unicas | {georef} ya geocodificadas | {pendientes} pendientes por geocodificar")


def main():
    parser = argparse.ArgumentParser(description="Normalizar domicilios de staging para geocodificacion")
    parser.add_argument("--dry-run", action="store_true", help="Solo mostrar, no escribir en DB")
    parser.add_argument("--verbose", "-v", action="store_true", help="Mostrar detalles de normalizacion")
    args = parser.parse_args()

    with psycopg.connect(DB_URL) as conn:
        run(conn, dry_run=args.dry_run, verbose=args.verbose)


if __name__ == "__main__":
    main()
