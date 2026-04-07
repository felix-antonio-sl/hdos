# Migración Categorial Sprint 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el framework categorial y los functores F₀–F₃ para migrar 673 pacientes + 838 estadías estrictas a PostgreSQL v4 con path equations verificadas.

**Architecture:** Framework ligero (Functor, PathEquation, NaturalTransformation) donde cada fase es un functor composable. F₀ bootstraps DDL + strict staging; F₁ carga territorial; F₂ migra pacientes (strict ⊕ canonical); F₃ migra estadías (strict ⊕ canonical). Cada functor verifica sus path equations post-carga — si falla, rollback + halt.

**Tech Stack:** Python 3.14, psycopg ≥3.1, PostgreSQL ≥14, pytest, hashlib (SHA-1/SHA-256)

**Spec:** `docs/superpowers/specs/2026-04-06-migracion-categorial-pg-v4-design.md`

---

## File Structure

```
scripts/migrate_to_pg/
  __init__.py
  run_migration.py              # CLI entry point
  framework/
    __init__.py
    category.py                 # PathEquation, Functor, ComposedFunctor
    provenance.py               # NaturalTransformation → migration_provenance
    hash_ids.py                 # stable_id, make_id, patient_id_from_rut
    runner.py                   # MigrationSources, MigrationReport, run_migration()
  functors/
    __init__.py
    f0_bootstrap.py             # DDL + strict schema + strict data staging
    f1_territorial.py           # canonical → territorial.*
    f2_pacientes.py             # strict ⊕ canonical → clinical.paciente
    f3_estadias.py              # strict ⊕ canonical → clinical.estadia

tests/
  test_migration/
    __init__.py
    conftest.py                 # PG fixtures: temp DB, DDL, sources
    test_hash_ids.py
    test_category.py
    test_f0_bootstrap.py
    test_f1_territorial.py
    test_f2_pacientes.py
    test_f3_estadias.py
    test_sprint1_integration.py
```

---

## Task 1: Setup — Dependencias y Estructura de Directorios

**Files:**
- Create: `scripts/migrate_to_pg/__init__.py`
- Create: `scripts/migrate_to_pg/framework/__init__.py`
- Create: `scripts/migrate_to_pg/functors/__init__.py`
- Create: `tests/test_migration/__init__.py`
- Create: `tests/test_migration/conftest.py`

- [ ] **Step 1: Instalar psycopg**

```bash
.venv/bin/pip install "psycopg[binary]>=3.1"
```

Expected: instalación exitosa. psycopg binary wheel evita compilación contra libpq.

- [ ] **Step 2: Verificar import**

```bash
.venv/bin/python -c "import psycopg; print(psycopg.__version__)"
```

Expected: versión ≥ 3.1

- [ ] **Step 3: Crear estructura de directorios**

```bash
mkdir -p scripts/migrate_to_pg/framework
mkdir -p scripts/migrate_to_pg/functors
mkdir -p tests/test_migration
```

- [ ] **Step 4: Crear __init__.py vacíos**

Crear estos archivos vacíos:
- `scripts/migrate_to_pg/__init__.py`
- `scripts/migrate_to_pg/framework/__init__.py`
- `scripts/migrate_to_pg/functors/__init__.py`
- `tests/test_migration/__init__.py`

- [ ] **Step 5: Crear conftest.py con fixtures PG**

```python
# tests/test_migration/conftest.py
"""
Fixtures for migration tests.
Requires PostgreSQL running on localhost:5432.
Set HODOM_TEST_DB_URL to override (e.g., postgresql://user:pass@host/db).
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

# Default: connect to Docker PG or local PG
_BASE_URL = os.environ.get("HODOM_TEST_DB_URL", "postgresql://postgres:postgres@localhost:5432/postgres")


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
    # Terminate connections to the test DB
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
    # Imported here to avoid circular deps during collection
    from scripts.migrate_to_pg.framework.runner import MigrationSources
    return MigrationSources(
        strict_db=STRICT_DB,
        canonical_dir=CANONICAL_DIR,
        intermediate_dir=INTERMEDIATE_DIR,
        enriched_dir=ENRICHED_DIR,
        legacy_dir=LEGACY_DIR,
    )
```

- [ ] **Step 6: Commit**

```bash
git add scripts/migrate_to_pg/ tests/test_migration/
git commit -m "feat(migration): scaffold project structure + PG test fixtures"
```

---

## Task 2: hash_ids.py — Funciones de Hash Deterministas

**Files:**
- Create: `scripts/migrate_to_pg/framework/hash_ids.py`
- Create: `tests/test_migration/test_hash_ids.py`

- [ ] **Step 1: Write failing tests**

```python
# tests/test_migration/test_hash_ids.py
"""Tests for deterministic ID generation — must match existing pipeline."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.hash_ids import stable_id, make_id, patient_id_from_rut


def test_stable_id_deterministic():
    """Same input always produces same output."""
    a = stable_id("pt", "rut:12345678-9")
    b = stable_id("pt", "rut:12345678-9")
    assert a == b


def test_stable_id_format():
    """stable_id produces prefix + _ + 16 hex chars."""
    result = stable_id("pt", "rut:12345678-9")
    assert result.startswith("pt_")
    hex_part = result.split("_", 1)[1]
    assert len(hex_part) == 16
    int(hex_part, 16)  # must be valid hex


def test_make_id_deterministic():
    """Same input always produces same output."""
    a = make_id("stay", "ep_abc|ep_def")
    b = make_id("stay", "ep_abc|ep_def")
    assert a == b


def test_make_id_format():
    """make_id produces prefix + _ + 12 hex chars."""
    result = make_id("stay", "ep_abc|ep_def")
    assert result.startswith("stay_")
    hex_part = result.split("_", 1)[1]
    assert len(hex_part) == 12
    int(hex_part, 16)  # must be valid hex


def test_patient_id_from_rut():
    """patient_id_from_rut uses stable_id with 'rut:' prefix."""
    result = patient_id_from_rut("12345678-9")
    expected = stable_id("pt", "rut:12345678-9")
    assert result == expected


def test_patient_id_matches_pipeline():
    """Verify our hash matches the pipeline's intermediate stage.

    The pipeline uses:
        stable_id("pt", patient_key) where patient_key = f"rut:{rut}"
    in build_hodom_intermediate.py:234-235.
    """
    import hashlib
    rut = "4038136-8"
    # Pipeline: stable_id("pt", f"rut:{rut}")
    expected_hash = hashlib.sha1(f"rut:{rut}".encode("utf-8")).hexdigest()[:16]
    expected = f"pt_{expected_hash}"
    assert patient_id_from_rut(rut) == expected


def test_different_ruts_different_ids():
    """Different RUTs produce different patient_ids."""
    a = patient_id_from_rut("12345678-9")
    b = patient_id_from_rut("98765432-1")
    assert a != b
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/bin/python -m pytest tests/test_migration/test_hash_ids.py -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'framework'`

- [ ] **Step 3: Implement hash_ids.py**

```python
# scripts/migrate_to_pg/framework/hash_ids.py
"""
Deterministic ID generation — reproduces the pipeline's hash algorithms.

Two hash families coexist in the pipeline:
  stable_id(): SHA-1 truncated to 16 hex (intermediate stage)
  make_id():   SHA-256 truncated to 12 hex (canonical stage)

patient_id uses stable_id (from build_hodom_intermediate.py:208-210).
stay_id uses make_id (from build_hodom_canonical.py:90-93).
"""

import hashlib


def stable_id(prefix: str, *parts: str) -> str:
    """SHA-1, 16 hex chars. Pipeline: build_hodom_intermediate.py:208-210."""
    digest = hashlib.sha1(
        "|".join(str(p) for p in parts).encode("utf-8")
    ).hexdigest()[:16]
    return f"{prefix}_{digest}"


def make_id(prefix: str, value: str) -> str:
    """SHA-256, 12 hex chars. Pipeline: build_hodom_canonical.py:90-93."""
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]
    return f"{prefix}_{digest}"


def patient_id_from_rut(rut: str) -> str:
    """Generate patient_id from RUT. Strategy: 'rut'.

    Matches pipeline: patient_id(patient_key) where patient_key = f"rut:{rut}"
    See build_hodom_intermediate.py:234-235 + migrate_hodom_csv.py:723-726.
    """
    return stable_id("pt", f"rut:{rut}")
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/bin/python -m pytest tests/test_migration/test_hash_ids.py -v
```

