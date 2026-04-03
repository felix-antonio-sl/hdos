from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_discharges_minimal import (
    apply_identity_run_backfill,
    build_minimal_discharge_rows,
    split_strict_minimal_discharge_rows,
)


def test_build_minimal_discharge_rows_projects_expected_columns() -> None:
    normalized_rows = [
        {
            "discharge_event_id": "alta_001",
            "rut_norm": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre_completo": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-01",
            "fecha_egreso": "2025-10-07",
            "motivo_egreso": "ALTA",
            "diagnostico": "ITU",
            "comuna": "SAN CARLOS",
            "direccion_o_comuna": "MATTA 123",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "7",
        }
    ]

    rows = build_minimal_discharge_rows(normalized_rows)

    assert rows == [
        {
            "egreso_id": "alta_001",
            "run": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-01",
            "fecha_egreso": "2025-10-07",
            "motivo_egreso": "ALTA",
            "diagnostico": "ITU",
            "comuna": "SAN CARLOS",
            "direccion_referencia": "MATTA 123",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "7",
        }
    ]


def test_split_strict_minimal_discharge_rows_separates_rejected_rows() -> None:
    minimal_rows = [
        {
            "egreso_id": "alta_001",
            "run": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-01",
            "fecha_egreso": "2025-10-07",
            "motivo_egreso": "ALTA",
            "diagnostico": "ITU",
            "comuna": "SAN CARLOS",
            "direccion_referencia": "MATTA 123",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "7",
        },
        {
            "egreso_id": "alta_002",
            "run": "",
            "fecha_egreso": "",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "8",
        },
    ]

    rows, rejected = split_strict_minimal_discharge_rows(minimal_rows)

    assert rows == [
        {
            "egreso_id": "alta_001",
            "run": "12345678-5",
            "fecha_egreso": "2025-10-07",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "7",
        }
    ]
    assert rejected == [
        {
            "egreso_id": "alta_002",
            "run": "",
            "rut_raw": "",
            "rut_valido": "",
            "nombre": "",
            "fecha_ingreso": "",
            "fecha_egreso": "",
            "motivo_egreso": "",
            "diagnostico": "",
            "comuna": "",
            "direccion_referencia": "",
            "discard_reason": "missing_fecha_egreso",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "8",
        }
    ]


def test_apply_identity_run_backfill_on_discharges_fills_unique_name_match() -> None:
    rows = [
        {
            "egreso_id": "alta_001",
            "run": "",
            "rut_raw": "",
            "rut_valido": "0",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-01",
            "fecha_egreso": "2025-10-07",
            "motivo_egreso": "ALTA",
            "diagnostico": "ITU",
            "comuna": "SAN CARLOS",
            "direccion_referencia": "MATTA 123",
            "source_file": "PLANILLA DE ALTAS 26.xlsx",
            "source_sheet": "ALTAS 01-07 OCT 2025",
            "source_row_number": "7",
        }
    ]

    resolved = apply_identity_run_backfill(rows, {"ANA PEREZ SOTO": "12345678-5"})

    assert resolved[0]["run"] == "12345678-5"
    assert resolved[0]["rut_valido"] == "1"
