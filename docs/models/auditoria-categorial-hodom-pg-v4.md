# Auditoría Categorial v4 — DDL PostgreSQL HODOM

Auditoría formal conforme a FXSL Categorical Audit Patterns.
Fecha: 2026-04-06. Auditoría exhaustiva del DDL PostgreSQL post-migración desde SQLite.

> **ESTADO: TODOS LOS ISSUES RESUELTOS** — ver `hodom-integrado-pg-v4.sql` (3616 líneas, 100 tablas, 6 schemas, 54 triggers, 7 views, 3 MVs, RBAC+RLS).

Artefacto auditado: `hodom-integrado-pg.sql` (4137 líneas)

**Método**: Auditoría secuencial STATIC + BEHAVIORAL + MIGRATION contra el artefacto completo.
Baseline: `auditoria-categorial-hodom-v3.md` (45 issues sobre SQLite, 87 tablas).

---

## 1. Clasificación DIK

| Atributo | Valor |
|---|---|
| DIK Level | **INFORMATION** (schema S) + **KNOWLEDGE** (coalgebras, guards, path equations, materialized views) |
| Type | SCHEMA (DDL PostgreSQL ≥14, PL/pgSQL) |
| Dominio | Sistema completo de hospitalización domiciliaria, HSC Ñuble |
| Construcción | Pushout sobre I = {clínica, operacional, territorial, reporte} + 14 dominios funcionales + telemetría GPS |
| Entidades | 98 tablas únicas + 8 catálogos de referencia + 6 definiciones duplicadas (dead code) |
| Trigger functions | 22 (19 funciones documentadas + 3 telemetría) |
| Trigger bindings | 48 (45 documentados + 3 telemetría) |
| Views | 7 regulares + 3 materializadas |
| Indexes | 163+ (incluyendo 5 partial, 3 GIN/GiST, 3 unique MV) |
| Identity keys | 9 (patient_id, stay_id, visit_id, provider_id, order_id, location_id, zone_id, establecimiento_id, device_id) |
| Normativa | DS 41/2012, Ley 20.584, Decreto 31/2024, DS 1/2022, Ley 21.375, DS 466/1984, Ley 19.966, Res. Exenta 643/2019 |

---

## 2. Estado de Reparaciones v3

De los 45 issues identificados en la auditoría v3 (SQLite):

| Severidad | Total v3 | Reparados en PG | Pendientes | Parciales |
|---|---|---|---|---|
| CRITICAL | 11 | **11** | 0 | 0 |
| HIGH | 16 | **12** | 4 | 0 |
| MEDIUM | 10 | **8** | 1 | 1 |
| LOW | 8 | **7** | 1 | 0 |
| **Total** | **45** | **38** | **6** | **1** |

**Tasa de reparación: 84% (38/45).** Todos los CRITICAL reparados.

### Issues v3 pendientes en PG

| v3 # | Sev. | Descripción | Estado PG |
|---|---|---|---|
| R4 | HIGH | `lista_espera.establecimiento_origen` TEXT libre | **PENDIENTE** — sin REFERENCES a establecimiento |
| R5 | HIGH | `paciente.cesfam` TEXT libre | **PENDIENTE** — sin REFERENCES a catálogo APS |
| B4 | HIGH | 20+ máquinas de estado "soft" sin enforcement | **PENDIENTE** — solo visita y estadia tienen coalgebra completa |
| M1 | HIGH | DDL nunca poblado con datos reales | **PENDIENTE** — 48 triggers sin validación empírica |
| M2 | HIGH | Functor Σ para PROGRAMACIÓN legacy sin especificar | **PENDIENTE** |
| B7 | MEDIUM | Vocabulario `prioridad` fragmentado en 5 tablas | **PENDIENTE** |
| S6 | MEDIUM | protocolo_fallecimiento.tipo vs estadia.tipo_egreso — mapping semántico | **PARCIAL** — trigger E6 valida que estadia ES de fallecido, pero no cross-valida `esperado` ↔ `fallecido_esperado` |

---

## 3. Resumen Diagnóstico v4

| Dimensión | Estado | Issues nuevos (PG) | Issues heredados (v3) |
|---|---|---|---|
| Structural | **FAIL** | 4 CRITICAL, 3 HIGH | 0 CRITICAL, 0 HIGH |
| Referential | **FAIL** | 2 CRITICAL, 1 HIGH | 0 CRITICAL, 2 HIGH |
| Behavioral | **WARN** | 1 CRITICAL, 2 HIGH | 0 CRITICAL, 2 HIGH |
| Completeness | **WARN** | 2 HIGH, 3 MEDIUM | 0 HIGH, 1 MEDIUM |
| Quality | **INFO** | 0 HIGH, 5 MEDIUM | 0 |
| Migration | **FAIL** | 3 CRITICAL, 1 HIGH | 0 CRITICAL, 2 HIGH |

