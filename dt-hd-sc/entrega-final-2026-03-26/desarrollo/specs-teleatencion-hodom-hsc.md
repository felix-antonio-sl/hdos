# HODOM Tele — Specs de teleatención domiciliaria
## App web mínima para smartphone | Hospital de San Carlos
### Principio: la herramienta más simple que cumpla toda la normativa

---

# 1. Concepto

Una **PWA (Progressive Web App)** ultraligera, mobile-first, sin necesidad de instalar desde app store, que permite al equipo HODOM hacer teleatención (voz, video, chat) con pacientes/cuidadores y entre profesionales, cumpliendo la normativa chilena vigente.

**No es un sistema clínico completo.** Es una capa de comunicación clínica trazable que se integra al panel HODOM OS.

---

# 2. Base normativa que debe cumplir

| Norma | Requisito clave para la app |
|-------|---------------------------|
| **Ley 21.541** | habilita atenciones de salud a distancia; mismos derechos que presencial |
| **NT N°237** | estándares técnicos para prestaciones a distancia y telemedicina |
| **Ley 20.584** | derechos del paciente: información, consentimiento, confidencialidad, registro |
| **Ley 19.628** | protección de datos personales |
| **Ley 21.668** | interoperabilidad de fichas clínicas |
| **Decreto 41** | reglamento de fichas clínicas |
| **Decreto 31** | consentimiento informado |
| **DS N°1/2022** | reglamento HODOM: registros, seguridad, continuidad |
| **NT HD 2024** | norma técnica hospitalización domiciliaria |

---

# 3. Requisitos normativos traducidos a specs

## 3.1 Consentimiento
- consentimiento informado digital previo a la primera teleatención
- debe quedar registrado: quién consintió, fecha, hora, alcance
- el paciente debe poder rechazar la modalidad remota
- consentimiento almacenado y auditable

## 3.2 Registro clínico
- toda teleatención debe generar un registro clínico equivalente al presencial
- el registro debe incluir: profesional, paciente, fecha/hora inicio/fin, motivo, hallazgos, indicaciones, plan
- el registro debe ser auditable, fechado y firmado digitalmente o con identificación del profesional
- debe poder exportarse/imprimirse para incorporar a ficha física si se requiere

## 3.3 Identificación
- el profesional debe estar identificado con nombre, rol y RUT o ID institucional
- el paciente debe estar identificado con nombre y RUT o ID del episodio HODOM
- la sesión debe vincular profesional ↔ paciente ↔ episodio

## 3.4 Confidencialidad y seguridad
- comunicación cifrada extremo a extremo (WebRTC con SRTP/DTLS es suficiente)
- no almacenar video/audio en servidores sin consentimiento explícito
- acceso solo para profesionales autorizados
- cumplimiento de Ley 19.628 en manejo de datos
- sesión protegida por autenticación

## 3.5 Calidad y adecuación del medio
- la plataforma debe ser adecuada a la prestación
- debe soportar audio y video de calidad suficiente para evaluación clínica remota
- debe tener fallback a solo audio o chat si la conexión es mala
- debe informar al profesional si la calidad es insuficiente para la atención

## 3.6 Derechos del paciente
- el paciente debe ser informado de que la atención es remota
- debe poder solicitar atención presencial en cualquier momento
- debe tener acceso a información sobre su diagnóstico, tratamiento, riesgos y alternativas
- debe poder ejercer derecho de rechazo

---

# 4. Arquitectura técnica mínima

## 4.1 Tipo de aplicación
**PWA (Progressive Web App)**

### Por qué PWA y no app nativa
- no requiere instalación desde store
- funciona desde cualquier navegador moderno (Chrome, Safari, Firefox)
- se puede "instalar" como ícono en pantalla de inicio
- actualizaciones instantáneas sin pasar por store
- un solo codebase para Android + iOS + desktop
- más rápido de desarrollar e iterar
- más liviano

## 4.2 Stack mínimo recomendado

| Capa | Tecnología sugerida | Razón |
|------|-------------------|-------|
| Frontend | HTML5 + CSS + JS vanilla o framework ligero (Preact/Svelte) | máxima ligereza |
| Comunicación real-time | **WebRTC** (nativo del navegador) | voz + video sin plugins, cifrado nativo |
| Señalización | WebSocket simple o servicio ligero | para establecer conexiones WebRTC |
| TURN/STUN | servidor TURN propio o servicio (coturn) | relay para NAT traversal en redes complicadas |
| Chat | WebSocket o canal de datos WebRTC (DataChannel) | chat integrado sin dependencia externa |
| Backend | Node.js / Go / Python (mínimo) | autenticación, registro, señalización |
| Base de datos | PostgreSQL o SQLite | registros de sesiones, consentimientos |
| Almacenamiento | filesystem o S3-compatible | solo si se graba audio/video con consentimiento |
| TLS | Let's Encrypt | HTTPS obligatorio para WebRTC |

## 4.3 Diagrama simplificado

