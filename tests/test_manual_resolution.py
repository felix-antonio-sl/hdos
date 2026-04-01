"""Tests for read_manual_resolutions, apply_resolutions_to_queue,
and build_canonical_outputs (integration) in build_hodom_canonical."""

from __future__ import annotations

import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_hodom_canonical import (
    apply_resolutions_to_queue,
    build_canonical_outputs,
    read_manual_resolutions,
)
from conftest import write_csv_to_path


# ---------------------------------------------------------------------------
# test_read_manual_resolutions
# ---------------------------------------------------------------------------


def test_read_manual_resolutions(tmp_path):
    """Write a manual_resolution CSV, read it back, verify content."""
    resolutions = [
        {
            "resolution_id": "res_001",
            "queue_type": "unmatched_form",
            "item_id": "mr_001",
            "action": "associate",
            "target_id": "ep_002",
            "field_corrected": "",
            "old_value": "",
            "new_value": "",
            "resolved_by": "admin",
            "resolved_at": "2026-03-30T10:00:00",
            "applied": "False",
        },
    ]
    path = tmp_path / "manual_resolution.csv"
    write_csv_to_path(path, resolutions)

    result = read_manual_resolutions(path)

    assert len(result) == 1
    assert result[0]["resolution_id"] == "res_001"
    assert result[0]["action"] == "associate"
    assert result[0]["item_id"] == "mr_001"
    assert result[0]["resolved_by"] == "admin"


def test_read_manual_resolutions_empty(tmp_path):
    """Non-existent file returns empty list."""
    path = tmp_path / "does_not_exist.csv"
    result = read_manual_resolutions(path)
    assert result == []


# ---------------------------------------------------------------------------
# test_apply_resolutions_to_queue
# ---------------------------------------------------------------------------


def test_apply_resolutions_discard_removes_from_queue():
    """A resolution with action='discard' removes the matching entity_id
    from the review queue."""
    queue = [
        {"queue_item_id": "rq_001", "queue_type": "unmatched_form", "entity_id": "mr_001", "summary": "Form match"},
        {"queue_item_id": "rq_002", "queue_type": "identity", "entity_id": "ir_001", "summary": "Identity issue"},
        {"queue_item_id": "rq_003", "queue_type": "unresolved_discharge", "entity_id": "de_001", "summary": "Discharge"},
    ]
    resolutions = [
        {
            "resolution_id": "res_001",
            "queue_type": "unmatched_form",
            "item_id": "mr_001",
            "action": "discard",
            "target_id": "",
            "applied": "False",
        },
    ]

    result = apply_resolutions_to_queue(queue, resolutions)

    assert len(result) == 2
    entity_ids = {r["entity_id"] for r in result}
    assert "mr_001" not in entity_ids
    assert "ir_001" in entity_ids
    assert "de_001" in entity_ids


def test_apply_resolutions_already_applied_not_removed():
    """A resolution with applied='True' should NOT remove items from the queue."""
    queue = [
        {"queue_item_id": "rq_001", "queue_type": "unmatched_form", "entity_id": "mr_001", "summary": "Form match"},
    ]
    resolutions = [
        {
            "resolution_id": "res_001",
            "queue_type": "unmatched_form",
            "item_id": "mr_001",
            "action": "discard",
            "target_id": "",
            "applied": "True",
        },
    ]

    result = apply_resolutions_to_queue(queue, resolutions)

    assert len(result) == 1
    assert result[0]["entity_id"] == "mr_001"


# ---------------------------------------------------------------------------
# test_canonical_main_produces_all_outputs (integration)
# ---------------------------------------------------------------------------


def test_canonical_main_produces_all_outputs(
    tmp_path,
    sample_episodes,
    sample_patients,
    sample_quality_issues,
    sample_match_review_queue,
    sample_identity_review,
    sample_discharge_events,
):
    """Full integration: build_canonical_outputs reads enriched CSVs and
    produces all 8 canonical output files plus reference copies."""

    enriched_dir = tmp_path / "enriched"
    enriched_dir.mkdir()
    output_dir = tmp_path / "canonical"
    manual_dir = tmp_path / "manual"
    manual_dir.mkdir()

    # Write enriched CSVs with the names expected by build_canonical_outputs
    write_csv_to_path(enriched_dir / "episode_master.csv", sample_episodes)
    write_csv_to_path(enriched_dir / "patient_master.csv", sample_patients)
    write_csv_to_path(enriched_dir / "data_quality_issue.csv", sample_quality_issues)
    write_csv_to_path(enriched_dir / "match_review_queue.csv", sample_match_review_queue)
    write_csv_to_path(enriched_dir / "identity_review_queue.csv", sample_identity_review)
    write_csv_to_path(enriched_dir / "normalized_discharge_event.csv", sample_discharge_events)

    # Reference files that get copied
    write_csv_to_path(
        enriched_dir / "establishment_reference.csv",
        [{"codigo_deis": "113100", "nombre_establecimiento": "CESFAM Dr. Jorge Sabat"}],
    )
    write_csv_to_path(
        enriched_dir / "locality_reference.csv",
        [{"localidad": "Valdivia Urbano", "comuna": "Valdivia"}],
    )

    # Create intermediate dir with raw_source_file.csv (2 rows)
    intermediate_dir = tmp_path / "intermediate"
    intermediate_dir.mkdir()
    write_csv_to_path(
        intermediate_dir / "raw_source_file.csv",
        [
            {"file_id": "f_001", "filename": "ingreso_202601.csv", "row_count": "150"},
            {"file_id": "f_002", "filename": "ingreso_202602.csv", "row_count": "120"},
        ],
    )

    # Run the orchestration
    build_canonical_outputs(enriched_dir, output_dir, manual_dir)

    # Verify all 8 output files exist
    expected_outputs = [
        "hospitalization_stay.csv",
        "patient_master.csv",
        "episode_source.csv",
        "pipeline_health.csv",
        "quality_issue.csv",
        "review_queue.csv",
        "coverage_gap.csv",
        "duplicate_candidate.csv",
    ]
    for filename in expected_outputs:
        output_file = output_dir / filename
        assert output_file.exists(), f"Missing output file: {filename}"

    # Verify reference files were copied
    assert (output_dir / "establishment_reference.csv").exists()
    assert (output_dir / "locality_reference.csv").exists()

    # Verify pipeline_health has content
    with open(output_dir / "pipeline_health.csv", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        health_rows = list(reader)
    assert len(health_rows) == 1
    assert health_rows[0]["source_files_processed"] == "2"

    # Verify hospitalization_stay has stays
    with open(output_dir / "hospitalization_stay.csv", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        stay_rows = list(reader)
    assert len(stay_rows) >= 1
