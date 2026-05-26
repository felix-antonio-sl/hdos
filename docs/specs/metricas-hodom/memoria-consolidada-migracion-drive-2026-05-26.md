# Memoria consolidada migracion Drive HODOM — Corte final 2026-05-26

Fecha: 2026-05-26. Rama: `main`.
Commit base: `f412a6a feat(audit): vistas estables de auditoria basadas en provenance`.
Actualizacion de cierre: resolucion de estadias activas, sincronizacion activo/egreso desde INGRESOS vivo, contrato flexible V2 materializado y normalizacion nominal controlada.

Actualizacion app/censo: ver `handoff-app-censo-calidad-datos-2026-05-26.md`. Se detecto que `/censo` exponia datos core incompletos como `a`, `0a` o diagnostico vacio. Se aplico respaldo operativo desde `staging.hodom_ingreso_2026` por RUT en `hdos-app` para edad/diagnostico cuando el core falta o es implausible, sin mutar datos clinicos. Queda pendiente una migracion DB acotada para corregir core solo con anclas RUT unicas y sin flags de calidad.

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
| Pacientes normalizados nominalmente desde INGRESOS | **7** |
| Estadias en `clinical.estadia` | **855** (+36 creadas desde INGRESOS + 18 resueltas desde INGRESOS + 117 sincronizadas activo/egreso + 21 ventanas previas extendidas) |
| Estadias resueltas para rutas sin ventana activa | **18** (17 abiertas + 1 extension) |
| Ventanas de estadia extendidas | 21 (13 post-egreso + 8 pre-ingreso) |
| INGRESOS 2026 en staging | 731 filas vivas (5 hojas Google Sheet) |
| RUT distintos en INGRESOS | 220 |
| Estadias activas core respaldadas por INGRESOS `ACTIVO` | 19/19 |
| Propuestas de reconciliacion totales | 1,300+ |
| Word-overlap V2 materializado | 3,197 filas |
| Campos enriquecidos por duplicados V2 | 25 |
| Provenance total | 10,222 filas de migracion 2026 core |
| Decisiones humanas efectivas | 0 |
| Tests | 99/99 OK |

### Distribucion de rutas 2026 por gate

| Gate | Rutas | Significado |
| --- | ---: | --- |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 2,064 | Ya promovidas o con visita core |
| `BLOCKED_NO_PATIENT_MATCH` | 709 | Paciente no matchea por `norm_text` exacto; V2 reduce esta cola a 177 |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 58 | Sin estadia activa en fecha visita tras cierre oficial de estadias por INGRESOS |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 21 | Ambiguedad de identidad |
| `READY_IDENTITY_STAY_ONLY` | 298 | Listas por identidad/estadia; mayoritariamente pendientes de servicio/diccionarios |

### Distribucion por contrato flexible V2

| Gate V2 | Rutas | Significado |
| --- | ---: | --- |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 2,401 | Visita core existente mismo dia usando identidad flexible unica |
| `READY_IDENTITY_STAY_ONLY` | 287 | Identidad y estadia resueltas; falta contrato de servicio/domicilio/profesional para insertar |
| `BLOCKED_NO_PATIENT_MATCH` | 177 | Sin paciente unico incluso con word-overlap materializado |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 156 | Match nominal no unico; requiere revision o ancla por RUT/SGH |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 129 | Identidad flexible unica, pero sin ventana activa tras cierre oficial de estadias por INGRESOS |

### Diagnostico de los 868 bloqueados restantes

Los bloqueos residuales ya no se explican por las 288 rutas sin estadia del corte anterior. Esa cola fue reducida a 2 rutas en el contrato exacto mediante INGRESOS antes de sincronizar egresos:
- 17 estadias abiertas creadas desde filas `ACTIVO` de INGRESOS, que explican 284 rutas.
- 1 estadia existente extendida hacia atras usando rango cerrado de INGRESOS, que explica 2 rutas.
- 2 rutas quedaron `UNRESOLVED_NO_INGRESOS_ANCHOR`.

El contrato exacto empeora nominalmente tras normalizar 7 nombres con segundos nombres desde INGRESOS, porque sigue dependiendo de igualdad `norm_text`. Por eso el contrato normativo de trabajo pasa a ser `v_hodom_route_promotion_contract_v2`, respaldado por tabla materializada de word-overlap.

