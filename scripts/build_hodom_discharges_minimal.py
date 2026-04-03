#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import migrate_hodom_csv as base
from build_hodom_enriched import parse_discharge_workbook


REPO_DIR = Path(__file__).resolve().parents[1]

DEFAULT_SOURCE_PATH = REPO_DIR / "input" / "reference" / "legacy_imports" / "planilla-altas-2024-2026.xlsx"
DEFAULT_SGH_PATH = REPO_DIR / "input" / "reference" / "legacy_imports" / "ingresos-hodom-2024-marzo-2026.txt"
DEFAULT_OUTPUT_PATH = Path("output/spreadsheet/hospitalizaciones/egresos_minimos.csv")
DEFAULT_STRICT_OUTPUT_PATH = Path("output/spreadsheet/hospitalizaciones/egresos_minimos_estrictos.csv")
DEFAULT_REJECTED_OUTPUT_PATH = Path("output/spreadsheet/hospitalizaciones/egresos_minimos_descartados.csv")
DEFAULT_MANUAL_RESOLUTION_PATH = Path("input/manual/discharges_minimal_resolution.csv")
DEFAULT_IDENTITY_MASTER_PATH = Path("output/spreadsheet/canonical/patient_identity_master.csv")

MINIMAL_DISCHARGE_COLUMNS = [
    "egreso_id",
    "run",
    "rut_raw",
    "rut_valido",
    "nombre",
    "fecha_ingreso",
    "fecha_egreso",
    "motivo_egreso",
    "diagnostico",
    "comuna",
    "direccion_referencia",
    "source_file",
    "source_sheet",
    "source_row_number",
]

STRICT_MINIMAL_DISCHARGE_COLUMNS = [
    "egreso_id",
    "run",
    "fecha_egreso",
    "source_file",
    "source_sheet",
    "source_row_number",
]

REJECTED_DISCHARGE_COLUMNS = [
    "egreso_id",
    "run",
    "rut_raw",
    "rut_valido",
    "nombre",
    "fecha_ingreso",
    "fecha_egreso",
    "motivo_egreso",
    "diagnostico",
    "comuna",
    "direccion_referencia",
    "discard_reason",
    "source_file",
    "source_sheet",
    "source_row_number",
]


def parse_sgh_discharges(path: Path) -> list[dict[str, str]]:
    """Parse SGH export file for rows that have a valid fecha_egreso."""
    if not path.exists():
        return []
    import hashlib
    import re

    rows: list[dict[str, str]] = []
    with path.open("r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row_num, row in enumerate(reader, start=2):
            fecha_egreso = base.normalize_whitespace(row.get("F. Egr."))
            if not fecha_egreso or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fecha_egreso):
                continue
            fecha_ingreso = base.normalize_whitespace(row.get("F. Ing."))
            # Descartar si fecha_egreso < fecha_ingreso (dato inconsistente)
            if fecha_ingreso and fecha_egreso < fecha_ingreso:
                continue
            rut_raw = base.normalize_whitespace(row.get("Rut"))
            run = base.normalize_rut(rut_raw)
            nombre = base.normalize_whitespace(row.get("Nombres"))
            diagnostico = base.normalize_whitespace(row.get("Diagnóstico"))
            sgh_id = base.normalize_whitespace(row.get("ID"))
            uid = hashlib.sha256(f"sgh|{sgh_id}|{run}|{fecha_egreso}".encode()).hexdigest()[:16]
            rows.append(
                {
                    "egreso_id": f"sgh_{uid}",
                    "run": run,
                    "rut_raw": rut_raw,
                    "rut_valido": "1" if run else "0",
                    "nombre": nombre,
                    "fecha_ingreso": fecha_ingreso,
                    "fecha_egreso": fecha_egreso,
                    "motivo_egreso": "",
                    "diagnostico": diagnostico,
                    "comuna": "",
                    "direccion_referencia": "",
                    "source_file": path.name,
                    "source_sheet": "SGH",
                    "source_row_number": str(row_num),
                }
            )
    return rows


def merge_sgh_into_discharges(
    altas_rows: list[dict[str, str]],
    sgh_rows: list[dict[str, str]],
) -> tuple[list[dict[str, str]], int]:
    """Merge SGH discharges into altas, deduplicating by run + fecha_egreso +-2 days.

    Altas (planilla) has priority. SGH rows that match an existing alta by
    run + fecha_egreso within 2 days are dropped as duplicates.
    Returns (merged_rows, sgh_added_count).
    """
    from datetime import datetime, timedelta

    # Index altas by run for fast lookup
    altas_by_run: defaultdict[str, list[str]] = defaultdict(list)
    for row in altas_rows:
        run = row.get("run", "")
        fecha = row.get("fecha_egreso", "")
        if run and fecha:
            altas_by_run[run].append(fecha)

    added = 0
    for sgh_row in sgh_rows:
        run = sgh_row.get("run", "")
        fecha_sgh = sgh_row.get("fecha_egreso", "")
        if not fecha_sgh:
            continue

        is_dup = False
        if run and run in altas_by_run:
            try:
                sgh_dt = datetime.fromisoformat(fecha_sgh).date()
            except ValueError:
                continue
            for alta_fecha in altas_by_run[run]:
                try:
                    alta_dt = datetime.fromisoformat(alta_fecha).date()
                except ValueError:
                    continue
                if abs((sgh_dt - alta_dt).days) <= 2:
                    is_dup = True
                    break

        if not is_dup:
            altas_rows.append(sgh_row)
            if run:
                altas_by_run[run].append(fecha_sgh)
            added += 1

    return altas_rows, added


