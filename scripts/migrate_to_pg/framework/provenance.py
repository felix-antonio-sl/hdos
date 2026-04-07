# scripts/migrate_to_pg/framework/provenance.py
"""
Natural Transformation eta: Id_Source => M
Tracks provenance for every migrated object at row-level and field-level.
"""

from __future__ import annotations
import psycopg

_PROVENANCE_DDL = """
CREATE SCHEMA IF NOT EXISTS migration;

CREATE TABLE IF NOT EXISTS migration.provenance (
    target_table  TEXT NOT NULL,
    target_pk     TEXT NOT NULL,
    source_type   TEXT NOT NULL,
    source_file   TEXT NOT NULL,
    source_key    TEXT,
    phase         TEXT NOT NULL,
    field_name    TEXT,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_provenance_key
    ON migration.provenance (target_table, target_pk, phase, COALESCE(field_name, ''));
"""


def ensure_provenance_table(conn: psycopg.Connection) -> None:
    conn.execute(_PROVENANCE_DDL)


class NaturalTransformation:
    def record(self, conn, *, target_table, target_pk, source_type, source_file, source_key=None, phase, field_name=None):
        conn.execute(
            """
            INSERT INTO migration.provenance
                (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (target_table, target_pk, phase, COALESCE(field_name, ''))
            DO UPDATE SET
                source_type = EXCLUDED.source_type,
                source_file = EXCLUDED.source_file,
                source_key  = EXCLUDED.source_key,
                created_at  = NOW()
            """,
            (target_table, target_pk, source_type, source_file, source_key, phase, field_name),
        )

    def record_batch(self, conn, *, rows):
        if not rows:
            return
        with conn.cursor() as cur:
            cur.executemany(
                """
                INSERT INTO migration.provenance
                    (target_table, target_pk, source_type, source_file, source_key, phase, field_name)
                VALUES (%(target_table)s, %(target_pk)s, %(source_type)s, %(source_file)s,
                        %(source_key)s, %(phase)s, %(field_name)s)
                ON CONFLICT (target_table, target_pk, phase, COALESCE(field_name, ''))
                DO UPDATE SET
                    source_type = EXCLUDED.source_type,
                    source_file = EXCLUDED.source_file,
                    source_key  = EXCLUDED.source_key,
                    created_at  = NOW()
                """,
                rows,
            )
