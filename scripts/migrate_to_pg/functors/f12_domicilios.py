# scripts/migrate_to_pg/functors/f12_domicilios.py
"""
F12: Domicilios — clinical.paciente -> territorial.localizacion + clinical.domicilio

Source:  clinical.paciente (direccion, comuna)
Target:  territorial.localizacion (N)
         clinical.domicilio (N)

Step A: patients WITH direccion -> localizacion (centroide_comuna) + domicilio (principal)
Step B: patients WITHOUT direccion but WITH comuna -> same pattern, direccion_texto=NULL

Does NOT touch operational.visita — localizacion_id/domicilio_id columns are for
future programmed visits only. Backfilling would fire triggers and risk corruption.
"""

from __future__ import annotations
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

# Commune centroids from territorial.ubicacion AVG(lat, lng)
CENTROIDES: dict[str, tuple[float, float]] = {
    "SAN CARLOS":    (-36.4185, -71.9786),
    "CHILLAN":       (-36.6236, -72.1352),
    "CHILLÁN":       (-36.6236, -72.1352),
    "CHILLÁN VIEJO": (-36.6763, -72.2175),
    "CHILLAN VIEJO": (-36.6763, -72.2175),
    "COIHUECO":      (-36.6332, -71.8089),
    "EL CARMEN":     (-36.9226, -71.8970),
    "BULNES":        (-36.7915, -72.2806),
    "COBQUECURA":    (-36.1554, -72.7321),
    "COELEMU":       (-36.5101, -72.7501),
    "NINHUE":        (-36.3783, -72.4180),
    "NIQUEN":        (-36.3294, -71.8583),
    "PEMUCO":        (-36.9907, -72.0524),
    "PINTO":         (-36.7877, -71.7910),
    "PORTEZUELO":    (-36.5442, -72.4714),
    "QUILLON":       (-36.8024, -72.4780),
    "QUIRIHUE":      (-36.2608, -72.5603),
    "RANQUIL":       (-36.6310, -72.5743),
    "SAN FABIAN":    (-36.5254, -71.5147),
    "SAN IGNACIO":   (-36.8283, -72.0290),
    "SAN NICOLAS":   (-36.4874, -72.2191),
    "TREGUACO":      (-36.4402, -72.6441),
    "TREHUACO":      (-36.4402, -72.6441),
    "YUNGAY":        (-37.1180, -72.0042),
    "OTRO":          (-36.4185, -71.9786),  # San Carlos default
}

# Default centroid when commune not found
_DEFAULT_CENTROID = (-36.4185, -71.9786)  # San Carlos


def _normalize_direccion(d: str) -> str:
    """Normalize address for hash stability."""
    return " ".join(d.upper().split())


def _centroid_for(comuna: str | None) -> tuple[float, float]:
    """Look up centroid; fall back to San Carlos."""
    if not comuna:
        return _DEFAULT_CENTROID
    key = comuna.strip().upper()
    return CENTROIDES.get(key, _DEFAULT_CENTROID)


