import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
READINESS_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-promotion-readiness.sql"
CONTRACT_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-promotion-contract.sql"
HUMAN_SQL = ROOT / "db" / "updates" / "2026-05-26-human-reconciliation.sql"
SIMULATED_SQL = ROOT / "db" / "updates" / "2026-05-26-simulated-reconciliation-proposals.sql"


class DrivePromotionReadinessTests(unittest.TestCase):
    def test_readiness_sql_defines_required_views(self):
        sql = READINESS_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE FUNCTION staging.norm_text", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_candidate", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_summary", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_handover_promotion_summary", sql)
        self.assertIn("READY_CORE_VISIT", sql)
        self.assertIn("BLOCKED_NO_ACTIVE_STAY_MATCH", sql)

    def test_readiness_sql_does_not_define_core_inserts(self):
        sql = READINESS_SQL.read_text(encoding="utf-8").upper()

        self.assertNotIn("INSERT INTO CLINICAL.", sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", sql)
        self.assertNotIn("UPDATE CLINICAL.", sql)
        self.assertNotIn("UPDATE OPERATIONAL.", sql)

    def test_contract_sql_degrades_ready_core_visit_to_identity_stay_only(self):
        sql = CONTRACT_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_contract_summary", sql)
        self.assertIn("READY_IDENTITY_STAY_ONLY", sql)
        self.assertIn("REVIEW_DUPLICATE_PUSHOUT_REQUIRED", sql)
        self.assertIn("service_text_to_prestacion_id", sql)

    def test_contract_sql_does_not_define_core_inserts(self):
        sql = CONTRACT_SQL.read_text(encoding="utf-8").upper()

        self.assertNotIn("INSERT INTO CLINICAL.", sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", sql)
        self.assertNotIn("UPDATE CLINICAL.", sql)
        self.assertNotIn("UPDATE OPERATIONAL.", sql)

    def test_human_reconciliation_sql_defines_decision_table_and_candidate_views(self):
        sql = HUMAN_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_reconciliation_decision", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_candidate", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_candidate_summary", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_reconciliation_human_gate", sql)
        self.assertIn("NEEDS_HUMAN_CONFIRMATION", sql)
        self.assertIn("human_approved", sql)

    def test_human_reconciliation_sql_does_not_define_core_inserts(self):
        sql = HUMAN_SQL.read_text(encoding="utf-8").upper()

        self.assertNotIn("INSERT INTO CLINICAL.", sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", sql)
        self.assertNotIn("UPDATE CLINICAL.", sql)
        self.assertNotIn("UPDATE OPERATIONAL.", sql)

    def test_simulated_reconciliation_sql_creates_proposals_not_approvals(self):
        self.assertTrue(SIMULATED_SQL.exists(), "simulated reconciliation SQL must exist")
        sql = SIMULATED_SQL.read_text(encoding="utf-8")
        lower_sql = sql.lower()

        self.assertIn("INSERT INTO staging.hodom_reconciliation_decision", sql)
        self.assertIn("simulated_agent_reconciliation", sql)
        self.assertIn("'proposed'", sql)
        self.assertIn("target_pk IS NOT NULL", sql)
        self.assertIn("HAVING count(DISTINCT target_pk) = 1", sql)
        self.assertNotIn("'approved'", lower_sql)

    def test_simulated_reconciliation_sql_does_not_define_core_inserts(self):
        self.assertTrue(SIMULATED_SQL.exists(), "simulated reconciliation SQL must exist")
        sql = SIMULATED_SQL.read_text(encoding="utf-8").upper()

        self.assertNotIn("INSERT INTO CLINICAL.", sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", sql)
        self.assertNotIn("UPDATE CLINICAL.", sql)
        self.assertNotIn("UPDATE OPERATIONAL.", sql)


if __name__ == "__main__":
    unittest.main()
