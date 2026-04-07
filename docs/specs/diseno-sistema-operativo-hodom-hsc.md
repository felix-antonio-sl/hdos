# Diseño del Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Estado: borrador de arquitectura operativa v1
Alcance: identificación de usuarios, necesidades, historias de usuario y diseño del sistema para Hospitalización Domiciliaria del Hospital de San Carlos

---

## 1. Tensión principal

El sistema no debe ser solo una ficha clínica ni solo una agenda logística.

Debe operar como un **sistema socio-técnico de hospitalización en domicilio** que coordina al mismo tiempo:

1. continuidad clínica hospitalaria en casa,
2. elegibilidad y admisión reglada,
3. programación dinámica de visitas y rutas,
4. teleatención y regulación a distancia,
5. registro clínico legalmente válido,
6. abastecimiento e insumos,
7. coordinación con APS, hospital y red,
8. tributación estadística REM A21.

La unidad estructural del dominio es el **episodio de hospitalización domiciliaria**, no el paciente aislado ni la visita aislada.

---

## 2. Qué dicen las fuentes, en síntesis

### 2.1 Normativa y operación mínima exigida

De DS 1/2022 y Norma Técnica 2024 se desprende que HODOM debe garantizar:

- indicación y control médico,
- plan terapéutico del equipo de salud,
- registro clínico manual o electrónico seguro,
- consentimiento informado,
- criterios de ingreso y egreso,
- continuidad asistencial,
- coordinación con derivadores y médico tratante,
- traslado oportuno si hay agudización o reingreso,
- infraestructura 24/7 de comunicación y trazabilidad de llamados,
- protocolos de rutas, visitas, emergencias, fallecimiento, agresiones, residuos e intervenciones,
- resguardo de confidencialidad de ficha clínica.

### 2.2 REM A21 impone observabilidad operativa

El sistema debe derivar automáticamente:

- ingresos,
- personas atendidas,
- días-persona,
- altas,
- fallecidos esperados y no esperados,
- reingresos,
- origen de derivación,
- visitas por profesión,
- cupos programados, usados y disponibles.

### 2.3 El legacy muestra el trabajo real

Las planillas y documentos legacy evidencian que hoy la operación vive fragmentada en:

- formularios de postulación/ingreso,
- programación diaria y mensual,
- rutas por profesional y hora,
- registro de llamadas,
- entrega de turno,
- registros específicos por disciplina,
- canasta de prestaciones,
- coordinación con APS y derivadores,
- seguimiento social y familiar.

### 2.4 Los modelos OPM y categoriales convergen en lo mismo

El sistema real tiene al menos estas capas:

- clínica,
- operacional,
- territorial/logística,
- documental,
- estadística,
- institucional/red.

---

## 3. Usuarios del sistema

## 3.1 Usuarios primarios clínico-operativos

### 1. Médico de atención directa
Necesita:
- evaluar ingreso y egreso,
- indicar tratamiento,
- hacer seguimiento clínico,
- regular eventos agudos,
- documentar evolución, indicaciones y epicrisis,
- decidir teleatención vs visita presencial vs reingreso.

### 2. Médico regulador
Necesita:
- recibir alertas y llamados,
- responder a distancia,
- dejar trazabilidad de regulación,
- activar derivación o traslado,
- supervisar continuidad fuera de horario o ante cambio clínico.

### 3. Enfermera clínica
Necesita:
- gestionar admisión clínica,
- construir plan de cuidados,
- registrar visitas, medicamentos, invasivos y educación,
- evaluar evolución y alertas,
- coordinar TENS y continuidad diaria,
- cerrar o escalar incidentes.

### 4. Enfermera coordinadora / coordinación HODOM
Necesita:
- tablero completo de capacidad, cupos y pacientes,
- decidir admisiones y prioridades,
- asignar equipo,
- programar visitas y rutas,
- monitorear cumplimiento,
- gestionar insumos, móviles, contingencias y continuidad,
- consolidar REM y trazabilidad operativa.

### 5. TENS / técnico paramédico
Necesita:
- ver su ruta diaria,
- acceder a indicaciones operativas seguras,
- registrar administración, controles y observaciones,
- reportar incidencias en terreno,
- dejar constancia de visita fallida, rechazo o imposibilidad.

### 6. Kinesiólogo
Necesita:
- gestionar evaluación de ingreso y controles,
- ver objetivos terapéuticos y restricciones,
- registrar intervención motora/respiratoria,
- dejar handoff de turno,
- coordinar ayuno, horario y condiciones de atención.

