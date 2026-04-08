# Auditoría Categorial — Base de Datos HDOS

**Fecha**: 2026-04-08  
**Base**: `hodom-pg` (PostgreSQL 14, puerto 5555)  
**DDL de referencia**: `docs/models/hodom-integrado-pg-v4.sql` (4111 líneas)

---

## Resumen ejecutivo

| Dimensión | Estado |
|-----------|--------|
| Integridad referencial (FK) | **0 violaciones** en 237 FKs |
| Path equations (PE-1 patient_id) | **0 violaciones** en tablas pobladas |
| Tablas pobladas | **45 de 115** (39%) |
| Tablas vacías | **70 de 115** (61%) — schema aspiracional |
| Drift DDL↔PG | **5 tablas** en PG sin DDL (portal_*, audit_log) — usadas por hdos-app |
| FKs duplicadas | **1 anomalía** (encuesta_satisfaccion dual schema) |
| Enums sin CHECK | **~35 columnas** TEXT sin constraint |
| Triggers activos | Todos habilitados (O = origin-enabled) |

---

## 1. HALLAZGO CRÍTICO: 61% de la base es fantasma

**70 de 115 tablas tienen 0 filas.** Esto incluye tablas clínicamente importantes:

### Tablas vacías que deberían tener datos (riesgo funcional)

| Tabla | Impacto | Observación |
|-------|---------|-------------|
| `clinical.valoracion_ingreso` | **ALTO** | Sin valoración al ingreso. Toda estadía debería tener una. |
| `clinical.medicacion` | **ALTO** | Sin medicaciones registradas para 673 pacientes domiciliarios. |
| `clinical.procedimiento` | **ALTO** | Sin procedimientos clínicos registrados. |
| `clinical.observacion` | **ALTO** | Sin signos vitales ni observaciones clínicas. |
| `clinical.herida` | **MEDIO** | Sin seguimiento de heridas (programa incluye curaciones). |
| `clinical.evaluacion_funcional` | **MEDIO** | Sin Barthel/evaluaciones funcionales. |
| `clinical.consentimiento` | **MEDIO** | Sin consentimientos informados. |
| `clinical.documentacion` | **MEDIO** | Sin documentos clínicos (epicrisis tiene doc_id FK a esta tabla). |
| `operational.orden_servicio` | **ALTO** | Sin órdenes de servicio — visitas existen sin orden. |
| `operational.ruta` | **MEDIO** | Sin rutas registradas (telemetría_resumen tiene route_id FK). |
| `operational.conductor` | **BAJO** | Sin conductores (vehículos sí existen). |

### Tablas vacías que son correctamente futuras (sin riesgo)

`sesion_rehabilitacion`, `equipo_medico`, `prestamo_equipo`, `oxigenoterapia_domiciliaria`, `solicitud_examen`, `lista_espera`, `teleconsulta`, `informe_social`, `interconsulta`, `derivacion`, `capacitacion`, `reunion_equipo`, `canasta_valorizada`, `compra_servicio`, `sla`, `insumo`, etc.

**Dictamen**: El schema es aspiracional — modela un sistema clínico completo, pero solo ~40% está poblado. Las 70 tablas vacías representan **deuda de integración de datos**, no deuda técnica. Las fuentes de datos existentes (SGH, DAU, XLSX, PDFs) no proveen la información para poblar las tablas clínicas faltantes.

---

## 2. Redundancia categorial: patient_id en 38 tablas

**Deuda documentada. 0 violaciones. Trigger enforced.**

38 tablas tienen `patient_id` como columna. En las que también tienen `stay_id → estadia`, el `patient_id` es categorialmente redundante (diagonal de triángulo conmutativo):

```
       T.patient_id
    T ─────────────────→ paciente
    │                      ↑
    │ stay_id              │ estadia.patient_id
    ↓                      │
  estadia ─────────────────┘
```

Verificación exhaustiva: **0 violaciones** en todas las tablas pobladas (nota_evolucion, epicrisis, condicion, visita). El trigger `check_stay_coherence` activo en 6 tablas. El trigger PE-1 activo en 27 tablas.

