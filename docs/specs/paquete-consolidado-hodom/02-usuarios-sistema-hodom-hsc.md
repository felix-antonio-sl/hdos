# Usuarios del Sistema Operativo HODOM HSC — Identificación y Necesidades

Fecha: 2026-04-07
Autor: Allan Kelly
Fuentes: ERD Modelo Integrado (43 tablas), FHIR R4 References, OPM v2.5 (SD–SD1.6), Modelo Categorial v4.1, Manual REM 2026, documentación legacy HSC.

---

## Propósito

Identificar los usuarios reales de un sistema operativo para hospitalización domiciliaria del Hospital de San Carlos, derivados del corpus completo disponible, y caracterizar sus necesidades funcionales como base para el diseño de historias de usuario.

---

## Método

No se inventaron usuarios. Se extrajeron de la convergencia de:
- agentes declarados en el modelo OPM (SD–SD9)
- roles tipados en el modelo categorial (C_op, C_proc)
- entidades del ERD (4 capas)
- recursos FHIR R4 mapeados al dominio
- formularios reales HSC (Ingreso Enfermería, Ciclo Vital, Curaciones, Kinesiología, CI, Postulación)
- normativa (DS 1/2022, NT 2024, REM 2026)
- datos empíricos HSC 2023-2025

---

## 1. Mapa de usuarios

### 1.1 Usuarios clínicos directos

| # | Usuario | Rol OPM | Rol categorial | Procesos principales | Frecuencia de uso |
|---|---------|---------|----------------|---------------------|-------------------|
| U1 | **Médico de atención directa** | Attending Physician | Profesional (rol=medico) | Evaluar condición clínica, prescribir, monitorear evolución, decidir continuidad, egresar, epicrisis | Diaria (L-V) |
| U2 | **Enfermera clínica** | Clinical Nurse | Profesional (rol=enfermera) | Ingreso enfermería, registro diario, administración medicamentos, curaciones, ciclo vital, plan de cuidados, educación cuidador | Diaria (L-D, cuarto turno) |
| U3 | **Kinesiólogo** | Physiotherapist | Profesional (rol=kinesiologo) | Evaluación motora/respiratoria, rehabilitación, Barthel, registro kinesiología | Diaria (L-D) |
| U4 | **Fonoaudiólogo** | Speech Therapist | Profesional (rol=fonoaudiologo) | Evaluación deglutoria/habla, rehabilitación, registro | Según indicación (L-V) |
| U5 | **Trabajador social** | Social Worker | Profesional (rol=trabajador_social) | Pesquisa candidatos, evaluación domicilio, informe social, verificación red apoyo, enlace APS | Según demanda + ingreso |
| U6 | **Técnico en enfermería (TENS)** | — (implícito en SD1.4) | Profesional (rol=tecnico_enfermeria) | Apoyo procedimientos enfermería, toma de signos vitales, acompañamiento visitas | Diaria (L-D) |

### 1.2 Usuarios de coordinación y gestión operativa

| # | Usuario | Rol OPM | Rol categorial | Procesos principales |
|---|---------|---------|----------------|---------------------|
| U7 | **Gestora encargada / Coordinadora** | Case Manager / Coordination Professional | GestoraEncargada ↪ Profesional | Recibir postulaciones, asignar pacientes, programar visitas, coordinar rutas, briefing matinal, gestión de cupos |
| U8 | **Director/a técnico** | Technical Director | (agente SD3) | Supervisión clínica, cumplimiento normativo, autorización alta disciplinaria, aprobación protocolos, responsabilidad legal ante SEREMI |
| U9 | **Conductor / logística** | (implícito en SD1.4a) | — | Ejecutar rutas, reportar estado móvil, GPS, contingencias de transporte |

### 1.3 Usuarios de red y derivación

| # | Usuario | Rol categorial | Procesos principales |
|---|---------|----------------|---------------------|
| U10 | **Profesional APS (CESFAM)** | Profesional_APS ↪ Profesional | Derivar candidatos desde programa postrados, recibir contrarreferencia, continuidad post-egreso |
| U11 | **Médico derivador hospitalario** | (implícito en Derivation Origin) | Derivar pacientes desde servicio hospitalario (medicina, cirugía, urgencia), informe de derivación |
| U12 | **Gestión centralizada de camas** | (implícito en SD1.1) | Asignar cupo HODOM desde central, coordinar con gestora |

