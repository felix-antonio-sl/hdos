# Memoria consolidada migracion Drive HODOM

Fecha: 2026-05-26.
Rama: `main`.
Estado base previo: `cfc8f4f feat(migration): migracion Drive HODOM 2026 — 4 fases`.

## Estado actual

Migracion Drive HODOM 2026 en fase avanzada de conciliacion y promocion core. Se ejecutaron 4 fases iniciales y dos continuaciones controladas: enriquecimiento de visitas existentes, insercion de visitas nuevas, reconciliacion profesional, fuzzy matching de pacientes, promocion fuzzy-resolved limitada y enriquecimiento fuzzy de visitas core existentes. La regla vigente sigue siendo no insertar en `clinical` — solo `operational.visita` con provenance completa.

Corte adicional: la fuente `INGRESOS 2026 DRIVE` (`1qynoVzgF5a5qMdTVXhfM35zQC4QCtVqh0MNaSHD2_aQ`) esta inventariada y registrada en `staging.drive_source_file` como `ingresos_2026`, pero aun no existe una tabla nominal especifica para ingresos/estadias 2026. Debe tratarse como el siguiente frente antes de declarar 2026 saneado en usuarios y episodios.

**Scope**: rutas Drive con `visit_date >= '2026-01-01'` (3,150 rutas de 17,117 totales).

Controles verificados:

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 totales | 3,150 |
| Rutas promovidas a `operational.visita` | 473 Drive-sourced distintas (448 piloto/Fase 2 + 25 fuzzy) |
| Visitas core enriquecidas (UPDATE provider) | 1,065 |
| Visitas core enriquecidas (UPDATE hora) | 522 |
| Visitas core 2026 total | 2,721 |
| Visitas core 2026 con provider_id | 1,855 |
| Visitas core 2026 con hora | 2,258 |
| Visitas core 2026 con prestacion | 2,604 |
| Visitas core 2026 completas (4/4 campos) | 1,526 (56%) |
| Propuestas de profesional | 62 (24 high-confidence unicas) |
| Propuestas fuzzy de identidad paciente | 30 (323 rutas con estadia activa unica) |
| Rutas fuzzy-resolved promovidas | 25 (15 single-service limpias + 10 en batch-duplicate review) |
| Enriquecimientos fuzzy seguros aplicados | 127 campos en 103 visitas core |
| Rutas bloqueadas sin paciente (65 nombres) | 768 |
| Rutas bloqueadas sin estadia activa | 198 |
| Provenance de fases Drive 2026 controladas | 7,535 filas |
| Decisiones humanas efectivas | 0 |

## Fases ejecutadas

### Fase 1 — Enriquecimiento (visitas existentes)
- **Artefacto**: `db/updates/2026-05-26-drive-enrichment-2026.sql`
- UPDATE `provider_id` en 1,065 visitas core desde match profesional
- UPDATE `hora_plan_inicio` en 522 visitas core desde Drive `planned_time`
- Visitas completas subieron de 18% a 59% en core 2026
- Provenance: 2,837 filas

### Fase 2 — Insercion de visitas nuevas
- **Artefacto**: `db/updates/2026-05-26-drive-new-visits-2026.sql`
- INSERT 333 visitas netamente nuevas en `operational.visita`
- 445 total Drive-sourced visits en core 2026
- Visitas core 2026 pasaron de 2,251 a 2,696 (+20%)

### Fase 3 — Reconciliacion profesional
- **Artefacto**: `db/updates/2026-05-26-professional-reconciliation.sql`
- Matching de nombres Drive (JSON `professionals`) contra `operational.profesional` (31 registros)
- 62 propuestas insertadas en `hodom_reconciliation_decision`
- 24 high-confidence unicas (primer nombre exacto + profesion), 11 ambiguous, 11 fono low-conf
- Principales matches: LAURA (3,877 rutas) → Laura Biernay, LUIS (3,754) → Luis Burgos, BRAYAN (3,912) → Brayan Reyes, AQUEVEQUE (1,142) → Nicolas Aqueveque
- Vistas: `v_hodom_drive_professional_lookup`, `v_hodom_professional_match_scoring`, `v_hodom_route_professional_match`

