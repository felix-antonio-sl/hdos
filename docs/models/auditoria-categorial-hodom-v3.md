# Auditoría Categorial v3 — Modelo Integrado HODOM (desde cero)

Auditoría formal conforme a FXSL Categorical Audit Patterns.
Fecha: 2026-04-06. Auditoría completa del DDL post-extensión a 87 tablas.

Artefacto auditado: `hodom-integrado.sql` (2776 líneas)

**Método**: 3 agentes de auditoría paralelos (structural, behavioral, completeness)
con consolidación y deduplicación manual.

---

## 1. Clasificación DIK

| Atributo | Valor |
|---|---|
| DIK Level | **INFORMATION** (schema S) + **KNOWLEDGE** (coalgebras, contratos OPM, migración) |
| Type | SCHEMA (DDL SQLite) |
| Dominio | Sistema completo de hospitalización domiciliaria, HSC Ñuble |
| Construcción | Pushout sobre I = {clínica, operacional, territorial, reporte} + 14 dominios funcionales |
| Entidades | 87 tablas + 4 vistas + 35 triggers + 120 índices |
| Identity keys | 8 (patient_id, stay_id, visit_id, provider_id, order_id, location_id, zone_id, establecimiento_id) |
| Normativa | DS 41/2012, Ley 20.584, Decreto 31/2024, DS 1/2022, Ley 21.375, DS 466/1984 |

---

## 2. Resumen Diagnóstico

| Dimensión | Estado | Issues |
|---|---|---|
| Structural | **FAIL** | 5 CRITICAL, 6 HIGH |
| Referential | **FAIL** | 3 CRITICAL, 4 HIGH |
| Behavioral | **FAIL** | 3 CRITICAL, 4 HIGH |
| Completeness | **WARN** | 10 MEDIUM |
| Quality | **INFO** | 8 LOW |
| Migration | **WARN** | 2 HIGH |

**Total: 11 CRITICAL, 16 HIGH, 10 MEDIUM, 8 LOW = 45 issues**

---

## 3. Issues Detectados

### 3.1 STRUCTURAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| S1 | **CRITICAL** | CHECK-PATH-EQUALITY | **13 tablas con triángulo stay_id+patient_id NO tienen trigger PE-1 alguno (ni INSERT ni UPDATE).** `herida`, `receta`, `dispensacion`, `botiquin_domiciliario`, `prestamo_equipo`, `oxigenoterapia_domiciliaria`, `solicitud_examen`, `teleconsulta`, `canasta_valorizada`, `educacion_paciente`, `evaluacion_paliativa`, `garantia_ges`, `entrega_turno_paciente`. Cualquier INSERT con patient_id ≠ estadia(stay_id).patient_id pasa sin error. | Dominios A-N |
| S2 | **CRITICAL** | CHECK-PATH-EQUALITY | **11 tablas con trigger INSERT-only PE-1 carecen de trigger UPDATE.** `consentimiento`, `valoracion_ingreso`, `sesion_rehabilitacion`, `nota_evolucion`, `evaluacion_funcional`, `epicrisis`, `indicacion_medica`, `informe_social`, `interconsulta`, `derivacion`, `protocolo_fallecimiento`. Un UPDATE a stay_id o patient_id evade la coherencia. | Registros Clínicos + Doc. Médica |
| S3 | **CRITICAL** | CHECK-PATH-EQUALITY | **`estadia` sin CHECK `fecha_egreso >= fecha_ingreso`.** Un egreso anterior al ingreso produce `dias_persona` negativos en REM A21. | L120-143 |
| S4 | HIGH | CHECK-PATH-EQUALITY | **9 pares de fechas inicio/fin sin validación de orden.** `orden_servicio`, `herida`, `oxigenoterapia_domiciliaria`, `prestamo_equipo`, `interconsulta`, `plan_cuidado`, `indicacion_medica`, `dispositivo`, `epicrisis`. | Passim |
| S5 | HIGH | CHECK-PATH-EQUALITY | **`epicrisis.tipo_egreso` y `epicrisis.fecha_ingreso/fecha_egreso` redundantes con `estadia` sin trigger de sync.** Pueden divergir silenciosamente. La epicrisis puede decir "alta_clinica" mientras estadia dice "renuncia_voluntaria". | L2084-2091 |
| S6 | HIGH | CHECK-PATH-EQUALITY | **`protocolo_fallecimiento.tipo` usa vocabulario distinto a `estadia.tipo_egreso`.** `esperado` vs `fallecido_esperado`. No hay constraint cruzado que asegure coherencia semántica. | L2346 vs L130 |
| S7 | HIGH | CHECK-COMPOSITION | **`observacion` sin `stay_id` ni `patient_id`.** Solo tiene `visit_id`. Si visit_id es NULL, la observación queda completamente huérfana — sin camino a paciente ni estadía. | L223-230 |
| S8 | HIGH | CHECK-COMPOSITION | **`procedimiento` sin `patient_id`.** Requiere 2 saltos (procedimiento→estadia→paciente) para llegar al paciente. Único registro clínico central sin enlace directo. | L209-215 |
| S9 | HIGH | CHECK-COMPOSITION | **`receta.indicacion_id` forward-references `indicacion_medica` (L2156) desde L1304.** SQLite no valida FKs en DDL time, pero una ejecución parcial del script rompe. Defecto de ordenamiento DDL. | L1304 vs L2156 |
| S10 | MEDIUM | CHECK-PATH-EQUALITY | **`trg_procedimiento_coherencia_stay`, `trg_visita_rango_temporal`, `trg_visita_ruta_provider`, `trg_rem_cupos_rc5`, `trg_encuesta_stay_required`, `trg_evento_estadia_transicion` — 6 triggers INSERT-only adicionales sin UPDATE.** | L2690-2770 |
| S11 | MEDIUM | CHECK-PATH-EQUALITY | **`visita.rem_prestacion` TEXT libre, sin REFERENCES a `catalogo_prestacion` ni CHECK.** Códigos MAI no validados. PE-8 de v2 persiste. | L481 |

