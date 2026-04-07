# Blueprint de Pantallas — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Estado: borrador v1
Dependencia: `diseno-sistema-operativo-hodom-hsc.md`, `roles-permisos-hodom-hsc.md`, `backlog-mvp-hodom-hsc.md`

---

## Principios de interfaz

1. **Operación-first**: las pantallas deben servir al ritmo real de trabajo, no a un ideal abstracto.
2. **Mobile-first en terreno**: el profesional en domicilio opera desde smartphone, con señal intermitente.
3. **Desktop-first en coordinación**: la coordinadora y el estadístico operan desde escritorio.
4. **Densidad informativa justa**: ni sobrecarga ni pantallas vacías. Cada dato visible debe servir a una decisión.
5. **Acción inmediata**: desde cualquier vista, la acción más probable está a 1 click.
6. **Offline-resilient**: los registros de terreno deben poder crearse sin conexión y sincronizar después.

---

## Navegación global

```
┌─────────────────────────────────────────────────────┐
│  🏠 HODOM HSC          [🔍 Buscar paciente/RUT]    │
├─────────────────────────────────────────────────────┤
│  📊 Tablero  │  👤 Ficha  │  📅 Agenda  │  📞 Llamadas  │  📈 REM  │
└─────────────────────────────────────────────────────┘
```

- **Tablero**: vista de coordinación y estado global
- **Ficha**: historia clínica por episodio/paciente
- **Agenda**: programación diaria y rutas
- **Llamadas**: registro y bandeja de comunicaciones
- **REM**: analítica y tributación estadística

Roles ven distintas combinaciones:
- Coordinación: todas
- Clínicos: Ficha + Agenda + Llamadas
- TENS/terreno: Agenda + Ficha (resumida)
- Administrativo: Tablero + Llamadas
- Estadístico: REM + Tablero
- Dir. Técnica: Tablero + REM

---

## Pantalla 1: Tablero de Coordinación

### Propósito
Vista panorámica de la operación HODOM en tiempo real. Es la pantalla de inicio para coordinación y el centro de mando diario.

