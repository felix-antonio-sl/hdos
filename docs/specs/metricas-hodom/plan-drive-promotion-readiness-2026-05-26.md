# Drive Promotion Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an auditable readiness layer that evaluates which Drive staging records can be promoted to HODOM core tables and which records remain blocked.

**Architecture:** Keep nominal data in PostgreSQL only. Version SQL view definitions, tests, and documentation; do not export route rows, handover text, names, addresses, phone numbers, or patient identifiers. Use deterministic non-destructive views under `staging` so promotion decisions can be reviewed before any insert into `clinical` or `operational`.

**Tech Stack:** PostgreSQL SQL views/functions, Python `unittest`, local `psql`, existing `staging.hodom_route_visit`, `staging.hodom_shift_handover`, `clinical.paciente`, `clinical.estadia`, `operational.visita`, and `migration.provenance`.

---

### Task 1: SQL Readiness Contract

**Files:**
- Create: `db/updates/2026-05-26-drive-promotion-readiness.sql`
- Test: `scripts/test_drive_promotion_readiness.py`

- [x] **Step 1: Write failing SQL contract test**

```python
def test_readiness_sql_defines_required_views(self):
    sql = MIGRATION_SQL.read_text(encoding="utf-8")
    self.assertIn("CREATE OR REPLACE FUNCTION staging.norm_text", sql)
    self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_candidate", sql)
    self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_route_promotion_summary", sql)
    self.assertIn("CREATE OR REPLACE VIEW staging.v_hodom_handover_promotion_summary", sql)
```

- [x] **Step 2: Run failing test**

Run: `python3 -m unittest scripts/test_drive_promotion_readiness.py`.
Expected: FAIL because the SQL file does not exist yet.

- [x] **Step 3: Add SQL contract**

Create:
- `staging.norm_text(text)` for deterministic uppercase whitespace/accent normalization.
- `staging.v_hodom_route_promotion_candidate` with route row ID, date, non-exported matching counters, candidate IDs, deterministic target visit ID and `match_status`.
- `staging.v_hodom_route_promotion_summary` with aggregate counts by year, month and `match_status`.
- `staging.v_hodom_handover_promotion_summary` with aggregate period/text readiness counts.

- [x] **Step 4: Run SQL contract test**

Run: `python3 -m unittest scripts/test_drive_promotion_readiness.py`.
Expected: PASS.

### Task 2: Apply Readiness Layer

**Files:**
- Apply: `db/updates/2026-05-26-drive-promotion-readiness.sql`

- [x] **Step 1: Apply SQL**

Run: `PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-promotion-readiness.sql`.
Expected: `COMMIT`.

- [x] **Step 2: Verify aggregate route readiness**

Run:

```sql
select match_status, sum(route_rows)
from staging.v_hodom_route_promotion_summary
group by match_status
order by match_status;
```

Expected: aggregate-only rows, no names, addresses or phone numbers.

- [x] **Step 3: Verify handover readiness**

Run:

```sql
select total_handovers, with_period, with_text, missing_period
from staging.v_hodom_handover_promotion_summary;
```

Expected: one aggregate-only row.

### Task 3: Documentation And Handoff

**Files:**
- Modify: `docs/specs/metricas-hodom/README.md`
- Modify: `docs/specs/metricas-hodom/handoff-2026-05-25.md`

- [x] **Step 1: Update README**

Add `db/updates/2026-05-26-drive-promotion-readiness.sql` and this plan to the normative artifact list.

- [x] **Step 2: Update handoff**

Document:
- readiness views applied;
- aggregate route readiness results;
- handover readiness results;
- explicit decision that core promotion is still blocked until patient/stay matching is reviewed;
- next prompt for promotion-rule refinement.

- [x] **Step 3: Verify**

Run:

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
git diff --check
```

Expected: all tests pass and diff check is clean.