### 3.2 REFERENTIAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| R1 | **CRITICAL** | CHECK-FOREIGN-KEY | **`catalogo_prestacion` es ORPHAN — ninguna tabla tiene FK hacia ella.** 76 prestaciones MAI sin consumidor. `visita.rem_prestacion` y `procedimiento.codigo` son TEXT libre. El catálogo existe pero no se usa. | L64-81 |
| R2 | **CRITICAL** | CHECK-FOREIGN-KEY | **`sla` es ORPHAN — desconectada de `orden_servicio` y `reporte_cobertura`.** `sla.service_type` y `orden_servicio.service_type` son TEXT libres sin FK ni CHECK compartido. Las definiciones SLA no influyen en ningún constraint de datos. | L379-389 |
| R3 | **CRITICAL** | CHECK-FOREIGN-KEY | **`conductor` es ORPHAN operacional — nunca referenciado por `ruta`.** `ruta.provider_id` referencia `profesional`, no `conductor`. Los conductores no pueden ser asignados a rutas. Dominio I (Transporte) desconectado de Capa 2 (Operacional). | L1862-1880 vs L427-443 |
| R4 | HIGH | CHECK-FOREIGN-KEY | **`lista_espera.establecimiento_origen` TEXT libre** — debería ser REFERENCES establecimiento. | L1562 |
| R5 | HIGH | CHECK-FOREIGN-KEY | **`paciente.cesfam` TEXT libre** — debería referenciar un catálogo de establecimientos APS. | L97 |
| R6 | MEDIUM | CHECK-FOREIGN-KEY | **`estadia_episodio_fuente.episode_id` sin validación** — intencional (pipeline CSV) pero no documentado. | L861 |
| R7 | LOW | CHECK-FOREIGN-KEY | **`prescriptor_id` en `receta` es la única FK a `profesional` con nombre distinto a `provider_id`** — rompe convención. | L1307 |