### Usuarios principales
Enfermera coordinadora, Dirección Técnica, Administrativo

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  TABLERO HODOM HSC                         07 Abr 2026  08:15   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ ACTIVOS │  │ CUPOS   │  │ HOY     │  │ ALERTAS │           │
│  │   22    │  │ 22/25   │  │ 34 vis  │  │   3 ⚠   │           │
│  │pacientes│  │ 88%     │  │programa │  │pendiente│           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
│                                                                  │
│  ── POSTULACIONES PENDIENTES (2) ─────────────────── [+ Nueva]  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ ⏳ María González  │ 68a │ Neumonía  │ UEH   │ Hoy 07:20│   │
│  │ ⏳ Pedro Muñoz     │ 74a │ ICC       │ Med   │ Ayer     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ── PACIENTES ACTIVOS ────────────────── [Filtrar ▼] [Exportar] │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ # │ Paciente          │Edad│ Dx principal    │Días│Estado │   │
│  │───┼───────────────────┼────┼─────────────────┼────┼───────│   │
│  │ 1 │ Néstor Riquelme   │ 57 │ SD Int. Corto   │117 │estable│   │
│  │ 2 │ Luis Maldonado     │ 59 │ Osteomielitis   │137 │mejorar│   │
│  │ 3 │ Luis Pincheira     │ 70 │ Fx expuesta     │  6 │estable│   │
│  │ 4 │ Daniel Crisóstomo  │ 53 │ Pie DBT         │ 27 │mejorar│   │
│  │ 5 │ Corina Venegas     │ 67 │ ACV isquémico   │  4 │nuevo  │   │
│  │...│                    │    │                 │    │       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ── ALERTAS ACTIVAS ────────────────────────────────────────    │
│  │ 🔴 Néstor Riquelme: NTP sin retiro programado              │   │
│  │ 🟡 Visita fallida: María Orrego (ayer, sin acceso)          │   │
│  │ 🟡 Exámenes pendientes: Luis Maldonado (2 días)            │   │
│                                                                  │
│  ── EGRESOS RECIENTES (últimos 7 días) ─────────────────────   │
│  │ Daniel Crisóstomo │ Alta clínica │ 01-04 │ Contraref: ✅   │   │
│  │ Teresa Valenzuela │ Alta clínica │ 29-03 │ Contraref: ⏳   │   │
│                                                                  │
│  ── RESUMEN MES ────────────────────────────────────────────    │
│  │ Ingresos: 8 │ Altas: 5 │ Fallecidos: 0 │ Reingresos: 1   │   │
│  │ Días-persona: 142 │ Ocupación: 88% │ Visitas: 187          │   │
└──────────────────────────────────────────────────────────────────┘
```

### Componentes clave

| Componente | Datos | Interacción |
|------------|-------|-------------|
| KPIs superiores | Pacientes activos, ocupación, visitas programadas hoy, alertas | Click abre detalle |
| Postulaciones pendientes | Nombre, edad, diagnóstico, origen, fecha postulación | Click abre evaluación de elegibilidad |
| Lista de pacientes activos | Ordenable por días estada, estado, nombre | Click abre ficha del episodio |
| Alertas activas | Clasificadas por severidad | Click abre contexto y acción |
| Egresos recientes | Con estado de contrarreferencia | Click abre epicrisis |
| Resumen mes | Indicadores REM parciales | Actualización automática |

### Filtros disponibles
- Estado del paciente (todos, estable, mejorando, deteriorándose, nuevo)
- Profesional asignado
- Zona/comuna
- Días de estada (>7, >14, >30)

---

## Pantalla 2: Ficha Clínica del Episodio

### Propósito
Historia clínica completa de un episodio HODOM. Centro de toda la información clínica, desde ingreso hasta egreso.

### Usuarios principales
Médico HODOM, Enfermera clínica, Kinesiólogo, todos los clínicos

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  ← Tablero    FICHA EPISODIO                    [⚙ Acciones ▼] │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ NÉSTOR RIQUELME BASCUR           RUT 11.444.532-0      │    │
│  │ 57 años │ Masculino │ FONASA                            │    │
│  │ Millauquén S/N, San Carlos │ ☎ 966349150 / 982414478   │    │
│  │ CESFAM: Teresa Baldecchi                                 │    │
│  │ Cuidador: Rosa Bascur (esposa) │ ☎ 982414478            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ EPISODIO #418                                          │     │
│  │ Estado: ACTIVO │ Categoría: ESTABLE                    │     │
│  │ Ingreso: 11-Dic-2025 │ Días estada: 117               │     │
│  │ Origen: Medicina │ Dx: SD Intestino Corto / AKI        │     │
│  │ Equipo: Dra. Sánchez, EU Pía Vallejos, TENS, Kine     │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────┬──────────┬──────────┬────────┬────────┬─────────┐    │
│  │Resum.│ Plan Tx  │ Visitas  │ S.Vital│ Docs   │ Llamadas│    │
│  └──────┴──────────┴──────────┴────────┴────────┴─────────┘    │
│                                                                  │
│  [Tab activo: Resumen]                                           │
│                                                                  │
│  ── DIAGNÓSTICOS ───────────────────────────────────────────    │
│  │ Principal: SD Intestino Corto / AKI                         │   │
│  │ Secundarios: DM2, HTA                                      │   │
│                                                                  │
│  ── PLAN TERAPÉUTICO ───────────────────────────────────────    │
│  │ Objetivo: NTP domiciliaria + control metabólico             │   │
│  │ Requerimientos: NTP, toma muestras, CSV, educación          │   │
│  │ Frecuencia: Enfermería diaria, Médico 2x/sem, Kine 3x/sem │   │
│  │ Estado: Activo desde 12-Dic-2025                            │   │
│                                                                  │
│  ── MEDICACIÓN ACTIVA ──────────────────────────────────────    │
│  │ NTP (bolsa) │ IV │ diaria │ preparada en farmacia          │   │
│  │ Insulina    │ SC │ c/8h  │ administra cuidador             │   │
│  │ Omeprazol   │ VO │ c/24h │                                 │   │
│                                                                  │
│  ── ÚLTIMA VISITA ──────────────────────────────────────────    │
│  │ 06-Abr │ EU Pía Vallejos │ NTP retiro + exámenes           │   │
│  │ PA 130/80 │ FC 78 │ T° 36.8 │ SAT 96%                     │   │
│                                                                  │
│  ── ALERTAS ────────────────────────────────────────────────    │
│  │ 🟡 NTP: programar retiro de bolsa                          │   │
│                                                                  │
│  ── PRÓXIMAS VISITAS ───────────────────────────────────────    │
│  │ 07-Abr 10:30 │ EU Pía │ NTP + CSV                          │   │
│  │ 08-Abr 09:00 │ Dra. Sánchez │ Control médico                │   │
│  │ 08-Abr 11:00 │ Klgo. Luis │ KTM                            │   │
│                                                                  │
│                                     [+ Registrar visita]        │
│                                     [+ Registrar llamada]       │
│                                     [Egresar paciente]          │
└──────────────────────────────────────────────────────────────────┘
```

