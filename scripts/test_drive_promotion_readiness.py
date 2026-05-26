import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
READINESS_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-promotion-readiness.sql"
CONTRACT_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-promotion-contract.sql"
HUMAN_SQL = ROOT / "db" / "updates" / "2026-05-26-human-reconciliation.sql"
SIMULATED_SQL = ROOT / "db" / "updates" / "2026-05-26-simulated-reconciliation-proposals.sql"
DUPLICATE_REVIEW_SQL = ROOT / "db" / "updates" / "2026-05-26-duplicate-visit-review.sql"
IDENTITY_STAY_REVIEW_SQL = ROOT / "db" / "updates" / "2026-05-26-identity-stay-review.sql"
DICTIONARY_SEEDS_SQL = ROOT / "db" / "updates" / "2026-05-26-dictionary-seeds.sql"
EXPERT_RECONCILIATION_SQL = ROOT / "db" / "updates" / "2026-05-26-expert-reconciliation-recommendations.sql"


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

    def test_duplicate_visit_review_sql_defines_queue_and_summary(self):
        self.assertTrue(DUPLICATE_REVIEW_SQL.exists(), "duplicate visit review SQL must exist")
        sql = DUPLICATE_REVIEW_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_duplicate_visit_review_queue", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_duplicate_visit_review_summary", sql)
        self.assertIn("DROP VIEW IF EXISTS staging.v_hodom_duplicate_visit_review_summary", sql)
        self.assertIn("DROP VIEW IF EXISTS staging.v_hodom_duplicate_visit_review_queue", sql)
        self.assertIn("anchor_type = 'duplicate_visit'", sql)
        self.assertIn("decided_by = 'simulated_agent_reconciliation'", sql)
        self.assertIn("MERGE_COMPLEMENT_CANDIDATE", sql)
        self.assertIn("MERGE_VERIFY_ONLY_CANDIDATE", sql)
        self.assertIn("target_source_row_count", sql)
        self.assertIn("MANY_TO_ONE_REVIEW", sql)
        self.assertIn("review_priority", sql)

    def test_duplicate_visit_review_sql_does_not_approve_or_write_core(self):
        self.assertTrue(DUPLICATE_REVIEW_SQL.exists(), "duplicate visit review SQL must exist")
        lower_sql = DUPLICATE_REVIEW_SQL.read_text(encoding="utf-8").lower()
        upper_sql = lower_sql.upper()

        self.assertNotIn("'approved'", lower_sql)
        self.assertNotIn("INSERT INTO CLINICAL.", upper_sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", upper_sql)
        self.assertNotIn("UPDATE CLINICAL.", upper_sql)
        self.assertNotIn("UPDATE OPERATIONAL.", upper_sql)

    def test_identity_stay_review_sql_defines_composition_queue_and_summary(self):
        self.assertTrue(IDENTITY_STAY_REVIEW_SQL.exists(), "identity/stay review SQL must exist")
        sql = IDENTITY_STAY_REVIEW_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_identity_stay_review_queue", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_identity_stay_review_summary", sql)
        self.assertIn("anchor_type IN ('patient_identity', 'active_stay')", sql)
        self.assertIn("stay_patient_matches_identity", sql)
        self.assertIn("visit_within_stay_window", sql)
        self.assertIn("IDENTITY_STAY_COMPOSES", sql)
        self.assertIn("PAIR_MISSING_ANCHOR", sql)
        self.assertIn("COMPOSITION_MISMATCH", sql)

    def test_identity_stay_review_sql_does_not_approve_or_write_core(self):
        self.assertTrue(IDENTITY_STAY_REVIEW_SQL.exists(), "identity/stay review SQL must exist")
        lower_sql = IDENTITY_STAY_REVIEW_SQL.read_text(encoding="utf-8").lower()
        upper_sql = lower_sql.upper()

        self.assertNotIn("'approved'", lower_sql)
        self.assertNotIn("INSERT INTO CLINICAL.", upper_sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", upper_sql)
        self.assertNotIn("UPDATE CLINICAL.", upper_sql)
        self.assertNotIn("UPDATE OPERATIONAL.", upper_sql)

    def test_dictionary_seeds_sql_defines_seed_views_and_scope(self):
        self.assertTrue(DICTIONARY_SEEDS_SQL.exists(), "dictionary seeds SQL must exist")
        sql = DICTIONARY_SEEDS_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_service_prestacion_dictionary_seed", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_professional_provider_dictionary_seed", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_address_domicilio_dictionary_seed", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_dictionary_seed_summary", sql)
        self.assertIn("READY_IDENTITY_STAY_ONLY", sql)
        self.assertIn("NEEDS_DICTIONARY_TARGET", sql)
        self.assertIn("reference.catalogo_prestacion", sql)
        self.assertIn("operational.profesional", sql)
        self.assertIn("clinical.domicilio", sql)

    def test_dictionary_seeds_sql_does_not_approve_or_write_core(self):
        self.assertTrue(DICTIONARY_SEEDS_SQL.exists(), "dictionary seeds SQL must exist")
        lower_sql = DICTIONARY_SEEDS_SQL.read_text(encoding="utf-8").lower()
        upper_sql = lower_sql.upper()

        self.assertNotIn("'approved'", lower_sql)
        self.assertNotIn("INSERT INTO CLINICAL.", upper_sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", upper_sql)
        self.assertNotIn("UPDATE CLINICAL.", upper_sql)
        self.assertNotIn("UPDATE OPERATIONAL.", upper_sql)

    def test_expert_reconciliation_sql_inserts_proposed_recommendations(self):
        self.assertTrue(EXPERT_RECONCILIATION_SQL.exists(), "expert reconciliation SQL must exist")
        sql = EXPERT_RECONCILIATION_SQL.read_text(encoding="utf-8")

        self.assertIn("INSERT INTO staging.hodom_reconciliation_decision", sql)
        self.assertIn("simulated_expert_reconciliation", sql)
        self.assertIn("'proposed'", sql)
        self.assertIn("service_prestacion", sql)
        self.assertIn("address_domicilio", sql)
        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_expert_migration_readiness", sql)
        self.assertIn("EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS", sql)
        self.assertIn("EXPERT_SPLIT_SERVICE_REQUIRED", sql)

    def test_expert_reconciliation_sql_does_not_approve_or_write_core(self):
        self.assertTrue(EXPERT_RECONCILIATION_SQL.exists(), "expert reconciliation SQL must exist")
        lower_sql = EXPERT_RECONCILIATION_SQL.read_text(encoding="utf-8").lower()
        upper_sql = lower_sql.upper()

        self.assertNotIn("'approved'", lower_sql)
        self.assertNotIn("INSERT INTO CLINICAL.", upper_sql)
        self.assertNotIn("INSERT INTO OPERATIONAL.", upper_sql)
        self.assertNotIn("UPDATE CLINICAL.", upper_sql)
        self.assertNotIn("UPDATE OPERATIONAL.", upper_sql)


if __name__ == "__main__":
    unittest.main()
