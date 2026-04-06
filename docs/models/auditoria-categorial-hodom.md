# Auditoría Categorial Exhaustiva — Modelo Integrado HODOM

Auditoría formal conforme a FXSL Categorical Audit Patterns.
Fecha: 2026-04-06. Artefactos auditados:

- `modelo-integrado-hodom.md` (1127 líneas, modelo conceptual)
- `hodom-integrado.sql` (720 líneas, DDL SQLite)
- `erd-modelo-integrado-hodom.html` (753 líneas, visualización)

---

## 1. Clasificación DIK

| Atributo | Valor |
|---|---|
| DIK Level | **INFORMATION** (schema S) + **KNOWLEDGE** (migración legacy → modelo, contratos OPM) |
| Type | SCHEMA (DDL) + MODEL (documento conceptual) |
| Dominio | Hospitalización domiciliaria, Hospital San Carlos, Ñuble |
| Construcción | Grothendieck ∫F sobre I = {clínica, operacional, territorial, reporte} |
| Entidades | 32 tablas + 3 vistas + 1 tabla de referencia seed |
| Identity keys | 8 (patient_id, stay_id, visit_id, provider_id, order_id, location_id, zone_id, establecimiento_id) |
| Path equations | 10 declaradas (PE-1..PE-10) |

---

## 2. Resumen Diagnóstico

| Dimensión | Estado | Issues |
|---|---|---|
| Structural | **WARN** | 4 HIGH, 2 MEDIUM |
| Referential | **WARN** | 3 HIGH, 1 CRITICAL |
| Completeness | **WARN** | 3 MEDIUM |
| Quality | **INFO** | 4 LOW |
| Migrations | **WARN** | 2 HIGH |
| Behavioral | **WARN** | 2 HIGH, 1 MEDIUM |

**Total: 1 CRITICAL, 11 HIGH, 6 MEDIUM, 4 LOW = 22 issues**

---

## 3. Issues Detectados

### STRUCTURAL (CHECK-IDENTITY, CHECK-COMPOSITION, CHECK-PATH-EQUALITY)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| S1 | HIGH | CHECK-PATH-EQUALITY | **PE-1 no es enforceable en DDL.** `visita.patient_id` y `visita.stay_id` son columnas independientes sin constraint que garantice `visita.patient_id = estadia(visita.stay_id).patient_id`. La vista `v_pe1_violations` detecta violaciones pero no las previene. En SQLite no hay CHECK con subconsultas ni triggers declarados. | `visita` DDL línea 448-477 |
| S2 | HIGH | CHECK-PATH-EQUALITY | **PE-2 misma brecha.** `orden_servicio.patient_id` y `orden_servicio.stay_id` sin constraint de coherencia. Mismo patrón que S1. | `orden_servicio` DDL línea 403-421 |
| S3 | HIGH | CHECK-PATH-EQUALITY | **PE-7 no enforceable.** La path equation `EncuestaSatisfaccion.stay_id → Estadia.tipo_egreso ∈ {alta_clinica, renuncia_voluntaria}` no tiene CHECK constraint ni trigger. Nada impide vincular una encuesta a un egreso por fallecimiento. | `encuesta_satisfaccion` DDL línea 304-328 |
| S4 | HIGH | CHECK-COMPOSITION | **Composición `estadia → plan_cuidado → requerimiento_cuidado → orden_servicio` rota.** No hay morfismo directo `requerimiento_cuidado → orden_servicio`. El modelo conceptual dice "se transforma en" (dashed arrow en ERD logística) pero no hay FK ni tabla de mapping. La cadena plan→requerimiento→orden no cierra. | Modelo conceptual vs DDL |
| S5 | MEDIUM | CHECK-PATH-EQUALITY | **PE-8 sin enforcement.** `procedimiento.codigo → catalogo_prestacion.codigo_mai` es una path equation declarada pero `procedimiento.codigo` no tiene REFERENCES a `catalogo_prestacion`. Los códigos pueden ser ad-hoc sin vínculo al catálogo MAI. | `procedimiento` DDL línea 201-209 |
| S6 | MEDIUM | CHECK-PATH-EQUALITY | **PE-10 no verificable en tiempo real.** `registro_llamada.estado_paciente` debería ser consistente con la existencia de una estadía activa, pero no hay trigger ni constraint. Es solo una aserción documental. | `registro_llamada` DDL línea 519-537 |

