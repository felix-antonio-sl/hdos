# Auditoría Categorial Exhaustiva v2 — Modelo Integrado HODOM

Segunda auditoría formal conforme a FXSL Categorical Audit Patterns.
Fecha: 2026-04-06. Auditoría post-correcciones.

Artefactos auditados:

- `hodom-integrado.sql` (858 líneas, DDL SQLite post-correcciones)
- `modelo-integrado-hodom.md` (1127 líneas, modelo conceptual)
- `erd-modelo-integrado-hodom.html` (visualización)
- `auditoria-categorial-hodom.md` (auditoría v1, 22 issues, 12 propuestas)

---

## 1. Clasificación DIK

| Atributo | Valor |
|---|---|
| DIK Level | **INFORMATION** (schema S) + **KNOWLEDGE** (migración, contratos OPM, coalgebras de estado) |
| Type | SCHEMA (DDL) + MODEL (documento conceptual) |
| Dominio | Hospitalización domiciliaria, Hospital San Carlos, Ñuble |
| Construcción declarada | Grothendieck ∫F sobre I = {clínica, operacional, territorial, reporte} |
| Entidades | 37 tablas + 3 vistas + 1 tabla seed |
| Identity keys | 8 (patient_id, stay_id, visit_id, provider_id, order_id, location_id, zone_id, establecimiento_id) |
| Path equations | 10 declaradas (PE-1..PE-10) + 5 reglas consistencia REM (RC-1..RC-5) |
| Triggers | 6 (PE-1, PE-2, PE-7, transición visita, sync estado visita, coherencia profesion_rem) |
| Junction tables | 5 (requerimiento_orden_mapping, orden_servicio_insumo, zona_profesional, estadia_episodio_fuente, evento_estadia) |

---

## 2. Estado de Correcciones v1

Primero, verificación de las 12 propuestas de la auditoría v1:

| Propuesta | Issue | Estado | Verificación |
|---|---|---|---|
| P1 — Triggers PE-1/PE-2 | S1, S2 | **APLICADA** | `trg_visita_pe1`, `trg_orden_pe2` en DDL línea 729-745 |
| P2 — Trigger PE-7 encuesta | S3 | **APLICADA** | `trg_encuesta_pe7` en DDL línea 749-757 |
| P3 — Junction requerimiento→orden | S4 | **APLICADA** | `requerimiento_orden_mapping` en DDL línea 761-766 |
| P4 — REFERENCES cross-layer | R1, R2, R3 | **PARCIAL** | R1 y R2 ya tenían REFERENCES (la v1 fue incorrecta en R1). **R3 persiste**: 4 FKs cross-layer sin REFERENCES |
| P5 — Validar transiciones estado | R4, B2 | **APLICADA** | `trg_evento_visita_transicion` en DDL línea 770-780 |
| P6 — Lifecycle estadía | B1 | **APLICADA** | `evento_estadia` en DDL línea 784-803 |
| P7 — Sync visita.estado | B3 | **APLICADA** | `trg_evento_visita_sync_estado` en DDL línea 807-814 |
| P8 — Junction orden↔insumo | C1 | **APLICADA** | `orden_servicio_insumo` en DDL línea 818-824 |
| P9 — Junction zona↔profesional | C2 | **APLICADA** | `zona_profesional` en DDL línea 828-833 |
| P10 — Tablas referencia para enums | Q1, Q2 | **NO APLICADA** | Enums largos siguen hardcodeados en CHECK constraints |
| P11 — Constraint profesion↔profesion_rem | Q3 | **APLICADA** | `trg_profesional_coherencia_rem` en DDL línea 837-845 |
| P12 — Junction episodio fuente | M2 | **PARCIAL** | `estadia_episodio_fuente` creada, pero `estadia.source_episode_ids` TEXT **no fue eliminado** |

**Corrección a la auditoría v1**: R1 era un falso positivo. Las 6 FKs listadas (`visita.stay_id`, `visita.patient_id`, `orden_servicio.stay_id`, `orden_servicio.patient_id`, `registro_llamada.patient_id`, `visita.location_id`) **ya tenían REFERENCES declaradas** en el DDL original. La auditoría v1 reportó incorrectamente que eran TEXT sin REFERENCES.

---

## 3. Resumen Diagnóstico v2

| Dimensión | Estado | Issues nuevos | Issues persistentes (v1) |
|---|---|---|---|
| Structural | **WARN** | 5 nuevos | 2 de v1 |
| Referential | **WARN** | 2 nuevos | 1 de v1 (R3) |
| Behavioral | **FAIL** | 5 nuevos | — |
| Completeness | **WARN** | 3 nuevos | 1 de v1 (Q1/Q2) |
| Quality | **INFO** | 3 nuevos | 1 de v1 (Q4) |
| Migration | **WARN** | 2 nuevos | 1 de v1 (M1) |
| Meta-Conceptual | **INFO** | 1 nuevo | — |

**Total: 3 CRITICAL, 10 HIGH, 8 MEDIUM, 5 LOW = 26 issues**

