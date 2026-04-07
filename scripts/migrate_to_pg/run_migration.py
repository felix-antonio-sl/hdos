#!/usr/bin/env python3
# scripts/migrate_to_pg/run_migration.py
"""
CLI entry point for the categorical migration.

Usage:
  .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url postgresql://user:pass@host/db
  .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url ... --phase F2_pacientes
  .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url ... --dry-run
"""

from __future__ import annotations
import argparse
import sys
from pathlib import Path

import psycopg

# Allow imports from this package
sys.path.insert(0, str(Path(__file__).resolve().parent))

from framework.runner import ComposedFunctor, MigrationSources
from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial
from functors.f2_pacientes import F2Pacientes
from functors.f3_estadias import F3Estadias
from functors.f4_episode_source import F4EpisodeSource
from functors.f5_clinical_enrichment import F5ClinicalEnrichment
from functors.f6_profesionales import F6Profesionales
from functors.f7_visitas import F7Visitas
from functors.f10_kpi_diario import F10KpiDiario

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

ALL_FUNCTORS = [
    F0Bootstrap(),
    F1Territorial(),
    F2Pacientes(),
    F3Estadias(),
    F4EpisodeSource(),
    F5ClinicalEnrichment(),
    F6Profesionales(),
    F7Visitas(),
    F10KpiDiario(),
]

FUNCTOR_MAP = {f.name: f for f in ALL_FUNCTORS}


def main():
    parser = argparse.ArgumentParser(description="HODOM Categorical Migration — Sprint 1")
    parser.add_argument("--db-url", required=True, help="PostgreSQL connection URL")
    parser.add_argument("--phase", help="Run only this phase (e.g., F2_pacientes)")
    parser.add_argument("--dry-run", action="store_true", help="Validate without writing")
    args = parser.parse_args()

    sources = MigrationSources(
        strict_db=PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=PROJECT_ROOT / "documentacion-legacy",
    )

    if args.phase:
        if args.phase not in FUNCTOR_MAP:
            print(f"Unknown phase: {args.phase}")
            print(f"Available: {', '.join(FUNCTOR_MAP)}")
            sys.exit(1)
        phases = [FUNCTOR_MAP[args.phase]]
    else:
        phases = ALL_FUNCTORS

    conn = psycopg.connect(args.db_url)
    composed = ComposedFunctor(phases)
    report = composed.run(conn, sources, dry_run=args.dry_run)
    print(report.summary())
    conn.close()
    sys.exit(0 if report.all_passed else 1)


if __name__ == "__main__":
    main()
