"""Tests for build_episode_source, build_pipeline_health, build_coverage_gaps."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_canonical import (
    COVERAGE_GAP_FIELDS,
    EPISODE_SOURCE_FIELDS,
    PIPELINE_HEALTH_FIELDS,
    build_coverage_gaps,
    build_episode_source,
    build_pipeline_health,
    consolidate_stays,
)


# ---------------------------------------------------------------------------
# test_build_episode_source
# ---------------------------------------------------------------------------


def test_build_episode_source(sample_episodes):
    """4 episodes -> consolidated into stays -> 4 source rows mapping back."""
    stays = consolidate_stays(sample_episodes)
    sources = build_episode_source(stays, sample_episodes)

    # Every original episode should appear as a source row
    assert len(sources) == 4

    source_ep_ids = {s["episode_id"] for s in sources}
    assert source_ep_ids == {"ep_001", "ep_002", "ep_003", "ep_004"}

    # All rows have the expected fields
    for row in sources:
        for field in EPISODE_SOURCE_FIELDS:
            assert field in row, f"Missing field {field}"

    # origin_type comes from the episode's episode_origin
    by_ep = {s["episode_id"]: s for s in sources}
    assert by_ep["ep_001"]["origin_type"] == "merged"
    assert by_ep["ep_003"]["origin_type"] == "form_rescued"
    assert by_ep["ep_004"]["origin_type"] == "alta_rescued"

    # Each source row references a valid stay_id
    stay_ids = {s["stay_id"] for s in stays}
    for row in sources:
        assert row["stay_id"] in stay_ids

    # source_id is deterministic and starts with "src_"
    for row in sources:
        assert row["source_id"].startswith("src_")


# ---------------------------------------------------------------------------
# test_build_pipeline_health
# ---------------------------------------------------------------------------


def test_build_pipeline_health(sample_episodes, sample_quality_issues):
    """Verify metrics computed correctly and health_status reflects issues."""
    stays = consolidate_stays(sample_episodes)
    coverage_gaps = build_coverage_gaps(stays)
    health = build_pipeline_health(stays, sample_quality_issues, coverage_gaps, 3)

    # Check field presence
    for field in PIPELINE_HEALTH_FIELDS:
        assert field in health, f"Missing field {field}"

    # 3 patients in the fixture
    assert health["patients_total"] == "3"

    # 3 stays (ep_001+ep_002 merged, ep_003, ep_004)
    assert health["stays_total"] == "3"

    # ep_001+ep_002 (merged) has egreso, ep_003 has no egreso, ep_004 has egreso
    assert health["stays_with_egreso"] == "2"
    assert health["stays_with_ingreso"] == "3"

    # Issues: qi_001 (REVIEW_REQUIRED), qi_002 (OPEN), qi_003 (OPEN) are open
    # qi_004 (RESOLVED_AUTO) is not open
    assert health["issues_open"] == "3"
    assert health["issues_review_required"] == "1"

    assert health["source_files_processed"] == "3"

    # health_status: 3 issues / 3 stays = 100% > 15% -> red
    assert health["health_status"] == "red"


# ---------------------------------------------------------------------------
# test_build_coverage_gaps
# ---------------------------------------------------------------------------


def test_build_coverage_gaps():
    """9 months with ~80 stays each, then 1 month with 30 -> gap detected."""
    stays: list[dict[str, str]] = []

    # Months 2025-01 through 2025-09: 80 stays each
    for month_num in range(1, 10):
        month_str = f"2025-{month_num:02d}"
        for day in range(1, 81):
            # Use day modulo 28 + 1 to keep valid-ish dates
            d = (day % 28) + 1
            stays.append({
                "patient_id": f"pt_{month_num:02d}_{day:03d}",
                "fecha_ingreso": f"{month_str}-{d:02d}",
                "fecha_egreso": f"{month_str}-{d:02d}",
                "establecimiento": "Hospital X",
                "source_episode_count": "1",
                "source_episode_ids": f"ep_{month_num:02d}_{day:03d}",
            })

    # Month 2025-10: only 30 stays (well below 70% of 80)
    for day in range(1, 31):
        d = (day % 28) + 1
        stays.append({
            "patient_id": f"pt_10_{day:03d}",
            "fecha_ingreso": f"2025-10-{d:02d}",
            "fecha_egreso": f"2025-10-{d:02d}",
            "establecimiento": "Hospital X",
            "source_episode_count": "1",
            "source_episode_ids": f"ep_10_{day:03d}",
        })

    gaps = build_coverage_gaps(stays)

    # Should have 10 months
    assert len(gaps) == 10

    # All rows have the expected fields
    for row in gaps:
        for field in COVERAGE_GAP_FIELDS:
            assert field in row, f"Missing field {field}"

    # The last month (2025-10) should be flagged
    gap_oct = [g for g in gaps if g["month"] == "2025-10"]
    assert len(gap_oct) == 1
    assert gap_oct[0]["gap_flag"] == "True"
    assert gap_oct[0]["observed"] == "30"

    # Earlier months with full history should NOT be flagged
    # (they are all ~80, which is at or above the moving average)
    for g in gaps:
        if g["month"] != "2025-10" and g["month"] != "2025-01":
            assert g["gap_flag"] == "False", (
                f"Month {g['month']} should not be flagged"
            )


# ---------------------------------------------------------------------------
# test_pipeline_health_status_green
# ---------------------------------------------------------------------------


def test_pipeline_health_status_green():
    """No issues, no gaps -> health_status is green."""
    stays = [
        {
            "patient_id": "pt_001",
            "stay_id": "stay_aaa",
            "fecha_ingreso": "2026-01-15",
            "fecha_egreso": "2026-02-10",
            "establecimiento": "Hospital Base",
            "source_episode_count": "1",
            "source_episode_ids": "ep_001",
        },
        {
            "patient_id": "pt_002",
            "stay_id": "stay_bbb",
            "fecha_ingreso": "2026-02-01",
            "fecha_egreso": "2026-02-28",
            "establecimiento": "CESFAM Norte",
            "source_episode_count": "1",
            "source_episode_ids": "ep_002",
        },
    ]
    quality_issues: list[dict[str, str]] = []
    coverage_gaps: list[dict[str, str]] = []

    health = build_pipeline_health(stays, quality_issues, coverage_gaps, 2)

    assert health["health_status"] == "green"
    assert health["issues_open"] == "0"
    assert health["issues_review_required"] == "0"
    assert health["coverage_gaps_detected"] == "0"
    assert health["patients_total"] == "2"
    assert health["stays_total"] == "2"
