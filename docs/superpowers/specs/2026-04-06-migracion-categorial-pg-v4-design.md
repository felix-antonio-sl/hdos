# Migración Categorial Legacy → PostgreSQL v4

**Fecha**: 2026-04-06
**Estado**: Aprobado
**Prerequisito**: `docs/models/hodom-integrado-pg-v4.sql` (DDL, 100 tablas, 6 schemas)
**Complemento**: `docs/models/migracion-legacy-pg-v4.md` (inventario de fuentes y mapeo)

---

## 1. Objetivo

Migrar datos históricos HODOM (2025-01-01 → presente) desde múltiples fuentes heterogéneas hacia el schema PostgreSQL v4, implementando la migración como un **sistema de functores composables** con verificación formal de path equations.

Los datos estrictos en `db/hdos.db` (673 pacientes, 838 hospitalizaciones) son la **única verdad aceptada**. Todo lo demás enriquece dentro de ese universo.

---

## 2. Modelo Categorial

### 2.1 Operador de Migración

Colímite controlado por estrictos (Grothendieck `∫F`):

```
M = Σ_strict ∘ Π_canonical ∘ Π_intermediate ∘ Π_legacy

  Σ_strict      = fusión total (todo lo estricto entra)
  Π_canonical   = restricción al universo estricto + enriquecimiento de campos
  Π_intermediate = restricción al universo estricto + desglose dimensional
  Π_legacy      = restricción al universo estricto + extracción de dominios nuevos
```

### 2.2 Jerarquía de Confianza

| Índice | Confianza | Fuente |
|--------|-----------|--------|
| `strict` | 1.0 | `db/hdos.db` |
| `canonical` | 0.8 | `output/spreadsheet/canonical/` |
| `intermediate` | 0.6 | `output/spreadsheet/intermediate/` + `enriched/` |
| `legacy` | 0.4 | `documentacion-legacy/` |

### 2.3 Regla de Oro

Solo entran al PG registros cuyo `rut` aparezca en `strict.paciente` y cuyo par `(rut, fecha_ingreso)` aparezca en `strict.hospitalizacion`.

---

## 3. Framework Categorial

### 3.1 Abstracciones Core

```python
class PathEquation:
    name: str                       # "PE-F2-IDENTITY"
    sql: str                        # query que detecta violaciones
    expected: int | Literal["empty"] # "empty" = 0 filas, int = count exacto
    severity: Literal["critical", "warning"]
    # critical: fallo → ROLLBACK + HALT
    # warning: fallo → log + continúa (diagrama no conmuta pero no es bloqueante)
    
    def check(self, conn) -> tuple[bool, str]

class Functor:
    name: str                       # "F2_pacientes"
    depends_on: list[str]           # ["F0_bootstrap", "F1_territorial"]
    
    def objects(self, conn, sources) -> int
    def path_equations(self) -> list[PathEquation]
    def glue_equations(self) -> list[PathEquation]
    def verify(self, conn) -> tuple[bool, list[str]]

class NaturalTransformation:
    """η: Id_Source ⇒ M — proveniencia"""
    def record(self, conn, target_table, target_pk, source_type, 
               source_file, source_key, phase, field_name=None)

class ComposedFunctor:
    """G ∘ F con verificación de pegado"""
    phases: list[Functor]
    
    def run(self, conn, sources) -> MigrationReport
```

### 3.2 Contrato de Ejecución

Cada functor ejecuta atómicamente:

```
BEGIN;
  F_i.objects(conn, sources)           -- transforma y carga
  η_i.record(conn)                     -- registra proveniencia
  passed, diags = F_i.verify(conn)     -- verifica path equations
  IF NOT passed → ROLLBACK + HALT
  COMMIT;
```

Si F_i falla, todas las fases anteriores permanecen committed y consistentes. Se puede re-ejecutar F_i tras corregir.

### 3.3 Idempotencia

Cada functor ejecuta `DELETE FROM target WHERE EXISTS (SELECT 1 FROM migration_provenance WHERE phase = 'F_i' AND target_table = '...')` antes de insertar. Re-ejecución produce resultado idéntico.

---

## 4. Catálogo de Functores

### 4.1 Definición

```
F₀:  Bootstrap      ∅ → PG_v4(schemas + seed + strict staging)
F₁:  Territorial    CSV_canonical → territorial.{establecimiento, ubicacion}
F₂:  Pacientes      SQLite_strict ⊕ CSV_canonical → clinical.paciente
F₃:  Estadías       SQLite_strict ⊕ CSV_canonical → clinical.estadia
F₄:  Provenance     CSV_canonical → operational.estadia_episodio_fuente
F₅:  Clinical       CSV_intermediate → clinical.{condicion, requerimiento, necesidad}
F₆:  Profesionales  XLSX_legacy → operational.profesional
F₇:  Visitas        XLSX_legacy → operational.{visita, ruta}
F₈:  Documentos     XLSX+PDF_legacy → clinical.{epicrisis, documentacion}
F₉:  Operacional    XLSX+DOCX_legacy → operational.{llamada, turno, canasta}
F₁₀: Reporting      XLSX_legacy → reporting.kpi_diario
```