---

## 4. Issues Detectados

### 4.1 STRUCTURAL (CHECK-PATH-EQUALITY, CHECK-COMPOSITION)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| S1n | **CRITICAL** | CHECK-PATH-EQUALITY | **Triggers PE-1, PE-2, PE-7 son BEFORE INSERT solamente — no protegen contra UPDATE.** Un `UPDATE visita SET patient_id = 'X' WHERE visit_id = 'Y'` viola PE-1 sin activar ningún trigger. Lo mismo para `UPDATE orden_servicio SET patient_id` (PE-2) y `UPDATE encuesta_satisfaccion SET stay_id` (PE-7). Cualquier UPDATE directo a estas columnas destruye la conmutatividad del diagrama sin impedimento. | `trg_visita_pe1` DDL:729, `trg_orden_pe2` DDL:738, `trg_encuesta_pe7` DDL:749 |
| S2n | HIGH | CHECK-PATH-EQUALITY | **PE-8 persiste sin enforcement.** `procedimiento.codigo` sigue siendo TEXT libre sin FK a `catalogo_prestacion.codigo_mai`. El morfismo `Procedimiento → CatalogoPrestacion` declarado en PE-8 no tiene materialización. Cualquier código inventado es aceptado. | `procedimiento.codigo` DDL:206, `catalogo_prestacion` DDL:64 |
| S3n | HIGH | CHECK-PATH-EQUALITY | **PE-10 persiste sin enforcement.** `registro_llamada.estado_paciente` no se valida contra la existencia real de una estadía activa. La path equation `estado_paciente='activo' ↔ ∃ Estadia(s) WHERE s.fecha_egreso IS NULL` es puramente documental. | `registro_llamada` DDL:519-537 |
| S4n | HIGH | CHECK-PATH-EQUALITY | **Path equation no declarada: `documentacion.patient_id = estadia(documentacion.stay_id).patient_id`.** `documentacion` tiene tanto `stay_id` como `patient_id` como FKs independientes. Es el mismo patrón de PE-1 (triángulo patient↔stay↔entity) pero sin trigger. Un documento puede apuntar a un paciente que no corresponde a la estadía referenciada. | `documentacion` DDL:262-283 |
| S5n | HIGH | CHECK-PATH-EQUALITY | **Path equation no declarada: `medicacion.stay_id = visita(medicacion.visit_id).stay_id`.** `medicacion` tiene dual FK a `estadia` (via stay_id) y a `visita` (via visit_id, sin REFERENCES). Si ambos están presentes, no hay constraint que garantice coherencia entre los dos paths. Lo mismo aplica a `procedimiento`. | `medicacion` DDL:233-244, `procedimiento` DDL:201-209 |
| S6n | MEDIUM | CHECK-PATH-EQUALITY | **Path equation no declarada: fecha de visita dentro del rango de estadía.** No hay constraint que impida `visita.fecha < estadia.fecha_ingreso` o `visita.fecha > estadia.fecha_egreso`. Una visita puede registrarse fuera del periodo de hospitalización. | `visita.fecha` DDL:458, `estadia.fecha_ingreso/fecha_egreso` DDL:118-119 |
| S7n | MEDIUM | CHECK-COMPOSITION | **Composición `visita → ruta → profesional` no conmuta con `visita → profesional`.** `visita.route_id → ruta.provider_id` y `visita.provider_id` son dos paths al mismo `profesional`. No hay constraint que garantice `ruta(visita.route_id).provider_id = visita.provider_id`. Un profesional puede ser asignado a una visita en una ruta que pertenece a otro profesional. | `visita` DDL:448-477, `ruta` DDL:427-443 |

### 4.2 REFERENTIAL (CHECK-FOREIGN-KEY)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| R1n | HIGH | CHECK-FOREIGN-KEY | **4 FKs cross-layer sin REFERENCES persisten (ex-R3 de v1).** `procedimiento.visit_id`, `observacion.visit_id`, `medicacion.visit_id`, `documentacion.visit_id` — las 4 columnas en capa Clínica que referencian `visita` (capa Operacional) siguen siendo TEXT libre. Con `PRAGMA foreign_keys = ON`, cualquier visit_id inventado es aceptado. Los comentarios en el DDL dicen `-- FK cross-layer` pero la intención no se materializa como REFERENCES. | DDL:203, 217, 237, 264 |
| R2n | MEDIUM | CHECK-FOREIGN-KEY | **`orden_servicio.service_type` ↔ `sla.service_type` sin FK.** El modelo conceptual declara `OrdenServicio }o--|| SLA : "meta SLA"` pero no existe FK ni tabla de referencia `service_type_ref`. Una orden puede tener un service_type para el cual no existe SLA definido. El lookup es puramente aplicativo. | `orden_servicio` DDL:403, `sla` DDL:379 |
| R3n | LOW | CHECK-FOREIGN-KEY | **`encuesta_satisfaccion.stay_id` es nullable — bypass de PE-7.** `trg_encuesta_pe7` tiene `WHEN NEW.stay_id IS NOT NULL`. Una encuesta con `stay_id = NULL` evade completamente la restricción OPM SD1.6. La encuesta queda "suelta" sin vínculo verificable a una estadía con egreso válido. | `encuesta_satisfaccion` DDL:304-328, `trg_encuesta_pe7` DDL:749 |