Expected: 7 passed

- [ ] **Step 5: Cross-validate against pipeline output**

```bash
.venv/bin/python -c "
import sys; sys.path.insert(0, 'scripts/migrate_to_pg')
from framework.hash_ids import patient_id_from_rut
import csv
# Check first 5 patients from canonical match our generated IDs
with open('output/spreadsheet/canonical/patient_master.csv') as f:
    for i, row in enumerate(csv.DictReader(f)):
        rut = row['rut'].strip()
        if not rut: continue
        generated = patient_id_from_rut(rut)
        canonical = row['patient_id']
        match = '=' if generated == canonical else '!='
        print(f'{rut}: generated={generated} {match} canonical={canonical}')
        if i >= 4: break
"
```

Expected: Si los IDs coinciden, `=` en todas las líneas. Si no coinciden, necesitamos ajustar la función — investigar la diferencia en el hash input.

- [ ] **Step 6: Commit**

```bash
git add scripts/migrate_to_pg/framework/hash_ids.py tests/test_migration/test_hash_ids.py
git commit -m "feat(migration): hash_ids — deterministic ID generation matching pipeline"
```

---

## Task 3: category.py — PathEquation + Functor

**Files:**
- Create: `scripts/migrate_to_pg/framework/category.py`
- Create: `tests/test_migration/test_category.py`

- [ ] **Step 1: Write failing tests**

```python
# tests/test_migration/test_category.py
"""Tests for the categorical framework: PathEquation and Functor."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.category import PathEquation, Functor


class TestPathEquation:
    def test_check_empty_passes(self, pg_bootstrapped):
        """A query returning 0 rows passes when expected='empty'."""
        eq = PathEquation(
            name="PE-TEST-EMPTY",
            sql="SELECT 1 WHERE FALSE",
            expected="empty",
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is True
        assert "PASS" in diag

    def test_check_empty_fails(self, pg_bootstrapped):
        """A query returning rows fails when expected='empty'."""
        eq = PathEquation(
            name="PE-TEST-NOTEMPTY",
            sql="SELECT 1",
            expected="empty",
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is False
        assert "FAIL" in diag
        assert "1 violations" in diag

    def test_check_count_passes(self, pg_bootstrapped):
        """A count query passes when it matches expected."""
        eq = PathEquation(
            name="PE-TEST-COUNT",
            sql="SELECT COUNT(*) FROM (SELECT 1 UNION ALL SELECT 2) t",
            expected=2,
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is True

    def test_check_count_fails(self, pg_bootstrapped):
        """A count query fails when it doesn't match expected."""
        eq = PathEquation(
            name="PE-TEST-BADCOUNT",
            sql="SELECT COUNT(*) FROM (SELECT 1) t",
            expected=99,
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is False
        assert "expected 99" in diag

    def test_warning_severity_does_not_block(self, pg_bootstrapped):
        """Warning equations are tracked but don't block."""
        eq = PathEquation(
            name="PE-TEST-WARN",
            sql="SELECT 1",
            expected="empty",
            severity="warning",
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is False  # still fails
        assert "FAIL" in diag


class TestFunctor:
    def test_verify_all_pass(self, pg_bootstrapped):
        """Verify returns True when all critical equations pass."""

        class F(Functor):
            name = "test_functor"
            depends_on = []

            def objects(self, conn, sources):
                return 0

            def path_equations(self):
                return [
                    PathEquation("PE-1", "SELECT 1 WHERE FALSE", "empty"),
                    PathEquation("PE-2", "SELECT COUNT(*) FROM (SELECT 1) t", 1),
                ]

        f = F()
        passed, diags = f.verify(pg_bootstrapped)
        assert passed is True
        assert len(diags) == 2

    def test_verify_critical_fail_blocks(self, pg_bootstrapped):
        """Verify returns False when a critical equation fails."""

        class F(Functor):
            name = "test_failing"
            depends_on = []

            def objects(self, conn, sources):
                return 0

            def path_equations(self):
                return [
                    PathEquation("PE-OK", "SELECT 1 WHERE FALSE", "empty"),
                    PathEquation("PE-BROKEN", "SELECT 1", "empty", severity="critical"),
                ]

        f = F()
        passed, diags = f.verify(pg_bootstrapped)
        assert passed is False

    def test_verify_warning_does_not_block(self, pg_bootstrapped):
        """Verify returns True when only warnings fail."""

        class F(Functor):
            name = "test_warnings"
            depends_on = []

            def objects(self, conn, sources):
                return 0

            def path_equations(self):
                return [
                    PathEquation("PE-OK", "SELECT 1 WHERE FALSE", "empty"),
                    PathEquation("PE-WARN", "SELECT 1", "empty", severity="warning"),
                ]

        f = F()
        passed, diags = f.verify(pg_bootstrapped)
        assert passed is True  # warnings don't block
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/bin/python -m pytest tests/test_migration/test_category.py -v
```

Expected: FAIL with `ModuleNotFoundError`

- [ ] **Step 3: Implement category.py**

```python
# scripts/migrate_to_pg/framework/category.py
"""
Categorical framework for data migration.

PathEquation: a diagram that must commute — verified as SQL query.
Functor: transforms source objects to target objects, preserving morphisms.
ComposedFunctor: G . F with glue equation verification.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal

import psycopg


@dataclass
class PathEquation:
    """A diagram that must commute.

    The SQL query detects violations:
    - expected="empty": query must return 0 rows (diagram commutes)
    - expected=N: query must return a single row with count = N
    """

    name: str
    sql: str
    expected: int | Literal["empty"]
    severity: Literal["critical", "warning"] = "critical"

    def check(self, conn: psycopg.Connection) -> tuple[bool, str]:
        cur = conn.execute(self.sql)
        rows = cur.fetchall()
        if self.expected == "empty":
            passed = len(rows) == 0
            if passed:
                diag = f"{self.name}: PASS (0 violations)"
            else:
                diag = f"{self.name}: FAIL — {len(rows)} violations"
        else:
            count = rows[0][0] if rows else 0
            passed = count == self.expected
            if passed:
                diag = f"{self.name}: PASS (count={count})"
            else:
                diag = f"{self.name}: FAIL — expected {self.expected}, got {count}"
        return passed, diag


class Functor:
    """Base class for migration functors.

    Each functor:
    - transforms source objects to target objects (objects method)
    - declares path equations that must hold post-load
    - declares glue equations with previously completed functors
    - verify() checks all equations; critical failures halt the migration
    """

    name: str = ""
    depends_on: list[str] = []

    def objects(self, conn: psycopg.Connection, sources: Any) -> int:
        """Execute the transformation. Return count of objects migrated."""
        raise NotImplementedError

    def path_equations(self) -> list[PathEquation]:
        """Path equations internal to this functor."""
        return []

    def glue_equations(self) -> list[PathEquation]:
        """Glue equations with previously completed functors."""
        return []

    def verify(self, conn: psycopg.Connection) -> tuple[bool, list[str]]:
        """Verify all path equations. Returns (all_critical_passed, diagnostics)."""
        all_eqs = self.path_equations() + self.glue_equations()
        diags: list[str] = []
        all_passed = True
        for eq in all_eqs:
            passed, diag = eq.check(conn)
            diags.append(diag)
            if not passed and eq.severity == "critical":
                all_passed = False
        return all_passed, diags
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/bin/python -m pytest tests/test_migration/test_category.py -v
```

Expected: 7 passed (requires PG running — tests skip if PG unavailable)

- [ ] **Step 5: Commit**

```bash
git add scripts/migrate_to_pg/framework/category.py tests/test_migration/test_category.py
git commit -m "feat(migration): category.py — PathEquation + Functor base classes"
```

