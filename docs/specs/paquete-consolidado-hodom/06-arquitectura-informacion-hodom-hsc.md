# Arquitectura de Información — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Autor: Allan Kelly
Prerrequisitos:
- `output/2026-04-07-usuarios-sistema-hodom-hsc.md` (17 usuarios)
- `output/2026-04-07-historias-usuario-hodom-hsc.md` (31 historias de usuario)
Fuentes: ERD Modelo Integrado (43 tablas, 4 capas), FHIR R4, OPM v2.5, Modelo Categorial v4.1, DS 1/2022, NT 2024, REM 2026.

---

## 1. Modelo de datos por módulo

El ERD ya existente organiza 43 tablas en 4 capas autónomas. Esta arquitectura mapea cada módulo funcional a las entidades del ERD que lo soportan.

### Módulo 1 — Censo / Lista de pacientes

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `paciente` | Identidad del paciente |
| `estadia` | Episodio activo (estado=activo) |
| `condicion` | Diagnóstico principal |
| `profesional` | Profesional responsable |
| `ubicacion` | Localidad del domicilio |
| `zona` | Zona operacional |
| `alerta` | Alertas activas |
| `rem_cupos` | Cupos programados/utilizados/disponibles |

**Vista principal:** JOIN paciente→estadia→condicion + LEFT JOIN alerta + LEFT JOIN ubicacion→zona
**Filtros:** estado=activo, profesional asignado, zona, categoría paciente

---

### Módulo 2 — Postulación y evaluación de ingreso

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `paciente` | Candidato |
| `cuidador` | Cuidador/familiar evaluado |
| `estadia` | Episodio creado al formalizar ingreso |
| `evento_estadia` | Lifecycle: pendiente_evaluacion→elegible→admitido |
| `documentacion` | CI, carta derechos, informe social, formulario ingreso |
| `condicion` | Diagnóstico de derivación |
| `establecimiento` | Servicio derivador |

**Flujo de estados (evento_estadia):**
```
pendiente_evaluacion → elegible → admitido → activo
                    ↘ no_elegible (terminal)
```

**Wide pullback de elegibilidad (8 condiciones simultáneas):**
1. Condición clínica estable ✓
2. Cuidador disponible ✓
3. Domicilio adecuado ✓
4. Consentimiento firmado ✓
5. Sin condición de exclusión ✓
6. Previsión Fonasa/PRAIS ✓
7. Radio ≤ 20km ✓
8. Edad ≥ 18 ✓

---

### Módulo 3 — Ficha clínica domiciliaria

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `estadia` | Episodio contenedor |
| `visita` | Unidad de registro (una fila por visita) |
| `observacion` | Signos vitales (12 códigos ENUM) |
| `procedimiento` | Procedimientos ejecutados |
| `medicacion` | Medicamentos prescritos/administrados |
| `dispositivo` | Dispositivos invasivos |
| `documentacion` | 26 tipos documentales |
| `plan_cuidado` | Plan terapéutico + plan enfermería |
| `meta` | Objetivos del paciente |

**Composición longitudinal:**
```
historia_clinica(estadia) = ⋃{genera_registro(v) | v ∈ visitas de la estadia}
```

**12 variables de observación (ciclo vital completo):**

| Código ENUM | Variable | Dimensión clínica | FHIR |
|-------------|----------|-------------------|------|
| PA | Presión arterial | Hemodinámica | Observation (blood-pressure) |
| FC | Frecuencia cardíaca | Hemodinámica | Observation (heart-rate) |
| FR | Frecuencia respiratoria | Respiratoria | Observation (respiratory-rate) |
| SPO2 | Saturación O₂ | Respiratoria | Observation (oxygen-saturation) |
| TEMP | Temperatura | Térmica | Observation (body-temperature) |
| HGT | Hemoglucotest | Metabólica | Observation (blood-glucose) |
| EVA | Escala visual analógica | Dolor | Observation (pain-severity) |
| GLASGOW | Escala Glasgow | Neurológica | Observation (glasgow-coma-scale) |
| EDEMA | Estado edema | Hídrica | Observation |
| DIURESIS | Volumen diuresis | Renal | Observation |
| DEPOSICIONES | Estado deposiciones | Gastrointestinal | Observation |
| INVASIVOS | Estado dispositivos | Dispositivos | Observation (device-status) |

