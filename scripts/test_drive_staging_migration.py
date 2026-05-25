import tempfile
import unittest
from datetime import datetime, time
from pathlib import Path

from openpyxl import Workbook


ROOT = Path(__file__).resolve().parents[1]
MIGRATION_SQL = ROOT / "db" / "updates" / "2026-05-25-drive-staging-migration.sql"


class DriveStagingMigrationTests(unittest.TestCase):
    def test_drive_staging_sql_defines_idempotent_tables(self):
        sql = MIGRATION_SQL.read_text(encoding="utf-8")

        self.assertIn("CREATE SCHEMA IF NOT EXISTS staging", sql)
        self.assertIn("CREATE TABLE IF NOT EXISTS staging.drive_source_file", sql)
        self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_route_visit", sql)
        self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_shift_handover", sql)
        self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_annual_metric", sql)
        self.assertIn("ON CONFLICT", sql)

    def test_parse_route_workbook_rows_extracts_date_and_visit_fields(self):
        from scripts.drive_staging_migration import parse_route_workbook

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "visitas.xlsx"
            wb = Workbook()
            ws = wb.active
            ws.title = "31.01"
            ws.append([datetime(2026, 1, 31), None, "MEDICO ", "FONO", "KINE", "ENFERMERA", "TENS"])
            ws.append(["CONDUCTOR TEST", time(8, 0), None, None, "KINE TEST", None, None, "PACIENTE TEST", "KTM", "DIRECCION TEST", "TELEFONO TEST"])
            wb.save(path)

            rows = parse_route_workbook(path, {"drive_id": "file1", "path": "rutas/ENERO.xlsx", "year": 2026, "month": 1})

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["visit_date"], "2026-01-31")
        self.assertEqual(rows[0]["patient_name"], "PACIENTE TEST")
        self.assertEqual(rows[0]["professionals"]["kine"], "KINE TEST")
        self.assertEqual(rows[0]["service_text"], "KTM")

    def test_build_sql_batch_quotes_values_and_includes_route_rows(self):
        from scripts.drive_staging_migration import build_sql_batch

        sql = build_sql_batch(
            files=[
                {
                    "drive_id": "file1",
                    "folder_url": "https://drive.google.com/drive/folders/root",
                    "path": "rutas/ENERO.xlsx",
                    "title": "ENERO.xlsx",
                    "mime_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    "dataset": "rutas",
                    "year": 2026,
                    "month": 1,
                    "local_path": ".tmp/raw/ENERO.xlsx",
                    "sha256": "abc",
                    "size_bytes": 10,
                    "metadata": {"sheet_count": 1},
                }
            ],
            route_rows=[
                {
                    "route_visit_id": "drv_visit_123",
                    "drive_id": "file1",
                    "source_path": "rutas/ENERO.xlsx",
                    "sheet_name": "31.01",
                    "source_row_number": 2,
                    "visit_date": "2026-01-31",
                    "driver_name": "CONDUCTOR TEST",
                    "planned_time": "08:00",
                    "patient_name": "PACIENTE TEST",
                    "service_text": "KTM",
                    "address_text": "DIRECCION TEST",
                    "phone_text": "TELEFONO TEST",
                    "professionals": {"kine": "KINE TEST"},
                    "raw_record": {"row": 2},
                }
            ],
            handovers=[],
            annual_metrics=[],
            rem_snapshots=[],
        )

        self.assertIn("INSERT INTO staging.drive_source_file", sql)
        self.assertIn("INSERT INTO staging.hodom_route_visit", sql)
        self.assertIn("drv_visit_123", sql)
        self.assertIn("KINE TEST", sql)


if __name__ == "__main__":
    unittest.main()
