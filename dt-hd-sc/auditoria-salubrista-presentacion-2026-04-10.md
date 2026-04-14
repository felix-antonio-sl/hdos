# Auditoria Salubrista -- Presentacion Plan de Evolucion HODOM

**Auditor:** Salubrista (copiloto estrategico)
**Fecha:** 10 de abril de 2026
**Documento auditado:** `presentacion-evolucion-hodom-goza-2026-04-10.md` (~27 slides Marp)
**Destinatario:** Dr. Felix Sanhueza G., Director Tecnico HODOM HSC

---

## 1. AUDITORIA DE CONTENIDO SALUBRISTA

### 1a. Solidez del diagnostico situacional

**Calificacion: BUENO, con ajustes necesarios**

**Fortalezas del diagnostico:**
- El encuadre demografico (indice de envejecimiento 97,6, segundo mas alto del pais) es contundente y bien contextualizado.
- La serie temporal de oportunidad de hospitalizacion (96,8% a 40,6% en seis anos) es el dato mas poderoso de toda la presentacion. Usarlo como slide es correcto.
- Los indices ocupacionales >96% en los cuatro servicios criticos son devastadores para cualquier argumento en contra.
- El cruce entre perfil demografico de Nuble y perfil de poblacion HODOM (70,1 anos promedio, 59% >=70) es un argumento solido de pertinencia.

**Dimensiones que faltan o estan debiles:**

1. **Tasa de reingresos propia**: La presentacion muestra 72 reingresos acumulados en 3 anos (16+28+28), pero NO calcula la tasa. Esto es un error significativo. Con 2.135 personas atendidas, la tasa acumulada es ~3,4%. Este dato es EXCELENTE comparado con el benchmark nacional de SSMOc (4,1%) y la evidencia internacional. Debe calcularse y exhibirse explicitamente. Es un indicador que el Director va a preguntar o que conviene anticipar.

2. **Estancia media (ALOS)**: No aparece en ninguna parte de la presentacion. Con 16.025 dias-persona y (estimando) ~2.135 episodios, el ALOS seria ~7,5 dias, dentro del rango esperado (5-10 dias segun la KB situacional Chile 2026). Este indicador es basico para cualquier director hospitalario y su ausencia se nota.

3. **Tasa de rescate hospitalario**: No se menciona cuantos pacientes requirieron reingreso de urgencia por descompensacion aguda. Es distinto al reingreso planificado. La ausencia de este dato deja una pregunta abierta sobre seguridad que conviene cerrar proactivamente.

4. **Comparacion con produccion nacional**: La KB situacional indica que a nivel pais la HD atendio 166.707 pacientes en 2024 con 1,4 millones de dias-persona (crecimiento 135% desde 2019). San Carlos con 1.077 pacientes en 2024 tiene una participacion proporcional que podria usarse como referencia de posicionamiento relativo.

5. **Brecha de RRHH**: Se menciona que "el componente medico esta fragmentado" pero no se cuantifica la brecha. La norma tecnica exige Director Tecnico 22 horas/semana, medicos de atencion directa, medico regulador, enfermeros, kinesiologos, TENS. La presentacion deberia tener un slide o al menos una linea sobre la dotacion actual vs. la minima normativa.

6. **Indicador financiero local**: No hay ningun dato de costo dia-cama HODOM vs. dia-cama intrahospitalario del propio hospital. Aunque sea estimativo, un Director necesita este dato. La evidencia internacional dice 19-32% menor, pero el Director va a preguntar: "Y aqui, cuanto nos cuesta?"

**Recomendacion:** Agregar un mini-slide o reforzar el slide de "HODOM en cifras" con: tasa de reingresos (3,4%), estancia media (~7,5 dias), y al menos una estimacion de costo relativo. Estos tres datos convierten una presentacion descriptiva en una presentacion de gestion.

---

### 1b. Pertinencia del modelo de 3 horizontes

**Calificacion: CORRECTO Y BIEN SECUENCIADO**

La logica Ordenar (0-30 dias) -> Normar (60-90 dias) -> Madurar (3-6 meses) es la secuencia correcta desde gestion hospitalaria. Razones:

1. **Ordenar primero es estrategicamente inteligente**: Demuestra que se puede mejorar productividad (+50-67%) sin pedir recursos adicionales. Esto genera credibilidad ante Direccion antes de pedir validacion normativa o inversiones en tecnologia.

2. **Normar despues es necesario**: Solo tiene sentido formalizar protocolos cuando la operacion esta funcionando de manera coordinada. De lo contrario se norma el caos.

3. **Madurar al final es realista**: El sistema de informacion (hdos-app) como herramienta del horizonte 3 es correcto porque requiere que los procesos subyacentes esten definidos antes de digitalizarlos.

**Observaciones criticas sobre plazos:**

