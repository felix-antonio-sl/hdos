# HODOM OS v1
## Sistema Operativo de Hospitalización Domiciliaria — Hospital de San Carlos
### Artefacto de conocimiento refactorizado | 2026-03-25

---

# Propósito de este documento
Una sola pieza, limpia y accionable, que reemplaza la dispersión acumulada.
Todo lo que necesitas saber, decidir, mostrar y construir para la nueva etapa de HODOM HSC está aquí.

---

# I. SITUACIÓN

## El hospital
- 130 camas
- centro de referencia red norte Ñuble (10 comunas)
- hospitalización ≤12h adulto: **96,8% (2019) → 40,6% (2025)**
- ocupación 2025: medicina 97,5 | cirugía 96,0 | trauma 97,9
- presión adicional por demanda extrarred (Maule, Chillán)

## HODOM hoy
- 3 años de operación (2023-2025)
- 2.135 personas atendidas
- 0 fallecidos no esperados
- 20-21 cupos simultáneos
- 26.000+ visitas acumuladas
- equipo multidisciplinario con experiencia real de terreno
- proyecto BIP 40059567-0 formulado para implementación permanente
- enlace piloto con APS / Programa Postrados en marcha blanca

## Diagnóstico en una frase
**Unidad valiosa que opera por debajo de su potencial, con alta dependencia del esfuerzo informal y brechas relevantes de gobernanza clínica, trazabilidad, rendimiento operativo y soporte tecnológico.**

---

# II. PROBLEMAS REALES

## 1. Gobernanza clínica
- no existe instancia formal de regulación de casos
- cada médico lleva "sus" pacientes sin alternancia suficiente
- altas decididas sin criterio homogéneo ni supervisión
- baja productividad médica presencial
- media jornada médica inestable que dificulta programación
- paradigma excesivamente presencial

## 2. Registro y trazabilidad
- médicos registran en papel; otros perfiles usan SGH
- dispersión documental: papel + planillas + Excel + Drive
- sin identificador único de episodio
- sin registro digital operativo compartido
- imposible medir, auditar ni rendir cuentas con lo actual

## 3. Rendimiento operativo
- tiempos muertos relevantes al inicio, mediodía y franja tardía
- jornada formal 12h pero operación real ~9h
- 1.818 horas de capacidad vehicular ociosa en un trimestre
- rutas sin optimización territorial ni georreferenciación activa
- oportunidad de +8-12 visitas/día sin recursos adicionales

## 4. Cumplimiento normativo
- protocolo PRO-002 desactualizado para unidad permanente
- escalamiento clínico sin formalización robusta
- evaluación domiciliaria no homogénea ni trazable
- contrarreferencia/alta no estandarizadas
- O₂ domiciliario y sueroterapia con acuerdos pero sin protocolo formal

## 5. Continuidad hospital-domicilio-red
- enlace APS incipiente
- contrarreferencia informal
- derivación desde hospital sin screening activo

## 6. Capacidad clínica subutilizada
- 3 concentradores de O₂ sin uso
- sueroterapia no desplegada
- cartera real más estrecha que la posible

---

# III. TRES HORIZONTES

## H1 — Mejor rendimiento con lo que ya tenemos
**Foco:** hacer que la unidad funcione mejor ahora, sin recursos nuevos.

| Eje | Qué significa |
|-----|--------------|
| Más visitas | aprovechar mejor el día, los km, los tiempos |
| Menos tiempos muertos | reordenar salidas, bloques, retornos |
| Regulación clínica | instancia diaria de revisión de casos (DT como médico regulador) |
| Mejor registro | digital, simple, desde celular, imprimible |
| Mejor coordinación | briefing, tablero, tareas visibles |
| Capacidad clínica | reactivar sueroterapia y oxigenoterapia |
| Teleatención útil | seguimiento, regulación y control remoto cuando sea pertinente y seguro |
| Cierres normativos urgentes | escalamiento, elegibilidad, evaluación domiciliaria |

