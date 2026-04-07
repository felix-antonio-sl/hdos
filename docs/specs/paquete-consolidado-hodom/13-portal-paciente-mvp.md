# Portal Paciente/Cuidador — MVP

**Contexto:** HODOM HSC, 20–30 activos. Complemento mínimo del sistema operativo.
**Fecha:** 2026-04-07

---

## Porqué y para qué

La norma técnica HODOM 2024 exige:
- DS 1/2022 art. 22: paciente recibe documento con indicaciones de emergencia
- Ley 20.584: derechos del paciente (acceso a su info clínica)
- PE-14: entrega de instrucciones para emergencias

El portal cierra ese gap: paciente/cuidador con internet accede sin app nativa.

---

## Historias de usuario

### HU-P1: Acceso al portal (login)
Como **paciente/cuidador (U16/U17)**, necesito acceder al sistema con mi email y contraseña para ver la información de mi hospitalización.

**Criterios de aceptación:**
- Login con email + password
- Si no tiene cuenta → link "¿No tienes cuenta?" → flujo con código de invitación
- Código de invitación de un solo uso, link generado por el equipo HODOM
- Después de login exitoso → dashboard principal
- "Olvidé mi contraseña" → reset por email

### HU-P2: Dashboard del paciente
Como **paciente/cuidador**, necesito ver un resumen de mi estado actual: diagnósticos, visitas próximas, teléfono HODOM.

**Criterios de aceptación:**
- Muestra: nombre paciente, diagnóstico, fecha ingreso, días en programa
- Próxima visita programada (fecha + hora + profesional si está asignada)
- Teléfonos de contacto: HODOM, emergencia (SAMU 131, SAPU)
- Indicaciones vigentes (farmacológicas y oxigenoterapia)
- Botón "Solicitar visita" o "Reportar síntoma"

### HU-P3: Ver indicaciones de cuidado
Como **paciente/cuidador**, necesito ver las indicaciones vigentes de mi cuidado para seguirlas correctamente.

**Criterios de aceptación:**
- Lista de medicamentos activos: nombre, dosis, vía, frecuencia
- Oxigenoterapia: dispositivo, flujo LPM, horas/día
- Curaciones: tipo, frecuencia
- Dietas si aplica
- Botón "Ver documento de emergencia" (PE-14)

### HU-P4: Documento de emergencia descargable
Como **paciente/cuidador**, necesito generar un documento descargable con indicaciones de emergencia para mostrar en urgencia o al cuidador.

**Criterios de aceptación:**
- PDF generado con: nombre, RUT, diagnóstico, teléfono HODOM
- Incluye indicaciones activas y signos de alarma
- Muestra teléfonos de contacto: HODOM, SAMU 131, SAPU local
- Horarios de atención HODOM (L-V 08:00-17:00 teléfono, L-D 08:00-19:00 visitas)

### HU-P5: Reportar síntoma o solicitar visita
Como **paciente/cuidador**, necesito enviar un mensaje de síntoma o solicitud de visita al equipo HODOM.

**Criorios de aceptación:**
- Formulario con: tipo (reporte de síntoma, consulta, solicitud de visita, otro)
- Campo opcional: signo de alarma (sí/no)
- Si signo de alarma = sí → mensaje marcado como urgente + instrucciones inmediatas
- Si no es urgente → mensaje normal al equipo
- Muestra estado del mensaje: Enviado → En proceso → Respondido

### HU-P6: Historial de visitas
Como **paciente/cuidador**, necesito ver un historial de las visitas realizadas para saber quién vino y cuándo.

**Criterios de aceptación:**
- Lista cronológica de visitas: fecha, profesional, tipo de atención
- Filtro por mes
- Visitas completadas y canceladas diferenciadas

### HU-P7: Mensajes recibidos
Como **paciente/cuidador**, necesito ver mensajes del equipo HODOM (respuestas, recordatorios, citaciones).

**Criterios de aceptación:**
- Inbox con mensajes del equipo HODOM
- Mensajes nuevos destacados
- Filtro por tipo (respuesta, recordatorio, citación)

---

## Modelo de datos

Ya creado en la BD `hodom` (puerto 5555):

