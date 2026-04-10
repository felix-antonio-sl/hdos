# Historias de Usuario Exhaustivas — HODOM Hospital de San Carlos
## Versión rehecha con trazabilidad normativa y documental
### Hospital de San Carlos Dr. Benicio Arzola Medina | Servicio de Salud Ñuble | Marzo 2026

---

## 0. Propósito

Este documento rehace y amplía exhaustivamente las historias de usuario de HODOM HSC, integrando de forma explícita:

1. **Manual de Dirección Técnica HD** (`/home/node/knowledge/salud/hodom/director/01-manual-direccion-tecnica.md`)
2. **Normativa HD vigente**:
   - `DS N°1/2022` Reglamento de establecimientos que otorgan prestaciones de hospitalización domiciliaria
   - `Norma Técnica HD 2024` (`DE 31/2024`)
3. **Documentación local HSC**:
   - Protocolo PRO-002 HODOM HSC
   - Proyecto BIP `40059567-0`
   - Presentación **Enlace HODOM–APS / Programa de Postrados**
   - Consentimiento informado 2026
   - Hoja de ingreso de enfermería
   - Hoja de ingreso de kinesiología
   - Registro visita equipo HODOM
   - Registro de enfermería actualizado
   - Registro de curaciones
   - Paquete legacy con datos reales de operación

> **Escala:** establecimiento  
> **Modalidad dominante:** hospital-domicilio-transición  
> **Rol del documento:** base funcional, operativa y digital para rediseño de la unidad y del sistema web HODOM HSC.

---

## 1. Criterios de diseño usados para rehacer las historias

Estas historias se construyen con 5 principios:

1. **Equivalencia hospitalaria real**: HODOM no es atención domiciliaria ambulatoria; debe sostener cuidados equivalentes a hospitalización cerrada según `DS 1/2022`.
2. **Trazabilidad normativa**: toda historia crítica deriva de una exigencia del reglamento, la norma técnica, el manual DT o un formulario/flujo real del HSC.
3. **Continuidad del cuidado**: ingreso hospital/APS → evaluación → hospitalización domiciliaria → rescate/reingreso → egreso → contrarreferencia.
4. **Modo operativo real HSC**: se incorpora lo que efectivamente ya usa la unidad (consentimiento, registros, rutas, entrega de turno, enlace APS, curaciones, evaluación kinésica, etc.).
5. **Preparación para sistema web**: cada historia puede transformarse luego en backlog funcional, módulo, formulario, alerta o flujo.

---

## 2. Alertas de coherencia local detectadas al rehacer

Estas tensiones deben verse como insumos para rediseño, no como errores del documento:

- El consentimiento 2026 informa atención de **08:00 a 19:00**, pero otros documentos operativos hablan de cobertura diferente.
- El consentimiento informa llamada al número HODOM en horario hábil y fuera de eso SAPU/UE/131, lo que obliga a una **historia explícita de comunicación en horario hábil e inhábil**.
- El consentimiento fija una estadía máxima de **6 a 8 días**, pero la lógica clínica real puede requerir duración variable según plan terapéutico. Debe normarse localmente.
- El consentimiento aún menciona contingencia COVID/EPP, lo que sugiere necesidad de **actualización de redacción**.
- El proyecto Enlace APS-HODOM define que HODOM asume algunas prestaciones y APS mantiene otras (ej. curaciones crónicas/cambios de dispositivos), lo que exige **fronteras de responsabilidad explícitas**.
- El paquete legacy demuestra que la cartera real y la complejidad operativa **superan lo descrito en el protocolo original**.

---

## 3. Estructura de historias

Cada historia incluye:
- **Código**
- **Actor**
- **Historia**
- **Valor esperado**
- **Trazabilidad principal**

Convención de trazabilidad:
- **R** = Reglamento `DS 1/2022`
- **NT** = Norma Técnica HD 2024
- **MDT** = Manual de Dirección Técnica
- **HSC** = documentos locales/formularios HSC

---

# EPIC A — DIRECCIÓN TÉCNICA, GOBERNANZA Y CUMPLIMIENTO

## A1. Dirección técnica y sucesión

- **HU-DT-01** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero contar con una designación formal, jornada informada y respaldo documental de mis requisitos habilitantes, para ejercer válidamente la conducción técnica de la unidad.  
  **Valor:** continuidad legal y sanitaria del servicio.  
  **Trazabilidad:** R arts. 7-10; NT personal; MDT cap. 3.

- **HU-DT-02** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero mantener acreditados mi título de médico cirujano, experiencia clínica, formación en gestión e IAAS vigente, para cumplir la exigencia regulatoria del cargo.  
  **Valor:** fiscalización favorable SEREMI.  
  **Trazabilidad:** NT; MDT 3.1.

- **HU-DT-03** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero registrar y comunicar a SEREMI cualquier cambio de titularidad o reemplazo temporal, para mantener la autorización sanitaria sin observaciones.  
  **Valor:** continuidad regulatoria.  
  **Trazabilidad:** R arts. 9-10; MDT 3.4.

- **HU-DT-04** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero disponer de un reemplazante formal que cumpla requisitos mínimos, para asegurar continuidad técnica en vacaciones, licencias o ausencias.  
  **Valor:** continuidad operativa y legal.  
  **Trazabilidad:** R art. 10; MDT 3.4.

- **HU-DT-05** — **Actor:** Dirección Hospitalaria  
  **Historia:** Como dirección del HSC, quiero que la unidad tenga una gobernanza explícita con Dirección Técnica, Coordinación y roles clínicos definidos, para evitar ambigüedades en la toma de decisiones.  
  **Valor:** mando claro y seguridad organizacional.  
  **Trazabilidad:** R art. 11; NT; MDT cap. 4.

## A2. Manuales, protocolos y documentos obligatorios

- **HU-DT-06** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero aprobar y mantener actualizados el Manual de Organización Interna, protocolos clínicos y manuales de procedimientos, para asegurar que la unidad opere con reglas explícitas y vigentes.  
  **Valor:** operación homogénea y trazable.  
  **Trazabilidad:** R art. 8; NT registros/protocolos; MDT cap. 8.

- **HU-DT-07** — **Actor:** Coordinación HODOM  
  **Historia:** Como coordinación, quiero disponer de una matriz maestra de documentos vigentes con versión, fecha, aprobador y próxima revisión, para evitar uso de formularios obsoletos.  
  **Valor:** control documental.  
  **Trazabilidad:** MDT cap. 3, 4 y 8; HSC formularios 2026.

- **HU-DT-08** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero asegurar que exista protocolo formal de ingreso, egreso, fallecimiento, rutas, visitas, emergencias, agresiones, REAS, IAAS y dispositivos invasivos, para cumplir el estándar de una hospitalización cerrada fuera del hospital.  
  **Valor:** seguridad integral.  
  **Trazabilidad:** NT protocolos; MDT caps. 6, 8, 9.

- **HU-DT-09** — **Actor:** Calidad/OCSP  
  **Historia:** Como referente de calidad, quiero auditar que cada documento obligatorio exista, esté aprobado y sea usado en terreno, para reducir brechas normativas invisibles.  
  **Valor:** preparación para fiscalización y mejora continua.  
  **Trazabilidad:** R art. 8; NT; MDT.

## A3. Autorización sanitaria y fiscalización

- **HU-DT-10** — **Actor:** Director Técnico  
  **Historia:** Como Director Técnico, quiero mantener disponible la carpeta SEREMI con antecedentes de autorización, personal, infraestructura, equipamiento, turnos, botiquín y residuos, para responder de inmediato a fiscalizaciones.  
  **Valor:** cumplimiento sanitario.  
  **Trazabilidad:** R arts. 4-6, 18-25; MDT 1.3.

