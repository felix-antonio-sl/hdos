# Historias de Usuario Núcleo — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Autor: Allan Kelly
Prerrequisito: `output/2026-04-07-usuarios-sistema-hodom-hsc.md`
Fuentes: ERD 43 tablas, FHIR R4, OPM v2.5, Modelo Categorial v4.1, Manual REM 2026, DS 1/2022, NT 2024, Decreto Exento 31/2024, formularios reales HSC, datos empíricos 2023-2025.

---

## Convenciones

- **Formato:** Como [usuario], necesito [acción] para [beneficio].
- **CA:** Criterio de aceptación.
- **FHIR:** Recurso FHIR R4 principal relacionado.
- **Normativa:** Artículo o sección normativa que respalda o exige la funcionalidad.
- **Prioridad:** P0 = bloqueante/obligatorio normativo, P1 = crítico operacional, P2 = alto valor, P3 = deseable.

---

## Módulo 1 — Censo / Lista de pacientes

### HU-1.1 Ver censo de pacientes activos
Como **gestora/coordinadora (U7)**, necesito ver la lista completa de pacientes activos con su estado actual, servicio de origen, días de estada, profesional asignado y ubicación (comuna/dirección), para planificar el día y detectar alertas.

**CA:**
- Lista muestra todos los pacientes con EstadoHospitalización = activo
- Cada fila incluye: nombre, RUT, edad, días de estada, comuna, diagnóstico principal, categoría (mejorando/estable/deteriorándose), profesional responsable
- Alerta visual si días de estada > 8 (PE-13 del modelo categorial)
- Alerta visual si cupos utilizados ≥ cupos programados (REM A21 C.1.3)
- Filtrable por profesional, comuna, categoría

**FHIR:** `Encounter` (class=HH, status=in-progress), `Patient`, `Condition`, `Location`
**Normativa:** DS 1/2022 art. 20 (descripción del proceso asistencial); REM A21 C.1.3 (cupos)
**Prioridad:** P0

### HU-1.2 Ver cupos disponibles en tiempo real
Como **gestión centralizada de camas (U12)**, necesito ver cuántos cupos HODOM están disponibles en tiempo real para decidir si derivar un paciente.

**CA:**
- Muestra: cupos programados, cupos utilizados, cupos disponibles
- Actualización en tiempo real al ingresar/egresar pacientes
- Consistente con REM: cupos_disponibles = cupos_programados - cupos_utilizados

**FHIR:** `Location` (status, operationalStatus)
**Normativa:** REM A21 C.1.3 reglas R.1 y R.2
**Prioridad:** P1

### HU-1.3 Ver censo para briefing matinal
Como **gestora/coordinadora (U7)**, necesito una vista de briefing que muestre por cada paciente activo: estado clínico del día anterior, visitas programadas hoy, alertas pendientes y novedades, para conducir la reunión de equipo.

**CA:**
- Agrupado por ruta/sector
- Incluye última categorización del paciente
- Incluye visitas pendientes del día
- Incluye alertas: sin visita ayer, deteriorándose, estada > 8 días, dispositivos invasivos próximos a cambio

**FHIR:** `Encounter`, `Observation`, `Flag`
**Normativa:** Inventario HSC (briefing matinal como coordinación diaria)
**Prioridad:** P1

---

## Módulo 2 — Postulación y evaluación de ingreso

### HU-2.1 Registrar postulación de candidato
Como **gestora/coordinadora (U7)**, necesito registrar una postulación nueva con los datos del candidato, servicio derivador y motivo de derivación, para iniciar el proceso de evaluación de elegibilidad.

**CA:**
- Campos mínimos: RUT paciente, nombre, edad, servicio derivador (Derivation Origin), diagnóstico de derivación, médico derivador, fecha
- Genera número de postulación único (PE-16)
- Valida automáticamente: edad ≥ 18, previsión Fonasa/PRAIS (PE-7)
- Estado inicial: pendiente