---

## Task 4: provenance.py + runner.py — Natural Transformation + Orchestration

**Files:**
- Create: `scripts/migrate_to_pg/framework/provenance.py`
- Create: `scripts/migrate_to_pg/framework/runner.py`
- Create: `tests/test_migration/test_provenance.py`

- [ ] **Step 1: Write failing tests for provenance**

```python
# tests/test_migration/test_provenance.py
"""Tests for NaturalTransformation (provenance tracking)."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.provenance import NaturalTransformation, ensure_provenance_table

PROV_DDL = """
CREATE SCHEMA IF NOT EXISTS migration;
"""


@pytest.fixture
def prov_conn(pg_bootstrapped):
    """Connection with provenance table created."""
    ensure_provenance_table(pg_bootstrapped)
    pg_bootstrapped.commit()
    yield pg_bootstrapped
    # Cleanup provenance between tests
    pg_bootstrapped.execute("DELETE FROM migration.provenance")
    pg_bootstrapped.commit()


class TestNaturalTransformation:
    def test_record_row_level(self, prov_conn):
        eta = NaturalTransformation()
        eta.record(
            prov_conn,
            target_table="clinical.paciente",
            target_pk="pt_abc123",
            source_type="strict",
            source_file="db/hdos.db",
            source_key="12345678-9",
            phase="F2",
        )
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT * FROM migration.provenance WHERE target_pk = 'pt_abc123'"
        ).fetchall()
        assert len(rows) == 1

    def test_record_field_level(self, prov_conn):
        eta = NaturalTransformation()
        eta.record(
            prov_conn,
            target_table="clinical.paciente",
            target_pk="pt_abc123",
            source_type="canonical",
            source_file="patient_master.csv",
            source_key="12345678-9",
            phase="F2",
            field_name="sexo",
        )
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT field_name FROM migration.provenance WHERE target_pk = 'pt_abc123'"
        ).fetchall()
        assert rows[0][0] == "sexo"

    def test_idempotent_upsert(self, prov_conn):
        eta = NaturalTransformation()
        for _ in range(3):
            eta.record(
                prov_conn,
                target_table="clinical.paciente",
                target_pk="pt_abc123",
                source_type="strict",
                source_file="db/hdos.db",
                source_key="12345678-9",
                phase="F2",
            )
        prov_conn.commit()
        rows = prov_conn.execute(
            "SELECT * FROM migration.provenance WHERE target_pk = 'pt_abc123' AND field_name IS NULL"
        ).fetchall()
        assert len(rows) == 1
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/bin/python -m pytest tests/test_migration/test_provenance.py -v
```

Expected: FAIL

- [ ] **Step 3: Implement provenance.py**

```python
# scripts/migrate_to_pg/framework/provenance.py
"""
Natural Transformation eta: Id_Source => M

Tracks provenance for every migrated object at row-level and field-level.
Table: migration.provenance
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

-- Unique constraint for idempotent upserts
CREATE UNIQUE INDEX IF NOT EXISTS uq_provenance_key
    ON migration.provenance (target_table, target_pk, phase, COALESCE(field_name, ''));
"""


def ensure_provenance_table(conn: psycopg.Connection) -> None:
    """Create migration.provenance if it doesn't exist."""
    conn.execute(_PROVENANCE_DDL)


class NaturalTransformation:
    """eta: records the origin of each migrated object."""

    def record(
        self,
        conn: psycopg.Connection,
        *,
        target_table: str,
        target_pk: str,
        source_type: str,
        source_file: str,
        source_key: str | None = None,
        phase: str,
        field_name: str | None = None,
    ) -> None:
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

    def record_batch(
        self,
        conn: psycopg.Connection,
        *,
        rows: list[dict],
    ) -> None:
        """Batch insert provenance records."""
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
```

- [ ] **Step 4: Implement runner.py**

```python
# scripts/migrate_to_pg/framework/runner.py
"""
Migration orchestrator — composes functors topologically and executes.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

import psycopg

from .category import Functor
from .provenance import NaturalTransformation, ensure_provenance_table


@dataclass
class MigrationSources:
    """Paths to all data sources."""

    strict_db: Path
    canonical_dir: Path
    intermediate_dir: Path
    enriched_dir: Path
    legacy_dir: Path

    def trust_level(self, source_type: str) -> float:
        return {
            "strict": 1.0,
            "canonical": 0.8,
            "intermediate": 0.6,
            "legacy": 0.4,
        }[source_type]


@dataclass
class PhaseReport:
    functor: str
    objects_migrated: int
    provenance_records: int
    equations_checked: int
    equations_passed: int
    violations: list[str]
    elapsed_seconds: float


@dataclass
class MigrationReport:
    phases: list[PhaseReport] = field(default_factory=list)
    total_objects: int = 0
    total_equations: int = 0
    all_passed: bool = True
    halted_at: str | None = None

    def summary(self) -> str:
        status = "ALL PASSED" if self.all_passed else f"HALTED at {self.halted_at}"
        lines = [
            f"Migration Report: {len(self.phases)} phases, "
            f"{self.total_objects} objects, "
            f"{self.total_equations} equations, {status}",
            "",
        ]
        for pr in self.phases:
            eqs = f"{pr.equations_passed}/{pr.equations_checked}"
            status = "OK" if not pr.violations else "FAIL"
            lines.append(
                f"  {pr.functor}: {pr.objects_migrated} objects, "
                f"{eqs} equations, {pr.elapsed_seconds:.1f}s [{status}]"
            )
            for v in pr.violations:
                lines.append(f"    ! {v}")
        return "\n".join(lines)


class ComposedFunctor:
    """G . F — composition with glue equation verification.

    Executes functors in order. Each phase is a transaction.
    If a critical path equation fails, ROLLBACK + HALT.
    """

    def __init__(self, phases: list[Functor]) -> None:
        self.phases = phases

    def run(
        self,
        conn: psycopg.Connection,
        sources: MigrationSources,
        *,
        dry_run: bool = False,
    ) -> MigrationReport:
        ensure_provenance_table(conn)
        conn.commit()

        report = MigrationReport()
        completed: set[str] = set()

        for functor in self.phases:
            # Check dependencies
            for dep in functor.depends_on:
                if dep not in completed:
                    report.halted_at = functor.name
                    report.all_passed = False
                    return report

            t0 = time.monotonic()

            if dry_run:
                pr = PhaseReport(
                    functor=functor.name,
                    objects_migrated=0,
                    provenance_records=0,
                    equations_checked=0,
                    equations_passed=0,
                    violations=["DRY RUN — skipped"],
                    elapsed_seconds=0.0,
                )
                report.phases.append(pr)
                completed.add(functor.name)
                continue

            try:
                n_objects = functor.objects(conn, sources)
                passed, diags = functor.verify(conn)

                violations = [d for d in diags if "FAIL" in d]
                n_passed = sum(1 for d in diags if "PASS" in d)

                pr = PhaseReport(
                    functor=functor.name,
                    objects_migrated=n_objects,
                    provenance_records=0,  # counted by provenance layer
                    equations_checked=len(diags),
                    equations_passed=n_passed,
                    violations=violations,
                    elapsed_seconds=time.monotonic() - t0,
                )

                if not passed:
                    conn.rollback()
                    report.phases.append(pr)
                    report.halted_at = functor.name
                    report.all_passed = False
                    break

                conn.commit()
                report.phases.append(pr)
                report.total_objects += n_objects
                report.total_equations += len(diags)
                completed.add(functor.name)

            except Exception as exc:
                conn.rollback()
                pr = PhaseReport(
                    functor=functor.name,
                    objects_migrated=0,
                    provenance_records=0,
                    equations_checked=0,
                    equations_passed=0,
                    violations=[f"EXCEPTION: {exc}"],
                    elapsed_seconds=time.monotonic() - t0,
                )
                report.phases.append(pr)
                report.halted_at = functor.name
                report.all_passed = False
                break

        return report
```

- [ ] **Step 5: Run tests**