- **HU-DT-11** — **Actor:** Administrativo HODOM  
  **Historia:** Como administrativo, quiero centralizar en formato físico o digital seguro toda la evidencia exigible por fiscalización, para disminuir dependencia de memoria individual.  
  **Valor:** resiliencia documental.  
  **Trazabilidad:** R arts. 4-6, 14, 23; MDT 5.1 y 7.1.

- **HU-DT-12** — **Actor:** Dirección Hospitalaria  
  **Historia:** Como dirección del hospital, quiero saber qué exigencias ya están cubiertas por la autorización matriz del establecimiento y cuáles requieren evidencia específica de HODOM, para no asumir coberturas no acreditadas.  
  **Valor:** precisión regulatoria.  
  **Trazabilidad:** R arts. 4-6; MDT 1.3.

---

# EPIC B — RECURSOS HUMANOS, HABILITACIÓN E INDUCCIÓN

## B1. Perfiles y habilitación

- **HU-RH-01** — **Actor:** RRHH HSC  
  **Historia:** Como RRHH, quiero mantener listado actualizado de todo el personal HODOM con profesión, experiencia, certificados y vigencias, para cumplir requerimientos regulatorios y de fiscalización.  
  **Valor:** control de dotación habilitada.  
  **Trazabilidad:** R art. 14; NT personal; MDT 4.5.

- **HU-RH-02** — **Actor:** RRHH HSC  
  **Historia:** Como RRHH, quiero validar que ningún funcionario inicie funciones sin habilitación comprobada, para evitar operación con personal no acreditado.  
  **Valor:** seguridad legal y clínica.  
  **Trazabilidad:** MDT 4.5.

- **HU-RH-03** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero asignar funciones solo a personal con perfil compatible con las prestaciones declaradas, para no sobreextender competencias en domicilio.  
  **Valor:** seguridad del paciente.  
  **Trazabilidad:** R arts. 11-14; NT; MDT 4.2.

- **HU-RH-04** — **Actor:** RRHH / DT  
  **Historia:** Como responsable de contratación, quiero asegurar cursos vigentes de IAAS, RCP básica y uso de desfibrilador según el rol, para cumplir exigencias mínimas del cargo.  
  **Valor:** preparación clínica y regulatoria.  
  **Trazabilidad:** NT; MDT 4.2 y 4.4.

- **HU-RH-05** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero definir si HODOM HSC declara o no cartera pediátrica o psiquiátrica, para no asumir prestaciones que exijan especialistas no disponibles.  
  **Valor:** coherencia entre oferta y dotación.  
  **Trazabilidad:** NT personal; R arts. 12-14.

## B2. Inducción y capacitación

- **HU-RH-06** — **Actor:** Coordinación HODOM  
  **Historia:** Como coordinación, quiero implementar una inducción formal de al menos 44 horas para todo el personal nuevo, para asegurar homogeneidad técnica y cultural antes de salir a terreno.  
  **Valor:** reducción de variabilidad.  
  **Trazabilidad:** NT; MDT 4.3.

- **HU-RH-07** — **Actor:** Coordinación HODOM  
  **Historia:** Como coordinación, quiero que la inducción incluya normativa HD, ficha clínica, seguridad del personal, REAS, IAAS, rutas, dispositivos y respuesta a urgencias, para preparar al equipo para la realidad domiciliaria.  
  **Valor:** habilitación operativa integral.  
  **Trazabilidad:** MDT 4.3.

- **HU-RH-08** — **Actor:** Director Técnico  
  **Historia:** Como DT, quiero aprobar un Plan Anual de Capacitación (PAC) con recertificación oportuna de IAAS y RCP, para no tener certificaciones vencidas en roles críticos.  
  **Valor:** continuidad de competencias.  
  **Trazabilidad:** R art. 8; NT; MDT 4.4.

- **HU-RH-09** — **Actor:** Gestión de Personas  
  **Historia:** Como Gestión de Personas, quiero mantener la evidencia firmada de inducción y capacitación en la hoja de vida de cada funcionario, para responder a auditorías y fiscalizaciones.  
  **Valor:** trazabilidad formativa.  
  **Trazabilidad:** NT; MDT 4.3-4.5.

- **HU-RH-10** — **Actor:** Equipo clínico  
  **Historia:** Como miembro del equipo clínico, quiero recibir simulaciones periódicas de emergencia, agresión y rescate, para no improvisar en eventos de alto riesgo.  
  **Valor:** seguridad operativa.  
  **Trazabilidad:** MDT 9.3 y 9.4.

---

# EPIC C — ADMISIÓN, ELEGIBILIDAD Y PRIORIZACIÓN

## C1. Captación hospitalaria y APS

- **HU-AD-01** — **Actor:** Médico tratante hospitalario  
  **Historia:** Como médico tratante, quiero conocer criterios de derivación a HODOM, para identificar tempranamente pacientes que requieren cama hospitalaria pero son tratables en domicilio.  
  **Valor:** descongestión y pertinencia clínica.  
  **Trazabilidad:** R arts. 1-3 y 15; HSC PRO-002.

- **HU-AD-02** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero hacer búsqueda activa en Medicina, Urgencia, Cirugía y Traumatología, para captar pacientes elegibles antes de que se cronifique la espera de cama.  
  **Valor:** mayor impacto sobre oportunidad hospitalaria.  
  **Trazabilidad:** HSC proyecto BIP; datos legacy; MDT 6.1.

- **HU-AD-03** — **Actor:** APS / Programa Postrados  
  **Historia:** Como equipo APS, quiero derivar pacientes agudos seleccionados a HODOM mediante informe médico resumido y datos mínimos de contacto, para evitar derivaciones innecesarias a urgencia.  
  **Valor:** admission avoidance.  
  **Trazabilidad:** HSC Enlace APS-HODOM.

- **HU-AD-04** — **Actor:** Enfermera coordinadora  
  **Historia:** Como enfermera coordinadora, quiero verificar cupo, ruta y factibilidad territorial antes de aceptar una derivación APS u hospitalaria, para no comprometer continuidad con una admisión inviable.  
  **Valor:** seguridad operacional.  
  **Trazabilidad:** HSC Enlace APS-HODOM; MDT 6.3.

## C2. Requisitos de ingreso

- **HU-AD-05** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero confirmar que el paciente tenga patología aguda o crónica reagudizada, condición clínica estable, indicación médica y plan terapéutico integral, para validar ingreso conforme al reglamento.  
  **Valor:** pertinencia de la modalidad.  
  **Trazabilidad:** R art. 15; NT definiciones; MDT 6.1.

- **HU-AD-06** — **Actor:** Trabajadora social / enfermería  
  **Historia:** Como evaluadora de ingreso, quiero verificar condiciones sanitarias básicas, servicios, acceso, telefonía y red de apoyo, para asegurar que el domicilio sea un entorno asistencial seguro.  
  **Valor:** seguridad no clínica.  
  **Trazabilidad:** R art. 15; MDT 6.1.

- **HU-AD-07** — **Actor:** Trabajadora social  
  **Historia:** Como trabajadora social, quiero verificar la existencia real de cuidador o tutor responsable, para no ingresar pacientes que queden sin soporte en domicilio.  
  **Valor:** continuidad y seguridad del cuidado.  
  **Trazabilidad:** R art. 15; R art. 13; MDT 6.1.

- **HU-AD-08** — **Actor:** Enfermería HODOM  
  **Historia:** Como enfermería HODOM, quiero aplicar un checklist de ingreso que incluya consentimiento, educación, medicamentos despachados, familiar presente, interconsultas pendientes, invasivos y lesiones de piel, para estandarizar la admisión domiciliaria.  
  **Valor:** ingreso seguro y completo.  
  **Trazabilidad:** HSC Hoja ingreso enfermería; MDT 6.1 y 7.