**FHIR:** `ServiceRequest` (intent=order, category=home-health), `Patient`
**Normativa:** DS 1/2022 art. 15 (requisitos de ingreso); OPM SD1.1 (Candidate Screening)
**Prioridad:** P0

### HU-2.2 Evaluar elegibilidad clínica
Como **médico AD (U1)**, necesito registrar la evaluación clínica del candidato indicando si cumple criterio de condición clínica estable y si tiene alguna condición de exclusión, para decidir si es elegible.

**CA:**
- Checklist de condiciones de exclusión (5 causales DS 1/2022 art. 17): inestabilidad clínica, diagnóstico no establecido, salud mental descompensada, prestación no listada, alta disciplinaria previa
- Si alguna condición presente → candidato no elegible (estado terminal)
- Si ninguna → avanza a evaluación domiciliaria
- Genera Registro de Evaluación Clínica

**FHIR:** `ClinicalImpression`, `Condition`
**Normativa:** DS 1/2022 art. 15, 17; OPM SD1.1 (Clinical Condition Evaluating); wide pullback modelo categorial §4.1
**Prioridad:** P0

### HU-2.3 Evaluar condición del domicilio
Como **trabajador social (U5)**, necesito registrar la evaluación sociosanitaria del domicilio del candidato (condiciones sanitarias, servicios básicos, acceso vial, telefonía, red de apoyo, cuidador disponible), para determinar si el domicilio es apto.

**CA:**
- Campos: dirección, comuna, distancia al hospital (valida ≤ 20 km, PE-5), servicios básicos, telefonía, acceso vial, evaluación visual de condiciones
- Registro de cuidador: RUT, nombre, parentesco, disponibilidad
- Genera Informe Social Preliminar
- Home Condition: adecuada / inadecuada

**FHIR:** `QuestionnaireResponse`, `RelatedPerson` (cuidador)
**Normativa:** DS 1/2022 art. 15; NT 2024 (trabajador social: informe diagnóstico social); OPM SD1.2
**Prioridad:** P0

### HU-2.4 Obtener consentimiento informado
Como **enfermera clínica (U2)**, necesito registrar la firma del consentimiento informado del paciente y/o representante, incluyendo la entrega de la carta de derechos y deberes, para formalizar el ingreso.

**CA:**
- Registra: RUT paciente, RUT cuidador, CESFAM, teléfonos, decisión (acepto/rechazo), firma, parentesco
- Si rechazado → flujo termina, candidato no ingresa
- Si aceptado → habilita ingreso formal
- Registra entrega de carta de derechos y deberes
- Timestamp de firma

**FHIR:** `Consent` (status=active, scope=treatment), `DocumentReference`
**Normativa:** DS 1/2022 art. 15, 20; Ley 20.584; CI 2026 HSC; OPM SD1.1 (Informed Consent Obtaining)
**Prioridad:** P0

### HU-2.5 Formalizar ingreso
Como **gestora/coordinadora (U7)**, necesito formalizar el ingreso del paciente creando el episodio de hospitalización domiciliaria con todos los datos de admisión, para activar el plan de atención.

**CA:**
- Crea EpisodioHD con: paciente, domicilio, equipo asignado, diagnóstico principal, servicio derivador, fecha ingreso, nro postulación
- Estado: activo
- Genera automáticamente: Formulario de Ingreso, vincula CI firmado, vincula Informe Social
- Activa ficha clínica del episodio (estado = activa)
- Cupo utilizado se incrementa en 1

**FHIR:** `Encounter` (class=HH, status=in-progress), `EpisodeOfCare`
**Normativa:** DS 1/2022 art. 15, 20; OPM SD1 (Patient Admitting)
**Prioridad:** P0

### HU-2.6 Registrar rechazo de ingreso con fundamento
Como **médico AD (U1)**, necesito registrar un rechazo de ingreso a HODOM con el motivo clínico documentado, para dejar trazabilidad y comunicar al servicio derivador.