### 3.3 BEHAVIORAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| B1 | **CRITICAL** | CHECK-BISIMULATION | **`paciente.estado_actual` sin event log, sin sync con `estadia.estado`, sin transition guard.** Cuando `trg_evento_estadia_sync_estado` cambia `estadia.estado` a `egresado`, `paciente.estado_actual` no se toca. Los dos estados derivan independientemente. No existe `evento_paciente` ni trigger de propagación. | L99 |
| B2 | **CRITICAL** | CHECK-INTERFACE-CONFORMANCE | **`medicacion.via` (5 valores) es subconjunto estricto de `receta.via` (10 valores).** Una receta con `via='inhalatoria'` no puede ser registrada en `medicacion` — CHECK violation. Rutas `inhalatoria`, `SNG`, `sublingual`, `transdermica`, `rectal` son prescribibles pero no administrables en el modelo. | L247 vs L1314 |
| B3 | **CRITICAL** | CHECK-BISIMULATION | **UPDATE directo a `estadia.estado` o `visita.estado` bypassa toda la coalgebra de transiciones.** No hay BEFORE UPDATE trigger en `estadia` ni en `visita` que valide contra `maquina_estados_*_ref`. Solo los INSERTs a las tablas de eventos son validados. | L120, L472 |
| B4 | HIGH | CHECK-INTERFACE-CONFORMANCE | **20 tablas con `estado` CHECK tienen coalgebra no enforced.** Solo `visita` y `estadia` tienen event tables + transition tables + sync triggers. Las otras 20 máquinas de estado (plan_cuidado, herida, receta, equipo_medico, solicitud_examen, etc.) no tienen event log, transition ref, ni sync trigger. | Passim |
| B5 | HIGH | CHECK-INTERFACE-CONFORMANCE | **`sesion_rehabilitacion.tipo` no está cross-validada contra `profesional.profesion`.** Un MEDICO puede insertar una sesión tipo `fonoaudiologia`. | L1177 |
| B6 | HIGH | CHECK-BEHAVIORAL-EQUIVALENCE | **`nota_evolucion.tipo` y `valoracion_ingreso.tipo` no cubren TENS.** Un TENS no tiene `tipo` correspondiente en notas ni valoraciones — cobertura profesional incompleta. | L1144, L919 |
| B7 | MEDIUM | CHECK-BEHAVIORAL-EQUIVALENCE | **Vocabulario `prioridad` fragmentado en 5 tablas.** `sla/orden_servicio` usan 4 valores, `solicitud_examen` usa 2 distintos, `interconsulta` usa 3 distintos. Imposible agregar prioridades cross-dominio. | Passim |

### 3.4 COMPLETENESS

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| C1 | MEDIUM | CHECK-INFO-COMPLETE | **`procedimiento.estado`, `alerta.estado`, `profesional.estado`, `orden_servicio.estado`, `ruta.estado` — 5 columnas `estado` sin CHECK constraint.** Texto libre donde debería haber vocabulario controlado. | L215, L304, L365, L426, L439 |
| C2 | MEDIUM | CHECK-INFO-COMPLETE | **`establecimiento.tipo`, `ubicacion.territory_type` — columnas categóricas sin CHECK.** `zona.tipo` sí tiene CHECK; `ubicacion.territory_type` debería tener el mismo. | L23, L49 |
| C3 | MEDIUM | CHECK-INFO-COMPLETE | **`kpi_diario` sin `establecimiento_id`** — agrega por zona pero no por establecimiento. No escalable a multi-sede. | L613 |
| C4 | MEDIUM | CHECK-INFO-COMPLETE | **`condicion`, `procedimiento`, `documentacion` con estado mutable pero sin `updated_at`.** DS 41/2012 requiere trazabilidad temporal de cambios. | L150, L209, L270 |
| C5 | MEDIUM | CHECK-INFO-COMPLETE | **`matriz_distancia` tiene `updated_at` pero no `created_at`.** Único caso invertido. | L57-65 |
| C6 | MEDIUM | CHECK-INFO-COMPLETE | **`sla.service_type` y `orden_servicio.service_type` sin vocabulario compartido ni tabla de referencia.** | L389, L415 |
| C7 | MEDIUM | CHECK-INFO-COMPLETE | **`catalogo_prestacion.estamento` TEXT libre** — debería compartir vocabulario con `profesional.profesion`. | L74 |
| C8 | MEDIUM | CHECK-INFO-COMPLETE | **~25 columnas FK sin índice.** `patient_id` en tablas nuevas (receta, dispensacion, teleconsulta, etc.) carece de índice individual. Impacto en queries por paciente. | Passim |
| C9 | MEDIUM | CHECK-INFO-COMPLETE | **`evento_estadia/evento_visita` usan AUTOINCREMENT** — rompe principio de IDs deterministas declarado en el proyecto. | L496, L794 |
| C10 | LOW | CHECK-INFO-COMPLETE | **`canasta_valorizada` almacena conteos derivables** (`visitas_realizadas`, `dias_cama`, `procedimientos`, `examenes`) sin provenance. | L1893-1915 |

