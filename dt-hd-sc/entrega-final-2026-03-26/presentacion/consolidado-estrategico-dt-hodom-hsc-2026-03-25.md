# Consolidado estratégico — Dirección Técnica HODOM HSC
## Fecha: 2026-03-25
## Propósito
Documento de consolidación sistemática de todo lo trabajado hasta este momento para la primera reunión de equipo del nuevo Director Técnico HODOM HSC y para la hoja de ruta inmediata de rediseño, regulación, cumplimiento y prototipado operativo.

---

# 1. Contexto y objetivo de uso

Este documento consolida en una sola pieza:
- el diagnóstico actual de la unidad HODOM HSC
- los hallazgos normativos y operativos críticos
- la propuesta narrativa y estratégica para la primera reunión de equipo
- la estructura de horizontes de desarrollo acordada
- el enfoque de implementación respetuoso, progresivo y de baja carga cognitiva
- las prioridades inmediatas de cierre de brechas
- los prototipos web que pueden mostrarse en el corto plazo
- la incorporación del rol dual del usuario como **Director Técnico + médico regulador**

Este documento debe servir como:
1. base para la presentación al equipo
2. recordatorio durable de decisiones ya trabajadas
3. hoja de ruta para iteraciones rápidas con el equipo de desarrollo
4. referencia para próximos turnos de trabajo del agente

---

# 2. Fuentes revisadas e integradas

## 2.1 Documentos y análisis ya consolidados del proyecto HODOM HSC
- `output/hodom-hsc/presentacion-dt-hodom-hsc.md`
- `output/hodom-hsc/checklist-normativo-hodom-hsc.md`
- `output/hodom-hsc/propuesta-hodom-hsc-ideal.md`
- `output/hodom-hsc/specs-sistema-web-hodom-hsc.md`
- `output/hodom-hsc/inventario-e-insights-hodom-hsc.md`
- `output/hodom-hsc/analisis-datos-legacy-hodom-hsc.md`
- `output/hodom-hsc/informe-definitivo-telemetria-hodom-hsc.md`
- `output/hodom-hsc/analisis-rutas-y-paradas-hodom-ene-mar-2026.md`
- `output/hodom-hsc/plan-capacitacion-hodom-hsc.md`
- `output/operacional/plan-90-dias-dt.md`
- `output/operacional/guia-escalamiento-terreno.md`
- `output/operacional/formato-briefing-matinal.md`

## 2.2 Documentos fuente adicionales integrados
- Proyecto BIP / implementación permanente HODOM HSC:
  - `PROYECTO_IMPLEMENTACION_HODOM_HSC_2---972bcda9-90ca-463c-9d77-68e46b2ed970.pdf`
  - `PROYECTO_IMPLEMENTACION_HODOM_HSC_2---ca3e0128-ff6a-4337-b2a0-a438c1c34b6c.docx`
- PPT Enlace HODOM-APS / Programa Postrados:
  - `ENLACE_HODOM_-APS---2e557608-df12-4c5a-89f0-c3f4e765f423.pptx`

## 2.3 Base normativa considerada
- DS N°1/2022 — Reglamento de establecimientos que otorgan prestaciones de hospitalización domiciliaria
- Decreto Exento N°31/2024 — aprueba Norma Técnica HD 2024
- Ley 20.584 — derechos y deberes del paciente
- Ley 19.628 — protección de datos personales
- referencias complementarias del hospital y marco MINSAL utilizado en documentos previos

---

# 3. Diagnóstico consolidado del dispositivo HODOM HSC

## 3.1 Tesis diagnóstica central
HODOM HSC **no es un dispositivo fallido**. Tiene valor demostrado, resultados históricos defendibles y legitimidad institucional creciente. Sin embargo, hoy opera **por debajo de su potencial real**, con una brecha importante entre el valor clínico que ya genera y el nivel de estructura, trazabilidad, soporte normativo, regulación clínica, coordinación interna y soporte tecnológico con que aún funciona.

## 3.2 Formulación diplomática recomendada para el equipo
La formulación recomendada no es describir la unidad como “anárquica” o “mínima”, sino como:

> una unidad valiosa, con resultados reales, pero que aún funciona con alta dependencia del esfuerzo del equipo y con un nivel de formalización, trazabilidad y soporte menor al que una unidad permanente necesita.

## 3.3 Problemas estructurales identificados

### A. Brechas normativas
- protocolo PRO-002 desactualizado para una unidad permanente
- insuficiente formalización de escalamiento clínico
- registros no suficientemente homogéneos ni auditables
- evaluación domiciliaria y red de apoyo no plenamente trazables en formato uniforme
- alta y contrarreferencia aún no suficientemente estructuradas
- coordinación con APS y procesos específicos (ej. O₂) insuficientemente protocolizados

### B. Brechas de rendimiento operativo
- tiempos muertos relevantes al inicio y durante la jornada
- baja utilización efectiva de la jornada formal
- oportunidad de aumentar visitas diarias sin depender primero de más recursos
- uso de kilómetros y rutas subóptimo
- necesidad de mejor planificación diaria, hitos y priorización

### C. Brechas de gobernanza clínica
- fragmentación de la atención médica
- médicos tienden a seguir “sus” pacientes sin adecuada alternancia o regulación compartida
- altas no suficientemente reguladas por una lógica común
- diferencias de criterio no suficientemente contenidas por una instancia estructurada de revisión de casos
- baja productividad médica presencial y dificultad de programación por variabilidad horaria de al menos un médico de media jornada

### D. Brechas de sistema de información
- papel + planillas + registros dispersos
- ausencia de capa operativa compartida y visible para todos
- médicos registran en papel mientras otros perfiles disponen de SGH
- no existe hoy un panel general compartido para censo, alertas, ingresos, altas, pendientes, rutas y coordinación diaria

### E. Brechas de continuidad y red
- Enlace HODOM-APS existe, pero aún en marcha blanca
- contrarreferencia no plenamente formalizada como flujo estándar
- gran oportunidad de fortalecer admission avoidance desde APS / Programa Postrados

---

# 4. Datos duros más relevantes ya consolidados

## 4.1 Presión estructural hospitalaria
### Oportunidad de hospitalización ≤12h adulto
- 2019: 96,8%
- 2022: 69,5%
- 2023: 61,0%
- 2024: 54,9%
- 2025: 40,6%

### Índice ocupacional 2025
- Medicina: 97,5
- Cirugía: 96,0
- Traumatología: 97,9
- Área quirúrgica: 98,1
- Total hospital: 86,6

### Hospital
- 130 camas
- centro de referencia de red norte
- presión adicional por demanda de otras redes y regiones

## 4.2 Resultados históricos HODOM
### 2023
- 307 personas atendidas
- 4.037 días persona
- 0 fallecidos no esperados
- 16 reingresos
- 5.148 visitas

### 2024
- 1.077 personas atendidas
- 6.508 días persona
- 0 fallecidos no esperados
- 28 reingresos
- 11.562 visitas

### 2025
- 751 personas atendidas
- 5.480 días persona
- 0 fallecidos no esperados
- 28 reingresos
- 9.428 visitas
- sin trabajadora social durante el período descrito

## 4.3 Hallazgos logísticos/telemetría
- match programación ↔ GPS ~87%
- jornada formal mayor que jornada efectivamente operada
- capacidad ociosa importante en franja tardía y tiempos en base
- oportunidad de recuperar capacidad con mejor diseño de rutas, tiempos y ventanas operativas
- existe margen relevante de mejora sin partir por más recursos

---

# 5. Legitimidad institucional ya disponible

El proyecto institucional BIP 40059567-0 reconoce formalmente que la HODOM:
- ya ha sido implementada en 3 oportunidades
- ha sido fundamental para mejorar el proceso de hospitalización
- reduce presión asistencial y descongestiona urgencias
- permite destinar camas a pacientes de mayor riesgo
- entrega cuidados comparables en calidad y cantidad a la hospitalización tradicional
- favorece continuidad con nivel primario y secundario

