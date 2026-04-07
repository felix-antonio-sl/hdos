# Backlog MVP — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Estado: borrador v1
Método: MoSCoW por fase
Dependencia: `diseno-sistema-operativo-hodom-hsc.md`, `roles-permisos-hodom-hsc.md`

---

## Principio rector

El MVP debe reemplazar las planillas Excel y Google Forms que hoy sostienen la operación, sin perder ninguna capacidad operativa real que ya existe. No es un sistema ideal futuro: es el sistema que permite operar mañana mejor que hoy.

---

## Fase 1 — Core operativo (MVP)

Objetivo: sostener la operación diaria de 20-30 pacientes activos sin planillas.

### MUST HAVE

| ID | Capacidad | Módulo | Usuarios principales | Justificación |
|----|-----------|--------|---------------------|---------------|
| F1-01 | Registro de paciente (RUT, nombre, edad, sexo, dirección, comuna, CESFAM, previsión, contacto, cuidador) | M1 | Administrativo, Enfermera coordinadora | Base de identidad. Hoy está en Google Form |
| F1-02 | Registro de postulación con origen de derivación (APS, UEH, hospitalización, ambulatorio, ley urgencia, UGCC) | M1 | Administrativo, Médico derivador | Reemplaza formulario Google. Alimenta REM |
| F1-03 | Evaluación de elegibilidad: checklist clínico + social + domicilio | M1 | Médico HODOM, Enfermera, Trabajo social | Hoy es verbal + papel. Debe ser trazable |
| F1-04 | Aceptación/rechazo con causal explícita | M1 | Coordinación, Médico HODOM | Requerido por normativa |
| F1-05 | Apertura de episodio HODOM con estado, diagnóstico, fecha ingreso, equipo asignado | M1/M2 | Coordinación, Médico HODOM | Núcleo del sistema. Reemplaza fila en planilla de programación |
| F1-06 | Tablero de pacientes activos: nombre, diagnóstico, días estada, estado, próxima visita, alertas | M2/M3 | Coordinación, Enfermera clínica | Reemplaza planilla de programación mensual |
| F1-07 | Plan terapéutico básico: objetivos, requerimientos de cuidado, profesiones necesarias, frecuencia | M2 | Médico HODOM | Estructura la atención desde el ingreso |
| F1-08 | Registro de visita: fecha, hora, profesional, tipo de atención, nota clínica, signos vitales | M2 | Todos los profesionales clínicos | Reemplaza registros en papel por disciplina |
| F1-09 | Signos vitales estructurados: PA, FC, FR, T°, SAT%, HGT, EVA, Glasgow | M2 | Enfermería, TENS, Kinesiólogo | Alineado con planilla real de ciclo vital (15 columnas) |
| F1-10 | Agenda diaria por profesional: pacientes, hora, dirección, tipo de atención | M3 | Todos los profesionales, Coordinación | Reemplaza hoja de ruta diaria en Excel |
| F1-11 | Registro de llamadas: fecha, hora, duración, motivo, paciente, familiar, tipo (emitida/recibida), funcionario, observaciones | M4 | Enfermería, Administrativo, Coordinación | Reemplaza planilla de llamadas. Normativa exige trazabilidad |
| F1-12 | Egreso: tipo normalizado (alta clínica, fallecido esperado, fallecido no esperado, reingreso, renuncia voluntaria, alta disciplinaria), fecha, epicrisis básica | M2/M6 | Médico HODOM | 6 tipos normativos. Alimenta REM |
| F1-13 | Consentimiento informado: registro de firma (aceptado/rechazado), fecha, firmante | M6 | Enfermería, Administrativo | Requerido por DS 1/2022 |
| F1-14 | Generación automática de indicadores REM A21 C.1.1: ingresos, personas atendidas, días-persona, altas, fallecidos, reingresos, por rango etario, sexo y origen derivación | M7 | Estadístico, Coordinación | Elimina redigitación. Derivado del episodio |
| F1-15 | Generación automática de REM A21 C.1.2: visitas por profesión | M7 | Estadístico | Derivado de visitas registradas |
| F1-16 | Autenticación por rol con RBAC básico | Transversal | Todos | Segregación de acceso según matriz de permisos |

### SHOULD HAVE (Fase 1)

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F1-17 | Entrega de turno digital: resumen por paciente para handoff entre profesionales | M2 | Reemplaza docx diarios de entrega kine/enfermería |
| F1-18 | Registro de curaciones estructurado: ubicación, grado, tejido, apósitos, tamaño | M2 | Reemplaza registro papel. Alta frecuencia |
| F1-19 | Registro de kinesiología: evaluación motora/respiratoria, Barthel, dependencia, objetivos | M2 | Reemplaza hoja de ingreso kine en papel |
| F1-20 | Cupos REM A21 C.1.3: programados, utilizados, disponibles, adicionales, salud mental, adultos, pediatría | M7 | Completa tributación REM |
| F1-21 | Encuesta de satisfacción al egreso | M6 | Requerida por normativa. Hoy es Google Form |
| F1-22 | Búsqueda rápida de paciente por RUT o nombre | Transversal | Operación diaria básica |

### COULD HAVE (Fase 1)

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F1-23 | Vista móvil offline-first para registro de visita en terreno | M2/M3 | Mejora captura en zonas rurales sin señal |
| F1-24 | Mapa de pacientes activos por zona | M3 | Ayuda visual para planificación de rutas |
| F1-25 | Notificaciones a coordinación por eventos críticos | M4 | Alertas tempranas |

---

## Portal Paciente/Cuidador (fase inmediata, paralelo a Fase 1)

Acceso sin app nativa — navegador web en PC/móvil. Datos ya en BD existente (4 tablas + 3 vistas).

