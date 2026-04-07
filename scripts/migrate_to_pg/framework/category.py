"""
Categorical framework for data migration.

PathEquation: a diagram that must commute — verified as SQL query.
Functor: transforms source objects to target objects, preserving morphisms.
"""

from __future__ import annotations

from dataclasses import dataclass
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
        raise NotImplementedError

    def path_equations(self) -> list[PathEquation]:
        return []

    def glue_equations(self) -> list[PathEquation]:
        return []

    def verify(self, conn: psycopg.Connection) -> tuple[bool, list[str]]:
        all_eqs = self.path_equations() + self.glue_equations()
        diags: list[str] = []
        all_passed = True
        for eq in all_eqs:
            passed, diag = eq.check(conn)
            diags.append(diag)
            if not passed and eq.severity == "critical":
                all_passed = False
        return all_passed, diags
