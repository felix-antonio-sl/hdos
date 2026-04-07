# Wireframes y Flujos — Módulos P0 del Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Autor: Allan Kelly
Prerrequisitos:
- `output/2026-04-07-usuarios-sistema-hodom-hsc.md`
- `output/2026-04-07-historias-usuario-hodom-hsc.md`
- `output/2026-04-07-arquitectura-informacion-hodom-hsc.md`

---

## Alcance

Solo los **15 historias P0** (bloqueante/obligatorio) agrupadas en los módulos que las contienen. Cada módulo incluye:
- flujo de interacción principal
- wireframe textual de cada pantalla clave
- datos mostrados/capturados
- acciones disponibles
- transiciones entre pantallas

---

## Convenciones de wireframe textual

```
┌─────────────────────────────────┐  ← borde de pantalla
│ TÍTULO DE PANTALLA              │
│─────────────────────────────────│
│ [componente]  [componente]      │  ← elementos de UI
│                                 │
│ ┌───────────────────────┐       │
│ │ zona de contenido     │       │  ← área principal
│ └───────────────────────┘       │
│                                 │
│ (Acción primaria)  (Secundaria) │  ← botones
└─────────────────────────────────┘
```

- `[campo]` = input
- `(Botón)` = acción
- `→` = navegación
- `⚠` = alerta/validación
- `📋` = lista/tabla
- `📄` = documento generado

---

# MÓDULO 1 — CENSO DE PACIENTES ACTIVOS

## HU-1.1 — Ver censo de pacientes activos

### Flujo

```
Login → Pantalla principal (Censo) → Click paciente → Ficha del paciente
                                   → Filtrar por profesional/zona/categoría
                                   → Ver alertas
```

### Wireframe: Pantalla Censo

```
┌──────────────────────────────────────────────────────────────┐
│ 🏠 HODOM HSC                          👤 Dra. López  (Salir) │
│──────────────────────────────────────────────────────────────│
│ CENSO DE PACIENTES ACTIVOS              Cupos: 22/25 (3 disp)│
│──────────────────────────────────────────────────────────────│
│ Filtros: [Profesional ▼] [Zona ▼] [Categoría ▼] (Limpiar)   │
│──────────────────────────────────────────────────────────────│
│ 📋 PACIENTES ACTIVOS (22)                                    │
│                                                              │
│ ┌──┬──────────┬────┬────┬──────┬───────┬─────┬────────┬───┐ │
│ │# │Nombre    │Edad│Días│Dx    │Categ. │Prof.│Comuna  │⚠  │ │
│ ├──┼──────────┼────┼────┼──────┼───────┼─────┼────────┼───┤ │
│ │1 │García M. │ 72 │ 5  │NAC   │ ↑ Mej │ELópez│S.Carlos│   │ │
│ │2 │Muñoz R.  │ 68 │ 9  │ICC   │ = Est │JPérez│Ñiquén │⚠9d│ │
│ │3 │Soto P.   │ 81 │ 3  │EPOC  │ ↓ Det │ELópez│S.Nicolás│⚠ │ │
│ │4 │Vega L.   │ 55 │ 6  │Celul.│ ↑ Mej │MRuiz │S.Carlos│   │ │
│ │..│ ...      │ ...│ ...│ ...  │ ...   │ ... │ ...    │...│ │
│ └──┴──────────┴────┴────┴──────┴───────┴─────┴────────┴───┘ │
│                                                              │
│ ⚠ Alertas activas: 2 pacientes >8 días | 1 deteriorándose   │
│                                                              │
│ (+ Nueva postulación)         (📊 Indicadores)  (🔄 Refresh) │
└──────────────────────────────────────────────────────────────┘
```

**Datos por fila:**
- Nombre (click → ficha)
- Edad
- Días de estada (⚠ rojo si >8)
- Diagnóstico principal
- Categoría: ↑ mejorando / = estable / ↓ deteriorándose
- Profesional responsable
- Comuna
- Alertas (icono si hay)

**Acciones:**
- Click en fila → abre ficha del paciente
- Filtros → recarga lista
- "+ Nueva postulación" → módulo 2
- "Indicadores" → módulo 8

---

# MÓDULO 2 — POSTULACIÓN Y EVALUACIÓN DE INGRESO

## Flujo completo del módulo

```
                    ┌──────────────┐
                    │ Nueva        │
                    │ Postulación  │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Registrar    │
                    │ datos        │  ← HU-2.1
                    │ candidato    │
                    └──────┬───────┘
                           │
              ┌────────────▼────────────┐
              │ Evaluación elegibilidad │
              │ (paralelo)              │
              ├─────────┬───────────────┤
              │         │               │
        ┌─────▼───┐ ┌──▼──────┐ ┌──────▼─────┐
        │Eval.    │ │Eval.    │ │Verificar   │
        │clínica  │ │domicilio│ │red apoyo   │
        │(médico) │ │(TS)     │ │(TS)        │
        │HU-2.2   │ │HU-2.3   │ │HU-2.3      │
        └─────┬───┘ └──┬──────┘ └──────┬─────┘
              │         │               │
              └────────┬┘───────────────┘
                       │
                ┌──────▼───────┐
                │ ¿Elegible?   │
                ├──SI──────────┤──NO──→ Rechazo (HU-2.6)
                │              │
         ┌──────▼───────┐      │
         │ Consentimiento│      │
         │ informado     │      │
         │ (HU-2.4)      │      │
         └──────┬────────┘      │
                │               │
         ┌──────▼───────┐      │
         │ Formalizar   │      │
         │ ingreso      │      │
         │ (HU-2.5)     │      │
         └──────┬───────┘      │
                │              │
         ┌──────▼───────┐      │
         │ Paciente     │      │
         │ ACTIVO       │      │
         │ → Censo      │      │
         └──────────────┘      │
```

