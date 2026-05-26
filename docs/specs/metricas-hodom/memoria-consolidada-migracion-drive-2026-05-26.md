# Memoria consolidada migracion Drive HODOM — Corte final 2026-05-26

Fecha: 2026-05-26. Rama: `main`.
Commit: `7877247 feat(migration): cerrar fases 5-7`.

## Estado final consolidado

Migracion Drive HODOM 2026 ejecutada en 8 fases sobre rutas con `visit_date >= '2026-01-01'` + 2 fases paralelas de INGRESOS 2026 DRIVE.

### Resultados cuantitativos

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 en staging | 3,150 |
| Visitas Drive-sourced en `operational.visita` | **1,162** (37%) |
| Visitas core 2026 enriquecidas (provider) | 1,065 |
| Visitas core 2026 enriquecidas (hora) | 522 |
| Visitas core 2026 completas (4/4 campos) | 1,329 (59%) |
| Pacientes en `clinical.paciente` | **733** (+43 desde INGRESOS) |
| Estadias en `clinical.estadia` | **832** (+32 desde INGRESOS) |
| INGRESOS 2026 en staging | 722 filas (5 hojas) |
| Match paciente por RUT (ingresos) | 216/216 (100%) |
| Match estadia por solapamiento (ingresos) | ~340/417 (82%) |
| Propuestas de reconciliacion totales | ~1,300+ |
| Provenance total | ~8,500+ filas |
| Decisiones humanas efectivas | 0 |
| Tests | 93/93 OK |

### Distribucion de rutas 2026 por gate

| Gate | Rutas | Significado |
| --- | ---: | --- |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 2,136 | Ya promovidas o con visita core |
| `BLOCKED_NO_PATIENT_MATCH` | ~520 | 323 ya promovidas + ~200 irresolubles |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 392 | Sin estadia activa en fecha visita |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 21 | Ambiguedad de identidad |
| `READY_IDENTITY_STAY_ONLY` | 21 | Listas (sin servicio mapeado) |

### Fases ejecutadas

| Fase | Artefacto SQL | Accion | Impacto |
| --- | --- | --- | --- |
| Piloto | `drive-pilot-migration` | INSERT 115 rutas svc+addr | 112 visitas |
| 1 | `drive-enrichment-2026` | UPDATE provider+hora | 1,065+522 enriquecidas |
| 2 | `drive-new-visits-2026` | INSERT READY_IDENTITY | 333 visitas |
| 3 | `professional-reconciliation` | Match nombres→DB | 62 propuestas |
| 4 | `fuzzy-patient-match-2026` | Word-overlap identidad | 30 propuestas, 337 rutas |
| 5 | `drive-fuzzy-resolved-insert` | INSERT fuzzy-resolved | 310 visitas |
| 6 | `hodom-ingreso-2026-staging` | DDL + parser Excel | 722 ingresos |
| 6b | `hodom-ingreso-2026-views` | 6 vistas calidad/conciliacion | — |
| 6c | `hodom-create-missing-patients` | INSERT pacientes | +43 pacientes |
| 6d | `hodom-create-missing-stays` | INSERT estadias | +32 estadias |
| 7 | Ext. servicio v2 + INSERT | 445 svc props + INSERT | 326 visitas |
| 8 | Ingreso cross-match + INSERT | 6 identidades + INSERT | 56 visitas |

### Soluciones exploradas para frentes duros

1. **Cruce con INGRESOS 2026**: 6 nombres bloqueados (58 rutas) encontrados en la planilla de ingresos → identidad via RUT. **Funcionó**. 56 visitas promovidas.

2. **Creacion de estadias desde INGRESOS**: 106 rutas sin estadia tienen datos en INGRESOS que permitirian crear estadias. **Detectado pero requiere manejo mas fino** de exclusion constraints (overlap de fechas con estadias ya creadas en fases anteriores).