---

### Módulo 4 — Prescripción y tratamiento

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `medicacion` | Cadena: prescrita→dispensada→administrada |
| `plan_cuidado` | Plan terapéutico vigente |
| `requerimiento_cuidado` | 13 tipos de requerimiento |
| `orden_servicio` | Órdenes generadas del plan |

**Cadena de medicación:**
```
prescrita → dispensada → administrada
```
**Vías:** oral, IV, SC, IM, tópica

---

### Módulo 5 — Programación de visitas y rutas

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `orden_servicio` | Orden recurrente (1 orden → N visitas) |
| `visita` | Instancia programada (13 estados) |
| `ruta` | Ruta diaria por profesional |
| `profesional` | Recurso despachable |
| `agenda_profesional` | Disponibilidad por día |
| `zona` | Zonificación territorial |
| `ubicacion` | Localidad del paciente |
| `matriz_distancia` | Distancias precalculadas entre zonas |
| `decision_despacho` | Scoring multi-factor de asignación |
| `evento_visita` | Log de transiciones con GPS |
| `sla` | Metas de nivel de servicio |

**13 estados de visita:**
```
PROGRAMADA → ASIGNADA → EN_RUTA → EN_DOMICILIO → EN_ATENCION 
→ ATENCION_COMPLETADA → DOCUMENTADA → REPORTADA_REM
                    ↘ CANCELADA / NO_REALIZADA / REPROGRAMADA
```

**Scoring de asignación (decision_despacho):**
- skill match
- distancia
- continuidad profesional
- carga actual

**Zonificación (4 tipos):**

| Tipo | Capacidad visitas/día |
|------|----------------------|
| URBANO | 6-8 |
| PERIURBANO | 4-6 |
| RURAL | 2-4 |
| RURAL_AISLADO | 1-2 |

---

### Módulo 6 — Egreso y continuidad

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `estadia` | tipo_egreso (ENUM 6), fecha_egreso |
| `evento_estadia` | Transición activo→egresado |
| `documentacion` | Epicrisis, protocolo fallecimiento, declaración retiro |
| `encuesta_satisfaccion` | Post-egreso (45 columnas) |
| `registro_llamada` | Seguimiento telefónico 48h |

**Coproducto de egreso (6 variantes):**

| Variante | Documentos generados | Agente |
|----------|---------------------|--------|
| Alta médica | Epicrisis | Médico AD |
| Reingreso hospitalario | Epicrisis + solicitud traslado | Médico AD |
| Fallecido esperado | Epicrisis + protocolo fallecimiento | Médico AD |
| Fallecido no esperado | Epicrisis + protocolo fallecimiento | Médico AD |
| Renuncia voluntaria | Epicrisis + declaración retiro | — |
| Alta disciplinaria | Epicrisis | Director técnico |

---

### Módulo 7 — Teleatención

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `visita` | Con tipo=teleatención |
| `registro_llamada` | Log estructurado |
| `documentacion` | Registro telesalud |

---

### Módulo 8 — Reportería e indicadores

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `rem_personas_atendidas` | REM A21 C.1.1 (7 componentes × 14 dimensiones) |
| `rem_visitas` | REM A21 C.1.2 (visitas por profesión REM) |
| `rem_cupos` | REM A21 C.1.3 (cupos programados/utilizados/disponibles) |
| `kpi_diario` | 9 KPIs operacionales por zona |
| `descomposicion_temporal` | 8 segmentos temporales por visita |
| `reporte_cobertura` | Cobertura por paciente y orden |
| `maquina_estados_ref` | 15 transiciones válidas (referencia) |

**Functor F_REM (C_op → C_rem):**
```
personas_atendidas(mes) = activas(mes-1) + ingresos(mes) - egresos(mes) - fallecidos(mes)
```

**9 KPIs operacionales diarios:**

| KPI | Meta |
|-----|------|
| Tasa cumplimiento visitas | ≥ 90% |
| Tasa puntualidad | ≥ 85% |
| Continuidad profesional | — |
| Tasa EVV (encuesta vivencial) | ≥ 98% |
| Ratio viaje/atención | < 0.3 bueno, > 0.5 ineficiente |