### MUST HAVE (portal P0)

| ID | Capacidad | Justificación |
|----|-----------|---------------|
| FP-01 | Acceso con invitación (token 48h un uso), login email + contraseña | Paciente entra sin app |
| FP-02 | Dashboard resumen: diagnóstico, próxima visita, teléfonos HODOM | Info esencial al instante |
| FP-03 | Ver indicaciones vigentes (medicamentos, O₂, curaciones) | Cumple PE-14, DS 1/2022 art. 22 |
| FP-04 | Documento emergencia descargable (PDF con datos + teléfonos) | Paciente lo lleva a urgencia |

### SHOULD HAVE (portal P1)

| ID | Capacidad | Justificación |
|----|-----------|---------------|
| FP-05 | Reportar síntoma / solicitud visita con flag urgencia | Canal directo paciente → equipo |
| FP-06 | Historial de visitas | Transparencia |

### COULD HAVE (portal P2)

| ID | Capacidad | Justificación |
|----|-----------|---------------|
| FP-07 | Mensajes del equipo (respuestas, recordatorios) | Comunicación bidireccional |

---

## Fase 2 — Cierre de continuidad

Objetivo: cerrar los flujos que conectan HODOM con el mundo exterior y optimizar logística.

### MUST HAVE

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F2-01 | Rutas dinámicas: agrupación por zona, secuenciación, asignación de móvil | M3 | Reemplaza planilla de rutas mensuales |
| F2-02 | Teleatención estructurada: registro de teleorientación, telemonitoreo, regulación con vínculo al episodio | M4 | Hoy no se registra formalmente. REM A30 lo exige |
| F2-03 | Contrarreferencia a APS: documento estructurado al egreso | M6 | Cierra flujo APS-HODOM-APS |
| F2-04 | Gestión de stock e insumos: entrada, salida, despacho por paciente, quiebres | M5 | Hoy es control manual |
| F2-05 | Gestión de medicación: prescripción, despacho, administración, cadena trazable | M2/M5 | Plan terapéutico depende de esto |
| F2-06 | Gestión de dispositivos y equipos: asignación, devolución, mantención | M5 | Normativa exige programa de mantención |
| F2-07 | Alertas clínicas configurables: deterioro, incumplimiento, invasivos vencidos, visita fallida recurrente | M2/M4 | Seguridad del paciente |
| F2-08 | Derivación entrante desde APS (programa postrados): formulario de informe médico resumido | M1 | Enlace HODOM-APS bidireccional |

### SHOULD HAVE (Fase 2)

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F2-09 | Replanificación dinámica de agenda por contingencia | M3 | Hoy se hace por WhatsApp |
| F2-10 | Registro de educaciones al paciente/cuidador con evidencia | M2 | Normativa y trazabilidad |
| F2-11 | Coordinación de laboratorio e imagenología: solicitud, resultado, vínculo a episodio | M5 | Apoyo diagnóstico en domicilio |

---

## Fase 3 — Optimización institucional

Objetivo: escalar calidad, interoperabilidad y analítica.

### MUST HAVE

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F3-01 | Analítica avanzada: tendencias, estacionalidad, perfil de pacientes, tiempos de estada | M7 | Gestión basada en evidencia |
| F3-02 | Auditoría de calidad: documentación incompleta, protocolos no cumplidos, incidentes | M7 | Normativa de calidad (Res. Exenta 875) |
| F3-03 | Firma electrónica simple en documentos clínicos | M6 | Validez legal de FCE |

### SHOULD HAVE (Fase 3)

| ID | Capacidad | Módulo | Justificación |
|----|-----------|--------|---------------|
| F3-04 | Interoperabilidad FHIR: exportación de episodios como EpisodeOfCare, visitas como Encounter | M2 | Preparación para HCE nacional |
| F3-05 | Predicción de carga y cupos por temporada | M7 | Planificación de campaña de invierno |
| F3-06 | Mensajería estructurada al cuidador (SMS/WhatsApp) | M4 | Recordatorios y educación |
| F3-07 | Dashboard ejecutivo para gestión hospitalaria | M7 | Visibilidad directiva |

---

## Métricas de éxito del MVP

| Métrica | Línea base actual | Meta MVP |
|---------|-------------------|----------|
| Tiempo de generación REM mensual | ~2-3 días manuales | < 1 hora (generación + revisión) |
| Registros clínicos en papel | ~80% | < 20% |
| Planillas Excel activas para operación | ~8-10 | 0 |
| Trazabilidad de llamadas | parcial | 100% |
| Visitas sin registro formal | estimado 10-15% | < 2% |
| Tiempo de admisión (postulación → episodio) | variable, sin medición | medido y < 12h |

---

## Dependencias técnicas del MVP

| Dependencia | Decisión pendiente |
|-------------|-------------------|
| Stack tecnológico | **Decidido:** Next.js web app con PWA. Portal paciente como ruta `/portal/*` |
| Base de datos | **Decidido:** BD existente `hodom-pg-v4` (puerto 5555). No se crea BD nueva. 103 tablas en 8 schemas |
| Hosting | **Decidido:** `hd.sanixai.com`. Cloud con HTTPS |
| Autenticación | Portal: email + password con invitación. App interna: RBAC contra `operational.profesional` |
| Dispositivos en terreno | Smartphones personales (PWA) |
| Repo app | `/home/felix/projects/hdos-app` (separado de migración) |

---

## Siguiente paso

1. Validar este backlog con el equipo clínico real (coordinadora, médico, enfermera).
2. Decidir dependencias técnicas.
3. Diseñar wireframes de las 5 pantallas principales: tablero, ficha, agenda, llamadas, REM.
4. Derivar modelo de datos funcional desde el backlog + modelo integrado existente.