- **H1 (0-30 dias)**: Ambicioso pero factible SI el equipo esta comprometido. El briefing diario y la regulacion clinica son cambios de proceso, no de estructura. La reactivacion de sueroterapia y O2 depende de que los 3 concentradores esten operativos y del abastecimiento de insumos. Verificar que esto esta garantizado antes de prometer.

- **H2 (60-90 dias)**: El vacio entre dia 30 y dia 60 no esta explicado. Sugerencia: H2 deberia empezar en el dia 31, no en el dia 60. Si hay un gap de 30 dias sin nada planificado, se pierde momentum. Reformular como "Mes 2-3" en vez de "60-90 dias".

- **H3 (3-6 meses)**: Desplegar hdos-app en produccion en 3 meses es optimista. Se sugiere plantear "desde el mes 3" sin fecha de cierre rigida, para no generar una expectativa que pueda incumplirse ante Direccion.

- **Riesgo politico del +50-67%**: Prometer un incremento de productividad de esta magnitud ante Direccion genera una expectativa que se va a medir. Si en 30 dias no se alcanzan las 36-40 visitas/dia, la credibilidad del plan se erosiona. Recomendacion: presentar como "potencial identificado" y comprometer un objetivo mas conservador (por ejemplo +30-40%) como meta de H1.

---

### 1c. Presion de camas y reingresos

**Calificacion: MUY BIEN UTILIZADO, con un refuerzo faltante**

El argumento central esta muy bien construido:
- Oportunidad de hospitalizacion <=12h cayendo de 96,8% a 40,6% (serie 2019-2025).
- Indices ocupacionales >96% en cuatro servicios.
- Hospital de 130 camas como centro de referencia red norte.
- Dato nacional de 90,9% ocupacion critica adulto (MINSAL 8 abril 2026).

**Lo que falta:**

1. **Traduccion a camas equivalentes**: El Director necesita escuchar un numero concreto. Si HODOM atiende ~20 pacientes concurrentes (estimacion basada en dias-persona/365), eso equivale a ~20 camas virtuales, que representan el 15% de la capacidad del hospital de 130 camas. Este numero es contundente y deberia estar en la presentacion.

2. **Reingresos como argumento de calidad**: La tasa de reingresos de ~3,4% es inferior al benchmark SSMOc (4,1%) y consistente con la evidencia internacional (OR 0,72 a 30 dias segun meta-analisis HTA New York). Este dato deberia citarse como indicador de que HODOM no solo libera camas sino que lo hace con seguridad.

3. **Presion de camas en contexto GRD**: Segun la KB situacional Chile 2026, 80 hospitales estaran bajo GRD en 2026. Si San Carlos es uno de ellos (o lo sera pronto), HODOM tiene un argumento financiero potente: reduce estancia media intrahospitalaria, favorece alta precoz, evita Outliers Superiores en GRD, y optimiza el pago por egreso equivalente. Si no aplica GRD aun, mencionarlo como argumento prospectivo.

---

### 1d. Continuidad asistencial

**Calificacion: BIEN PLANTEADO, con dos interfaces criticas debiles**

El diagrama de flujo Hospital -> HODOM -> APS (slide 15) es claro y correcto. Las cuatro interfaces criticas identificadas son las correctas.

**Interfaces debiles:**

1. **Urgencia -> HODOM (evitacion de ingreso)**: La presentacion menciona que el 32% de ingresos viene de Urgencia, pero no distingue entre alta precoz (paciente ya ingresado al hospital) y evitacion de ingreso (paciente captado en urgencia que nunca se hospitaliza intrahospitalariamente). La evitacion de ingreso es el mecanismo de mayor impacto sobre presion de camas y el mas visible para Direccion. Se recomienda explicitar si HODOM opera en ambas modalidades o solo en alta precoz.

2. **HODOM -> APS (contrarreferencia)**: Se menciona como brecha ("contrarreferencia no plenamente estructurada") pero no se desarrolla la solucion. El enlace piloto HODOM-APS con Programa Postrados se menciona en el slide de punto de partida pero no se articula en los horizontes de implementacion. Sugerencia: incluir en H2 un hito especifico como "Epicrisis estandarizada con campos minimos para APS" y "Protocolo de seguimiento 48h post-alta con verificacion de recepcion por CESFAM".

3. **Especialidades -> HODOM**: No se menciona la interfaz con cirugia (que aporta parte del 25,3% restante de derivaciones). Los pacientes postquirurgicos con tratamiento antibiotico EV son candidatos clasicos de alta precoz. Explicitar esta interfaz fortalece el argumento de utilidad transversal.

---

### 1e. Campana de Invierno

**Calificacion: BIEN APROVECHADO, con un riesgo de encuadre**

El argumento es correcto: la Campana de Invierno 2026 ya esta activada, HODOM fue reconocida como dispositivo en la Campana 2024 (Chillan, San Carlos, Bulnes), y los datos de ocupacion nacional (90,9% critica adulto) crean urgencia.

