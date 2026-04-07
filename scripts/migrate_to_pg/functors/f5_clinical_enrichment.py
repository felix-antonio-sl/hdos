# scripts/migrate_to_pg/functors/f5_clinical_enrichment.py
"""
F₅: Clinical Enrichment — intermediate CSVs → clinical.{plan_cuidado, requerimiento_cuidado,
                                                         necesidad_profesional, condicion}

Dependent on F₄ for the span:
  episode_id ← estadia_episodio_fuente → stay_id

The mapping episode_id → stay_id is many-to-one (multiple episodes consolidate into one stay).
For each stay, we create an implicit plan_cuidado, then attach requirements, needs, and conditions.

Functor Information Loss:
  - Multiple episodes may contribute the same requirement type; we deduplicate by (plan_id, tipo, valor).
  - The specific episode that contributed each datum is not preserved in the target tables
    (only the stay-level aggregation survives). Provenance records retain episode-level detail.

Sources:
  intermediate/episode_care_requirement.csv (4140, trust=0.6)
  intermediate/episode_professional_need.csv (1959, trust=0.6)
  intermediate/episode_diagnosis.csv (2426, trust=0.6)

Targets:
  clinical.plan_cuidado             — 1 per estadia (implicit default plan)
  clinical.requerimiento_cuidado    — O₂, categorización, Barthel, etc.
  clinical.necesidad_profesional    — enfermería, kinesiología, fonoaudiología
  clinical.condicion                — diagnósticos CIE-10 y texto libre
"""

from __future__ import annotations
import csv
from pathlib import Path

import psycopg

try:
    from ..framework.category import Functor, PathEquation
    from ..framework.provenance import NaturalTransformation
    from ..framework.hash_ids import make_id
except ImportError:
    from framework.category import Functor, PathEquation  # type: ignore[no-redef]
    from framework.provenance import NaturalTransformation  # type: ignore[no-redef]
    from framework.hash_ids import make_id  # type: ignore[no-redef]