```
Profesional (smartphone/browser)
    ↕ WebRTC (cifrado nativo)
Paciente/Cuidador (smartphone/browser)
    ↕
Servidor señalización (WebSocket)
    ↕
TURN/STUN (relay si NAT complejo)
    ↕
Backend (auth + registro + API)
    ↕
Base de datos (sesiones, consentimientos, registros)
```

---

# 5. Funcionalidades mínimas

## 5.1 Para el profesional HODOM

### Iniciar teleatención
- seleccionar paciente del censo activo
- verificar consentimiento vigente
- elegir modalidad: video / voz / chat
- iniciar sesión con un tap

### Durante la sesión
- video bidireccional
- audio bidireccional
- chat de texto (fallback o complemento)
- indicador de calidad de conexión
- botón de degradar a solo audio si la conexión falla
- timer de duración
- campo de notas rápidas durante la sesión

### Al cerrar la sesión
- formulario breve de registro:
  - motivo de la teleatención
  - hallazgos principales
  - indicaciones/plan
  - próxima acción
  - alerta sí/no
- firma/confirmación del profesional
- registro automático: fecha, hora inicio/fin, duración, modalidad, profesional, paciente, episodio
- opción de grabar nota de voz como complemento del registro

### Extras útiles
- compartir pantalla / foto clínica durante la sesión
- enviar instrucciones escritas al paciente/cuidador post-sesión

## 5.2 Para el paciente/cuidador

### Recibir teleatención
- link único por SMS o WhatsApp (sin necesidad de instalar nada)
- al abrir el link: solicitud de permisos de cámara y micrófono
- pantalla simple: video del profesional + botones básicos
- chat de texto como fallback
- botón de cortar

### Sin requerimientos
- no requiere cuenta
- no requiere instalación
- no requiere login
- solo necesita un navegador y conexión

## 5.3 Entre profesionales (interconsulta rápida)
- misma herramienta, pero sesión profesional ↔ profesional
- sin link externo: acceso desde el panel HODOM
- registro opcional más breve

---

# 6. Pantallas mínimas

## Profesional

### P1. Lista de pacientes para teleatención
- censo activo filtrado
- estado de consentimiento
- última teleatención
- botón: iniciar

### P2. Sala de espera / pre-sesión
- verificación de consentimiento
- verificación de conexión (test audio/video)
- envío de link al paciente

### P3. Sesión activa
- video principal
- miniatura propia
- chat lateral o inferior
- indicador de calidad
- timer
- botón: degradar a audio
- botón: notas
- botón: finalizar

### P4. Cierre / registro
- formulario breve post-sesión
- campos mínimos
- opción nota de voz
- guardar → genera registro auditable

## Paciente

### C1. Pantalla de ingreso (desde link)
- "El equipo HODOM del Hospital de San Carlos lo va a atender"
- solicitud de permisos
- botón: entrar a la consulta

### C2. Sesión activa
- video del profesional
- chat
- botón: cortar

### C3. Post-sesión
- "Su atención ha finalizado"
- resumen breve si se desea enviar
- encuesta de satisfacción opcional (1 pregunta)

---

# 7. Consentimiento digital — Flujo mínimo

## Primera teleatención
1. profesional selecciona paciente
2. sistema verifica si existe consentimiento vigente
3. si no existe: genera formulario de consentimiento digital
4. opciones de firma:
   - firma en pantalla táctil del profesional (presencial previo)
   - aceptación digital del paciente desde su dispositivo
   - registro verbal con testigo + timestamp
5. consentimiento queda almacenado con: paciente, fecha, hora, modalidad, profesional testigo

## Teleatenciones posteriores
- consentimiento vigente → sesión directa
- si el paciente revoca → registro de revocación, no se puede hacer teleatención

---

# 8. Registro clínico de teleatención — Campos mínimos

| Campo | Tipo | Obligatorio |
|-------|------|:-----------:|
| paciente_id | ref | sí |
| episodio_id | ref | sí |
| profesional_id | ref | sí |
| fecha | date | sí |
| hora_inicio | time | sí |
| hora_fin | time | sí |
| duracion_min | int | auto |
| modalidad | enum: video/voz/chat | sí |
| motivo | text breve | sí |
| hallazgos | text | no |
| indicaciones | text | no |
| plan_proxima_accion | text | no |
| alerta | bool | sí |
| nota_voz_url | string | no |
| calidad_conexion | enum: buena/regular/mala | auto |
| consentimiento_id | ref | sí |
| registro_imprimible | bool | auto |

---

# 9. Seguridad y privacidad — Checklist mínimo

| Requisito | Implementación |
|-----------|---------------|
| Cifrado de comunicación | WebRTC nativo (SRTP + DTLS) |
| HTTPS obligatorio | TLS en todo el dominio |
| Autenticación del profesional | login con credenciales HODOM |
| No se graba video/audio por defecto | solo texto de registro; grabación solo con consentimiento explícito adicional |
| Datos en tránsito cifrados | TLS + WebRTC |
| Datos en reposo | base de datos en servidor controlado, acceso restringido |
| Sesiones temporales | link del paciente expira después de la sesión |
| No se almacenan datos del paciente en el dispositivo del paciente | solo streaming, sin persistencia local |
| Auditoría | log de sesiones con timestamp, profesional, paciente, duración |
| Cumplimiento Ley 19.628 | datos mínimos, acceso restringido, sin compartir con terceros |