**CA:**
- Campo: motivo de rechazo (texto libre + causal estructurada)
- Cambia estado postulación a rechazada
- Genera notificación al servicio derivador
- Queda en historial del candidato

**FHIR:** `ClinicalImpression` (status=completed, finding)
**Normativa:** Consulta 10 del operador
**Prioridad:** P1

---

## Módulo 3 — Ficha clínica domiciliaria

### HU-3.1 Ver ficha clínica longitudinal del episodio
Como **médico AD (U1)**, necesito ver la ficha clínica completa del episodio actual ordenada cronológicamente, incluyendo todas las notas, evoluciones, signos vitales, labs, indicaciones y procedimientos, para tomar decisiones informadas.

**CA:**
- Timeline cronológica inversa (más reciente primero)
- Agrupa por visita: fecha, profesional, tipo de registro, contenido
- Incluye: narrativa clínica, signos vitales (15 columnas), medicamentos, curaciones, evaluaciones kinesiología, informes sociales
- Permite filtrar por tipo de profesional o tipo de registro
- Accesible desde dentro y fuera del punto de atención (comité, revisión)

**FHIR:** `Composition`, `Observation`, `DocumentReference`, `MedicationRequest`, `Procedure`
**Normativa:** DS 1/2022 art. 20-25; DS 41/2012 (fichas clínicas)
**Prioridad:** P0

### HU-3.2 Registrar ingreso de enfermería
Como **enfermera clínica (U2)**, necesito completar el formulario de ingreso de enfermería con checklist (7 ítems), examen físico (6 dominios), historia clínica, examen segmentario (12 regiones), diagnóstico de enfermería, plan de atención y Barthel de ingreso.

**CA:**
- Formulario estructurado conforme a Hoja Ingreso Enfermería HODOM HSC
- Campos obligatorios: Nro Postulación, fechas, servicio origen, checklist, Barthel ingreso
- Barthel registrado como valor 0-100 (PE-15)
- Profesional responsable de ingreso + profesional responsable de VD

**FHIR:** `QuestionnaireResponse`, `Observation` (Barthel), `Composition`
**Normativa:** Formulario real HSC; NT 2024 (registros)
**Prioridad:** P0

### HU-3.3 Registrar signos vitales por visita (ciclo vital completo)
Como **enfermera clínica (U2)** o **TENS (U6)**, necesito registrar las 12 variables clínicas del ciclo vital en cada visita: PA, FC, FR, T°, SpO2, HGT, EVA, Glasgow, Edema, Diuresis, Deposiciones, Estado Invasivos.

**CA:**
- 12 campos clínicos + fecha + observaciones + responsable (15 columnas totales)
- Validación de rangos fisiológicos por variable
- Alerta si valor fuera de rango normal
- Histórico visible en formato tabla/tendencia

**FHIR:** `Observation` (vital-signs profile + extensiones)
**Normativa:** Formulario Registro Visita Equipo HODOM (real HSC); brecha detectada: OPM modela 4 de 12 variables
**Prioridad:** P0

### HU-3.4 Registrar narrativa clínica de enfermería
Como **enfermera clínica (U2)**, necesito registrar la narrativa clínica diaria, medicamentos administrados (dosis, dilución, vía, nro dosis), plan de enfermería (intervenciones) y estado de dispositivos invasivos.

**CA:**
- 4 secciones: narrativa, tabla medicamentos, plan enfermería, tabla invasivos
- Tabla medicamentos: medicamento × dosis × dilución × vía × nro_dosis
- Tabla invasivos: tipo × fecha_instalación × cambio × signos_infección × observaciones
- Firma electrónica del profesional

**FHIR:** `Composition` (type=progress-note), `MedicationAdministration`, `Device`
**Normativa:** Formulario Registro Enfermería HODOM HSC; DS 1/2022 art. 20
**Prioridad:** P0

### HU-3.5 Registrar evaluación de kinesiología
Como **kinesiólogo (U3)**, necesito registrar la evaluación de ingreso (funcionalidad previa, Barthel, dependencia motora/respiratoria, objetivos) y las evoluciones de seguimiento con signos vitales reducidos.