**Dictamen**: La redundancia está correctamente gestionada. No propagar a tablas nuevas (decisión documentada en CLAUDE.md).

---

## 3. Drift DDL ↔ PG: 5 tablas sin DDL

| Tabla en PG | En DDL v4? | Origen probable |
|-------------|-----------|-----------------|
| `clinical.portal_mensaje` | NO | Sistema portal paciente (futuro) |
| `operational.portal_usuario` | NO | Sistema portal paciente (futuro) |
| `operational.portal_invitacion` | NO | Sistema portal paciente (futuro) |
| `operational.portal_acceso_log` | NO | Sistema portal paciente (futuro) |
| `operational.audit_log` | NO | Auditoría de accesos |

Todas vacías. Tienen FKs válidas. **Son usadas activamente por `/home/felix/projects/hdos-app`** (Next.js + Drizzle ORM) en 8 archivos TypeScript: portal-auth, mensajes-portal, invitaciones, auditoría.

**Dictamen**: Incorporar al DDL v4. **NO eliminar** — son infraestructura del portal paciente de hdos-app.

---

## 4. Anomalía: encuesta_satisfaccion en 2 schemas

```
clinical.encuesta_satisfaccion    → 0 filas, con FKs patient_id + stay_id
reporting.encuesta_satisfaccion   → 33 filas, con FKs patient_id + stay_id (4 duplicadas cada una!)
```

La tabla `reporting.encuesta_satisfaccion` tiene **4 FKs duplicadas** para `patient_id` y **4 FKs duplicadas** para `stay_id` (visible en la query FK — 8 filas para 2 columnas). Esto es un artefacto de ALTERs repetidos.

**Dictamen**: 
1. Los datos viven solo en `reporting`. La tabla `clinical` está vacía y es redundante.
2. Las FKs duplicadas son inofensivas pero ensucian el catálogo.
3. Decidir: ¿mover datos a `clinical` y eliminar `reporting.encuesta_satisfaccion`? ¿O eliminar `clinical.encuesta_satisfaccion`?

---

## 5. visita: triple referencia geográfica

`operational.visita` tiene **3 columnas de ubicación** + GPS:

| Columna | FK a | Poblada | Semántica |
|---------|------|---------|-----------|
| `location_id` | `territorial.ubicacion` | 0/7594 | Ubicación abstracta (legacy) |
| `localizacion_id` | `territorial.localizacion` | 7594/7594 | Localización geocodificada |
| `domicilio_id` | `clinical.domicilio` | 7594/7594 | Domicilio vigente del paciente |
| `gps_lat` / `gps_lng` | — | 176/7594 | Coordenadas GPS reales (NavPro) |

El grafo de dependencia geográfica es:

```
visita.domicilio_id → domicilio.localizacion_id → localizacion (lat, lng)
visita.localizacion_id → localizacion (lat, lng)  ← redundante con domicilio
visita.location_id → ubicacion (lat, lng)          ← legacy, nunca poblado
visita.gps_lat/lng                                 ← dato real del GPS
```

**Dictamen**:
- `location_id` (→ ubicacion) es **dead code**. Nunca poblado. `ubicacion` tiene 1659 filas pero ninguna visita la referencia.
- `localizacion_id` y `domicilio_id` son redundantes entre sí (domicilio → localizacion). `localizacion_id` es derivable: `domicilio.localizacion_id`.
- Solo `domicilio_id` y `gps_lat/lng` son necesarios.

---

## 6. Enums implícitos: ~35 columnas TEXT sin CHECK

Columnas TEXT que almacenan valores de un dominio finito pero carecen de CHECK constraint:

### Riesgo ALTO (datos poblados o probables)

| Tabla | Columna | Valores esperados |
|-------|---------|-------------------|
| `condicion` | `estado_clinico` | activo, resuelto, controlado |
| `condicion` | `verificacion` | verificado, pendiente |
| `dispositivo` | `estado` | activo, inactivo, averiado |
| `profesional` | `contrato` | contrato, honorario, estudiante |
| `profesional` | `competencias` | Debería ser TEXT[] (array) |
| `profesional` | `vehiculo` | Debería FK → vehiculo_id |
| `profesional` | `comunas_cobertura` | Debería ser TEXT[] o JSONB |