---

# 10. Calidad de conexión — Manejo de degradación

| Situación | Acción automática |
|-----------|------------------|
| Conexión buena (>1 Mbps) | video + audio |
| Conexión regular (500 Kbps - 1 Mbps) | reducir resolución de video |
| Conexión mala (<500 Kbps) | degradar a solo audio + chat |
| Sin conexión | notificar al profesional, sugerir llamada telefónica |

El profesional siempre debe poder:
- forzar degradación manual a audio
- forzar degradación manual a chat
- ver indicador de calidad en pantalla

---

# 11. Integración con HODOM OS

| Punto de integración | Cómo |
|---------------------|------|
| Censo de pacientes | la lista de pacientes viene del panel HODOM |
| Episodio | la sesión se vincula al episodio activo |
| Registro post-sesión | se guarda en la misma base de registros clínicos |
| Consentimiento | se almacena junto al consentimiento general HODOM |
| Alertas | si la teleatención detecta alerta → se refleja en el panel |
| Impresión | el registro de teleatención es imprimible en formato ficha |
| Regulación clínica | las teleatenciones aparecen en la vista del regulador |

---

# 12. Lo que NO debe tener (para mantener simplicidad)

- no requiere app nativa
- no requiere cuenta del paciente
- no requiere descarga
- no requiere integración con FONASA/ISAPRE en v1
- no requiere receta electrónica en v1
- no requiere licencia médica electrónica en v1
- no requiere interoperabilidad FHIR en v1
- no requiere IA en v1
- no requiere grabación automática de sesiones
- no requiere agenda de teleatención compleja

---

# 13. Experiencia de usuario — Principios

## Para el profesional
- desde el panel HODOM → seleccionar paciente → un tap → sesión activa
- al terminar → formulario breve → guardar → listo
- **máximo 3 taps para iniciar una teleatención**
- **máximo 60 segundos para cerrar el registro post-sesión**

## Para el paciente
- recibir link → abrir → permitir cámara → ver al profesional
- **máximo 2 taps para entrar a la sesión**
- **cero cuenta, cero instalación, cero complejidad**

---

# 14. MVP — Lo mínimo que debe funcionar

## Para mostrar como prototipo
1. profesional abre la app en su celular
2. ve lista de pacientes activos
3. selecciona uno
4. sistema genera link único
5. link se envía por WhatsApp/SMS al cuidador
6. cuidador abre link en su celular
7. se establece videollamada cifrada
8. chat disponible como complemento
9. profesional cierra sesión
10. formulario breve de registro
11. registro queda guardado y vinculado al episodio

## Para que sea normativamente defendible
- consentimiento previo registrado
- registro clínico post-sesión
- identificación de profesional y paciente
- cifrado de la comunicación
- dato mínimo almacenado
- auditable

---

# 15. Estimación de complejidad

| Componente | Complejidad | Tiempo estimado |
|-----------|------------|----------------|
| PWA shell + routing | baja | 2-4 h |
| Señalización WebSocket | media | 4-6 h |
| WebRTC voz+video | media | 6-8 h |
| Chat (DataChannel) | baja | 2-3 h |
| Generación de link único | baja | 1-2 h |
| Formulario registro post-sesión | baja | 2-3 h |
| Consentimiento digital | baja-media | 3-4 h |
| Integración con panel HODOM | media | 4-6 h |
| Auth profesional | baja | 2-3 h |
| Degradación de calidad | media | 3-4 h |
| Servidor TURN (coturn) | media | 3-4 h |
| **Total MVP** | | **~32-47 h dev** |

Con equipo capaz y en paralelo: **prototipo funcional en 3-5 días**.

---

# 16. Decisiones de diseño inamovibles

1. **PWA, no app nativa.** Sin store, sin instalación.
2. **WebRTC, no Zoom/Meet/terceros.** Control total, cifrado nativo, sin dependencias externas.
3. **El paciente no necesita cuenta.** Solo un link.
4. **Registro obligatorio post-sesión.** Sin registro, la teleatención no se cierra.
5. **Consentimiento previo obligatorio.** Sin consentimiento, la sesión no se inicia.
6. **Mobile-first.** Desktop funciona, pero se diseña primero para smartphone.
7. **Degradación elegante.** Si no hay video, hay audio. Si no hay audio, hay chat.
8. **Integrado al panel HODOM.** No es una app aislada.
9. **Imprimible.** El registro se puede imprimir para la ficha papel si se necesita.
10. **Sin grabación por defecto.** Solo registro escrito + nota de voz opcional.

---

*HODOM Tele v1 — specs de teleatención domiciliaria*
*Lo más simple que cumple toda la normativa.*
*2026-03-26*