- **HU-AD-09** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero evaluar al ingreso funcionalidad previa, dependencia motora/respiratoria, Barthel y requerimientos de asistencia, para dimensionar correctamente el plan de rehabilitación y la carga familiar.  
  **Valor:** adecuación terapéutica.  
  **Trazabilidad:** HSC Hoja ingreso kinesiología.

- **HU-AD-10** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero que la admisión incluya un número único de postulación/episodio, para asegurar trazabilidad del caso desde ingreso a egreso.  
  **Valor:** continuidad documental.  
  **Trazabilidad:** HSC Hoja ingreso enfermería; datos legacy.

## C3. Exclusión y rechazo

- **HU-AD-11** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero rechazar pacientes con inestabilidad hemodinámica, necesidad de soporte vital avanzado o diagnóstico no establecido, para no usar HODOM fuera de su ámbito seguro.  
  **Valor:** seguridad clínica.  
  **Trazabilidad:** R art. 17; MDT 6.2.

- **HU-AD-12** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero rechazar ingresos cuando el domicilio no tenga condiciones mínimas o no exista red de apoyo responsable, para evitar hospitalizaciones domiciliarias inviable.  
  **Valor:** prevención de daño.  
  **Trazabilidad:** R arts. 15 y 17; MDT 6.2.

- **HU-AD-13** — **Actor:** Médico tratante derivador  
  **Historia:** Como derivador, quiero recibir motivo explícito de rechazo y recomendación alternativa, para mejorar futuras derivaciones y no dejar al paciente sin continuidad.  
  **Valor:** aprendizaje y seguridad.  
  **Trazabilidad:** MDT 6.2; HSC operación real.

- **HU-AD-14** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero que exista checklist de exclusión firmado por el evaluador, para defender técnicamente cada no ingreso ante reclamos o auditorías.  
  **Valor:** trazabilidad decisional.  
  **Trazabilidad:** MDT 6.2.

---

# EPIC D — CONSENTIMIENTO, DERECHOS Y EXPERIENCIA DEL USUARIO

## D1. Consentimiento informado

- **HU-CI-01** — **Actor:** Paciente / representante  
  **Historia:** Como paciente o representante, quiero recibir explicación clara de qué es HODOM y por qué soy elegible, para consentir de forma informada y no meramente formal.  
  **Valor:** autonomía y confianza.  
  **Trazabilidad:** Ley 20.584; R art. 15; HSC CI 2026.

- **HU-CI-02** — **Actor:** Paciente / representante  
  **Historia:** Como paciente o representante, quiero conocer horario de visitas, alcances del equipo, teléfonos de contacto y conducta ante urgencia, para saber cómo usar la unidad correctamente.  
  **Valor:** uso seguro del servicio.  
  **Trazabilidad:** HSC CI 2026; MDT 7.3.

- **HU-CI-03** — **Actor:** Paciente / representante  
  **Historia:** Como paciente o representante, quiero poder aceptar o rechazar la hospitalización domiciliaria dejando constancia formal, para resguardar mi derecho de decisión.  
  **Valor:** autonomía protegida.  
  **Trazabilidad:** Ley 20.584; HSC CI 2026; MDT 7.3.

- **HU-CI-04** — **Actor:** Enfermería / trabajo social  
  **Historia:** Como profesional que aplica el consentimiento, quiero verificar comprensión real de riesgos, límites y responsabilidades del cuidado domiciliario, para evitar consentimiento aparente pero no comprendido.  
  **Valor:** consentimiento válido.  
  **Trazabilidad:** Ley 20.584; MDT 7.3.

- **HU-CI-05** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero actualizar el consentimiento informado para reflejar el modelo operativo vigente, eliminar redacciones desfasadas y precisar canales de urgencia, para reducir ambigüedades médico-legales.  
  **Valor:** coherencia documental.  
  **Trazabilidad:** HSC CI 2026; MDT 7.3.

## D2. Derechos, privacidad y trato

- **HU-CI-06** — **Actor:** Paciente  
  **Historia:** Como paciente, quiero que se me entregue la Carta de Derechos y Deberes y la vía formal de reclamo, para conocer mis garantías durante el episodio HODOM.  
  **Valor:** transparencia institucional.  
  **Trazabilidad:** Ley 20.584; R art. 24; MDT 7.3.

- **HU-CI-07** — **Actor:** Paciente / familia  
  **Historia:** Como paciente o familia, quiero saber cuándo y con qué finalidad pueden usarse registros audiovisuales asociados a mi atención, para que se resguarde la confidencialidad y finalidad clínica.  
  **Valor:** protección de datos sensibles.  
  **Trazabilidad:** HSC CI 2026; Ley 19.628; MDT 1.2.

- **HU-CI-08** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero normas explícitas de privacidad para registros clínicos, llamados, fotos clínicas y documentos compartidos, para evitar uso indebido de datos sensibles.  
  **Valor:** resguardo legal y ético.  
  **Trazabilidad:** R art. 23; NT; MDT 1.2 y 7.1.

- **HU-CI-09** — **Actor:** Usuario  
  **Historia:** Como usuario, quiero una atención respetuosa de mi hogar, mi intimidad, mi cultura familiar y mis tiempos, para vivir la hospitalización como cuidado y no como intrusión.  
  **Valor:** experiencia humanizada.  
  **Trazabilidad:** Ley 20.584; NT humanización; HSC satisfacción usuaria.

- **HU-CI-10** — **Actor:** Calidad  
  **Historia:** Como calidad, quiero medir trato, oportunidad, claridad y respeto de intimidad en la encuesta de satisfacción al egreso, para monitorear experiencia usuaria de forma estructurada.  
  **Valor:** mejora continua centrada en el usuario.  
  **Trazabilidad:** R arts. 24-25; MDT 7.4.

---

# EPIC E — PACIENTE, CUIDADOR Y SOPORTE FAMILIAR

## E1. Preparación del cuidador

- **HU-PC-01** — **Actor:** Cuidador responsable  
  **Historia:** Como cuidador, quiero saber exactamente qué responsabilidades asumo y cuáles siguen siendo del equipo clínico, para no cargar con tareas clínicas impropias.  
  **Valor:** seguridad y confianza.  
  **Trazabilidad:** R art. 15; HSC CI 2026; MDT 6.1.

- **HU-PC-02** — **Actor:** Cuidador responsable  
  **Historia:** Como cuidador, quiero recibir educación de bienvenida HODOM y signos de alarma por escrito y verbalmente, para actuar adecuadamente entre visitas.  
  **Valor:** detección precoz de descompensación.  
  **Trazabilidad:** HSC ingreso enfermería; MDT 7.2.

- **HU-PC-03** — **Actor:** Cuidador responsable  
  **Historia:** Como cuidador, quiero conocer el plan diario de visitas y el profesional esperado, para organizar disponibilidad y apoyar la atención.  
  **Valor:** coordinación real del cuidado.  
  **Trazabilidad:** HSC rutas/entrega de turno; MDT 6.3.

- **HU-PC-04** — **Actor:** Trabajo social  
  **Historia:** Como trabajadora social, quiero evaluar sobrecarga, capacidad, condiciones del hogar y situación económica del cuidador, para anticipar riesgos de fracaso del cuidado domiciliario.  
  **Valor:** sostén del episodio y equidad.  
  **Trazabilidad:** R art. 13; MDT 4.2; HSC realidad local.

## E2. Educación y continuidad

- **HU-PC-05** — **Actor:** Cuidador  
  **Historia:** Como cuidador, quiero educación sobre administración de medicamentos, movilización, prevención de caídas, lesiones por presión y uso de dispositivos, para colaborar sin producir daño.  
  **Valor:** autocuidado asistido seguro.  
  **Trazabilidad:** R art. 13; HSC ingreso enfermería; HSC hoja kinesio; MDT 8.

