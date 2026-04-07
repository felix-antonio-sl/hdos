# tests/test_migration/test_f3_estadias.py
"""Tests for F3: Estadias — strict ⊕ canonical -> clinical.estadia."""

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
from functors.f3_estadias import F3Estadias

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://hodom:hodom@localhost:5555/hodom")


@pytest.fixture(scope="module")
def f3_test_db():
    """Create a dedicated test database for F3 tests, drop on teardown."""
    import psycopg
    db_name = f"hodom_f3_{uuid.uuid4().hex[:8]}"
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
    """Module-scoped MigrationSources for F3 tests."""
    from framework.runner import MigrationSources
    return MigrationSources(
        strict_db=_PROJECT_ROOT / "db" / "hdos.db",
        canonical_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "canonical",
        intermediate_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "intermediate",
        enriched_dir=_PROJECT_ROOT / "output" / "spreadsheet" / "enriched",
        legacy_dir=_PROJECT_ROOT / "documentacion-legacy",
    )


@pytest.fixture(scope="module")
def f3_conn(f3_test_db):
    """Fresh connection for F3 tests."""
    import psycopg
    conn = psycopg.connect(f3_test_db)
    yield conn
    conn.close()


@pytest.fixture(scope="module")
def f3_loaded(f3_conn, sources):
    """Run F0 -> F1 -> F2 -> F3 in sequence and return the connection."""
    f0 = F0Bootstrap()
    f0.objects(f3_conn, sources)
    f3_conn.commit()

    f1 = F1Territorial()
    f1.objects(f3_conn, sources)
    f3_conn.commit()

    f2 = F2Pacientes()
    f2.objects(f3_conn, sources)
    f3_conn.commit()

    f3 = F3Estadias()
    f3.objects(f3_conn, sources)
    f3_conn.commit()

    return f3_conn


class TestF3Estadias:
    def test_count_matches_strict(self, f3_loaded):
        """F3 must load estadias. Count may be less than 838 if the EXCLUDE
        constraint rejects overlapping stays for the same patient.
        The strict source has 838 rows but ~58 overlapping pairs exist."""
        count = f3_loaded.execute("SELECT COUNT(*) FROM clinical.estadia").fetchone()[0]
        strict_count = f3_loaded.execute("SELECT COUNT(*) FROM strict.hospitalizacion").fetchone()[0]
        assert strict_count == 838, f"Strict source should have 838 rows, got {strict_count}"
        # Must load the majority; overlaps are expected losses
        assert count >= 700, f"Too few estadias loaded: {count}"
        assert count <= 838, f"More estadias than strict source: {count}"

    def test_all_estadias_have_patient(self, f3_loaded):
        """Every estadia must reference an existing clinical.paciente — no orphans."""
        orphans = f3_loaded.execute(
            """SELECT e.stay_id FROM clinical.estadia e
               LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
               WHERE p.patient_id IS NULL"""
        ).fetchall()
        assert orphans == [], f"Orphan estadias without patient: {orphans[:5]}"

    def test_fk_triangle_commutes(self, f3_loaded):
        """estadia -> paciente -> rut must match strict.hospitalizacion.rut_paciente.

        This verifies the FK triangle: strict.hospitalizacion --(rut)--> strict.paciente
        must commute with clinical.estadia --(patient_id)--> clinical.paciente --(rut).

        Note: rows with swapped dates (fecha_egreso < fecha_ingreso in strict) get
        their dates corrected, so we also check against h.fecha_egreso as a match
        for e.fecha_ingreso.
        """
        violations = f3_loaded.execute(
            """SELECT e.stay_id, p.rut, e.fecha_ingreso
               FROM clinical.estadia e
               JOIN clinical.paciente p ON p.patient_id = e.patient_id
               WHERE NOT EXISTS (
                   SELECT 1 FROM strict.hospitalizacion h
                   WHERE h.rut_paciente = p.rut
                     AND (h.fecha_ingreso = e.fecha_ingreso
                          OR h.fecha_egreso = e.fecha_ingreso)
               )"""
        ).fetchall()
        assert violations == [], (
            f"FK triangle does not commute for {len(violations)} rows: {violations[:3]}"
        )

    def test_dates_ordered(self, f3_loaded):
        """No estadia should have fecha_egreso < fecha_ingreso."""
        inverted = f3_loaded.execute(
            """SELECT stay_id, fecha_ingreso, fecha_egreso
               FROM clinical.estadia
               WHERE fecha_egreso IS NOT NULL AND fecha_egreso < fecha_ingreso"""
        ).fetchall()
        assert inverted == [], f"Inverted date ranges: {inverted[:5]}"

    def test_enrichment_has_diagnostico(self, f3_loaded):
        """At least some estadias should have diagnostico_principal from canonical enrichment."""
        count = f3_loaded.execute(
            "SELECT COUNT(*) FROM clinical.estadia WHERE diagnostico_principal IS NOT NULL"
        ).fetchone()[0]
        assert count > 0, "No estadias have diagnostico — canonical enrichment did not apply"

    def test_path_equations_pass(self, f3_loaded):
        """All path equations (PE-F3-*) and glue equations (GLUE-F1-F3) must pass.
        PE-F3-COUNT is severity=warning (not critical) due to EXCLUDE constraint
        rejecting overlapping stays."""
        f3 = F3Estadias()
        passed, diags = f3.verify(f3_loaded)
        critical_failures = [d for d in diags if "FAIL" in d and "PE-F3-COUNT" not in d]
        assert passed is True, f"Path equations failed:\n" + "\n".join(critical_failures)