El operador `⊕` en F₂ y F₃ es un pushout sobre el pullback por RUT: strict prevalece, canonical enriquece campos que strict no tiene.

### 4.2 Grafo de Dependencias

```
F₀ ──→ F₁ ──→ F₂ ──→ F₃ ──→ F₄
              │       │
              ├──→ F₅ ┤
              │        ├──→ F₈
              └──→ F₆ ──→ F₇
                            │
                       F₉ ──┤
                            │
                       F₁₀ ─┘
```

Cada flecha = "destino requiere que origen haya completado con path equations verificadas".

### 4.3 Referencia Strict en PG

F₀ crea un schema `strict` y carga los datos de `db/hdos.db`:

```sql
CREATE SCHEMA IF NOT EXISTS strict;

CREATE TABLE strict.paciente (
    rut              TEXT PRIMARY KEY,
    nombre           TEXT NOT NULL,
    fecha_nacimiento DATE
);

CREATE TABLE strict.hospitalizacion (
    id               SERIAL PRIMARY KEY,
    rut_paciente     TEXT NOT NULL REFERENCES strict.paciente(rut),
    fecha_ingreso    DATE NOT NULL,
    fecha_egreso     DATE
);
```

Esto permite que todas las path equations operen enteramente en SQL contra la misma conexión PG.

---

## 5. Path Equations

### 5.1 F₂ (Pacientes) — 4 equations

| ID | Tipo | SQL (violaciones = 0 filas) |
|---|---|---|
| PE-F2-IDENTITY | critical | `SELECT rut FROM clinical.paciente WHERE rut NOT IN (SELECT rut FROM strict.paciente)` |
| PE-F2-SURJECTION | critical | `SELECT rut FROM strict.paciente WHERE rut NOT IN (SELECT rut FROM clinical.paciente)` |
| PE-F2-NAME-PRESERVE | critical | `SELECT p.rut FROM clinical.paciente p JOIN strict.paciente s ON s.rut = p.rut WHERE p.nombre_completo != s.nombre` |
| PE-F2-COUNT | critical | `SELECT COUNT(*) FROM clinical.paciente` → must equal 673 |

### 5.2 F₃ (Estadías) — 5 equations

| ID | Tipo | SQL |
|---|---|---|
| PE-F3-FK-COMMUTES | critical | `SELECT e.stay_id FROM clinical.estadia e JOIN clinical.paciente p ON p.patient_id = e.patient_id JOIN strict.hospitalizacion h ON h.rut_paciente = p.rut AND h.fecha_ingreso = e.fecha_ingreso WHERE h.fecha_egreso IS DISTINCT FROM e.fecha_egreso` |
| PE-F3-ANCHOR | critical | `SELECT e.stay_id FROM clinical.estadia e JOIN clinical.paciente p ON p.patient_id = e.patient_id WHERE NOT EXISTS (SELECT 1 FROM strict.hospitalizacion h WHERE h.rut_paciente = p.rut AND h.fecha_ingreso = e.fecha_ingreso)` |
| PE-F3-NO-ORPHAN | critical | `SELECT e.stay_id FROM clinical.estadia e LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id WHERE p.patient_id IS NULL` |
| PE-F3-DATE-ORDER | critical | `SELECT stay_id FROM clinical.estadia WHERE fecha_egreso IS NOT NULL AND fecha_egreso < fecha_ingreso` |
| PE-F3-COUNT | critical | `SELECT COUNT(*) FROM clinical.estadia` → must equal 838 |

### 5.3 Ecuaciones de Pegado (inter-functor)

| ID | Entre | SQL |
|---|---|---|
| GLUE-F1-F3 | F₁↔F₃ | `SELECT e.stay_id FROM clinical.estadia e WHERE e.establecimiento_id IS NOT NULL AND e.establecimiento_id NOT IN (SELECT establecimiento_id FROM territorial.establecimiento)` |
| GLUE-F2-F3 | F₂↔F₃ | (= PE-F3-NO-ORPHAN) |
| GLUE-F3-F4 | F₃↔F₄ | `SELECT f.source_id FROM operational.estadia_episodio_fuente f WHERE f.stay_id NOT IN (SELECT stay_id FROM clinical.estadia)` |
| GLUE-F3-F7 | F₃↔F₇ | `SELECT v.visit_id FROM operational.visita v WHERE v.stay_id IS NOT NULL AND v.stay_id NOT IN (SELECT stay_id FROM clinical.estadia)` |
| GLUE-F6-F7 | F₆↔F₇ | `SELECT v.visit_id FROM operational.visita v WHERE v.provider_id IS NOT NULL AND v.provider_id NOT IN (SELECT provider_id FROM operational.profesional)` |

