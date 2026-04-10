# Backlog de Producto — Sistema Operativo HODOM HSC
## Hospital de San Carlos Dr. Benicio Arzola Medina
### Basado en 147 historias de usuario + criterios de aceptación

---

## 1. Propósito

Este backlog traduce las historias y criterios de aceptación de HODOM HSC a un formato utilizable para:

- diseño de producto
- priorización de desarrollo
- licitación tecnológica
- roadmap de implementación
- ordenamiento del rediseño operativo de la unidad

No describe solo software. Describe el **sistema operativo de la unidad HODOM**, integrando clínica, coordinación, logística, cumplimiento normativo y continuidad con la red.

---

## 2. Convenciones del backlog

### Prioridad
- **Must** = imprescindible para operar con seguridad/cumplimiento/MVP
- **Should** = altamente importante, pero puede entrar después del núcleo
- **Could** = mejora valiosa, no bloqueante para partida

### Fase
- **F0** = preparatorio / diseño / normalización documental
- **F1** = MVP operativo seguro
- **F2** = consolidación clínica-operativa
- **F3** = inteligencia de gestión, interoperabilidad y escalamiento

### Tipo
- **Proceso** = requiere rediseño organizacional o normativo
- **Sistema** = requiere funcionalidad digital
- **Mixto** = necesita ambos

---

## 3. Módulos del producto

| Módulo | Nombre | Objetivo |
|--------|--------|----------|
| M1 | Gobernanza y cumplimiento | sostener DT, RRHH, documentos, auditoría, normativa |
| M2 | Admisión y elegibilidad | gestionar postulación, ingreso, exclusión y priorización |
| M3 | Episodio clínico HODOM | llevar ficha, visitas, planes, registros y evolución |
| M4 | Interdisciplina clínica | enfermería, medicina, kinesiología, fono, TS, TENS |
| M5 | Logística y operaciones | rutas, flota, insumos, farmacia, exámenes, REAS |
| M6 | Seguridad y escalamiento | IAAS, invasivos, alarmas, reingresos, agresiones |
| M7 | Egreso y continuidad con la red | epicrisis, contrarreferencia, cierre de episodio |
| M8 | Calidad, indicadores y tablero | monitoreo de desempeño, riesgos y satisfacción |
| M9 | Soporte documental del paciente | consentimiento, resumen domiciliario, instrucciones |

---

## 4. Roadmap resumido

### F0 — Preparación
- depuración documental
- estandarización de formularios
- definición de cartera real
- definición de reglas del episodio
- definición de campos obligatorios
- matriz normativa y documental

### F1 — MVP operativo seguro
- postulación
- ingreso
- ficha clínica única
- evolución básica
- visitas
- rutas
- consentimientos
- resumen domiciliario
- epicrisis
- alertas críticas

### F2 — Consolidación
- gestión integral de interdisciplina
- curaciones
- invasivos
- exámenes/imágenes
- REAS
- auditoría
- tablero mensual
- contrarreferencia APS

### F3 — Escalamiento
- interoperabilidad con sistemas hospitalarios
- analítica avanzada
- productividad por profesional
- trazabilidad completa de eventos y calidad
- gobierno de datos robusto

---

# 5. Backlog priorizado