**Total: 10 CRITICAL, 16 HIGH, 9 MEDIUM, 0 LOW = 35 issues**

(vs 45 en v3. Menos issues totales, pero los nuevos son graves — muchos son defectos de migración SQLite→PG que invalidan el DDL antes de ejecutarlo.)

---

## 4. Issues Detectados

### 4.1 STRUCTURAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-S1 | **CRITICAL** | CHECK-PATH-EQUALITY | **`rem_reportable = 1` en vistas y MVs — type mismatch en PostgreSQL.** `visita.rem_reportable` es `BOOLEAN`. En PG, `BOOLEAN = INTEGER` es un error de tipo. `v_consolidado_atenciones_diarias` (L3411) y `mv_kpi_diario` (L3565) fallarán al crearse. Deben usar `rem_reportable = TRUE` o `rem_reportable IS TRUE`. **El DDL no se puede ejecutar completo tal cual.** | L3411, L3565 |
| PG-S2 | **CRITICAL** | CHECK-IDENTITY | **6 definiciones de tablas duplicadas (dead code).** Las siguientes tablas están definidas DOS VECES en el script: `requerimiento_orden_mapping` (L1040 + L1117), `evento_estadia` (L1048 + L1126), `orden_servicio_insumo` (L1070 + L1147), `zona_profesional` (L1079 + L1157), `estadia_episodio_fuente` (L1087 + L1166), `maquina_estados_estadia_ref` (L1017 + L2613). Además, `vehiculo` (L706 + L2036) y `conductor` (L728 + L2059) están duplicadas en Dominio I. El `IF NOT EXISTS` previene errores, pero las definiciones duplicadas tienen **DEFAULT syntax inconsistente**: Part 1 usa `(NOW() AT TIME ZONE 'UTC')::TEXT`, Part 2 usa `(NOW() AT TIME ZONE 'UTC')` sin cast. Esto es dead code que genera confusión sobre cuál es la definición canónica. | L1107-1172, L2036-2070, L2613-2629 |
| PG-S3 | **CRITICAL** | CHECK-PATH-EQUALITY | **`encuesta_satisfaccion` NO tiene trigger PE-1.** El comentario en L3275-3281 menciona que se debería agregar, pero **nunca se crea el binding**. Las 26 tablas con PE-1 binding excluyen a `encuesta_satisfaccion`. Un INSERT con `patient_id` ≠ `estadia(stay_id).patient_id` pasa sin error. | L3275-3282 |
| PG-S4 | **CRITICAL** | CHECK-PATH-EQUALITY | **`check_stay_coherence()` solo está vinculado a 2 de 6+ tablas donde aplica.** Tablas con BOTH `visit_id` AND `stay_id` donde la coherencia stay↔visita no está enforced: `observacion`, `nota_evolucion`, `sesion_rehabilitacion`, `educacion_paciente`. Estas 4 tablas pueden tener `stay_id` que contradice `visita(visit_id).stay_id`. | L496, L1390, L1418, L1897 |
| PG-S5 | HIGH | CHECK-PATH-EQUALITY | **`condicion` sin `patient_id`.** Solo tiene `stay_id`. Requiere 2 hops (condicion→estadia→paciente) para llegar al paciente. No fue reparado en PG a diferencia de `procedimiento` (S8 de v3) y `observacion` (S7 de v3). | L416-425 |
| PG-S6 | HIGH | CHECK-PATH-EQUALITY | **`plan_cuidado` sin CHECK `periodo_fin >= periodo_inicio`.** El issue S4 de v3 se reparó para `orden_servicio`, `herida`, `oxigenoterapia_domiciliaria`, pero se omitió `plan_cuidado`. | L429-437 |
| PG-S7 | HIGH | CHECK-PATH-EQUALITY | **`protocolo_fallecimiento.tipo` no está cross-validado semánticamente con `estadia.tipo_egreso`.** El trigger E6 valida que `tipo_egreso ∈ {'fallecido_esperado', 'fallecido_no_esperado'}`, pero NO valida que `protocolo.tipo = 'esperado'` corresponda a `estadia.tipo_egreso = 'fallecido_esperado'`. El mapping `esperado → fallecido_esperado` y `no_esperado → fallecido_no_esperado` es implícito, no enforced. Un protocolo `tipo='esperado'` puede coexistir con una estadia `tipo_egreso='fallecido_no_esperado'`. | L2555 vs L389 |