## H2 — Cumplimiento normativo y consolidación formal
**Foco:** dejar la unidad defendible, trazable y segura.

| Eje | Qué significa |
|-----|--------------|
| DS 1/2022 + NT 2024 | cerrar checklist normativo completo |
| Protocolos | núcleo mínimo usable (15 procesos) |
| Registros auditables | ficha clínica cumpliendo Ley 20.584 |
| Seguridad del paciente | escalamiento, eventos adversos, rescate |
| Gobernanza | roles, supervisión, subrogancia, comités |
| Indicadores | tablero mensual con pocos KPIs realmente útiles |
| Capacitación | plan semestral formal |

## H3 — Máxima expresión del potencial
**Foco:** amplificar capacidad sin crecer linealmente en gasto.

| Palanca | Aplicación |
|---------|-----------|
| Tecnología | sistema operativo HODOM completo |
| IA | apoyo a priorización, regulación, gestión |
| Automatización | registros, alertas, reportes, rutas |
| Digitalización | cero papel operativo innecesario |
| Gestión del conocimiento | aprendizaje organizacional acumulado |
| Capacitación continua | basada en brechas reales |
| Gestión de campo | optimización territorial y logística |
| Cultura | calidad, seguridad, innovación como práctica |

---

# IV. PRINCIPIOS DE DISEÑO

## 1. Menor carga cognitiva
Toda herramienta, flujo o cambio debe reducir carga mental, no aumentarla.

## 2. Una sola fuente de verdad
No más planillas compitiendo.

## 3. Registrar una vez, usar muchas
Una captura que sirva para clínica, coordinación, impresión, indicadores y continuidad.

## 4. Visibilidad compartida
La información crítica no puede vivir en un cuaderno o en una persona.

## 5. Regulación clínica común
No pacientes "de cada uno". Unidad con criterio compartido.

## 6. Presencialidad inteligente
No todo acto médico requiere ir al domicilio.

## 7. Papel mínimo, no cero dogmático
Digital first. Impresión cuando sea necesario.

## 8. Iteración rápida
Prototipos cortos. Ajustes rápidos. Sin enamorarse del diseño inicial.

## 9. Simplicidad radical
Lo breve y usable vale más que lo perfecto e inutilizable.

## 10. Continuidad del cuidado
Hospital → domicilio → APS → rescate: siempre visible.

---

# V. CAPA OPERATIVA DIGITAL — PROTOTIPOS

## P1. Panel general
- censo: pacientes activos, cupos, alertas
- ingresos/altas pendientes
- móviles y rutas del día
- procedimientos críticos
- pendientes y tareas
- recursos disponibles

## P2. Registro móvil de atención
- formulario breve por disciplina
- signos vitales, procedimiento, nota corta
- captura de voz para comentarios
- georreferencia automática opcional
- imprimible en formato ficha papel

## P3. Regulación clínica
- casos nuevos / alertas / egresos posibles / rescates
- decisión del regulador
- responsable y plazo
- huella de decisión

## P4. Georreferenciación y rutas
- mapa de pacientes activos
- macrozonas y agrupación territorial
- rutas sugeridas por móvil
- km y tiempo estimado

## P5. Ingreso / evaluación domiciliaria
- elegibilidad clínica
- evaluación domicilio/cuidador
- decisión: apto / apto con condiciones / no apto
- cupo

## P6. Alta y contrarreferencia
- resumen clínico
- indicaciones
- destino APS/CESFAM
- seguimiento
- imprimible/enviable

## P7. Teleatención / telecontrol HODOM
- app web ultraligera, optimizada para smartphone
- voz, video y chat en navegador, sin instalar app
- acceso del paciente/cuidador por link único
- consentimiento digital previo y auditable
- registro clínico post-sesión obligatorio
- degradación elegante: video → audio → chat
- no grabar por defecto
- impresión del registro para ficha papel
- integrada al censo, al episodio activo y a la regulación clínica

