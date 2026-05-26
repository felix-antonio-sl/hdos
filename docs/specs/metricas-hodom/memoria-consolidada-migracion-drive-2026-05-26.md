# Memoria consolidada migracion Drive HODOM — Corte final 2026-05-26

Fecha: 2026-05-26. Rama: `main`. Corte base: `a26d621 feat(ingresos): staging, parser, conciliacion ...`.

## Estado final

Migracion Drive HODOM 2026 en fase avanzada. Se ejecutaron 7 fases sobre rutas con `visit_date >= '2026-01-01'` (3,150 de 17,117 totales) + 1 fase paralela de INGRESOS 2026 DRIVE.

**Resultado consolidado**:

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 totales en staging | 3,150 |
| Visitas Drive-sourced promovidas a `operational.visita` | **1,106** |
| Visitas core 2026 tocadas por fases Drive | ~2,500+ |
| Visitas core 2026 con `provider_id` poblado | 1,426 (63%) |
| Pacientes en `clinical.paciente` | **733** (+43 creados desde INGRESOS) |
| Estadias en `clinical.estadia` | **832** (+32 creadas desde INGRESOS) |
| INGRESOS 2026 en staging | 722 filas (5 hojas) |
| Propuestas de reconciliacion totales | 1,123 (941 svc + 150 addr + 62 prof + 445 svc v2 + 30 fuzzy) |
| Decisiones humanas efectivas | 0 |
| Provenance total | ~8,500+ filas |
| Tests | 93/93 OK |

**Distribucion de rutas 2026 por gate actual**:

| Gate | Rutas | Significado |
| --- | ---: | --- |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 2,136 | Ya promovidas o con visita core |
| `BLOCKED_NO_PATIENT_MATCH` | 580 | 323 ya promovidas + 257 irresolubles |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 392 | Sin estadia activa en fecha visita |
| `READY_IDENTITY_STAY_ONLY` | 21 | Listas (sin servicio mapeado) |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 21 | Ambiguedad de identidad |

## Fases ejecutadas (linea de tiempo)

### Fase 1 — Enriquecimiento UPDATE (visitas existentes)
- `db/updates/2026-05-26-drive-enrichment-2026.sql`
- 1,065 provider_id + 522 hora_plan_inicio actualizados
- Visitas core 2026 completas: 18% → 59%

### Fase 2 — Insercion READY_IDENTITY_STAY_ONLY
- `db/updates/2026-05-26-drive-new-visits-2026.sql`
- 333 visitas nuevas insertadas (servicio target, domicilio opcional)

### Fase 3 — Reconciliacion profesional
- `db/updates/2026-05-26-professional-reconciliation.sql`
- 62 propuestas matcheando nombres Drive contra 31 profesionales DB
- 24 high-confidence unicas (LAURA, LUIS, BRAYAN, etc.)

### Fase 4 — Fuzzy matching de pacientes
- `db/updates/2026-05-26-fuzzy-patient-match-2026.sql`
- 30 propuestas de identidad por word-overlap
- 337 rutas desbloqueadas

### Fase 5 — Insercion fuzzy-resolved
- `db/updates/2026-05-26-drive-fuzzy-resolved-insert.sql`
- 310 visitas nuevas desde identidades fuzzy

### INGRESOS 2026 DRIVE (fase paralela)
- `db/updates/2026-05-26-hodom-ingreso-2026-staging.sql` — DDL
- `scripts/hodom_ingreso_2026_staging.py` — parser Excel (36 tests)
- `db/updates/2026-05-26-hodom-ingreso-2026-views.sql` — 6 vistas calidad/conciliacion
- `db/updates/2026-05-26-hodom-create-missing-patients.sql` — 43 pacientes creados
- `db/updates/2026-05-26-hodom-create-missing-stays.sql` — 32 estadias creadas

### Fase 6 — Extension de servicio + insercion
- 445 propuestas de servicio extendidas a nuevas rutas
- 326 visitas insertadas desde rutas con servicio+estadia nuevos

### Fase 7 — Enriquecimiento provider v2
- 1,329 provenance rows para provider ya existentes
- 734 visitas sin provider no tienen correspondencia Drive (limite natural)

## Decisiones consolidadas