### 3.5 QUALITY

| # | Sev. | Check | Descripción |
|---|---|---|---|
| Q1 | LOW | CHECK-UNIVERSAL-CONSTRUCTION | Enums ≥10 valores hardcodeados en CHECK (documentacion.tipo=26, requerimiento_cuidado.tipo=13, visita.estado=13, valoracion_hallazgo.dominio=29, sesion_rehabilitacion_item.categoria=23). Tablas de referencia serían el colímite correcto. |
| Q2 | LOW | CHECK-FUNCTORIALITY | `ubicacion.territory_type` vs `zona.tipo` — naming inconsistente en misma capa territorial (`territory_type` vs `tipo`). |
| Q3 | LOW | CHECK-FUNCTORIALITY | `item_id` como PK en `insumo` y en `sesion_rehabilitacion_item` — colisión de nombres en queries sin alias. |
| Q4 | LOW | CHECK-FUNCTORIALITY | `cuidador.parentesco` nullable sin justificación — dato clínico relevante para representación legal. |
| Q5 | LOW | CHECK-FUNCTORIALITY | `visita.resultado` y `visita.doc_estado` TEXT libre sin CHECK. |
| Q6 | LOW | CHECK-FUNCTORIALITY | `nota_evolucion.medicamentos_texto` duplica datos de `medicacion` sin sync. |
| Q7 | LOW | CHECK-UNIVERSAL-CONSTRUCTION | `ruta.total_visitas` es agregado materializado sin trigger de mantenimiento. |
| Q8 | LOW | CHECK-FUNCTORIALITY | `evento_adverso` no tiene `visit_id` — un evento adverso durante una visita no se puede vincular a ella. |

### 3.6 MIGRATION

| # | Sev. | Check | Descripción |
|---|---|---|---|
| M1 | HIGH | CHECK-MIGRATION-FUNCTOR | **DDL nunca poblado con datos reales.** 35 triggers sin validación empírica. Bugs latentes probables. |
| M2 | HIGH | CHECK-MIGRATION-FUNCTOR | **Functor Σ para PROGRAMACIÓN legacy sin especificar.** Matriz paciente×día→código no tiene descomposición formal definida. |

---

## 4. Priorización de Reparaciones

### CRITICAL (11 issues — ejecutar antes de poblar datos)

| # | Issue(s) | Reparación | Esfuerzo |
|---|---|---|---|
| P1 | S1 | **Crear 13 triggers INSERT PE-1** para herida, receta, dispensacion, botiquin, prestamo_equipo, o2_domiciliaria, solicitud_examen, teleconsulta, canasta, educacion, eval_paliativa, garantia_ges, entrega_turno_paciente. | 13 triggers |
| P2 | S2, S10 | **Crear 17 triggers UPDATE PE-1** para todas las tablas con INSERT-only. | 17 triggers |
| P3 | S3 | **Agregar CHECK `(fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso)` a `estadia`.** | 1 CHECK |
| P4 | B1 | **Crear trigger `trg_evento_estadia_sync_paciente`** que actualice `paciente.estado_actual` cuando `estadia.estado` cambie a `egresado` o `fallecido`. | 1 trigger |
| P5 | B2 | **Expandir `medicacion.via`** de 5 a 10 valores para alinear con `receta.via`. | 1 ALTER (recrear tabla en SQLite) |
| P6 | B3 | **Crear triggers BEFORE UPDATE OF estado** en `estadia` y `visita` que validen contra `maquina_estados_*_ref`. | 2 triggers |
| P7 | R1 | **Conectar `catalogo_prestacion`**: agregar `visita.prestacion_id REFERENCES catalogo_prestacion` o crear FK desde `procedimiento.codigo`. | 1-2 columnas |
| P8 | R2 | **Crear tabla `service_type_ref`** y refactorizar `sla.service_type` y `orden_servicio.service_type` como FKs. | 1 tabla + 2 FKs |
| P9 | R3 | **Agregar `ruta.conductor_id REFERENCES conductor`** para conectar Dominio I con Capa 2. | 1 columna |
| P10 | S7 | **Agregar `observacion.stay_id REFERENCES estadia` y `observacion.patient_id REFERENCES paciente`.** | 2 columnas |
| P11 | S8 | **Agregar `procedimiento.patient_id REFERENCES paciente`.** | 1 columna |