### 4.2 REFERENTIAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-R1 | **CRITICAL** | CHECK-FOREIGN-KEY | **Todos los timestamps son `TEXT` en lugar de `TIMESTAMPTZ`.** Las 98 tablas usan `TEXT NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::TEXT` para `created_at` / `updated_at`. PostgreSQL tiene un sistema de tipos temporal nativo (`TIMESTAMPTZ`, `DATE`, `INTERVAL`) con operadores, indexing B-tree optimizado, y funciones de ventana temporal. Usar TEXT pierde: (a) validación de formato — un INSERT con `created_at = 'banana'` pasa sin error; (b) operadores `<`, `>`, `BETWEEN` requieren cast explícito; (c) la constraint EXCLUDE de `estadia` (L405-408) castea `fecha_ingreso::date` y `fecha_egreso::date` — si el TEXT no es ISO 8601, falla en runtime; (d) `mv_rem_personas_atendidas` castea `fecha_ingreso::date` 12+ veces (L3478-3528), cada cast es un punto de fallo silencioso. **Esto es el anti-pattern más costoso del DDL: migrar a PG sin migrar los tipos.** | 98 tablas, ~200 columnas |
| PG-R2 | **CRITICAL** | CHECK-FOREIGN-KEY | **No hay validación de formato ISO 8601 en ninguna columna de fecha TEXT.** Ni CHECK constraints que validen el patrón `^\d{4}-\d{2}-\d{2}`, ni dominios (CREATE DOMAIN), ni regex. La constraint EXCLUDE de `estadia` y las materialized views asumen formato ISO pero nada lo enforza. El primer dato mal formateado rompe las vistas y la constraint de solapamiento. | Todas las columnas fecha/timestamp |
| PG-R3 | HIGH | CHECK-FOREIGN-KEY | **`lista_espera.establecimiento_origen` y `paciente.cesfam` siguen como TEXT libre** (issues R4 y R5 de v3). Ambos deberían ser REFERENCES a `establecimiento` o a un catálogo de establecimientos APS. | L1795, L355 |

### 4.3 BEHAVIORAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-B1 | **CRITICAL** | CHECK-BISIMULATION | **`guard_estadia_estado()` y `guard_visita_estado()` permiten transiciones en INSERT.** Ambos guards son `BEFORE UPDATE` only (L3313-3320). Un INSERT directo con `estado = 'activo'` en `estadia` bypassa completamente la coalgebra — no valida que la transición `NULL → activo` o `pendiente_evaluacion → activo` sea legal. Solo los UPDATEs posteriores están guardados. **La primera escritura del estado es libre.** | L3313-3320 |
| PG-B2 | HIGH | CHECK-INTERFACE-CONFORMANCE | **20+ máquinas de estado "soft" sin enforcement coalgebraico.** Solo `visita` y `estadia` tienen coalgebra completa (event table + transition ref + sync trigger + guard). Las siguientes tablas tienen `estado CHECK` pero CERO enforcement dinámico: `plan_cuidado`, `herida`, `receta`, `equipo_medico`, `solicitud_examen`, `indicacion_medica`, `lista_espera`, `evento_adverso`, `notificacion_obligatoria`, `garantia_ges`, `prestamo_equipo`, `oxigenoterapia_domiciliaria`, `botiquin_domiciliario`, `compra_servicio`, `orden_servicio`, `interconsulta`, `derivacion`, `dispositivo`, `alerta`, `documentacion`. (Heredado de v3 B4.) | Passim |
| PG-B3 | HIGH | CHECK-BEHAVIORAL-EQUIVALENCE | **Vocabulario `prioridad` fragmentado sin unificación.** (Heredado de v3 B7.) `sla`/`orden_servicio`: `{urgente, alta, normal, baja}`. `solicitud_examen`: `{urgente, rutina}`. `interconsulta`: `{urgente, preferente, normal}`. `entrega_turno_paciente`: `{alta, media, baja}`. `lista_espera`: `{urgente, alta, normal, baja}`. 4 vocabularios distintos para el mismo concepto semántico. | Passim |

