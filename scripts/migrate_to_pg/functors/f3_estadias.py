# scripts/migrate_to_pg/functors/f3_estadias.py
"""
F3: Estadias — strict ⊕ canonical -> clinical.estadia

Source:  strict.hospitalizacion (838, trust=1.0) ⊕ canonical/hospitalization_stay.csv (trust=0.8)
Target:  clinical.estadia (838)

The pushout over the pullback by (rut, fecha_ingreso):
  - strict provides: rut_paciente, fecha_ingreso, fecha_egreso (ALWAYS wins)
  - canonical enriches: stay_id, diagnostico_principal, tipo_egreso, origen_derivacion,
                        establecimiento, confidence_level
"""

from __future__ import annotations
import csv
from datetime import date, timedelta
from pathlib import Path

import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import patient_id_from_rut, make_id
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import patient_id_from_rut, make_id  # type: ignore[no-redef]


_TIPO_EGRESO_MAP = {
    "ALTA": "alta_clinica",
    "ALTA CLINICA": "alta_clinica",
    "REHOSPITALIZACION": "reingreso",
    "REINGRESO": "reingreso",
    "FALLECIMIENTO": "fallecido_esperado",
    "FALLECIDO": "fallecido_esperado",
    "RENUNCIA": "renuncia_voluntaria",
    "RENUNCIA VOLUNTARIA": "renuncia_voluntaria",
    "ALTA DISCIPLINARIA": "alta_disciplinaria",
}

_ORIGEN_MAP = {
    "Urgencia": "urgencia",
    "UE": "urgencia",
    "Hospitalizacion": "hospitalizacion",
    "APS": "APS",
    "Ambulatorio": "ambulatorio",
    "Ley Urgencia": "ley_urgencia",
    "UGCC": "UGCC",
}


def _build_canonical_index(canonical_dir: Path) -> dict[tuple[str, str], dict]:
    """Index canonical stays by (rut, fecha_ingreso) for lookup."""
    index: dict[tuple[str, str], dict] = {}
    path = canonical_dir / "hospitalization_stay.csv"
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rut = row.get("rut", "").strip()
            fi = row.get("fecha_ingreso", "").strip()
            if not rut or not fi:
                continue
            key = (rut, fi)
            existing = index.get(key)
            if existing is None:
                index[key] = row
            else:
                # Prefer higher confidence
                conf_order = {"high": 3, "medium": 2, "low": 1, "": 0}
                if conf_order.get(row.get("confidence_level", ""), 0) > conf_order.get(
                    existing.get("confidence_level", ""), 0
                ):
                    index[key] = row
    return index


def _build_establecimiento_index(conn: psycopg.Connection) -> dict[str, str]:
    """Index territorial.establecimiento by lowercase nombre -> establecimiento_id."""
    rows = conn.execute(
        "SELECT establecimiento_id, nombre FROM territorial.establecimiento"
    ).fetchall()
    return {nombre.strip().lower(): eid for eid, nombre in rows if nombre}


def _lookup_canonical(
    index: dict[tuple[str, str], dict], rut: str, fecha_ingreso: str
) -> dict | None:
    """Look up canonical match by (rut, fecha_ingreso) with +/-1 day tolerance."""
    # Exact match first
    key = (rut, fecha_ingreso)
    if key in index:
        return index[key]

    # Fuzzy: +/-1 day
    try:
        fi_date = date.fromisoformat(fecha_ingreso)
    except (ValueError, TypeError):
        return None

    for delta in (-1, 1):
        alt_date = fi_date + timedelta(days=delta)
        alt_key = (rut, alt_date.isoformat())
        if alt_key in index:
            return index[alt_key]

    return None