class F12Domicilios(Functor):
    name = "F12_domicilios"
    depends_on = ["F2_pacientes", "F3_estadias"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Execute DDL for new tables
        ddl_path = Path(__file__).resolve().parent.parent / "ddl_domicilio.sql"
        ddl = ddl_path.read_text(encoding="utf-8")
        conn.execute(ddl)

        # Step A + B: all patients with comuna (with or without direccion)
        patients = conn.execute("""
            SELECT p.patient_id, p.nombre_completo, p.rut,
                   p.direccion, p.comuna,
                   (SELECT MIN(e.fecha_ingreso) FROM clinical.estadia e
                    WHERE e.patient_id = p.patient_id) AS primer_ingreso
              FROM clinical.paciente p
             WHERE p.comuna IS NOT NULL AND TRIM(p.comuna) != ''
        """).fetchall()

        n_loc = 0
        n_dom = 0

        for patient_id, nombre, rut, direccion, comuna, primer_ingreso in patients:
            # Normalize for hash determinism
            dir_norm = _normalize_direccion(direccion) if direccion and direccion.strip() else None
            has_address = dir_norm is not None

            # localizacion_id: hash from patient + normalized address (or commune-only)
            if has_address:
                loc_seed = f"loc_{patient_id}_{dir_norm}"
            else:
                loc_seed = f"loc_{patient_id}_{comuna.strip().upper()}"
            loc_id = make_id("loc", loc_seed)

            lat, lng = _centroid_for(comuna)

            # INSERT localizacion (idempotent)
            conn.execute(
                """
                INSERT INTO territorial.localizacion
                    (localizacion_id, direccion_texto, comuna, latitud, longitud,
                     precision_geo, fuente_coords)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (localizacion_id) DO NOTHING
                """,
                (
                    loc_id,
                    direccion if has_address else None,
                    comuna,
                    lat,
                    lng,
                    "centroide_comuna",
                    "centroide_ubicacion_avg",
                ),
            )
            n_loc += 1

            # domicilio_id: one principal per patient
            dom_id = make_id("dom", f"dom_{patient_id}_principal")

            # vigente_desde: earliest estadia, or fallback to 2024-01-01
            vigente_desde = primer_ingreso if primer_ingreso else "2024-01-01"

            # INSERT domicilio (idempotent)
            conn.execute(
                """
                INSERT INTO clinical.domicilio
                    (domicilio_id, patient_id, localizacion_id, tipo,
                     vigente_desde, vigente_hasta)
                VALUES (%s, %s, %s, %s, %s, NULL)
                ON CONFLICT (domicilio_id) DO NOTHING
                """,
                (dom_id, patient_id, loc_id, "principal", vigente_desde),
            )
            n_dom += 1

            # Provenance: localizacion
            eta.record(
                conn,
                target_table="territorial.localizacion",
                target_pk=loc_id,
                source_type="clinical",
                source_file="clinical.paciente",
                source_key=patient_id,
                phase="F12",
            )

            # Provenance: domicilio
            eta.record(
                conn,
                target_table="clinical.domicilio",
                target_pk=dom_id,
                source_type="clinical",
                source_file="clinical.paciente",
                source_key=patient_id,
                phase="F12",
            )

            # Field-level provenance for key fields
            if has_address:
                eta.record(
                    conn,
                    target_table="territorial.localizacion",
                    target_pk=loc_id,
                    source_type="clinical",
                    source_file="clinical.paciente",
                    source_key=patient_id,
                    phase="F12",
                    field_name="direccion_texto",
                )
            eta.record(
                conn,
                target_table="territorial.localizacion",
                target_pk=loc_id,
                source_type="derived",
                source_file="centroides_ubicacion_avg",
                source_key=comuna,
                phase="F12",
                field_name="coords",
            )

        return n_loc + n_dom

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE3-LOC-COORDS-COMPLETE",
                sql="SELECT COUNT(*) FROM territorial.localizacion WHERE latitud IS NULL OR longitud IS NULL",
                expected=0,
            ),
            PathEquation(
                name="PE4-NO-ORPHAN-DOMICILIO",
                sql="""SELECT d.domicilio_id FROM clinical.domicilio d
                    LEFT JOIN clinical.paciente p ON p.patient_id = d.patient_id
                    WHERE p.patient_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE4-NO-ORPHAN-LOCALIZACION",
                sql="""SELECT d.domicilio_id FROM clinical.domicilio d
                    LEFT JOIN territorial.localizacion l ON l.localizacion_id = d.localizacion_id
                    WHERE l.localizacion_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F12-PRECISION-ALL-CENTROIDE",
                sql="""SELECT COUNT(*) FROM territorial.localizacion
                    WHERE precision_geo != 'centroide_comuna'""",
                expected=0,
            ),
        ]

    def glue_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="GLUE-F12-F2-PACIENTE-FK",
                sql="""SELECT d.patient_id FROM clinical.domicilio d
                    WHERE d.patient_id NOT IN (SELECT patient_id FROM clinical.paciente)""",
                expected="empty",
            ),
            PathEquation(
                name="GLUE-F12-VISITA-UNTOUCHED",
                sql="""SELECT COUNT(*) FROM operational.visita
                    WHERE localizacion_id IS NOT NULL OR domicilio_id IS NOT NULL""",
                expected=0,
            ),
        ]