Conclusión estratégica:
> no se está defendiendo una ocurrencia individual del DT, sino una convergencia entre valor ya demostrado por el equipo, necesidad estructural del hospital y reconocimiento institucional formal.

---

# 6. Estructura estratégica acordada: 3 horizontes

## Horizonte 1 — Mejor funcionamiento con lo que ya tenemos
### Idea central
Sacar lo mejor de lo que la unidad ya naturalmente hace, sin partir por pedir más recursos y sin sobrecargar al equipo.

### Orientación práctica
- optimizar funcionamiento actual
- aumentar visitas con los recursos actuales
- usar mejor kilómetros y tiempos
- mejorar coordinación y comunicación
- disminuir tiempos muertos
- mejorar registros
- ordenar planificación diaria, salidas, hitos y seguimiento
- instalar revisión/regulación de casos
- cerrar ya las brechas normativas insostenibles de mayor retorno operativo y cognitivo

### Tesis del horizonte 1
> aumentar el rendimiento real de la unidad con lo que ya tiene, mejorando cómo se organiza, cómo se mueve, cómo se coordina y cómo usa su tiempo.

## Horizonte 2 — Cumplimiento normativo y consolidación formal
### Idea central
Cerrar brechas exigibles y dejar la unidad defendible, trazable y segura.

### Componentes
- alineamiento con DS 1/2022 y NT 2024
- actualización de protocolos mínimos
- registros auditables
- seguridad del paciente
- trazabilidad
- gobernanza
- capacitación e inducción
- indicadores y evidencia de cumplimiento

## Horizonte 3 — Máxima expresión del potencial con los recursos que tenemos
### Idea central
Llevar la unidad a una versión más madura, inteligente y sostenible sin depender linealmente de más gasto.

### Palancas definidas
- nuevas tecnologías útiles
- inteligencia artificial
- automatización
- digitalización
- gestión del conocimiento
- capacitación continua
- gestión de campo
- trabajo en equipo
- cultura organizacional
- calidad
- seguridad
- innovación

---

# 7. Forma de implementación acordada (sin nombrarlo como gestión del cambio)

## Principios acordados
- avanzar por capas, no con cambios masivos de una vez
- partir por lo más útil para el trabajo real
- formalizar solo lo necesario
- usar herramientas breves, claras, absorbibles y fácilmente digeribles
- evitar burocracia innecesaria
- mostrar resultados tempranos
- ajustar con retroalimentación del equipo
- no duplicar trabajo
- diseñar todo para **bajar carga cognitiva**

## Fórmulas clave de lenguaje acordadas
- “ordenar sin rigidizar”
- “formalizar sin burocratizar”
- “mejorar sin sobrecargar”
- “más claridad, menos fricción”
- “todo lo que implementemos debe disminuir carga cognitiva, no aumentarla”

## Instrumentos mínimos y efectivos acordados
- briefing diario corto
- guías operativas de una página
- formatos mínimos estandarizados
- tablero simple de indicadores
- registro más homogéneo
- revisión periódica breve de lo que funcionó, lo que trabó y lo que hay que ajustar

---

# 8. Brechas normativas y operativas que deben cerrarse “ahora ya”

Se acordó priorizar no todas las brechas a la vez, sino las que sean:
- normativamente relevantes
- insostenibles si se dejan abiertas
- de alto retorno operativo
- de alto retorno en menor desgaste y menor carga cognitiva
- prototipables rápidamente

## Prioridad inmediata A
### 1. Revisión / regulación clínica de casos
Tu rol como **DT + médico regulador** debe traducirse en una instancia estable de revisión de casos para:
- priorizar ingresos
- revisar seguimientos complejos
- decidir egresos
- ordenar rescates
- priorizar cupos
- disminuir variabilidad clínica

Formato recomendado:
- presencial o digital
- 10-20 min
- integrado al briefing o posterior inmediato
- con decisión visible y registrada

### 2. Escalamiento clínico
Ya existe base en guía de semáforo/NEWS2. Debe traducirse a:
- regla única
- tiempos de respuesta
- trazabilidad mínima
- soporte real a terreno