**Riesgo de encuadre:**
Si la presentacion asocia HODOM demasiado a Campana de Invierno, el Director puede interpretar que HODOM solo tiene valor estacional. La presentacion ya maneja esto bien con la frase "no es un proyecto accesorio", pero oralmente hay que reforzar: "Campana de Invierno es la urgencia inmediata, pero el plan de evolucion es para todo el ano. HODOM resuelve presion de camas 365 dias al ano, no solo en invierno."

**Dato faltante:** Si es posible obtener el numero de camas extra que el hospital necesita habilitar para Campana de Invierno (camas de sobredemanda, camas transitorias), ese numero comparado con los cupos HODOM seria un argumento demoledor. Ejemplo: "El hospital necesita habilitar X camas para invierno. HODOM ya aporta el equivalente a Y camas virtuales."

---

### 1f. Gobernanza propuesta

**Calificacion: CORRECTA EN PRINCIPIO, INSUFICIENTE EN DETALLE**

La estructura SDM (supervision clinica) + SDGC (supervision de cuidados de enfermeria) con reportabilidad a Direccion es la correcta para un hospital de 130 camas. Razones:

- HODOM es una unidad hospitalaria, no un programa comunitario. La dependencia de la Subdireccion Medica es obligatoria porque los pacientes estan bajo regimen de internacion.
- El componente de enfermeria (82% de los ingresos gestionados por 6 enfermeras gestoras) justifica la supervision SDGC.
- La doble dependencia funcional (clinica + cuidados) es el modelo estandar en Chile para unidades hospitalarias con enfermeria autonoma.

**Lo que falta:**

1. **Organigrama minimo**: Un diagrama que muestre: Direccion -> SDM -> Director Tecnico HODOM -> Equipo. Y: SDGC -> Coordinadora de enfermeria HODOM (linea funcional, no jerarquica). El Director espera ver una caja organizacional, no solo texto.

2. **Frecuencia de reportabilidad**: No se dice cada cuanto HODOM reporta a Direccion. Sugerencia: reporte mensual con indicadores clave + reporte semanal durante Campana de Invierno.

3. **Comite clinico HODOM**: La norma tecnica exige gobierno clinico. Se sugiere un comite clinico mensual (Director Tecnico + Coordinadora enfermeria + SDM/representante) para revision de casos, indicadores y eventos adversos. Esto convierte la gobernanza en algo operativo, no solo organigraficol.

4. **Resolucion de conflictos**: Cuando SDM y SDGC tienen posiciones diferentes sobre un caso HODOM, quien decide? El Director Tecnico? El Director del hospital? Este punto de gobernanza es critico y no esta resuelto.

---

### 1g. Cuidador

**Calificacion: BUENO COMO SLIDE, INSUFICIENTE COMO ARGUMENTO DE RIESGO**

El slide del cuidador (slide 14) es correcto en su estructura: evaluacion al ingreso, educacion durante estadia, indicaciones al alta. Sin embargo:

**Lo que falta:**

1. **Instrumento de evaluacion del cuidador**: La norma tecnica exige evaluacion del cuidador, pero la presentacion no dice con que instrumento. Mencionarlo aunque sea de pasada (Zarit abreviado, escala propia, checklist estructurado) demuestra que no es solo discurso.

2. **Criterio de exclusion por cuidador**: El factor mas restrictivo para eligibilidad HODOM es la ausencia de cuidador competente (segun KB situacional Chile 2026, seccion 4.2). La presentacion no dice que porcentaje de candidatos se rechaza por esta causa. Si el dato existe, es relevante porque demuestra rigor en la seleccion.

3. **Cuidador como riesgo operativo**: La evidencia internacional (NAM perspective, corpus HAH F73) documenta riesgo de task-shifting al cuidador, costos ocultos (24h/semana promedio + gastos de bolsillo), y disrupcion de vida diaria. La presentacion no menciona estos riesgos. Ante un auditorio hospitalario esto puede no ser critico, pero si la SDGC pregunta, Felix debe tener respuesta.

4. **Cuidador en contexto de equidad**: El 87,6% de pacientes HODOM son FONASA A y B. Esto implica poblacion vulnerable con mayor probabilidad de cuidadores sobrecargados, redes de apoyo debiles y viviendas precarias. La interseccion entre vulnerabilidad socioeconomica y exigencia de cuidador competente es una tension que HODOM debe gestionar activamente.

---

### 1h. Indicadores

**Calificacion: INSUFICIENTE PARA EL NIVEL DIRECTIVO**

La presentacion menciona indicadores en varios slides pero no consolida un tablero minimo. Los indicadores actuales son basicamente de produccion (personas atendidas, dias-persona, visitas, reingresos, fallecidos). Faltan:

**Indicadores que un Director espera ver:**