### 4.3 BEHAVIORAL (CHECK-INTERFACE-CONFORMANCE, CHECK-BISIMULATION)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| B1n | **CRITICAL** | CHECK-BISIMULATION | **`evento_estadia` no tiene trigger de validación de transiciones.** A diferencia de `evento_visita` (que tiene `trg_evento_visita_transicion`), `evento_estadia` acepta cualquier par `(estado_previo, estado_nuevo)`. No existe `maquina_estados_estadia_ref`. El lifecycle OPM SD1 de 7 pasos (elegibilidad→ingreso→planificación→ejecución→monitoreo→egreso→seguimiento) no tiene enforcement: la transición `pendiente_evaluacion → fallecido` pasaría sin error. | `evento_estadia` DDL:784-803 |
| B2n | **CRITICAL** | CHECK-BISIMULATION | **`evento_estadia` no tiene trigger de sincronización con `estadia.estado`.** `evento_visita` tiene `trg_evento_visita_sync_estado` que sincroniza `visita.estado` con el último evento. `evento_estadia` no tiene equivalente. `estadia.estado` y el último `evento_estadia.estado_nuevo` pueden divergir libremente. La estadía tiene dos representaciones de estado sin bisimulación garantizada. | `evento_estadia` DDL:784-803 vs `trg_evento_visita_sync_estado` DDL:807 |
| B3n | HIGH | CHECK-INTERFACE-CONFORMANCE | **Dominio de estados inconsistente: `estadia.estado` ≠ `evento_estadia.estado_nuevo`.** `estadia.estado` acepta `{activo, egresado, fallecido}` (3 valores). `evento_estadia.estado_nuevo` acepta `{pendiente_evaluacion, elegible, admitido, activo, egresado, fallecido}` (6 valores). Si existiera un trigger de sincronización (B2n), un estado `pendiente_evaluacion` en evento_estadia violaría el CHECK de estadia.estado. **Los dos enums son irreconciliables sin expandir `estadia.estado`.** | `estadia.estado` DDL:120, `evento_estadia.estado_nuevo` DDL:789-792 |
| B4n | HIGH | CHECK-BISIMULATION | **`trg_evento_visita_transicion` no valida que `estado_previo` sea el estado actual de la visita.** El trigger verifica que la transición `(estado_previo → estado_nuevo)` exista en `maquina_estados_ref`, pero no verifica que `estado_previo = visita.estado`. Se puede insertar un evento con `estado_previo='COMPLETA'` cuando `visita.estado='PROGRAMADA'`. La coalgebra de transición no verifica el estado actual del carrier — solo la existencia de la arista en el autómata. | `trg_evento_visita_transicion` DDL:770-780 |
| B5n | MEDIUM | CHECK-BISIMULATION | **Triggers de sincronización (`trg_evento_visita_sync_estado`) son AFTER INSERT solamente.** Si un `evento_visita` se actualiza vía UPDATE (cambio de `estado_nuevo`), `visita.estado` no se re-sincroniza. La bisimulación se mantiene solo bajo INSERTs, no bajo UPDATEs de corrección. | `trg_evento_visita_sync_estado` DDL:807-814 |

### 4.4 COMPLETENESS (CHECK-INFO-COMPLETE)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| C1n | HIGH | CHECK-INFO-COMPLETE | **`estadia.source_episode_ids` TEXT persiste junto a `estadia_episodio_fuente`.** P12 creó la junction table pero no eliminó el campo TEXT. Hay dos representaciones del mismo dato: el TEXT concatenado y la tabla normalizada. Pueden divergir. El TEXT concatenado es un vestigio no-functorial que debió ser eliminado. | `estadia.source_episode_ids` DDL:132, `estadia_episodio_fuente` DDL:849-855 |
| C2n | MEDIUM | CHECK-INFO-COMPLETE | **Enums largos siguen hardcodeados en CHECK constraints (ex-Q1/Q2 de v1).** `documentacion.tipo` (26 valores), `requerimiento_cuidado.tipo` (13), `visita.estado` (13), `observacion.codigo` (12). Agregar un tipo de documento requiere ALTER TABLE. No permiten metadata (descripción, mapeo REM, activo/deprecado). Son coproductos ad-hoc donde tablas de referencia serían el colímite categórico correcto. | DDL:267-278, 169-175, 464-469, 220-225 |
| C3n | MEDIUM | CHECK-INFO-COMPLETE | **`registro_llamada` no tiene FK a `estadia`.** Una llamada se vincula a `paciente` pero no a una estadía específica. Si un paciente tiene múltiples estadías, la llamada no se puede atribuir a una hospitalización concreta. Esto rompe la trazabilidad `llamada → estadía → plan_cuidado` necesaria para seguimiento post-egreso (OPM SD1.7). | `registro_llamada` DDL:519-537 |
| C4n | LOW | CHECK-INFO-COMPLETE | **`paciente.estado_actual` no tiene CHECK constraint.** Es TEXT libre. Contraste con `estadia.estado` que tiene enum de 3 valores. El "estado actual" del paciente no tiene vocabulario controlado — podría ser cualquier string. | `paciente.estado_actual` DDL:96 |

