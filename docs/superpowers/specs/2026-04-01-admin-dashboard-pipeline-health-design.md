# HODOM Dashboard Administrativo: Pipeline Health, Resolución y Modelo Estabilizado

**Fecha**: 2026-04-01
**Estado**: Aprobado
**Enfoque**: C — Modelo estable + dashboard alineado en paralelo

## Contexto

HODOM es un sistema de hospitalización domiciliaria que procesa datos desde planillas CSV y Excel a través de un pipeline de 3 etapas:

1. `migrate_hodom_csv.py` — normalización cruda
2. `build_hodom_intermediate.py` — modelo intermedio relacional
3. `build_hodom_enriched.py` — enriquecimiento, reconciliación, rescate

El dashboard administrativo (`streamlit_admin_app.py`) sirve a dos audiencias:
- **Jefatura/dirección**: indicadores agregados confiables para reportar a MINSAL/Servicio de Salud
- **Gestoras/equipo clínico**: verificación nominal caso a caso

### Estado actual del pipeline

- 1,848 episodios (1,583 merged, 159 raw, 80 alta_rescued, 26 form_rescued)
- 1,468 pacientes
- 55 episodios sin fecha_egreso
- 13 episodios sin fecha_ingreso
- 31 archivos fuente CSV + planilla de altas Excel

### Issues pendientes

| Issue | Cantidad | Estado |
|-------|----------|--------|
| UNMATCHED_FORM_SUBMISSION | 139 | REVIEW_REQUIRED |
| PATIENT_WITHOUT_EPISODE | 129 | REVIEW_REQUIRED |
| LOCALITY_COORDINATES_MISSING | 204 | OPEN |
| ESTABLISHMENT_UNRESOLVED | 38 | OPEN |
| BIRTHDATE_AGE_MISMATCH | 7 | OPEN |
| Discharges unresolved | 80 | sin match |
| Match review queue (manual) | 1,681 | 154 con auto_close |
| Identity review | 5 | pendiente |

## Objetivos

1. Estabilizar el modelo de datos de salida del pipeline como contrato
2. Panel de salud del pipeline con semáforos de confiabilidad
3. Flujos de resolución activos con edición directa
4. Control reforzado de duplicados (eventos y pacientes)

---

## 1. Modelo de Datos Estabilizado

### 1.1 Capa Core — Entidades canónicas

#### `patient_master.csv`

Paciente canónico deduplicado. El dashboard no necesita hacer joins para mostrar la vista de pacientes.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| patient_id | string | Identificador único |
| nombre_completo | string | Nombre normalizado |
| rut | string | RUT validado |
| sexo | string | femenino/masculino/sin_sexo |
| fecha_nacimiento | date | ISO 8601 |
| edad_reportada | int | Edad desde fuente |
| edad_calculada | int | Calculada desde fecha_nacimiento |
| comuna | string | |
| cesfam | string | |
| prevision | string | |
| total_hospitalizaciones | int | Conteo de stays |
| primera_fecha_ingreso | date | |
| ultima_fecha_egreso | date | |
| dias_totales_estadia | int | Suma de días en todos los stays |
| estado_actual | string | activo/egresado/sin_info |
| tiene_issues_abiertos | bool | True si hay quality_issue OPEN/REVIEW_REQUIRED |

#### `hospitalization_stay.csv`

Hospitalización consolidada. 1 fila = 1 estancia real. Reemplaza a `episode_master.csv` como fuente del dashboard admin.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| stay_id | string | Identificador único del stay |
| patient_id | string | FK a patient_master |
| fecha_ingreso | date | |
| fecha_egreso | date | Nullable si aún activo |
| estado | string | ACTIVO/EGRESADO/SIN_ESTADO |
| servicio_origen | string | |
| prevision | string | |
| diagnostico_principal | string | Consolidado de fuentes |
| motivo_egreso | string | |
| establecimiento | string | Nombre resuelto |
| codigo_deis | string | Código DEIS resuelto |
| comuna | string | |
| localidad | string | |
| latitud | float | |
| longitud | float | |
| source_episode_ids | string | pipe-separated |
| source_episode_count | int | |
| episode_origin | string | raw/merged/alta_rescued/form_rescued/consolidated |
| confidence_level | string | high (merged con egreso completo), medium (raw o alta_rescued), low (form_rescued o sin egreso) |
| gestora | string | |
| usuario_o2 | string | |