### 1.4 Usuarios de reporte y supervisión

| # | Usuario | Procesos principales |
|---|---------|---------------------|
| U13 | **Estadístico/a DEIS** | Generar REM A21 C.1, validar consistencia, tributar al Servicio de Salud |
| U14 | **Jefatura de servicio / Dirección hospital** | Revisar indicadores, ocupación, egresos, reingresos, productividad |
| U15 | **SEREMI / Autoridad sanitaria** | Auditoría normativa, carpeta de autorización, fiscalización |

### 1.5 Usuarios no profesionales

| # | Usuario | Procesos principales |
|---|---------|---------------------|
| U16 | **Paciente** | Recibir atención, firmar consentimiento, reportar síntomas, participar en plan terapéutico |
| U17 | **Cuidador / familiar responsable** | Firmar CI, recibir educación, monitorear signos de alarma, facilitar acceso al domicilio, comunicar emergencias |

---

## 2. Necesidades funcionales por usuario

### U1 — Médico de atención directa

**Contexto:** Opera L-V en horario diurno. Visita pacientes en domicilio. Toma decisiones clínicas de continuidad y egreso. Es el agente principal de prescripción y epicrisis.

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver panorama clínico completo del paciente antes de visita | Crítica | Consultas 1, 7, 8 del operador |
| Registrar evolución clínica en cada visita | Crítica | OPM SD1.5, formulario Resumen Clínico Domiciliario |
| Prescribir y ajustar tratamiento farmacológico | Crítica | OPM SD1.4, MedicationRequest FHIR |
| Decidir continuidad vs egreso (continuar-tratamiento / proceder-egreso) | Crítica | OPM SD1.5, Continuity Decision |
| Generar epicrisis al egreso | Crítica | OPM SD1.6, Consulta 11 del operador |
| Generar solicitud de hospitalización si deterioro | Alta | Consulta 5 del operador |
| Generar texto de interconsulta | Alta | Consulta 6 del operador |
| Ver antecedentes, hospitalizaciones previas, labs | Alta | Historia longitudinal |
| Registrar rechazo de ingreso a HODOM con fundamento | Alta | Consulta 10 del operador |
| Acceder a información fuera de punto de atención (comité, revisión) | Media | Consulta 7 del operador |

### U2 — Enfermera clínica

**Contexto:** Opera L-D en cuarto turno (08:00-19:00). Es el profesional con mayor frecuencia de visitas (4.688 visitas/2024). Captura la mayor cantidad de datos clínicos por visita.

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Registrar signos vitales completos (15 columnas de ciclo vital) | Crítica | Formulario Registro Visita Equipo HODOM |
| Registrar narrativa clínica diaria | Crítica | Formulario Registro Enfermería |
| Registrar medicamentos administrados (dosis, dilución, vía, nro dosis) | Crítica | Formulario Registro Enfermería |
| Registrar estado de dispositivos invasivos | Crítica | Formulario Registro Enfermería |
| Registrar plan de enfermería (intervenciones) | Crítica | Formulario Registro Enfermería |
| Registrar curaciones avanzadas (lugar, grado, exudación, tejido, apósitos) | Alta | Formulario Registro Curaciones |
| Completar ingreso de enfermería (checklist 7 ítems, examen físico 6 dominios, Barthel) | Alta | Hoja Ingreso Enfermería HODOM HSC |
| Obtener consentimiento informado firmado | Alta | OPM SD1.1, CI 2026 |
| Ver plan terapéutico vigente y últimas indicaciones médicas | Alta | OPM SD1.4 |
| Educación al cuidador con registro | Media | OPM SD1.4 (Caregiver Educating) |

### U3 — Kinesiólogo

**Contexto:** 3.195 visitas/2024. Evaluación motora y respiratoria. Barthel como indicador de resultado.

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Registrar evaluación de ingreso kinesiología (funcionalidad, Barthel, dependencia motora/respiratoria) | Crítica | Hoja Ingreso Kinesiología |
| Registrar evolución kinésica por visita | Crítica | — |
| Registrar signos vitales reducidos (PA, FR, FC, SpO2, LitrosO2) | Alta | Formulario CSV kinesiología |
| Ver historial de Barthel del episodio (ingreso vs actual) | Alta | PE-15 modelo categorial |
| Ver indicaciones médicas relevantes para rehabilitación | Media | — |