### 4.5 QUALITY (CHECK-UNIVERSAL-CONSTRUCTION, CHECK-FUNCTORIALITY)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| Q1n | MEDIUM | CHECK-FUNCTORIALITY | **Reglas de consistencia REM (RC-1..RC-5) sin enforcement.** RC-2 (`total >= sexo_masculino + sexo_femenino`), RC-3 (`Σ(origen_*) = total`), RC-5 (`disponibles = programados - utilizados`) son path equations que no tienen CHECKs ni triggers. Datos REM inconsistentes pasarían al reporte MINSAL sin validación en la capa de datos. | `rem_personas_atendidas` DDL:549-572, `rem_cupos` DDL:589-601 |
| Q2n | LOW | CHECK-UNIVERSAL-CONSTRUCTION | **`kpi_diario` y `descomposicion_temporal` sin provenance.** Son tablas de materialización (capa Reporte) pero no registran qué visitas/rutas fueron la fuente. No son reproducibles — si se borran, no hay forma de regenerarlas desde los datos base sin re-ejecutar el batch. Violan el principio de provenance completa declarado en el modelo conceptual. | `kpi_diario` DDL:604-619, `descomposicion_temporal` DDL:622-633 |
| Q3n | LOW | CHECK-FUNCTORIALITY | **`sla` no tiene índice en `(service_type, prioridad)`.** El patrón de lookup natural es WHERE service_type = X AND prioridad = Y, pero no hay índice compuesto. Subóptimo para consultas de validación SLA. | `sla` DDL:379-389 |

### 4.6 MIGRATION (CHECK-MIGRATION-FUNCTOR, CHECK-CONSTRAINT-PRESERVATION)

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| M1n | HIGH | CHECK-MIGRATION-FUNCTOR | **El DDL es un schema sin instancias — nunca ha sido poblado con datos.** No existe ETL `CSV pipeline → SQLite`. El pipeline actual (4 stages) produce CSVs; el DDL describe un target schema que ningún proceso alimenta. Los 6 triggers y todas las constraints son **teóricamente correctos pero empíricamente no verificados**. Los triggers podrían tener bugs latentes (e.g., subqueries que retornan NULL en edge cases) que solo se descubrirían con datos reales. | DDL completo |
| M2n | HIGH | CHECK-CONSTRAINT-PRESERVATION | **Migración `PROGRAMACIÓN legacy → orden_servicio + visita` (ex-M1 v1) sigue sin functor definido.** La PROGRAMACIÓN es una matriz `paciente×día→código_actividad`. La descomposición en tuplas `(patient_id, fecha, service_type)` → `orden_servicio` + `visita` no tiene especificación formal. Es el Σ functor más riesgoso del sistema: fusiona estructura denormalizada con pérdida potencial de la semántica de "semana programada". | Modelo conceptual §Auditoría Legacy |
| M3n | MEDIUM | CHECK-CONSTRAINT-PRESERVATION | **Migración `Stage 4 canonical → SQLite` necesita reconciliar dos identity resolution strategies.** El pipeline CSV usa identity resolution (RUT → nombre+fecha → nombre+contacto → legacy key) mientras que el DDL SQLite asume patient_id como hash determinista ya resuelto. El functor de migración debe componer: `resolve_identity ∘ ingest` pero no se especifica qué pasa con identidades parciales o en conflicto cuando se cargan en la BD. | Stage 4 pipeline vs `paciente` DDL:84-98 |

### 4.7 META-CONCEPTUAL

| # | Sev. | Check | Descripción | Ubicación |
|---|---|---|---|---|
| MC1 | LOW | — | **La construcción categórica declarada (Grothendieck ∫F) no corresponde a la estructura real.** Una fibración de Grothendieck sobre I = {clínica, operacional, territorial, reporte} requiere funtores F(α): F(j)→F(i) para cada morfismo α: i→j en I. Pero I no tiene morfismos explícitos entre las capas — son 4 objetos discretos. La estructura real es un **colímite (pushout)**: `∐ᵢ F(i) / ~` donde `~` identifica objetos por identity keys compartidas. La composición inter-capa no es "cambio de fibra a lo largo de la base" sino "identificación en el coequalizer". La implicación práctica: las path equations inter-capa (PE-1..PE-5) son constraints del pushout, no secciones de la fibración. Esto no invalida el DDL pero sí la narrativa formal. | Header DDL:4, Modelo conceptual línea 8-10 |

---

## 5. Priorización de Reparaciones

### CRITICAL (ejecutar antes de poblar datos)