### 7. Fonoaudiólogo
Necesita:
- evaluar deglución, comunicación y terapia,
- emitir indicaciones para hogar y cuidador,
- coordinar continuidad con APS,
- registrar recomendaciones y riesgos.

### 8. Trabajador social
Necesita:
- evaluar condiciones del hogar,
- validar cuidador y red de apoyo,
- hacer seguimiento social,
- documentar barreras de acceso, telefonía, servicios básicos y vulnerabilidad,
- coordinar con familia y red.

### 9. Terapeuta ocupacional / psicólogo / matrona / otros profesionales
Necesitan:
- ver pacientes asignados,
- registrar intervención específica,
- programar visitas o teleatención,
- aportar a objetivos del plan interdisciplinario.

## 3.2 Usuarios administrativos y de soporte

### 10. Administrativo/a HODOM
Necesita:
- registrar postulaciones,
- validar datos demográficos y contactos,
- gestionar consentimientos y documentos,
- coordinar agenda, llamados y comunicaciones,
- mantener trazabilidad documental.

### 11. Gestor/a de rutas y despacho
Necesita:
- ver mapa, zonas, tiempos y restricciones,
- secuenciar visitas,
- asignar móvil y profesional,
- reprogamar ante contingencias,
- separar teleatención de visita presencial,
- optimizar cobertura de 20 a 30 pacientes activos.

### 12. Encargado/a de farmacia, botiquín e insumos
Necesita:
- gestionar stock,
- preparar despacho por paciente/visita,
- asegurar cadena de frío cuando aplique,
- registrar entrega, consumo, devolución y quiebres,
- vincular insumos a plan terapéutico.

### 13. Conductor / apoyo logístico
Necesita:
- ver ruta, horarios y carga,
- confirmar salida/llegada,
- reportar incidentes, atrasos o imposibilidad de acceso,
- coordinar traslado de personal, equipos o paciente.

### 14. Estadístico / referente REM
Necesita:
- obtener datos consistentes sin reprocesamiento manual,
- auditar cierres de ficha,
- validar origen de derivación, profesión, tipo de egreso y cupos,
- exportar REM A21 y trazas de respaldo.

## 3.3 Usuarios institucionales y de red

### 15. Dirección Técnica
Necesita:
- visibilidad global de cumplimiento normativo,
- auditoría de registros, incidentes y mortalidad,
- control de dotación, capacitación, protocolos y calidad,
- métricas de operación y riesgo.

### 16. Servicio derivador hospitalario / unidad de origen
Necesita:
- postular paciente,
- conocer aceptación o rechazo con causal,
- enviar antecedentes clínicos,
- recibir retroalimentación del proceso.

### 17. APS / CESFAM / programa postrados
Necesita:
- derivar o contraderivar,
- recibir epicrisis y plan post egreso,
- coordinar continuidad ambulatoria o domiciliaria no hospitalaria,
- participar en telecoordinación cuando aplique.

## 3.4 Usuarios beneficiarios externos

### 18. Paciente
Necesita:
- comprender plan terapéutico,
- conocer próximas visitas o teleatenciones,
- recibir indicaciones claras,
- reportar síntomas o eventos,
- saber cuándo contactar al equipo o acudir a urgencias.

### 19. Cuidador / familiar / tutor
Necesita:
- educación y tareas claras,
- registrar o comunicar cambios relevantes,
- recibir recordatorios e indicaciones,
- conocer ventanas horarias,
- participar en consentimiento y continuidad de cuidado.

---

## 4. Segmentación funcional de usuarios

### A. Conducen el episodio
- médico atención directa
- enfermera clínica
- coordinación HODOM

### B. Ejecutan atención y observación en terreno
- TENS
- kinesiólogo
- fonoaudiólogo
- trabajador social
- otros profesionales

### C. Operan la máquina logística-documental
- administrativo
- gestor de rutas
- bodega/farmacia
- conductor
- estadístico

### D. Gobiernan y auditan
- Dirección Técnica
- coordinación
- calidad / auditoría / estadística

### E. Interfaz de red y continuidad
- derivadores hospitalarios
- APS / CESFAM
- paciente / cuidador

---

## 5. Necesidades críticas por dominio

## 5.1 Admisión y elegibilidad

El sistema debe permitir:
- registrar postulación desde hospital, urgencia, APS, ambulatorio o UGCC,
- validar criterios de ingreso y exclusión,
- verificar domicilio, cobertura, telefonía, servicios básicos y cuidador,
- gestionar consentimiento informado,
- dejar aceptación, rechazo o pendiente con causal explícita,
- asignar episodio, equipo responsable y ventana de primera visita.

## 5.2 Gestión clínica del episodio