| Tipo | Indicador | Por que importa |
|------|-----------|-----------------|
| Eficiencia | **Estancia media (ALOS)** | Basico. Sin este dato no hay benchmarking posible |
| Eficiencia | **Indice ocupacional HODOM** | Cuantos cupos de los disponibles estan ocupados |
| Eficiencia | **Giro-cama virtual** | Productividad de cada cupo |
| Seguridad | **Tasa de reingresos a 30 dias** | Ya existe el dato, solo falta calcularlo y presentarlo |
| Seguridad | **Tasa de rescate hospitalario** | Pacientes que vuelven al hospital por descompensacion aguda |
| Seguridad | **Eventos adversos notificados** | Aunque sea cero, el indicador debe existir formalmente |
| Calidad | **Satisfaccion del paciente/familia** | Puede ser un survey simple. Dato de alto impacto politico |
| Financiero | **Costo dia-cama HODOM vs intrahospitalario** | Aunque sea estimativo, es el indicador que cierra la conversacion |
| Continuidad | **Tasa de contrarreferencia efectiva a APS** | Mide integracion real con la red |
| Oportunidad | **Tiempo desde indicacion de derivacion a ingreso HODOM** | Mide la friccion de la interfaz hospital->HODOM |

**Recomendacion:** Incluir un slide con "Tablero de indicadores propuesto para H2" que liste estos KPIs con su frecuencia de reporte y fuente de datos.

---

### 1i. Evidencia internacional

**Calificacion: CORRECTA Y PERTINENTE, con un matiz**

Las referencias citadas son las adecuadas:

| Referencia | Evaluacion |
|------------|-----------|
| **Lancet Regional Health, junio 2025** | Probablemente se refiere al meta-analisis reciente. Es pertinente. Verificar titulo exacto y que sea accesible si alguien lo pide. |
| **Levine et al., Ann Intern Med 2020** | Es EL ensayo clinico fundacional del modelo CMS en EEUU. Correcto y necesario. |
| **CMS Report to Congress 2024 / Fact Sheet** | Correcto. Es la evaluacion regulatoria mas grande del mundo sobre HAH. |
| **Cochrane Reviews** | Correcto. Hay multiples (Edgar 2024 para admission avoidance, Shepperd/Goncalves-Bradley para early discharge). Especificar cual se cita para evitar ambiguedad. |
| **Caplan 2012** | Es un meta-analisis clasico (MJA). Sigue siendo citado pero tiene 14 anos. No es un problema, pero si alguien pregunta, existen revisiones mas recientes (HTA New York 2025, que integra toda la evidencia anterior). |
| **Shepperd et al. 2022** | RCT NIHR multicentrido UK. Correcto. |

**Referencia faltante clave:**
- **HTA New York (Connor et al., Nov 2025)**: Es la revision sistematica mas completa y reciente del corpus (380K caracteres, 14 publicaciones de 10 RCTs, meta-analisis GRADE). Es la fuente primaria del corpus HAH de las KBs. Si Felix quiere una referencia "nuclear" para defender la evidencia, esta es la mejor. Tiene los meta-analisis mas robustos: mortalidad sin diferencia, reingresos 30d OR 0,72 (favor HAH), traslado a larga estancia OR 0,03 (fuerte favor HAH), satisfaccion superior en 5/5 RCTs.

**Matiz importante:** La evidencia tiene certeza baja a moderada (GRADE) para la mayoria de outcomes. La presentacion ya lo dice ("certeza baja a moderada"), lo cual es correcto y honesto. No inflarlo.

---

## 2. RECOMENDACIONES PARA EL GUION ORAL, SLIDE POR SLIDE

### Estructura general sugerida
- **Duracion total:** 25-30 minutos de presentacion + 15-20 minutos de preguntas.
- **Ritmo:** 60-90 segundos por slide informativo, 2-3 minutos por slide de argumento clave.
- **Tono:** Profesional, mesurado, basado en datos. No defensivo. No apologetico. Postura de quien rinde cuentas y propone.

### Slide por slide

**Slide 1 -- Portada** (15 seg)
- Solo nombrar titulo, fecha, cargo.
- NO hacer preambulos largos ni agradecer excesivamente. Ir directo.

**Slide 2 -- Proposito y alcance** (90 seg)
- Enfatizar: "Esto se basa en tres anos de operacion real y en datos propios, no en literatura solamente."
- Leer el blockquote final: "Esta presentacion busca validacion institucional..."
- NO decir "vengo a pedir permiso". Decir "vengo a proponer un camino y buscar alineamiento."

**Slide 3 -- Tesis central** (2 min)
- Este es el slide mas importante de toda la presentacion. Tomarse tiempo.
- Frase clave: "La brecha no es de sentido, es de consolidacion."
- La tabla Consolidar/Integrar/Optimizar es poderosa. Leerla.
- Cita final: "No vengo a presentar una idea nueva..." -- decirla mirando al Director.
- NO decir "HODOM funciona mal" o "estamos desordenados". Decir "lo que funciona merece estructura para ser sostenible."

