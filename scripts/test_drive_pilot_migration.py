import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PILOT_SQL = ROOT / "db" / "updates" / "2026-05-26-drive-pilot-migration.sql"


class DrivePilotMigrationTests(unittest.TestCase):
    def test_pilot_sql_exists(self):
        self.assertTrue(PILOT_SQL.exists(), "pilot migration SQL must exist")

    def test_pilot_sql_defines_preview_view(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_preview", sql)
        self.assertIn("EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS", sql)
        self.assertIn("READY_IDENTITY_STAY_ONLY", sql)
        self.assertIn("matched_patient_id", sql)
        self.assertIn("matched_stay_id", sql)
        self.assertIn("route_visit_id", sql)
        self.assertIn("source_path", sql)
        self.assertIn("candidate_visit_id AS visit_id", sql)

    def test_pilot_sql_defines_gate_view(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_gate", sql)
        self.assertIn("preview_visit_count", sql)
        self.assertIn("expected_pilot_route_count", sql)
        self.assertIn("already_promoted_count", sql)
        self.assertIn("pilot_preview_gate", sql)

    def test_pilot_sql_defines_audit_view(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_audit", sql)
        self.assertIn("promoted", sql)
        self.assertIn("provider_id_assigned", sql)
        self.assertIn("provenance_field_count", sql)
        self.assertIn("LEFT JOIN operational.visita", sql)
        self.assertIn("migration.provenance", sql)

    def test_pilot_sql_defines_promotion_summary_view(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_promotion_summary", sql)
        self.assertIn("migration_phase", sql)
        self.assertIn("expected_visits", sql)
        self.assertIn("promoted_visits", sql)
        self.assertIn("rows_with_provider_assigned", sql)
        self.assertIn("provenance_rows_total", sql)

    def test_pilot_sql_inserts_into_operational_visita(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("INSERT INTO operational.visita", sql)
        self.assertIn("visit_id", sql)
        self.assertIn("stay_id", sql)
        self.assertIn("patient_id", sql)
        self.assertIn("PROGRAMADA", sql)
        self.assertIn("pendiente", sql)

    def test_pilot_sql_inserts_provenance_per_field(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("INSERT INTO migration.provenance", sql)
        self.assertIn("pilot_minimal_2026_05_26", sql)
        self.assertIn("target_table", sql)
        self.assertIn("target_pk", sql)
        self.assertIn("source_type", sql)
        self.assertIn("source_file", sql)
        self.assertIn("source_key", sql)
        self.assertIn("phase", sql)
        self.assertIn("field_name", sql)

    def test_pilot_sql_provider_id_from_professional_match(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("pv.provider_id", sql)
        self.assertIn("suggested_provider_id", sql)
        self.assertIn("provider_id_assigned", sql)
        self.assertIn("rows_with_provider_assigned", sql)
        self.assertIn("suggested_provider_name", sql)

    def test_pilot_sql_does_not_touch_duplicate_visit(self):
        raw_sql = PILOT_SQL.read_text(encoding="utf-8")
        code_lines = [l for l in raw_sql.split("\n")
                      if not l.strip().startswith("--")]
        code_text = "\n".join(code_lines).lower()

        self.assertNotIn("duplicate_visit", code_text)
        self.assertNotIn("duplicate_of", code_text)
        self.assertNotIn("pushout_required", code_text)
        self.assertNotIn("existing_visit", code_text)

    def test_pilot_sql_does_not_pathologically_insert(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertNotIn("INSERT INTO clinical.", sql)
        self.assertNotIn("UPDATE clinical.", sql)
        self.assertNotIn("UPDATE operational.", sql)

    def test_pilot_sql_has_not_exists_guard(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        self.assertIn("NOT EXISTS", sql)
        self.assertIn("WHERE NOT EXISTS", sql)

    def test_pilot_sql_defines_preview_first(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        preview_idx = sql.index("CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_preview")
        insert_idx = sql.index("INSERT INTO operational.visita")

        self.assertLess(preview_idx, insert_idx,
                        "preview view must be defined before INSERT statements")

    def test_pilot_sql_preview_is_select_only(self):
        preview_lines = []
        capture = False
        for line in PILOT_SQL.read_text(encoding="utf-8").split("\n"):
            if "CREATE OR REPLACE VIEW staging.v_hodom_pilot_minimal_preview" in line:
                capture = True
                continue
            if capture and "COMMENT ON VIEW staging.v_hodom_pilot_minimal_preview" in line:
                break
            if capture and line.strip():
                preview_lines.append(line.strip())

        preview_text = "\n".join(preview_lines).upper()
        self.assertNotIn("INSERT", preview_text)
        self.assertNotIn("UPDATE", preview_text)
        self.assertNotIn("DELETE", preview_text)
        self.assertNotIn("DROP", preview_text)

    def test_pilot_sql_is_transactional(self):
        sql = PILOT_SQL.read_text(encoding="utf-8")

        begin_idx = sql.index("BEGIN;")
        commit_idx = sql.index("COMMIT;")

        self.assertLess(begin_idx, commit_idx,
                        "BEGIN must precede COMMIT")
        self.assertIn("BEGIN;", sql)
        self.assertIn("COMMIT;", sql)

    def test_professional_reconciliation_views_populated(self):
        prof_sql_path = ROOT / "db" / "updates" / "2026-05-26-professional-reconciliation.sql"
        self.assertTrue(prof_sql_path.exists(), "professional reconciliation SQL must exist")
        sql = prof_sql_path.read_text(encoding="utf-8")

        self.assertIn("v_hodom_drive_professional_lookup", sql)
        self.assertIn("v_hodom_professional_match_scoring", sql)
        self.assertIn("v_hodom_professional_match_summary", sql)
        self.assertIn("v_hodom_route_professional_match", sql)
        self.assertIn("professional_provider", sql)
        self.assertIn("simulated_expert_reconciliation", sql)
        self.assertIn("maps_to", sql)

    def test_professional_reconciliation_no_core_inserts(self):
        prof_sql_path = ROOT / "db" / "updates" / "2026-05-26-professional-reconciliation.sql"
        sql = prof_sql_path.read_text(encoding="utf-8")

        self.assertNotIn("INSERT INTO clinical.", sql)
        self.assertNotIn("INSERT INTO operational.", sql)
        self.assertNotIn("UPDATE clinical.", sql)
        self.assertNotIn("UPDATE operational.", sql)


if __name__ == "__main__":
    unittest.main()
