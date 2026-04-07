"""Tests for deterministic ID generation — must match existing pipeline."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.hash_ids import stable_id, make_id, patient_id_from_rut


def test_stable_id_deterministic():
    a = stable_id("pt", "rut:12345678-9")
    b = stable_id("pt", "rut:12345678-9")
    assert a == b

def test_stable_id_format():
    result = stable_id("pt", "rut:12345678-9")
    assert result.startswith("pt_")
    hex_part = result.split("_", 1)[1]
    assert len(hex_part) == 16
    int(hex_part, 16)

def test_make_id_deterministic():
    a = make_id("stay", "ep_abc|ep_def")
    b = make_id("stay", "ep_abc|ep_def")
    assert a == b

def test_make_id_format():
    result = make_id("stay", "ep_abc|ep_def")
    assert result.startswith("stay_")
    hex_part = result.split("_", 1)[1]
    assert len(hex_part) == 12
    int(hex_part, 16)

def test_patient_id_from_rut():
    result = patient_id_from_rut("12345678-9")
    expected = stable_id("pt", "rut:12345678-9")
    assert result == expected

def test_patient_id_matches_pipeline():
    import hashlib
    rut = "4038136-8"
    expected_hash = hashlib.sha1(f"rut:{rut}".encode("utf-8")).hexdigest()[:16]
    expected = f"pt_{expected_hash}"
    assert patient_id_from_rut(rut) == expected

def test_different_ruts_different_ids():
    a = patient_id_from_rut("12345678-9")
    b = patient_id_from_rut("98765432-1")
    assert a != b