### 3. Registro clínico mínimo homogéneo
Debe existir una sola captura operativa simple para:
- ingreso
- atención/visita
- procedimiento
- alerta
- alta

### 4. Formulario de ingreso + evaluación domicilio/cuidador
Debe permitir:
- decisión clínica más consistente
- trazabilidad de elegibilidad
- respaldo normativo
- menor ambigüedad y menor carga mental

### 5. Briefing/tablero diario
Debe permitir:
- ver el censo
- ver alertas
- ver ingresos, altas y pendientes
- ver móviles/rutas
- alinear el día

## Prioridad inmediata B
### 6. Alta y contrarreferencia
### 7. Núcleo mínimo de protocolos usables
- ingreso/elegibilidad
- evaluación domicilio/cuidador
- escalamiento
- alta/contrarreferencia
- O₂ domiciliario
- coordinación APS
- medicamentos y muestras

---

# 9. Panel de control general y prototipos inmediatos

## 9.1 Decisión estratégica
Se definió como objetivo mostrar mañana un **prototipo funcional rápido** de una capa operativa web, visible para todos, accesible por celular y orientada a ordenar el funcionamiento cotidiano.

## 9.2 Contexto técnico relevante
- médicos registran hoy en papel
- otros profesionales tienen relación con SGH
- el usuario ya cuenta con acceso vía CLI a SGH con sus credenciales
- se dispone de dominio e infraestructura para desplegar rápidamente un prototipo funcional
- existe posibilidad de construir en pocas iteraciones de horas varios prototipos web mínimos
- el sistema debe permitir **registrar digital** y luego **imprimir en formato compatible con la ficha papel** si se requiere respaldo físico

## 9.3 Qué debe demostrar el panel mañana
No un sistema grande, sino una **capa operativa mínima compartida** que permita:
- visibilidad común de la unidad
- coordinación diaria
- registros estructurados
- soporte a regulación clínica
- georreferenciación
- reducción de papel operativo
- reducción de pérdida de información
- preparación para continuidad futura

## 9.4 Prototipos web priorizados para mostrar
### Prototipo 1 — Panel general / tablero operativo
- pacientes activos
- cupos
- alertas
- ingresos pendientes
- altas pendientes
- móviles/rutas
- pendientes críticos

### Prototipo 2 — Registro web móvil de atención
- formulario breve por disciplina
- signos/procedimientos/nota corta
- usable desde celular
- imprimible en formato compatible con papel

### Prototipo 3 — Regulación clínica de casos
- ingresos propuestos
- casos complejos
- egresos posibles
- rescates
- decisión del regulador
- responsable

### Prototipo 4 — Georreferenciación y rutas
- mapa de pacientes
- agrupación territorial
- asignación de móvil/ruta
- apoyo a planificación y uso de kilómetros

### Prototipo 5 — Alta y contrarreferencia
- resumen breve
- indicaciones
- continuidad APS
- salida imprimible/enviable

## 9.5 Criterios de diseño acordados
Todo prototipo debe:
- reducir carga cognitiva
- no aumentar pasos innecesarios
- no duplicar trabajo
- permitir visibilidad compartida
- ser mobile-first
- ser simple, breve y usable
- ayudar al trabajo real del equipo

---

# 10. Replanteamiento del componente médico

## Problema identificado
- baja productividad médica presencial
- dificultad de programación por variabilidad horaria de un médico de media jornada
- poca cantidad de visitas médicas de ingreso/egreso/control
- continuidad fragmentada entre médicos
- paradigma actual demasiado centrado en presencialidad

## Decisión estratégica
El valor médico del dispositivo no debe expresarse solo como visita presencial. También debe expresarse como:
- regulación clínica
- revisión de casos
- seguimiento remoto/telemático cuando corresponda
- apoyo oportuno a terreno
- mejor orden de ingresos, egresos, alertas y rescates

## Formulación recomendada
> existe una brecha importante entre la necesidad de regulación y seguimiento médico de la unidad y la forma en que el componente médico está actualmente desplegado. Esto obliga a rediseñar la organización médica, combinando mejor presencialidad, regulación clínica y atención telemática cuando sea pertinente.