**CA:**
- Ingreso: antecedentes, estado actual, evaluación motora, evaluación respiratoria, dependencia kinésica, objetivos, indicación
- Seguimiento: signos vitales (PA, FR, FC, SpO2, LitrosO2), evolución, intervenciones
- Barthel pareado ingreso-egreso visible (PE-15)

**FHIR:** `QuestionnaireResponse`, `Observation`, `Procedure`
**Normativa:** Hoja Ingreso Kinesiología HSC
**Prioridad:** P1

### HU-3.6 Registrar curaciones
Como **enfermera clínica (U2)**, necesito registrar curaciones avanzadas con: lugar/grado, exudación/cantidad, tipo tejido, características/tamaño, apósitos utilizados, observaciones.

**CA:**
- Un registro por herida por visita
- Seguimiento longitudinal de la misma herida
- Responsable firmante

**FHIR:** `Procedure` (code=wound-care), `Observation`
**Normativa:** Formulario Registro Curaciones HSC
**Prioridad:** P1

---

## Módulo 4 — Prescripción y tratamiento

### HU-4.1 Prescribir y ajustar medicación
Como **médico AD (U1)**, necesito prescribir medicamentos con dosis, vía, frecuencia y duración, y poder ajustar prescripciones existentes, para que enfermería ejecute el plan farmacológico.

**CA:**
- Lista de medicamentos activos del episodio
- Crear nueva prescripción con campos: medicamento, dosis, dilución, vía, frecuencia, duración
- Modificar/suspender prescripción existente con motivo
- Visible para enfermería en su registro diario

**FHIR:** `MedicationRequest` (intent=order, status=active)
**Normativa:** DS 1/2022 art. 12-13 (médico AD); OPM SD1.4
**Prioridad:** P0

### HU-4.2 Ver plan terapéutico vigente
Como **enfermera clínica (U2)** o **kinesiólogo (U3)**, necesito ver el plan terapéutico completo y vigente del paciente (indicaciones médicas, medicamentos, terapias, cuidados), para ejecutar las intervenciones correctas en cada visita.

**CA:**
- Muestra plan terapéutico activo con todas las indicaciones vigentes
- Diferencia entre indicaciones nuevas y previas
- Incluye fecha de última modificación y autor

**FHIR:** `CarePlan` (status=active), `MedicationRequest`, `ServiceRequest`
**Normativa:** OPM SD1.3 (Care Planning); DS 1/2022 art. 15
**Prioridad:** P0

---

## Módulo 5 — Programación de visitas y rutas

### HU-5.1 Programar visitas diarias
Como **gestora/coordinadora (U7)**, necesito asignar visitas del día por profesional y paciente, indicando orden de visita y horario estimado, para organizar la jornada del equipo.

**CA:**
- Seleccionar profesionales disponibles del día
- Asignar pacientes a cada profesional
- Definir orden de visitas
- Validar que toda visita esté dentro del horario 08:00-19:00 (PE-12)
- Validar que pacientes activos tengan al menos una visita programada

**FHIR:** `Appointment` (status=booked), `Schedule`, `Slot`
**Normativa:** CI 2026 (cobertura L-D 08:00-19:00); OPM SD1.4a
**Prioridad:** P0

### HU-5.2 Asignar y optimizar rutas
Como **gestora/coordinadora (U7)**, necesito asignar pacientes a rutas de transporte considerando ubicación geográfica, para minimizar tiempos de desplazamiento y maximizar visitas.

**CA:**
- Agrupar pacientes por proximidad geográfica
- Asignar a vehículo disponible (3 móviles HSC)
- Mostrar ruta en mapa con orden de visitas
- Estimar tiempos de traslado
- Permitir resolver visitas sin ruta asignada

**FHIR:** `Appointment`, `Location`
**Normativa:** OPM SD1.4a (Route Assignment, Visit Sequencing); NT 2024 (protocolo rutas y visitas)
**Prioridad:** P1