#### `episode_source.csv`

Trazabilidad: cada fila fuente que alimentó un stay.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| source_id | string | |
| stay_id | string | FK a hospitalization_stay |
| episode_id | string | ID del episodio original |
| raw_file | string | Nombre del archivo fuente |
| raw_row | int | Fila en el archivo fuente |
| origin_type | string | raw/form/alta |
| fields_contributed | string | Campos que esta fuente aportó al stay |

### 1.2 Capa Referencia

Sin cambios estructurales:
- `establishment_reference.csv`
- `locality_reference.csv`

### 1.3 Capa Calidad y Auditoría

#### `pipeline_health.csv`

1 fila por ejecución del pipeline.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| run_id | string | |
| run_timestamp | datetime | |
| source_files_processed | int | |
| raw_rows_processed | int | |
| patients_total | int | |
| stays_total | int | |
| stays_with_egreso | int | |
| stays_with_ingreso | int | |
| stays_with_establishment | int | |
| issues_open | int | |
| issues_review_required | int | |
| review_queue_pending | int | |
| duplicate_candidates | int | |
| coverage_gaps_detected | int | |
| health_status | string | green/yellow/red |

#### `quality_issue.csv`

Solo issues abiertos con acción requerida (OPEN + REVIEW_REQUIRED).

| Columna | Tipo | Descripción |
|---------|------|-------------|
| issue_id | string | |
| issue_type | string | |
| severity | string | |
| entity_type | string | patient/stay/episode |
| entity_id | string | |
| description | string | Descripción humana del problema |
| raw_value | string | |
| suggested_value | string | |
| status | string | OPEN/REVIEW_REQUIRED |
| created_at | datetime | |

#### `review_queue.csv`

Cola unificada de revisión: match pendientes + identidad + egresos sin resolver.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| queue_item_id | string | |
| queue_type | string | unmatched_form/unresolved_discharge/identity/patient_orphan/establishment |
| entity_id | string | ID del formulario, alta, paciente, etc. |
| patient_name | string | |
| patient_rut | string | |
| summary | string | Resumen legible del caso |
| candidate_ids | string | pipe-separated, IDs de episodios/stays candidatos |
| candidate_scores | string | pipe-separated, scores de matching |
| priority | string | high (afecta indicadores REM), medium (datos incompletos), low (cosmético/referencial) |
| created_at | datetime | |

#### `coverage_gap.csv`

Meses con cobertura sospechosamente baja.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| month | string | YYYY-MM |
| metric | string | ingresos/egresos/stays |
| observed | int | Conteo real |
| expected | int | Promedio móvil 6 meses |
| ratio | float | observed/expected |
| gap_flag | bool | True si ratio < 0.70 |

#### `duplicate_candidate.csv`

Pares sospechosos de duplicación.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| candidate_id | string | |
| entity_type | string | stay/patient |
| entity_a_id | string | |
| entity_b_id | string | |
| match_reason | string | same_rut_similar_dates/similar_name_same_comuna/overlapping_stays |
| confidence | float | 0-1 |
| reviewed | bool | False hasta que gestora decide |
| resolution | string | merge/not_duplicate/null |

#### `manual_resolution.csv`

Decisiones de gestoras. Input para el pipeline y output del dashboard.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| resolution_id | string | |
| queue_type | string | Tipo de cola origen |
| item_id | string | ID del item en la cola |
| action | string | associate/create/discard/correct/merge/not_duplicate |
| target_id | string | ID del episodio/stay/paciente destino |
| field_corrected | string | Nombre del campo corregido (si action=correct) |
| old_value | string | |
| new_value | string | |
| resolved_by | string | Nombre del usuario |
| resolved_at | datetime | |
| applied | bool | False hasta que el pipeline lo procese |

---

## 2. Panel de Salud del Pipeline