## EPIC 1 — GOBERNANZA, DIRECCIÓN TÉCNICA Y CUMPLIMIENTO

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-001 | Registro formal de Dirección Técnica | Mantener ficha del DT titular, subrogante, vigencia y respaldo documental | Must | F0 | Mixto | M1 | ninguna |
| BG-002 | Registro de requisitos habilitantes | Guardar título, experiencia, formación en gestión, IAAS y vigencias | Must | F0 | Mixto | M1 | BG-001 |
| BG-003 | Gestión de subrogancia | Registrar reemplazos temporales del DT y continuidad del cargo | Must | F0 | Mixto | M1 | BG-001 |
| BG-004 | Matriz documental maestra | Inventario de protocolos, manuales y formularios vigentes con versión y fecha | Must | F0 | Mixto | M1 | ninguna |
| BG-005 | Carpeta de fiscalización SEREMI | Repositorio estructurado de evidencia regulatoria exigible | Must | F0 | Mixto | M1 | BG-004 |
| BG-006 | Manual de organización interna vigente | Organigrama, roles, líneas de dependencia, horarios y turnos | Must | F0 | Proceso | M1 | BG-004 |
| BG-007 | Agenda de revisión documental | Calendario de actualización de protocolos y formularios | Should | F1 | Sistema | M1 | BG-004 |
| BG-008 | Auditoría de cumplimiento normativo | Pauta auditable de revisión documental y operativa | Must | F2 | Mixto | M1 | BG-004, BG-005 |
| BG-009 | Gestión de observaciones y brechas | Registro de hallazgos, responsables y fechas de cierre | Should | F2 | Sistema | M1 | BG-008 |

---

## EPIC 2 — RRHH, HABILITACIÓN E INDUCCIÓN

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-010 | Nómina única del personal HODOM | Base única de funcionarios, cargo, jornada y estado | Must | F0 | Mixto | M1 | ninguna |
| BG-011 | Carpeta de habilitación por funcionario | Título, registro, experiencia, IAAS, RCP, desfibrilador | Must | F0 | Mixto | M1 | BG-010 |
| BG-012 | Control de vigencia de certificaciones | Alertas por vencimiento de IAAS, RCP y otros | Must | F1 | Sistema | M1 | BG-011 |
| BG-013 | Regla de no salida a terreno sin habilitación | Bloqueo o alerta si falta requisito crítico | Must | F1 | Mixto | M1 | BG-011, BG-012 |
| BG-014 | Programa de inducción 44 horas | Estructura formal de ingreso para personal nuevo | Must | F0 | Proceso | M1 | BG-010 |
| BG-015 | Registro de inducción por funcionario | Evidencia firmada y trazable de inducción completada | Must | F1 | Sistema | M1 | BG-014 |
| BG-016 | Plan anual de capacitación (PAC) | Programación formativa anual con recertificaciones | Should | F1 | Mixto | M1 | BG-010 |
| BG-017 | Simulaciones periódicas | Emergencia clínica, agresión, rescate, fallas logísticas | Should | F2 | Mixto | M1 | BG-016 |

---

## EPIC 3 — CARTERA, ELEGIBILIDAD Y ADMISIÓN

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-018 | Definición de cartera real HODOM | Catálogo formal de diagnósticos/prestaciones realmente ofrecidas | Must | F0 | Proceso | M2 | BG-004 |
| BG-019 | Reglas de inclusión y exclusión | Parametrización de criterios normativos y locales | Must | F0 | Mixto | M2 | BG-018 |
| BG-020 | Formulario único de postulación | Ingreso estructurado desde hospital o APS | Must | F1 | Sistema | M2 | BG-019 |
| BG-021 | Identificador único de episodio | Crear número único desde la postulación | Must | F1 | Sistema | M2 | BG-020 |
| BG-022 | Registro de origen de derivación | Servicio hospitalario, APS, postrados, otro | Must | F1 | Sistema | M2 | BG-020 |
| BG-023 | Evaluación médica de elegibilidad | Validación clínica del ingreso por médico HODOM | Must | F1 | Mixto | M2 | BG-020 |
| BG-024 | Evaluación domiciliaria/social | Validar servicios básicos, acceso, telefonía y cuidador | Must | F1 | Mixto | M2 | BG-020 |
| BG-025 | Checklist de ingreso enfermería | Consentimiento, educación, invasivos, lesiones, tratamientos | Must | F1 | Sistema | M2 | BG-020 |
| BG-026 | Evaluación kinésica de ingreso | Barthel, dependencia motora/respiratoria, objetivos | Should | F1 | Sistema | M2 | BG-020 |
| BG-027 | Registro de rechazo/no ingreso | Motivo, responsable, conducta alternativa, trazabilidad | Must | F1 | Sistema | M2 | BG-023, BG-024 |
| BG-028 | Retroalimentación al derivador | Notificación estructurada de aceptación o rechazo | Should | F1 | Sistema | M2 | BG-027 |
| BG-029 | Búsqueda activa hospitalaria | Flujo operativo para pesquisa en Medicina/UE/Cirugía/Trauma | Should | F2 | Mixto | M2 | BG-018, BG-020 |
| BG-030 | Flujo APS/Postrados | Canal específico para derivación directa APS→HODOM | Should | F2 | Mixto | M2 | BG-020, BG-028 |