---

# 11. Continuidad con APS y admission avoidance

## Estado actual
El enlace HODOM-APS / Programa Postrados debe ser tratado como activo estratégico.

### Elementos ya presentes
- APS puede detectar descompensación/cuadro agudo y remitir informe resumido
- HODOM evalúa cupo y acepta/inicia tratamiento
- HODOM asume tratamiento, evaluación médica, exámenes y radiografías
- APS mantiene curaciones crónicas y cambio de dispositivos invasivos
- se informa alta por epicrisis

## Interpretación estratégica
HODOM no solo debe presentarse como herramienta para liberar camas. También debe presentarse como:
- interfaz hospital-APS
- soporte de continuidad del cuidado
- embrión de admission avoidance en pacientes vulnerables

---

# 12. Narrativa política y técnica acordada para la reunión

## Qué no hacer
- no partir criticando
- no usar lenguaje agresivo (“anárquico”, “desordenado”, “improvisado”)
- no sobreprometer
- no presentar tecnología como solución mágica

## Qué sí hacer
- reconocer al equipo
- reconocer resultados históricos
- mostrar problema estructural del hospital
- explicar que la unidad funciona pero por debajo de su potencial
- mostrar brechas como brechas del dispositivo y del soporte, no como fallas personales
- presentar un camino por horizontes
- mostrar herramientas concretas y alcanzables

## Frases acordadas de alto valor
- “No vengo a partir de cero.”
- “Lo que hoy existe merece ser reconocido, pero también protegido del desorden, la precariedad y la dependencia excesiva de soluciones informales.”
- “La pregunta ya no es si HODOM sirve, sino cuánto más podría aportar si estuviera mejor estructurado.”
- “Todo lo que implementemos debe disminuir carga cognitiva, no aumentarla.”
- “No quiero instalar un sistema pesado; quiero una capa operativa simple que ayude a que la unidad funcione mejor.”
- “Primero optimizar lo que ya existe. Luego consolidarlo. Después amplificar su potencial.”

---

# 13. Estructura de presentación consolidada

Se acordó evolucionar hacia una presentación final breve, fuerte y políticamente inteligente, basada en:
1. reconocimiento del trabajo del equipo
2. valor hospitalario de HODOM
3. diagnóstico actual (valor demostrado + capacidad no desplegada)
4. tres horizontes de desarrollo
5. forma de implementación simple y respetuosa
6. cierres normativos y operativos prioritarios
7. demostración temprana de prototipos web
8. cierre convocando al equipo

---

# 14. Acciones inmediatas sugeridas para mañana / próximas iteraciones

## Mañana
- presentar relato consolidado
- mostrar panel operativo / prototipos si están disponibles
- instalar idea de regulación clínica compartida
- instalar criterio de baja carga cognitiva
- recoger retroalimentación del equipo

## Iteraciones rápidas posteriores
### Sprint 0
- tablero briefing/censo/alertas/cupos
- regulación clínica de casos
- registro móvil mínimo
- escalamiento digital simple

### Sprint 1
- ingreso/evaluación domicilio
- georreferenciación
- rutas
- alta/contrarreferencia

### Sprint 2
- indicadores
- repositorio documental
- auditoría breve
- consolidación del núcleo mínimo de protocolos

---

# 15. Inventario estratégico de artefactos y recursos disponibles para la nueva etapa

## 15.1 Artefactos documentales y operativos ya existentes
Se debe considerar como activo estratégico todo el repositorio histórico acumulado en Google Drive y otras fuentes del programa desde el inicio de HODOM, incluyendo:
- documentación histórica completa de hospitalización domiciliaria desde su inicio
- formularios y registros clínicos actualmente usados e impresos para escritura manual
- planillas y consolidados por profesional/estamento
- rutas programadas históricas
- consolidaciones operativas y productivas
- documentos de entrega de turno
- epicrisis, DAU y documentación clínica histórica
- registros y material asociado a curaciones, educaciones y otros procesos