| # | Issue | Pattern | Propuesta | Justificación |
|---|---|---|---|---|
| P1v2 | S1n | BROKEN-DIAGRAM | **Crear triggers BEFORE UPDATE para PE-1, PE-2 y PE-7.** Duplicar la lógica de `trg_visita_pe1`, `trg_orden_pe2` y `trg_encuesta_pe7` como triggers `BEFORE UPDATE OF patient_id, stay_id ON visita` (y análogos). Sin estos, cualquier UPDATE destruye las path equations. | Las path equations deben ser invariantes bajo INSERT y UPDATE. Un trigger solo INSERT cubre la mitad del contrato. |
| P2v2 | B1n | BROKEN-DIAGRAM | **Crear `maquina_estados_estadia_ref` y `trg_evento_estadia_transicion`.** Tabla de referencia con transiciones válidas del lifecycle OPM SD1: `(pendiente_evaluacion→elegible, elegible→admitido, admitido→activo, activo→egresado, activo→fallecido, egresado→activo [reingreso])`. Trigger BEFORE INSERT ON evento_estadia que valide la transición. | Sin esto, el lifecycle OPM es decorativo. `evento_estadia` acepta transiciones arbitrarias. |
| P3v2 | B2n, B3n | BROKEN-DIAGRAM | **Expandir `estadia.estado` a 6 valores y crear `trg_evento_estadia_sync_estado`.** Primero, cambiar CHECK a `{pendiente_evaluacion, elegible, admitido, activo, egresado, fallecido}`. Luego crear trigger AFTER INSERT ON evento_estadia que sincronice `estadia.estado = NEW.estado_nuevo`. Esto cierra la bisimulación y hace compatible los dominios. | `estadia.estado` con 3 valores y `evento_estadia.estado_nuevo` con 6 son incompatibles. La sincronización es imposible sin expandir el enum. |

### HIGH (ejecutar antes de producción)

| # | Issue | Pattern | Propuesta | Justificación |
|---|---|---|---|---|
| P4v2 | R1n | DANGLING-REF | **Agregar REFERENCES a las 4 FKs cross-layer restantes.** `procedimiento.visit_id TEXT REFERENCES visita(visit_id)`, `observacion.visit_id TEXT REFERENCES visita(visit_id)`, `medicacion.visit_id TEXT REFERENCES visita(visit_id)`, `documentacion.visit_id TEXT REFERENCES visita(visit_id)`. El orden de creación (Clínica antes de Operacional) requiere reordenar: crear `visita` antes de estas tablas, o usar deferred FK. | 4 columnas que dicen `-- FK cross-layer` en el comentario pero no materializan el morfismo. Con `PRAGMA foreign_keys = ON`, son text libre. |
| P5v2 | B4n | BROKEN-DIAGRAM | **Modificar `trg_evento_visita_transicion` para validar estado actual.** Agregar validación: `AND NEW.estado_previo = (SELECT estado FROM visita WHERE visit_id = NEW.visit_id)`. Esto cierra la coalgebra: la transición no solo debe existir en el autómata sino partir del estado actual del carrier. | Sin esto se pueden "saltar" estados: insertar un evento COMPLETA→DOCUMENTADA cuando la visita está en PROGRAMADA. |
| P6v2 | S4n, S5n | BROKEN-DIAGRAM | **Crear triggers PE para documentacion y medicacion.** Para documentacion: `BEFORE INSERT ON documentacion WHEN stay_id IS NOT NULL AND patient_id IS NOT NULL` verificar `patient_id = estadia(stay_id).patient_id`. Para medicacion: `BEFORE INSERT ON medicacion WHEN visit_id IS NOT NULL AND stay_id IS NOT NULL` verificar `stay_id = visita(visit_id).stay_id`. | Son path equations no declaradas pero implícitas en la estructura del diagrama. Triángulos que no conmutan. |
| P7v2 | C1n | REDUNDANT-BISIMILAR | **Eliminar `estadia.source_episode_ids` (TEXT).** El dato ahora vive en `estadia_episodio_fuente`. La columna TEXT es la representación ad-hoc que P12 debía reemplazar. Mantener ambas crea un punto de divergencia sin bisimulación. | Dos representaciones del mismo dato sin constraint de sincronización = divergencia garantizada. |
| P8v2 | M1n | NON-FUNCTORIAL | **Crear script `scripts/populate_sqlite.py` (Stage 5).** Implementar el functor de migración `canonical CSV → SQLite`. Este script debe: (1) leer CSVs de `output/spreadsheet/canonical/`, (2) mapear columnas al DDL, (3) insertar con los triggers activos para verificación empírica. Sin este script, el DDL es un artefacto teórico no validado. | El modelo más elegante del mundo es inútil si nunca se prueba con datos reales. Los triggers podrían tener bugs latentes. |
| P9v2 | Q1n | BROKEN-DIAGRAM | **Crear triggers de validación REM.** Al menos RC-5 es enforceable: `BEFORE INSERT ON rem_cupos` verificar `NEW.total = NEW.programados - NEW.utilizados` cuando componente='disponibles'. RC-2 y RC-3 son más complejas pero al menos deberían materializarse como vistas de validación. | Los datos REM van a MINSAL. Una inconsistencia numérica en el reporte es un problema regulatorio, no solo técnico. |