### Riesgo MEDIO (tablas futuras)

`observacion.categoria`, `alerta.categoria`, `alerta.codigo`, `herida.grado`, `herida.tipo_curacion`, `evaluacion_funcional.dependencia_motora`, `evaluacion_funcional.dependencia_respiratoria`, `evaluacion_funcional.df_score` (debería ser INTEGER), `sesion_rehabilitacion.estado_general`, `informe_social.composicion_familiar`, `resultado_examen.valor` (debería ser NUMERIC).

**Dictamen**: Para tablas pobladas, agregar CHECKs. Para tablas vacías, corregir antes de poblar.

---

## 7. Zona: modelo geográfico infrautilizado

| Tabla | Filas | Uso real |
|-------|-------|----------|
| `territorial.zona` | 1 | Solo "HODOM Hospital San Carlos" |
| `territorial.ubicacion` | 1659 | Comunas, pero sin FK desde visita |
| `territorial.localizacion` | 673 | Domicilios geocodificados — **el modelo real** |
| `territorial.matriz_distancia` | 0 | Nunca calculada |
| `territorial.establecimiento` | 86 | CESFAMs + hospitales |

El modelo territorial tiene **dos subsistemas paralelos**:
1. **zona → ubicacion → matriz_distancia**: diseñado para planificación de rutas (nunca usado)
2. **localizacion → domicilio → visita**: diseñado para geolocalización real (100% poblado)

**Dictamen**: El subsistema zona/ubicación/matriz_distancia es **dead architecture**. `ubicacion` tiene datos (1659 comunas) pero nada los consume. `zona` tiene 1 fila placeholder. `matriz_distancia` está vacía.

---

## 8. Triggers: máquina de estados sin combustible

Los triggers de máquina de estados (`guard_estadia_estado`, `guard_visita_estado`, `sync_visita_estado`, `sync_estadia_estado`) están todos activos, pero:

- `evento_visita`: 0 filas → la máquina de estados de visita **nunca se ha ejecutado**
- `evento_estadia`: 0 filas → la máquina de estados de estadía **nunca se ha ejecutado**
- Las visitas tienen `estado` directamente seteado (bypass via los scripts de migración que ejecutan `ALTER TABLE DISABLE TRIGGER`)
- Las estadías tienen `estado` directamente seteado

**Dictamen**: Los triggers de state machine son correctos categóricamente pero operacionalmente inertes. Si se activa un sistema de workflow real, funcionarán. Mientras tanto, son peso muerto.

---

## 9. strict schema: validación sombra

| Tabla | Filas | Relación |
|-------|-------|----------|
| `strict.hospitalizacion` | 834 | Superset de `clinical.estadia` (779) |
| `strict.paciente` | 673 | Mirror de `clinical.paciente` (673) |

55 hospitalizaciones en `strict` no tienen estadia en `clinical`. Probablemente registros que no pasaron la validación de migración.

**Dictamen**: `strict` actúa como staging area validada. La relación 834→779 es normal (hay rechazos). Pero debería documentarse la diferencia.

---

## 10. Provenance: cobertura parcial

| Phase | Filas |
|-------|-------|
| Total | 32,294 |

La provenance cubre las migraciones F0-F12 y correcciones CORR-01 a SYNC-GPS, pero no cubre las tablas de referencia (seed data) ni las tablas creadas por correcciones SQL directas.

**Dictamen**: La provenance es sólida para datos migrados. Para datos operacionales futuros (ingresados vía aplicación), se necesita un mecanismo de auditoría diferente (`audit_log` está creado pero vacío).

---

## 11. Resumen de dictámenes por severidad

### Acciones recomendadas