3. **Extension de ventana de estadia**: 13 rutas a 1-3 dias post-egreso, 12 pre-ingreso. Posible ajustar `fecha_egreso`/`fecha_ingreso` de estadias existentes. **No implementado**.

4. **Cruce inverso INGRESOS→rutas para los 392**: usar fechas de ingreso de la planilla para cubrir visitas que caen fuera de ventana. **Parcialmente implementado** (106 candidatos detectados).

## Artefactos del repo

| Artefacto | Rol |
| --- | --- |
| `db/updates/2026-05-26-drive-pilot-migration.sql` | Piloto 115 rutas |
| `db/updates/2026-05-26-professional-reconciliation.sql` | Conciliacion profesional (62 props) |
| `db/updates/2026-05-26-drive-enrichment-2026.sql` | Enriquecimiento UPDATE |
| `db/updates/2026-05-26-drive-new-visits-2026.sql` | Insercion 333 visitas |
| `db/updates/2026-05-26-fuzzy-patient-match-2026.sql` | Fuzzy matching (30 props) |
| `db/updates/2026-05-26-drive-fuzzy-resolved-insert.sql` | Insercion fuzzy 310 |
| `db/updates/2026-05-26-hodom-ingreso-2026-staging.sql` | DDL staging ingresos |
| `db/updates/2026-05-26-hodom-ingreso-2026-views.sql` | Vistas calidad/conciliacion |
| `db/updates/2026-05-26-hodom-create-missing-patients.sql` | Creacion 43 pacientes |
| `db/updates/2026-05-26-hodom-create-missing-stays.sql` | Creacion 32 estadias |
| `scripts/hodom_ingreso_2026_staging.py` | Parser Excel ingresos (36 tests) |
| `scripts/test_hodom_ingreso_2026_staging.py` | 36 tests parser |
| `scripts/test_drive_pilot_migration.py` | 24 tests migracion |

## Pendientes priorizados

1. **Crear 106 estadias desde INGRESOS con overlap handling**: la via esta detectada, el codigo funciona pero requiere manejo de exclusion constraints. Ver `hodom-create-missing-stays.sql` como base y ajustar los NOT EXISTS para dateranges que ya fueron creados.

2. **392 sin estadia**: extender ventanas de estadias existentes (13 rutas a 1-3 dias) y usar fechas de INGRESOS para el resto.

3. **~200 irresolubles**: pacientes sin correspondencia en DB ni en INGRESOS. Evaluar creacion desde RUT (si se consigue) o flag `UNRESOLVABLE`.

4. **734 visitas sin provider_id**: sin correspondencia Drive. Asignacion manual o reconciliacion futura con otra fuente.

5. **Duplicate visits**: flujo separado de merge/pushout para 6,293+3,151 rutas.

6. **Profesionales ambiguous**: desambiguar PIA (2 candidatos), CAMILA (2 candidatos), M.JOSE (fono).

## Riesgos

- Propuestas simuladas (`proposed`) sin aprobacion humana final.
- Pacientes creados desde Drive con datos parciales.
- Estadias en estado `pendiente_evaluacion` (no transicionadas).
- PII en staging y clinical — no exportar a docs versionados.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md`:

1. **Crear 106 estadias desde INGRESOS**: usar `ingreso_candidates` CTE del ultimo intento, con overlap handling mas robusto (exclusion por `daterange &&` en vez de comparacion simple). Ver `hodom-create-missing-stays.sql`.
2. **Extender 13+12 estadias**: UPDATE `fecha_egreso` +1-3 dias donde la visita esta apenas fuera de ventana.
3. **257 irresolubles**: verificar si `hsc-agent-cli` puede obtener RUTs por nombre a traves de HCC search.
4. **Duplicate visits**: disenar flujo de enriquecimiento (no merge) para las 2,136 rutas con visita core mismo dia — usar datos Drive para completar campos faltantes en la visita existente.

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -c "SELECT count(*) FROM operational.visita WHERE fecha >= '2026-01-01';"
```
