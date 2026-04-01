"""Tests for consolidate_stays() in build_hodom_canonical."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from build_hodom_canonical import consolidate_stays


def test_consolidate_stays_merges_same_patient_same_dates(sample_episodes):
    """ep_001 and ep_002 share patient_id+dates -> 1 stay.
    ep_003 and ep_004 are different -> total 3 stays."""
    stays = consolidate_stays(sample_episodes)
    assert len(stays) == 3

    # Find the consolidated stay (ep_001 + ep_002)
    consolidated = [s for s in stays if s["source_episode_count"] == "2"]
    assert len(consolidated) == 1
    stay = consolidated[0]
    assert "ep_001" in stay["source_episode_ids"]
    assert "ep_002" in stay["source_episode_ids"]
    assert stay["patient_id"] == "pt_001"
    assert stay["fecha_ingreso"] == "2026-01-15"
    assert stay["fecha_egreso"] == "2026-02-10"
    # Both episodes have the same diagnostico -> no " | " join needed
    assert stay["diagnostico_principal"] == "Neumonia adquirida en comunidad"
    assert stay["episode_origin"] == "consolidated"


def test_consolidate_stays_single_episode_not_consolidated(sample_episodes):
    """ep_003 (alone) should have source_episode_count=1 and keep its
    original episode_origin."""
    stays = consolidate_stays(sample_episodes)
    ep003_stays = [
        s for s in stays if "ep_003" in s["source_episode_ids"]
    ]
    assert len(ep003_stays) == 1
    stay = ep003_stays[0]
    assert stay["source_episode_count"] == "1"
    assert stay["episode_origin"] == "form_rescued"


def test_consolidate_stays_confidence_levels(sample_episodes):
    """consolidated stays -> high, form_rescued without egreso -> low,
    alta_rescued with egreso -> medium."""
    stays = consolidate_stays(sample_episodes)

    # Consolidated stay (ep_001 + ep_002) -> high
    consolidated = [s for s in stays if s["source_episode_count"] == "2"]
    assert consolidated[0]["confidence_level"] == "high"

    # form_rescued without egreso -> low
    ep003_stays = [
        s for s in stays if "ep_003" in s["source_episode_ids"]
    ]
    assert ep003_stays[0]["confidence_level"] == "low"

    # alta_rescued with egreso -> medium
    ep004_stays = [
        s for s in stays if "ep_004" in s["source_episode_ids"]
    ]
    assert ep004_stays[0]["confidence_level"] == "medium"