**Slide 4 -- Evidencia internacional** (90 seg)
- Pasar rapido. No es el corazon de la presentacion.
- Dato clave: "Costos 19-32% menores. Mortalidad igual o mejor. Esto no es experimental."
- NO entrar en detalles metodologicos. Si preguntan, responder con "la evidencia es de certeza baja a moderada, que es el estandar en intervenciones complejas."
- NO DECIR: "En Estados Unidos..." como si fuera argumento. Decir: "Hay mas de 30 paises con programas activos, y Chile tiene regulacion propia desde 2022."

**Slide 5 -- Contexto demografico** (60 seg)
- Dato killer: "Por cada 100 menores de 15, hay 97,6 personas de 65+ en Nuble."
- Conectar: "Nuestra poblacion HODOM tiene 70 anos promedio. Atendemos exactamente la poblacion que mas crece y mas demanda."
- NO entrar en proyecciones demograficas largas. Dato, conexion, seguir.

**Slide 6 -- Urgencia hospitalaria local** (2 min)
- ESTE ES EL SLIDE QUE VENDE LA PRESENTACION. Detenerse.
- Leer la serie: "De 96,8% a 40,6% en seis anos."
- Pausa. Dejar que el dato resuene.
- Luego los indices ocupacionales: "Medicina 97,5. Cirugia 96. Traumatologia 97,9. Area quirurgica 98,1."
- Frase: "Cada paciente que puede hospitalizarse en su domicilio con seguridad es una cama disponible para quien no tiene esa alternativa."
- NO culpar a nadie por el deterioro. Es una tendencia nacional. San Carlos no es excepcion.
- NO DECIR: "El hospital esta colapsado." Decir: "La capacidad de respuesta se ha deteriorado significativamente."

**Slide 7 -- Campana de Invierno** (60 seg)
- Dato: campana ya activada, HODOM ya reconocida como dispositivo en 2024.
- Frase: "Fortalecer HODOM no es un proyecto accesorio. Es una medida concreta de preparacion hospitalaria."
- TRAMPA POLITICA: si el Director percibe que HODOM se posiciona SOLO como herramienta de invierno, se pierde el argumento del plan anual. Agregar oralmente: "Campana de Invierno es la urgencia inmediata, pero el plan que presento es para todo el ano."

**Slide 8 -- HODOM en cifras** (90 seg)
- Enfatizar el "0 muertes no esperadas". Repetirlo.
- Si se agrego la tasa de reingresos (3,4%), mencionarla: "Nuestra tasa de reingresos es 3,4%, inferior al benchmark nacional."
- Si se agrego estancia media, mencionarla brevemente.
- NO leer toda la tabla. Destacar los tres datos mas impactantes: personas atendidas, visitas, cero muertes.

**Slide 9 -- Perfil de la poblacion** (60 seg)
- Dato clave: "FONASA A y B 87,6%. Atendemos poblacion vulnerable."
- Conectar: "No es seguimiento domiciliario. Es hospitalizacion activa en el domicilio."
- NO entrar en la lista de diagnosticos. Demasiado clinico para este auditorio.

**Slide 10 -- Punto de partida** (60 seg)
- Enfatizar el proyecto BIP como respaldo institucional formal.
- Frase: "No se defiende una iniciativa individual. Se propone consolidar un activo que la institucion ya reconocio como valioso."
- NO listar todos los activos. Destacar BIP + equipo con experiencia + infraestructura operativa.

**Slide 11 -- Que es y que no es HODOM** (90 seg)
- Slide defensivo pero necesario. Leerlo con calma.
- Frase killer: "Los pacientes HODOM son pacientes hospitalizados. El domicilio es el lugar de atencion, no el nivel de atencion."
- Este slide previene la objecion "HODOM es para sacar pacientes del hospital".
- TRAMPA POLITICA: si alguien dice "pero ustedes atienden cosas sencillas", responder: "El 45% de nuestros pacientes recibe tratamiento endovenoso. Eso es atencion cerrada."

**Slide 12 -- Anclaje normativo** (60 seg)
- Pasar relativamente rapido. La tabla esta clara.
- Enfatizar: "No estamos inventando nada. El marco normativo ya existe. Lo que proponemos es cumplirlo plenamente."
- NO leer toda la tabla. Mencionar DS 1/2022 y NT 2024 como los dos pilares.

**Slide 13 -- Diagnostico consolidado** (90 seg)
- Leer las fortalezas primero (genera confianza).
- Luego las brechas: "Cada brecha tiene solucion conocida. Ninguna requiere inversion extraordinaria."
- NO enfatizar las brechas mas de lo necesario. El Director no necesita sentir que la unidad esta mal. Necesita sentir que hay un plan para cerrar brechas identificadas.

**Slide 14 -- Brecha vs estandar** (90 seg)
- Este slide es para quien quiera detalle. Pasarlo rapido si el auditorio se ve saturado.
- Destacar solo las prioridades "Critica" y "Alta".
- NO leer toda la tabla. Decir: "Hay 10 dimensiones con brecha identificada, la mayoria de prioridad alta, todas con solucion conocida."