Debe permitir:
- problema principal, comorbilidades, diagnóstico y objetivos,
- plan terapéutico interdisciplinario,
- plan de cuidados de enfermería,
- categorización del paciente,
- programación de frecuencia por disciplina,
- registro clínico por visita o teleatención,
- alertas por signos, eventos, incumplimientos o deterioro,
- egreso con epicrisis y continuidad.

## 5.3 Operación diaria y logística

Debe permitir:
- tablero de pacientes activos,
- programación diaria y semanal,
- rutas por zona/profesional/móvil,
- replanificación dinámica por contingencia,
- trazabilidad de visita realizada, fallida, rechazada o reagendada,
- coordinación de exámenes, insumos, fármacos y retiro de residuos.

## 5.4 Comunicación y teleatención

Debe permitir:
- registro de llamadas entrantes y salientes,
- teleorientación y telemonitoreo,
- regulación médica y de enfermería a distancia,
- mensajería/documentación de indicaciones al paciente o cuidador,
- escalamiento a visita presencial o traslado,
- trazabilidad legal y clínica de toda interacción remota.

## 5.5 Registro clínico y cumplimiento legal

Debe permitir:
- ficha clínica electrónica o híbrida compatible con DS 41,
- consentimiento, carta de derechos y deberes, formulario de ingreso, resumen clínico domiciliario, plan de cuidados y epicrisis,
- seguridad, integridad, confidencialidad e inviolabilidad,
- firma o validación por autor,
- cierre oportuno de registros para REM y auditoría.

## 5.6 Observabilidad y gestión institucional

Debe permitir:
- cupos programados/usados/disponibles,
- ocupación, días-persona, visitas por disciplina,
- ingresos por origen de derivación,
- reingresos, fallecidos esperados/no esperados,
- cumplimiento de tiempos y productividad,
- auditoría de documentación faltante.

---

## 6. Historias de usuario nucleares

## 6.1 Admisión

- Como **médico derivador**, quiero postular un paciente con antecedentes clínicos mínimos para saber si es elegible para HODOM.
- Como **enfermera coordinadora**, quiero ver postulaciones nuevas con causal y procedencia para priorizar admisiones según riesgo y cupo.
- Como **trabajadora social**, quiero evaluar hogar, telefonía y cuidador para confirmar factibilidad domiciliaria.
- Como **coordinación**, quiero registrar aceptación/rechazo con causal normativa para trazabilidad clínica y administrativa.

## 6.2 Operación clínica

- Como **médico HODOM**, quiero abrir un episodio con diagnóstico, objetivos y plan terapéutico para dirigir el tratamiento en domicilio.
- Como **enfermera clínica**, quiero registrar visita, signos vitales, intervenciones, invasivos y educación para sostener continuidad segura.
- Como **TENS**, quiero ver indicaciones simplificadas y registrar ejecución en terreno para no depender de papel o WhatsApp.
- Como **kinesiólogo**, quiero registrar evaluación, control y entrega de turno para continuidad terapéutica diaria.

## 6.3 Teleatención y regulación

- Como **médico regulador**, quiero recibir una alerta remota y decidir si basta teleindicación, si requiere visita o si debe reingresar a hospital.
- Como **enfermera**, quiero registrar una llamada clínica y asociarla al episodio para que quede como parte de la historia clínica.
- Como **cuidador**, quiero reportar una descompensación o duda y recibir instrucciones claras con respaldo del equipo.

## 6.4 Logística

- Como **gestor de rutas**, quiero agrupar visitas por zona y ventana horaria para maximizar cobertura sin perder prioridad clínica.
- Como **coordinación**, quiero reprogramar automáticamente cuando un profesional falta o aparece una urgencia para evitar quiebres de continuidad.
- Como **bodega/farmacia**, quiero preparar despachos por paciente y plan terapéutico para asegurar insumos correctos y trazables.

## 6.5 Egreso y continuidad

- Como **médico**, quiero egresar con tipo de egreso normalizado para generar epicrisis, REM y continuidad con APS.
- Como **APS/CESFAM**, quiero recibir contrarreferencia estructurada para continuar cuidados post egreso.
- Como **estadístico**, quiero que el egreso impacte automáticamente REM sin doble digitación.

---

## 7. Diseño del sistema operativo HODOM

## 7.1 Principio de diseño

No conviene un solo módulo monolítico indiferenciado. Tampoco conviene fragmentarlo en sistemas inconexos.

La mejor forma aquí es un **modular monolith clínico-operacional** con un episodio compartido como núcleo y 7 bounded domains internos.

## 7.2 Núcleo canónico