```bash
.venv/bin/python -m pytest tests/test_migration/test_provenance.py -v
```

Expected: 3 passed

- [ ] **Step 6: Commit**

```bash
git add scripts/migrate_to_pg/framework/provenance.py scripts/migrate_to_pg/framework/runner.py tests/test_migration/test_provenance.py
git commit -m "feat(migration): provenance + runner — NaturalTransformation + ComposedFunctor"
```

---

## Task 5: F₀ Bootstrap — DDL + Strict Staging

**Files:**
- Create: `scripts/migrate_to_pg/functors/f0_bootstrap.py`
- Create: `tests/test_migration/test_f0_bootstrap.py`

- [ ] **Step 1: Write failing test**

```python
# tests/test_migration/test_f0_bootstrap.py
"""Tests for F0: DDL bootstrap + strict data staging."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f0_bootstrap import F0Bootstrap


@pytest.fixture
def f0_conn(pg_test_db):
    """Fresh connection for F0 tests (no DDL pre-loaded)."""
    import psycopg
    conn = psycopg.connect(pg_test_db)
    yield conn
    conn.close()


class TestF0Bootstrap:
    def test_creates_schemas(self, f0_conn, sources):
        f0 = F0Bootstrap()
        f0.objects(f0_conn, sources)
        f0_conn.commit()

        schemas = [
            r[0]
            for r in f0_conn.execute(
                "SELECT schema_name FROM information_schema.schemata "
                "WHERE schema_name IN ('reference','territorial','clinical','operational','reporting','telemetry','strict','migration')"
            ).fetchall()
        ]
        for expected in ["reference", "territorial", "clinical", "operational", "reporting", "telemetry", "strict", "migration"]:
            assert expected in schemas, f"Schema {expected} not created"

    def test_loads_strict_pacientes(self, f0_conn, sources):
        f0 = F0Bootstrap()
        f0.objects(f0_conn, sources)
        f0_conn.commit()

        count = f0_conn.execute("SELECT COUNT(*) FROM strict.paciente").fetchone()[0]
        assert count == 673

    def test_loads_strict_hospitalizaciones(self, f0_conn, sources):
        f0 = F0Bootstrap()
        f0.objects(f0_conn, sources)
        f0_conn.commit()

        count = f0_conn.execute("SELECT COUNT(*) FROM strict.hospitalizacion").fetchone()[0]
        assert count == 838

    def test_path_equations_pass(self, f0_conn, sources):
        f0 = F0Bootstrap()
        f0.objects(f0_conn, sources)
        f0_conn.commit()

        passed, diags = f0.verify(f0_conn)
        assert passed is True, f"Path equations failed: {diags}"

    def test_reference_seed_data(self, f0_conn, sources):
        """Reference tables have seed data from DDL."""
        f0 = F0Bootstrap()
        f0.objects(f0_conn, sources)
        f0_conn.commit()

        count = f0_conn.execute("SELECT COUNT(*) FROM reference.prioridad_ref").fetchone()[0]
        assert count >= 7  # 7 prioridades seeded in DDL
```

- [ ] **Step 2: Run to verify failure**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f0_bootstrap.py -v
```

Expected: FAIL

- [ ] **Step 3: Implement f0_bootstrap.py**

```python
# scripts/migrate_to_pg/functors/f0_bootstrap.py
"""
F0: Bootstrap — DDL execution + strict data staging.

Source:  {} (empty — DDL is the source)
Target:  PG_v4 (100 tables + strict schema + migration schema)

This functor:
1. Executes the full DDL (hodom-integrado-pg-v4.sql)
2. Creates strict.paciente + strict.hospitalizacion
3. Loads 673 patients + 838 hospitalizations from db/hdos.db
4. Creates migration.provenance table
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

import psycopg

from ..framework.category import Functor, PathEquation
from ..framework.provenance import ensure_provenance_table


_STRICT_DDL = """
CREATE SCHEMA IF NOT EXISTS strict;

CREATE TABLE IF NOT EXISTS strict.paciente (
    rut              TEXT PRIMARY KEY,
    nombre           TEXT NOT NULL,
    fecha_nacimiento DATE
);

CREATE TABLE IF NOT EXISTS strict.hospitalizacion (
    id               SERIAL PRIMARY KEY,
    rut_paciente     TEXT NOT NULL REFERENCES strict.paciente(rut),
    fecha_ingreso    DATE NOT NULL,
    fecha_egreso     DATE
);

CREATE INDEX IF NOT EXISTS idx_strict_hosp_rut
    ON strict.hospitalizacion(rut_paciente);
CREATE INDEX IF NOT EXISTS idx_strict_hosp_fechas
    ON strict.hospitalizacion(fecha_ingreso, fecha_egreso);
"""


class F0Bootstrap(Functor):
    name = "F0_bootstrap"
    depends_on = []

    def objects(self, conn: psycopg.Connection, sources) -> int:
        ddl_path = Path(sources.strict_db).resolve().parent.parent / "docs" / "models" / "hodom-integrado-pg-v4.sql"
        ddl = ddl_path.read_text(encoding="utf-8")
        conn.execute(ddl)

        conn.execute(_STRICT_DDL)
        ensure_provenance_table(conn)

        # Load strict data from SQLite
        sqlite_conn = sqlite3.connect(sources.strict_db)
        sqlite_conn.row_factory = sqlite3.Row

        # Patients
        patients = sqlite_conn.execute("SELECT rut, nombre, fecha_nacimiento FROM paciente").fetchall()
        for p in patients:
            conn.execute(
                "INSERT INTO strict.paciente (rut, nombre, fecha_nacimiento) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                (p["rut"], p["nombre"], p["fecha_nacimiento"]),
            )

        # Hospitalizations
        hosps = sqlite_conn.execute(
            "SELECT rut_paciente, fecha_ingreso, fecha_egreso FROM hospitalizacion"
        ).fetchall()
        for h in hosps:
            conn.execute(
                "INSERT INTO strict.hospitalizacion (rut_paciente, fecha_ingreso, fecha_egreso) VALUES (%s, %s, %s)",
                (h["rut_paciente"], h["fecha_ingreso"], h["fecha_egreso"]),
            )

        sqlite_conn.close()
        return len(patients) + len(hosps)

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F0-STRICT-PAC-COUNT",
                sql="SELECT COUNT(*) FROM strict.paciente",
                expected=673,
            ),
            PathEquation(
                name="PE-F0-STRICT-HOSP-COUNT",
                sql="SELECT COUNT(*) FROM strict.hospitalizacion",
                expected=838,
            ),
            PathEquation(
                name="PE-F0-STRICT-NO-ORPHAN",
                sql="""
                    SELECT h.id FROM strict.hospitalizacion h
                    LEFT JOIN strict.paciente p ON p.rut = h.rut_paciente
                    WHERE p.rut IS NULL
                """,
                expected="empty",
            ),
            PathEquation(
                name="PE-F0-DDL-SCHEMAS",
                sql="""
                    SELECT s.expected FROM (
                        VALUES ('reference'),('territorial'),('clinical'),
                               ('operational'),('reporting'),('telemetry')
                    ) AS s(expected)
                    WHERE s.expected NOT IN (
                        SELECT schema_name FROM information_schema.schemata
                    )
                """,
                expected="empty",
            ),
        ]
```

- [ ] **Step 4: Run tests**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f0_bootstrap.py -v
```

Expected: 5 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/migrate_to_pg/functors/f0_bootstrap.py tests/test_migration/test_f0_bootstrap.py
git commit -m "feat(migration): F0 bootstrap — DDL + strict staging + provenance table"
```

---

## Task 6: F₁ Territorial — Establecimientos + Ubicaciones

**Files:**
- Create: `scripts/migrate_to_pg/functors/f1_territorial.py`
- Create: `tests/test_migration/test_f1_territorial.py`

- [ ] **Step 1: Write failing test**

```python
# tests/test_migration/test_f1_territorial.py
"""Tests for F1: territorial — establecimientos + ubicaciones."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial


@pytest.fixture(scope="module")
def f1_conn(pg_test_db):
    """Connection with F0 + F1 applied."""
    import psycopg
    conn = psycopg.connect(pg_test_db)
    # Re-create from scratch for this module
    conn.execute("DROP SCHEMA IF EXISTS strict CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS migration CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS reference CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS territorial CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS clinical CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS operational CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS reporting CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS telemetry CASCADE")
    conn.commit()

    from framework.runner import MigrationSources
    sources = MigrationSources(
        strict_db=Path(__file__).resolve().parent.parent.parent / "db" / "hdos.db",
        canonical_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "canonical",
        intermediate_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "intermediate",
        enriched_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "enriched",
        legacy_dir=Path(__file__).resolve().parent.parent.parent / "documentacion-legacy",
    )
    F0Bootstrap().objects(conn, sources)
    conn.commit()
    F1Territorial().objects(conn, sources)
    conn.commit()
    yield conn
    conn.close()


class TestF1Territorial:
    def test_establecimientos_count(self, f1_conn):
        count = f1_conn.execute("SELECT COUNT(*) FROM territorial.establecimiento").fetchone()[0]
        assert count == 86

    def test_ubicaciones_count(self, f1_conn):
        count = f1_conn.execute("SELECT COUNT(*) FROM territorial.ubicacion").fetchone()[0]
        assert count == 1660

    def test_path_equations_pass(self, f1_conn):
        f1 = F1Territorial()
        passed, diags = f1.verify(f1_conn)
        assert passed is True, f"Path equations failed: {diags}"
```

- [ ] **Step 2: Run to verify failure**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f1_territorial.py -v
```

- [ ] **Step 3: Implement f1_territorial.py**

```python
# scripts/migrate_to_pg/functors/f1_territorial.py
"""
F1: Territorial — establishments + locations.

Source:  canonical/establishment_reference.csv, canonical/locality_reference.csv
Target:  territorial.establecimiento (86), territorial.ubicacion (1660)

Functor F1: CSV_canonical -> PG_v4.territorial
"""

from __future__ import annotations

import csv

import psycopg

from ..framework.category import Functor, PathEquation
from ..framework.provenance import NaturalTransformation

# Map CSV tipo_establecimiento -> DDL CHECK enum
_TIPO_MAP = {
    "Hospital": "hospital",
    "CESFAM": "cesfam",
    "CECOSF": "cecosf",
    "Posta de Salud Rural": "postas",
    "CGR": "otro",
    "SAPU": "sapu",
    "SAR": "sar",
    "COSAM": "cosam",
}


class F1Territorial(Functor):
    name = "F1_territorial"
    depends_on = ["F0_bootstrap"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()
        n = 0

        # -- Establecimientos --
        estab_path = sources.canonical_dir / "establishment_reference.csv"
        with open(estab_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                eid = row["establishment_id"].strip()
                tipo_raw = row.get("tipo_establecimiento", "").strip()
                tipo = _TIPO_MAP.get(tipo_raw)

                via = row.get("via", "").strip()
                numero = row.get("numero", "").strip()
                direccion = f"{via} {numero}".strip() if via else row.get("direccion", "").strip()

                conn.execute(
                    """
                    INSERT INTO territorial.establecimiento
                        (establecimiento_id, nombre, tipo, comuna, direccion, servicio_salud)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (establecimiento_id) DO UPDATE SET
                        nombre = EXCLUDED.nombre,
                        tipo = EXCLUDED.tipo,
                        comuna = EXCLUDED.comuna,
                        direccion = EXCLUDED.direccion,
                        servicio_salud = EXCLUDED.servicio_salud
                    """,
                    (
                        eid,
                        row.get("nombre_oficial", "").strip(),
                        tipo,
                        row.get("comuna", "").strip(),
                        direccion,
                        row.get("servicio_salud", "").strip() or None,
                    ),
                )
                eta.record(
                    conn,
                    target_table="territorial.establecimiento",
                    target_pk=eid,
                    source_type="canonical",
                    source_file="establishment_reference.csv",
                    source_key=eid,
                    phase="F1",
                )
                n += 1

        # -- Ubicaciones --
        loc_path = sources.canonical_dir / "locality_reference.csv"
        with open(loc_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                lid = row["locality_id"].strip()
                tt = row.get("territory_type", "").strip().upper()
                tipo = tt if tt in ("URBANO", "PERIURBANO", "RURAL", "RURAL_AISLADO") else None

                lat = row.get("latitud", "").strip()
                lng = row.get("longitud", "").strip()

                conn.execute(
                    """
                    INSERT INTO territorial.ubicacion
                        (location_id, nombre_oficial, comuna, tipo, latitud, longitud)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (location_id) DO UPDATE SET
                        nombre_oficial = EXCLUDED.nombre_oficial,
                        comuna = EXCLUDED.comuna,
                        tipo = EXCLUDED.tipo,
                        latitud = EXCLUDED.latitud,
                        longitud = EXCLUDED.longitud
                    """,
                    (
                        lid,
                        row.get("nombre_oficial", "").strip(),
                        row.get("comuna", "").strip() or None,
                        tipo,
                        float(lat) if lat else None,
                        float(lng) if lng else None,
                    ),
                )
                eta.record(
                    conn,
                    target_table="territorial.ubicacion",
                    target_pk=lid,
                    source_type="canonical",
                    source_file="locality_reference.csv",
                    source_key=lid,
                    phase="F1",
                )
                n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F1-ESTAB-COUNT",
                sql="SELECT COUNT(*) FROM territorial.establecimiento",
                expected=86,
            ),
            PathEquation(
                name="PE-F1-UBIC-COUNT",
                sql="SELECT COUNT(*) FROM territorial.ubicacion",
                expected=1660,
            ),
            PathEquation(
                name="PE-F1-ESTAB-TIPO-VALID",
                sql="""
                    SELECT establecimiento_id FROM territorial.establecimiento
                    WHERE tipo IS NOT NULL
                      AND tipo NOT IN ('hospital','cesfam','cecosf','cec','postas','sapu','sar','cosam','otro')
                """,
                expected="empty",
            ),
        ]
```

- [ ] **Step 4: Run tests**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f1_territorial.py -v
```

Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/migrate_to_pg/functors/f1_territorial.py tests/test_migration/test_f1_territorial.py
git commit -m "feat(migration): F1 territorial — 86 establecimientos + 1660 ubicaciones"
```

---

## Task 7: F₂ Pacientes — Strict ⊕ Canonical → clinical.paciente

**Files:**
- Create: `scripts/migrate_to_pg/functors/f2_pacientes.py`
- Create: `tests/test_migration/test_f2_pacientes.py`

- [ ] **Step 1: Write failing test**

```python
# tests/test_migration/test_f2_pacientes.py
"""Tests for F2: pacientes — strict ⊕ canonical -> clinical.paciente."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f2_pacientes import F2Pacientes


class TestF2Pacientes:
    def test_count_matches_strict(self, pg_bootstrapped, sources):
        """Exactly 673 patients — one per strict.paciente."""
        f2 = F2Pacientes()
        f2.objects(pg_bootstrapped, sources)
        pg_bootstrapped.commit()

        count = pg_bootstrapped.execute("SELECT COUNT(*) FROM clinical.paciente").fetchone()[0]
        assert count == 673

    def test_all_ruts_from_strict(self, pg_bootstrapped):
        """Every clinical.paciente.rut exists in strict.paciente."""
        violations = pg_bootstrapped.execute("""
            SELECT p.rut FROM clinical.paciente p
            WHERE p.rut NOT IN (SELECT rut FROM strict.paciente)
        """).fetchall()
        assert len(violations) == 0

    def test_nombres_preserved_from_strict(self, pg_bootstrapped):
        """Names come from strict, not overwritten by canonical."""
        violations = pg_bootstrapped.execute("""
            SELECT p.rut FROM clinical.paciente p
            JOIN strict.paciente s ON s.rut = p.rut
            WHERE p.nombre_completo != s.nombre
        """).fetchall()
        assert len(violations) == 0

    def test_enrichment_has_sexo(self, pg_bootstrapped):
        """At least some patients have sexo enriched from canonical."""
        count = pg_bootstrapped.execute(
            "SELECT COUNT(*) FROM clinical.paciente WHERE sexo IS NOT NULL"
        ).fetchone()[0]
        assert count > 0  # canonical has sexo for many patients

    def test_path_equations_pass(self, pg_bootstrapped):
        f2 = F2Pacientes()
        passed, diags = f2.verify(pg_bootstrapped)
        assert passed is True, f"Path equations failed: {diags}"
```