---

## EPIC 4 — CONSENTIMIENTO, DERECHOS Y SOPORTE DOCUMENTAL DEL USUARIO

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-031 | Consentimiento informado actualizado | Versión corregida a operación real HODOM HSC | Must | F0 | Proceso | M9 | BG-004 |
| BG-032 | Registro digital/físico del consentimiento | Firma, fecha, paciente/representante y profesional responsable | Must | F1 | Mixto | M9 | BG-031, BG-021 |
| BG-033 | Registro de entrega de derechos y deberes | Evidencia de entrega/información de carta y reclamos | Must | F1 | Sistema | M9 | BG-032 |
| BG-034 | Instrucciones de urgencia para familia | Documento simple con conducta en horario hábil e inhábil | Must | F1 | Mixto | M9 | BG-031 |
| BG-035 | Política de privacidad y uso audiovisual | Reglas claras para datos sensibles y registros audiovisuales | Must | F0 | Proceso | M9 | BG-004 |
| BG-036 | Resumen clínico domiciliario imprimible | Documento breve y actualizado para dejar en el hogar | Must | F1 | Sistema | M9 | BG-055, BG-081 |
| BG-037 | Encuesta de satisfacción usuaria | Aplicación formal al egreso con trazabilidad | Should | F2 | Sistema | M9 | BG-091 |

---

## EPIC 5 — FICHA CLÍNICA ÚNICA Y GESTIÓN DEL EPISODIO

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-038 | Ficha clínica única HODOM | Un único expediente por episodio | Must | F1 | Sistema | M3 | BG-021 |
| BG-039 | Línea base clínica inicial | Diagnóstico, antecedentes, Barthel, contexto de ingreso | Must | F1 | Sistema | M3 | BG-038 |
| BG-040 | Línea base social inicial | Cuidador, vivienda, teléfono, acceso, red de apoyo | Must | F1 | Sistema | M3 | BG-038 |
| BG-041 | Registro cronológico de visitas | Secuencia completa de intervenciones por fecha/hora/profesional | Must | F1 | Sistema | M3 | BG-038 |
| BG-042 | Estado del episodio | Postulado, aceptado, activo, suspendido, egresado, reingresado, fallecido | Must | F1 | Sistema | M3 | BG-038 |
| BG-043 | Línea de tiempo del caso | Vista resumida de hitos clínicos y operativos | Should | F2 | Sistema | M3 | BG-041, BG-042 |
| BG-044 | Gestión de pendientes clínicos | Exámenes, interconsultas, imágenes, recetas, controles | Must | F1 | Sistema | M3 | BG-041 |
| BG-045 | Bitácora de llamadas clínicas | Registro estructurado de llamadas relevantes | Must | F1 | Sistema | M3 | BG-038 |
| BG-046 | Registro de observaciones críticas | Alertas de riesgo, eventos adversos, agresiones, brechas | Must | F2 | Sistema | M3 | BG-041 |
| BG-047 | Control de acceso por rol | Restricción por perfil profesional y administrativo | Must | F1 | Sistema | M3 | BG-038 |
| BG-048 | Bitácora de cambios | Trazabilidad de edición de información crítica | Should | F2 | Sistema | M3 | BG-047 |

---

