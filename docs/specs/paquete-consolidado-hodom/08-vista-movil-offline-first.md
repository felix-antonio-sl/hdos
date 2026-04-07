# Vista Móvil y Formulario Offline-First — HODOM HSC

Fecha: 2026-04-07
Origen: Fugaz (exclusivo — no cubierto por Allan)

---

## Propósito

El profesional en terreno (enfermera, TENS, kinesiólogo, fonoaudiólogo) necesita una interfaz móvil que funcione con señal intermitente o sin conexión en zonas rurales de Ñiquén, San Nicolás y sectores aislados de San Carlos.

---

## Principios

1. **Offline-first**: el registro se guarda localmente y sincroniza cuando hay conexión.
2. **Pre-llenado desde agenda**: al abrir "Registrar visita", los datos del paciente, episodio y tipo de atención vienen de la programación.
3. **Mínimos toques**: optimizado para smartphone con una mano.
4. **Sincronización transparente**: indicador visual de estado (sincronizado / pendiente / error).

---

## Pantalla: Mi Agenda de Hoy

```
┌──────────────────────────────────┐
│  MI AGENDA │ 07 Abr 2026         │
│  Klgo. Luis Burgos               │
│  Móvil: SERVANDO                 │
│  🔄 Sincronizado                 │
├──────────────────────────────────┤
│                                  │
│  08:00  ──────────────────────   │
│  Nelson Sepúlveda                │
│  CA + KTM                        │
│  📍 El Espinal, Ñiquén           │
│  ☎ 950016723                     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  09:00  ──────────────────────   │
│  Corina Venegas                  │
│  ING ENF + ING KTM               │
│  📍 Gaona km 372, San Carlos     │
│  ☎ 968083366                     │
│  ⚠ INGRESO — traer kit eval     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  11:30  ──────────────────────   │
│  Néstor Riquelme                 │
│  NTP                             │
│  📍 Millauquén, San Carlos       │
│  ☎ 966349150                     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  14:00  ──────────────────────   │
│  Elisa Rodríguez                 │
│  ING KTM                         │
│  📍 Balmaceda 0148, San Carlos   │
│  ☎ 981393193                     │
│  ⚠ INGRESO — Barthel requerido  │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  14:30  ──────────────────────   │
│  María Orrego                    │
│  KTM                             │
│  📍 ELEAM San Agustín            │
│  ☎ 978778607                     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  15:10  ──────────────────────   │
│  Víctor Belmar                   │
│  KTR                             │
│  📍 Pedro Lagos 121, San Carlos  │
│  ☎ 957032303                     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  16:00  ──────────────────────   │
│  Marta Romero                    │
│  KTR                             │
│  📍 Lago Rupanco 819, San Carlos │
│  ☎ 964935098                     │
│  [📋 Registrar] [📍 Navegar]    │
│                                  │
│  ────────────────────────────    │
│  7 visitas │ Est: 16:30 fin     │
│  [🗺 Ver ruta completa]          │
│                                  │
│  ── RESUMEN ──────────────────   │
│  ✅ Realizadas: 3                │
│  ⏳ Pendientes: 4                │
│  ❌ Fallidas: 0                  │
└──────────────────────────────────┘
```

### Interacciones

| Acción | Resultado |
|--------|-----------|
| Click "Registrar" | Abre formulario de visita pre-llenado |
| Click "Navegar" | Abre Google Maps / Waze con dirección |
| Click teléfono | Marca directamente |
| Click en nombre | Abre resumen clínico compacto |
| Swipe derecha en visita | Marca como realizada rápidamente |
| "Ver ruta completa" | Abre mapa con todas las paradas |

---

## Formulario: Registro de Visita (Offline-First)