### 4.4 COMPLETENESS

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-C1 | HIGH | CHECK-INFO-COMPLETE | **No hay SCHEMA separation.** Las 98 tablas viven en `public`. PostgreSQL permite schemas (`CREATE SCHEMA clinical; CREATE SCHEMA operational;`). La arquitectura de 4 capas + 14 dominios se pierde en un namespace plano. Impacto: (a) sin control de acceso granular por dominio; (b) sin namespace para evitar colisiones de nombres; (c) sin ownership diferenciado por equipo/rol. | Global |
| PG-C2 | HIGH | CHECK-INFO-COMPLETE | **No hay RBAC/RLS para datos clínicos.** DS 41/2012 Art. 13: "La ficha clínica es de carácter reservado". Ley 20.584 Art. 12-13: confidencialidad datos clínicos. El DDL no tiene `GRANT`, `REVOKE`, `CREATE ROLE`, ni `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`. Un solo usuario con acceso a la base ve RUT, nombres, diagnósticos, direcciones, teléfonos de todos los pacientes. | Global |
| PG-C3 | MEDIUM | CHECK-INFO-COMPLETE | **No hay funciones de refresh para materialized views.** Los 3 MVs (`mv_rem_personas_atendidas`, `mv_kpi_diario`, `mv_telemetria_kpi_diario`) tienen comentarios "REFRESH with CONCURRENTLY" pero no existe función `refresh_materialized_views()`, ni trigger de refresh, ni documentación de cuándo refrescar. Las MVs quedan stale indefinidamente. | L3475, L3538, L4066 |
| PG-C4 | MEDIUM | CHECK-INFO-COMPLETE | **`sync_paciente_estado()` no maneja la transición `NULL → activo`.** El trigger (Pattern D3) solo se dispara cuando `estadia.estado ∈ {'egresado', 'fallecido'}` (L2851). Cuando una estadia cambia a `activo`, `paciente.estado_actual` no se actualiza a `activo`. El path `evento_estadia → estadia.estado = 'activo' → paciente.estado_actual = 'activo'` no está implementado. | L2849-2868 |
| PG-C5 | MEDIUM | CHECK-INFO-COMPLETE | **Duplicate INDEX definitions.** La mayoría de los 151+ indexes se crean inline con cada CREATE TABLE y TAMBIÉN se repiten en la Section 5 (L3582+). El `IF NOT EXISTS` previene errores, pero el DDL tiene ~80 líneas de indexes duplicados que son puro ruido. | L3582-3827 |

### 4.5 QUALITY

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-Q1 | MEDIUM | CHECK-UNIVERSAL-CONSTRUCTION | **`TEXT` donde PostgreSQL tiene tipos nativos superiores.** (a) Fechas: `TEXT` vs `DATE` — pierde validación, operadores, funciones de ventana. (b) Timestamps: `TEXT` vs `TIMESTAMPTZ` — pierde timezone handling, `EXTRACT()`, `AGE()` sin cast. (c) JSON: `comunas TEXT` con "JSON array o CSV de comunas" (L38) vs `JSONB` con operadores `@>`, `?`, `?|`. (d) Arrays: `competencias TEXT`, `comunas_cobertura TEXT` vs `TEXT[]` con operadores `@>`, `&&`. (e) Coordenadas: `REAL` vs `POINT` o `geography(Point, 4326)` con PostGIS. El DDL migra la **sintaxis** de SQLite a PG pero no migra la **semántica de tipos**. | Global |
| PG-Q2 | MEDIUM | CHECK-FUNCTORIALITY | **`visita.rem_prestacion TEXT` coexiste con `visita.prestacion_id REFERENCES catalogo_prestacion`.** El campo TEXT legacy se mantiene "por retrocompatibilidad" (L795), pero crea dualidad: ¿cuál es la fuente de verdad? Sin trigger de sincronización, pueden divergir. | L794-795 |
| PG-Q3 | MEDIUM | CHECK-FUNCTORIALITY | **DEFAULT syntax inconsistente entre Part 1 y Part 2.** Part 1 usa `(NOW() AT TIME ZONE 'UTC')::TEXT`. Part 2 (dead code) usa `(NOW() AT TIME ZONE 'UTC')` sin `::TEXT`. Si alguien reactiva Part 2, el formato del timestamp difiere. | L1120 vs L1040 |
| PG-Q4 | MEDIUM | CHECK-UNIVERSAL-CONSTRUCTION | **`mv_rem_personas_atendidas` tiene lógica tautológica.** L3480-3482: `COUNT(*) FILTER (WHERE TO_CHAR(e.fecha_ingreso::date, 'YYYY-MM') = TO_CHAR(e.fecha_ingreso::date, 'YYYY-MM'))` — el filtro siempre es TRUE. Es equivalente a `COUNT(*)`. La columna `total_ingresos` no filtra por período; simplemente cuenta todas las filas del GROUP BY. | L3480-3482 |
| PG-Q5 | MEDIUM | CHECK-FUNCTORIALITY | **`telemetria_segmento_ruta` trigger (L3945-3962) es un no-op.** La función `check_telemetria_segmento_ruta()` obtiene vehiculo_id y provider_id pero el comentario dice "no forzamos match estricto" y no hace ninguna validación efectiva. Es un trigger que se ejecuta en cada INSERT/UPDATE de route_id pero no valida nada. Overhead sin beneficio. | L3945-3962 |