### Núcleo: Episodio HODOM
Entidad central con:
- paciente,
- domicilio,
- cuidador,
- origen de derivación,
- estado de elegibilidad,
- estado del episodio,
- plan terapéutico,
- equipo asignado,
- agenda y visitas,
- registros clínicos,
- insumos y medicación,
- tipo de egreso,
- continuidad con APS/red,
- trazabilidad REM.

## 7.3 Módulos del sistema

### M1. Admisión y elegibilidad
Funciones:
- intake de postulaciones,
- checklist clínico-social,
- validación de cobertura y exclusiones,
- consentimiento,
- aceptación/rechazo,
- apertura de episodio.

Usuarios:
- médico derivador,
- médico HODOM,
- enfermera coordinadora,
- trabajadora social,
- administrativo.

### M2. Gestión clínica interdisciplinaria
Funciones:
- problema activo,
- plan terapéutico,
- planes por disciplina,
- objetivos y criterios de alta,
- evolución clínica,
- administración terapéutica,
- observaciones y procedimientos.

Usuarios:
- médicos,
- enfermería,
- TENS,
- kinesio,
- fono,
- psicología,
- TO,
- trabajo social.

### M3. Programación, agenda y rutas
Funciones:
- agenda por día/semana,
- rutas por profesional,
- asignación de móvil,
- ventanas horarias,
- replanificación dinámica,
- visitas fallidas o reagendadas.

Usuarios:
- coordinación,
- gestor de rutas,
- profesionales,
- conductor.

### M4. Teleatención, llamadas y regulación
Funciones:
- bandeja de llamados,
- registro de teleorientación,
- telemonitoreo y control remoto,
- indicaciones a cuidador,
- escalamiento clínico,
- continuidad fuera de terreno.

Usuarios:
- médico regulador,
- enfermería,
- coordinación,
- administrativo,
- paciente/cuidador.

### M5. Logística clínica y abastecimiento
Funciones:
- stock,
- despacho por paciente,
- equipos y dispositivos,
- cadena de frío,
- retiro de residuos,
- coordinación con laboratorio, imagenología y apoyo diagnóstico.

Usuarios:
- coordinación,
- farmacia/bodega,
- conductor,
- profesionales clínicos.

### M6. Documentos clínico-legales
Funciones:
- consentimiento,
- carta de derechos y deberes,
- formulario de ingreso,
- resumen clínico domiciliario,
- epicrisis,
- documentos para APS,
- evidencias de educación y entrega.

Usuarios:
- médicos,
- enfermería,
- administrativo,
- Dirección Técnica,
- auditoría.

### M7. Analítica, REM y auditoría
Funciones:
- tablero operacional,
- cálculo REM A21,
- validaciones de consistencia,
- productividad por disciplina,
- capacidad y ocupación,
- indicadores de calidad,
- documentación incompleta.

Usuarios:
- coordinación,
- estadístico,
- Dirección Técnica,
- gestión hospitalaria.

---

## 8. Flujos operativos que el sistema debe sostener

## F1. Derivación e ingreso
Derivador -> postulación -> evaluación clínica -> evaluación social/logística -> consentimiento -> aceptación/rechazo -> episodio activo -> primera visita.

## F2. Planificación diaria
Pacientes activos -> priorización clínica -> definición de visitas/teleatenciones -> secuenciación de rutas -> despacho de equipos/insumos -> ejecución.

## F3. Atención en domicilio
Llegada -> identificación -> intervención -> registro estructurado + nota libre -> indicaciones -> cierre de visita -> actualización de estado.

## F4. Regulación remota
Llamado/alerta -> clasificación -> revisión del episodio -> teleindicación o visita -> posible derivación/reingreso -> registro trazable.

## F5. Egreso y continuidad
Decisión de egreso -> tipo de egreso -> epicrisis -> educación -> encuesta -> contrarreferencia -> cierre episodio -> consolidación REM.

---

## 9. Diseño específico para telemática

La telemática no debe ser un módulo accesorio. Debe ser una forma de acto asistencial con reglas explícitas.

## 9.1 Tipos de interacción remota
- teleorientación administrativa,
- teleorientación clínica,
- telemonitoreo programado,
- regulación médica,
- seguimiento post visita,
- coordinación con APS o familia.

## 9.2 Reglas mínimas
Toda interacción remota debe registrar:
- quién atendió,
- quién participó,
- fecha y hora,
- motivo,
- contexto clínico consultado,
- evaluación o decisión,
- indicación entregada,
- necesidad de escalamiento,
- vínculo al episodio.