### Tabs internos

#### Tab: Plan Terapéutico
```
── PLAN TERAPÉUTICO ─────────────────── Estado: ACTIVO ── [Editar]
│ Objetivo general: Completar NTP, estabilizar función renal
│ Criterios de alta: Tolerancia oral >80%, Cr <2.0, sin infección
│
│ REQUERIMIENTOS DE CUIDADO
│ ┌────────────────┬────────────┬───────────────────────┐
│ │ Tipo           │ Frecuencia │ Profesional           │
│ │ NTP            │ Diaria     │ Enfermería            │
│ │ Toma muestras  │ 2x/semana  │ Enfermería/TENS       │
│ │ CSV            │ c/visita   │ Todos                 │
│ │ Educación      │ Semanal    │ Enfermería            │
│ │ Control médico │ 2x/semana  │ Médico                │
│ │ KTM            │ 3x/semana  │ Kinesiólogo           │
│ └────────────────┴────────────┴───────────────────────┘
│
── PLAN DE CUIDADOS ENFERMERÍA ──────── Estado: ACTIVO ── [Editar]
│ Dx enfermería: Riesgo de infección asociado a CVC
│ Intervenciones: Curación sitio CVC c/72h, vigilancia signos infección
│ Metas: Sitio CVC sin signos de infección durante estada
```

#### Tab: Visitas
```
── HISTORIAL DE VISITAS ──────────────────── [Filtrar ▼] [+ Nueva]
│ Fecha    │ Profesional      │ Tipo    │ Registro │ SV  │
│──────────┼──────────────────┼─────────┼──────────┼─────│
│ 06-Abr   │ EU Pía Vallejos  │ NTP     │ ✅       │ ✅  │
│ 05-Abr   │ Klgo. Brayan     │ KTM     │ ✅       │ ✅  │
│ 05-Abr   │ Fono M. José     │ Eval    │ ✅       │ —   │
│ 04-Abr   │ EU Pía Vallejos  │ NTP+EX  │ ✅       │ ✅  │
│ 04-Abr   │ Klgo. Brayan     │ KTM     │ ✅       │ ✅  │
│ 03-Abr   │ Dra. Sánchez     │ Control │ ✅       │ ✅  │
│ ...
│
│ Click en fila → detalle completo de la visita
```

#### Tab: Signos Vitales
```
── TENDENCIA SIGNOS VITALES ──────────── [Últimos 7 │ 14 │ 30 días]
│
│ PA    ████████████████████ 130/80  (rango: 120-140 / 70-85)
│ FC    ████████████████     78      (rango: 70-88)
│ FR    ██████████████       18      (rango: 16-20)
│ T°    ██████████████████   36.8    (rango: 36.2-37.1)
│ SAT%  █████████████████    96      (rango: 94-97)
│ HGT   ████████████████     145     (rango: 110-180)
│
│ ── TABLA DETALLE ───────────────────────────────
│ Fecha  │ PA     │ FC │ FR │ T°  │SAT%│ HGT │EVA│Glasgow│
│ 06-Abr │130/80  │ 78 │ 18 │36.8 │ 96 │ 145 │ 2 │  15   │
│ 05-Abr │125/78  │ 80 │ 18 │36.5 │ 95 │ 160 │ 2 │  15   │
│ 04-Abr │135/85  │ 82 │ 20 │37.0 │ 94 │ 170 │ 3 │  15   │
```