### Fase 4 — Fuzzy matching de pacientes
- **Artefacto**: `db/updates/2026-05-26-fuzzy-patient-match-2026.sql`
- Word-overlap matching entre nombres Drive bloqueados y `clinical.paciente`
- 30 propuestas de identidad paciente con todas las palabras significativas matching
- 323 rutas con identidad unica y estadia activa unica para 24 nombres bloqueados
- 1 nombre bloqueado quedo ambiguo contra 6 pacientes DB (12 rutas) y no se usa para promocion automatica
- Patron: nombres Drive omiten segundos nombres (ej. "ELBA SAN MARTIN MARIN" → "ELBA NIEVES SAN MARTIN MARIN")

### Fase 5 — Promocion fuzzy-resolved controlada
- **Artefactos**: `db/updates/2026-05-26-fuzzy-patient-match-expansion.sql` y `db/updates/2026-05-26-fuzzy-resolved-migration-2026.sql`
- Reparacion reproducible: las 30 decisiones fuzzy quedan regenerables desde SQL y con `match_pattern` en evidencia.
- 323 rutas fuzzy-resolved: 285 ya tenian visita core el mismo dia y quedan como deuda de enriquecimiento, no insercion.
- 38 rutas eran netamente nuevas; se promovieron 25 a `operational.visita` con 191 filas de provenance.
- De las 25 promovidas, 15 son single-service sin colision de batch y 10 quedan marcadas como `FUZZY_REVIEW_BATCH_DUPLICATE` por compartir paciente/estadia/dia con otra ruta Drive del mismo lote. No se borran: quedan trazables para conciliacion posterior.
- 13 rutas net-new quedan bloqueadas por batch duplicate, split de servicio o servicio no mapeado.

### Fase 6 — Revision y enriquecimiento fuzzy
- **Artefacto**: `db/updates/2026-05-26-fuzzy-review-enrichment-2026.sql`
- Las 10 fuzzy promovidas como batch duplicate quedan en cola de revision; no se tratan como aprobacion humana.
- Las 13 net-new no promovidas quedan clasificadas: 6 batch duplicate, 6 requieren modelo de split de visita y 1 requiere diccionario de servicio.
- De 285 rutas fuzzy con visita core existente, 171 tenian visita core unica y 114 quedaron ambiguas por multiples visitas core el mismo dia.
- Se aplicaron 127 enriquecimientos seguros en 103 visitas core: 91 `provider_id`, 35 `hora_plan_inicio`, 1 `prestacion_id`, 0 `domicilio_id`.
- Quedan 24 filas de campo con valores conflictivos, bloqueadas para revision.

## Artefactos relevantes