- **HU-PC-06** — **Actor:** Cuidador  
  **Historia:** Como cuidador, quiero saber qué hacer ante ausencia del equipo, empeoramiento clínico o urgencia nocturna, para no depender de instrucciones informales.  
  **Valor:** respuesta oportuna.  
  **Trazabilidad:** HSC CI 2026; MDT 9.3.

- **HU-PC-07** — **Actor:** Cuidador  
  **Historia:** Como cuidador, quiero recibir al alta un plan resumido de continuidad, controles y señales de alarma, para disminuir reconsultas evitables y errores post-egreso.  
  **Valor:** continuidad hospital-APS.  
  **Trazabilidad:** R art. 24; MDT 7.2 y 6.4.

---

# EPIC F — MÉDICO DE ATENCIÓN DIRECTA Y REGULACIÓN

## F1. Evaluación, ingreso y plan médico

- **HU-MD-01** — **Actor:** Médico atención directa  
  **Historia:** Como médico HODOM, quiero evaluar personalmente la estabilidad clínica y la indicación de ingreso, para sostener el juicio médico que habilita la modalidad.  
  **Valor:** pertinencia clínica.  
  **Trazabilidad:** R arts. 1-3, 12 y 15; MDT 6.1.

- **HU-MD-02** — **Actor:** Médico atención directa  
  **Historia:** Como médico HODOM, quiero dejar diagnóstico, plan terapéutico, riesgos y condiciones de rescate claramente documentados al ingreso, para que todo el equipo opere sobre una base común.  
  **Valor:** alineación clínica.  
  **Trazabilidad:** R arts. 1-3; MDT 7.1-7.2.

- **HU-MD-03** — **Actor:** Médico atención directa  
  **Historia:** Como médico HODOM, quiero poder ajustar tratamiento, solicitar exámenes y coordinar imagenología durante el episodio, para sostener una hospitalización resolutiva y no meramente observacional.  
  **Valor:** resolutividad clínica.  
  **Trazabilidad:** R art. 12; HSC Enlace APS-HODOM; HSC legacy.

- **HU-MD-04** — **Actor:** Médico regulador / atención directa  
  **Historia:** Como médico regulador, quiero recibir llamadas, orientar a distancia y activar rescate o reingreso cuando corresponda, para dar continuidad clínica fuera de la visita presencial.  
  **Valor:** contención del riesgo.  
  **Trazabilidad:** R arts. 12 y 19; MDT 9.3.

## F2. Comunicación y continuidad

- **HU-MD-05** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero coordinarme con servicios derivadores y APS al ingreso y al alta, para evitar episodios aislados sin continuidad de responsabilidad.  
  **Valor:** continuidad del cuidado.  
  **Trazabilidad:** R art. 8; R art. 12; MDT 6.4.

- **HU-MD-06** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero definir formalmente reingreso hospitalario cuando el paciente pierde condición clínica estable, para no retrasar rescate por exceso de optimismo domiciliario.  
  **Valor:** seguridad del paciente.  
  **Trazabilidad:** R art. 16; MDT 6.4 y 9.3.

- **HU-MD-07** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero emitir epicrisis médica al alta con diagnóstico, terapias realizadas, evolución y continuidad indicada, para entregar el caso de forma segura a la red.  
  **Valor:** cierre clínico correcto.  
  **Trazabilidad:** R art. 24; MDT 6.4 y 7.1.

- **HU-MD-08** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero documentar criterios y decisiones de adecuación del esfuerzo terapéutico cuando corresponda, para sostener una indicación alineada con el estado clínico y el contexto familiar.  
  **Valor:** calidad clínica y ética.  
  **Trazabilidad:** R art. 15; MDT 6.1.

---

# EPIC G — ENFERMERÍA CLÍNICA Y COORDINACIÓN DE CUIDADOS

## G1. Ingreso de enfermería

- **HU-ENF-01** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero registrar al ingreso nombre, RUT, dirección, edad, alergias, CESFAM, diagnóstico, Barthel, familiar responsable y teléfonos, para contar con una base clínica y operativa completa.  
  **Valor:** seguridad y trazabilidad.  
  **Trazabilidad:** HSC ingreso enfermería.

- **HU-ENF-02** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero dejar documentados antecedentes mórbidos, quirúrgicos, medicamentos crónicos e historia de ingreso, para contextualizar riesgos y cuidados.  
  **Valor:** continuidad clínica.  
  **Trazabilidad:** HSC ingreso enfermería.

- **HU-ENF-03** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero realizar examen físico estructurado y diagnóstico de enfermería al ingreso, para construir un plan de atención individualizado.  
  **Valor:** cuidado planificado.  
  **Trazabilidad:** HSC ingreso enfermería; R art. 13.

- **HU-ENF-04** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero verificar si el paciente es portador de SNG, CVC, PICC, ostomías, CUP, VVP u otros invasivos, para anticipar insumos, vigilancia y riesgo infeccioso.  
  **Valor:** seguridad del procedimiento.  
  **Trazabilidad:** HSC ingreso enfermería; MDT 8.1.

- **HU-ENF-05** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero identificar lesiones de piel, LPP, pie diabético o heridas operatorias desde el ingreso, para no perder línea base ni subestimar riesgos.  
  **Valor:** prevención de daño y continuidad.  
  **Trazabilidad:** HSC ingreso enfermería; HSC registro curaciones.

## G2. Ejecución y seguimiento de cuidados

- **HU-ENF-06** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero registrar en cada atención la evolución, medicamentos administrados, dilución, vía, número de dosis y plan de enfermería, para mantener continuidad segura entre turnos.  
  **Valor:** trazabilidad del tratamiento.  
  **Trazabilidad:** HSC registro enfermería actualizado.

- **HU-ENF-07** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero registrar fecha de instalación, cambio y signos de infección o flebitis de cada invasivo, para detectar tempranamente complicaciones.  
  **Valor:** prevención de IAAS.  
  **Trazabilidad:** HSC registro enfermería; MDT 8.1 y 9.1.

- **HU-ENF-08** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero monitorear signos vitales, estado de conciencia, dolor, edema, diuresis y observaciones de visita, para evaluar evolución y necesidad de escalamiento.  
  **Valor:** vigilancia clínica domiciliaria.  
  **Trazabilidad:** HSC registro visita equipo; MDT 8.4.

- **HU-ENF-09** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero administrar tratamientos endovenosos, subcutáneos o intramusculares con trazabilidad completa, para sostener equivalencia con hospitalización cerrada.  
  **Valor:** seguridad terapéutica.  
  **Trazabilidad:** R art. 13; MDT 8.2; HSC legacy prestaciones.

- **HU-ENF-10** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero educar al paciente y cuidador en el plan terapéutico y autocuidado, para disminuir errores entre visitas.  
  **Valor:** adherencia y seguridad.  
  **Trazabilidad:** R art. 13; NT; HSC checklist de ingreso.

## G3. Curaciones y lesiones

- **HU-ENF-11** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero registrar en formato estructurado fecha, lugar, grado, exudado, tipo de tejido, tamaño, apósitos y observaciones de cada curación, para medir evolución de heridas.  
  **Valor:** seguimiento objetivo.  
  **Trazabilidad:** HSC registro curaciones.

- **HU-ENF-12** — **Actor:** Enfermera clínica  
  **Historia:** Como enfermera clínica, quiero distinguir curación simple de curación avanzada y asociarla al plan terapéutico, para gestionar insumos y frecuencia correctamente.  
  **Valor:** pertinencia de recursos.  
  **Trazabilidad:** HSC curaciones; HSC legacy prestaciones.

- **HU-ENF-13** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero identificar pacientes con lesiones complejas que requieran continuidad compartida con APS u otros dispositivos, para no romper el hilo del cuidado al alta.  
  **Valor:** continuidad asistencial.  
  **Trazabilidad:** HSC Enlace APS-HODOM; MDT 6.4.

## G4. Coordinación de enfermería

