"""Tests for hodom_ingreso_2026_staging parser."""
import unittest
from datetime import date, datetime

from hodom_ingreso_2026_staging import (
    norm_rut, parse_date, flag_estado, flag_categorizacion,
    parse_sexo, parse_bool, norm_text, parse_edad, compute_row_hash,
)


class RUTNormalizationTests(unittest.TestCase):
    def test_standard_rut(self):
        rut, flag = norm_rut("11444532-0")
        self.assertEqual(rut, "11444532-0")
        self.assertIsNone(flag)

    def test_rut_with_dots(self):
        rut, flag = norm_rut("9.441.281-1")
        self.assertEqual(rut, "9441281-1")
        self.assertIsNone(flag)

    def test_rut_with_dots_and_comma(self):
        rut, flag = norm_rut("4.427.580-5")
        self.assertEqual(rut, "4427580-5")
        self.assertIsNone(flag)

    def test_rut_with_k_verifier(self):
        rut, flag = norm_rut("3977867-K")
        self.assertEqual(rut, "3977867-K")
        self.assertIsNone(flag)

    def test_rut_with_k_and_dots(self):
        rut, flag = norm_rut("14.303.772-K")
        self.assertEqual(rut, "14303772-K")
        self.assertIsNone(flag)

    def test_empty_rut(self):
        rut, flag = norm_rut("")
        self.assertIsNone(rut)
        self.assertEqual(flag, "RUT_VACIO")

    def test_none_rut(self):
        rut, flag = norm_rut(None)
        self.assertIsNone(rut)
        self.assertEqual(flag, "RUT_VACIO")

    def test_digit_k_variants(self):
        rut, flag = norm_rut("9526087-k")
        self.assertEqual(rut, "9526087-K")
        self.assertIsNone(flag)


class DateParsingTests(unittest.TestCase):
    def test_datetime_object(self):
        d, f = parse_date(datetime(2026, 1, 2))
        self.assertEqual(d, date(2026, 1, 2))
        self.assertIsNone(f)

    def test_date_object(self):
        d, f = parse_date(date(2026, 5, 7))
        self.assertEqual(d, date(2026, 5, 7))
        self.assertIsNone(f)

    def test_formula_text(self):
        d, f = parse_date("=D2-C2")
        self.assertIsNone(d)
        self.assertEqual(f, "FECHA_FORMULA")

    def test_garbled_date(self):
        d, f = parse_date("15-01-19458")
        self.assertIsNone(d)
        self.assertEqual(f, "FECHA_ANO_ANOMALO")

    def test_dd_mm_yyyy_string(self):
        d, f = parse_date("03-06-1996")
        self.assertEqual(d, date(1996, 6, 3))
        self.assertIsNone(f)

    def test_none(self):
        d, f = parse_date(None)
        self.assertIsNone(d)
        self.assertIsNone(f)


class EstadoTests(unittest.TestCase):
    def test_egresado_ok(self):
        self.assertIsNone(flag_estado("EGRESADO"))

    def test_typo_egresadc(self):
        self.assertEqual(flag_estado("EGRESADC"), "ESTADO_TYPO")

    def test_fallecido_ok(self):
        self.assertIsNone(flag_estado("FALLECIDO"))

    def test_vacio(self):
        self.assertEqual(flag_estado(None), "ESTADO_VACIO")


class CategorizacionTests(unittest.TestCase):
    def test_complejo_ok(self):
        self.assertIsNone(flag_categorizacion("COMPLEJO"))

    def test_intermedio_ok(self):
        self.assertIsNone(flag_categorizacion("INTERMEDIO"))

    def test_typo_cmplejo(self):
        self.assertEqual(flag_categorizacion("CMPLEJO"), "CATEGORIZACION_TYPO")

    def test_vacia(self):
        self.assertEqual(flag_categorizacion(None), "CATEGORIZACION_VACIA")


class ConversionTests(unittest.TestCase):
    def test_sexo_m(self):
        self.assertEqual(parse_sexo("M"), "M")
        self.assertEqual(parse_sexo("MASCULINO"), "M")

    def test_sexo_f(self):
        self.assertEqual(parse_sexo("F"), "F")

    def test_sexo_none(self):
        self.assertIsNone(parse_sexo(None))

    def test_bool_si(self):
        self.assertTrue(parse_bool("SI"))

    def test_bool_no(self):
        self.assertFalse(parse_bool("NO"))

    def test_bool_none(self):
        self.assertIsNone(parse_bool(None))

    def test_text_normal(self):
        self.assertEqual(norm_text("  FONASA B "), "FONASA B")

    def test_text_none(self):
        self.assertIsNone(norm_text(None))

    def test_text_empty(self):
        self.assertIsNone(norm_text(""))

    def test_edad_int(self):
        self.assertEqual(parse_edad(57), 57)
        self.assertEqual(parse_edad(57.0), 57)

    def test_edad_string(self):
        self.assertEqual(parse_edad("70"), 70)

    def test_edad_impossible(self):
        self.assertIsNone(parse_edad(150))
        self.assertIsNone(parse_edad(-1))


class HashTests(unittest.TestCase):
    def test_deterministic_hash(self):
        d1 = {"a": 1, "b": "test"}
        d2 = {"b": "test", "a": 1}
        h1 = compute_row_hash(d1)
        h2 = compute_row_hash(d2)
        self.assertEqual(h1, h2)

    def test_different_hash(self):
        h1 = compute_row_hash({"a": 1})
        h2 = compute_row_hash({"a": 2})
        self.assertNotEqual(h1, h2)


if __name__ == "__main__":
    unittest.main()