### 4.6 MIGRATION (SQLite → PostgreSQL)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| PG-M1 | **CRITICAL** | CHECK-MIGRATION-FUNCTOR | **El DDL no se puede ejecutar limpiamente en PostgreSQL.** `rem_reportable = 1` (PG-S1) causa error de tipo. Las vistas y MVs que usan esta comparación fallarán al crearse. El script no produce un schema funcional completo. | L3411, L3565 |
| PG-M2 | **CRITICAL** | CHECK-CONSTRAINT-PRESERVATION | **El functor de migración F: SQLite → PG no preserva el sistema de tipos.** SQLite es type-affinity (todo es TEXT internamente). PG es strongly-typed. El functor Δ debería mapear `SQLite.TEXT → PG.DATE` para fechas, `SQLite.INTEGER(boolean) → PG.BOOLEAN` para booleanos, `SQLite.TEXT(json) → PG.JSONB` para JSON. En cambio, F mapea `SQLite.TEXT → PG.TEXT` uniformemente — un functor constante que pierde toda la estructura de tipos de PG. **Functor Information Loss inverso: es PG quien pierde su estructura al recibir tipos planos de SQLite.** | Global |
| PG-M3 | **CRITICAL** | CHECK-MIGRATION-FUNCTOR | **Dual definition hazard.** 8 tablas definidas dos veces. Si el script se ejecuta parcialmente (error en medio), las tablas Part 2 podrían crearse con defaults distintos a Part 1. El `IF NOT EXISTS` asume ejecución completa y secuencial. En una migración parcial o rollback, el estado resultante es impredecible. | L1107-1172 |
| PG-M4 | HIGH | CHECK-MIGRATION-FUNCTOR | **DDL nunca poblado con datos reales (heredado M1 v3).** 48 triggers (22 functions × bindings) sin validación empírica. Los 3 MVs nunca han sido refrescados con datos. Bugs latentes en cast TEXT→DATE, comparación boolean, y coherencia semántica son probables. | Global |

---

## 5. Análisis Categorial Profundo

### 5.1 El anti-pattern TEXT-everywhere como functor degenerado

```
Sea T el sistema de tipos de PostgreSQL:

  T = {TIMESTAMPTZ, DATE, BOOLEAN, JSONB, TEXT[], INTEGER, REAL, POINT, ...}

El functor de migración F: SQLite_Schema → PG_Schema actúa como:

  F(tipo) = TEXT   ∀ tipo ∈ {fecha, timestamp, boolean_01, json_array}

Esto hace de F un functor CONSTANTE en la fibra de tipos:

  F: Obj(SQLite_Types) → {TEXT} ⊂ Obj(PG_Types)

La información perdida no es de SQLite (que ya era TEXT), sino de PG:
el functor rechaza la riqueza del codomain.

  Functor Information Loss (reverse):
    PG.DATE     → TEXT  : pierde validación, operadores, indexing nativo
    PG.BOOLEAN  → TEXT  : pierde '= 1' vs '= TRUE' (PG-S1)
    PG.JSONB    → TEXT  : pierde operadores @>, ?, containment, GIN indexing
    PG.INTERVAL → TEXT  : pierde aritmética temporal
    PG.POINT    → 2×REAL: pierde distancia(), PostGIS, GiST spatial index

El colímite correcto sería:

  F*(tipo) = CASE tipo
    WHEN fecha    THEN DATE
    WHEN timestamp THEN TIMESTAMPTZ
    WHEN bool_01   THEN BOOLEAN
    WHEN json      THEN JSONB
    WHEN coords    THEN geography(Point, 4326)
    ELSE TEXT
  END

Esto preservaría la estructura de PG como Σ (left Kan extension)
en vez de destruirla como Π (restriction).
```

### 5.2 Coalgebra de estados: cobertura post-migración

| Carrier | Event table | Transition ref | Sync trigger | BEFORE UPDATE guard | BEFORE INSERT guard | Enforcement |
|---|---|---|---|---|---|---|
| `visita.estado` (13 estados) | `evento_visita` | `maquina_estados_ref` | `sync_visita_estado` | `guard_visita_estado` | **NO** | **Alto** (falla en INSERT libre) |
| `estadia.estado` (6 estados) | `evento_estadia` | `maquina_estados_estadia_ref` | `sync_estadia_estado` + `sync_paciente_estado` | `guard_estadia_estado` | **NO** | **Alto** (falla en INSERT libre) |
| `paciente.estado_actual` (4 estados) | **NO** | **NO** | Via `sync_paciente_estado` | **NO** | **NO** | **Bajo** — solo se sincroniza en egreso/fallecido, no en activación |
| Otros 20+ carriers | **NO** | **NO** | **NO** | **NO** | **NO** | **Ninguno** |

**Mejora vs v3**: Los guards de UPDATE (Pattern C3/C4) cierran el bypass que existía en SQLite. Pero el gap INSERT permanece — la coalgebra arranca desde un estado no validado.

