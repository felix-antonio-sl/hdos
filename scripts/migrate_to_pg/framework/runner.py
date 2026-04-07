# scripts/migrate_to_pg/framework/runner.py
"""Migration orchestrator — composes functors topologically and executes."""

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
    strict_db: Path
    canonical_dir: Path
    intermediate_dir: Path
    enriched_dir: Path
    legacy_dir: Path

    def trust_level(self, source_type: str) -> float:
        return {"strict": 1.0, "canonical": 0.8, "intermediate": 0.6, "legacy": 0.4}[source_type]


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
            st = "OK" if not pr.violations else "FAIL"
            lines.append(
                f"  {pr.functor}: {pr.objects_migrated} objects, "
                f"{eqs} equations, {pr.elapsed_seconds:.1f}s [{st}]"
            )
            for v in pr.violations:
                lines.append(f"    ! {v}")
        return "\n".join(lines)


class ComposedFunctor:
    def __init__(self, phases: list[Functor]) -> None:
        self.phases = phases

    def run(self, conn: psycopg.Connection, sources: MigrationSources, *, dry_run: bool = False, skip_deps: bool = False) -> MigrationReport:
        ensure_provenance_table(conn)
        conn.commit()
        report = MigrationReport()
        completed: set[str] = set()
        for functor in self.phases:
            if not skip_deps:
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
                    provenance_records=0,
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