### HU-5.3 Registrar ejecución de ruta
Como **conductor (U9)**, necesito registrar el estado de ejecución de la ruta del día (visitado, no visitado, contingencia), para que coordinación tenga visibilidad en tiempo real.

**CA:**
- Checklist por paciente: visitado / no visitado / contingencia
- Campo de contingencia: motivo (paciente no ubicado, camino cortado, otro)
- Timestamp de llegada y salida por domicilio
- Km recorridos

**FHIR:** `Task` (status=completed/failed)
**Normativa:** OPM SD1.4a (Route Execution Monitoring)
**Prioridad:** P2

---

## Módulo 6 — Egreso y continuidad

### HU-6.1 Decidir continuidad o egreso
Como **médico AD (U1)**, necesito registrar la decisión de continuidad (continuar tratamiento / proceder egreso) con fundamento clínico, tras evaluar la evolución del paciente.

**CA:**
- Selección binaria: continuar-tratamiento / proceder-egreso
- Campo de fundamento clínico obligatorio
- Si proceder-egreso → habilita flujo de egreso
- Registra autor y timestamp

**FHIR:** `ClinicalImpression` (status=completed)
**Normativa:** OPM SD1.5 (Clinical Evolution Monitoring → Continuity Decision)
**Prioridad:** P0

### HU-6.2 Generar egreso formal
Como **médico AD (U1)**, necesito generar el egreso del paciente seleccionando el tipo de egreso (alta médica, reingreso hospitalario, fallecimiento esperado/no esperado, renuncia voluntaria, alta disciplinaria) y completando la documentación requerida.

**CA:**
- Selección de motivo de egreso (coproducto de 5 variantes, modelo categorial §4.2)
- Según variante, genera documentos requeridos:
  - Alta médica → epicrisis
  - Reingreso → epicrisis + solicitud traslado
  - Fallecimiento → epicrisis + protocolo fallecimiento
  - Renuncia voluntaria → epicrisis + declaración retiro
  - Alta disciplinaria → epicrisis (requiere autorización DT)
- Registra Barthel de egreso (PE-15: Δ_barthel = egreso - ingreso)
- Cambia EstadoHospitalización a egresado
- Cierra ficha clínica (PE-11)
- Libera cupo
- Activa encuesta de satisfacción

**FHIR:** `Encounter` (status=finished), `Composition` (type=discharge-summary), `DocumentReference`
**Normativa:** DS 1/2022 art. 16, 20; OPM SD1.6; REM A21 C.1
**Prioridad:** P0

### HU-6.3 Generar epicrisis
Como **médico AD (U1)**, necesito generar la epicrisis del paciente compilando diagnósticos, tratamientos realizados, evolución, indicaciones al alta y contrarreferencia a APS.

**CA:**
- Compone automáticamente desde datos del episodio: diagnósticos, medicamentos, procedimientos, evolución
- Permite edición manual del texto
- Incluye contrarreferencia a CESFAM (epicrisis_a_aps, modelo categorial)
- Genera documento exportable/imprimible
- Queda vinculada al episodio

**FHIR:** `Composition` (type=discharge-summary), `DocumentReference`
**Normativa:** DS 1/2022 art. 20; OPM SD1.6, SD1.7
**Prioridad:** P0

### HU-6.4 Registrar seguimiento post-egreso
Como **enfermera clínica (U2)**, necesito registrar el contacto de seguimiento telefónico a las 48 horas post-egreso y documentar el resultado (favorable/desfavorable).

**CA:**
- Alerta automática a 48h del egreso
- Registro de contacto: fecha, hora, resultado, observaciones
- Si desfavorable → alerta a médico AD

**FHIR:** `Communication` (category=notification), `Observation`
**Normativa:** OPM SD1.7 (Post-Discharge Following); DS 1/2022 art. 16
**Prioridad:** P1

---

## Módulo 7 — Teleatención / regulación remota