---

### Módulo 9 — Gestión de recursos

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `dispositivo` | 9 tipos de dispositivo |
| `insumo` | 5 categorías (curación, medicamento, equipo, O₂, descartable) |
| `orden_servicio_insumo` | Junction M:N orden↔insumo |

---

### Módulo 10 — Interconsultas y solicitudes

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `orden_servicio` | Orden de tipo interconsulta/hospitalización |
| `documentacion` | Documento generado |

---

### Módulo 11 — Portal paciente/cuidador

| Entidad ERD | Rol en el módulo |
|-------------|-----------------|
| `paciente` | Datos del paciente |
| `cuidador` | Datos del cuidador |
| `documentacion` | Documento de indicaciones para emergencia |

---

## 2. Mapeo FHIR detallado

### Entidades ERD → Recursos FHIR R4

| Entidad ERD | Recurso FHIR R4 | Notas |
|-------------|-----------------|-------|
| `paciente` | Patient | identifier=RUT |
| `estadia` | Encounter (class=HH) + EpisodeOfCare | class=HH para home health |
| `condicion` | Condition | code=CIE-10 |
| `cuidador` | RelatedPerson | relationship coded |
| `plan_cuidado` | CarePlan | status=draft/active/completed |
| `requerimiento_cuidado` | ServiceRequest | category=13 tipos |
| `necesidad_profesional` | PractitionerRole | — |
| `meta` | Goal | lifecycleStatus |
| `procedimiento` | Procedure | code→catalogo_prestacion |
| `observacion` | Observation | 12 códigos vital-signs |
| `medicacion` | MedicationRequest + MedicationAdministration | cadena prescrita→administrada |
| `dispositivo` | Device | 9 tipos |
| `documentacion` | DocumentReference + Composition | 26 tipos |
| `alerta` | Flag | category coded |
| `encuesta_satisfaccion` | QuestionnaireResponse | — |
| `profesional` | Practitioner + PractitionerRole | doble enum profesión |
| `agenda_profesional` | Schedule + Slot | — |
| `orden_servicio` | ServiceRequest | intent=order |
| `visita` | Encounter (partOf=estadia) | 13 estados |
| `ruta` | — | No hay equivalente FHIR directo |
| `registro_llamada` | Communication | category=notification |
| `establecimiento` | Organization | identifier=código DEIS |
| `zona` | Location | — |
| `ubicacion` | Location | position (lat/lon) |
| `catalogo_prestacion` | ActivityDefinition | code=MAI |
| `rem_*` | MeasureReport | — |

---

## 3. Flujos de estado

### 3.1 Lifecycle del episodio (evento_estadia)

```
pendiente_evaluacion
    │
    ├─[evaluar elegibilidad]──→ elegible
    │                              │
    │                              ├─[ingresar]──→ admitido ──→ activo
    │                              │                              │
    │                              │                    ┌─────────┤
    │                              │                    │  [monitorear + ejecutar plan]
    │                              │                    │  (ciclo iterativo)
    │                              │                    └─────────┤
    │                              │                              │
    │                              │                    ├─[egresar: alta médica]──→ egresado
    │                              │                    ├─[egresar: reingreso]──→ egresado
    │                              │                    ├─[egresar: fallecido]──→ fallecido
    │                              │                    ├─[egresar: renuncia]──→ egresado
    │                              │                    └─[egresar: disciplinaria]──→ egresado
    │                              │
    │                              └─[rechazar]──→ no_elegible (terminal)
    │
    └─[exclusión presente]──→ no_elegible (terminal)
```

### 3.2 Lifecycle de la visita (evento_visita, 13 estados)

```
PROGRAMADA → ASIGNADA → EN_RUTA → EN_DOMICILIO → EN_ATENCION
    │            │                                     │
    │            └─[reasignar]──→ ASIGNADA              │
    │                                                   │
    ├─[cancelar]──→ CANCELADA                           │
    ├─[no realizada]──→ NO_REALIZADA                    │
    ├─[reprogramar]──→ REPROGRAMADA                     │
    │                                                   │
    │                              ATENCION_COMPLETADA ←┘
    │                                     │
    │                              DOCUMENTADA
    │                                     │
    │                              REPORTADA_REM (terminal)
```

