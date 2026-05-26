# Memoria consolidada migracion Drive HODOM

Fecha: 2026-05-26.
Rama: `main`.
Estado base previo: `cfc8f4f feat(migration): migracion Drive HODOM 2026 — 4 fases`.

## Estado actual

Migracion Drive HODOM 2026 en fase avanzada de conciliacion y promocion core. Se ejecutaron 4 fases iniciales y una continuacion controlada: enriquecimiento de visitas existentes, insercion de visitas nuevas, reconciliacion profesional, fuzzy matching de pacientes y promocion fuzzy-resolved limitada. La regla vigente sigue siendo no insertar en `clinical` — solo `operational.visita` con provenance completa.

**Scope**: rutas Drive con `visit_date >= '2026-01-01'` (3,150 rutas de 17,117 totales).

Controles verificados:

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 totales | 3,150 |
| Rutas promovidas a `operational.visita` | 473 Drive-sourced distintas (448 piloto/Fase 2 + 25 fuzzy) |
| Visitas core enriquecidas (UPDATE provider) | 1,065 |
| Visitas core enriquecidas (UPDATE hora) | 522 |
| Visitas core 2026 total | 2,721 |
| Visitas core 2026 completas (4/4 campos) | 1,439 (53%) |
| Propuestas de profesional | 62 (24 high-confidence unicas) |
| Propuestas fuzzy de identidad paciente | 30 (323 rutas con estadia activa unica) |
| Rutas fuzzy-resolved promovidas | 25 (15 single-service limpias + 10 en batch-duplicate review) |
| Rutas bloqueadas sin paciente (65 nombres) | 768 |
| Rutas bloqueadas sin estadia activa | 198 |
| Provenance de fases Drive 2026 controladas | 7,408 filas |
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

## Artefactos relevantes

| Artefacto | Uso |
| --- | --- |
| `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md` | Esta memoria consolidada. |
| `docs/specs/metricas-hodom/handoff-2026-05-25.md` | Handoff historico acumulado con todas las fases. |
| `db/updates/2026-05-26-drive-pilot-migration.sql` | Piloto inicial (115 rutas con servicio+domicilio). |
| `db/updates/2026-05-26-drive-enrichment-2026.sql` | Enriquecimiento UPDATE de visitas core 2026. |
| `db/updates/2026-05-26-drive-new-visits-2026.sql` | Insercion de 333 visitas nuevas 2026. |
| `db/updates/2026-05-26-drive-new-visits-audit-repair.sql` | Reparacion view-only de auditoria/resumen Phase 2 desde provenance. |
| `db/updates/2026-05-26-professional-reconciliation.sql` | Conciliacion de profesionales Drive vs DB. |
| `db/updates/2026-05-26-fuzzy-patient-match-2026.sql` | Fuzzy matching de identidad paciente. |
| `db/updates/2026-05-26-fuzzy-patient-match-expansion.sql` | Expansion reproducible de propuestas fuzzy all-words y backfill de `match_pattern`. |
| `db/updates/2026-05-26-fuzzy-resolved-migration-2026.sql` | Promocion fuzzy-resolved controlada a `operational.visita`. |
| `db/updates/2026-05-26-expert-reconciliation-recommendations.sql` | Recomendaciones expertas servicio + domicilio. |
| `db/updates/2026-05-26-human-reconciliation.sql` | Tabla de decisiones humanas. |
| `db/updates/2026-05-26-simulated-reconciliation-proposals.sql` | Propuestas simuladas iniciales. |
| `db/updates/2026-05-26-drive-promotion-*.sql` | Readiness y contrato de promocion. |
| `scripts/test_drive_pilot_migration.py` | 22 tests unitarios para piloto, profesional, repairs y fuzzy-resolved. |

## Decisiones consolidadas