### 5.3 PE-1 Path Equation: cobertura por tabla

```
Tablas con triángulo stay_id + patient_id:          ~29
  Con trigger PE-1 (BEFORE INSERT OR UPDATE):        26  (90%)
  Sin trigger PE-1:                                   3  (10%)
    - encuesta_satisfaccion (mencionada pero no bound)
    - [encuesta no es parte del count exacto 27]
    
Mejora dramática vs v3: 52% → 90%

Tablas con triángulo visit_id + stay_id:             ~6
  Con trigger stay_coherence:                         2  (33%)
  Sin trigger stay_coherence:                         4  (67%)
    - observacion, nota_evolucion, sesion_rehabilitacion, educacion_paciente

Este 67% de gaps en stay_coherence es el defecto silencioso
más peligroso del DDL PostgreSQL.
```

### 5.4 Diagrama de capas: entidades huérfanas

```
Huérfanos v3 (catalogo_prestacion, sla, conductor): TODOS REPARADOS ✓

Huérfanos nuevos PG: ningún huérfano estructural nuevo.

Huérfanos leaf (aceptables):
  kpi_diario, descomposicion_temporal, reporte_cobertura,
  configuracion_programa, reunion_equipo, capacitacion,
  canasta_valorizada, compra_servicio, notificacion_obligatoria,
  diagnostico_egreso (leaf via epicrisis)
```

### 5.5 Ventajas PostgreSQL aprovechadas

| Feature PG | Uso en DDL | Evaluación |
|---|---|---|
| `EXCLUDE USING gist` | No-overlap de fechas en `estadia` | **Excelente** — previene estadías solapadas por paciente |
| Reusable trigger functions | 1 función `check_pe1()` → 26 bindings | **Excelente** — 75% reducción de código vs SQLite |
| `BEFORE INSERT OR UPDATE` | Cierra gap INSERT+UPDATE de SQLite | **Excelente** — elimina 51 triggers → 26 bindings |
| Partial indexes | 5 indexes parciales para queries frecuentes | **Bueno** |
| `MATERIALIZED VIEW` | 3 MVs para reporting | **Bueno** (pero sin refresh strategy) |
| `JSONB` | Solo en `telemetria_segmento.geofences_in` | **Infrautilizado** — el resto usa TEXT para JSON |
| GIN index | 1 para geofences JSONB | **Infrautilizado** |
| `FILTER (WHERE ...)` | En MVs para aggregados condicionales | **Bueno** |
| Schemas | No usado | **No aprovechado** |
| RBAC/RLS | No usado | **No aprovechado — riesgo normativo** |
| Native types | Casi no usados | **No aprovechado — anti-pattern central** |

### 5.6 Ventajas PostgreSQL desaprovechadas (Top 5 por impacto)

1. **`TIMESTAMPTZ` / `DATE`** → eliminaría PG-R1, PG-R2, PG-Q1, PG-S1 (4 issues, 2 CRITICAL)
2. **`CREATE SCHEMA`** → eliminaría PG-C1 (1 HIGH)
3. **`CREATE ROLE` + `ROW LEVEL SECURITY`** → eliminaría PG-C2 (1 HIGH, riesgo normativo)
4. **`BOOLEAN` nativo correcto** → eliminaría PG-S1 parcialmente (1 CRITICAL)
5. **`CREATE DOMAIN iso_date AS TEXT CHECK (VALUE ~ '^\d{4}-\d{2}-\d{2}$')`** → mitigaría PG-R2 como paso intermedio antes de migrar a DATE

---

## 6. Priorización de Reparaciones

### CRITICAL (7 issues — bloquean ejecución o producción)