### 3.3 Lifecycle del plan de cuidado

```
borrador → activo → completado
```
Se cierra automáticamente al egresar (OPM SD1.6).

### 3.4 Lifecycle de medicación

```
prescrita → dispensada → administrada
```

---

## 4. Permisos por rol

### Matriz de acceso por módulo

| Módulo | Médico AD | Enfermera | Kine | Fono | TS | TENS | Coordinadora | DT | Conductor | APS | Estadístico |
|--------|-----------|-----------|------|------|----|------|-------------|----|-----------|----|-------------|
| 1. Censo | R | R | R | R | R | R | RW | R | R | — | R |
| 2. Postulación | RW | RW | — | — | RW | — | RW | R | — | W | — |
| 3. Ficha clínica | RW | RW | RW | RW | RW | RW | R | R | — | R | — |
| 4. Prescripción | RW | R | R | R | — | R | R | R | — | — | — |
| 5. Visitas/Rutas | R | R | R | R | R | R | RW | R | RW | — | — |
| 6. Egreso | RW | RW | — | — | — | — | RW | RW* | — | R | — |
| 7. Teleatención | RW | RW | — | — | — | — | R | R | — | — | — |
| 8. Reportería | R | — | — | — | — | — | R | R | — | — | RW |
| 9. Recursos | — | R | — | — | — | — | RW | R | R | — | — |
| 10. Interconsultas | RW | R | — | — | — | — | R | R | — | — | — |
| 11. Portal paciente | — | W | — | — | — | — | W | — | — | — | — |

**R** = lectura, **W** = escritura, **RW** = lectura + escritura
**RW*** = DT solo autoriza alta disciplinaria

### Reglas de acceso especiales

1. **Escritura clínica:** solo el profesional que realiza la visita puede crear el registro asociado
2. **Prescripción:** solo médico AD puede prescribir; enfermería y kine solo leen
3. **Alta disciplinaria:** requiere autorización explícita del DT (DS 1/2022 art. 16f)
4. **REM:** solo estadístico puede exportar/tributar; los demás solo leen indicadores
5. **Consentimiento:** enfermera registra la firma; médico y coordinadora pueden ver
6. **Paciente/cuidador:** acceso solo a su propia información y documentos entregados

---

## 5. Integraciones externas

### 5.1 REM → DEIS/MINSAL

| Integración | Dirección | Frecuencia | Mecanismo |
|-------------|-----------|------------|-----------|
| REM A21 sección C | Sistema → DEIS | Mensual | Export formato tributación |
| Personas atendidas (C.1.1) | Sistema → DEIS | Mensual | Derivado automático |
| Visitas por profesión (C.1.2) | Sistema → DEIS | Mensual | Derivado automático |
| Cupos (C.1.3) | Sistema → DEIS | Mensual | Semi-automático (cupos programados = input manual) |

### 5.2 APS / CESFAM

| Integración | Dirección | Frecuencia | Mecanismo |
|-------------|-----------|------------|-----------|
| Derivación APS → HODOM | APS → Sistema | Por evento | Formulario de derivación |
| Contrarreferencia al egreso | Sistema → APS | Por evento | Epicrisis + informe |
| Seguimiento post-egreso | Sistema → APS | 48h post-egreso | Notificación |

### 5.3 Gestión centralizada de camas

| Integración | Dirección | Frecuencia | Mecanismo |
|-------------|-----------|------------|-----------|
| Consulta cupos disponibles | GCC → Sistema | Por demanda | API / vista en tiempo real |
| Asignación cupo HODOM | GCC → Sistema | Por evento | Solicitud de ingreso |

### 5.4 Sistemas clínicos hospitalarios (DAU/SGH)

| Integración | Dirección | Frecuencia | Mecanismo |
|-------------|-----------|------------|-----------|
| Datos del paciente al derivar | DAU/SGH → Sistema | Por evento | Importación/consulta |
| Solicitud de reingreso | Sistema → SGH | Por evento | Documento + notificación |
| Interconsulta a especialista | Sistema → SGH | Por evento | Documento |

### 5.5 Laboratorio

| Integración | Dirección | Frecuencia | Mecanismo |
|-------------|-----------|------------|-----------|
| Resultados de laboratorio | Lab → Sistema | Por evento | Importación |
| Solicitud de exámenes | Sistema → Lab | Por evento | Orden |