Conclusión: el nuevo trabajo no parte desde cero. Existe un corpus operativo real que debe ser inventariado, clasificado, simplificado y reutilizado como base para formularios, flujos y prototipos.

## 15.2 Segunda categoría de artefactos: documentación rectora
Debe existir como categoría propia de artefactos para el nuevo trabajo:
- normativa vigente HODOM (DS N°1/2022, NT 2024, regulación complementaria)
- protocolo vigente y sus versiones
- proyecto BIP / formulación institucional
- acuerdos operativos específicos (ej. O₂)
- presentación y flujo de enlace HODOM-APS
- instrumentos locales de calidad, seguridad y reportabilidad

Conclusión: no basta con mirar la operación; también hay que ordenar el corpus rector y normativo que va a guiar los rediseños.

## 15.3 Activos de datos a integrar en la nueva etapa
Se dejó explícito que deben considerarse como activos estructurales a ordenar e integrar:
- catastro de pacientes históricos
- rutas históricas
- geoposicionamiento / geolocalización de pacientes y rutas
- base histórica de visitas y atenciones
- registros impresos y digitales existentes
- telemetría GPS y análisis previos

## 15.4 Recursos humanos y materiales a ordenar y hacer visibles
Debe existir inventario coordinado y visible de:
- planilla completa de trabajadores
- horas y jornadas de cada integrante
- dotación real y disponibilidad operativa
- vehículos y estado operativo
- insumos disponibles
- medicamentos disponibles
- equipamiento clínico disponible
- recursos territoriales/logísticos disponibles

Esto debe pasar a ser parte del panel y de la coordinación operativa de la unidad.

## 15.5 Prioridades clínicas/operativas inmediatas explicitadas
Quedó señalado como prioridad de la nueva etapa debutar con la reactivación o reinstalación de prestaciones actualmente no desplegadas o subutilizadas:
- **sueloterapia**: reinicio/instalación como línea de trabajo concreta
- **oxigenoterapia**: reactivación, considerando que existen **3 concentradores de oxígeno** disponibles y actualmente subutilizados/no utilizados

Conclusión: estas líneas deben tratarse no solo como prestaciones clínicas, sino como prueba visible de capacidad recuperada del dispositivo.

---

# 16. Decisiones y posiciones que no deben olvidarse

1. **El tono diplomático no es debilidad: es una decisión estratégica.**
2. **El diagnóstico de fondo sí reconoce subutilización, baja formalización y alta dependencia del esfuerzo individual.**
3. **La narrativa pública debe hablar de capacidad no plenamente desplegada, no de caos.**
4. **El primer horizonte incluye también cierres normativos insostenibles, no solo eficiencia operativa.**
5. **La baja carga cognitiva es criterio de diseño central para cualquier herramienta o cambio.**
6. **La regulación clínica compartida es prioritaria y debe ser visible.**
7. **El componente médico debe rediseñarse incluyendo regulación y telematicidad, no solo presencialidad.**
8. **El panel web compartido debe estrenarse como símbolo de posibilidad concreta, no como sistema definitivo.**
9. **La documentación que se construya debe ser mínima, absorbible, efectiva y fácilmente actualizable.**
10. **Todo debe quedar nativamente documentado en la plataforma para no depender solo de memoria conversacional.**
11. **El repositorio histórico de Google Drive y los artefactos documentales existentes son activos del rediseño, no solo archivo muerto.**
12. **Los inventarios de RRHH, vehículos, insumos, medicamentos y equipamiento deben integrarse a la coordinación visible de la unidad.**
13. **La reactivación de sueroterapia y oxigenoterapia debe tratarse como prioridad concreta de capacidad clínica recuperada.**

---

# 17. Cierre operativo

Este consolidado debe tratarse como documento madre de la fase actual. Cualquier siguiente producto — presentación final, tablero, backlog, flujos, prototipos o plan de 90 días ajustado — debe derivarse de esta síntesis.

**Estado:** consolidado al 2026-03-25, listo para continuar trabajo sin pérdida de contexto.