- [ ] **Step 2: Run to verify failure**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f2_pacientes.py -v
```

- [ ] **Step 3: Implement f2_pacientes.py**

```python
# scripts/migrate_to_pg/functors/f2_pacientes.py
"""
F2: Pacientes — strict ⊕ canonical -> clinical.paciente

Source:  strict.paciente (673, trust=1.0) ⊕ canonical/patient_master.csv (trust=0.8)
Target:  clinical.paciente (673)

The pushout over the pullback by RUT:
  - strict provides: rut, nombre, fecha_nacimiento (ALWAYS wins)
  - canonical enriches: sexo, comuna, cesfam, prevision, contacto, estado_actual
  - only patients with RUT in strict.paciente enter the target
"""

from __future__ import annotations

import csv

import psycopg

from ..framework.category import Functor, PathEquation
from ..framework.hash_ids import patient_id_from_rut
from ..framework.provenance import NaturalTransformation

# Map canonical sexo values to DDL CHECK enum
_SEXO_MAP = {"M": "masculino", "F": "femenino", "masculino": "masculino", "femenino": "femenino"}

# Map canonical prevision to DDL CHECK enum
_PREVISION_MAP = {
    "FONASA A": "fonasa-a", "FONASA B": "fonasa-b", "FONASA C": "fonasa-c",
    "FONASA D": "fonasa-d", "PRAIS": "prais",
}