## EPIC 6 — ENFERMERÍA CLÍNICA

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-049 | Ingreso de enfermería digital | Versión estructurada del formulario actual HSC | Must | F1 | Sistema | M4 | BG-038 |
| BG-050 | Evolución de enfermería por visita | Registro clínico estandarizado con hora y plan | Must | F1 | Sistema | M4 | BG-041 |
| BG-051 | Registro de administración de medicamentos | Dosis, vía, dilución, número de dosis, observaciones | Must | F1 | Sistema | M4 | BG-050 |
| BG-052 | Vigilancia de invasivos | Fecha de instalación, cambio, signos de infección/flebitis | Must | F1 | Sistema | M4 | BG-050 |
| BG-053 | Registro de plan de enfermería | Diagnóstico de enfermería + objetivos + seguimiento | Must | F1 | Sistema | M4 | BG-049 |
| BG-054 | Registro de educación al paciente/cuidador | Tema, destinatario, fecha, profesional | Should | F1 | Sistema | M4 | BG-050 |
| BG-055 | Registro de signos vitales y visita equipo | Formato unificado del control de visita domiciliaria | Must | F1 | Sistema | M4 | BG-041 |
| BG-056 | Registro de curaciones | Lugar, grado, exudado, tejido, apósito, evolución | Should | F2 | Sistema | M4 | BG-050 |
| BG-057 | Clasificación de curación simple/avanzada | Estandarización para insumos y seguimiento | Should | F2 | Sistema | M4 | BG-056 |
| BG-058 | Cierre de enfermería al egreso | Barthel egreso, cierre de plan y educación final | Must | F2 | Sistema | M4 | BG-091 |

---

## EPIC 7 — MÉDICO HODOM Y REGULACIÓN CLÍNICA

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-059 | Evaluación médica de ingreso | Registro clínico formal del juicio de elegibilidad | Must | F1 | Sistema | M4 | BG-023 |
| BG-060 | Plan terapéutico médico | Diagnóstico, tratamiento, frecuencia, criterios de control | Must | F1 | Sistema | M4 | BG-059 |
| BG-061 | Gestión de interconsultas e indicaciones | Solicitud, respuesta y seguimiento | Should | F2 | Sistema | M4 | BG-044 |
| BG-062 | Gestión de exámenes e imagenología | Solicitud, estado, resultado y revisión clínica | Must | F2 | Sistema | M4 | BG-044 |
| BG-063 | Regulación clínica a distancia | Registro de orientación/remota y decisiones | Should | F2 | Sistema | M4 | BG-045 |
| BG-064 | Registro de reingreso hospitalario | Motivo, hora, conductor clínico y destino | Must | F1 | Sistema | M6 | BG-088 |
| BG-065 | Epicrisis médica | Cierre del episodio con continuidad y pendientes | Must | F1 | Sistema | M7 | BG-091 |
| BG-066 | Registro de adecuación de esfuerzo terapéutico | Campo específico para situaciones complejas | Could | F3 | Sistema | M4 | BG-060 |

---

## EPIC 8 — KINESIOLOGÍA, FONOAUDIOLOGÍA, TENS Y TRABAJO SOCIAL

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-067 | Ingreso kinésico digital | Captura de formulario actual HSC de kinesiología | Should | F1 | Sistema | M4 | BG-038 |
| BG-068 | Plan kinésico motoro-respiratorio | Objetivos, frecuencia, evolución | Should | F2 | Sistema | M4 | BG-067 |
| BG-069 | Registro fonoaudiológico | Evaluación, plan e indicaciones a cuidadores | Could | F2 | Sistema | M4 | BG-038 |
| BG-070 | Registro TENS | Tareas asignadas, controles y observaciones | Should | F1 | Sistema | M4 | BG-041 |
| BG-071 | Evaluación social de ingreso | Domicilio, cuidador, economía, accesos, apoyos | Must | F1 | Sistema | M4 | BG-024 |
| BG-072 | Seguimiento social durante el episodio | Gestión de ayudas/redes/brechas persistentes | Should | F2 | Sistema | M4 | BG-071 |
| BG-073 | Coordinación con red municipal y APS | Registro de derivaciones y apoyos sociales | Should | F2 | Sistema | M7 | BG-072 |

---