### Specs núcleo de teleatención
| Componente | Decisión mínima |
|------------|-----------------|
| Tipo de app | PWA mobile-first |
| Canal clínico | WebRTC cifrado + chat |
| Acceso paciente | link único por SMS/WhatsApp |
| Acceso profesional | desde panel HODOM con login |
| Registro | profesional, paciente, episodio, fecha/hora, modalidad, motivo, hallazgos, plan, alerta |
| Consentimiento | previo, trazable, revocable |
| Seguridad | HTTPS, autenticación, sesiones temporales, datos mínimos |
| Integración | panel HODOM OS, impresión, alertas, vista del regulador |

---

# VI. PROTOCOLOS MÍNIMOS

Formato: una página por proceso. Propósito → cuándo aplica → criterios → pasos → responsables → red flags → qué registrar.

| # | Protocolo |
|---|-----------|
| 1 | Ingreso / elegibilidad |
| 2 | Evaluación domiciliaria y cuidador |
| 3 | Regulación / revisión de casos |
| 4 | Escalamiento clínico (semáforo + NEWS2) |
| 5 | Alta / contrarreferencia |
| 6 | Registro clínico mínimo |
| 7 | Manejo de medicamentos en domicilio |
| 8 | Toma y transporte de muestras |
| 9 | Sueroterapia |
| 10 | Oxigenoterapia domiciliaria |
| 11 | Coordinación APS / Postrados |
| 12 | Teleatención / telecontrol médico |
| 13 | Rutas y gestión de campo |
| 14 | Eventos adversos / incidentes |
| 15 | Educación al paciente/cuidador |

## Requisitos mínimos del protocolo 12 — Teleatención / telecontrol médico
- indicación clínica explícita y pertinencia de modalidad remota
- consentimiento informado previo, registrado y revocable
- identificación de profesional y paciente
- canal seguro con voz, video y chat, con fallback si falla la conexión
- registro clínico obligatorio equivalente al presencial
- posibilidad de escalar a evaluación presencial si la calidad o el riesgo clínico lo exige
- no grabación por defecto; solo con autorización explícita adicional

---

# VII. RECURSOS A ORDENAR

## RRHH
- planilla maestra: nombre, rol, jornada, horas, disponibilidad, teléfono, competencias
- distribución médica: presencial / regulación / teleatención
- cobertura y reemplazos

## Vehículos
- 3 móviles: patente, estado, límite km, conductor, equipamiento
- control diario: salida, regreso, km, incidencias

## Insumos y medicamentos
- stock crítico visible
- punto de reorden
- asignación por ruta/paciente

## Equipamiento
- 3 concentradores O₂
- monitores, oxímetros, DEA, ECG portátil
- maletines de terreno

---

# VIII. PRESENTACIÓN AL EQUIPO

## Estructura (10 slides)

| # | Contenido |
|---|-----------|
| 1 | Título: consolidar, cerrar brechas, proyectar |
| 2 | Objetivo de la reunión |
| 3 | Lo que el equipo ya logró (resultados) |
| 4 | Por qué HODOM importa para el hospital (presión, camas, oportunidad) |
| 5 | Estado actual: valor + brechas |
| 6 | Horizonte 1: mejor rendimiento con lo que tenemos |
| 7 | Horizonte 2: cumplimiento normativo |
| 8 | Horizonte 3: máxima expresión del potencial |
| 9 | Cómo lo vamos a hacer (simple, por capas, baja carga cognitiva) + demo |
| 10 | Lo que pido y lo que comprometo |

## Narrativa
- reconocer antes de diagnosticar
- diplomacia firme, no blanda
- brechas del dispositivo, no del equipo
- tono: "valor demostrado + capacidad no plenamente desplegada"
- nunca: "anárquico", "desordenado", "improvisado"
- siempre: "informal", "no suficientemente consolidado", "por debajo de su potencial"

## Frases clave
- "No vengo a partir de cero."
- "Lo que existe merece ser reconocido, pero también protegido."
- "La pregunta ya no es si HODOM sirve, sino cuánto más podría aportar."
- "Todo lo que implementemos debe disminuir carga cognitiva."
- "Primero optimizar. Luego consolidar. Después amplificar."

