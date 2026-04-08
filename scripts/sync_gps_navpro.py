#!/usr/bin/env python3
"""
SYNC-GPS: Sincronización de posiciones GPS desde NavPro.cl → PG telemetry.

Dos modos de operación:
  --poll    Polling liviano: obtiene posición actual de los 3 vehículos
            via /objects/items (JSON, ~2KB). Cada 30 min, 07:00-21:00.
  (sin flag) Sync completo: export CSV del rango de fechas, detección de
            paradas, matching geoespacial con domicilios/visitas, resúmenes
            diarios. Una vez al día a las 21:30.

Fuente:   NavPro.cl (GPS TECNOMACK, v3.7.7, Cloudflare-protected)
Target:   telemetry.gps_posicion, telemetria_segmento, telemetria_resumen_diario,
          telemetry.posicion_actual, operational.vehiculo, telemetria_dispositivo

Idempotencia: ON CONFLICT DO NOTHING/UPDATE en todas las tablas.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import os
import re
import sys
import time
from datetime import date, datetime, timedelta, timezone
from math import atan2, cos, radians, sin, sqrt
from pathlib import Path

import cloudscraper
import psycopg


# ---------------------------------------------------------------------------
# ID generation (same pattern as framework/hash_ids.py)
# ---------------------------------------------------------------------------

def make_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode()).hexdigest()[:12]}"


# ---------------------------------------------------------------------------
# NavPro client
# ---------------------------------------------------------------------------

NAVPRO_BASE = "https://navpro.cl"

DEVICES = {
    "PFFF57": {"navpro_id": 23, "nombre": "PFFF57- RICARDO ALVIAL"},
    "RGHB14": {"navpro_id": 51, "nombre": "RGHB14 NAVARA"},
    "TZXS94": {"navpro_id": 208, "nombre": "SUV TZXS94"},
}


class NavProClient:
    """Stateful client for NavPro.cl GPS fleet platform."""

    def __init__(self, user: str, password: str):
        self.scraper = cloudscraper.create_scraper(
            browser={"browser": "chrome", "platform": "linux", "desktop": True}
        )
        self._login(user, password)

    def _login(self, user: str, password: str):
        r = self.scraper.get(f"{NAVPRO_BASE}/login")
        m = re.search(r'name="_token" type="hidden" value="([^"]+)"', r.text)
        if not m:
            raise RuntimeError("No se encontró CSRF token en NavPro login")
        csrf = m.group(1)

        r2 = self.scraper.post(
            f"{NAVPRO_BASE}/authentication/store",
            data={
                "_token": csrf,
                "email": user,
                "password": password,
                "remember_me": "1",
            },
            allow_redirects=True,
        )
        if r2.status_code != 200 or "/login" in r2.url:
            raise RuntimeError(f"Login NavPro falló: status={r2.status_code} url={r2.url}")

        # Extract post-login CSRF for XHR calls
        m2 = re.search(r'name="csrf-token" content="([^"]+)"', r2.text)
        self.csrf = m2.group(1) if m2 else csrf
        self.headers = {
            "X-CSRF-TOKEN": self.csrf,
            "X-Requested-With": "XMLHttpRequest",
        }

    def get_current_positions(self) -> list[dict]:
        """GET /objects/items → posición actual de todos los vehículos."""
        r = self.scraper.get(f"{NAVPRO_BASE}/objects/items", headers=self.headers)
        r.raise_for_status()
        data = r.json()
        return data.get("data", [])

    def export_csv(self, device_id: int, from_date: date, to_date: date) -> str:
        """Export CSV de posiciones GPS. Max 31 días por request."""
        r = self.scraper.get(
            f"{NAVPRO_BASE}/history/export",
            headers=self.headers,
            params={
                "device_id": device_id,
                "from_date": from_date.isoformat(),
                "from_time": "00:00",
                "to_date": to_date.isoformat(),
                "to_time": "23:59",
                "format": "csv",
            },
        )
        r.raise_for_status()
        dl = r.json()
        url = dl["download"]
        r2 = self.scraper.get(url)
        r2.raise_for_status()
        return r2.text


# ---------------------------------------------------------------------------
# DDL & seed
# ---------------------------------------------------------------------------

DDL = """\
-- Tabla de posiciones actual (1 fila por vehículo, UPSERT cada 30 min)
CREATE TABLE IF NOT EXISTS telemetry.posicion_actual (
    device_id   TEXT PRIMARY KEY
                REFERENCES telemetry.telemetria_dispositivo(device_id),
    dt          TIMESTAMPTZ NOT NULL,
    latitud     REAL NOT NULL,
    longitud    REAL NOT NULL,
    speed       REAL,
    course      REAL,
    online      TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de posiciones GPS históricas (raw CSV import)
CREATE TABLE IF NOT EXISTS telemetry.gps_posicion (
    posicion_id  TEXT PRIMARY KEY,
    device_id    TEXT NOT NULL
                 REFERENCES telemetry.telemetria_dispositivo(device_id),
    dt           TIMESTAMPTZ NOT NULL,
    latitud      REAL NOT NULL,
    longitud     REAL NOT NULL,
    altitude     REAL,
    course       REAL,
    speed        REAL,
    distance     REAL,
    total_distance REAL,
    motion       BOOLEAN,
    ignition     BOOLEAN,
    event        TEXT,
    accuracy     REAL,
    alarm        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_gps_pos_device_dt
    ON telemetry.gps_posicion(device_id, dt);
CREATE INDEX IF NOT EXISTS idx_gps_posicion_device_dt
    ON telemetry.gps_posicion(device_id, dt);
"""


def seed_vehicles(conn):
    """Insert vehículos y dispositivos GPS si no existen."""
    for patente, info in DEVICES.items():
        veh_id = make_id("veh", f"navpro|{patente}")
        dev_id = make_id("dev", f"navpro|{patente}")

        conn.execute(
            """INSERT INTO operational.vehiculo
                   (vehiculo_id, patente, gps_device_name, gps_plataforma, tipo)
               VALUES (%s, %s, %s, 'navpro', 'auto')
               ON CONFLICT (vehiculo_id) DO NOTHING""",
            (veh_id, patente, info["nombre"]),
        )
        conn.execute(
            """INSERT INTO telemetry.telemetria_dispositivo
                   (device_id, vehiculo_id, nombre, plataforma)
               VALUES (%s, %s, %s, 'navpro')
               ON CONFLICT (device_id) DO NOTHING""",
            (dev_id, veh_id, info["nombre"]),
        )


# ---------------------------------------------------------------------------
# CSV parsing
# ---------------------------------------------------------------------------

def parse_csv_text(csv_text: str, device_id: str) -> list[dict]:
    """Parse NavPro CSV export → list of point dicts."""
    reader = csv.DictReader(io.StringIO(csv_text))
    points = []
    for row in reader:
        dt_str = row.get("dt", "").strip().strip('"')
        if not dt_str:
            continue
        try:
            dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue

        lat = float(row.get("lat", 0))
        lng = float(row.get("lng", 0))
        if lat == 0 and lng == 0:
            continue

        speed_raw = row.get("speed", "0")
        motion_raw = row.get("motion", "false")

        points.append({
            "device_id": device_id,
            "dt": dt,
            "lat": lat,
            "lng": lng,
            "altitude": _float_or_none(row.get("altitude")),
            "course": _float_or_none(row.get("course")),
            "speed": _float_or_none(speed_raw),
            "distance": _float_or_none(row.get("distance")),
            "total_distance": _float_or_none(row.get("totaldistance")),
            "motion": motion_raw.strip().lower() == "true",
            "ignition": row.get("ignition", "false").strip().lower() == "true",
            "event": row.get("event", "").strip() or None,
            "accuracy": _float_or_none(row.get("accuracy")),
            "alarm": row.get("alarm", "").strip() or None,
        })
    return points


def _float_or_none(v):
    if v is None:
        return None
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


# ---------------------------------------------------------------------------
# Segment detection
# ---------------------------------------------------------------------------

def detect_segments(points: list[dict], device_id: str) -> list[dict]:
    """Detect drive/stop segments from ordered GPS points.

    Stop: speed ≈ 0 AND motion=false, duration ≥ 300s (5 min).
    Drive: speed > 0 OR motion=true.
    """
    if not points:
        return []

    pts = sorted(points, key=lambda p: p["dt"])
    segments = []
    cur_type = None
    cur_points = []

    for pt in pts:
        is_stop = (pt["speed"] is None or pt["speed"] < 1) and not pt["motion"]
        pt_type = "stop" if is_stop else "drive"

        if pt_type != cur_type:
            if cur_type and cur_points:
                seg = _finalize_segment(cur_type, cur_points, device_id)
                if seg:
                    segments.append(seg)
            cur_type = pt_type
            cur_points = [pt]
        else:
            cur_points.append(pt)

    if cur_type and cur_points:
        seg = _finalize_segment(cur_type, cur_points, device_id)
        if seg:
            segments.append(seg)

    return segments


def _finalize_segment(tipo: str, pts: list[dict], device_id: str) -> dict | None:
    start = pts[0]
    end = pts[-1]
    dur = int((end["dt"] - start["dt"]).total_seconds())

    # Skip stops shorter than 5 minutes
    if tipo == "stop" and dur < 300:
        return None

    speeds = [p["speed"] for p in pts if p["speed"] is not None]
    total_dist = sum(p["distance"] or 0 for p in pts)

    seg_id = make_id("seg", f"{device_id}|{start['dt'].isoformat()}")

    return {
        "segment_id": seg_id,
        "device_id": device_id,
        "tipo": tipo,
        "start_at": start["dt"],
        "end_at": end["dt"],
        "start_lat": start["lat"],
        "start_lng": start["lng"],
        "end_lat": end["lat"],
        "end_lng": end["lng"],
        "distancia_km": round(total_dist, 3) if total_dist else 0,
        "duracion_seg": dur,
        "velocidad_max_kmh": max(speeds) if speeds else None,
    }


# ---------------------------------------------------------------------------
# Haversine geo-matching
# ---------------------------------------------------------------------------

def haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Distance in meters between two GPS points."""
    R = 6_371_000
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
    return R * 2 * atan2(sqrt(a), sqrt(1 - a))


def match_stops_to_visits(
    stops: list[dict],
    domicilios: list[dict],
    visitas_por_fecha: dict[date, list[dict]],
) -> list[dict]:
    """Match stop segments to patient visits via geospatial + temporal cross."""
    matches = []
    for stop in stops:
        fecha = stop["start_at"].date()
        visitas_dia = visitas_por_fecha.get(fecha, [])
        if not visitas_dia:
            continue

        best_dist = 999_999.0
        best_dom = None
        for dom in domicilios:
            d = haversine_m(stop["start_lat"], stop["start_lng"], dom["lat"], dom["lng"])
            if d < best_dist:
                best_dist = d
                best_dom = dom

        if best_dist > 150 or best_dom is None:
            continue

        visita = next(
            (v for v in visitas_dia if v["patient_id"] == best_dom["patient_id"]),
            None,
        )
        if visita:
            score = round((1 - best_dist / 150) * 0.7 + 0.3, 3)
            matches.append({
                "segment_id": stop["segment_id"],
                "visit_id": visita["visit_id"],
                "distance_m": round(best_dist, 1),
                "correlacion_score": score,
                "gps_lat": stop["start_lat"],
                "gps_lng": stop["start_lng"],
            })
    return matches


# ---------------------------------------------------------------------------
# DB operations
# ---------------------------------------------------------------------------

def insert_positions(conn, points: list[dict]) -> int:
    """Bulk insert GPS positions. ON CONFLICT DO NOTHING for idempotency."""
    n = 0
    for pt in points:
        pos_id = make_id("gps", f"{pt['device_id']}|{pt['dt'].isoformat()}")
        try:
            conn.execute(
                """INSERT INTO telemetry.gps_posicion
                       (posicion_id, device_id, dt, latitud, longitud, altitude,
                        course, speed, distance, total_distance, motion,
                        ignition, event, accuracy, alarm)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                   ON CONFLICT DO NOTHING""",
                (
                    pos_id, pt["device_id"], pt["dt"], pt["lat"], pt["lng"],
                    pt["altitude"], pt["course"], pt["speed"], pt["distance"],
                    pt["total_distance"], pt["motion"], pt["ignition"],
                    pt["event"], pt["accuracy"], pt["alarm"],
                ),
            )
            n += 1
        except Exception as e:
            print(f"  WARN insert position: {e}", file=sys.stderr)
    return n


def insert_segments(conn, segments: list[dict]) -> int:
    """Insert drive/stop segments. ON CONFLICT UPDATE for re-processing."""
    n = 0
    for seg in segments:
        conn.execute(
            """INSERT INTO telemetry.telemetria_segmento
                   (segment_id, device_id, tipo, start_at, end_at,
                    start_lat, start_lng, end_lat, end_lng,
                    distancia_km, duracion_seg, velocidad_max_kmh)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
               ON CONFLICT (segment_id) DO UPDATE SET
                    end_at = EXCLUDED.end_at,
                    distancia_km = EXCLUDED.distancia_km,
                    duracion_seg = EXCLUDED.duracion_seg,
                    velocidad_max_kmh = EXCLUDED.velocidad_max_kmh""",
            (
                seg["segment_id"], seg["device_id"], seg["tipo"],
                seg["start_at"], seg["end_at"],
                seg["start_lat"], seg["start_lng"],
                seg["end_lat"], seg["end_lng"],
                seg["distancia_km"], seg["duracion_seg"],
                seg["velocidad_max_kmh"],
            ),
        )
        n += 1
    return n


def apply_matches(conn, matches: list[dict]) -> int:
    """Update segments with visit_id + correlacion_score, and visita with GPS coords."""
    n = 0
    for m in matches:
        conn.execute(
            """UPDATE telemetry.telemetria_segmento
               SET visit_id = %s, correlacion_score = %s
               WHERE segment_id = %s""",
            (m["visit_id"], m["correlacion_score"], m["segment_id"]),
        )
        conn.execute(
            """UPDATE operational.visita
               SET gps_lat = %s, gps_lng = %s, updated_at = NOW()
               WHERE visit_id = %s AND gps_lat IS NULL""",
            (m["gps_lat"], m["gps_lng"], m["visit_id"]),
        )
        n += 1
    return n


def upsert_daily_summary(conn, device_id: str, fecha: date, segments: list[dict]):
    """Upsert telemetria_resumen_diario for a device+date."""
    drives = [s for s in segments if s["tipo"] == "drive"]
    stops = [s for s in segments if s["tipo"] == "stop"]

    km = sum(s["distancia_km"] for s in drives)
    min_drive = sum(s["duracion_seg"] for s in drives) / 60
    min_stop = sum(s["duracion_seg"] for s in stops) / 60
    vmax = max((s["velocidad_max_kmh"] or 0 for s in segments), default=0)

    all_times = [s["start_at"] for s in segments] + [s["end_at"] for s in segments if s["end_at"]]
    primer = min(all_times) if all_times else None
    ultimo = max(all_times) if all_times else None

    resumen_id = make_id("rd", f"{device_id}|{fecha.isoformat()}")

    conn.execute(
        """INSERT INTO telemetry.telemetria_resumen_diario
               (resumen_id, device_id, fecha, km_totales,
                minutos_drive, minutos_stop,
                n_segmentos_drive, n_segmentos_stop,
                n_stops_significativos, velocidad_max_kmh,
                primer_movimiento, ultimo_movimiento)
           VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
           ON CONFLICT (device_id, fecha) DO UPDATE SET
                km_totales = EXCLUDED.km_totales,
                minutos_drive = EXCLUDED.minutos_drive,
                minutos_stop = EXCLUDED.minutos_stop,
                n_segmentos_drive = EXCLUDED.n_segmentos_drive,
                n_segmentos_stop = EXCLUDED.n_segmentos_stop,
                n_stops_significativos = EXCLUDED.n_stops_significativos,
                velocidad_max_kmh = EXCLUDED.velocidad_max_kmh,
                primer_movimiento = EXCLUDED.primer_movimiento,
                ultimo_movimiento = EXCLUDED.ultimo_movimiento""",
        (
            resumen_id, device_id, fecha, round(km, 2),
            round(min_drive, 1), round(min_stop, 1),
            len(drives), len(stops), len(stops),
            round(vmax, 1) if vmax else None,
            primer, ultimo,
        ),
    )


def insert_provenance(conn, target_table: str, target_pk: str, source_key: str):
    conn.execute(
        """INSERT INTO migration.provenance
               (target_table, target_pk, source_type, source_file, source_key, phase)
           VALUES (%s, %s, 'navpro_gps', 'sync_gps_navpro.py', %s, 'SYNC-GPS')
           ON CONFLICT DO NOTHING""",
        (target_table, target_pk, source_key),
    )


# ---------------------------------------------------------------------------
# Poll mode (lightweight, every 30 min)
# ---------------------------------------------------------------------------

def run_poll(conn, client: NavProClient, dry_run: bool) -> dict:
    """Fetch current positions from /objects/items and upsert posicion_actual."""
    positions = client.get_current_positions()
    updated = 0

    patente_to_device = {}
    for patente in DEVICES:
        patente_to_device[DEVICES[patente]["navpro_id"]] = make_id("dev", f"navpro|{patente}")

    for pos in positions:
        navpro_id = pos.get("id")
        device_id = patente_to_device.get(navpro_id)
        if not device_id:
            continue

        dt_str = pos.get("time", "")
        try:
            dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue

        lat = float(pos.get("lat", 0))
        lng = float(pos.get("lng", 0))
        if lat == 0 and lng == 0:
            continue

        if not dry_run:
            conn.execute(
                """INSERT INTO telemetry.posicion_actual
                       (device_id, dt, latitud, longitud, speed, course, online)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)
                   ON CONFLICT (device_id) DO UPDATE SET
                       dt = EXCLUDED.dt,
                       latitud = EXCLUDED.latitud,
                       longitud = EXCLUDED.longitud,
                       speed = EXCLUDED.speed,
                       course = EXCLUDED.course,
                       online = EXCLUDED.online,
                       updated_at = NOW()""",
                (
                    device_id, dt, lat, lng,
                    float(pos.get("speed", 0)),
                    float(pos.get("course", 0)),
                    pos.get("online", "offline"),
                ),
            )
        updated += 1
        status = pos.get("online", "?")
        speed = pos.get("speed", 0)
        print(f"  {pos.get('name','?'):30s}  {lat:.6f}, {lng:.6f}  "
              f"v={speed}km/h  status={status}  t={dt_str}")

    if not dry_run:
        conn.commit()

    return {"polled": len(positions), "updated": updated}


# ---------------------------------------------------------------------------
# Full sync mode (daily, CSV export + processing)
# ---------------------------------------------------------------------------

def run_full_sync(
    conn,
    client: NavProClient,
    from_date: date,
    to_date: date,
    device_filter: str | None,
    dry_run: bool,
) -> dict:
    """Full sync: download CSV, detect segments, match visits, build summaries."""

    # Load domicilios for geo-matching
    domicilios = [
        {"patient_id": r[0], "lat": r[1], "lng": r[2], "domicilio_id": r[3]}
        for r in conn.execute("""
            SELECT patient_id, latitud, longitud, domicilio_id
            FROM clinical.v_domicilio_vigente
            WHERE latitud IS NOT NULL AND longitud IS NOT NULL
        """).fetchall()
    ]
    print(f"Domicilios cargados: {len(domicilios)}")

    # Load visitas indexed by fecha
    visitas_rows = conn.execute(
        """SELECT visit_id, patient_id, fecha
           FROM operational.visita
           WHERE fecha BETWEEN %s AND %s""",
        (from_date, to_date),
    ).fetchall()
    visitas_por_fecha: dict[date, list[dict]] = {}
    for vid, pid, f in visitas_rows:
        visitas_por_fecha.setdefault(f, []).append(
            {"visit_id": vid, "patient_id": pid}
        )
    print(f"Visitas en rango: {len(visitas_rows)}")

    devices = DEVICES
    if device_filter:
        devices = {device_filter: DEVICES[device_filter]}

    stats = {
        "positions": 0, "segments": 0, "matches": 0,
        "days": 0, "devices": len(devices),
    }

    for patente, info in devices.items():
        device_id = make_id("dev", f"navpro|{patente}")
        navpro_id = info["navpro_id"]
        print(f"\n{'='*60}")
        print(f"Vehículo: {patente} (NavPro ID={navpro_id})")

        # Download CSV in 31-day chunks
        all_points = []
        current = from_date
        while current <= to_date:
            chunk_end = min(current + timedelta(days=30), to_date)
            print(f"  Descargando {current} → {chunk_end}...", end=" ", flush=True)
            try:
                csv_text = client.export_csv(navpro_id, current, chunk_end)
                pts = parse_csv_text(csv_text, device_id)
                all_points.extend(pts)
                print(f"{len(pts)} puntos")
            except Exception as e:
                print(f"ERROR: {e}")
            current = chunk_end + timedelta(days=1)
            time.sleep(1)  # Rate limit courtesy

        if not all_points:
            print("  Sin datos GPS")
            continue

        # Insert positions
        if not dry_run:
            n_pos = insert_positions(conn, all_points)
            stats["positions"] += n_pos
            print(f"  Posiciones insertadas: {n_pos}")
        else:
            stats["positions"] += len(all_points)
            print(f"  Posiciones (dry-run): {len(all_points)}")

        # Group by date, detect segments, match
        by_date: dict[date, list[dict]] = {}
        for pt in all_points:
            by_date.setdefault(pt["dt"].date(), []).append(pt)

        total_segs = 0
        total_matches = 0

        for fecha in sorted(by_date):
            day_points = by_date[fecha]
            segments = detect_segments(day_points, device_id)

            if not dry_run:
                n_seg = insert_segments(conn, segments)
            else:
                n_seg = len(segments)
            total_segs += n_seg

            # Match stops to visits
            stops = [s for s in segments if s["tipo"] == "stop"]
            matches = match_stops_to_visits(stops, domicilios, visitas_por_fecha)
            if not dry_run:
                n_match = apply_matches(conn, matches)
            else:
                n_match = len(matches)
            total_matches += n_match

            # Daily summary
            if not dry_run and segments:
                upsert_daily_summary(conn, device_id, fecha, segments)

            drives = [s for s in segments if s["tipo"] == "drive"]
            km = sum(s["distancia_km"] for s in drives)
            print(f"    {fecha}: {len(day_points):4d} pts, "
                  f"{len(drives)} drives, {len(stops)} stops, "
                  f"{n_match} matches, {km:.1f} km")

            stats["days"] += 1

        stats["segments"] += total_segs
        stats["matches"] += total_matches

        # Provenance (one per device sync)
        if not dry_run:
            insert_provenance(
                conn,
                "telemetry.gps_posicion",
                f"batch_{device_id}_{from_date}_{to_date}",
                f"{patente}|{from_date}|{to_date}",
            )

    if not dry_run:
        conn.commit()

    return stats


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="SYNC-GPS: NavPro.cl → PG telemetry"
    )
    parser.add_argument(
        "--db-url",
        default="postgresql://hodom:hodom@localhost:5555/hodom",
    )
    parser.add_argument("--poll", action="store_true",
                        help="Modo poll: solo posición actual (liviano)")
    parser.add_argument("--from-date", type=date.fromisoformat, default=None,
                        help="Fecha inicio (default: último dt en PG + 1 día)")
    parser.add_argument("--to-date", type=date.fromisoformat, default=None,
                        help="Fecha fin (default: ayer)")
    parser.add_argument("--device", choices=list(DEVICES.keys()),
                        help="Solo un vehículo")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    conn = psycopg.connect(args.db_url, autocommit=False)

    # DDL + seed (always, idempotent)
    conn.execute(DDL)
    seed_vehicles(conn)
    conn.commit()

    navpro_user = os.environ.get("NAVPRO_USER", "accesoe1@ttm.cl")
    navpro_pass = os.environ.get("NAVPRO_PASS", "Ac123321")

    print(f"Conectando a NavPro como {navpro_user}...")
    client = NavProClient(navpro_user, navpro_pass)
    print("Login OK\n")

    if args.poll:
        print("=== MODO POLL: posición actual ===")
        result = run_poll(conn, client, args.dry_run)
        print(f"\nPolled: {result['polled']}, Updated: {result['updated']}")
    else:
        # Determine date range
        if args.from_date:
            from_date = args.from_date
        else:
            row = conn.execute(
                "SELECT MAX(dt)::date FROM telemetry.gps_posicion"
            ).fetchone()
            if row[0]:
                from_date = row[0] + timedelta(days=1)
            else:
                from_date = date(2026, 1, 1)

        to_date = args.to_date or (date.today() - timedelta(days=1))

        if from_date > to_date:
            print(f"Nada que sincronizar: última fecha en PG = {from_date - timedelta(days=1)}, to_date = {to_date}")
            conn.close()
            return

        print(f"=== SYNC COMPLETO: {from_date} → {to_date} ===")
        prefix = "[DRY-RUN] " if args.dry_run else ""
        print(f"{prefix}Rango: {(to_date - from_date).days + 1} días\n")

        result = run_full_sync(conn, client, from_date, to_date, args.device, args.dry_run)

        print(f"\n{'='*60}")
        print(f"{prefix}Resumen:")
        print(f"  Vehículos:   {result['devices']}")
        print(f"  Días:        {result['days']}")
        print(f"  Posiciones:  {result['positions']:,}")
        print(f"  Segmentos:   {result['segments']:,}")
        print(f"  Matches:     {result['matches']}")

        if not args.dry_run:
            # Print post-sync stats
            for label, sql in [
                ("gps_posicion", "SELECT count(*) FROM telemetry.gps_posicion"),
                ("segmentos", "SELECT count(*) FROM telemetry.telemetria_segmento"),
                ("stops matcheados", "SELECT count(*) FROM telemetry.telemetria_segmento WHERE visit_id IS NOT NULL"),
                ("resúmenes diarios", "SELECT count(*) FROM telemetry.telemetria_resumen_diario"),
            ]:
                n = conn.execute(sql).fetchone()[0]
                print(f"  {label}: {n:,}")

    conn.close()


if __name__ == "__main__":
    main()