#### Tab: Documentos
```
── DOCUMENTOS DEL EPISODIO ──────────────────────── [+ Subir]
│ Tipo                    │ Estado    │ Fecha   │ Autor        │
│ Consentimiento informado│ ✅ Firmado│ 11-Dic  │ EU Pía       │
│ Formulario de ingreso   │ ✅        │ 11-Dic  │ Admin        │
│ Carta derechos/deberes  │ ✅ Entrega│ 11-Dic  │ Admin        │
│ Informe social          │ ✅        │ 12-Dic  │ TS Bárbara   │
│ Epicrisis               │ ⏳ Pend.  │ —       │ —            │
```

---

## Pantalla 3: Agenda y Rutas

### Propósito
Programación diaria y semanal de visitas. Vista global para coordinación, vista personal para cada profesional.

### Usuarios principales
Coordinación, Gestor de rutas, todos los profesionales clínicos, Conductor

### Layout — Vista Coordinación (Desktop)

```
┌──────────────────────────────────────────────────────────────────┐
│  AGENDA HODOM                    [◀ 06-Abr] 07-Abr [08-Abr ▶]  │
│                                  [Día │ Semana]    [+ Programar] │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ── RESUMEN DEL DÍA ───────────────────────────────────────     │
│  │ Visitas programadas: 34 │ Profesionales: 8 │ Móviles: 3    │   │
│  │ Teleatenciones: 4 │ Pendientes de confirmar: 2              │   │
│                                                                  │
│  ┌─── MÓVIL SERVANDO ──────────────────────────────────────┐    │
│  │ Profesionales: Klgo. Luis + EU Pía                       │    │
│  │ Zona: San Carlos centro + Ñiquén                         │    │
│  │                                                           │    │
│  │ 08:00 │ Nelson Sepúlveda    │ CA + KTM  │ El Espinal    │    │
│  │ 09:00 │ Corina Venegas      │ ING + KTM │ Gaona km 372  │    │
│  │ 11:30 │ Néstor Riquelme     │ NTP       │ Millauquén    │    │
│  │ 14:00 │ Elisa Rodríguez     │ ING KTM   │ Balmaceda 148 │    │
│  │ 14:30 │ María Orrego        │ KTM       │ Serrano 179   │    │
│  │ 15:10 │ Víctor Belmar       │ KTR       │ Pedro Lagos   │    │
│  │ 16:00 │ Marta Romero        │ KTR       │ Lago Rupanco  │    │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─── MÓVIL HUGO ──────────────────────────────────────────┐    │
│  │ Profesionales: Klgo. Luis + Fono M.José                  │    │
│  │ Zona: San Carlos norte + Ñiquén rural                    │    │
│  │                                                           │    │
│  │ 08:00 │ Corina Venegas     │ KTM+FONO │ Gaona km 372   │    │
│  │ 09:00 │ María Luz Alarcón  │ KTM      │ La Gloria      │    │
│  │ 09:50 │ María González     │ KTM      │ Las Alitas     │    │
│  │ 10:30 │ Margarita Gómez    │ KTM+FONO │ Cachapoal      │    │
│  │ 11:10 │ Cristian Ramírez   │ KTM      │ La Camelia     │    │
│  │ 11:50 │ María Orrego       │ EV FONO  │ ELEAM          │    │
│  │ 12:30 │ Lucía Norambuena   │ KTM+FONO │ La Chinchilla  │    │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─── MÓVIL ANDRÉS ────────────────────────────────────────┐    │
│  │ ...                                                       │    │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ── TELEATENCIONES PROGRAMADAS ─────────────────────────────    │
│  │ 10:00 │ Dra. Sánchez  │ Néstor Riquelme │ Resultado ex. │   │
│  │ 11:00 │ EU Pía        │ Luis Maldonado  │ Seguimiento   │   │
│  │ 15:00 │ TS Bárbara    │ Elisa García    │ Eval. social  │   │
│  │ 16:00 │ Dra. Sánchez  │ Marta Romero    │ Control       │   │
│                                                                  │
│  ── SIN VISITA HOY (pacientes activos) ─────────────────────    │
│  │ Luis Maldonado (última visita: 05-Abr) — próx: 08-Abr      │   │
│  │ Eliecer Soto (última visita: 05-Abr) — próx: 08-Abr        │   │
└──────────────────────────────────────────────────────────────────┘
```

### Layout — Vista Profesional Móvil (Smartphone)