## EPIC 9 — RUTAS, FLOTA Y OPERACIÓN DIARIA

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-074 | Programación diaria de rutas | Asignación de pacientes, profesionales, horarios y móvil | Must | F1 | Sistema | M5 | BG-042 |
| BG-075 | Hoja de ruta por móvil | Vista operativa para conductor/equipo | Must | F1 | Sistema | M5 | BG-074 |
| BG-076 | Control de salida a terreno | Checklist de móvil, equipamiento y comunicaciones | Must | F1 | Mixto | M5 | BG-074 |
| BG-077 | Registro de flota y mantención | Vehículo, estado, mantenciones, incidentes | Should | F2 | Sistema | M5 | BG-076 |
| BG-078 | Gestión de contingencias de ruta | Reasignación o cambios por falla, clima, acceso, urgencia | Should | F2 | Sistema | M5 | BG-074 |
| BG-079 | Entrega de turno estructurada | Documento/flujo de relevo por paciente y operación | Must | F1 | Mixto | M5 | BG-041, BG-074 |
| BG-080 | Pase diario interdisciplinario | Vista clínica y operativa de pacientes activos | Should | F2 | Mixto | M5 | BG-079 |

---

## EPIC 10 — INSUMOS, FARMACIA, CADENA DE FRÍO Y MUESTRAS

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-081 | Trazabilidad de insumos clínicos | Entrega y uso de insumos por episodio/paciente | Must | F2 | Sistema | M5 | BG-038 |
| BG-082 | Trazabilidad de medicamentos | Desde prescripción/despacho hasta administración | Must | F2 | Sistema | M5 | BG-051, BG-060 |
| BG-083 | Control de temperatura/cadena de frío | Bodega, traslado y termolábiles | Should | F2 | Mixto | M5 | BG-081 |
| BG-084 | Gestión de muestras clínicas | Toma, embalaje, transporte, recepción y resultado | Should | F2 | Mixto | M5 | BG-062 |
| BG-085 | Flujo con laboratorio | Estados y trazabilidad de examen solicitado | Should | F2 | Sistema | M5 | BG-084 |
| BG-086 | Flujo con imagenología | Coordinación y cierre de estudio por episodio | Could | F3 | Sistema | M5 | BG-062 |

---

## EPIC 11 — SEGURIDAD CLÍNICA, IAAS, REAS Y EVENTOS

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-087 | Registro de dispositivos invasivos por episodio | Catálogo y vigilancia estructurada | Must | F1 | Sistema | M6 | BG-052 |
| BG-088 | Protocolo y flujo de escalamiento clínico | Alerta, regulación, SAMU, reingreso, registro | Must | F1 | Mixto | M6 | BG-060 |
| BG-089 | Registro de signos de alarma / deterioro | Evento, gravedad, acción tomada, resultado | Must | F2 | Sistema | M6 | BG-055, BG-088 |
| BG-090 | Protocolo IAAS domiciliario operativo | Precauciones estándar y aislamiento adaptado al domicilio | Must | F0 | Proceso | M6 | BG-004 |
| BG-091 | Gestión de egreso y cierre clínico | Alta, reingreso, fallecimiento, renuncia, alta disciplinaria | Must | F1 | Mixto | M7 | BG-042 |
| BG-092 | Manejo REAS | Segregación, transporte, disposición transitoria y trazabilidad | Must | F2 | Mixto | M6 | BG-004 |
| BG-093 | Registro de eventos adversos e incidentes | Caídas, errores, IAAS, eventos de seguridad | Should | F2 | Sistema | M6 | BG-089 |
| BG-094 | Protocolo de agresión al personal | Respuesta frente a entorno inseguro | Must | F0 | Proceso | M6 | BG-004 |
| BG-095 | Registro de incidentes de seguridad del personal | Hecho, acción, apoyo institucional, seguimiento | Should | F2 | Sistema | M6 | BG-094 |

---

