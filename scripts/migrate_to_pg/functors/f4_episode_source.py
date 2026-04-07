# scripts/migrate_to_pg/functors/f4_episode_source.py
"""
F₄: Episode Source — canonical/episode_source.csv → operational.estadia_episodio_fuente

Pullback over clinical.estadia by stay_id:
  only rows whose stay_id exists in clinical.estadia are admitted.

Source:  canonical/episode_source.csv (3115, trust=0.8)
Target:  operational.estadia_episodio_fuente (stay_id, episode_id, source_origin)

This functor establishes the span:
  episode_id ← estadia_episodio_fuente → stay_id
which F₅ uses to resolve episode-level data to stay-level PG entities.
"""

from __future__ import annotations
import csv
from pathlib import Path

import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]


class F4EpisodeSource(Functor):
    name = "F4_episode_source"
    depends_on = ["F0_bootstrap", "F3_estadias"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM operational.estadia_episodio_fuente WHERE TRUE")

        # Load existing stay_ids from clinical.estadia
        existing_stays = {
            row[0]
            for row in conn.execute("SELECT stay_id FROM clinical.estadia").fetchall()
        }

        # Read episode_source.csv
        path = sources.canonical_dir / "episode_source.csv"
        with open(path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        n = 0
        for row in rows:
            stay_id = row.get("stay_id", "").strip()
            episode_id = row.get("episode_id", "").strip()
            origin_type = row.get("origin_type", "").strip() or None

            if not stay_id or not episode_id:
                continue

            # Pullback: only admit if stay_id exists in clinical.estadia
            if stay_id not in existing_stays:
                continue

            conn.execute(
                """
                INSERT INTO operational.estadia_episodio_fuente
                    (stay_id, episode_id, source_origin)
                VALUES (%s, %s, %s)
                ON CONFLICT (stay_id, episode_id) DO NOTHING
                """,
                (stay_id, episode_id, origin_type),
            )

            eta.record(
                conn,
                target_table="operational.estadia_episodio_fuente",
                target_pk=f"{stay_id}|{episode_id}",
                source_type="canonical",
                source_file="episode_source.csv",
                source_key=f"{stay_id}|{episode_id}",
                phase="F4",
            )

            n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F4-FK-STAY",
                sql="""SELECT eef.stay_id FROM operational.estadia_episodio_fuente eef
                    LEFT JOIN clinical.estadia e ON e.stay_id = eef.stay_id
                    WHERE e.stay_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F4-NO-DUP",
                sql="""SELECT stay_id, episode_id, COUNT(*)
                    FROM operational.estadia_episodio_fuente
                    GROUP BY stay_id, episode_id
                    HAVING COUNT(*) > 1""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F4-NONEMPTY",
                sql="SELECT COUNT(*) FROM operational.estadia_episodio_fuente",
                expected=0,  # Will be overridden after load
                severity="warning",
            ),
        ]

    def glue_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="GLUE-F3-F4-COVERAGE",
                sql="""SELECT e.stay_id FROM clinical.estadia e
                    LEFT JOIN operational.estadia_episodio_fuente eef
                        ON eef.stay_id = e.stay_id
                    WHERE eef.stay_id IS NULL""",
                expected="empty",
                severity="warning",
            ),
        ]
