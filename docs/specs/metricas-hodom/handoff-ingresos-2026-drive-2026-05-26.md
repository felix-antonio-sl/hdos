# Handoff INGRESOS 2026 DRIVE

Fecha: 2026-05-26.
Rama: `main`.
Corte base: `bd48e92 feat(migration): enrich fuzzy-resolved HODOM visits`.

## Estado actual

La fuente `INGRESOS 2026 DRIVE` esta considerada como source original, pero aun no esta depositada como tabla relacional nominal de ingresos/estadias.

Evidencia consolidada:

| Indicador | Valor |
| --- | ---: |
| Drive ID | `1qynoVzgF5a5qMdTVXhfM35zQC4QCtVqh0MNaSHD2_aQ` |
| Dataset | `ingresos_2026` |
| Titulo | `INGRESOS 2026 DRIVE` |
| Archivo local temporal | `.tmp/drive-consolidation/raw/INGRESOS_2026_DRIVE.xlsx` |
| SHA256 | `01d1c6d00daca6367371c66a9762f652c3dd4c7da3aab40363692b01ddf292ee` |
| Hojas detectadas | 5 |
| Registro en `staging.drive_source_file` | si |
| Filas en `staging.hodom_route_visit` desde esta fuente | 0 |
| Filas en `staging.hodom_shift_handover` desde esta fuente | 0 |
| Tabla nominal especifica de ingresos 2026 | no existe aun |

Estado 2026 ya migrado desde rutas/visitas:

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 en staging | 3,150 |
| Visitas core 2026 | 2,721 |
| Visitas nuevas Drive-sourced promovidas | 473 |
| Visitas core tocadas por fases Drive controladas | 2,081 |
| Visitas core 2026 completas 4/4 | 1,526 |
| Provenance fases Drive 2026 controladas | 7,535 |

## Decision

El siguiente frente normativo no debe seguir insertando visitas. Debe abrir una fase separada para `INGRESOS 2026 DRIVE`, porque esta planilla gobierna pacientes, ingresos, egresos y estadias, no rutas de visita.

Regla de seguridad:

- Primero crear staging nominal y vistas de conciliacion.
- No escribir en `clinical.paciente` ni `clinical.estadia` hasta tener gates agregados y colas de revision.
- No exportar nombres, RUT ni filas nominales a documentos versionados.
- `simulated_expert_reconciliation` puede orientar revision, pero no equivale a aprobacion humana.

## Artefactos relevantes

| Artefacto | Uso |
| --- | --- |
| `docs/specs/metricas-hodom/manifiesto-fuentes-drive-2026-05-25.json` | Registra el Drive ID y clasifica `INGRESOS 2026 DRIVE` como `ingresos_2026`. |
| `docs/specs/metricas-hodom/inventario-fuentes-drive-2026-05-25.csv` | Inventario tabular con hash, tamano y hoja. |
| `docs/specs/metricas-hodom/consolidacion-fuentes-drive-2026-05-25.*` | Consolidacion agregada de fuentes Drive. |
| `staging.drive_source_file` | Fuente registrada en la base local. |
| `.tmp/drive-consolidation/raw/INGRESOS_2026_DRIVE.xlsx` | Export temporal nominal no versionado. |
| `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md` | Memoria consolidada del corte de visitas/rutas. |
| `docs/specs/metricas-hodom/handoff-2026-05-25.md` | Handoff historico acumulado. |

## Pendientes

1. Crear DDL staging idempotente para `staging.hodom_ingreso_2026`.
2. Crear parser/loader desde `.tmp/drive-consolidation/raw/INGRESOS_2026_DRIVE.xlsx`.
3. Normalizar RUT, nombres, sexo, fechas, estado, motivo de egreso, prevision y dias de estada.
4. Registrar provenance por fila: `drive_id`, `sheet_name`, `source_row_number`, `source_hash`, `imported_at`.
5. Auditar calidad:
   - RUT vacios o invalidos.
   - fechas invertidas o imposibles.
   - typos de estado o motivo.
   - duplicados intra-hoja e inter-hoja.
   - diferencia entre dias de estada declarado y calculado.
6. Conciliar contra `clinical.paciente`:
   - match fuerte por RUT normalizado.
   - match secundario por nombre + fecha de nacimiento.
   - colas para paciente faltante, RUT conflictivo e identidad ambigua.
7. Conciliar contra `clinical.estadia`:
   - match por paciente + ventana ingreso/egreso.
   - colas para estadia faltante, fecha distinta, solapamiento y duplicado.
8. Cruzar con visitas 2026 ya migradas:
   - visitas sin estadia respaldada por planilla de ingresos.
   - ingresos/estadias sin visitas asociadas.
   - pacientes con visitas pero sin ingreso anual.
9. Solo despues de gates agregados, definir una migracion controlada hacia `clinical.paciente` y `clinical.estadia`.

## Supuestos

- La planilla `INGRESOS 2026 DRIVE` es fuente original para usuarios/episodios 2026.
- La base ya funciona con `clinical.paciente`, `clinical.estadia` y `operational.visita`; cualquier cambio en `clinical` tiene mayor riesgo que enriquecer `operational`.
- El archivo nominal puede contener errores humanos visibles en muestra inicial, por ejemplo estados con typo y fechas de egreso anteriores a ingreso.
- El staging nominal puede contener PII y por eso no debe versionarse fuera de la base local.

## Riesgos

- Crear pacientes por nombre sin RUT confiable puede duplicar identidad clinica.
- Ajustar estadias sin revisar solapamientos puede violar restricciones de episodios.
- Interpretar egresos mensuales como ingresos unicos puede duplicar episodios.
- No incorporar esta fuente dejaria 2026 saneado solo en visitas, pero no en usuarios/estadias.
- Exportar filas nominales de la planilla en docs versionados expondria informacion sensible.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/handoff-ingresos-2026-drive-2026-05-26.md`.

Prioridad: crear staging nominal para `INGRESOS 2026 DRIVE` (`staging.hodom_ingreso_2026`) y parser/loader desde `.tmp/drive-consolidation/raw/INGRESOS_2026_DRIVE.xlsx`, con tests antes de SQL/codigo. No tocar `clinical` todavia. Luego construir vistas agregadas de calidad, conciliacion contra `clinical.paciente`, conciliacion contra `clinical.estadia` y cruce con visitas 2026 ya migradas. Mantener PII fuera de docs versionados y tratar `simulated_expert_reconciliation` como orientacion, no aprobacion humana.

