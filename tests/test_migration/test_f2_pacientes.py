# tests/test_migration/test_f2_pacientes.py
"""Tests for F2: Pacientes — strict ⊕ canonical -> clinical.paciente."""

import os
import sys
import uuid
from pathlib import Path

import pytest

# Allow direct imports from scripts/migrate_to_pg
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial
from functors.f2_pacientes import F2Pacientes

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


@pytest.fixture(scope="module")
def f2_test_db():
    """Create a dedicated test database for F2 tests, drop on teardown."""
    import psycopg
    db_name = f"hodom_f2_{uuid.uuid4().hex[:8]}"
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
    """Module-scoped MigrationSources for F2 tests."""
    from framework.runner import MigrationSources
    return MigrationSources(
        strict_db=_PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=_PROJECT_ROOT / "documentacion-legacy",
    )


@pytest.fixture(scope="module")
def f2_conn(f2_test_db):
    """Fresh connection for F2 tests."""
    import psycopg
    conn = psycopg.connect(f2_test_db)
    yield conn
    conn.close()


@pytest.fixture(scope="module")
def f2_loaded(f2_conn, sources):
    """Run F0 + F1 + F2 in sequence and return the connection."""
    f0 = F0Bootstrap()
    f0.objects(f2_conn, sources)
    f2_conn.commit()

    f1 = F1Territorial()
    f1.objects(f2_conn, sources)
    f2_conn.commit()

    f2 = F2Pacientes()
    f2.objects(f2_conn, sources)
    f2_conn.commit()

    return f2_conn


class TestF2Pacientes:
    def test_count_matches_strict(self, f2_loaded):
        """F2 must produce exactly 673 patients — one per strict.paciente row."""
        count = f2_loaded.execute("SELECT COUNT(*) FROM clinical.paciente").fetchone()[0]
        assert count == 673

    def test_all_ruts_from_strict(self, f2_loaded):
        """clinical.paciente must contain ONLY RUTs that exist in strict.paciente — no extras."""
        extras = f2_loaded.execute(
            "SELECT rut FROM clinical.paciente WHERE rut NOT IN (SELECT rut FROM strict.paciente)"
        ).fetchall()
        assert extras == [], f"Unexpected extra RUTs in clinical.paciente: {extras[:5]}"

    def test_nombres_preserved_from_strict(self, f2_loaded):
        """strict.nombre is the authoritative name and must never be overwritten by canonical."""
        mismatches = f2_loaded.execute(
            """
            SELECT p.rut, p.nombre_completo, s.nombre
            FROM clinical.paciente p
            JOIN strict.paciente s ON s.rut = p.rut
            WHERE p.nombre_completo != s.nombre
            """
        ).fetchall()
        assert mismatches == [], (
            f"Name overwritten for {len(mismatches)} patient(s): {mismatches[:3]}"
        )

    def test_enrichment_has_sexo(self, f2_loaded):
        """At least some patients should have sexo enriched from canonical patient_master."""
        count = f2_loaded.execute(
            "SELECT COUNT(*) FROM clinical.paciente WHERE sexo IS NOT NULL"
        ).fetchone()[0]
        assert count > 0, "No patients have sexo — canonical enrichment did not apply"

    def test_path_equations_pass(self, f2_loaded):
        """All 4 path equations (PE-F2-*) must pass."""
        f2 = F2Pacientes()
        passed, diags = f2.verify(f2_loaded)
        failures = [d for d in diags if "FAIL" in d]
        assert passed is True, f"Path equations failed:\n" + "\n".join(failures)
