from __future__ import annotations

import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

import migrate_hodom_csv as mhc


def write_csv(path: Path, rows: list[list[str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerows(rows)


def write_tsv(path: Path, rows: list[list[str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerows(rows)


def test_detects_sgh_tsv_pattern() -> None:
    rows = [
        ["ID", "SERV", "Rut", "Nombres", "Edad", "F. Ing.", "F. Hosp.", "Sala", "Cama", "F. Egr.", "Diagnóstico", "Tipo"],
        ["280660", "HDOM", "6833972-3", "FLOR MARIA MENDEZ RAMIREZ", "80", "2024-01-10", "", "", "", "", "", ""],
    ]

    spec = mhc.detect_pattern(mhc.DEFAULT_SGH_SOURCE_PATH.name, rows)

    assert spec is not None
    assert spec.name == "sgh_tsv"


def test_reads_sgh_records_with_rut_identity(tmp_path: Path) -> None:
    source_dir = tmp_path / "csv"
    source_dir.mkdir()
    sgh_path = tmp_path / mhc.DEFAULT_SGH_SOURCE_PATH.name
    write_tsv(
        sgh_path,
        [
            ["ID", "SERV", "Rut", "Nombres", "Edad", "F. Ing.", "F. Hosp.", "Sala", "Cama", "F. Egr.", "Diagnóstico", "Tipo"],
            ["280660", "HDOM", "6833972-3", "FLOR MARIA MENDEZ RAMIREZ", "80", "2024-01-10", "", "", "", "", "", ""],
            ["284502", "HDOM", "6803385-3", "JUAN BAUTISTA MORAGA SEPULVEDA", "74", "2024-02-10", "", "", "", "2024-02-12", "J15.9-NEUMONIA BACTERIANA, NO ESPECIFICADA", "DOMICILIO"],
        ],
    )

    records = mhc.read_records(source_dir, sgh_path)

    assert len(records) == 2
    first, second = records

    assert first["source_pattern"] == "sgh_tsv"
    assert first["source_family"] == "SGH"
    assert first["source_row_id"] == "280660"
    assert first["rut"] == "6833972-3"
    assert first["patient_key"] == "rut:6833972-3"
    assert first["patient_key_strategy"] == "rut"
    assert first["estado"] == "ACTIVO"
    assert first["fecha_ingreso_date"] == "2024-01-10"

    assert second["source_row_id"] == "284502"
    assert second["estado"] == "EGRESADO"
    assert second["fecha_egreso_date"] == "2024-02-12"
    assert second["diagnostico_egreso"] == "J15.9-NEUMONIA BACTERIANA, NO ESPECIFICADA"


def test_sgh_record_wins_deduplication_against_manual_csv(tmp_path: Path) -> None:
    source_dir = tmp_path / "csv"
    source_dir.mkdir()

    manual_csv = source_dir / "INGRESOS.csv"
    write_csv(
        manual_csv,
        [
            [f"h{i}" for i in range(26)],
            [
                "ACTIVO",
                "2024-01-10",
                "",
                "",
                "",
                "FLOR MARIA MENDEZ RAMIREZ",
                "F",
                "80",
                "",
                "6833972-3",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
            ],
        ],
    )

    sgh_path = tmp_path / mhc.DEFAULT_SGH_SOURCE_PATH.name
    write_tsv(
        sgh_path,
        [
            ["ID", "SERV", "Rut", "Nombres", "Edad", "F. Ing.", "F. Hosp.", "Sala", "Cama", "F. Egr.", "Diagnóstico", "Tipo"],
            ["280660", "HDOM", "6833972-3", "FLOR MARIA MENDEZ RAMIREZ", "80", "2024-01-10", "", "", "", "", "", ""],
        ],
    )

    raw_records = mhc.read_records(source_dir, sgh_path)
    kept_records, duplicate_rows = mhc.deduplicate_records(raw_records)

    assert len(raw_records) == 2
    assert len(kept_records) == 1
    assert len(duplicate_rows) == 2
    assert kept_records[0]["source_pattern"] == "sgh_tsv"
    assert kept_records[0]["source_file"] == mhc.DEFAULT_SGH_SOURCE_PATH.name
    assert kept_records[0]["duplicate_count"] == "2"


def test_filters_test_patient_records_from_sgh(tmp_path: Path) -> None:
    source_dir = tmp_path / "csv"
    source_dir.mkdir()
    sgh_path = tmp_path / mhc.DEFAULT_SGH_SOURCE_PATH.name
    write_tsv(
        sgh_path,
        [
            ["ID", "SERV", "Rut", "Nombres", "Edad", "F. Ing.", "F. Hosp.", "Sala", "Cama", "F. Egr.", "Diagnóstico", "Tipo"],
            ["333979", "HDOM", "5-1", "PACIENTE PRUEBA PACIENTE PRUEBA. PRUEBA ING.", "46", "2025-04-23", "", "", "", "", "", ""],
            ["280660", "HDOM", "6833972-3", "FLOR MARIA MENDEZ RAMIREZ", "80", "2024-01-10", "", "", "", "", "", ""],
        ],
    )

    records = mhc.read_records(source_dir, sgh_path)

    assert len(records) == 1
    assert records[0]["nombre_completo"] == "FLOR MARIA MENDEZ RAMIREZ"