def build_minimal_discharge_rows(normalized_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for row in normalized_rows:
        rows.append(
            {
                "egreso_id": row.get("discharge_event_id", ""),
                "run": row.get("rut_norm", ""),
                "rut_raw": row.get("rut_raw", ""),
                "rut_valido": row.get("rut_valido", ""),
                "nombre": row.get("nombre_completo", ""),
                "fecha_ingreso": row.get("fecha_ingreso", ""),
                "fecha_egreso": row.get("fecha_egreso", ""),
                "motivo_egreso": row.get("motivo_egreso", ""),
                "diagnostico": row.get("diagnostico", ""),
                "comuna": row.get("comuna", ""),
                "direccion_referencia": row.get("direccion_o_comuna", ""),
                "source_file": row.get("source_file", ""),
                "source_sheet": row.get("source_sheet", ""),
                "source_row_number": row.get("source_row_number", ""),
            }
        )
    rows.sort(
        key=lambda row: (
            row["fecha_egreso"],
            row["fecha_ingreso"],
            row["run"],
            row["nombre"],
            row["egreso_id"],
        )
    )
    return rows


def load_identity_run_lookup(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    grouped: defaultdict[str, set[str]] = defaultdict(set)
    for row in rows:
        run = base.normalize_whitespace(row.get("run"))
        if not run:
            continue
        names = [row.get("nombre", ""), *str(row.get("nombre_variantes", "")).split(" | ")]
        for name in names:
            normalized = base.canonical_text(name)
            if normalized:
                grouped[normalized].add(run)

    lookup: dict[str, str] = {}
    for normalized, runs in grouped.items():
        if len(runs) == 1:
            lookup[normalized] = next(iter(runs))
    return lookup


def apply_identity_run_backfill(
    minimal_rows: list[dict[str, str]],
    identity_lookup: dict[str, str],
) -> list[dict[str, str]]:
    resolved_rows: list[dict[str, str]] = []
    for row in minimal_rows:
        updated = dict(row)
        if not updated.get("run"):
            matched_run = identity_lookup.get(base.canonical_text(updated.get("nombre", "")), "")
            if matched_run:
                updated["run"] = matched_run
                updated["rut_valido"] = "1"
        resolved_rows.append(updated)
    return resolved_rows


def load_manual_resolution(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    resolved: dict[str, dict[str, str]] = {}
    for row in rows:
        egreso_id = base.normalize_whitespace(row.get("egreso_id"))
        if egreso_id:
            resolved[egreso_id] = row
    return resolved


def apply_manual_resolution(
    minimal_rows: list[dict[str, str]],
    resolution_by_id: dict[str, dict[str, str]],
) -> list[dict[str, str]]:
    resolved_rows: list[dict[str, str]] = []
    for row in minimal_rows:
        updated = dict(row)
        resolution = resolution_by_id.get(row.get("egreso_id", ""))
        if resolution:
            action = base.normalize_whitespace(resolution.get("action")).lower()
            if action == "set_run":
                run_value = base.normalize_whitespace(resolution.get("run"))
                if run_value:
                    updated["run"] = run_value
                    updated["rut_valido"] = "1"
            elif action == "discard":
                updated["manual_discard"] = "1"
            elif action == "set_fecha_egreso_fix":
                new_date = base.normalize_whitespace(resolution.get("run", ""))
                if new_date:
                    updated["fecha_egreso"] = new_date
            elif action == "force_pair_canon":
                updated["force_pair_canon"] = "1"
        resolved_rows.append(updated)
    return resolved_rows


def write_csv(path: Path, rows: list[dict[str, str]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow({column: row.get(column, "") for column in columns})


def split_strict_minimal_discharge_rows(
    minimal_rows: list[dict[str, str]],
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    accepted: list[dict[str, str]] = []
    rejected: list[dict[str, str]] = []
    for row in minimal_rows:
        if not row.get("fecha_egreso", ""):
            rejected.append(
                {
                    "egreso_id": row.get("egreso_id", ""),
                    "run": row.get("run", ""),
                    "rut_raw": row.get("rut_raw", ""),
                    "rut_valido": row.get("rut_valido", ""),
                    "nombre": row.get("nombre", ""),
                    "fecha_ingreso": row.get("fecha_ingreso", ""),
                    "fecha_egreso": row.get("fecha_egreso", ""),
                    "motivo_egreso": row.get("motivo_egreso", ""),
                    "diagnostico": row.get("diagnostico", ""),
                    "comuna": row.get("comuna", ""),
                    "direccion_referencia": row.get("direccion_referencia", ""),
                    "discard_reason": "missing_fecha_egreso",
                    "source_file": row.get("source_file", ""),
                    "source_sheet": row.get("source_sheet", ""),
                    "source_row_number": row.get("source_row_number", ""),
                }
            )
            continue
        accepted.append(
            {
                "egreso_id": row.get("egreso_id", ""),
                "run": row.get("run", ""),
                "fecha_egreso": row.get("fecha_egreso", ""),
                "source_file": row.get("source_file", ""),
                "source_sheet": row.get("source_sheet", ""),
                "source_row_number": row.get("source_row_number", ""),
            }
        )
    accepted.sort(
        key=lambda row: (
            row["fecha_egreso"],
            row["run"],
            row["egreso_id"],
        )
    )
    rejected.sort(
        key=lambda row: (
            row["source_file"],
            row["source_sheet"],
            row["source_row_number"],
            row["egreso_id"],
        )
    )
    return accepted, rejected


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extrae un maestro mínimo de egresos HODOM desde la planilla de altas."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE_PATH,
        help="Workbook principal de altas HODOM.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help="CSV de salida con columnas mínimas de egreso.",
    )
    parser.add_argument(
        "--strict-output",
        type=Path,
        default=DEFAULT_STRICT_OUTPUT_PATH,
        help="CSV de salida con esquema estricto: id, run validado, fecha_egreso y source.",
    )
    parser.add_argument(
        "--rejected-output",
        type=Path,
        default=DEFAULT_REJECTED_OUTPUT_PATH,
        help="CSV de salida con egresos descartados del esquema estricto y motivo de descarte.",
    )
    parser.add_argument(
        "--sgh-source",
        type=Path,
        default=DEFAULT_SGH_PATH,
        help="Export SGH con egresos históricos (tab-separated).",
    )
    parser.add_argument(
        "--manual-resolution",
        type=Path,
        default=DEFAULT_MANUAL_RESOLUTION_PATH,
        help="CSV opcional con correcciones manuales para egresos mínimos.",
    )
    parser.add_argument(
        "--identity-master",
        type=Path,
        default=DEFAULT_IDENTITY_MASTER_PATH,
        help="Maestro canónico de identidad para backfill seguro de run por nombre.",
    )
    args = parser.parse_args()

    _, normalized_rows = parse_discharge_workbook(args.source)
    minimal_rows = build_minimal_discharge_rows(normalized_rows)

    # Integrar SGH como segunda fuente (prioridad menor que planilla)
    sgh_rows = parse_sgh_discharges(args.sgh_source)
    minimal_rows, sgh_added = merge_sgh_into_discharges(minimal_rows, sgh_rows)
    minimal_rows.sort(
        key=lambda row: (
            row.get("fecha_egreso", ""),
            row.get("fecha_ingreso", ""),
            row.get("run", ""),
            row.get("nombre", ""),
            row.get("egreso_id", ""),
        )
    )

    identity_lookup = load_identity_run_lookup(args.identity_master)
    minimal_rows = apply_identity_run_backfill(minimal_rows, identity_lookup)
    manual_resolution = load_manual_resolution(args.manual_resolution)
    minimal_rows = apply_manual_resolution(minimal_rows, manual_resolution)
    strict_rows, rejected_rows = split_strict_minimal_discharge_rows(
        [row for row in minimal_rows if row.get("manual_discard") != "1"]
    )
    write_csv(args.output, minimal_rows, MINIMAL_DISCHARGE_COLUMNS)
    write_csv(args.strict_output, strict_rows, STRICT_MINIMAL_DISCHARGE_COLUMNS)
    write_csv(args.rejected_output, rejected_rows, REJECTED_DISCHARGE_COLUMNS)

    print(f"source_altas: {args.source}")
    print(f"source_sgh: {args.sgh_source}")
    print(f"sgh_egresos_parsed: {len(sgh_rows)}")
    print(f"sgh_egresos_added: {sgh_added}")
    print(f"sgh_egresos_deduped: {len(sgh_rows) - sgh_added}")
    print(f"output: {args.output}")
    print(f"egresos_minimos: {len(minimal_rows)}")
    print(f"identity_run_backfill_keys: {len(identity_lookup)}")
    print(f"manual_resolution_rows: {len(manual_resolution)}")
    print(f"strict_output: {args.strict_output}")
    print(f"egresos_minimos_estrictos: {len(strict_rows)}")
    print(f"rejected_output: {args.rejected_output}")
    print(f"egresos_minimos_descartados: {len(rejected_rows)}")


if __name__ == "__main__":
    main()
