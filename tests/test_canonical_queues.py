"""Tests for build_unified_review_queue, filter_actionable_quality_issues,
and build_duplicate_candidates in build_hodom_canonical."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_canonical import (
    DUPLICATE_CANDIDATE_FIELDS,
    QUALITY_ISSUE_FIELDS,
    REVIEW_QUEUE_FIELDS,
    build_duplicate_candidates,
    build_unified_review_queue,
    consolidate_stays,
    filter_actionable_quality_issues,
)


# ---------------------------------------------------------------------------
# test_build_unified_review_queue
# ---------------------------------------------------------------------------


def test_build_unified_review_queue(
    sample_match_review_queue,
    sample_identity_review,
    sample_discharge_events,
    sample_quality_issues,
):
    """Items from match queue, identity queue, and discharge events all
    appear with the correct queue_type.  Should produce >= 3 items."""
    queue = build_unified_review_queue(
        match_queue=sample_match_review_queue,
        identity_queue=sample_identity_review,
        discharge_events=sample_discharge_events,
        quality_issues=sample_quality_issues,
    )

    assert len(queue) >= 3

    # All rows have the required fields
    for row in queue:
        for field in REVIEW_QUEUE_FIELDS:
            assert field in row, f"Missing field {field}"

    queue_types = {row["queue_type"] for row in queue}

    # We expect at least these three from the fixtures
    assert "unmatched_form" in queue_types
    assert "unresolved_discharge" in queue_types
    assert "identity" in queue_types

    # match_queue item -> unmatched_form with priority=high
    match_items = [r for r in queue if r["queue_type"] == "unmatched_form"]
    assert len(match_items) == 1
    assert match_items[0]["priority"] == "high"
    assert match_items[0]["candidate_ids"] == "ep_002"

    # discharge_events item -> unresolved_discharge with priority=medium
    discharge_items = [r for r in queue if r["queue_type"] == "unresolved_discharge"]
    assert len(discharge_items) == 1
    assert discharge_items[0]["priority"] == "medium"

    # identity item -> identity with priority=low
    identity_items = [r for r in queue if r["queue_type"] == "identity"]
    assert len(identity_items) == 1
    assert identity_items[0]["priority"] == "low"

    # qi_003 (ESTABLISHMENT_UNRESOLVED + OPEN) should also produce an item
    establishment_items = [r for r in queue if r["queue_type"] == "establishment"]
    assert len(establishment_items) == 1
    assert establishment_items[0]["priority"] == "low"


# ---------------------------------------------------------------------------
# test_filter_quality_issues_only_open
# ---------------------------------------------------------------------------


def test_filter_quality_issues_only_open(sample_quality_issues):
    """4 input issues: qi_001 (REVIEW_REQUIRED), qi_002 (OPEN),
    qi_003 (OPEN), qi_004 (RESOLVED_AUTO).
    Only 3 should pass the filter (OPEN + REVIEW_REQUIRED)."""
    filtered = filter_actionable_quality_issues(sample_quality_issues)

    assert len(filtered) == 3

    # All rows have the required fields
    for row in filtered:
        for field in QUALITY_ISSUE_FIELDS:
            assert field in row, f"Missing field {field}"

    # Only OPEN and REVIEW_REQUIRED statuses survive
    statuses = {row["status"] for row in filtered}
    assert statuses <= {"OPEN", "REVIEW_REQUIRED"}

    # Verify the correct issue_ids made it through
    issue_ids = {row["issue_id"] for row in filtered}
    assert issue_ids == {"qi_001", "qi_002", "qi_003"}

    # RESOLVED_AUTO should be excluded
    assert "qi_004" not in issue_ids


# ---------------------------------------------------------------------------
# test_build_duplicate_candidates
# ---------------------------------------------------------------------------


def test_build_duplicate_candidates(sample_episodes, sample_patients):
    """Normal consolidated data from conftest should NOT produce duplicates,
    since each patient has a unique RUT and names are distinct enough."""
    stays = consolidate_stays(sample_episodes)
    duplicates = build_duplicate_candidates(stays, sample_patients)

    assert isinstance(duplicates, list)

    # Verify all rows have the expected fields (even if list is empty)
    for row in duplicates:
        for field in DUPLICATE_CANDIDATE_FIELDS:
            assert field in row, f"Missing field {field}"

    # The conftest patients all have unique RUTs and distinct names,
    # so no duplicates should be detected.
    assert len(duplicates) == 0


def test_build_duplicate_candidates_detects_same_rut_different_patient():
    """Two stays with same RUT but different patient_id and close dates
    should be detected as same_rut_similar_dates duplicates."""
    stays = [
        {
            "stay_id": "stay_aaa",
            "patient_id": "pt_100",
            "rut": "11111111-1",
            "fecha_ingreso": "2026-03-01",
            "fecha_egreso": "2026-03-15",
            "nombre_completo": "JUAN PEREZ SOTO",
            "comuna": "Valdivia",
        },
        {
            "stay_id": "stay_bbb",
            "patient_id": "pt_200",
            "rut": "11111111-1",
            "fecha_ingreso": "2026-03-05",
            "fecha_egreso": "2026-03-20",
            "nombre_completo": "JUAN PEREZ SOTO",
            "comuna": "Valdivia",
        },
    ]
    patients = [
        {
            "patient_id": "pt_100",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "11111111-1",
            "comuna": "Valdivia",
        },
        {
            "patient_id": "pt_200",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "11111111-1",
            "comuna": "Valdivia",
        },
    ]

    duplicates = build_duplicate_candidates(stays, patients)

    assert len(duplicates) >= 1

    # All rows have the expected fields
    for row in duplicates:
        for field in DUPLICATE_CANDIDATE_FIELDS:
            assert field in row, f"Missing field {field}"

    # Check stay-level duplicate was detected
    stay_dups = [d for d in duplicates if d["entity_type"] == "stay"]
    assert len(stay_dups) >= 1
    assert stay_dups[0]["match_reason"] == "same_rut_similar_dates"
    assert stay_dups[0]["confidence"] == "high"
    assert stay_dups[0]["reviewed"] == "False"

    # Check patient-level duplicate (same RUT, different patient_id)
    patient_dups = [d for d in duplicates if d["entity_type"] == "patient"
                    and d["match_reason"] == "same_rut_different_patient"]
    assert len(patient_dups) >= 1
    assert patient_dups[0]["confidence"] == "high"