### MEDIUM (mejora incremental)

| # | Issue | Pattern | Propuesta | Justificación |
|---|---|---|---|---|
| P10v2 | S2n | BROKEN-DIAGRAM | **Agregar `procedimiento.prestacion_id TEXT REFERENCES catalogo_prestacion(prestacion_id)`.** O bien FK a `codigo_mai`, según el patrón de lookup. El campo `codigo` puede ser un vocabulario mixto (MAI + interno), pero al menos los códigos MAI deben ser verificables. | PE-8 declarada, no enforceada desde v1. |
| P11v2 | S6n | BROKEN-DIAGRAM | **Crear trigger temporal:** `BEFORE INSERT ON visita` verificar que `NEW.fecha >= estadia(NEW.stay_id).fecha_ingreso AND (estadia.fecha_egreso IS NULL OR NEW.fecha <= estadia.fecha_egreso)`. | Visitas fuera del rango de estadía son datos inconsistentes que contaminarían REM. |
| P12v2 | S7n | BROKEN-DIAGRAM | **Crear trigger de conmutatividad ruta↔proveedor:** `BEFORE INSERT ON visita WHEN NEW.route_id IS NOT NULL AND NEW.provider_id IS NOT NULL` verificar que `ruta(NEW.route_id).provider_id = NEW.provider_id`. | La composición visita→ruta→profesional debe conmutar con visita→profesional. |
| P13v2 | C2n | AD-HOC-CONSTRUCTION | **Extraer enums ≥10 valores a tablas de referencia.** Priorizar `tipo_documento_ref` (26 valores) y `estado_visita_ref` (13 valores) porque son los más extensibles. Patrón: tabla `(codigo TEXT PK, descripcion TEXT, activo INTEGER DEFAULT 1)` + FK desde la tabla consumidora. | Acumulado desde v1. ALTER TABLE para extender un CHECK es frágil y no permite metadata. |
| P14v2 | C3n | AD-HOC-CONSTRUCTION | **Agregar `registro_llamada.stay_id TEXT REFERENCES estadia(stay_id)` (nullable).** Permite vincular llamadas a estadías específicas cuando aplique (seguimiento post-egreso, llamadas durante hospitalización). | OPM SD1.7 requiere trazabilidad llamada→estadía para seguimiento post-egreso. |
| P15v2 | B5n | BROKEN-DIAGRAM | **Crear triggers AFTER UPDATE para sincronización de estado.** Tanto para `evento_visita` como para `evento_estadia` (cuando se implemente P3v2). Que un UPDATE a `estado_nuevo` re-sincronice la entidad principal. | Las correcciones post-facto existen. Los triggers deben cubrir INSERT y UPDATE. |
| P16v2 | M3n | NON-FUNCTORIAL | **Documentar formalmente el functor de migración `Stage4 → SQLite`.** Especificar: para cada CSV del canonical, qué tabla destino, qué columnas mapean, qué transformaciones se aplican, y qué hacer con identidades parciales (mapear a `confidence_level` o rechazar). | Sin especificación formal, la migración será ad-hoc y no reproducible. |

### LOW (mejora cosmética o a largo plazo)

| # | Issue | Pattern | Propuesta | Justificación |
|---|---|---|---|---|
| P17v2 | C4n | AD-HOC-CONSTRUCTION | **Agregar CHECK constraint a `paciente.estado_actual`.** Valores posibles: `{activo, egresado, fallecido, pre_ingreso}` o derivar de la última estadía. | Vocabulario sin control = dato no tipado. |
| P18v2 | Q2n | AD-HOC-CONSTRUCTION | **Agregar columnas de provenance a `kpi_diario`.** Al menos `source_visit_count INTEGER` y `generated_at TEXT` para saber cuándo y con qué datos se generó. | La reproducibilidad es un principio declarado del pipeline. |
| P19v2 | Q3n | AD-HOC-CONSTRUCTION | **Crear índice compuesto en `sla`.** `CREATE INDEX idx_sla_lookup ON sla(service_type, prioridad)`. | Optimización de lookup. |
| P20v2 | R3n | BROKEN-DIAGRAM | **Hacer `encuesta_satisfaccion.stay_id` NOT NULL** o bien crear un trigger que requiera al menos patient_id cuando stay_id es NULL. | El bypass de PE-7 via stay_id NULL es una puerta trasera semántica. |
| P21v2 | MC1 | — | **Corregir la narrativa categórica del modelo conceptual.** Cambiar "Grothendieck ∫F" por "Pushout con identity keys compartidas" o "Colímite sobre el diagrama de spans de identity keys". O bien definir explícitamente los funtores F(α) para justificar la fibración. | La narrativa formal debe corresponder a la estructura real. Una fibración sin funtores de transporte es una etiqueta vacía. |

---

## 6. Mapa de Dependencias de Reparaciones