### HU-7.1 Registrar atención telemática
Como **médico AD o regulador (U1)**, necesito registrar una atención clínica realizada a distancia (teléfono o video), para que quede en la ficha clínica con la misma trazabilidad que una visita presencial.

**CA:**
- Tipo de atención: teléfono / video
- Contenido clínico: motivo, evaluación, indicaciones, plan
- Diferenciada visualmente de visita presencial
- Registra duración y medio utilizado

**FHIR:** `Encounter` (class=VR), `Composition`
**Normativa:** DS 1/2022 art. 12-13 (TICs para diagnóstico y tratamiento); REM A30/A32
**Prioridad:** P2

---

## Módulo 8 — Reportería e indicadores

### HU-8.1 Generar REM A21 sección C automáticamente
Como **estadístico DEIS (U13)**, necesito que el sistema genere automáticamente el REM A21 sección C (hospitalización domiciliaria) a partir de los datos operativos del mes, para tributar sin digitación manual.

**CA:**
- Genera las 3 subsecciones:
  - C.1.1: Personas atendidas por sexo, rango etario y origen de derivación
  - C.1.2: Egresos por tipo (alta, reingreso, fallecido esperado/no esperado, renuncia, disciplinaria), días de estada
  - C.1.3: Cupos programados, utilizados, disponibles
- Cumple reglas de consistencia: PE-8, PE-9, PE-10
- personas_atendidas = activas_mes_anterior + ingresos - egresos - fallecidos
- Exportable en formato tributación

**FHIR:** No aplica directamente (es functor F_REM del modelo categorial)
**Normativa:** Manual REM 2026; modelo categorial §4.5 (pushout C_op → C_rem)
**Prioridad:** P0

### HU-8.2 Ver dashboard de indicadores operativos
Como **director/a técnico (U8)** o **jefatura (U14)**, necesito ver un panel con indicadores clave: ocupación, estada promedio, tasa de reingresos, egresos por tipo, visitas por profesional, productividad.

**CA:**
- Indicadores mínimos:
  - Ocupación: cupos utilizados / programados
  - Estada promedio: días_estada / egresos
  - Tasa reingresos: reingresos / egresos totales (meta ≤ 5%)
  - Egresos por tipo (coproducto de 5 variantes)
  - Visitas por tipo de profesional (datos HSC: médico 1.280, enfermera 4.688, kine 3.195, fono 1.279, TS 1.120, TENS 422 en 2024)
- Filtrable por período
- Comparación con metas BIP cuando aplique

**FHIR:** No aplica directamente
**Normativa:** Proyecto implementación HSC; NT 2024
**Prioridad:** P1

---

## Módulo 9 — Gestión de recursos

### HU-9.1 Gestionar inventario de equipamiento e insumos
Como **gestora/coordinadora (U7)**, necesito llevar control del equipamiento médico asignado a pacientes (concentradores O2, bombas infusión, etc.) y del stock de insumos clínicos, para asegurar abastecimiento y trazabilidad.

**CA:**
- Lista de equipos con: tipo, estado (disponible/asignado/en mantención), paciente asignado, fecha próxima mantención
- Alerta de mantención preventiva vencida
- Stock de insumos con alerta de mínimo

**FHIR:** `Device` (status), `SupplyRequest`, `SupplyDelivery`
**Normativa:** DS 1/2022 art. 7-10 (DT: verificar programas preventivos); NT 2024 (equipamiento mínimo)
**Prioridad:** P2

---

## Módulo 10 — Interconsultas y solicitudes

### HU-10.1 Generar solicitud de hospitalización
Como **médico AD (U1)**, necesito generar una solicitud de reingreso hospitalario cuando el paciente se deteriora, compilando el resumen clínico y el motivo de traslado.

**CA:**
- Compone automáticamente desde datos del episodio
- Campos: motivo de reingreso, estado clínico actual, tratamiento vigente, establecimiento destino
- Genera documento exportable
- Registra en ficha clínica

