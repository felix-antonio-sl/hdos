"""Tests for enrich_patient_master() in build_hodom_canonical."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_canonical import consolidate_stays, enrich_patient_master


def test_enrich_patients_adds_aggregated_fields(sample_episodes, sample_patients):
    """pt_001 has 1 consolidated stay (2 episodes -> 1 stay),
    so total_hospitalizaciones=1, dates from that stay."""
    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])

    pt_001 = [p for p in enriched if p["patient_id"] == "pt_001"][0]

    assert pt_001["total_hospitalizaciones"] == 1
    assert pt_001["primera_fecha_ingreso"] == "2026-01-15"
    assert pt_001["ultima_fecha_egreso"] == "2026-02-10"
    assert pt_001["estado_actual"] == "egresado"
    # Original fields preserved
    assert pt_001["nombre_completo"] == "JUAN PEREZ SOTO"
    assert pt_001["rut"] == "12345678-5"


def test_enrich_patients_active_state(sample_episodes, sample_patients):
    """pt_002 has a stay without egreso -> estado_actual='activo'."""
    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])

    pt_002 = [p for p in enriched if p["patient_id"] == "pt_002"][0]

    assert pt_002["estado_actual"] == "activo"
    assert pt_002["primera_fecha_ingreso"] == "2026-02-01"
    assert pt_002["ultima_fecha_egreso"] == ""


def test_enrich_patients_with_open_issues(
    sample_episodes, sample_patients, sample_quality_issues
):
    """Pass quality_issues with OPEN issue on ep_003 -> pt_002 has
    tiene_issues_abiertos='True'."""
    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(
        sample_patients, stays, sample_quality_issues
    )

    pt_002 = [p for p in enriched if p["patient_id"] == "pt_002"][0]
    assert pt_002["tiene_issues_abiertos"] == "True"

    # pt_001 also has open issues (qi_001 REVIEW_REQUIRED on ep_001,
    # qi_002 OPEN on ep_002 — both episodes belong to pt_001)
    pt_001 = [p for p in enriched if p["patient_id"] == "pt_001"][0]
    assert pt_001["tiene_issues_abiertos"] == "True"

    # pt_003 has only qi_004 with RESOLVED_AUTO -> no open issues
    pt_003 = [p for p in enriched if p["patient_id"] == "pt_003"][0]
    assert pt_003["tiene_issues_abiertos"] == "False"


def test_enrich_patients_calculates_days(sample_episodes, sample_patients):
    """pt_001's stay: 2026-01-15 to 2026-02-10 = 26 days."""
    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])

    pt_001 = [p for p in enriched if p["patient_id"] == "pt_001"][0]

    assert pt_001["dias_totales_estadia"] == 26