### U4 — Fonoaudiólogo

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Registrar evaluación deglutoria/habla | Crítica | OPM SD1.4 |
| Registrar evolución por visita | Alta | — |
| Ver diagnóstico médico y antecedentes neurológicos | Alta | — |

### U5 — Trabajador social

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Registrar evaluación sociosanitaria del domicilio | Crítica | OPM SD1.1, SD1.2 |
| Generar informe social preliminar y definitivo | Crítica | OPM SD1.2 |
| Verificar red de apoyo y cuidador disponible | Crítica | OPM SD1.1 |
| Registrar enlace con APS/CESFAM | Alta | Enlace HODOM-APS |
| Registrar llamadas de seguimiento | Media | Formulario Registro Llamadas |

### U6 — TENS

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Registrar signos vitales | Alta | Apoyo a enfermería |
| Ver indicaciones de enfermería para la visita | Alta | — |
| Registrar procedimientos realizados | Media | — |

### U7 — Gestora encargada / Coordinadora

**Contexto:** Es el nodo operativo central. Recibe postulaciones, asigna pacientes, programa visitas y rutas, coordina el briefing matinal. Hasta 25 pacientes asignados.

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver lista de pacientes activos con estado actual | Crítica | OPM SD1, censo |
| Recibir y gestionar postulaciones (formulario digital) | Crítica | OPM SD1.1, Postulacion |
| Programar visitas diarias por profesional y paciente | Crítica | OPM SD1.4a |
| Asignar y optimizar rutas de transporte | Crítica | OPM SD1.4a, Route Assignment |
| Coordinar briefing matinal con equipo | Alta | Inventario HSC |
| Gestionar cupos disponibles vs ocupados | Alta | REM A21 C.1.3 |
| Ver estado de derivaciones entrantes (hospital, APS, GCC) | Alta | OPM SD1.1 |
| Resolver contingencias de visitas sin ruta | Media | OPM SD1.4a |

### U8 — Director/a técnico

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver dashboard de indicadores operativos (ocupación, egresos, reingresos, estada promedio) | Crítica | REM, proyecto implementación |
| Supervisar cumplimiento normativo | Crítica | DS 1/2022, NT 2024 |
| Autorizar alta disciplinaria | Alta | OPM SD1.6 |
| Aprobar protocolos y manual de organización interna | Alta | DS 1/2022 art. 11 |
| Ver trazabilidad de atenciones por profesional | Media | — |

### U9 — Conductor / logística

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver ruta del día con direcciones y orden de visitas | Crítica | OPM SD1.4a |
| Reportar estado de ejecución de ruta | Alta | Route Execution Monitoring |
| Reportar contingencias (paciente no ubicado, camino cortado) | Alta | — |
| Registrar km recorridos y combustible | Media | — |

### U10 — Profesional APS

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Derivar candidato a HODOM con informe resumido | Alta | Enlace HODOM-APS |
| Recibir contrarreferencia al egreso | Alta | OPM SD1.7, epicrisis_a_aps |
| Consultar estado del paciente derivado | Media | — |

### U11 — Médico derivador hospitalario

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Solicitar evaluación para HODOM desde servicio | Alta | Derivation Origin |
| Adjuntar información clínica de derivación | Alta | — |
| Recibir confirmación de ingreso o rechazo | Media | — |

### U12 — Gestión centralizada de camas

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver cupos disponibles HODOM en tiempo real | Alta | REM A21 C.1.3 |
| Asignar cupo HODOM desde central | Alta | OPM SD1.1 |

### U13 — Estadístico/a DEIS

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Generar REM A21 sección C automáticamente desde datos operativos | Crítica | Manual REM 2026, functor F_REM |
| Validar consistencia interna (PE-8, PE-9, PE-10) | Crítica | Path equations modelo categorial |
| Exportar datos en formato tributación | Alta | — |

### U14 — Jefatura / Dirección hospital

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Ver indicadores consolidados: ocupación, estada, reingresos, productividad | Crítica | Proyecto implementación |
| Comparar con metas comprometidas (BIP) | Alta | — |

### U15 — SEREMI / Autoridad sanitaria

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Acceder a carpeta de autorización sanitaria | Alta | DS 1/2022 |
| Verificar cumplimiento de dotación mínima, protocolos, PAC | Alta | NT 2024 |