```
┌──────────────────────────────┐
│  MI AGENDA │ 07 Abr          │
│  Klgo. Luis Burgos           │
│  Móvil: SERVANDO             │
├──────────────────────────────┤
│                              │
│  08:00  ──────────────────   │
│  Nelson Sepúlveda            │
│  CA + KTM                    │
│  📍 El Espinal, Ñiquén      │
│  ☎ 950016723                 │
│  [📋 Registrar] [📍 Navegar]│
│                              │
│  09:00  ──────────────────   │
│  Corina Venegas              │
│  ING ENF + ING KTM           │
│  📍 Gaona km 372, San Carlos │
│  ☎ 968083366                 │
│  ⚠ INGRESO — traer kit eval │
│  [📋 Registrar] [📍 Navegar]│
│                              │
│  11:30  ──────────────────   │
│  Néstor Riquelme             │
│  NTP                         │
│  📍 Millauquén, San Carlos   │
│  ☎ 966349150                 │
│  [📋 Registrar] [📍 Navegar]│
│                              │
│  ...                         │
│                              │
│  ────────────────────────    │
│  7 visitas │ Est: 14:30 fin  │
│  [🗺 Ver ruta completa]      │
└──────────────────────────────┘
```

### Interacciones clave

| Acción | Desde | Resultado |
|--------|-------|-----------|
| Click en paciente | Agenda | Abre ficha del episodio |
| Click "Registrar" | Agenda móvil | Abre formulario de visita pre-llenado (paciente, hora, tipo) |
| Click "Navegar" | Agenda móvil | Abre Google Maps / Waze con dirección |
| Drag & drop visita | Agenda desktop | Reprograma hora o asigna a otro móvil |
| Click "+ Programar" | Agenda desktop | Abre selector de paciente → profesional → hora → móvil |
| Marcar visita fallida | Agenda móvil | Pide motivo (sin acceso, rechazo, ausente, otro) + reprograma |

---

## Pantalla 4: Registro y Bandeja de Llamadas

### Propósito
Trazabilidad de toda comunicación telefónica entre HODOM y pacientes/cuidadores/red. Requerido por normativa (sistema 24/7 con registro).