```
P3v2 ────▶ P2v2        (expandir estadia.estado antes de crear maquina_estados)
   │
   └─────▶ P15v2       (sync triggers dependen de enum expandido)

P4v2 ────▶ P6v2        (REFERENCES cruzadas antes de triggers de coherencia)
   │
   └─────▶ P10v2       (REFERENCES a catalogo_prestacion)

P7v2 (independiente — eliminar columna TEXT)

P8v2 ────▶ [todos]     (validación empírica descubre bugs latentes en triggers)

P1v2 (independiente — duplicar triggers existentes como BEFORE UPDATE)
```

Secuencia recomendada:
1. P1v2 (trivial, alto impacto)
2. P3v2 + P2v2 (lifecycle estadía)
3. P4v2 (REFERENCES cross-layer)
4. P5v2 + P6v2 (coalgebra de transiciones)
5. P7v2 (eliminar redundancia)
6. P8v2 (validación empírica — revela bugs en todo lo anterior)
7. P9v2 (validación REM)
8. Resto por severidad

---

## 7. Análisis Coalgebraico de las Máquinas de Estado

### Visita: coalgebra (U_v, c_v: U_v → F(U_v))

```
Carrier U_v = {PROGRAMADA, ASIGNADA, DESPACHADA, EN_RUTA, LLEGADA,
               EN_ATENCION, COMPLETA, PARCIAL, NO_REALIZADA,
               DOCUMENTADA, VERIFICADA, REPORTADA_REM, CANCELADA}

F(U_v) = P(U_v)  (powerset — transiciones no deterministas por estado)

c_v definida por maquina_estados_ref:
  PROGRAMADA    ↦ {ASIGNADA, CANCELADA}
  ASIGNADA      ↦ {DESPACHADA, CANCELADA}
  DESPACHADA    ↦ {EN_RUTA}
  EN_RUTA       ↦ {LLEGADA}
  LLEGADA       ↦ {EN_ATENCION, NO_REALIZADA}
  EN_ATENCION   ↦ {COMPLETA, PARCIAL}
  COMPLETA      ↦ {DOCUMENTADA}
  PARCIAL       ↦ {DOCUMENTADA}
  NO_REALIZADA  ↦ {DOCUMENTADA}
  DOCUMENTADA   ↦ {VERIFICADA}
  VERIFICADA    ↦ {REPORTADA_REM}
  REPORTADA_REM ↦ ∅  (estado terminal)
  CANCELADA     ↦ ∅  (estado terminal)
```

**Diagnóstico coalgebraico:**
- La coalgebra es **casi determinista** (Mealy sin input): la mayoría de estados tiene un solo sucesor.
- Bifurcaciones solo en PROGRAMADA (2), ASIGNADA (2), LLEGADA (2), EN_ATENCION (2).
- No hay ciclos → la coalgebra es well-founded (todo comportamiento es finito).
- Falta: no hay arista `DESPACHADA → CANCELADA` ni `EN_RUTA → CANCELADA`. Un profesional en ruta cuya visita se cancela no tiene transición válida. Esto es potencialmente un **deadlock operacional**.

### Estadía: coalgebra (U_e, c_e: U_e → F(U_e))

```
Carrier U_e (evento_estadia) = {pendiente_evaluacion, elegible, admitido,
                                 activo, egresado, fallecido}

c_e NO DEFINIDA — no existe maquina_estados_estadia_ref.
Las transiciones implícitas del OPM SD1 serían:
  pendiente_evaluacion ↦ {elegible}           (SD1.1 Evaluar Elegibilidad)
  elegible             ↦ {admitido}           (SD1.2 Ingresar Paciente)
  admitido             ↦ {activo}             (SD1.3 Planificar Atención)
  activo               ↦ {egresado, fallecido, activo}  (SD1.4-SD1.6, reingreso)
  egresado             ↦ {activo}             (reingreso)
  fallecido            ↦ ∅                    (terminal)
```

**Diagnóstico coalgebraico:**
- La coalgebra de estadía ni siquiera está definida formalmente — solo existe implícitamente en el OPM.
- `activo → activo` (reingreso a la misma estadía) es discutible: ¿es la misma estadía o una nueva?
- El dominio de 3 valores de `estadia.estado` vs 6 valores de `evento_estadia.estado_nuevo` significa que **no existe homomorfismo** entre las dos coalgebras. No son bisimilares porque ni siquiera comparten carrier.

---

## 8. Functor Information Loss

| Transformación | Operador | Perdido |
|---|---|---|
| PROGRAMACIÓN legacy → orden_servicio + visita | Σ (fusión) | Semántica de "semana programada" como unidad; relación espacial paciente-en-misma-ruta |
| CSV pipeline canonical → SQLite | Δ (reestructuración) | Ninguno si el functor es correcto, pero **no verificado empíricamente** |
| `estadia.source_episode_ids` → `estadia_episodio_fuente` | Δ (normalización) | Ninguno — pero la coexistencia de ambas representaciones introduce riesgo de divergencia |
| `estadia.estado` (3 val) ← `evento_estadia.estado_nuevo` (6 val) | Π (restricción) | 3 estados pre-admission (`pendiente_evaluacion`, `elegible`, `admitido`) se pierden al proyectar sobre el enum de estadía |