### REFERENTIAL (CHECK-FOREIGN-KEY, CHECK-REF-INTERNAL)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| R1 | **CRITICAL** | CHECK-FOREIGN-KEY | **6 FKs cross-layer declaradas como TEXT sin REFERENCES.** `visita.stay_id`, `visita.patient_id`, `orden_servicio.stay_id`, `orden_servicio.patient_id`, `registro_llamada.patient_id`, `visita.location_id`. Con `PRAGMA foreign_keys = ON`, SQLite no valida estas columnas — cualquier valor es aceptado, incluyendo IDs inexistentes. La integridad referencial cross-layer es **nula**. | DDL passim |
| R2 | HIGH | CHECK-FOREIGN-KEY | **`reporte_cobertura.patient_id` y `reporte_cobertura.order_id` sin REFERENCES.** Misma categoría que R1 pero en capa Reporte. | DDL línea 636-647 |
| R3 | HIGH | CHECK-FOREIGN-KEY | **`procedimiento.visit_id`, `observacion.visit_id`, `medicacion.visit_id`, `documentacion.visit_id` sin REFERENCES.** 4 columnas en capa Clínica que referencian `visita` (capa Operacional) sin enforcement. | DDL líneas 203, 217, 236, 264 |
| R4 | HIGH | CHECK-REF-INTERNAL | **`evento_visita.estado_previo` y `evento_visita.estado_nuevo` no validados contra `maquina_estados_ref`.** Los estados pueden ser texto libre. No hay CHECK constraint que los restrinja al enum de visita ni trigger que valide que la transición `(estado_previo → estado_nuevo)` sea una fila válida de `maquina_estados_ref`. | `evento_visita` DDL línea 487-498 |

### COMPLETENESS (CHECK-INFO-COMPLETE)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| C1 | MEDIUM | CHECK-INFO-COMPLETE | **Falta tabla de junction `orden_servicio_insumo`.** El modelo conceptual declara `OrdenServicio → Insumo` con cardinalidad `0..*` ("requiere"), pero no hay tabla de junction ni FK en el DDL. La relación many-to-many no tiene materialización relacional. | Modelo conceptual vs DDL |
| C2 | MEDIUM | CHECK-INFO-COMPLETE | **Falta `zona_profesional` (cobertura).** El ERD logística declara `zone → provider` con cardinalidad `*..*` (dashed) para cobertura geográfica. No hay tabla de junction ni atributo estructurado. `profesional.comunas_cobertura` es TEXT libre, no normalizado. | ERD logística vs DDL |
| C3 | MEDIUM | CHECK-INFO-COMPLETE | **`rem_personas_atendidas` no tiene dimensión `rango_20_59` con separación 20-59 vs ≥60.** El REM actual tiene `20 y más años` como rango único, pero el modelo declara `rango_20_59` y `mayores_60` como columnas separadas. Esto es correcto para REM 2026 pero no para REM 2023 (que usaba `20 y más`). Hay un VERSION-MISMATCH entre la estructura del DDL y los datos históricos. | `rem_personas_atendidas` DDL vs REM julio 2023 |