Nuevo tab "Salud del Pipeline" en el dashboard admin.

### 2.1 Semáforo general

Indicador único de confiabilidad:

| Estado | Condiciones |
|--------|------------|
| **Verde** | Cobertura mensual estable (sin gaps), <5% issues abiertos sobre total stays, 0 duplicados pendientes, pipeline ejecutado en últimos 7 días |
| **Amarillo** | 1+ gaps de cobertura detectados, o entre 5-15% issues abiertos, o duplicados pendientes |
| **Rojo** | >15% issues abiertos, o meses completos sin datos, o pipeline no ejecutado en >7 días |

### 2.2 Tarjetas de métricas

Tarjetas con valor + tendencia:

- Stays totales / Pacientes únicos
- % con fecha_egreso completa
- % con establecimiento resuelto
- Issues abiertos por tipo (barras apiladas)
- Cola de revisión pendiente (por queue_type)
- Gaps de cobertura detectados
- Duplicados pendientes de revisión
- Última ejecución del pipeline (timestamp + delta)

### 2.3 Cobertura mensual

Gráfico de líneas: observado vs esperado (promedio móvil 6 meses) por mes.
Meses con gap_flag=True se resaltan en rojo.
Permite a jefatura identificar: "octubre-diciembre 2025 está bajo, faltan fuentes".

---

## 3. Flujos de Resolución Activos

Nuevo tab "Revisión y Resolución" con sub-tabs por tipo de cola.

### 3.1 Formularios sin match (queue_type=unmatched_form)

- Muestra: formulario (paciente, fecha, servicio, diagnóstico, gestora) + top 3 candidatos con score
- Acciones:
  - "Asociar a este episodio" → action=associate, target_id=stay_id
  - "Crear episodio nuevo" → action=create
  - "Descartar" → action=discard
- Filtros: por gestora, servicio, fecha, prioridad

### 3.2 Egresos sin resolver (queue_type=unresolved_discharge)

- Muestra: alta de planilla (paciente, RUT, fechas, diagnóstico) + stays candidatos
- Acciones:
  - "Asociar a este stay" → action=associate
  - "Crear stay nuevo" → action=create
  - "Descartar (duplicado/error)" → action=discard

### 3.3 Datos e identidad (queue_type=identity/patient_orphan/establishment)

- Muestra: caso con datos conflictivos
- Acciones con edición directa vía st.form:
  - Corregir RUT, nombre, fecha_nacimiento, sexo, comuna, cesfam
  - Asignar establecimiento desde dropdown con catálogo DEIS
  - Confirmar como correcto
  - Marcar paciente para eliminar (huérfano confirmado)
- Validación en tiempo real: RUT duplicado, formato fecha, etc.
- Confirmación para campos críticos (RUT, fecha_ingreso)

### 3.4 Posibles duplicados (queue_type desde duplicate_candidate)

- Muestra: dos filas lado a lado (stay vs stay, o paciente vs paciente)
- Acciones:
  - "Fusionar" → elige cuál gana, el otro se marca como duplicado
  - "No es duplicado" → marca como revisado

### 3.5 Contadores en sidebar

Badges con conteo pendiente por tipo de cola, visibles desde cualquier tab.

### 3.6 Persistencia

Todas las decisiones se escriben a `manual_resolution.csv`. El pipeline en su próxima corrida:
1. Lee `manual_resolution.csv`
2. Aplica resoluciones (asociaciones, correcciones, descartes, fusiones)
3. Marca applied=True
4. Regenera CSVs canónicos con las resoluciones incorporadas

---

## 4. Control de Duplicados Reforzado

### 4.1 Prevención en pipeline (Capa 1)

Deduplicación al generar `hospitalization_stay.csv`:

| Criterio | Ventana |
|----------|---------|
| patient_id + fecha_ingreso + fecha_egreso | Exacto (actual) |
| rut + fecha_ingreso | ±2 días (nuevo — cubre identidad fragmentada) |
| nombre_normalizado + fecha_ingreso | ±2 días (nuevo — fallback sin RUT) |

Cada stay consolidado registra source_episode_ids y source_episode_count.