---

## 9. Estado Post-Correcciones v2

### Correcciones aplicadas al DDL

| Propuesta | Issue | Estado | Objetos creados/modificados |
|---|---|---|---|
| P1v2 | S1n CRITICAL | **APLICADA** | `trg_visita_pe1_update`, `trg_orden_pe2_update`, `trg_encuesta_pe7_update`, `trg_profesional_coherencia_rem_update` |
| P2v2 | B1n CRITICAL | **APLICADA** | `maquina_estados_estadia_ref` (7 transiciones seed), `trg_evento_estadia_transicion` |
| P3v2 | B2n+B3n CRITICAL | **APLICADA** | `estadia.estado` expandido a 6 valores, `trg_evento_estadia_sync_estado`, `trg_evento_estadia_sync_estado_update` |
| P4v2 | R1n HIGH | **APLICADA** | 4 columnas `visit_id` ahora con REFERENCES visita(visit_id) |
| P5v2 | B4n HIGH | **APLICADA** | `trg_evento_visita_transicion` reemplazado con validación de estado actual |
| P6v2 | S4n+S5n HIGH | **APLICADA** | `trg_documentacion_coherencia_patient[_update]`, `trg_medicacion_coherencia_stay[_update]`, `trg_procedimiento_coherencia_stay` |
| P7v2 | C1n HIGH | **APLICADA** | `estadia.source_episode_ids` eliminado |
| P9v2 | Q1n HIGH | **APLICADA** | `trg_rem_cupos_rc5` |
| P11v2 | S6n MEDIUM | **APLICADA** | `trg_visita_rango_temporal` |
| P12v2 | S7n MEDIUM | **APLICADA** | `trg_visita_ruta_provider` |
| P14v2 | C3n MEDIUM | **APLICADA** | `registro_llamada.stay_id` agregado (nullable, REFERENCES estadia) |
| P15v2 | B5n MEDIUM | **APLICADA** | `trg_evento_visita_sync_estado_update`, `trg_evento_estadia_sync_estado_update` |
| P17v2 | C4n LOW | **APLICADA** | `paciente.estado_actual` CHECK constraint |
| P19v2 | Q3n LOW | **APLICADA** | `idx_sla_lookup` |
| P20v2 | R3n LOW | **APLICADA** | `trg_encuesta_stay_required` |

### Issues residuales (no corregidos en DDL)

| # | Sev. | Descripción | Razón |
|---|---|---|---|
| S2n | HIGH | PE-8: procedimiento.codigo sin FK a catalogo_prestacion | Requiere decisión: FK a codigo_mai o a prestacion_id. Vocabulario mixto MAI+interno. |
| S3n | HIGH | PE-10: registro_llamada.estado_paciente sin validación | Trigger costoso (subconsulta a estadia por cada INSERT). Mejor implementar en aplicación. |
| M1n | HIGH | DDL nunca poblado con datos reales | Requiere Stage 5 del pipeline (script `populate_sqlite.py`). |
| M2n | HIGH | Functor Σ para PROGRAMACIÓN legacy sin especificar | Requiere análisis del formato de la matriz PROGRAMACIÓN. |
| M3n | MEDIUM | Migración Stage4→SQLite sin especificación formal | Depende de M1n. |
| C2n | MEDIUM | Enums largos en CHECK constraints | Refactorización a tablas de referencia es invasiva. Planificable para v3. |
| Q2n | LOW | kpi_diario sin provenance | Mejora incremental. |
| MC1 | LOW | Narrativa categórica Grothendieck vs pushout | Corrección documental. |

### Estadísticas finales del DDL

```
Objetos:        44 tablas, 3 vistas, 23 triggers, 48 índices
Correcciones:   v1 (12 propuestas, 10 aplicadas) + v2 (21 propuestas, 15 aplicadas)
Tests:          15 casos de prueba ejecutados, 100% passing
```

---

## 10. Signature de Auditoría

```
Modo:           STATIC + BEHAVIORAL + MIGRATION
Artefactos:     SCHEMA (DDL SQLite ~1050 líneas) + MODEL (Markdown 1127 líneas)
Issues v2:      26 detectados → 18 corregidos + 8 residuales
Residuales:     0 CRITICAL, 4 HIGH, 2 MEDIUM, 2 LOW
Patrones:       BROKEN-DIAGRAM (12→0), DANGLING-REFERENCE (2→0), AD-HOC-CONSTRUCTION (5→2),
                REDUNDANT-BISIMILAR (1→0), NON-FUNCTORIAL (2→2)
Migración:      Schema sin instancias (M1n HIGH) — próximo paso: Stage 5 pipeline
Riesgos:        CRITICALs eliminados.
                Residuales HIGH son migración (M1n, M2n) y PE parcialmente enforceables (S2n, S3n).
                El DDL necesita validación empírica con datos reales.
```