## EPIC 12 — EGRESO, CONTINUIDAD Y RED ASISTENCIAL

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-096 | Epicrisis integral de egreso | Médica + enfermería + continuidad esencial | Must | F1 | Sistema | M7 | BG-065, BG-058 |
| BG-097 | Contrarreferencia APS | Envío estructurado de continuidad a CESFAM/programas | Must | F2 | Mixto | M7 | BG-096 |
| BG-098 | Definición de responsable post-alta | Qué continúa HODOM, APS, hospital, familia | Must | F2 | Mixto | M7 | BG-096 |
| BG-099 | Cierre por alta disciplinaria o renuncia | Flujo y trazabilidad formal | Should | F2 | Sistema | M7 | BG-091 |
| BG-100 | Protocolo de fallecimiento en domicilio | Certificación, retiro de dispositivos, cierre documental | Must | F0 | Proceso | M7 | BG-004 |
| BG-101 | Registro de continuidad social | Ayudas, apoyos, derivaciones vigentes al egreso | Should | F2 | Sistema | M7 | BG-073 |

---

## EPIC 13 — CALIDAD, INDICADORES Y TABLERO

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-102 | Diccionario de indicadores HODOM | Definición, fórmula, fuente y periodicidad | Must | F0 | Proceso | M8 | BG-018 |
| BG-103 | Tablero operativo diario | Pacientes activos, cupos, rutas, alertas | Must | F1 | Sistema | M8 | BG-042, BG-074 |
| BG-104 | Tablero mensual de gestión | Ingresos, egresos, ocupación, estada, reingresos, productividad | Must | F2 | Sistema | M8 | BG-102, BG-103 |
| BG-105 | Indicadores de calidad y seguridad | Eventos adversos, IAAS, mortalidad, cumplimiento documental | Should | F2 | Sistema | M8 | BG-093 |
| BG-106 | Indicadores de satisfacción usuaria | Consolidado y evolución mensual | Should | F2 | Sistema | M8 | BG-037 |
| BG-107 | Auditoría de fichas y procesos | Muestreo, hallazgos, planes de mejora | Should | F2 | Mixto | M8 | BG-008, BG-104 |
| BG-108 | Productividad por profesional y móvil | Carga operativa real por equipo | Could | F3 | Sistema | M8 | BG-074, BG-041 |
| BG-109 | Medición de días cama liberados | Cuantificar impacto hospitalario de HODOM | Should | F2 | Sistema | M8 | BG-104 |

---

## EPIC 14 — ALERTAS, REGLAS Y SEGURIDAD DIGITAL

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-110 | Alertas de consentimiento faltante | Aviso si el episodio no tiene consentimiento válido | Must | F1 | Sistema | M9 | BG-032 |
| BG-111 | Alertas de registro incompleto | Campos críticos faltantes en ingreso/visita/egreso | Must | F1 | Sistema | M3 | BG-038 |
| BG-112 | Alertas de certificación vencida | Personal no habilitado para salir a terreno | Must | F1 | Sistema | M1 | BG-012 |
| BG-113 | Alertas de epicrisis pendiente | Episodio sin cierre documental completo | Must | F1 | Sistema | M7 | BG-096 |
| BG-114 | Alertas de signos críticos | Parámetros fuera de rango o eventos de deterioro | Should | F2 | Sistema | M6 | BG-089 |
| BG-115 | Bitácora de resolución de alertas | Cierre, justificación y responsable de la alerta | Should | F2 | Sistema | M8 | BG-110, BG-111, BG-112, BG-113 |

---

## EPIC 15 — INTEROPERABILIDAD Y ESCALAMIENTO

| ID | Feature | Descripción | Prioridad | Fase | Tipo | Módulo | Dependencias |
|----|---------|-------------|-----------|------|------|--------|--------------|
| BG-116 | Integración con laboratorio hospitalario | Consulta/recepción estructurada de resultados | Could | F3 | Sistema | M5 | BG-085 |
| BG-117 | Integración con imagenología | Estado del examen y resultado asociado al episodio | Could | F3 | Sistema | M5 | BG-086 |
| BG-118 | Integración con farmacia hospitalaria | Despacho/entrega vinculada al episodio | Could | F3 | Sistema | M5 | BG-082 |
| BG-119 | Integración con sistemas hospitalarios maestros | Paciente, RUT, episodio, datos básicos | Could | F3 | Sistema | M3 | BG-038 |
| BG-120 | Exportación de reportes institucionales | Dirección, servicio de salud, proyecto BIP, calidad | Should | F3 | Sistema | M8 | BG-104 |