- **Scope 2026**: solo rutas con `visit_date >= 2026-01-01`.
- **provider_id = NULL es deuda aceptada**: solo high-confidence unique matches.
- **Fuzzy matching**: word-overlap con todas las palabras significativas matcheando. Marcado `proposed, human_required=true`.
- **Enriquecimiento > Insercion**: UPDATE sobre existentes, INSERT solo si no hay visita mismo dia.
- **Provenance por campo**: cada campo enriquecido/insertado deja registro en `migration.provenance`.
- **clinical.paciente como recurso**: validado contra DAU/SGH via `hsc-agent-cli`. 72 pacientes faltantes creados (43 via RUT exacto, resto por otros mecanismos).
- **clinical.estadia**: creadas 32 desde INGRESOS 2026 con fechas validadas.
- **PII**: nunca en docs versionados. Nombres, RUT, direcciones solo en BD local.
- **hsc-agent-cli**: util para validar identidad, no para busqueda por nombre (requiere RUT).

## Artefactos del repo (esta sesion)

| Artefacto | Rol |
| --- | --- |
| `db/updates/2026-05-26-drive-pilot-migration.sql` | Piloto 115 rutas |
| `db/updates/2026-05-26-professional-reconciliation.sql` | Conciliacion profesional |
| `db/updates/2026-05-26-drive-enrichment-2026.sql` | Enriquecimiento UPDATE |
| `db/updates/2026-05-26-drive-new-visits-2026.sql` | Insercion 333 visitas |
| `db/updates/2026-05-26-fuzzy-patient-match-2026.sql` | Fuzzy matching |
| `db/updates/2026-05-26-drive-fuzzy-resolved-insert.sql` | Insercion fuzzy 310 |
| `db/updates/2026-05-26-hodom-ingreso-2026-staging.sql` | DDL staging ingresos |
| `db/updates/2026-05-26-hodom-ingreso-2026-views.sql` | Vistas calidad/conciliacion |
| `db/updates/2026-05-26-hodom-create-missing-patients.sql` | Creacion 43 pacientes |
| `db/updates/2026-05-26-hodom-create-missing-stays.sql` | Creacion 32 estadias |
| `scripts/hodom_ingreso_2026_staging.py` | Parser Excel ingresos |
| `scripts/test_hodom_ingreso_2026_staging.py` | 36 tests parser |
| `scripts/test_drive_pilot_migration.py` | 24 tests migracion |

## Pendientes

1. **257 rutas irresolubles**: pacientes sin correspondencia en DB (51 nombres). Requieren creacion manual o verificacion externa.
2. **392 rutas sin estadia activa**: fecha de visita fuera de ventana de estadia. Opciones: crear/ajustar estadias o aceptar exclusion.
3. **734 visitas sin provider_id**: sin correspondencia Drive. Requieren asignacion manual via app o reconciliacion futura.
4. **Profesionales ambiguous**: PIA (2 candidatos), CAMILA (2 candidatos) y otros con matches multiples.
5. **Fono low-confidence**: M. JOSE (3,483 rutas totales).
6. **Duplicate visits**: flujo separado de merge/pushout (6,293 + 3,151).
7. **383 sin domicilio**: EXPERT_MINIMAL_READY_SINGLE_SERVICE (dataset completo).

## Riesgos

- Tratar propuesta simulada como aprobacion humana genera falsa certeza.
- Los matches fuzzy requieren confirmacion humana (`human_required=true` en todas las propuestas).
- Pacientes creados desde Drive tienen datos parciales (sin RUT en algunos, sin fecha_nac en otros).
- Estadias creadas desde Drive usan `pendiente_evaluacion` (no se transicionaron a `egresado`).
- PII en staging y clinical — no exportar a docs versionados.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. **392 rutas sin estadia**: evaluar si se crean estadias adicionales o se relaja ventana de matching.
2. **257 irresolubles**: requieren intervencion humana o creacion de pacientes.
3. **734 visitas sin provider**: asignacion manual via app o nuevo lote de reconciliacion.
4. **Duplicate visits**: disenar flujo de merge/pushout.
5. **Profesionales ambiguous**: desambiguar PIA, CAMILA y otros.

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -c "SELECT count(*) FROM operational.visita WHERE fecha >= '2026-01-01';"
```