- **HU-ENF-14** — **Actor:** Enfermera coordinadora  
  **Historia:** Como enfermera coordinadora, quiero organizar rutas, cupos, agenda diaria y distribución de profesionales, para asegurar continuidad con el menor tiempo ocioso y menor riesgo operativo.  
  **Valor:** eficiencia segura.  
  **Trazabilidad:** MDT 6.3; HSC rutas; HSC programación.

- **HU-ENF-15** — **Actor:** Enfermera coordinadora  
  **Historia:** Como enfermera coordinadora, quiero articular farmacia, laboratorio, imagenología, APS y SAMU, para que la unidad no dependa de gestiones informales persona a persona.  
  **Valor:** confiabilidad del sistema.  
  **Trazabilidad:** R art. 8; R art. 11; HSC operación real.

---

# EPIC H — KINESIOLOGÍA, FONOAUDIOLOGÍA, TENS Y TRABAJO SOCIAL

## H1. Kinesiología

- **HU-KIN-01** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero evaluar consciencia, PA, FR, FC, saturación, litros de O2, Barthel, tiempo de reposo, fármacos y asistencias al ingreso, para estimar riesgo y plan terapéutico real.  
  **Valor:** evaluación funcional y respiratoria completa.  
  **Trazabilidad:** HSC hoja ingreso kinesiología.

- **HU-KIN-02** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero clasificar dependencia kinésica motora y respiratoria de ingreso, para priorizar intensidad y frecuencia de visitas.  
  **Valor:** asignación adecuada de recursos.  
  **Trazabilidad:** HSC hoja ingreso kinesiología.

- **HU-KIN-03** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero definir objetivos y observaciones explícitas en cada caso, para que el resto del equipo comprenda el foco de la intervención.  
  **Valor:** coherencia interdisciplinaria.  
  **Trazabilidad:** HSC hoja ingreso kinesiología.

- **HU-KIN-04** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero intervenir en terapia motora y respiratoria de pacientes con neumonía, EPOC, inmovilidad o post-ACV, para acelerar recuperación funcional y prevenir complicaciones.  
  **Valor:** resolutividad clínica.  
  **Trazabilidad:** R art. 13; HSC legacy prestaciones.

- **HU-KIN-05** — **Actor:** Kinesiólogo  
  **Historia:** Como kinesiólogo, quiero participar en evaluación de habitabilidad y seguridad del domicilio cuando existan requerimientos respiratorios o de equipamiento, para evitar altas inseguras.  
  **Valor:** seguridad contextual.  
  **Trazabilidad:** correo O2 domiciliario; MDT 6.1.

## H2. Fonoaudiología

- **HU-FON-01** — **Actor:** Fonoaudióloga  
  **Historia:** Como fonoaudióloga, quiero evaluar deglución, lenguaje, voz y cognición de pacientes neurológicos o frágiles, para prevenir aspiración y deterioro funcional.  
  **Valor:** continuidad rehabilitadora.  
  **Trazabilidad:** HSC legacy prestaciones; HSC cartera real.

- **HU-FON-02** — **Actor:** Fonoaudióloga  
  **Historia:** Como fonoaudióloga, quiero educar al cuidador sobre consistencias, postura y signos de aspiración, para sostener seguridad alimentaria entre visitas.  
  **Valor:** prevención de neumonía aspirativa.  
  **Trazabilidad:** HSC operación; continuidad clínica.

## H3. TENS

- **HU-TENS-01** — **Actor:** TENS  
  **Historia:** Como TENS, quiero ejecutar controles y tareas definidas por enfermería clínica dentro de mi competencia, para apoyar el plan terapéutico sin exceder funciones.  
  **Valor:** cuidado seguro y eficiente.  
  **Trazabilidad:** R art. 13; NT personal.

- **HU-TENS-02** — **Actor:** TENS  
  **Historia:** Como TENS, quiero registrar signos vitales y observaciones relevantes con el mismo estándar en todos los turnos, para favorecer continuidad del cuidado.  
  **Valor:** vigilancia consistente.  
  **Trazabilidad:** HSC registro visita equipo; MDT 8.4.

## H4. Trabajo social

- **HU-TS-01** — **Actor:** Trabajadora social  
  **Historia:** Como trabajadora social, quiero elaborar diagnóstico social del hogar, acceso a telefonía, servicios básicos, accesos viales y situación económica, para fundamentar ingreso y plan de soporte.  
  **Valor:** modalidad ajustada a realidad social.  
  **Trazabilidad:** R art. 13; MDT 4.2.

- **HU-TS-02** — **Actor:** Trabajadora social  
  **Historia:** Como trabajadora social, quiero documentar y seguir la intervención social durante el episodio, para no reducir mi rol solo al preingreso.  
  **Valor:** continuidad social del cuidado.  
  **Trazabilidad:** R art. 13; MDT 4.2.

- **HU-TS-03** — **Actor:** Trabajadora social  
  **Historia:** Como trabajadora social, quiero coordinar redes municipales, APS y apoyos territoriales para pacientes vulnerables, para evitar que el alta fracase por causas sociales.  
  **Valor:** continuidad post-egreso.  
  **Trazabilidad:** R art. 13; HSC contexto territorial.

---

# EPIC I — REGISTROS CLÍNICOS, FICHA, RESUMEN DOMICILIARIO Y DATOS

## I1. Ficha clínica y episodio

- **HU-REG-01** — **Actor:** Equipo clínico  
  **Historia:** Como equipo clínico, quiero una ficha clínica física o electrónica única por episodio HODOM, para concentrar la información de ingreso, evolución, prestaciones y egreso.  
  **Valor:** continuidad y seguridad documental.  
  **Trazabilidad:** R art. 24; NT ficha clínica; MDT 7.1; legacy.

- **HU-REG-02** — **Actor:** Equipo clínico  
  **Historia:** Como equipo clínico, quiero registrar cada visita domiciliaria con signos vitales, intervenciones y respuesta clínica, para que cualquier integrante del equipo comprenda el estado actual del paciente.  
  **Valor:** continuidad intradisciplinaria.  
  **Trazabilidad:** MDT 7.1 y 8.4; HSC registro visita equipo.

- **HU-REG-03** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero que los formularios capturen campos estructurados y no solo texto libre, para producir indicadores reales y disminuir ambigüedad clínica.  
  **Valor:** gestión basada en datos.  
  **Trazabilidad:** legacy; HSC formularios.

- **HU-REG-04** — **Actor:** Administrativo / TI  
  **Historia:** Como responsable de datos, quiero asociar a cada episodio un identificador único, fechas clave y profesional responsable, para calcular reingresos, estada, ocupación y carga asistencial con precisión.  
  **Valor:** analítica fiable.  
  **Trazabilidad:** datos legacy; HSC ingreso enfermería.

## I2. Resumen clínico en domicilio

- **HU-REG-05** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero dejar en el domicilio un resumen clínico actualizado con diagnósticos, tratamientos, evolución, cuidados y signos de alarma, para facilitar continuidad por familia y equipos externos.  
  **Valor:** seguridad en urgencias y continuidad.  
  **Trazabilidad:** NT; MDT 7.2.

- **HU-REG-06** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero actualizar ese resumen al final de cada visita relevante, para que no exista divergencia entre domicilio y ficha principal.  
  **Valor:** consistencia de la información.  
  **Trazabilidad:** MDT 7.2 y 8.4.

## I3. Llamados y comunicaciones

- **HU-REG-07** — **Actor:** Base administrativa  
  **Historia:** Como base administrativa, quiero registrar llamadas con fecha, hora, quién llama, quién responde y a quién se deriva, para dar trazabilidad a urgencias y orientación telefónica.  
  **Valor:** seguridad y defensa médico-legal.  
  **Trazabilidad:** R art. 19; MDT 5.1.

