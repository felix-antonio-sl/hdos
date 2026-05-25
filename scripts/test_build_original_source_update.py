import json
import unittest
from pathlib import Path

from scripts.build_original_source_update import (
    build_sql,
    load_cartera_rows,
    load_rem_snapshot,
)


ROOT = Path(__file__).resolve().parents[1]


class OriginalSourceUpdateTests(unittest.TestCase):
    def test_load_cartera_rows_skips_repeated_headers(self):
        source = Path("/home/felix/projects/hd-dt/02-cartera-y-prestaciones/cartera-servicios-hsc-2024.txt")

        rows = load_cartera_rows(source)

        self.assertEqual(len(rows), 2111)
        self.assertEqual(rows[0]["row_number"], 2)
        self.assertEqual(rows[0]["prestacion"], "Várices esofágicos, ligadura directa")
        self.assertEqual(rows[-1]["source_id"], "cartera_hsc_2024")
        self.assertTrue(all(row["prestacion"] != "PRESTACIÓN" for row in rows))

    def test_load_rem_snapshot_preserves_source_payload(self):
        source = Path("/home/felix/projects/hd-dt/05-gobernanza-datos/rem-a21-c1-abril-2026.json")

        snapshot = load_rem_snapshot(source)

        self.assertEqual(snapshot["snapshot_id"], "rem_a21_c1_hodom_hsc_2026_04")
        self.assertEqual(snapshot["periodo"], "2026-04")
        self.assertEqual(snapshot["payload"]["c_1_1_personas_atendidas"]["personas_atendidas"]["total"], 69)
        self.assertIsNone(snapshot["payload"]["c_1_1_personas_atendidas"]["fallecidos_esperados"])

    def test_build_sql_is_idempotent_and_contains_source_ids(self):
        cartera = load_cartera_rows(Path("/home/felix/projects/hd-dt/02-cartera-y-prestaciones/cartera-servicios-hsc-2024.txt"))
        rem = load_rem_snapshot(Path("/home/felix/projects/hd-dt/05-gobernanza-datos/rem-a21-c1-abril-2026.json"))

        sql = build_sql(cartera, rem)

        self.assertIn("CREATE TABLE IF NOT EXISTS reference.original_source", sql)
        self.assertIn("ON CONFLICT", sql)
        self.assertIn("cartera_hsc_2024", sql)
        self.assertIn("rem_a21_c1_hodom_hsc_2026_04", sql)
        self.assertGreater(sql.count("INSERT INTO reference.cartera_prestacion_hsc"), 0)
        json.loads(rem["payload_json"])


if __name__ == "__main__":
    unittest.main()