| Tabla | Schema | Propósito |
|---|---|---|
| `portal_usuario` | operational | Cuentas de acceso (email, password_hash, rol, OTP) |
| `portal_invitacion` | operational | Tokens de invitación un solo uso, expiran a 48h |
| `portal_mensaje` | clinical | Mensajes/consultas del equipo |
| `portal_acceso_log` | operational | Auditoría de accesos |

### Vistas read-only para el portal

| Vista | Schema | Contenido |
|---|---|---|
| `v_mi_episodio` | portal | Resumen del episodio activo |
| `v_mis_indicaciones` | portal | Indicaciones vigentes |
| `v_mi_documento_emergencia` | portal | Datos para el PDF de emergencia (PE-14) |

### Flujo de acceso

```
Equipo HODOM  →  crea cuenta invitada  →  email con link/token  →  paciente crea password  →  acceso portal
```

1. Coordinador crea `portal_usuario` con `rol = 'cuidador'`, `email`, `estado = 'invitado'`
2. O genera `portal_invitacion` con token, envía link por email
3. Paciente/cuidador accede al link, crea password, primer login
4. Dashboard con sus datos restringidos por `patient_id` en FK

---

## Seguridad

| Capa | Implementación |
|---|---|
| Auth | Email + password (bcrypt/argon2) + sesión JWT |
| 2FA opcional | TOTP (otp_secret), activable por el usuario |
| Invitación | Token de un solo uso, expira 48h |
| Isolación de datos | FK a patient_id → solo ve su episodio |
| Auditoría | `portal_acceso_log` registra IP, user_agent, timestamp |
| Suspensión | `portal_usuario.estado = 'suspendido'` bloquea acceso |
| Datos mínimos | Solo lo necesario: diagnósticos, indicaciones, próximas visitas |
| No datos de otros | JOIN restringido por patient_id (el FK es la barrera) |

---

## UI del portal (3 pantallas)

### P1: Login
- Logo HODOM HSC
- Email + contraseña
- "¿No tienes cuenta?" → código de invitación
- "Olvidé mi contraseña"

### P2: Dashboard principal
- Encabezado: nombre del paciente + diagnóstico
- Tarjeta **Próxima visita**: fecha, hora, profesional
- Tarjeta **Indicaciones vigentes**: lista compacta
- Banner rojo: **Teléfono HODOM** + **SAMU 131** siempre visible
- Botón "Reportar síntoma"
- Botón "Documento de emergencia"
- Link "Historial de consultas"

### P3: Detalle visita/indicación
- Click en indicación → detalle completo (dosis, horario, vía)
- Click en visita → detalle (qué se hizo, notas si aplica)
- Botón descargar PDF emergencia

---

## Integración con la app principal

El portal es un módulo más del sistema, no un producto separado:

| Aspecto | Detalle |
|---|---|
| Shared DB | Mismo PostgreSQL (`hodom`) |
| Auth | Diferente: `portal_usuario` tabla separada de `profesional` |
| Permisos | RLS: `patient_id` como barrera |
| Mensajería | `portal_mensaje` aparece en la bandeja del coordinador (app principal) |
| UI | Ruta `/portal/*` vs `/app/*` en la app Next.js |

---

## Prioridad y scope

**MVP (ahora):** HU-P1 a HU-P4 (acceso, dashboard, indicaciones, documento emergencia)
**Sprint 2:** HU-P5 (reportar síntoma), HU-P6 (historial visitas)
**Sprint 3:** HU-P7 (mensajes), mejoras UX

**Fuera de scope por ahora:**
- Chat en tiempo real
- Subida de fotos (por ejemplo: foto de herida)
- Notificaciones push (SMS/WhatsApp)
- Firma digital de consentimiento
- Multi-paciente (cuidador con varios pacientes)

---

## Relación con el paquete consolidado

| Paquete consolidado | Este portal |
|---|---|
| Módulo 11 (1 HU) | Se expande a 7 HUs operables |
| Sin data model | 4 tablas + 3 vistas creadas en la BD |
| FHIR: `Communication`, `DocumentReference` | Se usan en HU-P4, HU-P7 (fase 2) |
| "Futuro" | MVP inmediato, porque no requiere app nativa |
