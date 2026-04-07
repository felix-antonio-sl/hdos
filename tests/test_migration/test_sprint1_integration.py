# tests/test_migration/test_sprint1_integration.py
"""
Integration test: run the full Sprint 1 migration (F0 → F3)
and verify all path equations + glue equations + provenance coverage.
"""

import sys, os, uuid
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.runner import ComposedFunctor, MigrationSources
from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial
from functors.f2_pacientes import F2Pacientes
from functors.f3_estadias import F3Estadias

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


@pytest.fixture(scope="module")
def integration_result():
    """Run full Sprint 1 in a fresh database."""
    import psycopg

    db_name = f"hodom_integ_{uuid.uuid4().hex[:8]}"
    admin = psycopg.connect(_BASE_URL, autocommit=True)
    admin.execute(f"CREATE DATABASE {db_name}")
    admin.close()

    test_url = _BASE_URL.rsplit("/", 1)[0] + f"/{db_name}"
    conn = psycopg.connect(test_url)

    sources = MigrationSources(
        strict_db=PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=PROJECT_ROOT / "documentacion-legacy",
    )

    composed = ComposedFunctor([F0Bootstrap(), F1Territorial(), F2Pacientes(), F3Estadias()])
    report = composed.run(conn, sources)

    yield report, conn

    conn.close()
    admin = psycopg.connect(_BASE_URL, autocommit=True)
    admin.execute(f"""
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity
        WHERE datname = '{db_name}' AND pid <> pg_backend_pid()
    """)
    admin.execute(f"DROP DATABASE {db_name}")
    admin.close()


class TestSprint1Integration:
    def test_all_phases_completed(self, integration_result):
        report, _ = integration_result
        assert len(report.phases) == 4

    def test_all_equations_passed(self, integration_result):
        report, _ = integration_result
        assert report.all_passed is True, report.summary()

    def test_pacientes_count(self, integration_result):
        _, conn = integration_result
        count = conn.execute("SELECT COUNT(*) FROM clinical.paciente").fetchone()[0]
        assert count == 673

    def test_estadias_loaded(self, integration_result):
        """At least 700 of 838 estadias loaded (some rejected by EXCLUDE constraint)."""
        _, conn = integration_result
        count = conn.execute("SELECT COUNT(*) FROM clinical.estadia").fetchone()[0]
        assert count >= 700

    def test_establecimientos_count(self, integration_result):
        _, conn = integration_result
        count = conn.execute("SELECT COUNT(*) FROM territorial.establecimiento").fetchone()[0]
        assert count == 86

    def test_provenance_exists(self, integration_result):
        _, conn = integration_result
        count = conn.execute("SELECT COUNT(*) FROM migration.provenance").fetchone()[0]
        assert count > 0

    def test_provenance_covers_all_patients(self, integration_result):
        _, conn = integration_result
        missing = conn.execute("""
            SELECT p.patient_id FROM clinical.paciente p
            WHERE NOT EXISTS (
                SELECT 1 FROM migration.provenance prov
                WHERE prov.target_table = 'clinical.paciente' AND prov.target_pk = p.patient_id
            )
        """).fetchall()
        assert len(missing) == 0

    def test_provenance_covers_all_estadias(self, integration_result):
        _, conn = integration_result
        missing = conn.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            WHERE NOT EXISTS (
                SELECT 1 FROM migration.provenance prov
                WHERE prov.target_table = 'clinical.estadia' AND prov.target_pk = e.stay_id
            )
        """).fetchall()
        assert len(missing) == 0

    def test_no_orphan_estadias(self, integration_result):
        _, conn = integration_result
        orphans = conn.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
            WHERE p.patient_id IS NULL
        """).fetchall()
        assert len(orphans) == 0

    def test_strict_is_base_of_truth(self, integration_result):
        _, conn = integration_result
        extras = conn.execute("""
            SELECT rut FROM clinical.paciente
            WHERE rut NOT IN (SELECT rut FROM strict.paciente)
        """).fetchall()
        assert len(extras) == 0