### QUALITY (CHECK-UNIVERSAL-CONSTRUCTION, CHECK-FUNCTORIALITY)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| Q1 | LOW | CHECK-UNIVERSAL-CONSTRUCTION | **`documentacion.tipo` es un coproducto ad-hoc de 26 valores.** Un enum de 26 valores en un CHECK constraint es frágil — agregar un tipo requiere ALTER TABLE. Una tabla de referencia `tipo_documento_ref` sería el colímite formal (coproducto con inyecciones tipadas). | `documentacion` DDL línea 267-278 |
| Q2 | LOW | CHECK-UNIVERSAL-CONSTRUCTION | **`requerimiento_cuidado.tipo` (13 valores) y `visita.estado` (13 valores) presentan el mismo patrón.** Enums largos hardcodeados en CHECK constraints en lugar de tablas de referencia. Son coproductos que se beneficiarían de normalización como lookup tables. | DDL passim |
| Q3 | LOW | CHECK-FUNCTORIALITY | **Functor `profesion → profesion_rem` no es inyectivo.** `NUTRICION` mapea a NULL (no reportable REM). Esto es correcto pero no está declarado como constraint — un profesional con `profesion='NUTRICION'` y `profesion_rem='enfermera'` pasaría los CHECKs sin error. Falta constraint de coherencia entre los dos enums. | `profesional` DDL línea 337-361 |
| Q4 | LOW | CHECK-BEHAVIORAL-EQUIVALENCE | **`sla.service_type` y `orden_servicio.service_type` no comparten vocabulario controlado.** Ambos son TEXT libre. No hay tabla de referencia ni CHECK constraint que garantice que una orden use un service_type para el cual existe un SLA definido. | `sla` vs `orden_servicio` DDL |

### MIGRATION (CHECK-MIGRATION-FUNCTOR, CHECK-CONSTRAINT-PRESERVATION)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| M1 | HIGH | CHECK-MIGRATION-FUNCTOR | **Migración Legacy → SQLite: el functor no preserva la estructura de la PROGRAMACIÓN.** La PROGRAMACIÓN es una matriz `paciente×día→código_actividad` (schema denormalizado). La migración debe descomponer cada celda en tuplas `(patient_id, fecha, service_type)` y crear tanto `orden_servicio` como `visita`. No hay functor Σ definido para esta descomposición — la transformación es ad-hoc. | Modelo conceptual §Auditoría Legacy |
| M2 | HIGH | CHECK-CONSTRAINT-PRESERVATION | **Migración CSV pipeline → SQLite: las path equations del pipeline actual no se preservan.** El pipeline actual (Stage 4) produce `hospitalization_stay.csv` con `source_episode_ids` como TEXT concatenado. La migración a `estadia.source_episode_ids` preserva el dato pero pierde la semántica de FK multiple — debería ser una tabla de junction `estadia_episodio_fuente(stay_id, episode_id)` para que cada referencia sea un morfismo verificable. | `estadia.source_episode_ids` DDL línea 132 |

### BEHAVIORAL (CHECK-INTERFACE-CONFORMANCE, CHECK-BISIMULATION)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| B1 | HIGH | CHECK-INTERFACE-CONFORMANCE | **El lifecycle OPM SD1 no tiene enforcement en el DDL.** Los 7 pasos del proceso (elegibilidad→ingreso→planificación→ejecución→monitoreo→egreso→seguimiento) no se materializan como máquina de estados de la estadía. `estadia.estado` tiene solo 3 valores (`activo`, `egresado`, `fallecido`) pero el OPM define al menos 6 estados (`pending`, `eligible`, `admitted`, `active`, `discharged` + subestados). No hay tabla `evento_estadia` análoga a `evento_visita`. | `estadia` DDL vs OPM SD1 |
| B2 | HIGH | CHECK-INTERFACE-CONFORMANCE | **La máquina de estados de visita tiene transiciones no validadas.** `maquina_estados_ref` define 15 transiciones válidas, pero `evento_visita` acepta cualquier par `(estado_previo, estado_nuevo)`. No hay trigger que verifique `EXISTS (SELECT 1 FROM maquina_estados_ref WHERE from_state = NEW.estado_previo AND to_state = NEW.estado_nuevo)`. Las transiciones inválidas (e.g., `PROGRAMADA → REPORTADA_REM`) pasarían sin error. | `evento_visita` + `maquina_estados_ref` DDL |
| B3 | MEDIUM | CHECK-BISIMULATION | **`visita.estado` y `evento_visita.estado_nuevo` pueden divergir.** No hay constraint que garantice `visita.estado = (SELECT estado_nuevo FROM evento_visita WHERE visit_id = visita.visit_id ORDER BY timestamp DESC LIMIT 1)`. El estado de la visita puede ser actualizado directamente sin generar un evento, rompiendo la bisimulación entre la entidad y su log de eventos. | `visita` vs `evento_visita` DDL |