```
┌──────────────────────────────────┐
│  REGISTRAR VISITA                │
│  (pre-llenado desde agenda)      │
├──────────────────────────────────┤
│                                  │
│  Paciente: Corina Venegas        │
│  Episodio: #425 │ ACV Isquémico  │
│  Fecha: 07-Abr  Hora: [09:00]   │
│                                  │
│  Tipo atención:                  │
│  [▼ Seleccionar                ] │
│  │ KTM (kine motora)            │
│  │ KTR (kine respiratoria)      │
│  │ CA (curación avanzada)       │
│  │ CS (curación simple)         │
│  │ NTP                          │
│  │ Evaluación                   │
│  │ Educación                    │
│  │ Control                      │
│  │ Ingreso                      │
│  │ Visita médica                │
│  │ TTO EV                       │
│  │ TTO SC                       │
│  │ Toma muestras                │
│  │ Telesalud                    │
│  │ Otro                         │
│                                  │
│  ── SIGNOS VITALES (opcional) ── │
│  PA: [___/___]  FC: [___]       │
│  FR: [___]      T°: [___]      │
│  SAT%: [___]    HGT: [___]     │
│  EVA: [___]     Glasgow: [___] │
│  Edema: [No ▼]  Diuresis: [__] │
│  Deposiciones: [__]             │
│  Invasivos: [________________]  │
│                                  │
│  ⚠ Valores fuera de rango se    │
│  resaltan automáticamente        │
│                                  │
│  ── NOTA CLÍNICA ────────────── │
│  [________________________________│
│   ________________________________│
│   ________________________________│
│   ________________________________]│
│                                  │
│  ── INTERVENCIONES (check) ───── │
│  □ Administración medicamento    │
│  □ Curación                      │
│  □ Toma de muestra               │
│  □ Educación paciente/cuidador   │
│  □ Cambio/retiro de invasivo     │
│  □ Terapia motora                │
│  □ Terapia respiratoria          │
│  □ Evaluación fonoaudiológica    │
│  □ Intervención social           │
│  □ Otro: [________________]     │
│                                  │
│  ── INCIDENCIAS ─────────────── │
│  □ Sin incidencia                │
│  □ Paciente ausente              │
│  □ Rechazo de atención           │
│  □ Evento adverso                │
│  □ Otra: [________________]     │
│                                  │
│  Estado visita:                  │
│  (●) Realizada  (○) Fallida     │
│                                  │
│  Si fallida:                     │
│  Motivo: [________________]     │
│                                  │
│  [Guardar borrador]  [Enviar ✓] │
│                                  │
│  🔄 Sin conexión: se guardará   │
│  localmente y sincronizará      │
│  automáticamente.                │
└──────────────────────────────────┘
```

### Códigos de actividad alineados con operación real

Los tipos de atención corresponden exactamente a los códigos usados en las planillas de programación y rutas del legacy HSC:

| Código sistema | Código legacy | Descripción |
|----------------|---------------|-------------|
| KTM | KTM | Kinesiología motora |
| KTR | KTR | Kinesiología respiratoria |
| CA | CA | Curación avanzada |
| CS | CS | Curación simple |
| VM | VM | Visita médica |
| NTP | NTP / NPT | Nutrición parenteral total |
| TTO_EV | TTO EV / ERTA | Tratamiento endovenoso |
| TTO_SC | TTO SC | Tratamiento subcutáneo |
| FONO | FONO | Fonoaudiología |
| EXAMENES | EXAMENES | Toma de muestras |

### Comportamiento offline

| Situación | Comportamiento |
|-----------|---------------|
| Con conexión | Envío inmediato, confirmación visual ✅ |
| Sin conexión | Guardado local con marca ⏳, cola de sincronización |
| Reconexión | Sincronización automática, notificación de éxito/conflicto |
| Conflicto | Alerta al usuario, resolución manual (prioridad: dato más reciente) |
| Caché de agenda | Se descarga al inicio del día; funciona todo el día sin conexión |

### Resumen clínico compacto (al tocar nombre del paciente)

```
┌──────────────────────────────────┐
│  Corina Venegas Martínez         │
│  67a │ F │ 7.877.696-K          │
│  ACV Isquémico HP Izquierdo     │
│  Día 4 │ Estable                │
│                                  │
│  Última visita: 06-Abr, KTM     │
│  PA 125/75 │ SAT 94% │ Glasgow 15│
│                                  │
│  Plan: Movilidad en cama + SBC  │
│  + Marcha dinámica con bastón   │
│                                  │
│  ⚠ Requiere 1 cooperador        │
│  Cuidador: hijo (☎ 968083366)   │
│                                  │
│  [Ver ficha completa]            │
└──────────────────────────────────┘
```

---

## Entrega de turno digital (complemento)

Vista rápida para handoff entre profesionales al final del día:

```
┌──────────────────────────────────┐
│  ENTREGA TURNO KINE HODOM       │
│  05-Abr-2026                     │
│  Entrega: Brayan Reyes           │
│  Recibe: Luis Burgos             │
├──────────────────────────────────┤
│                                  │
│  Marta Romero │ 9.260.553-1     │
│  Neumonía │ Control              │
│  TTKK + SOF + MSB               │
│  Hora: 17:40 / Ayuno: 15:00     │
│  Registro: KTR                   │
│                                  │
│  Corina Venegas │ 7.877.696-K   │
│  ACV Isquémico │ Control         │
│  Mov. cama + SBC + Marcha       │
│  Hora: 08:30                     │
│  Registro: ED+KTM               │
│                                  │
│  Luis Pincheira │ 7.663.156-5   │
│  Fx Expuesta │ Control           │
│  Mov EEII + STS + Marcha AF     │
│  Hora: 09:30                     │
│  Registro: KTM                   │
│                                  │
│  [Firmar entrega]                │
└──────────────────────────────────┘
```

Estos datos vienen directamente del formato real de `Ent. Turno Hodom KINE.xlsx`.