## 9.3 Qué sí puede resolverse remotamente
- educación,
- seguimiento de síntomas leves o esperables,
- revisión de adherencia,
- coordinación de visita,
- aclaración de indicaciones,
- entrega de resultados con registro.

## 9.4 Qué debe escalar
- sospecha de inestabilidad clínica,
- deterioro respiratorio o hemodinámico,
- imposibilidad del cuidador para sostener cuidados,
- problemas de acceso esenciales,
- falla de dispositivo o insumo crítico,
- rechazo repetido de visitas,
- eventos adversos relevantes.

---

## 10. Mapa de pantallas / superficies del sistema

## 10.1 Coordinación
- tablero diario de pacientes activos,
- postulaciones pendientes,
- cupos y ocupación,
- agenda/rutas por día,
- alertas e incidencias,
- pendientes documentales,
- REM del mes.

## 10.2 Clínico por paciente
- resumen clínico,
- diagnósticos,
- plan terapéutico,
- visitas y teleatenciones,
- medicación,
- signos y procedimientos,
- documentos,
- alertas,
- continuidad/red.

## 10.3 Profesional móvil
- mi agenda de hoy,
- datos de contacto,
- mapa/ruta,
- ficha resumida,
- checklist de atención,
- registro rápido offline-first,
- incidentes.

## 10.4 Administrativo/call center
- llamadas,
- contactos,
- mensajes pendientes,
- documentos por firmar,
- derivaciones entrantes,
- coordinación de ventana horaria.

## 10.5 Estadística y gestión
- REM A21,
- productividad,
- ocupación,
- egresos,
- reingresos,
- auditoría de completitud.

---

## 11. Priorización de implementación

## Fase 1. Core operativo mínimo viable
- episodio HODOM,
- admisión y elegibilidad,
- ficha clínica base,
- visitas por disciplina,
- agenda diaria,
- llamadas/regulación,
- egreso,
- REM A21 básico.

## Fase 2. Cierre de continuidad real
- rutas dinámicas,
- teleatención estructurada,
- stock e insumos,
- interconsulta/apoyo diagnóstico,
- contrarreferencia APS,
- alertas y reglas.

## Fase 3. Optimización institucional
- analítica avanzada,
- predicción de carga y cupos,
- auditoría de calidad,
- interoperabilidad FHIR,
- mensajería al cuidador,
- firma y documentos avanzados.

---

## 12. Recomendación arquitectónica

### Recomendación
Construir un **modular monolith con núcleo de episodio**, orientado a operación clínica diaria, con soporte mobile/offline para terreno y una capa analítica que derive REM por consulta, no por redigitación.

### Razones
- el equipo parece pequeño y altamente coordinado,
- las fronteras del dominio ya son claras, pero la operación depende de visibilidad compartida,
- la complejidad principal es de coordinación clínico-logística, no de escalado distribuido extremo,
- fragmentarlo demasiado aumentaría fricción y riesgo regulatorio.

### Trade-offs aceptados
- menos independencia técnica entre módulos al inicio,
- mayor disciplina interna de modelo de datos compartido,
- necesidad de gobernar muy bien estados del episodio y permisos por rol.

---

## 13. Riesgos de diseño a evitar

- tratar HODOM como agenda de visitas y no como hospitalización,
- separar teleatención de la historia clínica,
- mantener REM como proceso manual aguas abajo,
- no modelar cuidador, domicilio y red de apoyo como objetos de primer nivel,
- no distinguir visita programada, realizada, fallida, rechazada y reagendada,
- no modelar tipo de egreso y origen de derivación de forma normalizada,
- no incorporar trazabilidad de llamadas y decisiones clínicas remotas,
- dejar la logística fuera del modelo clínico.

---

## 14. Conclusión

Los usuarios reales del sistema no son solo “médicos y enfermeras”. El sistema debe servir simultáneamente a:

- conducción clínica,
- coordinación operativa,
- ejecución móvil en terreno,
- red familiar/cuidador,
- logística e insumos,
- teleatención,
- continuidad APS-hospital,
- auditoría y REM.

Por eso, el diseño correcto no es una HCE genérica. Es un **sistema operativo de hospitalización domiciliaria**, centrado en el episodio, con clínica + logística + regulación + documentación + estadística como partes del mismo flujo.

---

## 15. Siguiente paso recomendado

Transformar este diseño en 4 artefactos ejecutables:

1. **Mapa de roles y permisos** por usuario.
2. **Catálogo de capacidades por módulo** con prioridad MoSCoW.
3. **Modelo de datos funcional** derivado de este diseño.
4. **Blueprint de pantallas y workflows** para coordinación, terreno y ficha clínica.
