import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
READINESS_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-promotion-readiness.sql"


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


if __name__ == "__main__":
    unittest.main()