### HU-2.1 — Wireframe: Registrar postulación

```
┌──────────────────────────────────────────────────────────────┐
│ ← Volver al censo                                            │
│──────────────────────────────────────────────────────────────│
│ NUEVA POSTULACIÓN                         Nro: AUTO-2026-0847│
│──────────────────────────────────────────────────────────────│
│                                                              │
│ DATOS DEL CANDIDATO                                          │
│ [RUT ___________] (Buscar)  ⚠ Valida formato + dígito verif.│
│ Nombre: [________________________]                           │
│ Fecha nac: [__/__/____]  Edad: 72 ✓ ≥18                     │
│ Sexo: (M) (F)                                                │
│ Previsión: [Fonasa A ▼]  ✓ Fonasa/PRAIS                     │
│ Comuna: [San Carlos ▼]                                       │
│ Dirección: [________________________]                        │
│ Teléfono: [____________]                                     │
│ CESFAM: [CESFAM San Carlos ▼]                                │
│                                                              │
│ DERIVACIÓN                                                   │
│ Servicio derivador: [Medicina interna ▼]                     │
│ Origen: (●Hosp.cerrada) (○Urgencia) (○APS) (○Ambulatorio)   │
│         (○Ley urgencia) (○Gestión camas)                     │
│ Médico derivador: [________________________]                 │
│ Diagnóstico derivación: [________________________]           │
│ CIE-10: [J18.9 ▼] Neumonía                                  │
│                                                              │
│ VALIDACIÓN AUTOMÁTICA                                        │
│ ✓ Edad ≥ 18                                                  │
│ ✓ Previsión Fonasa                                           │
│ ○ Radio cobertura: pendiente evaluación domicilio            │
│ ○ Condición clínica: pendiente evaluación médica             │
│ ○ Exclusiones: pendiente evaluación médica                   │
│ ○ Cuidador: pendiente evaluación social                      │
│ ○ Domicilio: pendiente evaluación social                     │
│ ○ Consentimiento: pendiente                                  │
│                                                              │
│ (Guardar postulación)                    (Cancelar)          │
└──────────────────────────────────────────────────────────────┘
```

### HU-2.2 — Wireframe: Evaluación clínica

```
┌──────────────────────────────────────────────────────────────┐
│ ← Postulación #2026-0847 — García Muñoz, María (72 años)    │
│──────────────────────────────────────────────────────────────│
│ EVALUACIÓN DE ELEGIBILIDAD CLÍNICA          Dr. Pérez        │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ Diagnóstico principal: NAC — J18.9                           │
│ Servicio derivador: Medicina interna                         │
│                                                              │
│ CONDICIÓN CLÍNICA                                            │
│ ¿Condición clínica estable? (●Sí) (○No)                     │
│ Observaciones: [________________________________]            │
│                                                              │
│ CONDICIONES DE EXCLUSIÓN (DS 1/2022 art. 17)                 │
│ ┌─────────────────────────────────────────────┬─────┐        │
│ │ Inestabilidad clínica                       │ □ No│        │
│ │ Diagnóstico no establecido                  │ □ No│        │
│ │ Salud mental descompensada                  │ □ No│        │
│ │ Prestación no incluida en listado           │ □ No│        │
│ │ Alta disciplinaria previa                   │ □ No│        │
│ └─────────────────────────────────────────────┴─────┘        │
│ ⚠ Si alguna condición = Sí → candidato NO ELEGIBLE          │
│                                                              │
│ RESULTADO                                                    │
│ (✓ Aprobar evaluación clínica)   (✗ Rechazar con motivo)     │
└──────────────────────────────────────────────────────────────┘
```

### HU-2.3 — Wireframe: Evaluación domicilio y red de apoyo