---

## 6. Triggers y auditoría (del ERD)

El modelo incluye 6 triggers ya diseñados:

| Trigger | Entidad | Función |
|---------|---------|---------|
| T1 | `visita` | Valida transiciones de estado contra `maquina_estados_ref` |
| T2 | `orden_servicio` | Valida coherencia con plan de cuidado |
| T3 | `encuesta_satisfaccion` | Vincula automáticamente a estadia al egreso |
| T4 | `evento_visita` | Registra automáticamente timestamp y GPS |
| T5 | `profesional` | Valida competencias contra `necesidad_profesional` |

**Tablas de auditoría:**
- `evento_estadia` — lifecycle OPM SD1 materializado (6 estados, 7 procesos)
- `evento_visita` — log inmutable de transiciones con timestamp y GPS
- `estadia_episodio_fuente` — trazabilidad de episodios fuente
- `maquina_estados_ref` — 15 transiciones válidas (solo lectura)

---

## 7. Consistencia del modelo

### Path equations implementables como constraints

| PE | Constraint | Implementación |
|----|-----------|----------------|
| PE-1 | Domicilio del episodio = domicilio del paciente | CHECK en estadia |
| PE-2 | fecha_egreso ≥ fecha_ingreso | CHECK en estadia |
| PE-4 | Fecha visita dentro del rango del episodio | CHECK en visita |
| PE-5 | Radio ≤ 20km | CHECK en ubicacion→zona→matriz_distancia |
| PE-7 | Previsión Fonasa/PRAIS | CHECK en paciente.prevision |
| PE-8 | personas_atendidas = mes_anterior + ingresos - egresos - fallecidos | Validación en rem_personas_atendidas |
| PE-10 | cupos_utilizados ≤ cupos_programados | CHECK en rem_cupos |
| PE-11 | Estado egresado → ficha cerrada | Trigger en evento_estadia |
| PE-12 | Hora visita ∈ [08:00, 19:00] | CHECK en visita |
| PE-13 | Alerta si días_estada > 8 | Trigger en estadia |
| PE-15 | Barthel ingreso y egreso registrados | NOT NULL en observacion |
| PE-16 | Postulación precede episodio | CHECK fecha postulación ≤ fecha ingreso |

---

## 8. Resumen de la arquitectura

### Dimensiones del sistema

| Dimensión | Valor |
|-----------|-------|
| Tablas del modelo | 43 |
| Capas | 4 (territorial, clínica, operacional, reporte) |
| Triggers | 6 |
| Índices | 87 |
| Path equations | 12 implementables como constraints |
| Usuarios del sistema | 17 |
| Módulos funcionales | 11 |
| Historias de usuario | 31 (15 P0, 12 P1, 4 P2) |
| Recursos FHIR mapeados | 25 |
| Integraciones externas | 5 sistemas |
| Variables de ciclo vital | 12 (formulario real HSC) |
| Tipos de egreso | 6 (coproducto OPM SD1.6) |
| Estados de visita | 13 |
| Estados de episodio | 6 |
| Tipos documentales | 26 |
| Tipos de dispositivo | 9 |
| Categorías de insumo | 5 |
| Prestaciones MAI (canasta) | 23 |

---

## 9. Siguiente paso

Con usuarios, historias de usuario y arquitectura de información definidos, el sistema tiene suficiente especificación para entrar a **diseño de interfaz y prototipado por módulo**.

La secuencia recomendada sería:

### Fase 1 — Prototipo funcional mínimo
Implementar los 15 P0 sobre el modelo de datos existente (43 tablas):
1. Censo de pacientes activos
2. Flujo completo de postulación → evaluación → ingreso
3. Ficha clínica (ingreso enfermería + signos vitales + narrativa)
4. Prescripción
5. Programación de visitas
6. Egreso + epicrisis
7. Generación automática REM

### Fase 2 — Operación completa
Agregar las 12 P1 para operación diaria real.

### Fase 3 — Complementos
Las 4 P2 restantes.

El prototipo funcional existente (`hdos`) ya tiene una base de demo. La decisión de diseño es si se evoluciona ese prototipo o se reconstruye sobre el ERD integrado.