- **HU-REG-08** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero que exista protocolo de comunicación en horario hábil e inhábil coherente con lo informado al usuario, para no dejar zonas grises de responsabilidad.  
  **Valor:** claridad operacional.  
  **Trazabilidad:** HSC CI 2026; MDT 9.3.

## I4. Confidencialidad y acceso

- **HU-REG-09** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero definir accesos restringidos a información clínica según rol, para cumplir con la confidencialidad de datos sensibles.  
  **Valor:** protección legal y ética.  
  **Trazabilidad:** R art. 23; Ley 19.628; MDT 1.2 y 7.1.

- **HU-REG-10** — **Actor:** Calidad / TI  
  **Historia:** Como calidad/TI, quiero asegurar resguardo físico o informático seguro de fichas, protocolos y archivos sensibles, para reducir pérdidas, accesos indebidos o fragmentación documental.  
  **Valor:** integridad de registros.  
  **Trazabilidad:** R arts. 19 y 23; MDT 5.1 y 7.1.

---

# EPIC J — LOGÍSTICA, RUTAS, FLOTA, INSUMOS Y SOPORTE CLÍNICO

## J1. Programación de rutas

- **HU-LOG-01** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero programar rutas y visitas por profesional considerando distancia, simultaneidad, complejidad y equipamiento requerido, para usar cupos y tiempo de forma segura.  
  **Valor:** eficiencia operativa real.  
  **Trazabilidad:** MDT 6.3; HSC rutas/programaciones.

- **HU-LOG-02** — **Actor:** Conductor / coordinación  
  **Historia:** Como conductor, quiero recibir ruta diaria validada con orden de visitas, pacientes y observaciones críticas, para evitar errores de desplazamiento y retrasos.  
  **Valor:** puntualidad y seguridad.  
  **Trazabilidad:** HSC rutas; MDT 5.4.

- **HU-LOG-03** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero verificar que ningún equipo salga a terreno sin monitorización mínima obligatoria y equipamiento declarado, para no exponer al paciente a una visita insuficiente.  
  **Valor:** equivalencia hospitalaria mínima.  
  **Trazabilidad:** NT equipamiento; MDT 5.3 y 6.3.

## J2. Vehículos y transporte

- **HU-LOG-04** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero checklists diarios de vehículos, equipos, radiocomunicación y cadena de frío cuando corresponda, para asegurar trazabilidad logística.  
  **Valor:** seguridad de salida a terreno.  
  **Trazabilidad:** MDT 5.3 y 5.4.

- **HU-LOG-05** — **Actor:** Conductores  
  **Historia:** Como conductores, quiero contar con vehículos mantenidos, estacionamiento o detención transitoria segura y medios de comunicación permanente, para trasladar personal y equipos sin comprometer la atención.  
  **Valor:** continuidad operativa.  
  **Trazabilidad:** R art. 19; MDT 5.4.

## J3. Farmacia, insumos y cadena de frío

- **HU-LOG-06** — **Actor:** Enfermera coordinadora / farmacia  
  **Historia:** Como responsable de abastecimiento, quiero trazabilidad de despacho de medicamentos e insumos desde farmacia o botiquín hasta el domicilio, para evitar pérdidas, desabastecimientos o errores.  
  **Valor:** seguridad farmacológica.  
  **Trazabilidad:** R art. 8; NT infraestructura; MDT 5.2 y 8.2.

- **HU-LOG-07** — **Actor:** Farmacia HSC  
  **Historia:** Como farmacia, quiero saber qué parte del tratamiento y stock corresponde a HODOM y cuál debe continuar por APS al alta, para no generar discontinuidades ni duplicidades.  
  **Valor:** continuidad del tratamiento.  
  **Trazabilidad:** HSC Enlace APS-HODOM; MDT 5.2.

- **HU-LOG-08** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero control diario de temperatura y humedad en bodegas y refrigeración cuando corresponda, para cumplir condiciones de resguardo de insumos y termolábiles.  
  **Valor:** calidad del insumo.  
  **Trazabilidad:** R art. 19; MDT 5.2.

## J4. Exámenes e imagenología

- **HU-LOG-09** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero tomar muestras y derivarlas con embalaje, bioseguridad y cadena de frío adecuados, para sostener la resolutividad clínica sin comprometer seguridad.  
  **Valor:** continuidad diagnóstica.  
  **Trazabilidad:** MDT 8.3; NT; REAS.

- **HU-LOG-10** — **Actor:** Laboratorio  
  **Historia:** Como laboratorio, quiero recibir y procesar muestras HODOM con identificación robusta y tiempos de respuesta definidos, para integrarlas como parte de la atención cerrada domiciliaria.  
  **Valor:** soporte diagnóstico confiable.  
  **Trazabilidad:** HSC operación; MDT 8.3.

- **HU-LOG-11** — **Actor:** Imagenología  
  **Historia:** Como imagenología, quiero contar con un flujo expedito para pacientes HODOM que requieren radiografías u otros estudios sin pasar innecesariamente por urgencia, para no romper el episodio domiciliario.  
  **Valor:** continuidad hospitalaria extendida.  
  **Trazabilidad:** HSC Enlace APS-HODOM; HSC proyecto BIP.

---

# EPIC K — DISPOSITIVOS, IAAS, REAS Y SEGURIDAD DEL PACIENTE

## K1. Dispositivos invasivos y procedimientos

- **HU-SEG-01** — **Actor:** Enfermería / DT  
  **Historia:** Como responsable clínico, quiero manuales vigentes para VVP, CVC, PICC, CUP, traqueostomía, ostomías y toma de muestras, para unificar técnica y vigilancia en domicilio.  
  **Valor:** reducción de variabilidad y complicaciones.  
  **Trazabilidad:** NT protocolos; MDT 8.1 y 8.3.

- **HU-SEG-02** — **Actor:** Enfermería  
  **Historia:** Como enfermería, quiero evaluar diariamente fijación, sitio de inserción y signos de infección o flebitis, para prevenir complicaciones asociadas a invasivos.  
  **Valor:** prevención IAAS.  
  **Trazabilidad:** HSC registro enfermería; MDT 8.1 y 9.1.

- **HU-SEG-03** — **Actor:** Paciente/cuidador  
  **Historia:** Como paciente o cuidador, quiero recibir educación específica sobre manipulación segura de dispositivos y señales de alarma, para no generar daño entre visitas.  
  **Valor:** seguridad compartida.  
  **Trazabilidad:** MDT 8.1; HSC ingreso enfermería.

## K2. IAAS y aislamiento

- **HU-SEG-04** — **Actor:** IAAS / DT  
  **Historia:** Como referente IAAS, quiero protocolo de precauciones estándar y aislamientos adaptado al domicilio, para sostener control infeccioso fuera del hospital.  
  **Valor:** prevención de infecciones asociadas a la atención.  
  **Trazabilidad:** R art. 8; NT; MDT 9.1.

- **HU-SEG-05** — **Actor:** Enfermería / equipo clínico  
  **Historia:** Como equipo clínico, quiero verificar desde el ingreso si el domicilio permite aplicar las medidas de aislamiento requeridas, para no aceptar situaciones incontrolables.  
  **Valor:** factibilidad sanitaria real.  
  **Trazabilidad:** MDT 6.1 y 9.1.

- **HU-SEG-06** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero asegurar disponibilidad de EPP acorde a riesgo clínico y epidemiológico, para proteger a pacientes y trabajadores.  
  **Valor:** seguridad ocupacional y clínica.  
  **Trazabilidad:** R art. 5; MDT 9.1.

## K3. REAS y residuos

- **HU-SEG-07** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero segregar residuos especiales y cortopunzantes en domicilio con contenedores adecuados, para no tratarlos como basura domiciliaria común.  
  **Valor:** bioseguridad.  
  **Trazabilidad:** R art. 19; NT; MDT 9.2.