---

## 4. Propuestas de Mejora

| # | Issue | Pattern | Propuesta | Justificación |
|---|---|---|---|---|
| P1 | S1, S2 | PATTERN-BROKEN-DIAGRAM | **Crear triggers `BEFORE INSERT` en `visita` y `orden_servicio`** que verifiquen `NEW.patient_id = (SELECT patient_id FROM estadia WHERE stay_id = NEW.stay_id)`. Alternativa: agregar REFERENCES cross-layer (ver P5). | Las path equations PE-1 y PE-2 son constraints de conmutatividad — sin enforcement, el diagrama no conmuta. |
| P2 | S3 | PATTERN-BROKEN-DIAGRAM | **Crear trigger `BEFORE INSERT` en `encuesta_satisfaccion`** que verifique `(SELECT tipo_egreso FROM estadia WHERE stay_id = NEW.stay_id) IN ('alta_clinica', 'renuncia_voluntaria')`. | OPM SD1.6: Satisfaction Survey solo se genera en Medical Discharging y Voluntary Withdrawal Discharging. |
| P3 | S4 | PATTERN-BROKEN-DIAGRAM | **Crear tabla `requerimiento_orden_mapping`** con `(req_id FK → requerimiento_cuidado, order_id FK → orden_servicio)` para cerrar la composición plan→requerimiento→orden. | El morfismo "se transforma en" del modelo logístico necesita materialización relacional. Sin él, la cadena de trazabilidad clínica→operacional está rota. |
| P4 | R1, R2, R3 | PATTERN-DANGLING-REFERENCE | **Agregar REFERENCES explícitas a las 10 FKs cross-layer.** SQLite permite FKs a tablas ya creadas. El orden de creación (Territorial → Clínica → Operacional → Reporte) ya es correcto. La decisión de omitirlas fue por "autonomía de capas" pero es un over-design — la autonomía conceptual no requiere integridad referencial rota. | Con `PRAGMA foreign_keys = ON`, REFERENCES sin declarar = integridad nula. La autonomía de capas se preserva a nivel de pipeline/ownership, no a nivel de FK. |
| P5 | R4, B2 | PATTERN-BROKEN-DIAGRAM | **Crear trigger `BEFORE INSERT ON evento_visita`** que valide `EXISTS (SELECT 1 FROM maquina_estados_ref WHERE from_state = NEW.estado_previo AND to_state = NEW.estado_nuevo)`. Agregar CHECK constraints en `evento_visita.estado_previo` y `estado_nuevo` con el enum de 13 estados. | Sin esto, la coalgebra de estados (OPM SD10, ERD logística) es decorativa — define transiciones que no se enforzan. |
| P6 | B1 | PATTERN-ORPHAN-OBJECT | **Expandir `estadia.estado` a 6+ valores del lifecycle OPM** y crear tabla `evento_estadia(event_id, stay_id, timestamp, estado_previo, estado_nuevo)` simétrica a `evento_visita`. Estados: `pendiente_evaluacion`, `elegible`, `admitido`, `activo`, `egresado`, `fallecido`. | La estadia tiene un lifecycle tan formal como la visita (OPM SD1) pero no tiene audit trail. El lifecycle OPM de 7 pasos no tiene materialización. |
| P7 | B3 | PATTERN-REDUNDANT-BISIMILAR | **Crear trigger `AFTER INSERT ON evento_visita`** que actualice `UPDATE visita SET estado = NEW.estado_nuevo WHERE visit_id = NEW.visit_id`. Esto garantiza bisimulación: el estado de la visita es siempre el último evento. | La redundancia `visita.estado` vs `MAX(evento_visita.estado_nuevo)` es un anti-pattern coalgebraico. El estado debería ser derivado o sincronizado. |
| P8 | C1 | PATTERN-AD-HOC-CONSTRUCTION | **Crear tabla `orden_servicio_insumo(order_id, item_id, cantidad)`** como junction table para la relación many-to-many OrdenServicio↔Insumo. | El pullback OrdenServicio ×_{service_type} Insumo necesita materialización explícita. |
| P9 | C2 | PATTERN-AD-HOC-CONSTRUCTION | **Crear tabla `zona_profesional(zone_id, provider_id)`** como junction table para cobertura geográfica. Reemplaza `profesional.comunas_cobertura` (TEXT libre). | La relación many-to-many zona↔profesional es un pullback sobre cobertura territorial que hoy está representado como atributo plano ad-hoc. |
| P10 | Q1, Q2 | PATTERN-AD-HOC-CONSTRUCTION | **Extraer enums largos (≥10 valores) a tablas de referencia** con FK desde la tabla consumidora. Candidatos: `tipo_documento_ref(26)`, `tipo_requerimiento_ref(13)`, `estado_visita_ref(13)`, `codigo_observacion_ref(12)`. | Los coproductos de ≥10 valores en CHECK constraints son frágiles (ALTER TABLE para extender) y no permiten metadata (descripción, mapeo REM, activo/deprecado). Las tablas de referencia son el colímite categórico correcto. |
| P11 | Q3 | PATTERN-BROKEN-DIAGRAM | **Agregar CHECK constraint en `profesional`**: `CHECK ((profesion = 'NUTRICION' AND profesion_rem IS NULL) OR (profesion != 'NUTRICION' AND profesion_rem IS NOT NULL))`. | El functor profesion→profesion_rem tiene kernel no trivial (NUTRICION → NULL). Sin constraint explícito, el mapeo puede ser inconsistente. |
| P12 | M2 | PATTERN-NON-FUNCTORIAL-MIGRATION | **Crear tabla `estadia_episodio_fuente(stay_id, episode_id)` y eliminar `estadia.source_episode_ids` (TEXT).** Cada referencia a episodio fuente se convierte en un morfismo verificable. | TEXT concatenado no es un morfismo — es la serialización ad-hoc de un conjunto de morfismos. La tabla de junction recupera la functorialidad de la referencia. |