class F3Estadias(Functor):
    name = "F3_estadias"
    depends_on = ["F0_bootstrap", "F1_territorial", "F2_pacientes"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency: clean previous
        conn.execute("DELETE FROM clinical.estadia WHERE TRUE")

        # Temporarily disable state-machine triggers for bulk migration.
        # The DDL enforces that new estadias start as 'pendiente_evaluacion'
        # and that estado updates go through evento_estadia. During migration
        # we load historical data with its final estado directly.
        conn.execute("ALTER TABLE clinical.estadia DISABLE TRIGGER trg_estadia_guard_insert")
        conn.execute("ALTER TABLE clinical.estadia DISABLE TRIGGER trg_estadia_guard_estado")

        # Build canonical index and establecimiento lookup
        canonical_index = _build_canonical_index(sources.canonical_dir)
        estab_index = _build_establecimiento_index(conn)

        # Load all strict hospitalizations
        strict_rows = conn.execute(
            "SELECT rut_paciente, fecha_ingreso, fecha_egreso FROM strict.hospitalizacion ORDER BY rut_paciente, fecha_ingreso"
        ).fetchall()

        n = 0
        overlap_concerns: list[str] = []

        for rut, fecha_ingreso, fecha_egreso in strict_rows:
            # Fix inverted dates (data entry error): swap if egreso < ingreso
            if fecha_ingreso and fecha_egreso and fecha_egreso < fecha_ingreso:
                fecha_ingreso, fecha_egreso = fecha_egreso, fecha_ingreso

            fi_str = str(fecha_ingreso) if fecha_ingreso else ""
            fe_str = str(fecha_egreso) if fecha_egreso else ""
            patient_id = patient_id_from_rut(rut)

            # Look up canonical match
            canon = _lookup_canonical(canonical_index, rut, fi_str)

            # Determine stay_id
            if canon:
                stay_id = canon.get("stay_id", "").strip()
                if not stay_id:
                    stay_id = make_id("stay", f"{rut}|{fi_str}|{fe_str or 'NULL'}")
            else:
                stay_id = make_id("stay", f"{rut}|{fi_str}|{fe_str or 'NULL'}")

            # Estado
            estado = "activo" if not fecha_egreso else "egresado"

            # Enrichment from canonical
            diagnostico = None
            tipo_egreso = None
            origen_derivacion = None
            establecimiento_id = None
            confidence_level = None

            if canon:
                diag_raw = canon.get("diagnostico_principal", "").strip()
                diagnostico = diag_raw or None

                motivo_raw = canon.get("motivo_egreso", "").strip().upper()
                tipo_egreso = _TIPO_EGRESO_MAP.get(motivo_raw)

                origen_raw = canon.get("origen_derivacion_rem", "").strip()
                if not origen_raw:
                    origen_raw = canon.get("servicio_origen", "").strip()
                origen_derivacion = _ORIGEN_MAP.get(origen_raw)

                # Establecimiento lookup by name
                estab_nombre = canon.get("establecimiento", "").strip().lower()
                if estab_nombre:
                    establecimiento_id = estab_index.get(estab_nombre)

                confidence_level = canon.get("confidence_level", "").strip() or None

            # Use savepoint so a single ExclusionViolation doesn't abort
            # the entire transaction.
            conn.execute("SAVEPOINT sp_insert")
            try:
                conn.execute(
                    """
                    INSERT INTO clinical.estadia
                        (stay_id, patient_id, establecimiento_id,
                         fecha_ingreso, fecha_egreso, estado,
                         tipo_egreso, origen_derivacion,
                         diagnostico_principal, confidence_level)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (stay_id) DO UPDATE SET
                        fecha_egreso = EXCLUDED.fecha_egreso,
                        estado = EXCLUDED.estado,
                        tipo_egreso = EXCLUDED.tipo_egreso,
                        origen_derivacion = EXCLUDED.origen_derivacion,
                        diagnostico_principal = EXCLUDED.diagnostico_principal,
                        confidence_level = EXCLUDED.confidence_level,
                        updated_at = NOW()
                    """,
                    (
                        stay_id,
                        patient_id,
                        establecimiento_id,
                        fecha_ingreso,
                        fecha_egreso if fecha_egreso else None,
                        estado,
                        tipo_egreso,
                        origen_derivacion,
                        diagnostico,
                        confidence_level,
                    ),
                )
                conn.execute("RELEASE SAVEPOINT sp_insert")
            except psycopg.errors.ExclusionViolation as exc:
                # Overlapping stays for same patient — rollback this row only
                conn.execute("ROLLBACK TO SAVEPOINT sp_insert")
                overlap_concerns.append(
                    f"Overlap for patient {rut}, ingreso={fi_str}: {exc}"
                )
                continue

            # Provenance: row-level from strict
            eta.record(
                conn,
                target_table="clinical.estadia",
                target_pk=stay_id,
                source_type="strict",
                source_file="db/hdos.db",
                source_key=f"{rut}|{fi_str}",
                phase="F3",
            )

            # Provenance: field-level from canonical enrichment
            if canon:
                for fname, fval in {
                    "diagnostico_principal": diagnostico,
                    "tipo_egreso": tipo_egreso,
                    "origen_derivacion": origen_derivacion,
                    "establecimiento_id": establecimiento_id,
                    "confidence_level": confidence_level,
                }.items():
                    if fval is not None:
                        eta.record(
                            conn,
                            target_table="clinical.estadia",
                            target_pk=stay_id,
                            source_type="canonical",
                            source_file="hospitalization_stay.csv",
                            source_key=f"{rut}|{fi_str}",
                            phase="F3",
                            field_name=fname,
                        )

            n += 1

        # Re-enable triggers after bulk load
        conn.execute("ALTER TABLE clinical.estadia ENABLE TRIGGER trg_estadia_guard_insert")
        conn.execute("ALTER TABLE clinical.estadia ENABLE TRIGGER trg_estadia_guard_estado")

        if overlap_concerns:
            # Store concerns for reporting but don't fail
            for i, concern in enumerate(overlap_concerns[:10]):  # limit noise
                eta.record(
                    conn,
                    target_table="clinical.estadia",
                    target_pk=f"OVERLAP_{i}",
                    source_type="concern",
                    source_file="strict.hospitalizacion",
                    source_key=concern[:200],
                    phase="F3",
                    field_name="overlap_warning",
                )

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F3-ANCHOR",
                sql="""SELECT e.stay_id FROM clinical.estadia e
                    JOIN clinical.paciente p ON p.patient_id = e.patient_id
                    WHERE NOT EXISTS (
                        SELECT 1 FROM strict.hospitalizacion h
                        WHERE h.rut_paciente = p.rut
                          AND (h.fecha_ingreso = e.fecha_ingreso
                               OR h.fecha_egreso = e.fecha_ingreso)
                    )""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-NO-ORPHAN",
                sql="""SELECT e.stay_id FROM clinical.estadia e
                    LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
                    WHERE p.patient_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-DATE-ORDER",
                sql="SELECT stay_id FROM clinical.estadia WHERE fecha_egreso IS NOT NULL AND fecha_egreso < fecha_ingreso",
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-COUNT",
                sql="SELECT COUNT(*) FROM clinical.estadia",
                expected=838,
                severity="warning",
            ),
        ]

    def glue_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="GLUE-F1-F3",
                sql="""SELECT e.stay_id FROM clinical.estadia e
                    WHERE e.establecimiento_id IS NOT NULL
                      AND e.establecimiento_id NOT IN (
                        SELECT establecimiento_id FROM territorial.establecimiento
                      )""",
                expected="empty",
            ),
        ]