**Slide 15 -- Estado objetivo** (60 seg)
- Los 8 puntos son correctos. No leerlos todos.
- Decir: "El objetivo es que HODOM pueda sostenerse ante auditoria, demostrar su aporte con datos, y proyectar su desarrollo con evidencia."

**Slide 16 -- Principios rectores** (60 seg)
- La jerarquia de principios es estrategicamente correcta: seguridad > normativa > continuidad > trazabilidad > productividad.
- Frase clave: "Ordenar sin rigidizar. Formalizar sin burocratizar. Mejorar sin sobrecargar."
- NO explicar cada principio. Leer la frase final y seguir.

**Slide 17 -- Flujos criticos** (90 seg)
- El diagrama ASCII es claro. Leerlo de izquierda a derecha.
- Enfatizar las 4 interfaces criticas.
- Si se agrego la distincion evitacion de ingreso vs alta precoz, mencionarla aqui.
- NO decir "esto no funciona hoy". Decir "estas interfaces necesitan formalizarse."

**Slide 18 -- El cuidador** (60 seg)
- Frase potente: "El cuidador no es mano de obra gratuita. Es un integrante de la unidad de cuidado."
- Mirar a la SDGC al decir esto. Es su territorio.
- NO entrar en detalles de instrumentos de evaluacion salvo que pregunten.

**Slide 19 -- Estrategia en 3 horizontes** (2 min)
- Este es el segundo slide mas importante. Tomarse tiempo.
- Leer por columnas, no por filas: primero H1 completo, luego H2, luego H3.
- Frase: "Cada horizonte se sustenta en el anterior. No se salta etapas."
- Si se ajusto el porcentaje de productividad a +30-40%, usar ese numero.
- NO prometer fechas exactas de H3. Decir "desde el tercer mes".

**Slide 20 -- Capacidad operativa recuperable** (2 min)
- El analisis GPS es el argumento empirico mas original de la presentacion.
- Dato killer: "La flota podria pasar de 24 a 36-40 visitas/dia sin vehiculos ni personal adicional."
- Si se ajusto a +30-40%, presentar asi: "Estimamos conservadoramente que podemos aumentar un 30-40% la capacidad con las mismas personas y vehiculos."
- TRAMPA POLITICA: NO presentar esto como "estamos trabajando poco". Presentar como "tenemos holgura operativa que podemos activar con mejor coordinacion."
- NO decir "productividad de 39%". Decir "la ventana operativa real es menor que la jornada formal, y hay espacio para optimizar."

**Slide 21 -- Activos disponibles** (60 seg)
- Pasar rapido. El mensaje es "no partimos de cero en ninguna dimension."
- Destacar: equipo con experiencia + infraestructura + datos + normativa.

**Slides 22-23 -- hdos-app** (2 min para ambas)
- Ser breve y estrategico. No vender tecnologia; vender capacidad de trazabilidad y gestion.
- Frase: "La digitalizacion util no es promesa futura. Es trabajo ya en curso."
- La evaluacion independiente citada fortalece la credibilidad. Mencionarla.
- TRAMPA POLITICA: NO presentar hdos-app como proyecto personal o de informatica. Presentarlo como "sistema de informacion para la unidad" con foco en registros auditables y reportabilidad.
- NO decir "110 pantallas" ni "131 tablas" al Director. Eso es para tecnicos. Decir "cubre admision, ficha clinica, visitas, indicadores y reportes normativos."

**Slide 24 -- Aporte al hospital** (90 seg)
- 10 dimensiones de aporte. No leer todas.
- Destacar las 3 que mas importan al Director: capacidad instalada, oportunidad de hospitalizacion, y Campana de Invierno.
- Destacar la que mas importa a la SDGC: calidad percibida y articulacion con APS.
- Frase: "HODOM no compite con el hospital. Lo complementa."

**Slide 25 -- Validacion institucional** (2 min)
- Este slide es la "pregunta" de la presentacion. Leerlo con claridad.
- 5 puntos de validacion. Cada uno es una decision que se espera del auditorio.
- NO presentar como demanda. Presentar como propuesta.
- Mirar al Director cuando se lea cada punto.
- ESTE ES EL MOMENTO DE PREGUNTAR: "Desean que me detenga en alguno de estos puntos?"

**Slide 26 -- Horizonte de implementacion** (90 seg)
- Resumen ejecutivo de los 3 horizontes con hitos verificables.
- Frase: "Cada hito es verificable. Cada plazo es realista."
- NO agregar mas detalle. Este slide es para cierre, no para discusion.

**Slide 27 -- Cierre** (30 seg)
- Leer la frase central: "La pregunta ya no es si HODOM sirve. La pregunta es cuanto mas puede aportar al hospital si se le da la estructura que su valor demostrado merece."
- Pausa. Mirar al auditorio.
- "Quedo disponible para preguntas."

---

## 3. ELEMENTOS FALTANTES

### 3.1 Elementos que un Director de hospital esperaria ver

