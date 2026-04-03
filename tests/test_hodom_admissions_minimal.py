from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_admissions_minimal import (
    apply_identity_run_backfill,
    build_minimal_admission_rows,
    split_strict_minimal_admission_rows,
)


def test_build_minimal_admission_rows_projects_expected_columns() -> None:
    form_rows = [
        {
            "form_submission_id": "frm_001",
            "rut_norm": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre_completo": "ANA PEREZ SOTO",
            "submission_timestamp": "2025-10-07T12:30:00",
            "source_files": "2025 FORMULARIO HODOM.csv",
            "source_rows": "2025 FORMULARIO HODOM.csv:7",
            "source_authority": "formulario_hodom",
        }
    ]

    rows = build_minimal_admission_rows(form_rows)

    assert rows == [
        {
            "ingreso_id": "frm_001",
            "run": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-07",
            "source_file": "2025 FORMULARIO HODOM.csv",
            "source_row_number": "2025 FORMULARIO HODOM.csv:7",
            "source_authority": "formulario_hodom",
        }
    ]


def test_split_strict_minimal_admission_rows_separates_rejected_rows() -> None:
    minimal_rows = [
        {
            "ingreso_id": "frm_001",
            "run": "12345678-5",
            "rut_raw": "12.345.678-5",
            "rut_valido": "1",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-07",
            "source_file": "2025 FORMULARIO HODOM.csv",
            "source_row_number": "2025 FORMULARIO HODOM.csv:7",
            "source_authority": "formulario_hodom",
        },
        {
            "ingreso_id": "frm_002",
            "run": "",
            "rut_raw": "",
            "rut_valido": "0",
            "nombre": "SIN FECHA",
            "fecha_ingreso": "",
            "source_file": "2025 FORMULARIO HODOM.csv",
            "source_row_number": "2025 FORMULARIO HODOM.csv:8",
            "source_authority": "formulario_hodom",
        },
    ]

    accepted, rejected = split_strict_minimal_admission_rows(minimal_rows)

    assert accepted == [
        {
            "ingreso_id": "frm_001",
            "run": "12345678-5",
            "fecha_ingreso": "2025-10-07",
            "source_file": "2025 FORMULARIO HODOM.csv",
            "source_row_number": "2025 FORMULARIO HODOM.csv:7",
        }
    ]


def test_apply_identity_run_backfill_fills_unique_name_match() -> None:
    rows = [
        {
            "ingreso_id": "frm_001",
            "run": "",
            "rut_raw": "",
            "rut_valido": "0",
            "nombre": "ANA PEREZ SOTO",
            "fecha_ingreso": "2025-10-07",
            "source_file": "f.csv",
            "source_row_number": "f.csv:7",
            "source_authority": "formulario_hodom",
        }
    ]

    resolved = apply_identity_run_backfill(rows, {"ANA PEREZ SOTO": "12345678-5"})

    assert resolved[0]["run"] == "12345678-5"