class F2Pacientes(Functor):
    name = "F2_pacientes"
    depends_on = ["F0_bootstrap", "F1_territorial"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency: clean previous F2 data
        conn.execute("DELETE FROM clinical.paciente WHERE TRUE")

        # Step 1: Load canonical enrichment index (by RUT)
        canonical_by_rut: dict[str, dict] = {}
        canon_path = sources.canonical_dir / "patient_master.csv"
        with open(canon_path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                rut = row.get("rut", "").strip()
                if rut:
                    canonical_by_rut[rut] = row

        # Step 2: For each strict patient, generate patient_id + enrich
        strict_patients = conn.execute(
            "SELECT rut, nombre, fecha_nacimiento FROM strict.paciente"
        ).fetchall()

        n = 0
        for rut, nombre, fdn in strict_patients:
            pid = patient_id_from_rut(rut)
            canon = canonical_by_rut.get(rut, {})

            # Enrichment fields (only from canonical, strict fields are authoritative)
            sexo_raw = canon.get("sexo", "").strip()
            sexo = _SEXO_MAP.get(sexo_raw)

            comuna = canon.get("comuna", "").strip() or None
            cesfam = canon.get("cesfam", "").strip() or None

            prevision_raw = canon.get("prevision", "").strip().upper()
            prevision = _PREVISION_MAP.get(prevision_raw)

            contacto = canon.get("contacto_telefono", "").strip() or None

            # Derive estado_actual
            estado = canon.get("estado_actual", "").strip().lower() or None
            if estado and estado not in ("pre_ingreso", "activo", "egresado", "fallecido"):
                estado = None

            conn.execute(
                """
                INSERT INTO clinical.paciente
                    (patient_id, nombre_completo, rut, sexo, fecha_nacimiento,
                     comuna, cesfam, prevision, contacto_telefono, estado_actual)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (pid, nombre, rut, sexo, fdn, comuna, cesfam, prevision, contacto, estado),
            )

            # Provenance: row-level from strict
            eta.record(
                conn,
                target_table="clinical.paciente",
                target_pk=pid,
                source_type="strict",
                source_file="db/hdos.db",
                source_key=rut,
                phase="F2",
            )

            # Provenance: field-level from canonical
            enriched_fields = {
                "sexo": sexo, "comuna": comuna, "cesfam": cesfam,
                "prevision": prevision, "contacto_telefono": contacto,
                "estado_actual": estado,
            }
            for fname, fval in enriched_fields.items():
                if fval is not None:
                    eta.record(
                        conn,
                        target_table="clinical.paciente",
                        target_pk=pid,
                        source_type="canonical",
                        source_file="patient_master.csv",
                        source_key=rut,
                        phase="F2",
                        field_name=fname,
                    )

            n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F2-IDENTITY",
                sql="SELECT rut FROM clinical.paciente WHERE rut NOT IN (SELECT rut FROM strict.paciente)",
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-SURJECTION",
                sql="SELECT rut FROM strict.paciente WHERE rut NOT IN (SELECT rut FROM clinical.paciente)",
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-NAME-PRESERVE",
                sql="""
                    SELECT p.rut FROM clinical.paciente p
                    JOIN strict.paciente s ON s.rut = p.rut
                    WHERE p.nombre_completo != s.nombre
                """,
                expected="empty",
            ),
            PathEquation(
                name="PE-F2-COUNT",
                sql="SELECT COUNT(*) FROM clinical.paciente",
                expected=673,
            ),
        ]
```

- [ ] **Step 4: Run tests**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f2_pacientes.py -v
```

Expected: 5 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/migrate_to_pg/functors/f2_pacientes.py tests/test_migration/test_f2_pacientes.py
git commit -m "feat(migration): F2 pacientes — strict ⊕ canonical pushout, 673 patients"
```

---

## Task 8: F₃ Estadías — Strict ⊕ Canonical → clinical.estadia

**Files:**
- Create: `scripts/migrate_to_pg/functors/f3_estadias.py`
- Create: `tests/test_migration/test_f3_estadias.py`

- [ ] **Step 1: Write failing test**

```python
# tests/test_migration/test_f3_estadias.py
"""Tests for F3: estadias — strict ⊕ canonical -> clinical.estadia."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from functors.f3_estadias import F3Estadias


class TestF3Estadias:
    def test_count_matches_strict(self, pg_bootstrapped, sources):
        """Exactly 838 estadias — one per strict.hospitalizacion."""
        f3 = F3Estadias()
        f3.objects(pg_bootstrapped, sources)
        pg_bootstrapped.commit()

        count = pg_bootstrapped.execute("SELECT COUNT(*) FROM clinical.estadia").fetchone()[0]
        assert count == 838

    def test_all_estadias_have_patient(self, pg_bootstrapped):
        """Every estadia references an existing clinical.paciente."""
        violations = pg_bootstrapped.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
            WHERE p.patient_id IS NULL
        """).fetchall()
        assert len(violations) == 0

    def test_fk_triangle_commutes(self, pg_bootstrapped):
        """The triangle estadia->paciente->rut = strict.hospitalizacion.rut_paciente commutes."""
        violations = pg_bootstrapped.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            JOIN clinical.paciente p ON p.patient_id = e.patient_id
            WHERE NOT EXISTS (
                SELECT 1 FROM strict.hospitalizacion h
                WHERE h.rut_paciente = p.rut AND h.fecha_ingreso = e.fecha_ingreso
            )
        """).fetchall()
        assert len(violations) == 0

    def test_dates_ordered(self, pg_bootstrapped):
        """No estadia has fecha_egreso < fecha_ingreso."""
        violations = pg_bootstrapped.execute("""
            SELECT stay_id FROM clinical.estadia
            WHERE fecha_egreso IS NOT NULL AND fecha_egreso < fecha_ingreso
        """).fetchall()
        assert len(violations) == 0

    def test_enrichment_has_diagnostico(self, pg_bootstrapped):
        """At least some estadias have diagnostico from canonical."""
        count = pg_bootstrapped.execute(
            "SELECT COUNT(*) FROM clinical.estadia WHERE diagnostico_principal IS NOT NULL"
        ).fetchone()[0]
        assert count > 0

    def test_path_equations_pass(self, pg_bootstrapped):
        f3 = F3Estadias()
        passed, diags = f3.verify(pg_bootstrapped)
        assert passed is True, f"Path equations failed: {diags}"
```

- [ ] **Step 2: Run to verify failure**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f3_estadias.py -v
```

- [ ] **Step 3: Implement f3_estadias.py**

```python
# scripts/migrate_to_pg/functors/f3_estadias.py
"""
F3: Estadias — strict ⊕ canonical -> clinical.estadia

Source:  strict.hospitalizacion (838, trust=1.0)
        ⊕ canonical/hospitalization_stay.csv (trust=0.8)
Target:  clinical.estadia (838)

stay_id cannot be regenerated from strict data alone (it depends on episode_ids).
We look up canonical stay_id by matching (rut, fecha_ingreso).
If no canonical match, we generate a fallback stay_id from (rut, fecha_ingreso, fecha_egreso).
"""

from __future__ import annotations

import csv
from datetime import date, timedelta

import psycopg

from ..framework.category import Functor, PathEquation
from ..framework.hash_ids import make_id, patient_id_from_rut
from ..framework.provenance import NaturalTransformation

# Map canonical motivo_egreso -> DDL CHECK tipo_egreso
_TIPO_EGRESO_MAP = {
    "ALTA": "alta_clinica",
    "ALTA CLINICA": "alta_clinica",
    "REHOSPITALIZACION": "reingreso",
    "REINGRESO": "reingreso",
    "FALLECIMIENTO": "fallecido_esperado",
    "FALLECIDO": "fallecido_esperado",
    "RENUNCIA": "renuncia_voluntaria",
    "RENUNCIA VOLUNTARIA": "renuncia_voluntaria",
    "ALTA DISCIPLINARIA": "alta_disciplinaria",
}

# Map canonical origen_derivacion_rem -> DDL CHECK origen_derivacion
_ORIGEN_MAP = {
    "Urgencia": "urgencia",
    "UE": "urgencia",
    "Hospitalizacion": "hospitalizacion",
    "APS": "APS",
    "Ambulatorio": "ambulatorio",
    "Ley Urgencia": "ley_urgencia",
    "UGCC": "UGCC",
}


def _parse_date(s: str) -> date | None:
    s = s.strip()
    if not s:
        return None
    try:
        return date.fromisoformat(s)
    except ValueError:
        return None


def _build_canonical_index(canonical_dir) -> dict[tuple[str, str], dict]:
    """Index canonical stays by (rut, fecha_ingreso) for lookup.

    If multiple stays share (rut, fecha_ingreso), keep the one with highest confidence.
    """
    index: dict[tuple[str, str], dict] = {}
    path = canonical_dir / "hospitalization_stay.csv"
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rut = row.get("rut", "").strip()
            fi = row.get("fecha_ingreso", "").strip()
            if not rut or not fi:
                continue
            key = (rut, fi)
            existing = index.get(key)
            if existing is None:
                index[key] = row
            else:
                # Prefer higher confidence
                conf_order = {"high": 3, "medium": 2, "low": 1, "": 0}
                if conf_order.get(row.get("confidence_level", ""), 0) > conf_order.get(
                    existing.get("confidence_level", ""), 0
                ):
                    index[key] = row
    return index


def _find_canonical_match(
    rut: str, fi: str, canonical_index: dict[tuple[str, str], dict]
) -> dict | None:
    """Find canonical match by (rut, fecha_ingreso) with ±1 day tolerance."""
    # Exact match first
    exact = canonical_index.get((rut, fi))
    if exact:
        return exact

    # ±1 day tolerance
    fi_date = _parse_date(fi)
    if fi_date is None:
        return None
    for delta in (1, -1):
        nearby = (fi_date + timedelta(days=delta)).isoformat()
        match = canonical_index.get((rut, nearby))
        if match:
            return match
    return None


class F3Estadias(Functor):
    name = "F3_estadias"
    depends_on = ["F0_bootstrap", "F1_territorial", "F2_pacientes"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM clinical.estadia WHERE TRUE")

        # Build canonical lookup index
        canonical_index = _build_canonical_index(sources.canonical_dir)

        # Load valid establecimiento_ids for FK validation
        valid_estab = {
            r[0]
            for r in conn.execute(
                "SELECT establecimiento_id FROM territorial.establecimiento"
            ).fetchall()
        }

        # For each strict hospitalization, match to canonical and enrich
        strict_hosps = conn.execute(
            "SELECT rut_paciente, fecha_ingreso, fecha_egreso FROM strict.hospitalizacion ORDER BY fecha_ingreso"
        ).fetchall()

        n = 0
        for rut, fi, fe in strict_hosps:
            pid = patient_id_from_rut(rut)
            canon = _find_canonical_match(rut, fi, canonical_index)

            # stay_id: from canonical if matched, else generate fallback
            if canon and canon.get("stay_id", "").strip():
                stay_id = canon["stay_id"].strip()
            else:
                fe_part = fe or "NULL"
                stay_id = make_id("stay", f"{rut}|{fi}|{fe_part}")

            # Estado
            estado = "activo" if fe is None else "egresado"

            # Enrichment from canonical
            diagnostico = None
            tipo_egreso = None
            origen = None
            estab_id = None
            confidence = None

            if canon:
                diagnostico = canon.get("diagnostico_principal", "").strip() or None

                motivo_raw = canon.get("motivo_egreso", "").strip().upper()
                tipo_egreso = _TIPO_EGRESO_MAP.get(motivo_raw)

                origen_raw = canon.get("origen_derivacion_rem", "").strip()
                origen = _ORIGEN_MAP.get(origen_raw)

                # Establecimiento: look up by nombre or codigo_deis
                canon_estab = canon.get("establecimiento", "").strip()
                canon_deis = canon.get("codigo_deis", "").strip()
                if canon_deis and canon_deis in valid_estab:
                    estab_id = canon_deis
                elif canon_estab:
                    # Look up by name
                    match = conn.execute(
                        "SELECT establecimiento_id FROM territorial.establecimiento WHERE nombre = %s LIMIT 1",
                        (canon_estab,),
                    ).fetchone()
                    if match:
                        estab_id = match[0]

                confidence = canon.get("confidence_level", "").strip() or None

            conn.execute(
                """
                INSERT INTO clinical.estadia
                    (stay_id, patient_id, fecha_ingreso, fecha_egreso, estado,
                     diagnostico_principal, tipo_egreso, origen_derivacion,
                     establecimiento_id, confidence_level)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (stay_id, pid, fi, fe, estado, diagnostico, tipo_egreso, origen, estab_id, confidence),
            )

            # Provenance
            eta.record(
                conn,
                target_table="clinical.estadia",
                target_pk=stay_id,
                source_type="strict",
                source_file="db/hdos.db",
                source_key=f"{rut}|{fi}",
                phase="F3",
            )
            if canon:
                for fname in ("diagnostico_principal", "tipo_egreso", "origen_derivacion", "establecimiento_id", "confidence_level"):
                    val = locals().get(fname) or eval(fname)  # noqa: the local vars above
                    # Simpler: just check if we enriched this field
                enriched = {
                    "diagnostico_principal": diagnostico,
                    "tipo_egreso": tipo_egreso,
                    "origen_derivacion": origen,
                    "establecimiento_id": estab_id,
                    "confidence_level": confidence,
                }
                for fname, fval in enriched.items():
                    if fval is not None:
                        eta.record(
                            conn,
                            target_table="clinical.estadia",
                            target_pk=stay_id,
                            source_type="canonical",
                            source_file="hospitalization_stay.csv",
                            source_key=f"{rut}|{fi}",
                            phase="F3",
                            field_name=fname,
                        )

            n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F3-ANCHOR",
                sql="""
                    SELECT e.stay_id FROM clinical.estadia e
                    JOIN clinical.paciente p ON p.patient_id = e.patient_id
                    WHERE NOT EXISTS (
                        SELECT 1 FROM strict.hospitalizacion h
                        WHERE h.rut_paciente = p.rut AND h.fecha_ingreso = e.fecha_ingreso
                    )
                """,
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-NO-ORPHAN",
                sql="""
                    SELECT e.stay_id FROM clinical.estadia e
                    LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
                    WHERE p.patient_id IS NULL
                """,
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-DATE-ORDER",
                sql="SELECT stay_id FROM clinical.estadia WHERE fecha_egreso IS NOT NULL AND fecha_egreso < fecha_ingreso",
                expected="empty",
            ),
            PathEquation(
                name="PE-F3-COUNT",
                sql="SELECT COUNT(*) FROM clinical.estadia",
                expected=838,
            ),
        ]

    def glue_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="GLUE-F1-F3",
                sql="""
                    SELECT e.stay_id FROM clinical.estadia e
                    WHERE e.establecimiento_id IS NOT NULL
                      AND e.establecimiento_id NOT IN (
                        SELECT establecimiento_id FROM territorial.establecimiento
                      )
                """,
                expected="empty",
            ),
        ]
```

- [ ] **Step 4: Run tests**

```bash
.venv/bin/python -m pytest tests/test_migration/test_f3_estadias.py -v
```

Expected: 6 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/migrate_to_pg/functors/f3_estadias.py tests/test_migration/test_f3_estadias.py
git commit -m "feat(migration): F3 estadias — strict ⊕ canonical, 838 stays with enrichment"
```

---

## Task 9: run_migration.py — CLI Entry Point

**Files:**
- Create: `scripts/migrate_to_pg/run_migration.py`

- [ ] **Step 1: Implement CLI**

```python
#!/usr/bin/env python3
# scripts/migrate_to_pg/run_migration.py
"""
CLI entry point for the categorical migration.

Usage:
  .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url postgresql://user:pass@host/db
  .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url ... --phase F2
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

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

ALL_FUNCTORS = [
    F0Bootstrap(),
    F1Territorial(),
    F2Pacientes(),
    F3Estadias(),
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
```

- [ ] **Step 2: Test CLI help**

```bash
.venv/bin/python scripts/migrate_to_pg/run_migration.py --help
```

Expected: usage message with --db-url, --phase, --dry-run

- [ ] **Step 3: Commit**

```bash
git add scripts/migrate_to_pg/run_migration.py
git commit -m "feat(migration): CLI entry point — run_migration.py"
```

---

## Task 10: Integration Test — Sprint 1 Completo

**Files:**
- Create: `tests/test_migration/test_sprint1_integration.py`

- [ ] **Step 1: Write integration test**

```python
# tests/test_migration/test_sprint1_integration.py
"""
Integration test: run the full Sprint 1 migration (F0 → F3)
and verify all path equations + glue equations.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.runner import ComposedFunctor, MigrationSources
from functors.f0_bootstrap import F0Bootstrap
from functors.f1_territorial import F1Territorial
from functors.f2_pacientes import F2Pacientes
from functors.f3_estadias import F3Estadias


@pytest.fixture(scope="module")
def migration_report(pg_test_db):
    """Run full Sprint 1 migration and return report."""
    import psycopg

    conn = psycopg.connect(pg_test_db)

    sources = MigrationSources(
        strict_db=Path(__file__).resolve().parent.parent.parent / "db" / "hdos.db",
        canonical_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "canonical",
        intermediate_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "intermediate",
        enriched_dir=Path(__file__).resolve().parent.parent.parent / "output" / "spreadsheet" / "enriched",
        legacy_dir=Path(__file__).resolve().parent.parent.parent / "documentacion-legacy",
    )

    composed = ComposedFunctor([
        F0Bootstrap(),
        F1Territorial(),
        F2Pacientes(),
        F3Estadias(),
    ])

    report = composed.run(conn, sources)
    yield report, conn
    conn.close()


class TestSprint1Integration:
    def test_all_phases_completed(self, migration_report):
        report, _ = migration_report
        assert report.halted_at is None, f"Migration halted at {report.halted_at}"
        assert len(report.phases) == 4

    def test_all_equations_passed(self, migration_report):
        report, _ = migration_report
        assert report.all_passed is True, report.summary()

    def test_total_objects(self, migration_report):
        report, _ = migration_report
        # F0: 673+838=1511, F1: 86+1660=1746, F2: 673, F3: 838
        assert report.total_objects > 0

    def test_pacientes_count(self, migration_report):
        _, conn = migration_report
        count = conn.execute("SELECT COUNT(*) FROM clinical.paciente").fetchone()[0]
        assert count == 673

    def test_estadias_count(self, migration_report):
        _, conn = migration_report
        count = conn.execute("SELECT COUNT(*) FROM clinical.estadia").fetchone()[0]
        assert count == 838

    def test_establecimientos_count(self, migration_report):
        _, conn = migration_report
        count = conn.execute("SELECT COUNT(*) FROM territorial.establecimiento").fetchone()[0]
        assert count == 86

    def test_provenance_exists(self, migration_report):
        _, conn = migration_report
        count = conn.execute("SELECT COUNT(*) FROM migration.provenance").fetchone()[0]
        assert count > 0, "No provenance records — eta didn't fire"

    def test_provenance_covers_all_patients(self, migration_report):
        _, conn = migration_report
        # Every patient should have at least one provenance record
        missing = conn.execute("""
            SELECT p.patient_id FROM clinical.paciente p
            WHERE NOT EXISTS (
                SELECT 1 FROM migration.provenance prov
                WHERE prov.target_table = 'clinical.paciente'
                  AND prov.target_pk = p.patient_id
            )
        """).fetchall()
        assert len(missing) == 0, f"{len(missing)} patients without provenance"

    def test_provenance_covers_all_estadias(self, migration_report):
        _, conn = migration_report
        missing = conn.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            WHERE NOT EXISTS (
                SELECT 1 FROM migration.provenance prov
                WHERE prov.target_table = 'clinical.estadia'
                  AND prov.target_pk = e.stay_id
            )
        """).fetchall()
        assert len(missing) == 0, f"{len(missing)} estadias without provenance"

    def test_no_orphan_estadias(self, migration_report):
        """FK triangle: every estadia.patient_id exists in clinical.paciente."""
        _, conn = migration_report
        orphans = conn.execute("""
            SELECT e.stay_id FROM clinical.estadia e
            LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
            WHERE p.patient_id IS NULL
        """).fetchall()
        assert len(orphans) == 0

    def test_strict_is_base_of_truth(self, migration_report):
        """Every clinical.paciente.rut comes from strict. No extras."""
        _, conn = migration_report
        extras = conn.execute("""
            SELECT rut FROM clinical.paciente
            WHERE rut NOT IN (SELECT rut FROM strict.paciente)
        """).fetchall()
        assert len(extras) == 0, f"{len(extras)} patients not in strict"
```

- [ ] **Step 2: Run integration test**

```bash
.venv/bin/python -m pytest tests/test_migration/test_sprint1_integration.py -v
```

Expected: 11 passed — all path equations, glue equations, provenance, and counts verified.

- [ ] **Step 3: Commit**

```bash
git add tests/test_migration/test_sprint1_integration.py
git commit -m "test(migration): Sprint 1 integration — full F0→F3 with path equation verification"
```

---

## Self-Review Checklist

1. **Spec coverage**: All 5 spec sections covered — framework (Tasks 2-4), F₀ (Task 5), F₁ (Task 6), F₂ (Task 7), F₃ (Task 8), CLI (Task 9), validation (Task 10).
2. **Placeholder scan**: No TBD/TODO. All code blocks are complete.
3. **Type consistency**: `PathEquation`, `Functor`, `NaturalTransformation`, `ComposedFunctor`, `MigrationSources`, `MigrationReport`, `PhaseReport` — consistent across all tasks. `patient_id_from_rut()`, `make_id()`, `stable_id()` — consistent between hash_ids.py and functors.
4. **Spec requirements**: Path equations PE-F2-*, PE-F3-*, GLUE-F1-F3 all implemented. Provenance η implemented. Idempotency via DELETE before INSERT. Transactional execution in ComposedFunctor.