---

# IX. HOJA DE RUTA

## Semana 1 (arranque 1 de abril)
- panel general operativo
- briefing digital
- registro móvil básico
- regulación de casos
- inventario RRHH / vehículos / O₂ / insumos
- reactivación sueroterapia y oxigenoterapia
- diseño validado del módulo de teleatención HODOM

## Semana 2
- ingreso + evaluación domicilio digital
- alta + contrarreferencia
- escalamiento digital
- georreferenciación activa
- impresión de formularios
- consentimiento digital y registro post-teleatención

## Semana 3
- tablero de indicadores
- control de insumos/medicamentos
- repositorio documental
- roles y permisos
- prototipo funcional PWA de teleatención

## Semana 4
- telecontroles médicos
- ajustes por retroalimentación
- protocolo mínimo consolidado v1
- cierre primera iteración
- salida controlada de teleatención para uso real

---

# X. NORMATIVA RECTORA

| Instrumento | Relevancia |
|-------------|-----------|
| DS N°1/2022 | Reglamento HODOM |
| DE N°31/2024 | Norma Técnica HD 2024 |
| Ley 21.541 | Autoriza atenciones mediante telemedicina |
| Norma General Técnica N°237 | Estándares para prestaciones de salud a distancia y telemedicina |
| Ley 21.668 | Interoperabilidad de fichas clínicas |
| Ley 20.584 | Derechos del paciente |
| Decreto 41 | Reglamento de fichas clínicas |
| Decreto 31 | Reglamento de consentimiento informado |
| Ley 19.628 | Protección de datos |
| PRO-002 HSC | Protocolo vigente (requiere actualización) |
| BIP 40059567-0 | Proyecto implementación permanente |

---

# XI. ACTIVOS EXISTENTES

| Categoría | Contenido |
|-----------|-----------|
| Drive histórico | formularios, planillas, consolidados, epicrisis, rutas, entregas de turno |
| Datos | catastro pacientes, rutas históricas, telemetría GPS, consolidados por profesional |
| Normativa | DS 1/2022, NT 2024, PRO-002, BIP, acuerdos O₂, enlace APS |
| Infraestructura tech | dominio disponible, acceso CLI a SGH, capacidad de deploy rápido |
| Equipamiento | 3 concentradores O₂, monitores, oxímetros, DEA, ECG, 3 móviles |

---

# XII. DECISIONES INAMOVIBLES

1. El tono diplomático es estratégico, no decorativo.
2. El diagnóstico real reconoce subutilización y baja madurez operativa.
3. La baja carga cognitiva es criterio de diseño, no aspiración.
4. La regulación clínica del DT es estructurante, no opcional.
5. El panel web se estrena como posibilidad concreta, no como sistema definitivo.
6. La teleatención será una PWA ultraligera: smartphone-first, sin app store y sin cuenta para el paciente.
7. Los protocolos deben ser de una página, no manuales.
8. La sueroterapia y oxigenoterapia se reactivan como señal de capacidad recuperada.
9. La continuidad hospital-domicilio-APS debe ser visible, no implícita.
10. Cada herramienta nueva debe demostrar que reduce fricción real.
11. Toda teleatención exige consentimiento previo, registro clínico post-sesión y canal seguro.
12. Todo queda documentado nativamente para no depender de la memoria conversacional.

---

# XIII. COLABORADORES OPERATIVOS

| Actor | Rol | Canal |
|-------|-----|-------|
| Salubrista-HaH | copiloto técnico HD/hospitalización integrada | este agente |
| Korax | extensión cognitiva personal de Félix, organización y producción | hook federado `kora-personal:18789` |
| Equipo de desarrollo | prototipado rápido web/mobile | instrucción directa de Félix |

---

*HODOM OS v1 — artefacto de conocimiento refactorizado*
*Todo lo necesario para arrancar. Nada que sobre.*
*2026-03-25*