---

## 5. Priorización

### CRITICAL (ejecutar antes de poblar datos)

1. **P4 — Agregar REFERENCES cross-layer** (R1, R2, R3). Sin esto, la integridad referencial entre capas es inexistente. 10 columnas afectadas.
2. **P1 — Triggers PE-1/PE-2** (S1, S2). Los diagramas no conmutan sin estos triggers.

### HIGH (ejecutar antes de producción)

3. **P5 — Validar transiciones de estado** (R4, B2). La máquina de estados es decorativa sin enforcement.
4. **P6 — Lifecycle de estadía** (B1). Agregar `evento_estadia` y expandir estados.
5. **P7 — Sincronizar `visita.estado`** (B3). Trigger AFTER INSERT en evento_visita.
6. **P3 — Junction requerimiento→orden** (S4). Cerrar la composición plan→orden.
7. **P12 — Junction episodio fuente** (M2). Reemplazar TEXT concatenado.

### MEDIUM (mejora incremental)

8. **P8, P9 — Junction tables** (C1, C2). Normalizar relaciones M:N.
9. **P2 — Trigger encuesta→egreso** (S3). Restricción OPM.
10. **P10 — Tablas de referencia para enums** (Q1, Q2). Extensibilidad.
11. **P11 — Constraint profesion↔profesion_rem** (Q3). Coherencia del functor.

---

## 6. Signature de Auditoría

```
Modo:       STATIC + BEHAVIORAL
Artefactos: SCHEMA (DDL SQLite) + MODEL (Markdown) + VISUALIZATION (HTML)
Issues:     1 CRITICAL, 11 HIGH, 6 MEDIUM, 4 LOW = 22 total
Patrones:   BROKEN-DIAGRAM (6), DANGLING-REFERENCE (3), AD-HOC-CONSTRUCTION (4),
            ORPHAN-OBJECT (1), NON-FUNCTORIAL (1), REDUNDANT-BISIMILAR (1)
Migración:  Σ (fusión con pérdida) — PROGRAMACIÓN denormalizada sin functor definido
Riesgos:    Integridad referencial cross-layer NULA (CRITICAL).
            Máquina de estados decorativa sin enforcement (HIGH).
            Lifecycle OPM de estadía sin materialización (HIGH).
```