**FHIR:** `ServiceRequest` (intent=order, category=inpatient)
**Normativa:** DS 1/2022 art. 7 (DT: coordinar reingreso); OPM SD1.6 (Reingreso)
**Prioridad:** P1

### HU-10.2 Generar texto de interconsulta
Como **médico AD (U1)**, necesito generar un texto clínico estructurado para interconsulta a especialista, para derivar al paciente con información completa.

**CA:**
- Compone desde datos del episodio: diagnósticos, tratamiento, evolución relevante
- Campo: especialidad destino, pregunta clínica
- Exportable/imprimible

**FHIR:** `ServiceRequest` (intent=order, category=consultation)
**Normativa:** DS 1/2022 art. 12 (coordinar continuidad)
**Prioridad:** P2

---

## Módulo 11 — Portal paciente/cuidador

### HU-11.1 Acceder al sistema (invitación + login)
Como **paciente/cuidador (U16/U17)**, necesito acceder al sistema con email y contraseña para ver la información de mi hospitalización.

**CA:**
- Login con email + password
- Si no tiene cuenta → flujo con código de invitación de un solo uso
- Código enviado por el equipo HODOM, expira a 48h
- Después del login → dashboard principal
- "Olvidé mi contraseña" → reset por email

**FHIR:** `Patient`, `RelatedPerson`
**Normativa:** Ley 20.584 (derecho a acceso a información clínica propia)
**Prioridad:** P0

### HU-11.2 Dashboard del paciente
Como **paciente/cuidador**, necesito ver un resumen de mi estado actual: diagnóstico, visitas próximas, teléfono HODOM.

**CA:**
- Muestra: nombre paciente, diagnóstico, fecha ingreso, días en programa
- Próxima visita programada (fecha + hora + profesional si está asignada)
- Teléfonos de contacto: HODOM, emergencia (SAMU 131, SAPU)
- Indicaciones vigentes (farmacológicas y oxigenoterapia)
- Botones: "Solicitar visita" y "Reportar síntoma"

**FHIR:** `CarePlan`, `Appointment`, `Communication`
**Normativa:** DS 1/2022 art. 22; Ley 20.584
**Prioridad:** P0

### HU-11.3 Ver indicaciones de cuidado
Como **paciente/cuidador**, necesito ver las indicaciones vigentes para seguirlas correctamente.

**CA:**
- Lista de medicamentos activos: nombre, dosis, vía, frecuencia
- Oxigenoterapia: dispositivo, flujo LPM, horas/día
- Curaciones: tipo, frecuencia
- Dietas si aplica
- Botón "Ver documento de emergencia"

**FHIR:** `MedicationRequest`, `NutritionOrder`, `ServiceRequest`
**Normativa:** DS 1/2022 art. 22
**Prioridad:** P0

### HU-11.4 Documento de emergencia descargable
Como **paciente/cuidador**, necesito generar un documento descargable con indicaciones de emergencia para mostrar en urgencia o al cuidador.

**CA:**
- PDF generado con: nombre, RUT, diagnóstico, teléfono HODOM
- Incluye indicaciones activas y signos de alarma
- Muestra teléfonos de contacto: HODOM, SAMU 131, SAPU local
- Horarios de atención HODOM (L-V 08:00-17:00 teléfono, L-D 08:00-19:00 visitas)

**FHIR:** `DocumentReference`, `Communication`
**Normativa:** DS 1/2022 art. 22; PE-14
**Prioridad:** P0

### HU-11.5 Reportar síntoma o solicitar visita
Como **paciente/cuidador**, necesito enviar un mensaje de síntoma o solicitud de visita al equipo HODOM.

**CA:**
- Formulario con: tipo (reporte de síntoma, consulta, solicitud de visita, otro)
- Campo opcional: signo de alarma (sí/no)
- Si signo de alarma = sí → mensaje marcado como urgente + instrucciones inmediatas
- Si no urgente → mensaje normal al equipo (visible en tablero de coordinación)
- Muestra estado del mensaje: Enviado → En proceso → Respondido

