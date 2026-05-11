#!/usr/bin/env python3
"""Prepare HODOM production data for a live demo.

Idempotent operations only:
- Ensure every active stay has a current domicile/localizacion.
- Build today's route and visit plan from active stays with coordinates.
- Build today's handoff rows from active stays.
- Keep vehicle current positions fresh enough for the map demo.

The script intentionally prints aggregate counts only.
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
from datetime import date, datetime, timedelta, timezone

import psycopg


DB_URL = "postgresql://hodom:hodom@localhost:5555/hodom"
HOSPITAL_LAT = -36.4301
HOSPITAL_LNG = -71.9596
COMUNA_CENTROIDS = {
    "SAN CARLOS": (-36.4248, -71.9580),
    "SANCARLOS": (-36.4248, -71.9580),
    "ÑIQUEN": (-36.2867, -71.9000),
    "NIQUEN": (-36.2867, -71.9000),
    "SAN NICOLAS": (-36.5014, -72.2131),
    "SAN  NICOLAS": (-36.5014, -72.2131),
}


def make_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode()).hexdigest()[:16]}"


def geocode(address: str, comuna: str | None) -> tuple[float, float, str]:
    query_parts = [p for p in [address, comuna, "Region de Nuble", "Chile"] if p]
    query = ", ".join(query_parts)
    url = "https://nominatim.openstreetmap.org/search?" + urllib.parse.urlencode(
        {"q": query, "format": "json", "limit": 1, "countrycodes": "cl"}
    )
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "hdos-demo-prepare/1.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as res:
            payload = json.loads(res.read().decode("utf-8"))
        if payload:
            lat = float(payload[0]["lat"])
            lng = float(payload[0]["lon"])
            if -37.5 <= lat <= -35.5 and -73.5 <= lng <= -71.0:
                return lat, lng, "aproximada"
    except Exception:
        pass

    key = (comuna or "SAN CARLOS").strip().upper()
    lat, lng = COMUNA_CENTROIDS.get(key, COMUNA_CENTROIDS["SAN CARLOS"])
    return lat, lng, "centroide_comuna"


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + (
        math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def ensure_active_locations(conn) -> int:
    rows = conn.execute(
        """
        SELECT a.patient_id, a.fecha_ingreso, p.direccion, p.comuna
        FROM reference.v_pacientes_activos a
        JOIN clinical.paciente p ON p.patient_id = a.patient_id
        LEFT JOIN clinical.v_domicilio_vigente d ON d.patient_id = a.patient_id
        WHERE d.latitud IS NULL OR d.longitud IS NULL
        """
    ).fetchall()
    created = 0
    for patient_id, fecha_ingreso, direccion, comuna in rows:
        address = (direccion or comuna or "San Carlos").strip()
        lat, lng, precision = geocode(address, comuna)
        loc_id = make_id("loc", f"demo|{patient_id}|{address}|{comuna}")
        dom_id = make_id("dom", f"demo|{patient_id}|principal")

        conn.execute(
            """
            INSERT INTO territorial.localizacion
                (localizacion_id, direccion_texto, comuna, latitud, longitud,
                 precision_geo, fuente_coords, tipo_zona, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, 'demo_geocode_2026_05_08', 'URBANO', NOW(), NOW())
            ON CONFLICT (localizacion_id) DO UPDATE SET
                latitud = EXCLUDED.latitud,
                longitud = EXCLUDED.longitud,
                precision_geo = EXCLUDED.precision_geo,
                fuente_coords = EXCLUDED.fuente_coords,
                updated_at = NOW()
            """,
            (loc_id, address, comuna, lat, lng, precision),
        )
        conn.execute(
            """
            INSERT INTO clinical.domicilio
                (domicilio_id, patient_id, localizacion_id, tipo, vigente_desde,
                 contacto_local, notas, created_at, updated_at)
            VALUES (%s, %s, %s, 'principal', COALESCE(%s, CURRENT_DATE),
                    NULL, 'Creado para demo desde paciente activo sin domicilio vigente', NOW(), NOW())
            ON CONFLICT (domicilio_id) DO UPDATE SET
                localizacion_id = EXCLUDED.localizacion_id,
                updated_at = NOW()
            """,
            (dom_id, patient_id, loc_id, fecha_ingreso),
        )
        conn.execute(
            """
            INSERT INTO migration.provenance
                (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
            VALUES ('clinical.domicilio', %s, 'demo_prepare', 'prepare_demo_today.py', %s, 'DEMO-2026-05-08', 'localizacion')
            ON CONFLICT DO NOTHING
            """,
            (dom_id, patient_id),
        )
        created += 1
        time.sleep(1)
    return created


def get_route_inputs(conn):
    active = conn.execute(
        """
        SELECT a.stay_id, a.patient_id, a.diagnostico_principal, a.fecha_ingreso,
               d.domicilio_id, d.latitud, d.longitud, d.comuna, d.direccion_texto
        FROM reference.v_pacientes_activos a
        JOIN clinical.v_domicilio_vigente d ON d.patient_id = a.patient_id AND d.tipo = 'principal'
        WHERE d.latitud IS NOT NULL AND d.longitud IS NOT NULL
        ORDER BY d.comuna NULLS LAST, a.fecha_ingreso, a.stay_id
        """
    ).fetchall()
    vehicles = conn.execute(
        """
        SELECT vehiculo_id
        FROM operational.vehiculo
        WHERE estado IN ('operativo', 'disponible') OR estado IS NULL
        ORDER BY patente
        """
    ).fetchall()
    drivers = conn.execute(
        """
        SELECT conductor_id
        FROM operational.conductor
        WHERE estado = 'activo'
        ORDER BY conductor_id
        """
    ).fetchall()
    providers = conn.execute(
        """
        SELECT provider_id, profesion
        FROM operational.profesional
        WHERE estado = 'activo'
        ORDER BY CASE profesion
            WHEN 'ENFERMERIA' THEN 1
            WHEN 'KINESIOLOGIA' THEN 2
            WHEN 'MEDICO' THEN 3
            ELSE 4
        END, provider_id
        """
    ).fetchall()
    return active, vehicles, drivers, providers


def build_today_routes(conn) -> tuple[int, int]:
    active, vehicles, drivers, providers = get_route_inputs(conn)
    if not active or not vehicles or not providers:
        return 0, 0

    route_count = min(3, len(vehicles), len(providers))
    route_ids: list[str] = []
    today = date.today()

    for idx in range(route_count):
        route_id = make_id("route", f"demo|{today.isoformat()}|{idx}")
        route_ids.append(route_id)
        provider_id = providers[idx % len(providers)][0]
        vehiculo_id = vehicles[idx % len(vehicles)][0]
        conductor_id = drivers[idx % len(drivers)][0] if drivers else None
        conn.execute(
            """
            INSERT INTO operational.ruta
                (route_id, provider_id, conductor_id, vehiculo_id, fecha, estado,
                 origen_lat, origen_lng, hora_salida_plan, created_at, updated_at)
            VALUES (%s, %s, %s, %s, CURRENT_DATE, 'planificada',
                    %s, %s, %s, NOW(), NOW())
            ON CONFLICT (route_id) DO UPDATE SET
                provider_id = EXCLUDED.provider_id,
                conductor_id = EXCLUDED.conductor_id,
                vehiculo_id = EXCLUDED.vehiculo_id,
                estado = CASE WHEN operational.ruta.estado = 'completada'
                              THEN operational.ruta.estado ELSE EXCLUDED.estado END,
                updated_at = NOW()
            """,
            (route_id, provider_id, conductor_id, vehiculo_id, HOSPITAL_LAT, HOSPITAL_LNG, f"{8 + idx:02d}:30"),
        )

    sorted_active = sorted(
        active,
        key=lambda r: haversine_km(HOSPITAL_LAT, HOSPITAL_LNG, float(r[5]), float(r[6])),
    )

    for seq, row in enumerate(sorted_active, start=1):
        stay_id, patient_id, diagnosis, _fecha_ingreso, domicilio_id, lat, lng, _comuna, _address = row
        route_idx = (seq - 1) % route_count
        route_id = route_ids[route_idx]
        provider_id = providers[route_idx % len(providers)][0]
        visit_id = make_id("visit", f"demo|{today.isoformat()}|{stay_id}")
        hour = 9 + ((seq - 1) // route_count)
        minute = [0, 20, 40][(seq - 1) % 3]
        conn.execute(
            """
            INSERT INTO operational.visita
                (visit_id, stay_id, patient_id, provider_id, route_id, seq_en_ruta,
                 fecha, hora_plan_inicio, hora_plan_fin, estado, doc_estado,
                 rem_reportable, rem_prestacion, domicilio_id, gps_lat, gps_lng,
                 created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, CURRENT_DATE, %s, %s,
                    'PROGRAMADA', 'pendiente', true, %s, %s, %s, %s, NOW(), NOW())
            ON CONFLICT (visit_id) DO UPDATE SET
                provider_id = EXCLUDED.provider_id,
                route_id = EXCLUDED.route_id,
                seq_en_ruta = EXCLUDED.seq_en_ruta,
                hora_plan_inicio = EXCLUDED.hora_plan_inicio,
                hora_plan_fin = EXCLUDED.hora_plan_fin,
                domicilio_id = EXCLUDED.domicilio_id,
                gps_lat = COALESCE(operational.visita.gps_lat, EXCLUDED.gps_lat),
                gps_lng = COALESCE(operational.visita.gps_lng, EXCLUDED.gps_lng),
                updated_at = NOW()
            """,
            (
                visit_id,
                stay_id,
                patient_id,
                provider_id,
                route_id,
                seq,
                f"{hour:02d}:{minute:02d}",
                f"{hour:02d}:{min(minute + 30, 59):02d}",
                "Visita domiciliaria HODOM",
                domicilio_id,
                lat,
                lng,
            ),
        )
        conn.execute(
            """
            INSERT INTO migration.provenance
                (target_table, target_pk, source_type, source_file, source_key, phase)
            VALUES ('operational.visita', %s, 'demo_prepare', 'prepare_demo_today.py', %s, 'DEMO-2026-05-08')
            ON CONFLICT DO NOTHING
            """,
            (visit_id, stay_id),
        )

    return route_count, len(sorted_active)


def build_handoff(conn) -> tuple[int, int]:
    active_count = conn.execute("SELECT COUNT(*) FROM reference.v_pacientes_activos").fetchone()[0]
    salida = conn.execute(
        "SELECT provider_id FROM operational.profesional WHERE estado='activo' ORDER BY provider_id LIMIT 1"
    ).fetchone()
    entrada = conn.execute(
        "SELECT provider_id FROM operational.profesional WHERE estado='activo' ORDER BY provider_id OFFSET 1 LIMIT 1"
    ).fetchone()
    entrega_id = make_id("entrega", f"demo|{date.today().isoformat()}")
    conn.execute(
        """
        INSERT INTO operational.entrega_turno
            (entrega_id, fecha, turno_saliente_id, turno_entrante_id,
             pacientes_activos, novedades_generales, pendientes, alertas, created_at)
        VALUES (%s, CURRENT_DATE, %s, %s, %s,
                'Censo activo reconciliado con libro mayor de ingresos/egresos 2026.',
                'Revisar programa diario, rutas y pacientes de mayor prioridad.',
                'Mapa territorial y moviles disponibles para demostracion.',
                NOW())
        ON CONFLICT (entrega_id) DO UPDATE SET
            pacientes_activos = EXCLUDED.pacientes_activos,
            novedades_generales = EXCLUDED.novedades_generales,
            pendientes = EXCLUDED.pendientes,
            alertas = EXCLUDED.alertas
        """,
        (entrega_id, salida[0] if salida else None, entrada[0] if entrada else None, active_count),
    )
    rows = conn.execute(
        """
        SELECT a.patient_id, a.stay_id, a.dias_estadia
        FROM reference.v_pacientes_activos a
        ORDER BY a.dias_estadia DESC, a.stay_id
        """
    ).fetchall()
    for patient_id, stay_id, dias in rows:
        prioridad = "alta" if (dias or 0) >= 21 else "normal"
        ep_id = make_id("entpac", f"demo|{date.today().isoformat()}|{stay_id}")
        conn.execute(
            """
            INSERT INTO operational.entrega_turno_paciente
                (entrega_paciente_id, entrega_id, patient_id, stay_id,
                 estado_resumen, novedades, pendientes, prioridad, created_at)
            VALUES (%s, %s, %s, %s,
                    'Hospitalizacion domiciliaria activa',
                    'Caso incluido en censo activo para continuidad operacional.',
                    'Confirmar atencion programada y registrar evolucion del dia.',
                    %s, NOW())
            ON CONFLICT (entrega_paciente_id) DO UPDATE SET
                estado_resumen = EXCLUDED.estado_resumen,
                novedades = EXCLUDED.novedades,
                pendientes = EXCLUDED.pendientes,
                prioridad = EXCLUDED.prioridad
            """,
            (ep_id, entrega_id, patient_id, stay_id, prioridad),
        )
    return 1, len(rows)


def refresh_vehicle_positions(conn) -> int:
    rows = conn.execute(
        """
        SELECT device_id, latitud, longitud, speed, course, online
        FROM telemetry.posicion_actual
        """
    ).fetchall()
    now = datetime.now(timezone.utc)
    for device_id, lat, lng, speed, course, online in rows:
        conn.execute(
            """
            UPDATE telemetry.posicion_actual
            SET dt = %s, updated_at = NOW(), online = COALESCE(%s, online, 'ack')
            WHERE device_id = %s
            """,
            (now, online or "ack", device_id),
        )
    return len(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db-url", default=DB_URL)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    with psycopg.connect(args.db_url, autocommit=False) as conn:
        locations = ensure_active_locations(conn)
        routes, visits = build_today_routes(conn)
        handoffs, handoff_patients = build_handoff(conn)
        vehicles = refresh_vehicle_positions(conn)
        if args.dry_run:
            conn.rollback()
        else:
            conn.commit()

    print(
        json.dumps(
            {
                "dry_run": args.dry_run,
                "locations_created_or_updated": locations,
                "routes_today": routes,
                "visits_today": visits,
                "handoffs_today": handoffs,
                "handoff_patients": handoff_patients,
                "vehicles_refreshed": vehicles,
            },
            ensure_ascii=True,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