```
┌──────────────────────────────────────────────────────────────┐
│ ← Postulación #2026-0847 — García Muñoz, María              │
│──────────────────────────────────────────────────────────────│
│ EVALUACIÓN SOCIOSANITARIA DEL DOMICILIO     TS Rodríguez     │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ DOMICILIO                                                    │
│ Dirección: Av. Bulnes 1234, San Carlos                       │
│ Comuna: San Carlos                                           │
│ Distancia al hospital: [8.5] km  ✓ ≤ 20 km                  │
│                                                              │
│ CONDICIONES SANITARIAS                                       │
│ Agua potable: (●Sí) (○No)                                   │
│ Electricidad: (●Sí) (○No)                                   │
│ Baño/letrina: (●Sí) (○No)                                   │
│ Telefonía:    (●Sí) (○No)                                   │
│ Acceso vial:  (●Adecuado) (○Difícil) (○Inaccesible)         │
│ Condición general: (●Adecuada) (○Inadecuada)                │
│                                                              │
│ CUIDADOR / RED DE APOYO                                      │
│ ¿Tiene cuidador disponible? (●Sí) (○No)                     │
│ Nombre cuidador: [María Soto Pérez        ]                  │
│ RUT cuidador:    [12.345.678-9            ]                  │
│ Parentesco:      [Hija ▼]                                    │
│ Teléfono:        [+56 9 1234 5678         ]                  │
│ Red de apoyo:    (●Verificada) (○Insuficiente)               │
│                                                              │
│ Observaciones: [________________________________]            │
│                                                              │
│ (✓ Aprobar evaluación domicilio)  (✗ Domicilio inadecuado)   │
└──────────────────────────────────────────────────────────────┘
```

### HU-2.4 — Wireframe: Consentimiento informado

