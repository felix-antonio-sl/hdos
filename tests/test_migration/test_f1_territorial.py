# tests/test_migration/test_f1_territorial.py
"""Tests for F1: Territorial — establishments + locations."""

import os
import uuid
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


@pytest.fixture(scope="module")
def f1_test_db():
    """Create a dedicated test database for F1, drop on teardown."""
    import psycopg
    db_name = f"hodom_f1_{uuid.uuid4().hex[:8]}"
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
    """Module-scoped MigrationSources for F1 tests."""
    from framework.runner import MigrationSources
    return MigrationSources(
        strict_db=_PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=_PROJECT_ROOT / "documentacion-legacy",
    )


@pytest.fixture(scope="module")
def f1_conn(f1_test_db):
    """Fresh connection for F1 tests."""
    import psycopg
    conn = psycopg.connect(f1_test_db)
    yield conn
    conn.close()


@pytest.fixture(scope="module")
def f1_loaded(f1_conn, sources):
    """Run F0 (dependency) then F1, return connection."""
    f0 = F0Bootstrap()
    f0.objects(f1_conn, sources)
    f1_conn.commit()

    f1 = F1Territorial()
    f1.objects(f1_conn, sources)
    f1_conn.commit()
    return f1_conn


class TestF1Territorial:
    def test_count_establecimientos(self, f1_loaded):
        count = f1_loaded.execute("SELECT COUNT(*) FROM territorial.establecimiento").fetchone()[0]
        assert count == 86

    def test_count_ubicaciones(self, f1_loaded):
        count = f1_loaded.execute("SELECT COUNT(*) FROM territorial.ubicacion").fetchone()[0]
        assert count == 1659

    def test_path_equations_pass(self, f1_loaded):
        f1 = F1Territorial()
        passed, diags = f1.verify(f1_loaded)
        assert passed is True, f"Path equations failed: {diags}"