| # | Issue(s) | Reparación | Esfuerzo |
|---|---|---|---|
| **FIX-1** | PG-S1, PG-M1 | **Reemplazar `rem_reportable = 1` por `rem_reportable = TRUE`** en `v_consolidado_atenciones_diarias` y `mv_kpi_diario`. Sin esto, el DDL no se ejecuta. | 2 líneas |
| **FIX-2** | PG-S2, PG-M3 | **Eliminar las 6 definiciones duplicadas** (Part 2: L1107-1172) y las duplicaciones de vehiculo/conductor (L2036-2070) y maquina_estados_estadia_ref (L2613-2629). Dejar solo Part 1. | Borrar ~120 líneas |
| **FIX-3** | PG-S3 | **Crear binding PE-1 para `encuesta_satisfaccion`**: `CREATE TRIGGER trg_encuesta_satisfaccion_pe1 BEFORE INSERT OR UPDATE ON encuesta_satisfaccion FOR EACH ROW EXECUTE FUNCTION check_pe1();` | 3 líneas |
| **FIX-4** | PG-S4 | **Crear 4 bindings stay_coherence** para observacion, nota_evolucion, sesion_rehabilitacion, educacion_paciente. | 12 líneas |
| **FIX-5** | PG-B1 | **Agregar validación de estado inicial en INSERT para estadia y visita.** Opción A: CHECK (`estado = 'pendiente_evaluacion'` en estadia, `estado = 'PROGRAMADA'` en visita) como DEFAULT ya seteado. Opción B: trigger BEFORE INSERT que valide estado inicial permitido. | 1 CHECK o 1 trigger |
| **FIX-6** | PG-R1, PG-R2, PG-Q1, PG-M2 | **Migrar columnas de fecha/timestamp a tipos nativos PG.** Fase 1 (inmediata): crear DOMAINs `CREATE DOMAIN iso_date AS TEXT CHECK (VALUE ~ '^\d{4}-\d{2}-\d{2}$')` y `CREATE DOMAIN iso_timestamp AS TEXT CHECK (VALUE ~ '^\d{4}-\d{2}-\d{2}T')`. Fase 2 (post-poblado): `ALTER COLUMN ... TYPE DATE USING col::date`, `ALTER COLUMN ... TYPE TIMESTAMPTZ USING col::timestamptz`. | Fase 1: ~30 líneas. Fase 2: ~200 ALTER |

### HIGH (16 issues — ejecutar antes de producción)

| # | Issue(s) | Reparación |
|---|---|---|
| FIX-7 | PG-S5 | Agregar `condicion.patient_id REFERENCES paciente(patient_id)` + trigger PE-1. |
| FIX-8 | PG-S6 | Agregar CHECK `(periodo_fin IS NULL OR periodo_fin >= periodo_inicio)` a `plan_cuidado`. |
| FIX-9 | PG-S7 | Expandir trigger E6 para cross-validar: `IF NEW.tipo = 'esperado' AND v_tipo_egreso != 'fallecido_esperado' THEN RAISE...`. |
| FIX-10 | PG-R3 | Agregar REFERENCES para `lista_espera.establecimiento_origen` y `paciente.cesfam` (o crear catálogo APS). |
| FIX-11 | PG-B2 | Documentar explícitamente qué máquinas son "soft". Crear tabla `estado_maquina_config(tabla, enforcement_level, justificacion)`. |
| FIX-12 | PG-B3 | Crear `prioridad_ref(codigo, descripcion, orden)` y refactorizar las 5 tablas. |
| FIX-13 | PG-C1 | Crear schemas: `clinical`, `operational`, `territorial`, `reporting`, `telemetry`, `reference`. Mover tablas. |
| FIX-14 | PG-C2 | Crear roles (`hodom_admin`, `hodom_clinico`, `hodom_coordinador`, `hodom_readonly`) + RLS en `paciente`, `estadia`, `visita`, `nota_evolucion`, etc. |
| FIX-15 | PG-C4 | Expandir `sync_paciente_estado()` para manejar transición a `activo`: `IF NEW.estado = 'activo' THEN UPDATE paciente SET estado_actual = 'activo' WHERE patient_id = NEW.patient_id`. |
| FIX-16 | PG-M4 | Implementar script de validación empírica con datos sintéticos. |

### MEDIUM (9 issues)

| # | Issue(s) | Reparación |
|---|---|---|
| FIX-17 | PG-C3 | Crear función `refresh_hodom_mvs()` y documentar estrategia de refresh (por cron o trigger). |
| FIX-18 | PG-C5 | Eliminar indexes duplicados en Section 5 (mantener solo los inline). |
| FIX-19 | PG-Q2 | Agregar trigger sync `visita.prestacion_id` ↔ `visita.rem_prestacion`, o deprecar `rem_prestacion`. |
| FIX-20 | PG-Q3 | Eliminar Part 2 duplicados (mismo que FIX-2). |
| FIX-21 | PG-Q4 | Corregir lógica de `mv_rem_personas_atendidas`: filtrar `total_ingresos` por el período del GROUP BY correctamente. |
| FIX-22 | PG-Q5 | Eliminar trigger no-op `check_telemetria_segmento_ruta()` o implementar validación real. |
| FIX-23 | PG-B7 | Crear catálogo unificado de prioridades (mismo que FIX-12). |

---

## 7. Functor Information Loss