```
┌──────────────────────────────────────────────────────────────┐
│ ← Postulación #2026-0847 — García Muñoz, María              │
│──────────────────────────────────────────────────────────────│
│ CONSENTIMIENTO INFORMADO                    Enf. López       │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ IDENTIFICACIÓN                                               │
│ Paciente: María García Muñoz — RUT 9.876.543-2              │
│ Cuidador: María Soto Pérez — RUT 12.345.678-9 (Hija)        │
│ CESFAM: CESFAM San Carlos                                    │
│ Teléfono contacto: +56 9 1234 5678                           │
│                                                              │
│ CLÁUSULAS INFORMADAS                                         │
│ ┌─────────────────────────────────────────────────┬───┐      │
│ │ 1. Atención L-D 08:00-19:00 por equipo de salud│ ✓ │      │
│ │ 2. Estadía máxima 6-8 días                      │ ✓ │      │
│ │ 3. Emergencias fuera de horario: SAMU 131       │ ✓ │      │
│ │ 4. Consulta telefónica: 42 2586292 (L-V)        │ ✓ │      │
│ │ 5. Derechos y deberes entregados                │ ✓ │      │
│ │ 6. Datos sensibles protegidos (Ley 19.628)      │ ✓ │      │
│ └─────────────────────────────────────────────────┴───┘      │
│                                                              │
│ DECISIÓN                                                     │
│ (● ACEPTO la hospitalización domiciliaria)                   │
│ (○ RECHAZO la hospitalización domiciliaria)                  │
│                                                              │
│ Carta de derechos y deberes entregada: (●Sí) (○No)          │
│                                                              │
│ Firma paciente: [________________________] Fecha: [hoy]      │
│ Firma cuidador: [________________________] Parentesco: Hija  │
│                                                              │
│ (✓ Registrar consentimiento)              (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

### HU-2.5 — Wireframe: Formalizar ingreso

```
┌──────────────────────────────────────────────────────────────┐
│ ← Postulación #2026-0847 — García Muñoz, María              │
│──────────────────────────────────────────────────────────────│
│ FORMALIZAR INGRESO A HODOM                                   │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ RESUMEN DE EVALUACIÓN                                        │
│ ✓ Evaluación clínica: aprobada (Dr. Pérez)                   │
│ ✓ Evaluación domicilio: aprobada (TS Rodríguez)              │
│ ✓ Red de apoyo: verificada                                   │
│ ✓ Consentimiento: firmado                                    │
│ ✓ Edad ≥ 18: Sí (72 años)                                   │
│ ✓ Previsión: Fonasa A                                        │
│ ✓ Radio: 8.5 km (≤ 20 km)                                   │
│ ✓ Sin exclusiones                                            │
│                                                              │
│ DATOS DEL EPISODIO                                           │
│ Fecha ingreso: [30/03/2026]                                  │
│ Equipo asignado: [Equipo Norte ▼]                            │
│ Profesional responsable: [Enf. López ▼]                      │
│                                                              │
│ DOCUMENTOS GENERADOS AUTOMÁTICAMENTE                         │
│ 📄 Formulario de ingreso                                     │
│ 📄 Ficha clínica (estado: activa)                            │
│ 📄 Vinculación CI firmado                                    │
│ 📄 Vinculación Informe Social                                │
│                                                              │
│ Cupos actuales: 22/25 → después del ingreso: 23/25          │
│                                                              │
│ ⚠ Esta acción crea el episodio y activa la ficha clínica.   │
│                                                              │
│ (✓ CONFIRMAR INGRESO)                     (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

---

# MÓDULO 3 — FICHA CLÍNICA DOMICILIARIA

## Flujo de navegación

```
Censo → Click paciente → Ficha clínica
                            ├── Timeline (cronológica inversa)
                            ├── Signos vitales (tabla/gráfico)
                            ├── Medicación activa
                            ├── Plan de cuidados
                            ├── Documentos
                            └── + Nuevo registro
                                  ├── Ingreso enfermería
                                  ├── Signos vitales
                                  ├── Narrativa enfermería
                                  ├── Evolución médica
                                  └── Registro kinesiología
```

### HU-3.1 — Wireframe: Ficha clínica longitudinal

```
┌──────────────────────────────────────────────────────────────┐
│ ← Censo                                                      │
│──────────────────────────────────────────────────────────────│
│ GARCÍA MUÑOZ, MARÍA — 72a F — RUT 9.876.543-2               │
│ NAC (J18.9) | Día 5 | Fonasa A | San Carlos                 │
│ Categoría: ↑ Mejorando | Barthel ingreso: 65                │
│──────────────────────────────────────────────────────────────│
│ [Timeline] [Signos vitales] [Medicación] [Plan] [Documentos]│
│──────────────────────────────────────────────────────────────│
│                                                              │
│ 📋 TIMELINE                              (+ Nuevo registro)  │
│                                                              │
│ ── 30/03/2026 ──────────────────────────────────────────     │
│ 🩺 16:30 Evolución médica — Dr. Pérez                        │
│    Paciente estable, afebril. SpO2 95% AA. Sigue tto EV.    │
│    Indicación: continuar ceftriaxona 2g c/24h EV.           │
│    → Decisión: continuar tratamiento                         │
│                                                              │
│ 💉 10:00 Registro enfermería — Enf. López                    │
│    SV: PA 130/80 | FC 78 | FR 18 | T° 36.8 | SpO2 95%      │
│    HGT 112 | EVA 2 | Glasgow 15 | Edema (-) | Diuresis OK   │
│    Medicamentos: Ceftriaxona 2g EV (dosis 5/7)              │
│    VVP: brazo izq., instalada 26/03, sin signos infección    │
│    Plan: mantener tto EV, control SV c/8h, curación VVP     │
│                                                              │
│ ── 29/03/2026 ──────────────────────────────────────────     │
│ 🏃 14:00 Registro kinesiología — Kine. Muñoz                 │
│    Barthel actual: 70 (ingreso: 65, Δ +5)                   │
│    Ejercicios respiratorios + deambulación asistida          │
│    SpO2 post-ejercicio: 93% → requiere reposo                │
│                                                              │
│ 💉 09:30 Registro enfermería — Enf. López                    │
│    SV: PA 125/75 | FC 82 | FR 20 | T° 37.2 | SpO2 94%      │
│    ...                                                       │
│                                                              │
│ ── 28/03/2026 ──────────────────────────────────────────     │
│ ...                                                          │
└──────────────────────────────────────────────────────────────┘
```

### HU-3.2 — Wireframe: Ingreso de enfermería

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María                                 │
│──────────────────────────────────────────────────────────────│
│ INGRESO DE ENFERMERÍA HODOM            Enf. López            │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ Nro. Postulación: 2026-0847                                  │
│ Fecha ingreso: 26/03/2026  Fecha visita ingreso: 26/03/2026 │
│ Servicio origen: Medicina interna                            │
│                                                              │
│ CHECKLIST DE INGRESO                                         │
│ ┌──────────────────────────────────────┬────┬────┬────┐      │
│ │ Ítem                                 │ Sí │ No │ NA │      │
│ ├──────────────────────────────────────┼────┼────┼────┤      │
│ │ Carta derechos y deberes entregada   │ ●  │    │    │      │
│ │ CI firmado                           │ ●  │    │    │      │
│ │ Indicaciones médicas recibidas       │ ●  │    │    │      │
│ │ Recetas entregadas                   │ ●  │    │    │      │
│ │ Insumos entregados                   │ ●  │    │    │      │
│ │ Equipamiento instalado               │    │    │ ●  │      │
│ │ Educación al cuidador realizada      │ ●  │    │    │      │
│ └──────────────────────────────────────┴────┴────┴────┘      │
│                                                              │
│ BARTHEL DE INGRESO: [65] /100                                │
│                                                              │
│ EXAMEN FÍSICO (6 dominios)                                   │
│ Estado general: [Alerta, orientada, cooperadora ▼]           │
│ Piel y tegumentos: [Piel pálida, sin lesiones ▼]             │
│ Cardiovascular: [Sin hallazgos patológicos ▼]                │
│ Respiratorio: [MP (+), crépitos base derecha ▼]              │
│ Abdominal: [BDI, sin dolor ▼]                                │
│ Neurológico: [Glasgow 15, sin focalidad ▼]                   │
│                                                              │
│ EXAMEN SEGMENTARIO (12 regiones)                             │
│ Cabeza: [Sin alteraciones]  Cuello: [Sin adenopatías]        │
│ Tórax: [Crépitos base D]   Abdomen: [BDI, indoloro]         │
│ EESS: [Sin edema]          EEII: [Edema leve bilateral]     │
│ ...                                                          │
│                                                              │
│ HISTORIA CLÍNICA                                             │
│ Antecedentes: [HTA, DM2, EPOC                     ]         │
│ Medicamentos crónicos: [Losartan 50mg, Metformina  ]         │
│ Exámenes relevantes: [PCR 45, Hemocultivo pendiente]         │
│                                                              │
│ DIAGNÓSTICO ENFERMERÍA: [Riesgo infección VVP      ]         │
│ PLAN ATENCIÓN: [Control SV c/8h, curación VVP c/72h]        │
│                                                              │
│ Prof. responsable ingreso: [Enf. López ▼]                    │
│ Prof. responsable VD: [Enf. López ▼]                         │
│                                                              │
│ (✓ Guardar ingreso enfermería)            (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

### HU-3.3 — Wireframe: Registro signos vitales

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María                                 │
│──────────────────────────────────────────────────────────────│
│ REGISTRO CICLO VITAL                     Enf. López          │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ Fecha: [30/03/2026]  Hora: [10:00]                           │
│                                                              │
│ ┌─────────────────┬────────────┬──────────┐                  │
│ │ Variable        │ Valor      │ Rango    │                  │
│ ├─────────────────┼────────────┼──────────┤                  │
│ │ PA sistólica    │ [130]      │ 90-140   │                  │
│ │ PA diastólica   │ [80]       │ 60-90    │                  │
│ │ FC              │ [78]       │ 60-100   │                  │
│ │ FR              │ [18]       │ 12-20    │                  │
│ │ Temperatura     │ [36.8]     │ 36-37.5  │                  │
│ │ SpO2 %          │ [95]       │ 92-100   │                  │
│ │ HGT mg/dL       │ [112]      │ 70-180   │                  │
│ │ EVA (0-10)      │ [2]        │ 0-10     │                  │
│ │ Glasgow (3-15)  │ [15]       │ 3-15     │                  │
│ │ Edema           │ [(-) ▼]    │ -/+/++   │                  │
│ │ Diuresis        │ [Normal ▼] │          │                  │
│ │ Deposiciones    │ [Normal ▼] │          │                  │
│ └─────────────────┴────────────┴──────────┘                  │
│                                                              │
│ Dispositivos invasivos:                                      │
│ [VVP brazo izq ▼] Estado: [Sin signos infección ▼]          │
│ (+ Agregar dispositivo)                                      │
│                                                              │
│ Observaciones: [Paciente afebril, hemodinámicamente estable] │
│                                                              │
│ ⚠ Valores fuera de rango se resaltan automáticamente         │
│                                                              │
│ (✓ Guardar signos vitales)                (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

### HU-3.4 — Wireframe: Narrativa clínica enfermería

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María                                 │
│──────────────────────────────────────────────────────────────│
│ REGISTRO DE ENFERMERÍA                   Enf. López          │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ NARRATIVA CLÍNICA                                            │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ Paciente tranquila, afebril, tolerando vía oral.     │     │
│ │ Se administra ceftriaxona 2g EV sin incidentes.      │     │
│ │ Curación VVP: sitio limpio, sin signos de infección. │     │
│ │ Cuidadora presente y colaboradora.                   │     │
│ └──────────────────────────────────────────────────────┘     │
│ Caracteres: 243/800                                          │
│                                                              │
│ MEDICAMENTOS ADMINISTRADOS                                   │
│ ┌────────────────┬──────┬────────┬─────┬──────┐             │
│ │ Medicamento    │ Dosis│Dilución│ Vía │#Dosis│             │
│ ├────────────────┼──────┼────────┼─────┼──────┤             │
│ │ Ceftriaxona    │ 2g   │ SF 100 │ EV  │ 5/7  │             │
│ │ Paracetamol    │ 1g   │ —      │ VO  │ 2/3  │             │
│ └────────────────┴──────┴────────┴─────┴──────┘             │
│ (+ Agregar medicamento)                                      │
│                                                              │
│ PLAN DE ENFERMERÍA                                           │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ 1. Control SV c/8h                                   │     │
│ │ 2. Curación VVP c/72h                                │     │
│ │ 3. Vigilar permeabilidad vía venosa                  │     │
│ │ 4. Educación al cuidador sobre signos de alarma      │     │
│ └──────────────────────────────────────────────────────┘     │
│ (+ Agregar intervención)                                     │
│                                                              │
│ DISPOSITIVOS INVASIVOS                                       │
│ ┌────────┬────────────┬────────┬──────────┬──────────┐      │
│ │ Tipo   │ Instalación│ Cambio │ Infección│ Obs.     │      │
│ ├────────┼────────────┼────────┼──────────┼──────────┤      │
│ │ VVP    │ 26/03      │ 29/03  │ No       │ Brazo izq│      │
│ └────────┴────────────┴────────┴──────────┴──────────┘      │
│                                                              │
│ (✓ Guardar registro enfermería)           (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

---

# MÓDULO 4 — PRESCRIPCIÓN Y TRATAMIENTO

### HU-4.1 — Wireframe: Prescripción médica

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María                                 │
│──────────────────────────────────────────────────────────────│
│ PRESCRIPCIÓN MÉDICA                      Dr. Pérez           │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ MEDICACIÓN ACTIVA                                            │
│ ┌────────────────┬──────┬─────┬──────────┬────────┬───┐     │
│ │ Medicamento    │ Dosis│ Vía │Frecuencia│ Inicio │ ⚙ │     │
│ ├────────────────┼──────┼─────┼──────────┼────────┼───┤     │
│ │ Ceftriaxona    │ 2g   │ EV  │ c/24h    │ 26/03  │ ✏ │     │
│ │ Paracetamol    │ 1g   │ VO  │ c/8h SOS │ 26/03  │ ✏ │     │
│ │ Losartan       │ 50mg │ VO  │ c/24h    │crónico │ ✏ │     │
│ └────────────────┴──────┴─────┴──────────┴────────┴───┘     │
│                                                              │
│ (+ Nueva prescripción)                                       │
│                                                              │
│ ┌─ NUEVA PRESCRIPCIÓN ──────────────────────────────┐        │
│ │ Medicamento: [Enoxaparina          ]               │        │
│ │ Dosis:       [40 mg                ]               │        │
│ │ Dilución:    [—                    ]               │        │
│ │ Vía:         [SC ▼]                                │        │
│ │ Frecuencia:  [c/24h               ]                │        │
│ │ Duración:    [7 días              ]                │        │
│ │ Indicación:  [Profilaxis TVP       ]               │        │
│ │                                                    │        │
│ │ (✓ Prescribir)              (Cancelar)             │        │
│ └────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

### HU-4.2 — Wireframe: Plan terapéutico vigente (vista)

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María                                 │
│──────────────────────────────────────────────────────────────│
│ PLAN TERAPÉUTICO VIGENTE                  Estado: ACTIVO     │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ INDICACIONES MÉDICAS                                         │
│ • Ceftriaxona 2g EV c/24h × 7 días (día 5/7)               │
│ • Paracetamol 1g VO c/8h SOS T° >38°C                      │
│ • Enoxaparina 40mg SC c/24h × 7 días ⭐ NUEVO               │
│ • Losartan 50mg VO c/24h (crónico)                          │
│ • Metformina 850mg VO c/12h (crónico)                       │
│                                                              │
│ REQUERIMIENTOS DE CUIDADO                                    │
│ ☑ Tratamiento EV (enfermería)                                │
│ ☑ Tratamiento SC (enfermería)                                │
│ ☑ Control signos vitales c/8h                                │
│ ☑ Curación VVP c/72h                                         │
│ ☑ Terapia respiratoria (kinesiología)                        │
│ ☑ Deambulación asistida (kinesiología)                       │
│                                                              │
│ METAS                                                        │
│ 🎯 Alta en 2 días (7 días total tto EV)                      │
│ 🎯 SpO2 >94% en aire ambiente                                │
│ 🎯 Barthel ≥80 al egreso                                     │
│                                                              │
│ Última modificación: 30/03/2026 — Dr. Pérez                  │
└──────────────────────────────────────────────────────────────┘
```

---

# MÓDULO 5 — PROGRAMACIÓN DE VISITAS

### HU-5.1 — Wireframe: Programación diaria

```
┌──────────────────────────────────────────────────────────────┐
│ 🏠 HODOM HSC                                                 │
│──────────────────────────────────────────────────────────────│
│ PROGRAMACIÓN DE VISITAS         Fecha: [31/03/2026]          │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ PROFESIONALES DISPONIBLES HOY                                │
│ ┌──────────────┬───────┬────────┬──────┐                     │
│ │ Profesional  │ Rol   │ Turno  │ Asig.│                     │
│ ├──────────────┼───────┼────────┼──────┤                     │
│ │ Enf. López   │ Enf.  │ 08-19  │ 6/8  │                     │
│ │ Enf. Díaz    │ Enf.  │ 08-19  │ 5/8  │                     │
│ │ Dr. Pérez    │ Méd.  │ 08-17  │ 4/6  │                     │
│ │ Kine Muñoz   │ Kine  │ 08-19  │ 7/8  │                     │
│ │ Fono Reyes   │ Fono  │ 08-17  │ 3/5  │                     │
│ │ TS Rodríguez │ TS    │ 08-17  │ 2/4  │                     │
│ └──────────────┴───────┴────────┴──────┘                     │
│                                                              │
│ VISITAS PROGRAMADAS (22 pacientes)                           │
│ ┌──┬──────────┬──────────┬───────┬──────┬───────────┐        │
│ │# │Paciente  │Profesional│Orden │ Hora │ Zona      │        │
│ ├──┼──────────┼──────────┼───────┼──────┼───────────┤        │
│ │1 │García M. │Enf. López│ 1/6  │08:30 │S.Carlos   │        │
│ │2 │Vega L.   │Enf. López│ 2/6  │09:15 │S.Carlos   │        │
│ │3 │Muñoz R.  │Dr. Pérez │ 1/4  │08:45 │Ñiquén     │        │
│ │..│...       │...       │ ...  │ ...  │...        │        │
│ └──┴──────────┴──────────┴───────┴──────┴───────────┘        │
│                                                              │
│ ⚠ Sin visita programada: Soto P. (día 3, deteriorándose)     │
│                                                              │
│ (+ Agregar visita) (🔄 Auto-asignar)  (📋 Ver rutas)         │
└──────────────────────────────────────────────────────────────┘
```

---

# MÓDULO 6 — EGRESO Y CONTINUIDAD

### HU-6.1 + HU-6.2 — Wireframe: Decisión de egreso

```
┌──────────────────────────────────────────────────────────────┐
│ ← Ficha García Muñoz, María — Día 7                         │
│──────────────────────────────────────────────────────────────│
│ DECISIÓN DE CONTINUIDAD / EGRESO          Dr. Pérez          │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ ESTADO ACTUAL                                                │
│ Categoría: ↑ Mejorando                                       │
│ Días de estada: 7  ⚠ Próximo al máximo (6-8 días)           │
│ Barthel actual: 75 (ingreso: 65, Δ +10)                     │
│ Último SpO2: 96% AA                                          │
│ Tto EV completado: Sí (7/7 dosis ceftriaxona)               │
│                                                              │
│ DECISIÓN                                                     │
│ (○ Continuar tratamiento)                                    │
│ (● Proceder a egreso)                                        │
│                                                              │
│ TIPO DE EGRESO                                               │
│ (● Alta médica)                                              │
│ (○ Reingreso hospitalario)                                   │
│ (○ Fallecimiento esperado)                                   │
│ (○ Fallecimiento no esperado)                                │
│ (○ Renuncia voluntaria)                                      │
│ (○ Alta disciplinaria) ⚠ Requiere autorización DT            │
│                                                              │
│ Fundamento clínico:                                          │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ Paciente completa 7 días de tto antibiótico EV con   │     │
│ │ buena evolución clínica. Afebril hace 72h. SpO2 96%  │     │
│ │ AA. Barthel mejorado (+10). Se decide alta médica     │     │
│ │ con indicaciones ambulatorias y contrarreferencia.     │     │
│ └──────────────────────────────────────────────────────┘     │
│                                                              │
│ BARTHEL DE EGRESO: [75] /100                                 │
│ Δ Barthel: +10 (mejoría)                                     │
│                                                              │
│ DOCUMENTOS QUE SE GENERARÁN                                  │
│ 📄 Epicrisis (se completará a continuación)                  │
│ 📄 Encuesta de satisfacción (se activará)                    │
│ 📄 Seguimiento post-egreso 48h (se programará)               │
│                                                              │
│ ⚠ Esta acción cierra la ficha clínica y libera el cupo.     │
│                                                              │
│ (✓ CONFIRMAR EGRESO → Generar epicrisis)  (Cancelar)         │
└──────────────────────────────────────────────────────────────┘
```

### HU-6.3 — Wireframe: Generación de epicrisis

```
┌──────────────────────────────────────────────────────────────┐
│ ← Egreso García Muñoz, María                                │
│──────────────────────────────────────────────────────────────│
│ EPICRISIS                                 Dr. Pérez          │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ ── DATOS AUTOCOMPLETADOS ──                                  │
│ Paciente: María García Muñoz, 72 años, F, Fonasa A          │
│ RUT: 9.876.543-2                                             │
│ Ingreso: 26/03/2026 | Egreso: 01/04/2026 | Estada: 7 días   │
│ Origen: Medicina interna                                     │
│ Tipo egreso: Alta médica                                     │
│                                                              │
│ Dx principal: NAC (J18.9)                                    │
│ Dx secundarios: HTA (I10), DM2 (E11.9), EPOC (J44.9)       │
│                                                              │
│ Barthel: ingreso 65 → egreso 75 (Δ +10)                     │
│                                                              │
│ ── TRATAMIENTO REALIZADO ──                                  │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ • Ceftriaxona 2g EV c/24h × 7 días (completado)     │     │
│ │ • Enoxaparina 40mg SC c/24h × 7 días                │     │
│ │ • Terapia respiratoria kinésica diaria               │     │
│ │ • Curaciones VVP c/72h                               │     │
│ └──────────────────────────────────────────────────────┘     │
│                                                              │
│ ── EVOLUCIÓN (editable) ──                                   │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ Paciente ingresa por NAC con buena evolución bajo    │     │
│ │ tto antibiótico EV. Completa esquema de 7 días.      │     │
│ │ Afebril, hemodinámicamente estable, SpO2 96% AA.     │     │
│ │ Mejoría funcional documentada (Barthel +10).         │     │
│ └──────────────────────────────────────────────────────┘     │
│                                                              │
│ ── INDICACIONES AL ALTA ──                                   │
│ ┌──────────────────────────────────────────────────────┐     │
│ │ 1. Amoxicilina/Ac. Clavulánico 875/125 VO c/12h ×7d │     │
│ │ 2. Paracetamol 1g VO c/8h SOS                       │     │
│ │ 3. Continuar medicación crónica habitual             │     │
│ │ 4. Control médico en CESFAM en 7 días               │     │
│ │ 5. Consultar en urgencia si fiebre, disnea o dolor   │     │
│ └──────────────────────────────────────────────────────┘     │
│                                                              │
│ ── CONTRARREFERENCIA ──                                      │
│ CESFAM destino: [CESFAM San Carlos ▼]                        │
│ Control en: [7] días                                         │
│ Motivo: Control evolución NAC post-alta HODOM                │
│                                                              │
│ (👁 Preview)  (🖨 Imprimir)  (✓ Guardar epicrisis)           │
└──────────────────────────────────────────────────────────────┘
```

---

# MÓDULO 8 — REPORTERÍA (REM)

### HU-8.1 — Wireframe: Generación REM A21 sección C

```
┌──────────────────────────────────────────────────────────────┐
│ 🏠 HODOM HSC                                                 │
│──────────────────────────────────────────────────────────────│
│ GENERACIÓN REM A21 SECCIÓN C              Período: [Mar 2026]│
│──────────────────────────────────────────────────────────────│
│                                                              │
│ VALIDACIÓN PREVIA                                            │
│ ✓ Fichas clínicas cerradas: 28/28                            │
│ ✓ PE-8: personas = 20 + 12 - 10 - 0 = 22 ✓                  │
│ ✓ PE-9: ∑ origen derivación = ∑ por rango etario ✓           │
│ ✓ PE-10: cupos utilizados (22) ≤ programados (25) ✓          │
│ ⚠ 2 episodios con estada > 8 días                            │
│                                                              │
│ C.1.1 PERSONAS ATENDIDAS                                     │
│ ┌────────────────┬─────┬──────┬──────┬──────┐               │
│ │ Componente     │Total│ <15  │ Masc.│ APS  │               │
│ ├────────────────┼─────┼──────┼──────┼──────┤               │
│ │ Activos mes ant│  20 │   0  │   9  │   3  │               │
│ │ Ingresos       │  12 │   0  │   5  │   2  │               │
│ │ Egresos        │  10 │   0  │   4  │   2  │               │
│ │ Fallecidos esp │   0 │   0  │   0  │   0  │               │
│ │ Fallecidos no  │   0 │   0  │   0  │   0  │               │
│ │ Personas atend.│  22 │   0  │  10  │   3  │               │
│ └────────────────┴─────┴──────┴──────┴──────┘               │
│                                                              │
│ C.1.2 VISITAS POR PROFESIÓN                                  │
│ ┌─────────────────┬───────┐                                  │
│ │ Profesión REM   │ Total │                                  │
│ ├─────────────────┼───────┤                                  │
│ │ Médico          │   108 │                                  │
│ │ Enfermera       │   396 │                                  │
│ │ Kinesiólogo     │   270 │                                  │
│ │ Fonoaudiólogo   │   108 │                                  │
│ │ Trabajador Soc. │    94 │                                  │
│ │ TENS            │    36 │                                  │
│ └─────────────────┴───────┘                                  │
│                                                              │
│ C.1.3 CUPOS                                                  │
│ Programados: [25]  Utilizados: 22  Disponibles: 3            │
│                                                              │
│ (👁 Preview REM)  (📤 Exportar tributación)  (🖨 Imprimir)    │
└──────────────────────────────────────────────────────────────┘
```

---

## Resumen de pantallas diseñadas

| Módulo | Pantalla | HU | Usuario principal |
|--------|----------|-----|-------------------|
| 1 | Censo pacientes activos | HU-1.1 | Coordinadora |
| 2 | Nueva postulación | HU-2.1 | Coordinadora |
| 2 | Evaluación clínica | HU-2.2 | Médico AD |
| 2 | Evaluación domicilio | HU-2.3 | Trabajador social |
| 2 | Consentimiento informado | HU-2.4 | Enfermera |
| 2 | Formalizar ingreso | HU-2.5 | Coordinadora |
| 3 | Ficha clínica (timeline) | HU-3.1 | Todos los clínicos |
| 3 | Ingreso enfermería | HU-3.2 | Enfermera |
| 3 | Registro signos vitales | HU-3.3 | Enfermera / TENS |
| 3 | Narrativa enfermería | HU-3.4 | Enfermera |
| 4 | Prescripción médica | HU-4.1 | Médico AD |
| 4 | Plan terapéutico vigente | HU-4.2 | Todos los clínicos |
| 5 | Programación visitas | HU-5.1 | Coordinadora |
| 6 | Decisión egreso | HU-6.1+6.2 | Médico AD |
| 6 | Epicrisis | HU-6.3 | Médico AD |
| 8 | Generación REM | HU-8.1 | Estadístico |

**Total: 16 pantallas** cubriendo las **15 historias P0**.

---

## Navegación principal

```
┌─────────┐     ┌──────────┐     ┌───────────┐
│  Login  │────→│  CENSO   │────→│  Ficha    │
│         │     │ (home)   │     │  paciente │
└─────────┘     └────┬─────┘     └─────┬─────┘
                     │                  │
              ┌──────┼──────┐     ┌─────┼────────────┐
              │      │      │     │     │     │      │
          ┌───▼──┐┌──▼──┐┌─▼──┐ ┌▼──┐┌─▼─┐┌──▼──┐┌──▼──┐
          │Nueva ││Visit││Ind.│ │SV ││Rx ││Nota ││Egre.│
          │Post. ││Prog.││REM │ │   ││   ││     ││     │
          └──────┘└─────┘└────┘ └───┘└───┘└─────┘└─────┘
```

---

## Siguiente paso

Con los wireframes P0 definidos, las rutas posibles son:

1. **Implementación técnica** — construir sobre el ERD de 43 tablas + hdos como base
2. **Wireframes P1** — agregar las 12 pantallas de prioridad alta
3. **Prototipo interactivo** — convertir estos wireframes en prototipo navegable

Mi recomendación: **ir directo a implementación de Fase 1** sobre el stack existente.