- **Scope 2026**: solo rutas desde 2026-01-01. Las 13,967 rutas pre-2026 quedan en staging sin tocar.
- **provider_id = NULL es deuda operacional aceptada**: solo se asigna cuando hay match profesional high-confidence unique.
- **Fuzzy matching**: se aceptan matches donde TODAS las palabras significativas (len>2) del nombre Drive aparecen en el nombre DB. No requiere contiguidad. Marcado como `proposed` con `human_required=true`.
- **Fuzzy-resolved no equivale a aprobado humano**: `simulated_expert_reconciliation` orienta promocion controlada; no reemplaza revision responsable.
- **Batch duplicate review**: multiples rutas Drive para el mismo paciente/estadia/dia no se destruyen ni se aprueban como verdad final; si ya fueron promovidas, quedan trazadas con provenance y marca `FUZZY_REVIEW_BATCH_DUPLICATE`.
- **Enriquecimiento > Insercion**: las visitas que ya existen en core se enriquecen (UPDATE), no se duplican. Solo se INSERTAN las que no tienen visita core el mismo dia.
- **Provenance por campo**: cada campo enriquecido o insertado deja registro en `migration.provenance` con `source_file`, `source_key`, `phase` y `field_name`.
- **No se toca `duplicate_visit`**: flujo separado, sin resolver aun.
- **No se toca `clinical`**: solo `operational.visita` y `migration.provenance`.
- **hsc-agent-cli no aplica para nombres sin RUT**: el CLI requiere RUT para buscar pacientes. Los 65 nombres restantes no tienen correspondencia en la DB.

## Pendientes inmediatos

1. **Revisar 10 fuzzy promovidas en batch-duplicate review**: decidir si son atenciones multiples reales o pushout/merge.
2. **Enriquecer 285 rutas fuzzy con visita core existente**: solo llenar brechas, sin duplicar.
3. **Resolver 13 rutas fuzzy net-new no promovidas**: batch duplicate, split de servicio o servicio no mapeado.
4. **Resolver 768 rutas sin paciente**: 65 nombres que no existen en `clinical.paciente`. Requieren creacion de pacientes o ingreso manual.
5. **Resolver 198 rutas sin estadia**: tienen paciente pero la fecha de visita no cae dentro de ninguna estadia.
6. **Resolver ambiguous de profesional**: 11 nombres Drive con multiples candidatos DB (PIA, CAMILA, etc.).
7. **Resolver fono low-confidence**: M. JOSE (3,483 rutas totales) requiere confirmacion.
8. **Resolver medicos sin match en DB**: SANCHEZ, PEREZ, PINO (~815 rutas).
9. **Duplicate visits**: 3,151 propuestas + 6,293 rutas `REVIEW_DUPLICATE_PUSHOUT_REQUIRED`.
10. **Servicios compuestos**: 207 rutas `EXPERT_SPLIT_SERVICE_REQUIRED` para 2026.
11. **383 rutas sin domicilio**: `EXPERT_MINIMAL_READY_SINGLE_SERVICE` en 2026.

## Riesgos

- Tratar una propuesta simulada como aprobacion humana real generaria falsa certeza.
- Los matches fuzzy requieren confirmacion humana (todos tienen `human_required=true`).
- Migrar duplicados sin pushout puede crear visitas paralelas incorrectas.
- Asignar profesional por texto debil puede crear falsa identidad de prestador.
- Exportar vistas con nombres o direcciones podria exponer informacion sensible.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. Revisar `staging.v_hodom_fuzzy_resolved_route_summary_2026`: hay 25 fuzzy promovidas, 15 single-service limpias y 10 `FUZZY_REVIEW_BATCH_DUPLICATE` trazadas.
2. Construir enriquecimiento para 285 rutas fuzzy con visita core existente; solo completar campos NULL con provenance.
3. Resolver 13 rutas fuzzy net-new no promovidas por batch duplicate, split de servicio o servicio no mapeado.
4. Resolver los 65 nombres bloqueados: no existen en `clinical.paciente`. Opciones: creacion manual de pacientes, busqueda en SGH/DAU via `hsc-agent-cli` si se consigue RUT por otra via, o flaggear como `UNRESOLVABLE`.
5. Resolver ambiguous de profesional: 11 nombres (PIA, CAMILA, etc.) requieren desambiguacion.
6. Duplicate visits: flujo separado de merge/pushout para las 6,293 + 3,151 rutas.
7. Antes de tocar OPM/OPL o canon, leer `docs/canon-opm/reglas-opm-estrictas.md`. Antes de tocar UI, `ui-forja/GOVERNANCE.md`.

Comandos de verificacion:
```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -c "SELECT count(*) FROM operational.visita WHERE fecha >= '2026-01-01';"
```
