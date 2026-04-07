# tests/test_migration/test_f0_bootstrap.py
"""Tests for F0: DDL bootstrap + strict data staging."""

import os
import uuid
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f0_bootstrap import F0Bootstrap

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


@pytest.fixture(scope="module")
def f0_test_db():
    """Create a dedicated test database for F0 (no prior DDL), drop on teardown."""
    import psycopg
    db_name = f"hodom_f0_{uuid.uuid4().hex[:8]}"
    admin = psycopg.connect(_BASE_URL, autocommit=True)
    admin.execute(f"CREATE DATABASE {db_name}")
    admin.close()

    test_url = _BASE_URL.rsplit("/", 1)[0] + f"/{db_name}"
    yield test_url

    admin = psycopg.connect(_BASE_URL, autocommit=True)
    admin.execute(f"""
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = '{db_name}' AND pid <> pg_backend_pid()
    """)
    admin.execute(f"DROP DATABASE {db_name}")
    admin.close()


@pytest.fixture(scope="module")
def sources():
    """Module-scoped MigrationSources for F0 tests."""
    from framework.runner import MigrationSources
    return MigrationSources(
        strict_db=_PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=_PROJECT_ROOT / "documentacion-legacy",
    )


@pytest.fixture(scope="module")
def f0_conn(f0_test_db):
    """Fresh connection for F0 tests (no DDL pre-loaded)."""
    import psycopg
    conn = psycopg.connect(f0_test_db)
    yield conn
    conn.close()


@pytest.fixture(scope="module")
def f0_loaded(f0_conn, sources):
    """Run F0 and return connection."""
    f0 = F0Bootstrap()
    f0.objects(f0_conn, sources)
    f0_conn.commit()
    return f0_conn


class TestF0Bootstrap:
    def test_creates_schemas(self, f0_loaded):
        schemas = [r[0] for r in f0_loaded.execute(
            "SELECT schema_name FROM information_schema.schemata "
            "WHERE schema_name IN ('reference','territorial','clinical','operational','reporting','telemetry','strict','migration')"
        ).fetchall()]
        for expected in ["reference", "territorial", "clinical", "operational", "reporting", "telemetry", "strict", "migration"]:
            assert expected in schemas, f"Schema {expected} not created"

    def test_loads_strict_pacientes(self, f0_loaded):
        count = f0_loaded.execute("SELECT COUNT(*) FROM strict.paciente").fetchone()[0]
        assert count == 673

    def test_loads_strict_hospitalizaciones(self, f0_loaded):
        count = f0_loaded.execute("SELECT COUNT(*) FROM strict.hospitalizacion").fetchone()[0]
        assert count == 838

    def test_path_equations_pass(self, f0_loaded):
        f0 = F0Bootstrap()
        passed, diags = f0.verify(f0_loaded)
        assert passed is True, f"Path equations failed: {diags}"

    def test_reference_seed_data(self, f0_loaded):
        count = f0_loaded.execute("SELECT COUNT(*) FROM reference.prioridad_ref").fetchone()[0]
        assert count >= 7