### U16 — Paciente

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Recibir información clara sobre su hospitalización | Alta | CI 2026, Ley 20.584 |
| Firmar consentimiento informado digitalmente o en papel | Alta | OPM SD1.1 |
| Comunicar síntomas o emergencias fuera de horario | Alta | PE-14, SAMU 131 |
| Recibir indicaciones post-alta legibles | Media | OPM SD1.7 |

### U17 — Cuidador / familiar responsable

| Necesidad | Prioridad | Fuente |
|-----------|-----------|--------|
| Firmar consentimiento informado | Alta | CI 2026 |
| Recibir educación sobre cuidados y signos de alarma | Alta | OPM SD1.4 |
| Reportar cambios de estado del paciente | Alta | — |
| Facilitar acceso al domicilio para visitas | Básica | PE-12 |

---

## 3. Agrupación funcional por módulo del sistema

Del análisis de usuarios y necesidades emerge una estructura natural de módulos:

| Módulo | Usuarios principales | Función |
|--------|---------------------|---------|
| **Censo / Lista de pacientes** | U7, U1, U2, U8 | Estado actual de todos los pacientes activos |
| **Ficha clínica domiciliaria** | U1, U2, U3, U4, U5, U6 | Registro longitudinal por episodio |
| **Postulación y evaluación de ingreso** | U7, U5, U10, U11, U12 | Flujo de derivación → elegibilidad → ingreso |
| **Programación de visitas y rutas** | U7, U9 | Asignación diaria, optimización, contingencias |
| **Registro clínico por visita** | U2, U3, U4, U5, U6 | Signos vitales, narrativa, procedimientos, formularios |
| **Prescripción y tratamiento** | U1 | Indicaciones, medicamentos, ajustes |
| **Egreso y continuidad** | U1, U7, U10 | Epicrisis, contrarreferencia, seguimiento post-alta |
| **Teleatención / regulación remota** | U1, U2 | Atención a distancia según regulación |
| **Reportería e indicadores** | U8, U13, U14 | REM A21, KPIs, productividad |
| **Gestión de recursos** | U7, U9 | Vehículos, equipamiento, insumos |
| **Portal paciente/cuidador** | U16, U17 | Información, consentimiento, comunicación |

---

## 4. Observaciones de diseño

### 4.1 Brechas detectadas entre formularios reales y modelos formales

Del contraste entre el modelo OPM y el modelo categorial surge una brecha importante:
- El modelo OPM modela 4 de las 12 variables de signos vitales que realmente se capturan en el formulario de ciclo vital.
- El esquema operacional no captura ninguna variable de signos vitales directamente.
- Esto significa que el sistema debe diseñarse para capturar las **15 columnas reales** del formulario de ciclo vital, no las 4 del modelo OPM.

### 4.2 Usuarios con doble rol

- La **gestora encargada** es simultáneamente coordinadora operativa y enfermera clínica.
- El **director técnico** puede ser médico AD y supervisar al mismo tiempo.
- El sistema debe soportar **roles múltiples por persona** sin confundir las interfaces.

### 4.3 Restricciones de escritura por campo

- DAU y SGH tienen campos de texto de máximo 800 caracteres.
- El borrado requiere reemplazo por "." y recarga, con riesgo de duplicación.
- El sistema debe implementar **escritura segura con preview/confirm** y control de estado.

### 4.4 Cobertura temporal asimétrica

- Visitas: L-D 08:00-19:00 (enfermería, kinesiología)
- Médico: L-V horario diurno
- Línea de consulta: L-V 08:00-17:00 (L-J) / 08:00-16:00 (V)
- Emergencia fuera de horario: SAPU/UEH/SAMU 131
- El sistema debe reflejar **qué profesionales están disponibles en qué momento**.

### 4.5 Estadía promedio vs máxima declarada

- CI 2026 declara máximo 6-8 días.
- Dato empírico 2023: promedio 13.1 días.
- El sistema debe **registrar y alertar** cuando un episodio supera la estadía máxima declarada.

---

## 5. Siguiente paso

Con los usuarios y necesidades identificados, el siguiente entregable natural es:

### **Historias de usuario núcleo por módulo**

Para cada módulo, derivar:
- 3-5 historias de usuario prioritarias
- criterio de aceptación
- mapeo a recurso FHIR
- restricciones normativas aplicables

Esto convertiría la identificación de usuarios en un **backlog accionable** para el diseño del sistema operativo HODOM HSC.