| Artefacto | Uso |
| --- | --- |
| `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md` | Esta memoria consolidada. |
| `docs/specs/metricas-hodom/handoff-2026-05-25.md` | Handoff historico acumulado con todas las fases. |
| `docs/specs/metricas-hodom/handoff-ingresos-2026-drive-2026-05-26.md` | Handoff explicito para incorporar `INGRESOS 2026 DRIVE`. |
| `db/updates/2026-05-26-drive-pilot-migration.sql` | Piloto inicial (115 rutas con servicio+domicilio). |
| `db/updates/2026-05-26-drive-enrichment-2026.sql` | Enriquecimiento UPDATE de visitas core 2026. |
| `db/updates/2026-05-26-drive-new-visits-2026.sql` | Insercion de 333 visitas nuevas 2026. |
| `db/updates/2026-05-26-drive-new-visits-audit-repair.sql` | Reparacion view-only de auditoria/resumen Phase 2 desde provenance. |
| `db/updates/2026-05-26-professional-reconciliation.sql` | Conciliacion de profesionales Drive vs DB. |
| `db/updates/2026-05-26-fuzzy-patient-match-2026.sql` | Fuzzy matching de identidad paciente. |
| `db/updates/2026-05-26-fuzzy-patient-match-expansion.sql` | Expansion reproducible de propuestas fuzzy all-words y backfill de `match_pattern`. |
| `db/updates/2026-05-26-fuzzy-resolved-migration-2026.sql` | Promocion fuzzy-resolved controlada a `operational.visita`. |
| `db/updates/2026-05-26-fuzzy-review-enrichment-2026.sql` | Colas de revision fuzzy y enriquecimiento seguro de visitas core existentes. |
| `db/updates/2026-05-26-expert-reconciliation-recommendations.sql` | Recomendaciones expertas servicio + domicilio. |
| `db/updates/2026-05-26-human-reconciliation.sql` | Tabla de decisiones humanas. |
| `db/updates/2026-05-26-simulated-reconciliation-proposals.sql` | Propuestas simuladas iniciales. |
| `db/updates/2026-05-26-drive-promotion-*.sql` | Readiness y contrato de promocion. |
| `scripts/test_drive_pilot_migration.py` | 24 tests unitarios para piloto, profesional, repairs, fuzzy-resolved y enriquecimiento fuzzy. |

## Decisiones consolidadas

- **Scope 2026**: solo rutas desde 2026-01-01. Las 13,967 rutas pre-2026 quedan en staging sin tocar.
- **provider_id = NULL es deuda operacional aceptada**: solo se asigna cuando hay match profesional high-confidence unique.
- **Fuzzy matching**: se aceptan matches donde TODAS las palabras significativas (len>2) del nombre Drive aparecen en el nombre DB. No requiere contiguidad. Marcado como `proposed` con `human_required=true`.
- **Fuzzy-resolved no equivale a aprobado humano**: `simulated_expert_reconciliation` orienta promocion controlada; no reemplaza revision responsable.
- **Batch duplicate review**: multiples rutas Drive para el mismo paciente/estadia/dia no se destruyen ni se aprueban como verdad final; si ya fueron promovidas, quedan trazadas con provenance y marca `FUZZY_REVIEW_BATCH_DUPLICATE`.
- **Enriquecimiento fuzzy seguro**: solo actualiza campos NULL cuando hay una unica visita core candidata y un unico valor Drive candidato por campo. Conflictos y multiples visitas core quedan bloqueados.
- **Enriquecimiento > Insercion**: las visitas que ya existen en core se enriquecen (UPDATE), no se duplican. Solo se INSERTAN las que no tienen visita core el mismo dia.
- **Provenance por campo**: cada campo enriquecido o insertado deja registro en `migration.provenance` con `source_file`, `source_key`, `phase` y `field_name`.
- **No se toca `duplicate_visit`**: flujo separado, sin resolver aun.
- **No se toca `clinical`**: solo `operational.visita` y `migration.provenance`.
- **hsc-agent-cli no aplica para nombres sin RUT**: el CLI requiere RUT para buscar pacientes. Los 65 nombres restantes no tienen correspondencia en la DB.
- **INGRESOS 2026 DRIVE es frente separado**: gobierna pacientes, ingresos, egresos y estadias; no debe mezclarse con la migracion de rutas/visitas ni promoverse directo a `clinical` sin staging y gates.

## Pendientes inmediatos

