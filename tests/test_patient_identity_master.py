from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_canonical import build_missing_run_review, build_patient_identity_master


def test_identity_master_merges_same_run_despite_name_variants() -> None:
    patients = [
        {
            "patient_id": "pt_001",
            "rut": "5458768-6",
            "fecha_nacimiento_date": "1929-04-01",
            "nombre_completo": "MARIA VALDES MUÑOZ",
            "source_files": "INGRESOS.csv",
        },
        {
            "patient_id": "pt_002",
            "rut": "5458768-6",
            "fecha_nacimiento_date": "1929-04-01",
            "nombre_completo": "MARIA VALDES MUNOZ",
            "source_files": "FORMULARIO.xlsx",
        },
    ]

    rows = build_patient_identity_master(patients)

    assert len(rows) == 1
    row = rows[0]
    assert row["run"] == "5458768-6"
    assert row["fecha_nacimiento"] == "1929-04-01"
    assert row["source_patient_count"] == "2"
    assert "MARIA VALDES MUÑOZ" in row["nombre_variantes"]
    assert "MARIA VALDES MUNOZ" in row["nombre_variantes"]
    assert "run_exact" in row["matching_strategy"]
    assert row["matching_confidence"] == "high"


def test_identity_master_merges_missing_run_on_birthdate_and_fuzzy_name() -> None:
    patients = [
        {
            "patient_id": "pt_010",
            "rut": "7663156-5",
            "fecha_nacimiento_date": "1955-05-21",
            "nombre_completo": "LUIS PINCHEIRA ARIAS",
            "source_files": "SGH.txt",
        },
        {
            "patient_id": "pt_011",
            "rut": "",
            "fecha_nacimiento_date": "1955-05-21",
            "nombre_completo": "LUIS ALFONSO PINCHEIRA ARIAS",
            "source_files": "FORMULARIO.xlsx",
        },
    ]

    rows = build_patient_identity_master(patients)

    assert len(rows) == 1
    row = rows[0]
    assert row["run"] == "7663156-5"
    assert row["fecha_nacimiento"] == "1955-05-21"
    assert row["source_patient_count"] == "2"
    assert "birth_name_fuzzy_to_existing_run" in row["matching_strategy"]
    assert row["matching_confidence"] in {"high", "medium"}


def test_missing_run_review_suggests_candidate_run() -> None:
    identity_rows = [
        {
            "identity_patient_id": "pid_1",
            "run": "7663156-5",
            "fecha_nacimiento": "1955-05-21",
            "nombre": "LUIS PINCHEIRA ARIAS",
            "source_patient_ids": "pt_010",
            "source_files": "SGH.txt",
        },
        {
            "identity_patient_id": "pid_2",
            "run": "",
            "fecha_nacimiento": "1955-05-21",
            "nombre": "LUIS ALFONSO PINCHEIRA ARIAS",
            "source_patient_ids": "pt_011",
            "source_files": "FORMULARIO.xlsx",
        },
    ]

    rows = build_missing_run_review(identity_rows)

    assert len(rows) == 1
    row = rows[0]
    assert row["identity_patient_id"] == "pid_2"
    assert row["candidate_run_1"] == "7663156-5"
    assert row["candidate_name_1"] == "LUIS PINCHEIRA ARIAS"
    assert row["recommendation"] in {"review_high_confidence_birth_name", "review_candidates"}