### HIGH (16 issues — ejecutar antes de producción)

| # | Issue(s) | Reparación |
|---|---|---|
| P12 | S4 | Agregar 9 CHECKs de orden temporal (fecha_fin >= fecha_inicio). |
| P13 | S5 | Crear trigger sync epicrisis↔estadia para tipo_egreso y fechas. |
| P14 | S6 | Crear trigger validación semántica protocolo.tipo vs estadia.tipo_egreso. |
| P15 | S9 | Reordenar DDL: mover `indicacion_medica` antes de `receta`. |
| P16 | B4 | Documentar explícitamente qué máquinas de estado son "soft" (sin enforcement). |
| P17 | B5 | Crear trigger `sesion_rehabilitacion.tipo` vs `profesional.profesion`. |
| P18 | B6 | Agregar 'tens' a `nota_evolucion.tipo` y `valoracion_ingreso.tipo`. |
| P19 | R4, R5 | Agregar REFERENCES para `lista_espera.establecimiento_origen` y `paciente.cesfam`. |
| P20 | C1 | Agregar CHECK constraints a 5 columnas `estado` libres. |
| P21 | C6 | Crear `service_type_ref` (mismo que P8). |
| P22 | C8 | Crear ~25 índices faltantes en columnas FK. |
| P23 | M1 | Implementar Stage 5 (`populate_sqlite.py`) para validación empírica. |
| P24 | M2 | Especificar formalmente functor Σ para PROGRAMACIÓN legacy. |

### MEDIUM (10 issues)

P25-P34: CHECKs de vocabulario (C2, C7), `updated_at` faltantes (C4, C5), `kpi_diario.establecimiento_id` (C3), AUTOINCREMENT→TEXT hash (C9), prioridad unificada (B7), `evento_adverso.visit_id` (Q8).

### LOW (8 issues)

P35-P42: Tablas de referencia para enums (Q1), naming (Q2, Q3), parentesco nullable (Q4), campos TEXT libre (Q5), redundancias documentadas (Q6, Q7, C10).

---

## 5. Análisis Coalgebraico

### Carrier de máquinas de estado: cobertura actual

| Carrier | Event table | Transition ref | Sync trigger | BEFORE UPDATE guard | Enforcement |
|---|---|---|---|---|---|
| `visita.estado` (13 estados) | `evento_visita` | `maquina_estados_ref` | `trg_evento_visita_sync_estado` | **NO** | **Parcial** — INSERTs validados, UPDATEs directos no |
| `estadia.estado` (6 estados) | `evento_estadia` | `maquina_estados_estadia_ref` | `trg_evento_estadia_sync_estado` | **NO** | **Parcial** |
| `paciente.estado_actual` (4 estados) | **NO** | **NO** | **NO** | **NO** | **Ninguno** |
| Otros 20 carriers | **NO** | **NO** | **NO** | **NO** | **Ninguno** |

### Bisimulación rota: paciente ↔ estadia

```
paciente.estado_actual ≠ f(estadia.estado) en general

El functor esperado:
  estadia.estado = 'activo'    → paciente.estado_actual = 'activo'
  estadia.estado = 'egresado'  → paciente.estado_actual = 'egresado' (si no hay otra estadia activa)
  estadia.estado = 'fallecido' → paciente.estado_actual = 'fallecido'

Pero nada enforza esta relación. Son dos coalgebras independientes
sobre carriers distintos sin homomorfismo entre ellas.
```

### Flujo de medicación roto

