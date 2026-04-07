# tests/test_migration/test_provenance.py
"""Tests for NaturalTransformation (provenance tracking)."""

import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.provenance import NaturalTransformation, ensure_provenance_table


@pytest.fixture
def prov_conn(pg_bootstrapped):
    ensure_provenance_table(pg_bootstrapped)
    pg_bootstrapped.commit()
    yield pg_bootstrapped
    pg_bootstrapped.execute("DELETE FROM migration.provenance")
    pg_bootstrapped.commit()


class TestNaturalTransformation:
    def test_record_row_level(self, prov_conn):
        eta = NaturalTransformation()
        eta.record(prov_conn, target_table="clinical.paciente", target_pk="pt_abc123",
            source_type="strict", source_file="db/hdos.db", source_key="12345678-9", phase="F2")
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT * FROM migration.provenance WHERE target_pk = 'pt_abc123'"
        ).fetchall()
        assert len(rows) == 1

    def test_record_field_level(self, prov_conn):
        eta = NaturalTransformation()
        eta.record(prov_conn, target_table="clinical.paciente", target_pk="pt_abc123",
            source_type="canonical", source_file="patient_master.csv",
            source_key="12345678-9", phase="F2", field_name="sexo")
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT field_name FROM migration.provenance WHERE target_pk = 'pt_abc123'"
        ).fetchall()
        assert rows[0][0] == "sexo"

    def test_idempotent_upsert(self, prov_conn):
        eta = NaturalTransformation()
        for _ in range(3):
            eta.record(prov_conn, target_table="clinical.paciente", target_pk="pt_abc123",
                source_type="strict", source_file="db/hdos.db", source_key="12345678-9", phase="F2")
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT * FROM migration.provenance WHERE target_pk = 'pt_abc123' AND field_name IS NULL"
        ).fetchall()
        assert len(rows) == 1