### 4.2 Detección en dashboard (Capa 2)

Panel "Posibles duplicados" detecta:
- Stays del mismo paciente con fechas solapadas
- Pacientes distintos con mismo RUT
- Pacientes distintos con nombre >90% similar y misma comuna

Genera `duplicate_candidate.csv` que alimenta el tab de resolución.

### 4.3 Protección en indicadores (Capa 3)

- REM y métricas de jefatura siempre calculan sobre `hospitalization_stay.csv` (ya deduplicado)
- Panel de salud incluye métrica: "Duplicados detectados pendientes de revisión"
- Si hay duplicados pendientes, el semáforo baja a amarillo mínimo

---

## 5. Arquitectura de archivos

### Pipeline produce

```
output/spreadsheet/enriched/
├── patient_master.csv              ← paciente canónico
├── hospitalization_stay.csv        ← estancia consolidada
├── episode_source.csv              ← trazabilidad
├── establishment_reference.csv     ← referencia DEIS
├── locality_reference.csv          ← localidades + coords
├── pipeline_health.csv             ← métricas por corrida
├── quality_issue.csv               ← issues abiertos
├── review_queue.csv                ← cola unificada
├── coverage_gap.csv                ← gaps de cobertura
├── duplicate_candidate.csv         ← pares sospechosos
├── manual_resolution.csv           ← decisiones de gestoras
│
│   (archivos internos preservados para trazabilidad)
├── episode_master.csv              ← episodios pre-consolidación
├── match_review_queue.csv          ← cola legacy
├── identity_review_queue.csv       ← cola legacy
├── normalized_discharge_event.csv  ← altas normalizadas
├── ... (resto de archivos intermedios)
```

### Dashboard admin consume

```
streamlit_admin_app.py
├── Tab: Resumen                    ← hospitalization_stay + patient_master
├── Tab: Hospitalizaciones          ← hospitalization_stay
├── Tab: Pacientes                  ← patient_master
├── Tab: REM A21/C1                 ← hospitalization_stay (cálculo por solapamiento)
├── Tab: Territorio                 ← hospitalization_stay + establishment_reference + locality_reference
├── Tab: Metodología                ← texto estático
├── Tab: Salud del Pipeline         ← pipeline_health + coverage_gap + quality_issue
└── Tab: Revisión y Resolución      ← review_queue + duplicate_candidate + manual_resolution
```

### Ciclo operativo

```
Pipeline genera datos canónicos
    ↓
Dashboard muestra estado + pendientes
    ↓
Gestora resuelve/corrige desde el dashboard
    ↓
Decisiones se escriben a manual_resolution.csv
    ↓
Pipeline incorpora resoluciones en siguiente corrida
    ↓
Pendientes bajan, semáforo mejora
```

---

## 6. Edición directa en Streamlit

### Campos editables por contexto

| Contexto | Campos | Widget |
|----------|--------|--------|
| Stay/hospitalización | fecha_ingreso, fecha_egreso, servicio_origen, diagnóstico, motivo_egreso, establecimiento | st.form con date_input, text_input, selectbox |
| Paciente | nombre_completo, rut, sexo, fecha_nacimiento, comuna, cesfam | st.form con validación RUT duplicado |
| Establecimiento | código DEIS, nombre oficial | selectbox desde catálogo DEIS |

### Validaciones

- RUT: formato válido + no duplicado en patient_master
- Fechas: formato ISO + fecha_ingreso <= fecha_egreso
- Campos críticos (RUT, fecha_ingreso): confirmación explícita antes de guardar

### Flujo de guardado

1. Gestora edita campo en formulario
2. Validación en tiempo real
3. Si campo crítico: modal de confirmación
4. Se escribe fila en manual_resolution.csv con action=correct
5. Feedback visual: "Corrección guardada. Se aplicará en la próxima ejecución del pipeline."

---

## Fuera de alcance

- Autenticación de usuarios (single-user por ahora)
- Base de datos relacional (se mantiene CSV como almacenamiento)
- API REST (todo es local via Streamlit)
- Notificaciones por email/Slack
- Histórico de versiones de datos (se confía en git para eso)