Despues de sincronizar estados desde la planilla viva INGRESOS, el contrato V2 muestra 129 rutas sin estadia activa. Esto no implica retroceso de poblacion: varias rutas caen despues de egresos oficiales ahora cerrados. La siguiente revision debe distinguir visitas Drive posteriores al egreso, errores de fecha y nuevos episodios no representados.

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
| 10 | `hodom-active-stay-resolution.sql` | INSERT/UPDATE estadias desde INGRESOS con `daterange &&` | 17 estadias nuevas + 1 extendida |
| 11 | `hodom-word-overlap-contract-v2.sql` | Tabla materializada word-overlap + contrato V2 | 3,197 matches |
| 12 | `hodom-patient-name-normalization.sql` | UPDATE controlado de nombres desde INGRESOS | 7 pacientes |
| 13 | `hodom-v2-duplicate-enrichment.sql` | UPDATE seguro de campos faltantes en duplicados V2 | 25 campos |
| 14 | `hodom-ingreso-status-sync.sql` | Sincronizacion activo/egreso desde INGRESOS vivo | 117 estadias tocadas, 19 activas respaldadas |
| 15 | `hodom-migration-dashboard-final.sql` | Dashboard final consolidado | metricas de cierre |

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
| `db/updates/2026-05-26-hodom-active-stay-resolution.sql` | Resolucion de 288 rutas sin estadia mediante INGRESOS y `daterange &&` |
| `db/updates/2026-05-26-hodom-ingreso-status-sync.sql` | Sincronizacion de activo/egreso desde INGRESOS vivo; cierra splits contiguos y crea estadias activas faltantes |
| `db/updates/2026-05-26-hodom-word-overlap-contract-v2.sql` | Tabla `staging.hodom_patient_word_overlap_match_2026` y contrato flexible V2 |
| `db/updates/2026-05-26-hodom-patient-name-normalization.sql` | Normalizacion controlada de `clinical.paciente.nombre_completo` desde INGRESOS |
| `db/updates/2026-05-26-hodom-v2-duplicate-enrichment.sql` | Enriquecimiento seguro de visitas core existentes desde duplicados V2 |
| `db/updates/2026-05-26-hodom-migration-dashboard-final.sql` | Dashboard final consolidado de migracion 2026 |
| `scripts/hodom_ingreso_2026_staging.py` | Parser Excel (36 tests) |
| `scripts/test_hodom_ingreso_2026_staging.py` | 36 tests parser |
| `scripts/test_drive_pilot_migration.py` | Tests migracion piloto/fuzzy/enrichment |
| `scripts/test_drive_promotion_readiness.py` | Tests contrato, estadias, V2, normalizacion y dashboard |

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
- **Contrato flexible V2**: word-overlap en vez de exact match es correcto conceptualmente. Queda materializado en `staging.hodom_patient_word_overlap_match_2026` y consumido por `v_hodom_route_promotion_contract_v2`.
- **Normalizacion de nombres**: solo se actualiza `clinical.paciente.nombre_completo` cuando los nombres actuales son subconjunto estricto del nombre INGRESOS y existe un unico candidato por paciente.
- **Estado activo/egresado**: INGRESOS vivo prevalece sobre estadias abiertas previas. Si un egreso y una fila activa apuntan a la misma estadia, el egreso documentado prevalece; si la fila activa es posterior al egreso y no solapa, se crea nueva estadia activa.

## Supuestos

- Las visitas sin `provider_id` (734) no tienen correspondencia Drive — son de la app.
- Las estadias creadas desde INGRESOS nacen en `pendiente_evaluacion` por trigger normativo y solo se activan/egresan mediante `clinical.transition_estadia`.
- Las filas INGRESOS `ACTIVO` sin fecha de egreso representan episodios abiertos y se modelan con `fecha_egreso = NULL`.
- La planilla INGRESOS 2026 DRIVE es la fuente autoritativa de episodios 2026.
- El censo SGH refleja el estado actual del hospital y puede usarse como verificacion de identidad.

## Riesgos

- Propuestas simuladas (`proposed`) sin aprobacion humana.
- Pacientes creados con datos parciales (sin RUT en algunos).
- Quedan residuos de INGRESOS status sync: 3 activos sin paciente core, 1 conflicto activo/egresado, 3 egresos sin estadia y 7 filas con fechas invalidas/review.
- El contrato exacto ya no es la herramienta primaria para identidad despues de normalizar nombres; usar V2 para trabajo operativo.
- Las 129 rutas `BLOCKED_NO_ACTIVE_STAY_MATCH` en V2 mezclan visitas posteriores al egreso oficial, errores de fecha y posibles nuevos episodios.
- Las 287 rutas `READY_IDENTITY_STAY_ONLY` en V2 requieren diccionario/servicio antes de insertar visitas nuevas.
- PII en staging y clinical — no exportar.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. **Resolver residuos INGRESOS/status**: revisar `staging.v_hodom_ingreso_status_sync_summary_2026`, especialmente 3 activos sin paciente core, 1 conflicto activo/egresado, 3 egresos sin estadia y 7 fechas invalidas/review.

2. **Resolver residuos V2**: investigar 129 `BLOCKED_NO_ACTIVE_STAY_MATCH` del contrato V2 y 177 `BLOCKED_NO_PATIENT_MATCH` con anclas RUT/SGH. No promover por fuzzy sin evidencia adicional.

3. **Diccionario de servicios**: resolver `service_prestacion` para las 287 rutas `READY_IDENTITY_STAY_ONLY` V2 antes de insertar nuevas visitas.

4. **Duplicate visits**: continuar enriquecimiento (UPDATE, no merge) para rutas `REVIEW_DUPLICATE_PUSHOUT_REQUIRED`, solo cuando exista target unico, valor fuente unico y campo destino nulo.

5. **Censo SGH periodico**: usar `hsc-agent-cli find --hospitalizados --hodom` como fuente de ancla operacional para pacientes activos y estadias abiertas.

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -c "SELECT * FROM staging.v_hodom_migration_dashboard;"
```