---

# 6. MVP recomendado (lo mínimo para partir bien)

## MVP F1 — indispensable

### Núcleo regulatorio-operativo
- BG-001 a BG-006
- BG-010 a BG-015
- BG-018 a BG-028
- BG-031 a BG-036
- BG-038 a BG-047
- BG-049 a BG-055
- BG-059, BG-060, BG-064, BG-065
- BG-071
- BG-074 a BG-076, BG-079
- BG-087, BG-088, BG-091
- BG-102, BG-103
- BG-110 a BG-113

### Resultado del MVP
Con esto HODOM HSC ya podría operar con:
- episodio único
- admisión trazable
- ficha clínica básica usable
- visitas domiciliarias registradas
- consentimiento y resumen domiciliario
- rutas y salida a terreno
- egreso y epicrisis
- tablero operacional mínimo
- alertas críticas de seguridad y cumplimiento

---

# 7. Dependencias críticas

## Dependencias estructurales
1. **No se debe desarrollar sistema sin cerrar F0 documental mínima**
   - cartera real
   - formularios definitivos
   - consentimiento corregido
   - reglas de inclusión/exclusión
   - protocolos críticos

2. **No se debe construir tablero serio sin identificador único de episodio**
   - si no, ocupación/reingresos/estada seguirán siendo inexactos

3. **No se debe prometer interoperabilidad antes de estabilizar el modelo interno**
   - primero flujo local consistente, después integraciones

4. **No se debe dejar fuera trabajo social, kinesiología ni curaciones del modelo de datos**
   - son parte del core real de HODOM HSC, no anexos

---

# 8. Recomendación de implementación

## Sprint 0 — diseño funcional
- validar backlog con DT + enfermera coordinadora + médico HODOM + TS + kinesiología
- congelar formularios definitivos
- definir campos obligatorios
- acordar estados del episodio
- definir indicadores mínimos

## Sprint 1 — admisión + ficha + consentimiento
- postulación
- episodio único
- ingreso enfermería
- evaluación médica
- consentimiento
- datos sociales básicos

## Sprint 2 — visitas + rutas + enfermería
- evolución
- signos vitales
- administración de medicamentos
- rutas
- entrega de turno

## Sprint 3 — egreso + epicrisis + continuidad
- alta
- contrarreferencia
- resumen domiciliario
- tablero básico

## Sprint 4 — seguridad + calidad
- alertas
- invasivos
- REAS
- incidentes
- satisfacción usuaria

## Sprint 5 — consolidación
- indicadores avanzados
- productividad
- auditoría
- integraciones

---

# 9. Conclusión

Este backlog deja a HODOM HSC en una posición mucho más madura porque:

- convierte normativa en producto,
- convierte formularios en módulos,
- convierte operación real en features,
- y convierte la unidad en un sistema gestionable, auditable y escalable.

El paso más lógico ahora no es seguir agregando documentos narrativos, sino hacer uno de estos dos:

## Próximo documento posible
### Opción 1 — **Backlog técnico detallado**
con columnas:
- ID
- épica
- feature
- descripción técnica
- entidad de datos
- pantalla/formulario
- regla de negocio
- prioridad
- dependencia

### Opción 2 — **Mapa de datos / modelo entidad-relación HODOM**
para diseñar la base del sistema:
- paciente
- episodio
- visita
- profesional
- ruta
- medicamento
- invasivo
- curación
- egreso
- contrarreferencia
- incidente

**Mi recomendación:** ir ahora con la **Opción 2 (modelo de datos)**, porque ordena todo el desarrollo posterior.