### Usuarios principales
Administrativo, Enfermería, Médico regulador, Coordinación

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  LLAMADAS HODOM                                   [+ Nueva]     │
│  [Hoy │ Semana │ Mes]  [Filtrar: motivo ▼] [paciente ▼]        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ── HOY 07-ABR ─────────────────────────────────────────────    │
│                                                                  │
│  │ 🟢 09:14 │ EMITIDA │ 3:25 │ EU Pía Vallejos                │
│  │ Paciente: Néstor Riquelme │ Familiar: Rosa Bascur (esposa) │
│  │ Motivo: RESULTADO EXÁMENES                                  │
│  │ Obs: Comunicar K normal. NTP continúa igual. Próx control  │
│  │ lunes.                                                       │
│  │                                          [Ver episodio →]    │
│  │                                                              │
│  │ 🔵 10:02 │ RECIBIDA │ 1:45 │ Admin. Carolina               │
│  │ Paciente: Marta Romero │ Familiar: Hija                     │
│  │ Motivo: CONSULTA HORARIO VISITA                             │
│  │ Obs: Consulta si kine viene hoy. Confirmado 17:00 aprox.   │
│  │                                          [Ver episodio →]    │
│  │                                                              │
│  │ 🔴 10:30 │ EMITIDA │ 0:00 │ EU Pía Vallejos               │
│  │ Paciente: María Orrego │ Familiar: —                        │
│  │ Motivo: SEGUIMIENTO                                          │
│  │ Obs: No contesta. Reintentar a las 12:00.                  │
│  │ Estado: ⏳ PENDIENTE RECONTACTO                              │
│  │                                          [Ver episodio →]    │
│                                                                  │
│  ── RESUMEN DEL DÍA ───────────────────────────────────────    │
│  │ Emitidas: 8 │ Recibidas: 3 │ Sin contacto: 2               │   │
│  │ Motivos: Resultado ex (3), Seguimiento (4), Coord (2),     │   │
│  │          Urgencia (1), Otro (1)                              │   │
└──────────────────────────────────────────────────────────────────┘
```

### Formulario de nueva llamada

```
┌──────────────────────────────────────────┐
│  REGISTRAR LLAMADA                       │
│                                          │
│  Fecha: [07-Abr-2026]  Hora: [10:45]    │
│  Duración: [__:__:__]                    │
│                                          │
│  Tipo: (●) Emitida  (○) Recibida        │
│                                          │
│  Paciente: [🔍 buscar por nombre/RUT]   │
│  → Néstor Riquelme (11.444.532-0)       │
│  Estado: ACTIVO                          │
│                                          │
│  Familiar/contacto: [_________________] │
│  Nro teléfono: [_________________]      │
│                                          │
│  Motivo:                                 │
│  [▼ Resultado exámenes    ]              │
│  │  Seguimiento                          │
│  │  Asistencia social                    │
│  │  Hora médica                          │
│  │  Coordinación                         │
│  │  Urgencia clínica                     │
│  │  Otro                                 │
│                                          │
│  Funcionario HODOM: [EU Pía Vallejos ▼] │
│                                          │
│  Observaciones:                          │
│  [________________________________]     │
│  [________________________________]     │
│  [________________________________]     │
│                                          │
│  Requiere acción: □ Sí                   │
│  Si sí: [________________________]      │
│                                          │
│  [Cancelar]              [Guardar]       │
└──────────────────────────────────────────┘
```

### Campos alineados con legacy real
Los campos del formulario replican exactamente las columnas de `REGISTRO LLAMADAS.xlsx`:
- FECHA, HORA, DURACIÓN, NRO. TELÉFONO, MOTIVO, USUARIO HODOM, NOMBRE FAMILIAR, ACT/EGR, TIPO DE LLAMADA, FUNCIONARIO HD, OBSERVACIONES

---

## Pantalla 5: REM y Analítica

### Propósito
Generación automática de REM A21 Sección C y tablero de gestión institucional. Elimina redigitación.

### Usuarios principales
Estadístico, Coordinación, Dirección Técnica

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  REM A21 — HOSPITALIZACIÓN DOMICILIARIA         [Mes: Marzo ▼]  │
│  Hospital de San Carlos                         [Exportar REM]  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ── C.1.1 PERSONAS ATENDIDAS ───────────────── Estado: ✅ OK    │
│                                                                  │
│  │              │ <15a │ 15-19a │ ≥20a │ Total │                │
│  │──────────────┼──────┼────────┼──────┼───────│                │
│  │ Ingresos     │   0  │    1   │  53  │   54  │                │
│  │  - Hombres   │   0  │    0   │  28  │   28  │                │
│  │  - Mujeres   │   0  │    1   │  25  │   26  │                │
│  │ Pers. atend. │   0  │    1   │  63  │   64  │                │
│  │ Días-persona │   0  │    8   │ 458  │  466  │                │
│  │ Altas        │   0  │    1   │  53  │   54  │                │
│  │ Fall. esper. │   0  │    0   │   0  │    0  │                │
│  │ Fall. no esp.│   0  │    0   │   0  │    0  │                │
│  │ Reingreso    │   0  │    0   │   1  │    1  │                │
│                                                                  │
│  ── ORIGEN DERIVACIÓN ──────────────────────────────────────    │
│  │ APS: 5 │ UEH: 22 │ Hospitalización: 18 │ Ambulatorio: 3   │   │
│  │ Ley Urgencia: 2 │ UGCC: 4                                  │   │
│  │ Total: 54  ✅ Coincide con ingresos                        │   │
│                                                                  │
│  ── C.1.2 VISITAS REALIZADAS ───────────────── Estado: ✅ OK    │
│                                                                  │
│  │ Médico: 87 │ Enfermera: 156 │ TENS: 203 │ Matrona: 0      │   │
│  │ Kinesiólogo: 312 │ Psicólogo: 8 │ Fonoaudiólogo: 45       │   │
│  │ Trabajador Social: 23 │ Terapeuta Ocupacional: 0           │   │
│  │ Total visitas: 834                                          │   │
│                                                                  │
│  ── C.1.3 CUPOS ────────────────────────────── Estado: ✅ OK    │
│                                                                  │
│  │ Cupos programados: 20 │ Utilizados: 64 │ Disponibles: 556 │   │
│  │ Cupos adicionales (invierno): 0 │ Salud mental: 0          │   │
│  │ Adultos: 20 │ Pediatría: 0                                 │   │
│                                                                  │
│  ── VALIDACIONES ───────────────────────────────────────────    │
│  │ ✅ R.1: Origen derivación suma = ingresos                  │   │
│  │ ✅ R.2: Cupos utilizados ≤ cupos programados               │   │
│  │ ⚠️ 2 episodios sin tipo de egreso registrado               │   │
│  │ ⚠️ 3 visitas sin signos vitales                            │   │
│                                                                  │
│  ══════════════════════════════════════════════════════════════  │
│                                                                  │
│  ── ANALÍTICA OPERACIONAL ──────────────────────────────────    │
│                                                                  │
│  │ OCUPACIÓN MENSUAL           DÍAS ESTADA PROMEDIO            │   │
│  │ ████████████████░░ 75.2%    ████████ 8.6 días               │   │
│  │                                                              │   │
│  │ TENDENCIA 6 MESES                                           │   │
│  │ Oct  Nov  Dic  Ene  Feb  Mar                                │   │
│  │  83   95   88   74   78   75  ← ocupación %                 │   │
│  │  55   40   49   52   49   54  ← ingresos                   │   │
│  │                                                              │   │
│  │ PRODUCTIVIDAD POR DISCIPLINA                                │   │
│  │ Kine:     312 vis │ 14.2/día │ 4.9/paciente                │   │
│  │ Enferm:   156 vis │  7.1/día │ 2.4/paciente                │   │
│  │ TENS:     203 vis │  9.2/día │ 3.2/paciente                │   │
│  │ Médico:    87 vis │  4.0/día │ 1.4/paciente                │   │
│  │ Fono:      45 vis │  2.0/día │ 0.7/paciente                │   │
│  │                                                              │   │
│  │ TOP 5 DIAGNÓSTICOS                                          │   │
│  │ 1. Neumonía (12) │ 2. ACV (8) │ 3. Fx (7) │ 4. PIE DBT   │   │
│  │ (5) │ 5. ICC (4)                                            │   │
│  │                                                              │   │
│  │ PENDIENTES DOCUMENTALES                                     │   │
│  │ ⚠ 2 epicrisis no generadas │ ⚠ 1 consentimiento sin firma │   │
│  │ ⚠ 3 contrarreferencias APS pendientes                      │   │
└──────────────────────────────────────────────────────────────────┘
```

