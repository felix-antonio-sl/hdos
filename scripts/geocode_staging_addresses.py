#!/usr/bin/env python3
"""Geocodificar direcciones normalizadas pendientes desde staging.domicilio_normalizado.

Pipeline:
  1. Lee staging.domicilio_normalizado WHERE ya_geocodificado = false.
  2. Geocodifica con Nominatim (OpenStreetMap), fallback a centroide de comuna.
  3. Inserta en territorial.localizacion (ON CONFLICT upsert).
  4. Crea clinical.domicilio para cada paciente asociado (vía staging → RUT → paciente).
  5. Marca ya_geocodificado = true en staging.domicilio_normalizado.

Uso:
  python geocode_staging_addresses.py [--dry-run] [--limit N]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
import time
import urllib.parse
import urllib.request
from typing import Any

import psycopg

DB_URL = "postgresql://hodom:hodom@localhost:5555/hodom"
NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
HOSPITAL_LAT = -36.4301
HOSPITAL_LNG = -71.9596

# Ampliado con todas las comunas presentes en staging
COMUNA_CENTROIDS: dict[str, tuple[float, float]] = {
    "SAN CARLOS": (-36.4248, -71.9580),
    "SANCARLOS": (-36.4248, -71.9580),
    "NIQUEN": (-36.2867, -71.9000),
    "ÑIQUEN": (-36.2867, -71.9000),
    "SAN NICOLAS": (-36.5014, -72.2131),
    "SAN  NICOLAS": (-36.5014, -72.2131),
    "SAN GREGORIO": (-36.2833, -71.8167),
    "CHILLAN": (-36.6066, -72.1034),
    "BULNES": (-36.7425, -72.2986),
    "SAN FABIAN": (-36.5500, -71.5500),
    "OTRO": (-36.4248, -71.9580),
}

# Bounding box for Ñuble Region + surrounding
BBOX_LAT_MIN, BBOX_LAT_MAX = -37.5, -35.5
BBOX_LNG_MIN, BBOX_LNG_MAX = -73.5, -71.0


def make_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode()).hexdigest()[:16]}"


GEONAMES_MAP: dict[str, tuple[float, float]] = {
    "AGUA BUENA": (-36.35, -71.85),
    "AGUA BUENA S/N": (-36.35, -71.85),
    "VERQUICO": (-36.38, -71.92),
    "VERQUICO S/N": (-36.38, -71.92),
    "LA RIBERA": (-36.45, -72.00),
    "LA RIBERA S/N": (-36.45, -72.00),
    "EL SAUCE": (-36.40, -71.90),
    "EL SAUCE S/N": (-36.40, -71.90),
    "LAS ARBOLEDAS": (-36.51, -71.90),
    "LAS ARBOLEDAS S/N": (-36.51, -71.90),
    "SAN CAMILO": (-36.42, -71.88),
    "MILLAUQUEN": (-36.43, -71.82),
    "ZEMITA": (-36.38, -71.96),
    "LLAHUIMAVIDA": (-36.37, -71.84),
    "CAMINO SAN AGUSTIN": (-36.43, -71.92),
    "CAPE": (-36.36, -71.89),
    "EL CAPE": (-36.36, -71.89),
    "CAMINO A CAPE": (-36.36, -71.89),
    "TORRECILLAS": (-36.42, -71.80),
    "CACHAPOAL": (-36.41, -71.83),
    "ITIHUE": (-36.46, -71.88),
    "NAVOTAVO": (-36.45, -71.85),
    "MONTELEON": (-36.52, -72.20),
    "TRAPICHE": (-36.42, -71.82),
    "SANTA ISABEL": (-36.48, -71.90),
    "SANTA FILOMENA": (-36.40, -71.88),
    "DAU": (-36.43, -71.90),
    "GAONA": (-36.43, -71.84),
}


def geocode(address: str, comuna: str, verbose: bool = False) -> tuple[float, float, str, str]:
    """Geocode address with Nominatim, falling back to centroids.

    Returns (lat, lng, precision_geo, fuente_coords).
    """
    query_parts = [p for p in [address, comuna, "Region de Nuble", "Chile"] if p]
    query = ", ".join(query_parts)

    # 1. Try local geonames cache for known rural sectors
    key = address.upper().strip()
    for geoname, coords in GEONAMES_MAP.items():
        if geoname in key or key in geoname:
            if verbose:
                print(f"    geonames hit: '{key}' → {geoname}")
            return coords[0], coords[1], "centroide_localidad", "geonames_local_rural_v1"

    # 2. Try Nominatim
    url = NOMINATIM_URL + "?" + urllib.parse.urlencode(
        {"q": query, "format": "json", "limit": 1, "countrycodes": "cl"}
    )
    req = urllib.request.Request(url, headers={"User-Agent": "hdos-geocode-staging/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=8) as res:
            payload = json.loads(res.read().decode("utf-8"))
        if payload:
            lat = float(payload[0]["lat"])
            lng = float(payload[0]["lon"])
            if BBOX_LAT_MIN <= lat <= BBOX_LAT_MAX and BBOX_LNG_MIN <= lng <= BBOX_LNG_MAX:
                precision = "aproximada"
                fuente = "nominatim_osm_staging_v1"
                if verbose:
                    print(f"    Nominatim hit: ({lat:.4f}, {lng:.4f})")
                return lat, lng, precision, fuente
    except Exception as e:
        if verbose:
            print(f"    Nominatim error: {e}")

    # 3. Fallback to comuna centroid
    key_comuna = comuna.strip().upper()
    lat, lng = COMUNA_CENTROIDS.get(key_comuna, COMUNA_CENTROIDS["SAN CARLOS"])
    if verbose:
        print(f"    fallback centroide_comuna: {key_comuna} ({lat:.4f}, {lng:.4f})")
    return lat, lng, "centroide_comuna", "centroide_comuna_fallback_staging_v1"


def load_pending(conn, limit: int | None = None) -> list[dict[str, Any]]:
    query = """
        SELECT domicilio_norm_id, direccion_original, direccion_normalizada,
               comuna_normalizada, frecuencia, staging_ids, localizacion_id,
               ya_geocodificado
        FROM staging.domicilio_normalizado
        WHERE ya_geocodificado = false
        ORDER BY frecuencia DESC
    """
    if limit:
        query += f" LIMIT {limit}"
    rows = conn.execute(query).fetchall()
    return [
        {
            "domicilio_norm_id": r[0],
            "direccion_original": r[1],
            "direccion_normalizada": r[2],
            "comuna_normalizada": r[3],
            "frecuencia": r[4],
            "staging_ids": r[5],
            "localizacion_id": r[6],
            "ya_geocodificado": r[7],
        }
        for r in rows
    ]


def load_already_geocoded(conn, limit: int | None = None) -> list[dict[str, Any]]:
    """Load addresses that are already geocoded but may need domicilio linking."""
    query = """
        SELECT domicilio_norm_id, direccion_normalizada, comuna_normalizada,
               frecuencia, staging_ids, localizacion_id
        FROM staging.domicilio_normalizado
        WHERE ya_geocodificado = true AND localizacion_id IS NOT NULL
        ORDER BY frecuencia DESC
    """
    if limit:
        query += f" LIMIT {limit}"
    rows = conn.execute(query).fetchall()
    return [
        {
            "domicilio_norm_id": r[0],
            "direccion_normalizada": r[1],
            "comuna_normalizada": r[2],
            "frecuencia": r[3],
            "staging_ids": r[4],
            "localizacion_id": r[5],
        }
        for r in rows
    ]


def find_patient_by_rut(conn, rut_norm: str) -> str | None:
    """Find patient_id by normalized RUT."""
    row = conn.execute("""
        SELECT p.patient_id
        FROM clinical.paciente p
        WHERE p.rut IS NOT NULL
          AND staging.norm_text(regexp_replace(p.rut, '[\\s.,]+', '', 'g')) = %s
          AND p.deleted_at IS NULL
        LIMIT 1
    """, (rut_norm,)).fetchone()
    return row[0] if row else None


def find_stay_for_patient(conn, patient_id: str, fecha_ingreso_approx: str | None = None) -> str | None:
    """Find active stay for a patient (prefer 2026)."""
    row = conn.execute("""
        SELECT stay_id FROM clinical.estadia
        WHERE patient_id = %s AND estado = 'activo'
        ORDER BY fecha_ingreso DESC LIMIT 1
    """, (patient_id,)).fetchone()
    return row[0] if row else None


def domicilio_exists(conn, patient_id: str, tipo: str = "principal") -> bool:
    row = conn.execute("""
        SELECT 1 FROM clinical.domicilio
        WHERE patient_id = %s AND tipo = %s
          AND (vigente_hasta IS NULL OR vigente_hasta >= CURRENT_DATE)
        LIMIT 1
    """, (patient_id, tipo)).fetchone()
    return row is not None


def create_domicilios_for_address(
    conn,
    norm_id: str,
    staging_ids: list[str],
    loc_id: str,
    verbose: bool = False,
) -> int:
    """Create clinical.domicilio for each patient linked via staging_ids → RUT.
    Returns number of domicilios created.
    """
    created = 0
    rut_set: set[str] = set()
    for sid in staging_ids:
        rows = conn.execute("""
            SELECT DISTINCT rut_normalizado
            FROM staging.hodom_ingreso_2026
            WHERE ingreso_id = %s AND rut_normalizado IS NOT NULL
        """, (sid,)).fetchall()
        for r in rows:
            rut_set.add(r[0])

    for rut_norm in rut_set:
        patient_id = find_patient_by_rut(conn, rut_norm)
        if not patient_id:
            continue

        if domicilio_exists(conn, patient_id):
            continue

        stay_id = find_stay_for_patient(conn, patient_id)
        fecha_ingreso = None
        if stay_id:
            row = conn.execute(
                "SELECT fecha_ingreso FROM clinical.estadia WHERE stay_id = %s",
                (stay_id,),
            ).fetchone()
            if row:
                fecha_ingreso = row[0]

        dom_id = make_id("dom", f"staging|{patient_id}")
        conn.execute("""
            INSERT INTO clinical.domicilio
                (domicilio_id, patient_id, localizacion_id, tipo, vigente_desde,
                 contacto_local, notas, created_at, updated_at)
            VALUES (%s, %s, %s, 'principal', COALESCE(%s, CURRENT_DATE),
                    NULL, 'Geocodificado desde staging INGRESOS 2026', now(), now())
            ON CONFLICT (domicilio_id) DO UPDATE SET
                localizacion_id = EXCLUDED.localizacion_id,
                updated_at = now()
        """, (dom_id, patient_id, loc_id, fecha_ingreso))

        conn.execute("""
            INSERT INTO migration.provenance
                (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
            VALUES ('clinical.domicilio', %s, 'staging_geocode', 'geocode_staging_addresses.py',
                    %s, 'staging_geocode_2026_05_26', 'localizacion')
            ON CONFLICT DO NOTHING
        """, (dom_id, norm_id))

        created += 1
        if verbose:
            print(f"    domicilio creado: patient_id={patient_id}")

    return created


def run(conn, dry_run: bool = False, limit: int | None = None, verbose: bool = False):
    # Fase 1: geocodificar direcciones pendientes
    print("Fase 1: Geocodificando direcciones pendientes...")
    pending = load_pending(conn, limit=limit)
    print(f"  {len(pending)} direcciones por geocodificar")

    geocoded = 0
    domicilios_created = 0

    for i, addr_info in enumerate(pending):
        norm_id = addr_info["domicilio_norm_id"]
        address = addr_info["direccion_normalizada"]
        comuna = addr_info["comuna_normalizada"]
        freq = addr_info["frecuencia"]
        staging_ids = addr_info["staging_ids"]

        print(f"[{i+1}/{len(pending)}] {comuna}: {address[:60]} ({freq}x)")

        if dry_run:
            lat, lng, precision, fuente = geocode(address, comuna, verbose=verbose)
            print(f"  DRY RUN: ({lat:.4f}, {lng:.4f}) precision={precision} fuente={fuente}")
            geocoded += 1
            continue

        lat, lng, precision, fuente = geocode(address, comuna, verbose=verbose)
        loc_id = make_id("loc", f"staging|{norm_id}")
        conn.execute("""
            INSERT INTO territorial.localizacion
                (localizacion_id, direccion_texto, comuna, latitud, longitud,
                 precision_geo, fuente_coords, tipo_zona, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'URBANO', now(), now())
            ON CONFLICT (localizacion_id) DO UPDATE SET
                latitud = EXCLUDED.latitud,
                longitud = EXCLUDED.longitud,
                precision_geo = EXCLUDED.precision_geo,
                fuente_coords = EXCLUDED.fuente_coords,
                updated_at = now()
        """, (loc_id, address, comuna, lat, lng, precision, fuente))

        created = create_domicilios_for_address(conn, norm_id, staging_ids, loc_id, verbose)
        domicilios_created += created

        conn.execute("""
            UPDATE staging.domicilio_normalizado
            SET ya_geocodificado = true, localizacion_id = %s, updated_at = now()
            WHERE domicilio_norm_id = %s
        """, (loc_id, norm_id))

        geocoded += 1
        time.sleep(1)

    if not dry_run:
        conn.commit()

    # Fase 2: vincular domicilios para direcciones ya geocodificadas
    print("\nFase 2: Vinculando pacientes con direcciones ya geocodificadas...")
    existing = load_already_geocoded(conn, limit=limit)
    print(f"  {len(existing)} direcciones ya geocodificadas para vincular")

    linked = 0
    for addr_info in existing:
        norm_id = addr_info["domicilio_norm_id"]
        loc_id = addr_info["localizacion_id"]
        staging_ids = addr_info["staging_ids"]
        address = addr_info["direccion_normalizada"]

        created = create_domicilios_for_address(conn, norm_id, staging_ids, loc_id, verbose)
        domicilios_created += created
        linked += 1

    if not dry_run:
        conn.commit()
        print(f"  {linked} direcciones procesadas para vinculacion")

    print(f"\nResumen: {geocoded} geocodificadas | {linked} vinculadas | {domicilios_created} domicilios creados")


def main():
    parser = argparse.ArgumentParser(description="Geocodificar direcciones staging y vincular pacientes")
    parser.add_argument("--dry-run", action="store_true", help="Solo mostrar, no escribir en DB")
    parser.add_argument("--limit", type=int, default=None, help="Limitar a N direcciones (para prueba)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Mostrar detalles")
    args = parser.parse_args()

    with psycopg.connect(DB_URL) as conn:
        run(conn, dry_run=args.dry_run, limit=args.limit, verbose=args.verbose)


if __name__ == "__main__":
    main()