- **HU-SEG-08** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero contar con procedimiento formal de recepción, transporte y disposición transitoria de REAS en la base, para cerrar correctamente el circuito de residuos.  
  **Valor:** cumplimiento normativo.  
  **Trazabilidad:** NT; MDT 9.2.

## K4. Escalamiento y reingreso

- **HU-SEG-09** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero protocolo explícito de emergencia clínica con criterios de llamada, regulación, SAMU y reingreso, para no improvisar ante descompensaciones.  
  **Valor:** rescate oportuno.  
  **Trazabilidad:** R art. 8; R art. 16; MDT 9.3.

- **HU-SEG-10** — **Actor:** Paciente/cuidador  
  **Historia:** Como paciente o cuidador, quiero instrucciones simples y visibles sobre qué hacer si aparecen signos de alarma fuera del horario de visita, para activar ayuda sin retrasos.  
  **Valor:** seguridad extravisita.  
  **Trazabilidad:** HSC CI 2026; MDT 7.2 y 9.3.

- **HU-SEG-11** — **Actor:** Servicios hospitalarios receptores  
  **Historia:** Como servicio hospitalario receptor, quiero recibir al paciente reingresado desde HODOM con resumen actualizado de evolución y tratamientos, para retomar el caso sin pérdida de información.  
  **Valor:** continuidad del episodio.  
  **Trazabilidad:** R art. 8; MDT 6.4.

## K5. Seguridad del personal

- **HU-SEG-12** — **Actor:** Equipo en terreno  
  **Historia:** Como equipo en terreno, quiero protocolo frente a agresiones, entorno inseguro o amenaza, para poder retirarme y escalar institucionalmente sin ambigüedad.  
  **Valor:** protección del trabajador.  
  **Trazabilidad:** MDT 9.4.

- **HU-SEG-13** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero que la pérdida de entorno seguro sea causal de reevaluación, no ingreso o egreso disciplinario según corresponda, para proteger al equipo y a la continuidad del servicio.  
  **Valor:** sostenibilidad operativa.  
  **Trazabilidad:** R art. 16; MDT 9.4.

---

# EPIC L — ENTREGA DE TURNO, PASE DE VISITA Y COORDINACIÓN INTERDISCIPLINARIA

- **HU-TUR-01** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero una entrega de turno estructurada por paciente con situación actual, riesgos, exámenes pendientes, invasivos y plan del día, para asegurar continuidad entre jornadas.  
  **Valor:** reducción de omisiones.  
  **Trazabilidad:** MDT 8.4; HSC entrega de turno.

- **HU-TUR-02** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero integrar en la entrega de turno el estado de rutas, flota, monitores y disponibilidad de personal, para alinear componente clínico y logístico.  
  **Valor:** operación integral.  
  **Trazabilidad:** MDT 8.4; legacy.

- **HU-TUR-03** — **Actor:** Equipo clínico  
  **Historia:** Como equipo clínico, quiero que el pase de visita diario refuerce signos de alarma y cambios en la estabilidad clínica, para detectar precozmente deterioros.  
  **Valor:** vigilancia activa.  
  **Trazabilidad:** MDT 8.4.

- **HU-TUR-04** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero que la información de entrega de turno quede registrada y no dependa solo de transmisión verbal, para disminuir pérdidas críticas de información.  
  **Valor:** trazabilidad.  
  **Trazabilidad:** MDT 8.4; HSC entrega de turno.

---

# EPIC M — EGRESO, FALLECIMIENTO Y CONTINUIDAD CON LA RED

## M1. Alta y cierre del episodio

- **HU-EGR-01** — **Actor:** Médico HODOM  
  **Historia:** Como médico HODOM, quiero dar alta cuando el paciente ya no requiera intensidad hospitalaria o haya completado el plan terapéutico, para cerrar el episodio con criterio clínico y no por mera presión de cupos.  
  **Valor:** pertinencia del egreso.  
  **Trazabilidad:** R art. 16; MDT 6.4.

- **HU-EGR-02** — **Actor:** Enfermería  
  **Historia:** Como enfermería, quiero registrar Barthel de egreso, cierre del plan de cuidados y educación final, para objetivar resultado funcional y continuidad requerida.  
  **Valor:** egreso trazable.  
  **Trazabilidad:** HSC ingreso enfermería; continuidad clínica.

- **HU-EGR-03** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero entregar epicrisis médica y de enfermería más indicaciones al egreso, para asegurar cierre clínico completo.  
  **Valor:** continuidad post-HODOM.  
  **Trazabilidad:** R art. 24; MDT 6.4 y 7.1.

## M2. Contrarreferencia y enlace con APS

- **HU-EGR-04** — **Actor:** APS  
  **Historia:** Como APS, quiero recibir contrarreferencia formal de pacientes egresados de HODOM con diagnósticos, tratamientos realizados y pendientes, para retomar el cuidado sin reiniciar la historia.  
  **Valor:** continuidad asistencial efectiva.  
  **Trazabilidad:** HSC Enlace APS-HODOM; MDT 6.4.

- **HU-EGR-05** — **Actor:** HODOM  
  **Historia:** Como HODOM, quiero diferenciar claramente qué prestaciones quedan a cargo de APS y cuáles no, para evitar duplicidades o vacíos al alta.  
  **Valor:** continuidad sin zonas grises.  
  **Trazabilidad:** HSC Enlace APS-HODOM.

- **HU-EGR-06** — **Actor:** Paciente/cuidador  
  **Historia:** Como paciente o cuidador, quiero saber a qué CESFAM, programa o dispositivo debo acudir tras el alta, para no quedar sin red una vez terminado el episodio.  
  **Valor:** seguridad post-egreso.  
  **Trazabilidad:** HSC CI 2026; HSC Enlace APS-HODOM.

## M3. Reingreso, renuncia, alta disciplinaria y fallecimiento

- **HU-EGR-07** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero protocolo de renuncia voluntaria y alta disciplinaria con causales y trazabilidad, para manejar conflictos o no adherencia de forma institucional.  
  **Valor:** seguridad jurídica y operativa.  
  **Trazabilidad:** R art. 16; MDT 6.4.

- **HU-EGR-08** — **Actor:** Equipo HODOM  
  **Historia:** Como equipo HODOM, quiero protocolo de fallecimiento que indique certificación, retiro de dispositivos, apoyo familiar y cierre documental, para actuar sin improvisación en un evento crítico.  
  **Valor:** dignidad y seguridad legal.  
  **Trazabilidad:** R art. 24; MDT 6.4.

---

# EPIC N — CALIDAD, INDICADORES, SATISFACCIÓN Y MEJORA CONTINUA

## N1. Indicadores operativos y clínicos

- **HU-CAL-01** — **Actor:** Dirección HSC  
  **Historia:** Como dirección del hospital, quiero indicadores mensuales de ingresos, egresos, cupos, ocupación, días cama liberados, estada, reingresos, eventos adversos y satisfacción, para conducir HODOM como capacidad hospitalaria real.  
  **Valor:** gestión basada en evidencia.  
  **Trazabilidad:** R art. 8; HSC proyecto BIP; legacy.

- **HU-CAL-02** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero distinguir indicadores de calidad clínica, continuidad, logística y cumplimiento normativo, para no reducir el desempeño solo a número de visitas.  
  **Valor:** mirada integral del servicio.  
  **Trazabilidad:** MDT; HSC tablero previo.

- **HU-CAL-03** — **Actor:** Calidad/OCSP  
  **Historia:** Como calidad, quiero auditar eventos adversos, caídas, errores de medicación, IAAS, mortalidad y reclamos, para integrar HODOM al sistema de seguridad del paciente del hospital.  
  **Valor:** aprendizaje institucional.  
  **Trazabilidad:** R art. 8; MDT 9; NT calidad.

## N2. Satisfacción usuaria