### Interacciones clave

| Acción | Resultado |
|--------|-----------|
| Cambiar mes | Recalcula todo desde episodios y visitas del periodo |
| Exportar REM | Genera planilla en formato DEIS para tributación |
| Click en validación ⚠ | Lista los episodios/visitas con el problema |
| Click en diagnóstico | Filtra pacientes por ese diagnóstico |
| Drill-down en productividad | Detalle por profesional individual |

---

## Formulario de registro de visita (móvil, offline-first)

Este es el formulario más usado del sistema. Debe funcionar sin conexión.

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
│  [Guardar borrador]  [Enviar ✓] │
│                                  │
│  🔄 Sin conexión: se guardará   │
│  localmente y sincronizará.     │
└──────────────────────────────────┘
```

---

## Resumen de pantallas

| # | Pantalla | Plataforma principal | Usuarios | Reemplaza |
|---|----------|---------------------|----------|-----------|
| 1 | Tablero de Coordinación | Desktop | Coordinación, Dir. Técnica | Planilla programación mensual |
| 2 | Ficha Clínica del Episodio | Desktop + Tablet | Todos los clínicos | Registros en papel + ficha física |
| 3 | Agenda y Rutas | Desktop (coord) + Móvil (terreno) | Todos | Planilla de rutas diarias |
| 4 | Llamadas | Desktop + Tablet | Administrativo, Enfermería | Planilla registro llamadas |
| 5 | REM y Analítica | Desktop | Estadístico, Coordinación | Redigitación manual REM |
| + | Formulario de visita | Móvil (offline-first) | Profesionales en terreno | Registros papel por disciplina |

---

## Siguiente paso

1. Validar estos wireframes con equipo real (coordinadora + 1 profesional terreno).
2. Priorizar qué pantalla construir primero (recomendación: Tablero + Registro de visita móvil).
3. Derivar modelo de datos funcional para soportar estas vistas.
