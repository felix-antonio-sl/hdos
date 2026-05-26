# Memoria consolidada migracion Drive HODOM — Corte final 2026-05-26

Fecha: 2026-05-26. Rama: `main`.
Commit base: `f412a6a feat(audit): vistas estables de auditoria basadas en provenance`.

## Estado final consolidado

Migracion Drive HODOM 2026 ejecutada en multiples fases sobre rutas con `visit_date >= '2026-01-01'` (3,150 de 17,117 totales) + fases paralelas de INGRESOS 2026 DRIVE.

### Resultados cuantitativos

| Indicador | Valor |
| --- | ---: |
| Visitas Drive-sourced en `operational.visita` 2026 | **1,275** (40%) |
| Visitas core 2026 enriquecidas (provider) | 1,065 |
| Visitas core 2026 enriquecidas (hora) | 522 |
| Visitas core 2026 completas (4/4 campos) | 1,329 (59%) |
| Pacientes en `clinical.paciente` | **733** (+43 desde INGRESOS) |
| Estadias en `clinical.estadia` | **836** (+36 desde INGRESOS + 21 extendidas) |
| Ventanas de estadia extendidas | 21 (13 post-egreso + 8 pre-ingreso) |
| INGRESOS 2026 en staging | 722 filas (5 hojas Excel) |
| Match paciente por RUT (ingresos) | 216/216 (100%) |
| Propuestas de reconciliacion totales | 1,300+ |
| Provenance total | ~9,600+ filas |
| Decisiones humanas efectivas | 0 |
| Tests | 93/93 OK |

### Distribucion de rutas 2026 por gate

| Gate | Rutas | Significado |
| --- | ---: | --- |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 2,249 | Ya promovidas o con visita core |
| `BLOCKED_NO_PATIENT_MATCH` | 580 | Paciente no matchea por `norm_text` exacto |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 288 | Sin estadia activa en fecha visita |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 21 | Ambiguedad de identidad |
| `READY_IDENTITY_STAY_ONLY` | 12 | Listas (sin servicio mapeado) |

### Diagnostico de los 868 bloqueados restantes

Los 580+288+21 = 868 rutas bloqueadas no son pacientes ausentes. La evidencia del censo SGH (via `hsc-agent-cli find --hospitalizados --hodom`) confirmo que la mayoria existen en el hospital y en `clinical.paciente`. El bloqueo es nominal:
- El contrato usa `norm_text` exacto, que falla cuando Drive omite segundos nombres ("JUANA BELMAR" vs "JUANA MARIA DEL CARMEN BELMAR")
- Las propuestas de reconciliacion fuzzy/direct ya resuelven la identidad para ~24 de 51 nombres
- Las 288 sin estadia tienen paciente (via fuzzy) pero la fecha de visita no cae dentro de ninguna ventana de estadia

### Lecciones del censo SGH

El censo HODOM activo (22 pacientes) fue cruzado contra nombres bloqueados. 17 de 22 matchean por word-overlap. El puente `censo SGH → RUT → clinical.paciente` funciona pero requiere que los nombres en `clinical.paciente` incluyan segundos nombres — actualmente la DB tiene nombres mas cortos que el hospital.

## Fases ejecutadas

| # | Artefacto | Accion | Impacto |
| --- | --- | --- | --- |
| Piloto | `drive-pilot-migration.sql` | INSERT 115 rutas svc+addr | 112 visitas |
| 1 | `drive-enrichment-2026.sql` | UPDATE provider+hora | 1,065+522 |
| 2 | `drive-new-visits-2026.sql` | INSERT READY_IDENTITY | 333 visitas |
| 3 | `professional-reconciliation.sql` | Match nombres→DB | 62 propuestas |
| 4 | `fuzzy-patient-match-2026.sql` | Word-overlap identidad | 30 propuestas |
| 5 | `drive-fuzzy-resolved-insert.sql` | INSERT fuzzy-resolved | 310 visitas |
| 6 | `hodom-ingreso-2026-staging.sql` | DDL + parser | 722 ingresos |
| 6b | `hodom-ingreso-2026-views.sql` | Vistas calidad/conciliacion | 6 vistas |
| 6c | `hodom-create-missing-patients.sql` | INSERT pacientes | +43 |
| 6d | `hodom-create-missing-stays.sql` | INSERT estadias | +32 |
| 7 | `hodom-ingreso-audit-stable.sql` | Vistas provenance-based | Dashboard + 6 vistas |
| 8 | Extension ventanas estadia | UPDATE fecha_egreso/ingreso | 21 ventanas |
| 9 | Promociones posteriores | INSERT desde READY | +145 visitas |

