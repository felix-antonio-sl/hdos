"""Tests for the categorical framework: PathEquation and Functor."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "migrate_to_pg"))

from framework.category import PathEquation, Functor


class TestPathEquation:
    def test_check_empty_passes(self, pg_bootstrapped):
        eq = PathEquation(
            name="PE-TEST-EMPTY",
            sql="SELECT 1 WHERE FALSE",
            expected="empty",
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is True
        assert "PASS" in diag

    def test_check_empty_fails(self, pg_bootstrapped):
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
        eq = PathEquation(
            name="PE-TEST-COUNT",
            sql="SELECT COUNT(*) FROM (SELECT 1 UNION ALL SELECT 2) t",
            expected=2,
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is True

    def test_check_count_fails(self, pg_bootstrapped):
        eq = PathEquation(
            name="PE-TEST-BADCOUNT",
            sql="SELECT COUNT(*) FROM (SELECT 1) t",
            expected=99,
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is False
        assert "expected 99" in diag

    def test_warning_severity_does_not_block(self, pg_bootstrapped):
        eq = PathEquation(
            name="PE-TEST-WARN",
            sql="SELECT 1",
            expected="empty",
            severity="warning",
        )
        passed, diag = eq.check(pg_bootstrapped)
        assert passed is False
        assert "FAIL" in diag


class TestFunctor:
    def test_verify_all_pass(self, pg_bootstrapped):
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