1. **Numero de camas virtuales equivalentes**: Traducir los dias-persona a camas virtuales diarias promedio. Es el dato que el Director puede comparar con su dotacion de 130 camas fisicas.

2. **Costo relativo dia-cama HODOM vs intrahospitalario**: Aunque sea una estimacion gruesa basada en la evidencia internacional aplicada al costo dia-cama del hospital, este dato cierra la conversacion financiera.

3. **Organigrama propuesto**: Un diagrama simple de gobernanza (Direccion -> SDM -> DT HODOM, con linea funcional a SDGC).

4. **Dotacion actual vs. minima normativa**: Cuantas personas tiene HODOM hoy vs. lo que exige la norma tecnica.

5. **Tasa de reingresos calculada**: El dato crudo esta (72/2.135 = 3,4%) pero no se presenta como indicador.

6. **Estancia media**: Ausente completamente.

7. **Proyeccion de demanda para invierno 2026**: Basada en datos historicos de inviernos anteriores, cuantos pacientes adicionales se esperan y cuanta capacidad HODOM puede absorber.

### 3.2 Elementos que podrian mejorar la presentacion pero no son criticos

8. **Mapa territorial**: Una imagen que muestre la cobertura geografica de HODOM (58% urbano, 16% periurbano, 19% rural cercano, 7% rural lejano) seria visualmente potente.

9. **Caso clinico tipo**: Un ejemplo anonimizado de un paciente real (ej: "Mujer de 78 anos, ITU complicada, 8 dias en HODOM, tratamiento EV completo, alta a APS sin reingreso") humaniza los datos.

10. **Satisfaccion del paciente/familia**: Si hay algun dato, aunque sea informal, incluirlo. Es un argumento de alto impacto politico ante la SDGC y ante Direccion.

---

## 4. PREGUNTAS DIFICILES ANTICIPADAS

### Pregunta 1: "Cuanto cuesta HODOM al hospital?"
**Respuesta sugerida:** "No tenemos aun un costeo local preciso, y eso es parte del plan de H2 con indicadores. Lo que sabemos es que la evidencia internacional consistentemente muestra costos 19-32% menores que la hospitalizacion tradicional. Ademas, cada dia-cama HODOM es una cama fisica disponible para pacientes de mayor complejidad que si generan costos altos. El beneficio de HODOM no es solo su costo directo, sino la cama que libera."

### Pregunta 2: "Si tienen 60% de capacidad ociosa, no estan trabajando poco?"
**Respuesta sugerida:** "La capacidad ociosa no se explica por falta de compromiso del equipo. Se explica por ventanas operativas no optimizadas: horarios de inicio, almuerzo no escalonado, cierre anticipado de la jornada. El analisis GPS nos muestra exactamente donde esta la holgura y como activarla. Lo que proponemos en H1 es precisamente eso: reorganizar la operacion para recuperar esa capacidad."

### Pregunta 3: "Por que no estan cumpliendo la norma tecnica hoy?"
**Respuesta sugerida:** "Porque HODOM ha operado como dispositivo de contingencia activado periodicamente, no como unidad permanente. El protocolo PRO-002 se escribio en 2022 para una realidad diferente. Lo que propongo es la transicion de dispositivo de contingencia a unidad permanente con cumplimiento normativo pleno. Para eso es el plan de evolucion."

### Pregunta 4: "Quien se hace responsable si un paciente se muere en la casa?"
**Respuesta sugerida:** "La responsabilidad medico-legal es la misma que en hospitalizacion intrahospitalaria. El paciente HODOM esta bajo regimen de internacion con indicacion medica activa, regulacion clinica diaria y protocolo de escalamiento. En tres anos de operacion tenemos cero muertes no esperadas. Lo que el plan agrega es protocolo de escalamiento formal, trazable y auditable, que hace defendible cada decision ante una eventual auditoria."

### Pregunta 5: "El sistema de informacion no es un gasto excesivo para una unidad tan chica?"
**Respuesta sugerida:** "hdos-app no es un sistema que compramos ni una inversion externa. Es un desarrollo propio, incremental, construido sobre las necesidades operativas reales de la unidad. Su costo marginal es bajo y su valor es alto: registros auditables, ficha clinica conforme a la ley, indicadores automaticos, reportabilidad MINSAL. La alternativa es seguir con planillas y papel, que no pasan una auditoria."

### Pregunta 6: "Como garantizan que los pacientes en domicilio esten seguros?"
**Respuesta sugerida:** "Tres mecanismos. Primero: criterios de elegibilidad estrictos, tanto clinicos como sociales, incluyendo evaluacion de cuidador y domicilio. Segundo: visitas domiciliarias con tratamiento activo y regulacion clinica diaria. Tercero: protocolo de escalamiento con rescate hospitalario, es decir, si un paciente se deteriora, hay un protocolo para traerlo de vuelta al hospital. En tres anos, cero muertes no esperadas."

