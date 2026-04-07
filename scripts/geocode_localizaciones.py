#!/usr/bin/env python3
"""
Geocode 671 patient locations using Google Maps Geocoding API.

Reads localizaciones from PG, geocodes via Google Maps API,
updates PG with real coordinates + precision_geo, generates provenance.
"""

import json
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

import psycopg

# --- Config ---
PG_DSN = "postgresql://hodom:hodom@localhost:5555/hodom"
GOOGLE_API_KEY = "AIzaSyDNhu45OKX0jwYrbD9wcdz4LsG5utS-rss"
RATE_LIMIT_DELAY = 0.1  # 10 req/s
SQL_OUTPUT = "/home/felix/projects/hdos/scripts/geocode_localizaciones.sql"

PRECISION_RANK = {
    "exacta": 4,
    "aproximada": 3,
    "centroide_localidad": 2,
    "centroide_comuna": 1,
}

PRECISION_MAP = {
    "ROOFTOP": "exacta",
    "RANGE_INTERPOLATED": "exacta",
    "GEOMETRIC_CENTER": "aproximada",
    "APPROXIMATE": "centroide_localidad",
}

# Nuble bounding box (generous)
LAT_MIN, LAT_MAX = -37.5, -35.5
LNG_MIN, LNG_MAX = -73.0, -71.0


def clean_address(addr: str) -> str:
    """Clean address for Google geocoding."""
    if not addr:
        return ""
    cleaned = addr.strip()
    # Remove "Sector " prefix -- Google doesn't understand this Chilean convention
    if cleaned.lower().startswith("sector "):
        cleaned = cleaned[7:]
    # Remove "S/N" suffix (sin numero)
    cleaned = cleaned.replace(" S/N", "").replace(" s/n", "")
    # Remove trailing ",  0" or " 0" (placeholder house numbers)
    if cleaned.endswith(" 0"):
        cleaned = cleaned[:-2].rstrip(", ")
    return cleaned.strip()


def geocode(address: str, comuna: str) -> tuple | None:
    """Geocode an address via Google Maps API.
    Returns (lat, lng, precision, formatted_address) or None.
    """
    full = f"{address}, {comuna}, Nuble, Chile"
    url = (
        "https://maps.googleapis.com/maps/api/geocode/json?"
        f"address={urllib.parse.quote(full)}&key={GOOGLE_API_KEY}&region=cl"
    )
    try:
        resp = json.loads(urllib.request.urlopen(url, timeout=10).read())
    except Exception as e:
        print(f"    HTTP error: {e}")
        return None

    if resp["status"] != "OK":
        return None

    result = resp["results"][0]
    loc = result["geometry"]["location"]
    loc_type = result["geometry"]["location_type"]
    lat, lng = loc["lat"], loc["lng"]

    # Validate within Nuble region
    if not (LAT_MIN < lat < LAT_MAX and LNG_MIN < lng < LNG_MAX):
        return None

    precision = PRECISION_MAP.get(loc_type, "aproximada")
    return (lat, lng, precision, result["formatted_address"])