**FHIR:** `Communication`, `AppointmentRequest`
**Normativa:** Norma Técnica HODOM art. 9 (seguimiento continuo)
**Prioridad:** P1

### HU-11.6 Historial de visitas
Como **paciente/cuidador**, necesito ver un historial de las visitas realizadas para saber quién vino y cuándo.

**CA:**
- Lista cronológica de visitas: fecha, profesional, tipo de atención
- Filtro por mes
- Visitas completadas y canceladas diferenciadas

**FHIR:** `Encounter`
**Prioridad:** P1

### HU-11.7 Mensajes recibidos del equipo
Como **paciente/cuidador**, necesito ver mensajes del equipo HODOM (respuestas, recordatorios, citaciones).

**CA:**
- Inbox con mensajes del equipo HODOM
- Mensajes nuevos destacados
- Filtro por tipo (respuesta, recordatorio, citación)

**FHIR:** `Communication`
**Prioridad:** P2

> **Nota de implementación:** El portal tiene data model ya creado en la BD existente:
> - `operational.portal_usuario` (cuentas, invitación, OTP)
> - `operational.portal_invitacion` (tokens un uso, 48h)
> - `clinical.portal_mensaje` (consultas del paciente)
> - `operational.portal_acceso_log` (auditoría de accesos)
> - Vistas: `portal.v_mi_episodio`, `portal.v_mis_indicaciones`, `portal.v_mi_documento_emergencia`

---

## Resumen cuantitativo

| Módulo | Historias | P0 | P1 | P2 | P3 |
|--------|----------|----|----|----|----|
| 1. Censo | 3 | 1 | 2 | 0 | 0 |
| 2. Postulación/Ingreso | 6 | 4 | 2 | 0 | 0 |
| 3. Ficha clínica | 6 | 4 | 2 | 0 | 0 |
| 4. Prescripción | 2 | 2 | 0 | 0 | 0 |
| 5. Visitas/Rutas | 3 | 1 | 1 | 1 | 0 |
| 6. Egreso/Continuidad | 4 | 2 | 2 | 0 | 0 |
| 7. Teleatención | 1 | 0 | 0 | 1 | 0 |
| 8. Reportería | 2 | 1 | 1 | 0 | 0 |
| 9. Recursos | 1 | 0 | 0 | 1 | 0 |
| 10. Interconsultas | 2 | 0 | 1 | 1 | 0 |
| 11. Portal paciente | 7 | 4 | 2 | 1 | 0 |
| **TOTAL** | **37** | **19** | **13** | **5** | **0** |

---

## Secuencia de implementación recomendada

### Fase 1 — Núcleo obligatorio (P0)
15 historias que cubren:
- censo de pacientes
- flujo completo de ingreso (postulación → elegibilidad → CI → ingreso formal)
- ficha clínica (ingreso enfermería, signos vitales, narrativa, evolución)
- prescripción
- programación de visitas
- decisión de continuidad/egreso
- egreso formal + epicrisis
- generación automática REM

**Criterio de salida de Fase 1:**
Un episodio completo (ingreso → atención → egreso) puede ejecutarse digitalmente de punta a punta, con REM generado automáticamente.

### Fase 2 — Operativo alto valor (P1)
12 historias que agregan:
- cupos en tiempo real
- briefing matinal
- rechazo fundamentado
- kinesiología y curaciones
- rutas optimizadas
- seguimiento post-egreso
- dashboard indicadores
- solicitud hospitalización
- documento emergencias paciente (ahora en portal paralelo)

### Fase 3 — Complementario (P2)
4 historias:
- teleatención
- ejecución de ruta
- gestión de recursos
- interconsultas

---

## Siguiente paso

Con usuarios y historias de usuario definidas, el siguiente entregable natural es:

### **Arquitectura de información del sistema**
- modelo de datos por módulo
- mapeo FHIR detallado
- flujos de estado
- permisos por rol
- integraciones externas (REM, APS, gestión de camas)

Esto convertiría las historias en un **diseño técnico accionable**.