### Pregunta 7: "Que pasa si el equipo se va? HODOM depende de personas, no de estructura."
**Respuesta sugerida:** "Exactamente ese es el problema que el plan resuelve. Hoy HODOM funciona por compromiso del equipo. El plan de evolucion busca que funcione, ademas, por diseno institucional: protocolos documentados, registros auditables, roles definidos, gobernanza formal. Si alguien se va, el sucesor encuentra un sistema, no un vacio."

### Pregunta 8: "Los CESFAM reciben bien a los pacientes de HODOM?"
**Respuesta sugerida:** "El enlace piloto con APS esta en marcha pero la contrarreferencia no esta plenamente estructurada. Es una de las brechas identificadas. En H2 proponemos una epicrisis estandarizada con campos minimos para APS y un protocolo de seguimiento 48 horas post-alta con verificacion de recepcion. Necesitamos que la Direccion facilite el dialogo con la Direccion de APS para formalizar este flujo."

### Pregunta 9: "Todo esto es interesante, pero que necesitas concretamente de nosotros?"
**Respuesta sugerida:** "Cinco cosas. Una: que compartamos el diagnostico. Dos: que la estrategia de tres horizontes sea un camino institucional, no solo de la direccion tecnica. Tres: que las acciones del primer horizonte, que no requieren recursos adicionales, cuenten con respaldo para implementarse. Cuatro: que se formalice la estructura de gobernanza con SDM y SDGC. Cinco: que hdos-app sea reconocido como activo institucional."

### Pregunta 10: "Y si no validamos este plan, que pasa?"
**Respuesta sugerida:** "HODOM seguira funcionando porque el equipo esta comprometido. Pero seguira funcionando con registros dispersos, sin gobernanza formal, sin indicadores de desempeno y sin cumplimiento normativo pleno. Eso significa que no sera defendible ante auditoria, no podra demostrar su impacto con datos, y no podra proyectar su desarrollo. La pregunta no es si HODOM seguira operando. La pregunta es si lo hara con la estructura que le permita aportar todo lo que puede al hospital."

---

## 5. OBSERVACIONES ESTRATEGICAS FINALES

### 5.1 Posicion politica
Felix se presenta como Director Tecnico que rinde cuentas, no como alguien que pide cosas. La postura correcta es: "He hecho un diagnostico riguroso, propongo un camino con hitos verificables, y busco alineamiento institucional." Esto es mas fuerte que pedir autorizacion.

### 5.2 Audiencia diferenciada
- **Director del Hospital (Goza)**: Le importan camas, costos, Campana de Invierno, riesgo legal. Hablarle en camas liberadas y riesgo.
- **Subdirector Medico**: Le importa gobierno clinico, seguridad del paciente, protocolos de escalamiento. Hablarle en mortalidad cero y criterios de elegibilidad.
- **Subdirectora de Gestion del Cuidado**: Le importa enfermeria, cuidador, continuidad, calidad percibida. Hablarle en cuidado integrado y evaluacion del cuidador.

### 5.3 Lo que NO decir
- No usar la palabra "piloto" o "proyecto". HODOM tiene 3 anos. Es una unidad.
- No decir "necesitamos mas recursos" en esta reunion. El H1 se plantea sin recursos adicionales. Ese es el argumento.
- No criticar la gestion anterior ni apuntar a personas. El diagnostico es de brechas de sistema, no de fallas individuales.
- No prometer plazos que no se puedan cumplir. Mejor prometer menos y cumplir mas.
- No entrar en jerga tecnica de informatica cuando se habla de hdos-app. El Director no necesita saber que son 131 tablas PostgreSQL.

### 5.4 Norma Tecnica 243 de mayo 2025
La presentacion no menciona la Norma Tecnica N. 243 de mayo 2025, que reordena la taxonomia hospitalaria y establece que la HD es un **proceso asistencial transversal** disponible en los tres niveles de atencion (Hospitales Comunitarios, Provinciales, Regionales). Si San Carlos califica como Hospital Provincial, esta norma refuerza que HODOM no es un agregado opcional sino un proceso transversal esperado en su nivel. Considerar mencionarla en el slide de anclaje normativo.

### 5.5 Financiamiento MCC y codigo 0201408
La presentacion no menciona la Modalidad de Cobertura Complementaria (MCC) ni el codigo 0201408 ("Dia Cama de Hospitalizacion Domiciliaria de Baja Complejidad"). Si bien HODOM HSC atiende predominantemente FONASA A y B, la existencia de este codigo demuestra que el sistema financiero ya reconoce la HD como prestacion con arancel propio. Es un argumento de legitimidad ante el Director.

---

**Documento producido por Salubrista (copiloto estrategico) para Dr. Felix Sanhueza G.**
**Fuentes consultadas:** corpus-hah-completo.md, director/03-situacion-chile-2026.md, normativa/03-norma-tecnica-hodom-2024.md, director/01-manual-direccion-tecnica.md, presentacion-evolucion-hodom-goza-2026-04-10.md