## Artefactos del repo

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
| `db/updates/2026-05-26-hodom-create-missing-stays.sql` | Creacion 36 estadias |
| `db/updates/2026-05-26-hodom-ingreso-audit-stable.sql` | Vistas estables provenance-based |
| `scripts/hodom_ingreso_2026_staging.py` | Parser Excel (36 tests) |
| `scripts/test_hodom_ingreso_2026_staging.py` | 36 tests parser |
| `scripts/test_drive_pilot_migration.py` | 24 tests migracion |

## Decisiones consolidadas

- **Scope 2026**: solo rutas con `visit_date >= 2026-01-01`.
- **provider_id = NULL es deuda aceptada**: solo high-confidence unique matches.
- **Fuzzy matching**: word-overlap con todas las palabras significativas. Marcado `proposed, human_required=true`.
- **Enriquecimiento > Insercion**: UPDATE sobre existentes, INSERT solo si no hay visita mismo dia.
- **Provenance por campo**: cada campo deja registro en `migration.provenance`.
- **`daterange &&` para estadias**: overlap semantico correcto para no duplicar episodios.
- **Vistas basadas en provenance**: metricas estables, idempotentes, independientes del estado vivo.
- **PII**: nunca en docs versionados.
- **hsc-agent-cli**: censo SGH util para confirmar existencia de pacientes. No busca por nombre sin RUT.
- **Contrato flexible V2**: word-overlap en vez de exact match es correcto conceptualmente pero costoso en compilacion. Se desarrollo un wrapper ligero (`v_hodom_route_promotion_contract_v2`) que usa reconciliation decisions como puente.

## Supuestos

- Las visitas sin `provider_id` (734) no tienen correspondencia Drive — son de la app.
- Las estadias creadas desde INGRESOS estan en `pendiente_evaluacion` — requieren transicion via app.
- La planilla INGRESOS 2026 DRIVE es la fuente autoritativa de episodios 2026.
- El censo SGH refleja el estado actual del hospital y puede usarse como verificacion de identidad.

## Riesgos

- Propuestas simuladas (`proposed`) sin aprobacion humana.
- Pacientes creados con datos parciales (sin RUT en algunos).
- Estadias en `pendiente_evaluacion` sin transicion a `egresado`.
- Las 868 rutas bloqueadas representan pacientes que existen pero no se promueven por rigidez del contrato o ventana temporal.
- PII en staging y clinical — no exportar.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. **Resolver los 288 sin estadia**: extender mas ventanas (no solo 1-3 dias) o crear estadias desde INGRESOS con `daterange &&`. El overlap checking ya esta implementado en `v_hodom_ingreso_2026_pending_stays`.

2. **Contrato flexible V2 optimizado**: materializar los resultados de word-overlap en una tabla auxiliar para evitar compilacion costosa. Luego usar esa tabla como fuente de `matched_patient_id` en el contrato.

3. **Normalizar nombres en clinical.paciente**: agregar segundos nombres desde INGRESOS o SGH para mejorar matching exacto por `norm_text`. Esto eliminaria la necesidad de fuzzy matching.

4. **Censo SGH periodico**: usar `hsc-agent-cli find --hospitalizados --hodom` para mantener actualizada la tabla de pacientes activos y cruzar con rutas pendientes.

5. **Duplicate visits**: disenar flujo de enriquecimiento (UPDATE, no merge) para las 2,249 rutas con visita core mismo dia.

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -c "SELECT * FROM staging.v_hodom_migration_dashboard;"
```