---

## 6. Natural Transformation η (Proveniencia)

### 6.1 Tabla de Proveniencia

```sql
CREATE TABLE migration_provenance (
    target_table  TEXT NOT NULL,
    target_pk     TEXT NOT NULL,
    source_type   TEXT NOT NULL CHECK (source_type IN ('strict','canonical','intermediate','legacy')),
    source_file   TEXT NOT NULL,
    source_key    TEXT,
    phase         TEXT NOT NULL,
    field_name    TEXT,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (target_table, target_pk, phase, COALESCE(field_name, ''))
);
```

### 6.2 Semántica

- **Row-level** (`field_name = NULL`): "esta fila fue migrada por F_i desde source_file"
- **Field-level** (`field_name = 'sexo'`): "este campo fue enriquecido por F_i desde canonical"

Para F₂, η genera:
- 673 registros row-level (source_type='strict', source_file='db/hdos.db')
- N registros field-level por campo enriquecido (source_type='canonical')

---

## 7. Estructura de Código

```
scripts/migrate_to_pg/
  framework/
    __init__.py
    category.py           # Functor, PathEquation, NaturalTransformation, ComposedFunctor
    runner.py              # Orquestador: composición topológica
    provenance.py          # η: migration_provenance
    hash_ids.py            # IDs deterministas (extraído del pipeline)
  functors/
    __init__.py
    f0_bootstrap.py        # DDL + seed + strict staging
    f1_territorial.py      # establecimientos + ubicaciones
    f2_pacientes.py        # strict ⊕ canonical → paciente
    f3_estadias.py         # strict ⊕ canonical → estadia
    f4_provenance.py       # episode_source → estadia_episodio_fuente
    f5_clinical.py         # intermediate → condicion, requerimientos
    f6_profesionales.py    # legacy XLSX → profesional
    f7_visitas.py          # legacy → visitas + rutas
    f8_documentos.py       # legacy → epicrisis, documentacion
    f9_operacional.py      # legacy → llamadas, turnos, canasta
    f10_reporting.py       # legacy → kpi_diario
  run_migration.py         # CLI: --db-url, --phase, --dry-run
```

---

## 8. MigrationReport

```python
@dataclass
class PhaseReport:
    functor: str
    objects_migrated: int
    provenance_records: int
    equations_checked: int
    equations_passed: int
    violations: list[str]
    elapsed_seconds: float

@dataclass
class MigrationReport:
    phases: list[PhaseReport]
    total_objects: int
    total_equations: int
    all_passed: bool
    halted_at: str | None
```

---

## 9. Sprints de Implementación

| Sprint | Fases | Entregable |
|--------|-------|-----------|
| **1** (core) | framework/ + F₀ + F₁ + F₂ + F₃ + validación | PG con 673 pac + 838 estadías + territorial |
| **2** (enriquecimiento) | F₄ + F₅ + F₁₀ | Proveniencia + clínico + KPI |
| **3** (operacional) | F₆ + F₇ + F₈ + F₉ | Profesionales, visitas, documentos |

---

## 10. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | Divergencia IDs hash con pipeline | CRITICAL | Extraer función de `build_hodom_canonical.py`, reutilizar |
| R2 | Matching fuzzy nombre→RUT en legacy | HIGH | Cola de revisión manual para no-match, no insertar sin match |
| R3 | Solapamiento estadías vs EXCLUDE | HIGH | Detección previa, ajuste de rangos `[)` |
| R4 | Epicrisis PDF sin OCR | MEDIUM | Solo metadata en esta migración |
| R5 | 55/100 tablas vacías | LOW | Aceptable — dominios clínicos para captura futura |

---

## 11. Cobertura Target

```
Tablas PG v4:  100
  Poblables:    22  (22%)
  Seed DDL:     13  (13%)
  Derivables:    6  (6%)
  Sin datos:    55  (55%)
  Staging:       4  (strict.* + migration_provenance + migration_report)
                ──
  Total útil:   45/100 (45%)
```

---

## 12. Functor Information Loss

| Transformación | Información perdida |
|---|---|
| legacy XLSX → operational.visita | Layout visual, notas marginales, colores |
| epicrisis PDF → clinical.epicrisis | Contenido textual (sin OCR), firmas, sellos |
| multiple episodes → single estadia | Episodio específico que aportó cada campo (parcial en F₄) |
| canonical 1753 → 838 estrictas | 915 estadías descartadas por filtro estricto |
| entrega turno DOCX → operational | Narrativa libre, contexto no estructurado |