```
receta.via: {oral, IV, SC, IM, topica, inhalatoria, SNG, rectal, sublingual, transdermica}
                         ↓ dispensacion (no verifica via)
medicacion.via: {oral, IV, SC, IM, topica}  ← 5 valores faltantes

El functor prescripcion → administracion no preserva el dominio.
Im(receta.via) ⊄ Dom(medicacion.via)
```

---

## 6. Objetos Huérfanos (PATTERN-ORPHAN-OBJECT)

| Tabla | Tipo de huérfano | Impacto |
|---|---|---|
| `catalogo_prestacion` | **Structural** — nunca referenciada por FK | El catálogo MAI existe pero es invisible al modelo operacional |
| `sla` | **Structural** — nunca referenciada por FK | Definiciones SLA completamente desconectadas de órdenes y reportes |
| `conductor` | **Structural** — nunca referenciada por FK, `ruta` no tiene `conductor_id` | Dominio Transporte aislado |
| `kpi_diario` | Leaf output — no referenciado | Aceptable (tabla materializada) |
| `descomposicion_temporal` | Leaf output — no referenciado | Aceptable |
| `reporte_cobertura` | Leaf output — no referenciado | Aceptable |
| `configuracion_programa` | Leaf singleton — no referenciado | Aceptable |
| `reunion_equipo` | Leaf — no referenciado | Aceptable |
| `capacitacion` | Leaf — no referenciado | Aceptable |
| `canasta_valorizada` | Leaf output — no referenciado | Aceptable |
| `compra_servicio` | Leaf output — no referenciado | Aceptable |

Los 3 primeros son **huérfanos estructurales críticos** — entidades creadas para un propósito que el modelo no conecta.

---

## 7. Functor Information Loss

| Transformación | Operador | Perdido |
|---|---|---|
| receta.via → medicacion.via | Π (restricción) | 5 vías de administración (`inhalatoria`, `SNG`, `sublingual`, `transdermica`, `rectal`) no representables en administración |
| estadia.estado → paciente.estado_actual | — (no existe functor) | La sincronización paciente↔estadia no está implementada; los carriers divergen |
| indicacion_medica → receta | Forward reference DDL | Dependencia de orden de creación del script |
| Formularios papel → DDL | Σ (fusión) | Layout visual, firmas, sellos, formato libre narrativo |

---

## 8. Estadísticas de Cobertura de Triggers

```
Tablas con triángulo stay_id + patient_id:  ~27
  Con INSERT trigger PE-1:                  14  (52%)
  Con UPDATE trigger PE-1:                   6  (22%)
  Sin trigger alguno:                       13  (48%)

Máquinas de estado (tablas con estado CHECK): 22
  Con coalgebra completa (event + ref + sync):  2  (9%)  — visita, estadia
  Sin enforcement alguno:                      20  (91%)

Path equations declaradas (PE-1..PE-10):      10
  Enforced por trigger INSERT+UPDATE:           3  (PE-1, PE-2, PE-7)
  Enforced solo INSERT:                         2  (PE-7 parcial, PE-8 no)
  Sin enforcement:                              5  (PE-3, PE-4, PE-5, PE-9, PE-10)
```

---

## 9. Signature

```
Modo:           STATIC + BEHAVIORAL + MIGRATION
Artefacto:      SCHEMA (DDL SQLite 2776 líneas, 87 tablas)
Issues:         11 CRITICAL, 16 HIGH, 10 MEDIUM, 8 LOW = 45 total
Patrones:       BROKEN-DIAGRAM (18), DANGLING-REFERENCE (4), ORPHAN-OBJECT (3),
                AD-HOC-CONSTRUCTION (5), NON-FUNCTORIAL (3), REDUNDANT-BISIMILAR (3)
Migración:      Schema sin instancias (M1). Functor Σ legacy sin especificar (M2).
Riesgos:        48% de triángulos PE-1 sin trigger alguno (CRITICAL).
                91% de máquinas de estado sin enforcement coalgebraico (HIGH).
                Functor receta→medicacion no preserva dominio de via (CRITICAL).
                paciente.estado_actual desincronizado de estadia.estado (CRITICAL).
                3 entidades huérfanas estructurales (catalogo_prestacion, sla, conductor).
                DDL nunca poblado — 35 triggers sin validación empírica.
```
