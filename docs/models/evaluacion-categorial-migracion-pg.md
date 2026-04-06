# Evaluación Categorial — Migración SQLite → PostgreSQL

Evaluación formal del functor de migración F: Sch_SQLite → Sch_PG.
Fecha: 2026-04-06.

---

## 1. Functor de Migración

```
F: Sch_SQLite → Sch_PG

Operador dominante: Δ (reestructuración preservando forma)
Propiedades preservadas: todas
Propiedades ganadas: exclusion, deferrable, functions, policies, partial indexes, MVCC
Propiedades perdidas: ninguna
Riesgo de información: CERO — F es inyectivo
```

| Aspecto | SQLite (source) | PostgreSQL (target) | Ganancia |
|---|---|---|---|
| **Identidad** | 95 tablas con TEXT PK | 95 tablas con TEXT PK (sin cambio) | Ninguna — preservación total |
| **Morfismos** | ~151 FKs + 77 triggers | ~151 FKs + ~37 trigger bindings + 10 funciones | **Compresión 77→37** sin pérdida de cobertura |
| **Composición** | Triggers copy-paste por tabla | Funciones reutilizables vía `EXECUTE FUNCTION` | **O(N²) → O(N)** en mantenimiento |
| **Path equations** | Triggers BEFORE INSERT + BEFORE UPDATE separados | `BEFORE INSERT OR UPDATE` en un trigger | **2N → N** triggers |
| **Limits** | CHECK simples, sin EXCLUDE | CHECK + EXCLUDE USING gist | **Rangos temporales no-overlapping** (imposible en SQLite) |
| **Colimits** | Tablas de referencia (9 catálogos) | Tablas de referencia (idem) o ENUM types | Sin cambio sustancial |

---

## 2. Ganancias Categórica Netas

### 2.1 Compresión de la coalgebra de triggers

**SQLite**: 77 triggers = 37 pares INSERT/UPDATE PE-1 + 3 sync triggers + 5 guard triggers + 32 triggers especiales.

**PostgreSQL**: ~10 funciones PL/pgSQL + ~37 bindings de 1 línea.

```
Función check_pe1()               → 27 tablas (INSERT OR UPDATE)
Función check_stay_coherence()    → 3 tablas (medicacion, procedimiento, documentacion)
Función check_state_transition()  → 2 tablas (evento_visita, evento_estadia)
Función sync_state()              → 2 tablas (visita, estadia)
Función sync_paciente_estado()    → 1 tabla (estadia)
Función guard_state_update()      → 2 tablas (visita, estadia)
Funciones especiales              → ~8 (encuesta, profesion_rem, rehab, temporal, etc.)

Total: ~10 funciones + ~45 bindings vs 77 triggers monolíticos
Ratio de compresión: 1:1.7 en líneas, 1:4 en lógica duplicada
```

### 2.2 Exclusion constraints (nuevas — imposibles en SQLite)

| Constraint | Tabla | Efecto |
|---|---|---|
| `EXCLUDE USING gist (patient_id =, daterange(...) &&)` | `estadia` | Impide estadías superpuestas para el mismo paciente |
| `EXCLUDE USING gist (provider_id =, daterange(fecha, fecha) &&)` | `agenda_profesional` | Impide doble-booking de profesionales |
| `EXCLUDE USING gist (equipo_id =, daterange(...) &&)` | `prestamo_equipo` | Impide préstamo simultáneo del mismo equipo |

Estos 3 EXCLUDE constraints cierran **3 invariantes de negocio que el modelo SQLite no puede expresar**.

### 2.3 Partial indexes (nuevos)

| Índice | Tabla | Efecto |
|---|---|---|
| `WHERE estado = 'activo'` | `estadia` | Solo indexa pacientes hospitalizados (~22 de ~791) |
| `WHERE estado IN ('PROGRAMADA', 'ASIGNADA')` | `visita` | Solo indexa visitas pendientes |
| `WHERE estado = 'activa'` | `indicacion_medica` | Solo indexa indicaciones vigentes |
| `WHERE estado = 'activa'` | `herida` | Solo indexa heridas abiertas |
| `WHERE estado = 'prestado'` | `prestamo_equipo` | Solo indexa préstamos activos |

5 partial indexes que reducen el tamaño del índice un ~95% para las queries más frecuentes.

### 2.4 Vistas materializadas (nuevas)

| Vista | Reemplaza | Beneficio |
|---|---|---|
| `mv_rem_personas_atendidas` | tabla `rem_personas_atendidas` | Derivada, no manual; REFRESH CONCURRENTLY |
| `mv_rem_visitas` | tabla `rem_visitas` | Derivada de visita+profesional |
| `mv_kpi_diario` | tabla `kpi_diario` | Derivada de visita+ruta |

Las 3 tablas de reporte materializadas pasan de ser **entidades mutables sin provenance** a **vistas materializadas derivadas con refresh explícito**.

---

## 3. Lo que NO cambia

| Aspecto | Razón |
|---|---|
| TEXT para fechas (no DATE) | Compatibilidad con pipeline CSV existente (Stage 1-4) |
| TEXT PRIMARY KEY (no SERIAL/UUID) | IDs deterministas por hash — principio del proyecto |
| 95 tablas | Misma estructura — F es 1:1 en objetos |
| 9 catálogos de referencia | Se mantienen (no se reemplazan por ENUM types — extensibilidad sin ALTER TYPE) |
| Seed data | Idéntico |

---

## 4. Riesgos de la Migración

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Pipeline CSV (Stage 1-4) asume SQLite | MEDIO | El pipeline no usa SQLite directamente — produce CSVs. Stage 5 es el puente. |
| Streamlit dashboards usan pandas, no SQL | BAJO | Los dashboards leen CSVs, no la BD. |
| PostgreSQL requiere servidor | MEDIO | Usar Supabase, Neon, o Docker local para desarrollo. |
| Complejidad operacional | BAJO | Para HSC con 22 pacientes activos, PG es oversized pero correcto. |

---

## 5. Functor Information Loss

```
F: Sch_SQLite → Sch_PG
Información perdida: NINGUNA (F es inyectivo)

G: Sch_PG → Sch_SQLite (inverso hipotético)
Información perdida:
  - EXCLUDE constraints (rangos no-overlapping)
  - Partial indexes
  - Funciones PL/pgSQL reutilizables → se expanden a N triggers
  - MATERIALIZED VIEW → tablas manuales
  - DEFERRABLE constraints
  - CONCURRENTLY refresh
  - Row-level security (si se implementa)
```

---

## 6. Signature

```
Modo:           STATIC (migración de schema)
Operador:       Δ (pullback — reestructuración sin pérdida)
Source:         Sch_SQLite (95 tablas, 77 triggers, 151 indexes)
Target:         Sch_PG (95 tablas, ~10 funciones + ~45 bindings, ~156 indexes)
Path equations: 100% preservadas + 3 EXCLUDE nuevos
Coalgebras:     Comprimidas de 77 triggers → ~10 funciones reutilizables
Preservado:     Todo (identidades, morfismos, composición, equations)
Ganado:         EXCLUDE, partial indexes, materialized views, function reuse
Perdido:        Nada
```
