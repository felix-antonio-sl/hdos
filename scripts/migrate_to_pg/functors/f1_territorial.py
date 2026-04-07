# scripts/migrate_to_pg/functors/f1_territorial.py
"""
F1: Territorial — establishments + locations.
Source:  canonical/establishment_reference.csv, canonical/locality_reference.csv
Target:  territorial.establecimiento (86), territorial.ubicacion (1660)
"""

from __future__ import annotations
import csv
import psycopg
try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]

_TIPO_MAP = {
    "Hospital": "hospital",
    "CESFAM": "cesfam",
    "CECOSF": "cecosf",
    "Posta de Salud Rural": "postas",
    "CGR": "otro",
    "SAPU": "sapu",
    "SAR": "sar",
    "COSAM": "cosam",
}


class F1Territorial(Functor):
    name = "F1_territorial"
    depends_on = ["F0_bootstrap"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()
        n = 0

        # Establecimientos
        estab_path = sources.canonical_dir / "establishment_reference.csv"
        with open(estab_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                eid = row["establishment_id"].strip()
                tipo_raw = row.get("tipo_establecimiento", "").strip()
                tipo = _TIPO_MAP.get(tipo_raw)
                via = row.get("via", "").strip()
                numero = row.get("numero", "").strip()
                direccion = f"{via} {numero}".strip() if via else row.get("direccion", "").strip()

                conn.execute("""
                    INSERT INTO territorial.establecimiento
                        (establecimiento_id, nombre, tipo, comuna, direccion, servicio_salud)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (establecimiento_id) DO UPDATE SET
                        nombre = EXCLUDED.nombre,
                        tipo = EXCLUDED.tipo,
                        comuna = EXCLUDED.comuna,
                        direccion = EXCLUDED.direccion,
                        servicio_salud = EXCLUDED.servicio_salud
                """, (
                    eid,
                    row.get("nombre_oficial", "").strip(),
                    tipo,
                    row.get("comuna", "").strip() or None,
                    direccion or None,
                    row.get("servicio_salud", "").strip() or None,
                ))
                eta.record(
                    conn,
                    target_table="territorial.establecimiento",
                    target_pk=eid,
                    source_type="canonical",
                    source_file="establishment_reference.csv",
                    source_key=eid,
                    phase="F1",
                )
                n += 1

        # Ubicaciones
        loc_path = sources.canonical_dir / "locality_reference.csv"
        with open(loc_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                lid = row["locality_id"].strip()
                tt = row.get("territory_type", "").strip().upper()
                tipo = tt if tt in ("URBANO", "PERIURBANO", "RURAL", "RURAL_AISLADO") else None
                lat = row.get("latitud", "").strip()
                lng = row.get("longitud", "").strip()

                conn.execute("""
                    INSERT INTO territorial.ubicacion
                        (location_id, nombre_oficial, comuna, tipo, latitud, longitud)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (location_id) DO UPDATE SET
                        nombre_oficial = EXCLUDED.nombre_oficial,
                        comuna = EXCLUDED.comuna,
                        tipo = EXCLUDED.tipo,
                        latitud = EXCLUDED.latitud,
                        longitud = EXCLUDED.longitud
                """, (
                    lid,
                    row.get("nombre_oficial", "").strip() or None,
                    row.get("comuna", "").strip() or None,
                    tipo,
                    float(lat) if lat else None,
                    float(lng) if lng else None,
                ))
                eta.record(
                    conn,
                    target_table="territorial.ubicacion",
                    target_pk=lid,
                    source_type="canonical",
                    source_file="locality_reference.csv",
                    source_key=lid,
                    phase="F1",
                )
                n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F1-ESTAB-COUNT",
                sql="SELECT COUNT(*) FROM territorial.establecimiento",
                expected=86,
            ),
            PathEquation(
                name="PE-F1-UBIC-COUNT",
                sql="SELECT COUNT(*) FROM territorial.ubicacion",
                expected=1659,
            ),
            PathEquation(
                name="PE-F1-ESTAB-TIPO-VALID",
                sql="""SELECT establecimiento_id FROM territorial.establecimiento
                    WHERE tipo IS NOT NULL
                      AND tipo NOT IN ('hospital','cesfam','cecosf','cec','postas','sapu','sar','cosam','otro')""",
                expected="empty",
            ),
        ]