1. **Revisar batch duplicates fuzzy**: 7 grupos; 3 ya promovidos completos, 2 parcialmente promovidos y 2 sin promover.
2. **Resolver 114 rutas fuzzy con multiples visitas core candidatas**: requiere criterio de merge/pushout antes de enriquecer.
3. **Resolver 24 filas de campo fuzzy con valores conflictivos**: principalmente provider/hora con mas de un valor candidato para la misma visita core.
4. **Resolver 13 rutas fuzzy net-new no promovidas**: 6 batch duplicate, 6 split de servicio, 1 servicio no mapeado.
5. **Resolver 768 rutas sin paciente**: 65 nombres que no existen en `clinical.paciente`. Requieren creacion de pacientes o ingreso manual.
6. **Resolver 198 rutas sin estadia**: tienen paciente pero la fecha de visita no cae dentro de ninguna estadia.
7. **Resolver ambiguous de profesional**: 11 nombres Drive con multiples candidatos DB (PIA, CAMILA, etc.).
8. **Resolver fono low-confidence**: M. JOSE (3,483 rutas totales) requiere confirmacion.
9. **Resolver medicos sin match en DB**: SANCHEZ, PEREZ, PINO (~815 rutas).
10. **Duplicate visits**: 3,151 propuestas + 6,293 rutas `REVIEW_DUPLICATE_PUSHOUT_REQUIRED`.
11. **Servicios compuestos**: 207 rutas `EXPERT_SPLIT_SERVICE_REQUIRED` para 2026.
12. **383 rutas sin domicilio**: `EXPERT_MINIMAL_READY_SINGLE_SERVICE` en 2026.
13. **Incorporar `INGRESOS 2026 DRIVE`**: crear staging nominal, auditar calidad, conciliar contra `clinical.paciente` y `clinical.estadia`, y cruzar contra visitas 2026 ya migradas.

## Riesgos

- Tratar una propuesta simulada como aprobacion humana real generaria falsa certeza.
- Los matches fuzzy requieren confirmacion humana (todos tienen `human_required=true`).
- Migrar duplicados sin pushout puede crear visitas paralelas incorrectas.
- Asignar profesional por texto debil puede crear falsa identidad de prestador.
- Exportar vistas con nombres o direcciones podria exponer informacion sensible.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. Revisar `staging.v_hodom_fuzzy_batch_duplicate_summary_2026`: 7 grupos batch fuzzy, con 10 rutas ya promovidas en revision y 6 no promovidas.
2. Revisar `staging.v_hodom_fuzzy_existing_enrichment_summary_2026`: 127 campos enriquecidos; quedan 114 rutas con core ambiguo y 24 filas de campo conflictivas.
3. Resolver `staging.v_hodom_fuzzy_unpromoted_net_new_summary_2026`: 6 batch duplicate, 6 split de servicio, 1 servicio no mapeado.
4. Resolver los 65 nombres bloqueados: no existen en `clinical.paciente`. Opciones: creacion manual de pacientes, busqueda en SGH/DAU via `hsc-agent-cli` si se consigue RUT por otra via, o flaggear como `UNRESOLVABLE`.
5. Resolver ambiguous de profesional: 11 nombres (PIA, CAMILA, etc.) requieren desambiguacion.
6. Duplicate visits: flujo separado de merge/pushout para las 6,293 + 3,151 rutas.
7. Antes de tocar OPM/OPL o canon, leer `docs/canon-opm/reglas-opm-estrictas.md`. Antes de tocar UI, `ui-forja/GOVERNANCE.md`.

Prompt alternativo para el siguiente frente:

Continuar desde `docs/specs/metricas-hodom/handoff-ingresos-2026-drive-2026-05-26.md`. Crear staging nominal para `INGRESOS 2026 DRIVE` (`staging.hodom_ingreso_2026`) y parser/loader desde `.tmp/drive-consolidation/raw/INGRESOS_2026_DRIVE.xlsx`, con tests antes de SQL/codigo. No tocar `clinical` todavia. Luego construir vistas agregadas de calidad, conciliacion contra `clinical.paciente`, conciliacion contra `clinical.estadia` y cruce con visitas 2026 ya migradas.

Comandos de verificacion:
```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -c "SELECT count(*) FROM operational.visita WHERE fecha >= '2026-01-01';"
```