- **HU-CAL-04** — **Actor:** Calidad  
  **Historia:** Como calidad, quiero aplicar encuesta de satisfacción usuaria al egreso con metodología y resguardo formal, para recoger experiencia real del usuario.  
  **Valor:** mejora centrada en personas.  
  **Trazabilidad:** R art. 24; MDT 7.4; HSC archivo de satisfacción.

- **HU-CAL-05** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero usar la satisfacción usuaria para detectar problemas de trato, cumplimiento de visitas, comunicación y educación, para ajustar la operación más allá de la productividad.  
  **Valor:** mejora continua con foco humano.  
  **Trazabilidad:** MDT 7.4.

## N3. Auditoría y aprendizaje

- **HU-CAL-06** — **Actor:** Dirección Técnica / Calidad  
  **Historia:** Como responsables de la unidad, quiero auditorías periódicas de fichas, consentimientos, rutas, entrega de turno y planes de cuidado, para cerrar brechas documentales y clínicas tempranamente.  
  **Valor:** prevención de desviaciones.  
  **Trazabilidad:** R art. 8; MDT 7-9.

- **HU-CAL-07** — **Actor:** Dirección Técnica  
  **Historia:** Como DT, quiero revisar periódicamente si los formularios locales capturan todos los campos exigidos normativamente y los necesarios para gestión real, para evitar sistemas paralelos y subregistro.  
  **Valor:** calidad del dato.  
  **Trazabilidad:** NT registros; HSC formularios; legacy.

---

# EPIC O — SISTEMA WEB / SISTEMA OPERATIVO DIGITAL DE HODOM

> Estas historias conectan la normativa y la práctica local con el futuro sistema web de la unidad.

- **HU-SIS-01** — **Actor:** Director Técnico  
  **Historia:** Como DT, quiero un sistema único que concentre postulación, admisión, ficha clínica, rutas, visitas, insumos, egreso e indicadores, para reemplazar planillas y PDFs dispersos.  
  **Valor:** gobernanza del dato.  
  **Trazabilidad:** legacy; MDT 7.1; HSC realidad documental.

- **HU-SIS-02** — **Actor:** Enfermería / coordinación  
  **Historia:** Como coordinación, quiero que el sistema genere automáticamente número de postulación/episodio y checklist de ingreso, para estandarizar admisión y seguimiento.  
  **Valor:** trazabilidad desde el inicio.  
  **Trazabilidad:** HSC ingreso enfermería; legacy.

- **HU-SIS-03** — **Actor:** Equipo clínico  
  **Historia:** Como equipo clínico, quiero formularios digitales equivalentes a ingreso enfermería, ingreso kinesiología, registro de visita, registro de enfermería, curaciones y epicrisis, para no duplicar registros.  
  **Valor:** continuidad y reducción de carga administrativa.  
  **Trazabilidad:** HSC formularios 2026.

- **HU-SIS-04** — **Actor:** Coordinación  
  **Historia:** Como coordinación, quiero un tablero en tiempo real de cupos, rutas, profesionales, pacientes activos y alertas clínicas, para gestionar la unidad día a día.  
  **Valor:** control operacional.  
  **Trazabilidad:** HSC programación/rutas; MDT 6.3 y 8.4.

- **HU-SIS-05** — **Actor:** Dirección / calidad  
  **Historia:** Como dirección y calidad, quiero indicadores automáticos de ocupación, estada, reingreso, productividad, satisfacción y cumplimiento documental, para conducir la unidad con evidencia.  
  **Valor:** mejora continua automatizada.  
  **Trazabilidad:** HSC proyecto BIP; legacy; MDT 7 y 9.

- **HU-SIS-06** — **Actor:** TI / seguridad  
  **Historia:** Como TI, quiero control de accesos por rol, bitácora de cambios y resguardo seguro de datos sensibles, para cumplir privacidad y confidencialidad clínica.  
  **Valor:** seguridad de la información.  
  **Trazabilidad:** R art. 23; Ley 19.628; MDT 1.2 y 7.1.

- **HU-SIS-07** — **Actor:** Usuario / cuidador  
  **Historia:** Como usuario o cuidador, quiero que el sistema permita imprimir o visualizar un resumen domiciliario claro y actualizado, para tener la información crítica siempre disponible.  
  **Valor:** continuidad en el hogar.  
  **Trazabilidad:** MDT 7.2.

- **HU-SIS-08** — **Actor:** DT / coordinación  
  **Historia:** Como DT o coordinación, quiero alertas automáticas por consentimiento faltante, registro incompleto, certificación vencida, control omitido o episodio sin epicrisis, para reducir fallas prevenibles.  
  **Valor:** control proactivo.  
  **Trazabilidad:** NT; MDT; legacy.

---

# 4. Resumen cuantitativo

| Epic | Tema | N° historias |
|------|------|--------------|
| A | Dirección técnica, gobernanza y cumplimiento | 12 |
| B | Recursos humanos, habilitación e inducción | 10 |
| C | Admisión, elegibilidad y priorización | 14 |
| D | Consentimiento, derechos y experiencia | 10 |
| E | Paciente, cuidador y soporte familiar | 7 |
| F | Médico de atención directa y regulación | 8 |
| G | Enfermería clínica y coordinación | 15 |
| H | Kinesiología, fono, TENS y trabajo social | 10 |
| I | Registros, ficha y datos | 10 |
| J | Logística, rutas, flota, insumos y soporte | 11 |
| K | Dispositivos, IAAS, REAS y seguridad | 13 |
| L | Entrega de turno y coordinación interdisciplinaria | 4 |
| M | Egreso, fallecimiento y continuidad con la red | 8 |
| N | Calidad, indicadores y mejora continua | 7 |
| O | Sistema web / sistema operativo digital | 8 |
| **Total** |  | **147 historias** |

---

# 5. Priorización sugerida para implementación

## Prioridad 1 — críticas para seguridad y cumplimiento
- HU-DT-06 a HU-DT-10
- HU-AD-05 a HU-AD-14
- HU-CI-01 a HU-CI-08
- HU-ENF-01 a HU-ENF-12
- HU-REG-01, HU-REG-05, HU-REG-07, HU-REG-09
- HU-SEG-01 a HU-SEG-13
- HU-EGR-01, HU-EGR-03, HU-EGR-07, HU-EGR-08

## Prioridad 2 — críticas para operación diaria
- HU-RH-01 a HU-RH-10
- HU-PC-01 a HU-PC-07
- HU-MD-01 a HU-MD-08
- HU-KIN-01 a HU-TS-03
- HU-LOG-01 a HU-LOG-11
- HU-TUR-01 a HU-TUR-04

## Prioridad 3 — críticas para gestión y escalamiento digital
- HU-CAL-01 a HU-CAL-07
- HU-SIS-01 a HU-SIS-08

---

# 6. Nota final para el rediseño HSC

Estas historias ya no describen solo un software ni solo una unidad clínica. Describen **el sistema operativo completo de HODOM HSC** como servicio de hospitalización cerrada en domicilio, con conducción técnica, continuidad hospital-red, seguridad clínica, trazabilidad normativa y soporte digital.

## Trazabilidad normativa mínima usada
- **DS N°1/2022**: arts. 1-25, especialmente 4-19, 23-25
- **Norma Técnica HD 2024**: personal, infraestructura, equipamiento, registros, protocolos y PAC
- **Manual de Dirección Técnica HD**: caps. 1-9
- **Documentación local HSC**: consentimiento 2026, hoja de ingreso de enfermería, hoja de ingreso de kinesiología, registro visita equipo, registro enfermería, registro curaciones, protocolo PRO-002, proyecto BIP 40059567-0, Enlace HODOM-APS

**Disclaimer:** Documento de apoyo técnico para conducción humana. En caso de contradicción, prevalece el texto oficial vigente del `DS 1/2022`, `DE 31/2024` y actos formales del `MINSAL` y `SEREMI`.