def main():
    conn = psycopg.connect(PG_DSN)
    print("Connected to PG. Loading localizaciones...")

    rows = conn.execute("""
        SELECT localizacion_id, direccion_texto, comuna, precision_geo, latitud, longitud
        FROM territorial.localizacion
        ORDER BY localizacion_id
    """).fetchall()

    print(f"Loaded {len(rows)} localizaciones")

    results = []  # (loc_id, lat, lng, precision, formatted_addr, strategy)
    stats = {
        "total": len(rows),
        "skipped_no_address": 0,
        "geocoded": 0,
        "failed": 0,
        "by_precision": {"exacta": 0, "aproximada": 0, "centroide_localidad": 0, "centroide_comuna": 0},
        "improved": 0,
        "strategy": {"clean_address": 0, "raw_address": 0, "comuna_fallback": 0},
    }

    t0 = time.time()

    for i, (loc_id, direccion, comuna, current_precision, cur_lat, cur_lng) in enumerate(rows):
        if i > 0 and i % 50 == 0:
            elapsed = time.time() - t0
            print(f"  [{i}/{len(rows)}] {elapsed:.1f}s elapsed, {stats['geocoded']} geocoded, {stats['failed']} failed")

        # Skip null/empty addresses
        if not direccion or not direccion.strip():
            stats["skipped_no_address"] += 1
            continue

        result = None
        strategy = None

        # Strategy A: clean address + comuna
        cleaned = clean_address(direccion)
        if cleaned:
            result = geocode(cleaned, comuna)
            if result:
                strategy = "clean_address"

        # Strategy B: raw address (if clean failed or got APPROXIMATE)
        if result is None or result[2] == "centroide_localidad":
            raw_result = geocode(direccion.strip(), comuna)
            if raw_result:
                # Keep raw if it's better than cleaned
                if result is None or PRECISION_RANK.get(raw_result[2], 0) > PRECISION_RANK.get(result[2], 0):
                    result = raw_result
                    strategy = "raw_address"

        # Strategy C: comuna centroid fallback
        if result is None and comuna and comuna != "OTRO":
            result = geocode("", comuna)
            if result:
                result = (result[0], result[1], "centroide_comuna", result[3])
                strategy = "comuna_fallback"

        if result:
            lat, lng, precision, formatted = result
            new_rank = PRECISION_RANK.get(precision, 0)
            cur_rank = PRECISION_RANK.get(current_precision, 0)

            if new_rank > cur_rank:
                results.append((loc_id, lat, lng, precision, formatted, strategy))
                stats["geocoded"] += 1
                stats["improved"] += 1
                stats["by_precision"][precision] += 1
                stats["strategy"][strategy] += 1
            else:
                # No improvement
                stats["failed"] += 1
        else:
            stats["failed"] += 1

        time.sleep(RATE_LIMIT_DELAY)

    elapsed = time.time() - t0
    print(f"\nDone in {elapsed:.1f}s")
    print(f"\n--- Summary ---")
    print(f"Total localizaciones: {stats['total']}")
    print(f"Skipped (no address): {stats['skipped_no_address']}")
    print(f"Geocoded & improved:  {stats['geocoded']}")
    print(f"Failed/no improvement:{stats['failed']}")
    print(f"\nBy precision:")
    for p in ["exacta", "aproximada", "centroide_localidad", "centroide_comuna"]:
        print(f"  {p}: {stats['by_precision'][p]}")
    print(f"\nBy strategy:")
    for s, c in stats["strategy"].items():
        print(f"  {s}: {c}")

    # --- Generate and execute SQL ---
    now = datetime.now(timezone.utc).isoformat()

    sql_lines = ["BEGIN;\n"]
    for loc_id, lat, lng, precision, formatted, strategy in results:
        # Escape single quotes in formatted address
        safe_formatted = formatted.replace("'", "''") if formatted else ""
        sql_lines.append(
            f"UPDATE territorial.localizacion "
            f"SET latitud = {lat}, longitud = {lng}, "
            f"precision_geo = '{precision}', "
            f"fuente_coords = 'google_geocoding', "
            f"updated_at = '{now}' "
            f"WHERE localizacion_id = '{loc_id}';"
        )
        sql_lines.append(
            f"INSERT INTO migration.provenance "
            f"(target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) "
            f"VALUES ('territorial.localizacion', '{loc_id}', 'google', 'google_geocoding_api', "
            f"'{safe_formatted}', 'GEOCODE', 'latitud,longitud,precision_geo', '{now}');"
        )

    sql_lines.append("\nCOMMIT;")
    sql_text = "\n".join(sql_lines)

    # Write SQL file
    with open(SQL_OUTPUT, "w") as f:
        f.write(sql_text)
    print(f"\nSQL written to {SQL_OUTPUT}")

    # Apply to PG
    if results:
        print(f"Applying {len(results)} updates to PG...")
        conn.execute(sql_text)
        conn.commit()
        print("Done. Updates applied to PG.")
    else:
        print("No improvements found, nothing to apply.")

    conn.close()


if __name__ == "__main__":
    main()