class F5ClinicalEnrichment(Functor):
    name = "F5_clinical_enrichment"
    depends_on = ["F0_bootstrap", "F3_estadias", "F4_episode_source"]

    def objects(self, conn: psycopg.Connection, sources) -> int:
        eta = NaturalTransformation()

        # Idempotency
        conn.execute("DELETE FROM clinical.requerimiento_cuidado WHERE TRUE")
        conn.execute("DELETE FROM clinical.necesidad_profesional WHERE TRUE")
        conn.execute("DELETE FROM clinical.condicion WHERE TRUE")
        conn.execute("DELETE FROM clinical.plan_cuidado WHERE TRUE")

        # ── Step 1: Build episode_id → stay_id index from F₄ ──
        ep_to_stay: dict[str, str] = {}
        for episode_id, stay_id in conn.execute(
            "SELECT episode_id, stay_id FROM operational.estadia_episodio_fuente"
        ).fetchall():
            ep_to_stay[episode_id] = stay_id

        # ── Step 2: Create implicit plan_cuidado per estadia ──
        stay_ids = conn.execute("SELECT stay_id, fecha_ingreso, fecha_egreso FROM clinical.estadia").fetchall()
        plan_lookup: dict[str, str] = {}  # stay_id → plan_id

        for stay_id, fi, fe in stay_ids:
            plan_id = make_id("plan", f"{stay_id}|default")
            plan_lookup[stay_id] = plan_id
            conn.execute(
                """
                INSERT INTO clinical.plan_cuidado (plan_id, stay_id, estado, periodo_inicio, periodo_fin)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (plan_id) DO NOTHING
                """,
                (plan_id, stay_id, "activo" if fe is None else "completado", fi, fe),
            )

        n_plans = len(plan_lookup)

        # ── Step 3: Requerimientos de cuidado ──
        n_reqs = self._load_requirements(conn, sources, ep_to_stay, plan_lookup, eta)

        # ── Step 4: Necesidades profesionales ──
        n_needs = self._load_needs(conn, sources, ep_to_stay, plan_lookup, eta)

        # ── Step 5: Condiciones / diagnósticos ──
        n_conds = self._load_conditions(conn, sources, ep_to_stay, eta)

        return n_plans + n_reqs + n_needs + n_conds

    def _load_requirements(self, conn, sources, ep_to_stay, plan_lookup, eta) -> int:
        path = sources.intermediate_dir / "episode_care_requirement.csv"
        if not path.exists():
            return 0

        seen: set[tuple[str, str, str]] = set()  # (plan_id, tipo, valor) dedup
        n = 0

        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                episode_id = row.get("episode_id", "").strip()
                stay_id = ep_to_stay.get(episode_id)
                if not stay_id:
                    continue
                plan_id = plan_lookup.get(stay_id)
                if not plan_id:
                    continue

                tipo = row.get("requirement_type", "").strip() or None
                valor = row.get("requirement_value_norm", "").strip()
                if not valor:
                    valor = row.get("requirement_value_raw", "").strip()
                if not tipo or not valor:
                    continue

                dedup_key = (plan_id, tipo, valor)
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)

                req_id = make_id("req", f"{plan_id}|{tipo}|{valor}")
                is_active = row.get("is_active", "").strip().upper() in ("TRUE", "1", "SI", "YES", "")

                conn.execute(
                    """
                    INSERT INTO clinical.requerimiento_cuidado (req_id, plan_id, tipo, valor_normalizado, activo)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (req_id) DO NOTHING
                    """,
                    (req_id, plan_id, tipo, valor, is_active),
                )

                eta.record(
                    conn,
                    target_table="clinical.requerimiento_cuidado",
                    target_pk=req_id,
                    source_type="intermediate",
                    source_file="episode_care_requirement.csv",
                    source_key=f"{episode_id}|{tipo}",
                    phase="F5",
                    field_name="requirement",
                )
                n += 1

        return n

    def _load_needs(self, conn, sources, ep_to_stay, plan_lookup, eta) -> int:
        path = sources.intermediate_dir / "episode_professional_need.csv"
        if not path.exists():
            return 0

        seen: set[tuple[str, str]] = set()  # (plan_id, profesion) dedup
        n = 0

        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                episode_id = row.get("episode_id", "").strip()
                stay_id = ep_to_stay.get(episode_id)
                if not stay_id:
                    continue
                plan_id = plan_lookup.get(stay_id)
                if not plan_id:
                    continue

                profesion = row.get("professional_type", "").strip()
                if not profesion:
                    continue

                nivel = row.get("need_level", "").strip() or None

                dedup_key = (plan_id, profesion)
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)

                need_id = make_id("need", f"{plan_id}|{profesion}")

                conn.execute(
                    """
                    INSERT INTO clinical.necesidad_profesional (need_id, plan_id, profesion_requerida, nivel_necesidad)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (need_id) DO NOTHING
                    """,
                    (need_id, plan_id, profesion, nivel),
                )

                eta.record(
                    conn,
                    target_table="clinical.necesidad_profesional",
                    target_pk=need_id,
                    source_type="intermediate",
                    source_file="episode_professional_need.csv",
                    source_key=f"{episode_id}|{profesion}",
                    phase="F5",
                    field_name="need",
                )
                n += 1

        return n

    def _load_conditions(self, conn, sources, ep_to_stay, eta) -> int:
        path = sources.intermediate_dir / "episode_diagnosis.csv"
        if not path.exists():
            return 0

        seen: set[tuple[str, str, str]] = set()  # (stay_id, code, desc) dedup
        n = 0

        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                episode_id = row.get("episode_id", "").strip()
                stay_id = ep_to_stay.get(episode_id)
                if not stay_id:
                    continue

                # Get patient_id for this stay
                patient_row = conn.execute(
                    "SELECT patient_id FROM clinical.estadia WHERE stay_id = %s",
                    (stay_id,),
                ).fetchone()
                if not patient_row:
                    continue
                patient_id = patient_row[0]

                codigo = row.get("cie10_code", "").strip() or None
                desc_raw = row.get("diagnosis_text_norm", "").strip()
                if not desc_raw:
                    desc_raw = row.get("diagnosis_text_raw", "").strip()
                if not desc_raw and not codigo:
                    continue

                dedup_key = (stay_id, codigo or "", desc_raw)
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)

                cond_id = make_id("cond", f"{stay_id}|{codigo or ''}|{desc_raw}")
                role = row.get("diagnosis_role", "").strip()
                estado = "activo" if role == "principal" else "resuelto"

                conn.execute(
                    """
                    INSERT INTO clinical.condicion
                        (condition_id, stay_id, patient_id, codigo_cie10, descripcion, estado_clinico)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (condition_id) DO NOTHING
                    """,
                    (cond_id, stay_id, patient_id, codigo, desc_raw, estado),
                )

                eta.record(
                    conn,
                    target_table="clinical.condicion",
                    target_pk=cond_id,
                    source_type="intermediate",
                    source_file="episode_diagnosis.csv",
                    source_key=f"{episode_id}|{codigo or desc_raw[:30]}",
                    phase="F5",
                    field_name="diagnosis",
                )
                n += 1

        return n

    def path_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="PE-F5-PLAN-PER-STAY",
                sql="""SELECT stay_id, COUNT(*) FROM clinical.plan_cuidado
                    GROUP BY stay_id HAVING COUNT(*) > 1""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F5-REQ-FK-PLAN",
                sql="""SELECT r.req_id FROM clinical.requerimiento_cuidado r
                    LEFT JOIN clinical.plan_cuidado p ON p.plan_id = r.plan_id
                    WHERE p.plan_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F5-NEED-FK-PLAN",
                sql="""SELECT n.need_id FROM clinical.necesidad_profesional n
                    LEFT JOIN clinical.plan_cuidado p ON p.plan_id = n.plan_id
                    WHERE p.plan_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F5-COND-FK-STAY",
                sql="""SELECT c.condition_id FROM clinical.condicion c
                    LEFT JOIN clinical.estadia e ON e.stay_id = c.stay_id
                    WHERE e.stay_id IS NULL""",
                expected="empty",
            ),
            PathEquation(
                name="PE-F5-COND-FK-PATIENT",
                sql="""SELECT c.condition_id FROM clinical.condicion c
                    LEFT JOIN clinical.paciente p ON p.patient_id = c.patient_id
                    WHERE p.patient_id IS NULL""",
                expected="empty",
            ),
        ]

    def glue_equations(self) -> list[PathEquation]:
        return [
            PathEquation(
                name="GLUE-F4-F5-SPAN",
                sql="""SELECT r.req_id FROM clinical.requerimiento_cuidado r
                    JOIN clinical.plan_cuidado pc ON pc.plan_id = r.plan_id
                    LEFT JOIN operational.estadia_episodio_fuente eef
                        ON eef.stay_id = pc.stay_id
                    WHERE eef.stay_id IS NULL""",
                expected="empty",
                severity="warning",
            ),
        ]