| # | Severidad | Hallazgo | Acción |
|---|-----------|----------|--------|
| 1 | **MEDIA** | 70 tablas vacías (61%) | Documentar cuáles son aspiracionales vs. pendientes de datos. No eliminar — son el modelo target. |
| 2 | **BAJA** | 5 tablas portal_*/audit_log sin DDL | Incorporar al DDL v4 o eliminar de PG. |
| 3 | **MEDIA** | encuesta_satisfaccion dual (clinical + reporting) | Eliminar `clinical.encuesta_satisfaccion` (vacía). Limpiar FKs duplicadas en reporting. |
| 4 | **BAJA** | visita.location_id dead FK | Eliminar columna (0/7594 poblado, nunca se usará). |
| 5 | **BAJA** | visita.localizacion_id redundante con domicilio_id | Documentar como derivable. No eliminar (query convenience). |
| 6 | **MEDIA** | ~35 TEXT sin CHECK | Agregar CHECKs a tablas pobladas (condicion, dispositivo, profesional). |
| 7 | **BAJA** | zona/ubicacion/matriz_distancia dead architecture | Documentar como futuro. No eliminar. |
| 8 | **INFO** | State machine triggers inertes | Funcionarán cuando se active workflow. No requiere acción. |
| 9 | **INFO** | strict.hospitalizacion superset (834 vs 779) | Documentar delta de 55 registros rechazados. |
| 10 | **BAJA** | profesional.vehiculo TEXT vs FK vehiculo_id | Corregir cuando se use operacionalmente. |

---

## 12. Remediaciones aplicadas (2026-04-08)

| # | Acción | Resultado |
|---|--------|-----------|
| R1 | ~~DROP `clinical.encuesta_satisfaccion`~~ | **REVERTIDO**: hdos-app INSERT/SELECT contra clinical.encuesta_satisfaccion. Recreada. |
| R2 | ~~DROP 5 tablas portal_*/audit_log~~ | **REVERTIDO**: usadas por hdos-app (Next.js + Drizzle ORM). Recreadas. |
| R3 | ~~DROP `visita.location_id`~~ | **REVERTIDO**: hdos-app queries JOIN con location_id. Restaurada. |
| R4 | ~~DROP `visita.localizacion_id`~~ | **REVERTIDO**: hdos-app rutas API JOIN con localizacion_id. Restaurada + repoblada (7594). |
| R5 | 4 CHECK en tablas pobladas | condicion.estado_clinico, condicion.verificacion, dispositivo.estado, profesional.contrato |
| R6 | COMMENT `profesional.vehiculo` | Documentado como legacy, FK futura |
| R7 | DROP `telemetria_segmento.location_id` | Eliminada (dead FK, usa start_lat/lng) |
| R8 | 7 CHECK en tablas futuras | alerta.categoria, herida.grado, evaluacion_funcional.dep_motora/resp, observacion.categoria, informe_social.red_familiar/comunitaria |
| R9 | Recrear v_consolidado_atenciones_diarias | Sin location_id |
| R10 | Recrear mv_kpi_diario | Sin location_id, usa zona universal |

**Post-remediación**: 115 tablas (igual al inicio), 11 CHECK constraints nuevos, `telemetria_segmento.location_id` eliminada (no usada por hdos-app).

**Nota**: R1-R4 fueron revertidos tras descubrir que `hdos-app` (Next.js + Drizzle ORM) consume directamente clinical.encuesta_satisfaccion, visita.location_id, y visita.localizacion_id. Las remediaciones que sobrevivieron son: R5 (4 CHECKs en tablas pobladas), R7 (segmento.location_id, no usado por hdos-app), y R8 (7 CHECKs en tablas futuras).

### Lo que está bien

- **0 violaciones FK** en 237 foreign keys
- **0 violaciones PE-1** (patient_id coherence) 
- **22 trigger functions** activas y correctas
- **208 índices** — cobertura completa
- **Provenance** tracking en 32,294 registros
- **Modelo domicilio-localización** 100% poblado y geocodificado
- **Telemetría GPS** operativa con 124K+ puntos y matching automático
- **Máquinas de estado** correctamente diseñadas (aunque inertes)
- **DDL v4** es un modelo clínico domiciliario completo y bien categorizado