| Transformación | Operador | Información perdida |
|---|---|---|
| SQLite types → PG TEXT | Δ (reestructuración fallida) | PG pierde DATE, TIMESTAMPTZ, BOOLEAN, JSONB, POINT, TEXT[], INTERVAL — **toda su ventaja de tipos** |
| SQLite triggers → PG functions | Σ (fusión exitosa) | Nada perdido: 77 → 19 functions + 48 bindings. Ganancia neta. |
| SQLite schema plano → PG schema plano | Δ (identidad) | PG pierde SCHEMA separation, RBAC, RLS — **toda su ventaja de seguridad** |
| `rem_reportable INTEGER` → `rem_reportable BOOLEAN` | Δ (migración correcta del tipo) | Pero las VISTAS no migraron: siguen usando `= 1` — **functor parcial: la tabla migró, las vistas no** |
| Formularios papel → DDL | Σ (fusión) | Layout visual, firmas, sellos, formato libre narrativo |

**Diagnóstico del functor de migración F: SQLite → PG:**

```
F es un FUNCTOR PARCIAL — preserva estructura en las tablas
pero falla en las vistas (PG-S1) y en los tipos (PG-R1).

  F(tablas)   = Σ (correcto, con mejoras: EXCLUDE, reusable functions)
  F(triggers) = Σ (correcto, 75% reducción de código)
  F(tipos)    = Π (restricción destructiva: TEXT everywhere)
  F(vistas)   = ⊥ (no ejecutable: type error en rem_reportable)
  F(seguridad)= ∅ (no migrado)

El functor F no es well-defined: falla en el subcategory de vistas.
Hasta que PG-S1 se repare, F: SQLite → PG no produce un schema válido.
```

---

## 8. Estadísticas Comparativas v3 → v4

```
                              v3 (SQLite)    v4 (PostgreSQL)
──────────────────────────────────────────────────────────────
Tablas                        87             98  (+11)
Triggers (bindings)           35             48  (+13)
Trigger functions             35 (inline)    22  (reusable)
Views                         4              7   (+3)
Materialized views            0              3   (+3)
Indexes                       120            163 (+43)
Catálogos referencia           0              8   (+8)
Path equations enforced        3              10  (+7)
PE-1 cobertura                52%            90% (+38pp)
State machine enforcement      9% (2/22)     9%  (2/22) — sin cambio
DDL ejecutable                Sí             **NO** (PG-S1)
Tipos nativos usados          N/A            1   (BOOLEAN en rem_reportable)
Issues CRITICAL               11             7   (-4, pero 3 son nuevos PG)
Issues totales                45             35  (-10)
```

---

## 9. Veredicto

**El DDL PostgreSQL es una mejora sustancial sobre el SQLite en arquitectura de triggers y constraints (PE-1 al 90%, guards de UPDATE, EXCLUDE non-overlap, reusable functions), pero falla como migración PostgreSQL porque no migra lo que hace a PostgreSQL valioso: el sistema de tipos, los schemas, y la seguridad.**

El DDL actual es esencialmente **SQLite con sintaxis PostgreSQL** — un functor que preserva la forma pero destruye la semántica del target.

**Bloqueantes inmediatos** (sin estos, el script no se ejecuta):
1. FIX-1: `rem_reportable = TRUE` (2 líneas)
2. FIX-2: Eliminar definiciones duplicadas (~120 líneas de dead code)

**Bloqueantes de producción** (sin estos, datos clínicos en riesgo):
3. FIX-6: Migrar a tipos nativos PG (o al menos DOMAINs validados)
4. FIX-14: RBAC/RLS para cumplir DS 41/2012 y Ley 20.584

---

## 10. Signature

```
Modo:           STATIC + BEHAVIORAL + MIGRATION
Artefacto:      SCHEMA (DDL PostgreSQL 4137 líneas, 98 tablas)
Baseline:       auditoria-categorial-hodom-v3.md (45 issues SQLite)
Issues v3:      38/45 reparados (84%), 6 pendientes, 1 parcial
Issues v4:      7 CRITICAL, 16 HIGH, 9 MEDIUM, 0 LOW = 32 nuevos
                + 6 heredados v3 no reparados = 35 total activos
Patrones:       BROKEN-DIAGRAM (4), NON-FUNCTORIAL (6), AD-HOC-CONSTRUCTION (3),
                REDUNDANT-BISIMILAR (2), ORPHAN-OBJECT (0)
Migración:      F: SQLite → PG es un functor parcial.
                F(tablas) = Σ (correcto). F(tipos) = Π (destructivo).
                F(vistas) = ⊥ (error de tipo). F(seguridad) = ∅.
Riesgos:        DDL no ejecutable (rem_reportable = 1 en BOOLEAN column).
                98 tablas con ~200 columnas fecha/timestamp como TEXT sin validación.
                0 RBAC/RLS en sistema con datos clínicos protegidos por ley.
                67% de tablas con visit_id+stay_id sin coherencia enforced.
                91% de máquinas de estado sin enforcement coalgebraico.
                8 tablas definidas dos veces (dead code con defaults inconsistentes).
```
