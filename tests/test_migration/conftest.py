# tests/test_migration/conftest.py
"""
Fixtures for migration tests.
Requires PostgreSQL running on localhost:5555.
Set HODOM_TEST_DB_URL to override.
"""

import os
import uuid
from pathlib import Path

import psycopg
import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
DDL_PATH = PROJECT_ROOT / "docs" / "models" / "hodom-integrado-pg-v4.sql"
STRICT_DB = PROJECT_ROOT / "db" / "hdos.db"
CANONICAL_DIR = PROJECT_ROOT / "output" / "spreadsheet" / "canonical"
INTERMEDIATE_DIR = PROJECT_ROOT / "output" / "spreadsheet" / "intermediate"
ENRICHED_DIR = PROJECT_ROOT / "output" / "spreadsheet" / "enriched"
LEGACY_DIR = PROJECT_ROOT / "documentacion-legacy"

_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


def _admin_conn():
    """Connection to admin DB for creating/dropping test databases."""
    conn = psycopg.connect(_BASE_URL, autocommit=True)
    return conn


@pytest.fixture(scope="session")
def pg_test_db():
    """Create a temporary test database, yield its URL, drop on teardown."""
    db_name = f"hodom_test_{uuid.uuid4().hex[:8]}"
    admin = _admin_conn()
    admin.execute(f"CREATE DATABASE {db_name}")
    admin.close()

    test_url = _BASE_URL.rsplit("/", 1)[0] + f"/{db_name}"
    yield test_url

    admin = _admin_conn()
    admin.execute(f"""
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = '{db_name}' AND pid <> pg_backend_pid()
    """)
    admin.execute(f"DROP DATABASE {db_name}")
    admin.close()


@pytest.fixture(scope="session")
def pg_conn(pg_test_db):
    """Connection to the test database."""
    conn = psycopg.connect(pg_test_db)
    yield conn
    conn.close()


@pytest.fixture(scope="session")
def pg_bootstrapped(pg_conn):
    """Execute DDL on the test database. Returns connection."""
    ddl = DDL_PATH.read_text(encoding="utf-8")
    pg_conn.execute(ddl)
    pg_conn.commit()
    return pg_conn


@pytest.fixture
def sources():
    """MigrationSources pointing to real project data."""
    from scripts.migrate_to_pg.framework.runner import MigrationSources
    return MigrationSources(
        strict_db=STRICT_DB,
        canonical_dir=CANONICAL_DIR,
        intermediate_dir=INTERMEDIATE_DIR,
        enriched_dir=ENRICHED_DIR,
        legacy_dir=LEGACY_DIR,
    )
