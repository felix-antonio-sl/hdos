# Modelo de Dominio HODOM HSC — Taxonomía HL7 FHIR R4
## Hospital de San Carlos — Servicio de Salud Ñuble

**Base:** HL7 FHIR R4 (4.0.1) + extensiones para telemetría domiciliaria
**Fuente:** Evidencia operacional real + DS 1/2022 + NT HD 2024

---

## 1. Mapeo Entidad HODOM → Recurso FHIR

| Concepto HODOM | Recurso FHIR R4 | Notas |
|---|---|---|
| Paciente | **Patient** | Identidad, demografía, contacto |
| Domicilio del paciente | **Location** (kind=`house`) | Coordenadas, dirección, evaluación |
| Episodio HODOM | **EpisodeOfCare** | Período ingreso→egreso, equipo, estado |
| Plan de cuidados | **CarePlan** | Actividades programadas, metas, condiciones |
| Visita domiciliaria | **Encounter** (class=`HH`) | Encuentro clínico en domicilio |
| Atención profesional | **Procedure** | Cada prestación realizada |
| Prestación programada | **ServiceRequest** | Orden/solicitud de prestación |
| Profesional | **Practitioner** | Identidad, profesión |
| Equipo HODOM | **CareTeam** | Composición del equipo por episodio |
| Diagnóstico | **Condition** | CIE-10, estado clínico |
| Consentimiento | **Consent** | Firma, alcance, período |
| Vehículo (móvil) | **Device** (type=`vehicle`) | Patente, límites, GPS device |
| Evento GPS | **Location** + extensión telemetría | Parada/movimiento con timestamp |
| Bloque de ruta | **Schedule** + **Slot** | Programación diaria por vehículo |
| Programación diaria | **Appointment** (por visita) | Hora, paciente, equipo, vehículo |
| Derivación hospitalaria | **ServiceRequest** (intent=`order`) | Origen de la derivación |
| Evaluación domicilio | **QuestionnaireResponse** | Formulario NT 2024 |
| Observaciones clínicas | **Observation** | Signos vitales, NEWS2, etc. |
| Documentos (epicrisis, etc.) | **DocumentReference** | PDFs, formularios escaneados |

---

## 2. Recursos FHIR Detallados

### 2.1 Patient (Paciente)

```json
{
  "resourceType": "Patient",
  "identifier": [
    {
      "system": "urn:oid:2.16.152.1",  // RUT Chile
      "value": "12345678-9"
    },
    {
      "system": "urn:hodom-hsc:paciente-id",
      "value": "PAC-087"
    }
  ],
  "name": [{
    "family": "PINCHEIRA ARIAS",
    "given": ["LUIS"]
  }],
  "gender": "male",
  "birthDate": "1954-03-12",
  "telecom": [
    {"system": "phone", "value": "965044833", "use": "mobile"}
  ],
  "address": [{
    "use": "home",
    "text": "AGUA BUENA S/N X CAPE, SAN CARLOS",
    "city": "San Carlos",
    "district": "Punilla",
    "state": "Ñuble",
    "country": "CL",
    "extension": [{
      "url": "urn:hodom-hsc:location-reference",
      "valueReference": {"reference": "Location/DOM-0042"}
    }]
  }],
  "extension": [{
    "url": "urn:minsal:prevision",
    "valueCoding": {"code": "A", "display": "FONASA A"}
  }]
}
```

**Brecha actual:** Hoy el paciente se identifica por nombre de pila en la planilla. FHIR exige `identifier` estructurado (RUT).

---

### 2.2 Location (Domicilio)

```json
{
  "resourceType": "Location",
  "id": "DOM-0042",
  "status": "active",
  "name": "Domicilio PINCHEIRA - Agua Buena",
  "mode": "instance",
  "type": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode", "code": "PTRES", "display": "Patient's Residence"}]}],
  "address": {
    "text": "AGUA BUENA S/N X CAPE, SAN CARLOS",
    "city": "San Carlos",
    "state": "Ñuble"
  },
  "position": {
    "longitude": -71.919,
    "latitude": -36.414
  },
  "extension": [
    {
      "url": "urn:hodom-hsc:geocode-quality",
      "valueCode": "media"
    },
    {
      "url": "urn:hodom-hsc:gps-learned-position",
      "valueString": "-36.4138,-71.9185 (n=12)"
    },
    {
      "url": "urn:hodom-hsc:macro-zona",
      "valueCode": "rural_cerca"
    },
    {
      "url": "urn:hodom-hsc:distancia-base-km",
      "valueDecimal": 8.4
    },
    {
      "url": "urn:hodom-hsc:evaluacion-domicilio",
      "valueReference": {"reference": "QuestionnaireResponse/EVAL-DOM-0042"}
    }
  ]
}
```

**Extensiones propias:** `gps-learned-position` (centroide GPS aprendido), `macro-zona`, `distancia-base-km` no existen en FHIR base. Se modelan como extensiones del perfil HODOM-CL.

---

### 2.3 EpisodeOfCare (Episodio HODOM)

```json
{
  "resourceType": "EpisodeOfCare",
  "id": "EP-2026-0142",
  "status": "active",
  "type": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/episodeofcare-type", "code": "hacc", "display": "Home and Community Care"}]}],
  "patient": {"reference": "Patient/PAC-087"},
  "period": {
    "start": "2026-01-04",
    "end": "2026-02-15"
  },
  "diagnosis": [{
    "condition": {"reference": "Condition/COND-001"},
    "role": {"coding": [{"code": "AD", "display": "Admission diagnosis"}]}
  }],
  "team": [{"reference": "CareTeam/TEAM-EP-0142"}],
  "managingOrganization": {"reference": "Organization/HODOM-HSC"},
  "extension": [
    {
      "url": "urn:hodom-hsc:origen-derivacion",
      "valueCoding": {"code": "medicina", "display": "Servicio de Medicina"}
    },
    {
      "url": "urn:hodom-hsc:motivo-egreso",
      "valueCode": "alta"
    },
    {
      "url": "urn:hodom-hsc:consentimiento",
      "valueReference": {"reference": "Consent/CONS-EP-0142"}
    },
    {
      "url": "urn:hodom-hsc:domicilio-episodio",
      "valueReference": {"reference": "Location/DOM-0042"}
    }
  ]
}
```

---

### 2.4 Encounter (Visita Domiciliaria)

```json
{
  "resourceType": "Encounter",
  "id": "VIS-2026-01-31-B01-002",
  "status": "finished",
  "class": {
    "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
    "code": "HH",
    "display": "home health"
  },
  "type": [{"coding": [{"system": "urn:hodom-hsc:tipo-visita", "code": "visita-programada"}]}],
  "subject": {"reference": "Patient/PAC-087"},
  "episodeOfCare": [{"reference": "EpisodeOfCare/EP-2026-0142"}],
  "participant": [
    {"individual": {"reference": "Practitioner/PROF-BRAYAN"}, "type": [{"coding": [{"code": "PPRF"}]}]},
    {"individual": {"reference": "Practitioner/PROF-LAURA"}, "type": [{"coding": [{"code": "PPRF"}]}]}
  ],
  "period": {
    "start": "2026-01-31T08:36:00",
    "end": "2026-01-31T08:52:00"
  },
  "location": [{
    "location": {"reference": "Location/DOM-0042"},
    "status": "completed"
  }],
  "extension": [
    {
      "url": "urn:hodom-hsc:hora-programada",
      "valueTime": "08:00"
    },
    {
      "url": "urn:hodom-hsc:bloque-ruta",
      "valueString": "BLQ-2026-01-31-B01"
    },
    {
      "url": "urn:hodom-hsc:vehiculo",
      "valueReference": {"reference": "Device/VEH-PFFF57"}
    },
    {
      "url": "urn:hodom-hsc:gps-match",
      "extension": [
        {"url": "confianza", "valueCode": "alta"},
        {"url": "distancia-m", "valueDecimal": 142.3},
        {"url": "stop-id", "valueString": "STOP-00287"},
        {"url": "delta-min", "valueInteger": 36}
      ]
    }
  ]
}
```

**Clase `HH`:** FHIR define `HH` (home health) como clase de Encounter. Es exactamente lo que necesitamos.

**El match GPS** se modela como extensión compleja dentro del Encounter.

---

### 2.5 Procedure (Atención Profesional)

```json
{
  "resourceType": "Procedure",
  "id": "ATN-2026-01-31-001",
  "status": "completed",
  "code": {"coding": [{"system": "urn:hodom-hsc:prestaciones", "code": "KTM", "display": "Kinesiterapia motora"}]},
  "subject": {"reference": "Patient/PAC-087"},
  "encounter": {"reference": "Encounter/VIS-2026-01-31-B01-002"},
  "performedDateTime": "2026-01-31T08:36:00",
  "performer": [{"actor": {"reference": "Practitioner/PROF-BRAYAN"}}],
  "category": {"coding": [{"code": "rehabilitacion", "display": "Rehabilitación"}]}
}
```

**Separación Encounter/Procedure:** Un Encounter (visita) puede tener N Procedures (atenciones). Esto resuelve el problema de "KTM + FONO + ING ENF" = 1 visita, 3 procedimientos.

---

### 2.6 Device (Vehículo)

```json
{
  "resourceType": "Device",
  "id": "VEH-PFFF57",
  "status": "active",
  "type": {"coding": [{"system": "urn:hodom-hsc:vehiculo-tipo", "code": "camioneta"}]},
  "identifier": [
    {"system": "urn:cl:patente", "value": "PFFF57"},
    {"system": "urn:gps:device-id", "value": "PFFF57- RICARDO ALVIAL"}
  ],
  "deviceName": [{"name": "Ricardo Alvial", "type": "user-friendly-name"}],
  "extension": [
    {"url": "urn:hodom-hsc:km-limite-diario", "valueInteger": 100},
    {"url": "urn:hodom-hsc:disponibilidad", "valueCode": "lun-dom"}
  ]
}
```

---

### 2.7 CarePlan (Plan de Cuidados)

```json
{
  "resourceType": "CarePlan",
  "id": "CP-EP-0142",
  "status": "active",
  "intent": "plan",
  "subject": {"reference": "Patient/PAC-087"},
  "encounter": {"reference": "EpisodeOfCare/EP-2026-0142"},
  "period": {"start": "2026-01-04"},
  "careTeam": [{"reference": "CareTeam/TEAM-EP-0142"}],
  "activity": [
    {
      "detail": {
        "kind": "ServiceRequest",
        "code": {"coding": [{"code": "KTM", "display": "Kinesiterapia motora"}]},
        "status": "in-progress",
        "scheduledTiming": {"repeat": {"frequency": 1, "period": 1, "periodUnit": "d"}},
        "performer": [{"reference": "Practitioner/PROF-BRAYAN"}]
      }
    },
    {
      "detail": {
        "kind": "ServiceRequest",
        "code": {"coding": [{"code": "TTO-EV", "display": "Tratamiento endovenoso"}]},
        "status": "in-progress",
        "scheduledTiming": {"repeat": {"frequency": 1, "period": 1, "periodUnit": "d"}},
        "performer": [{"reference": "Practitioner/PROF-LAURA"}]
      }
    },
    {
      "detail": {
        "kind": "ServiceRequest",
        "code": {"coding": [{"code": "CA", "display": "Curación avanzada"}]},
        "status": "in-progress",
        "scheduledTiming": {"repeat": {"frequency": 3, "period": 1, "periodUnit": "wk"}}
      }
    }
  ]
}
```

---

### 2.8 Schedule + Slot (Programación diaria / Bloque de ruta)

```json
{
  "resourceType": "Schedule",
  "id": "SCHED-2026-01-31-VEH-PFFF57",
  "active": true,
  "actor": [
    {"reference": "Device/VEH-PFFF57"},
    {"reference": "Practitioner/PROF-BRAYAN"},
    {"reference": "Practitioner/PROF-LAURA"}
  ],
  "planningHorizon": {
    "start": "2026-01-31T08:00:00",
    "end": "2026-01-31T20:00:00"
  },
  "extension": [{
    "url": "urn:hodom-hsc:lider-bloque",
    "valueString": "ANDRES"
  }]
}
```

Cada visita programada se modela como **Appointment**:

```json
{
  "resourceType": "Appointment",
  "id": "APT-2026-01-31-B01-002",
  "status": "fulfilled",
  "start": "2026-01-31T08:00:00",
  "end": "2026-01-31T08:30:00",
  "participant": [
    {"actor": {"reference": "Patient/PAC-087"}, "status": "accepted"},
    {"actor": {"reference": "Practitioner/PROF-BRAYAN"}, "status": "accepted"},
    {"actor": {"reference": "Location/DOM-0042"}, "status": "accepted"},
    {"actor": {"reference": "Device/VEH-PFFF57"}, "status": "accepted"}
  ],
  "serviceType": [{"coding": [{"code": "KTM"}]}],
  "slot": [{"reference": "Slot/SLOT-2026-01-31-0800"}]
}
```

---

## 3. Perfil FHIR HODOM-CL: Extensiones Propias

| Extensión | URL | Aplica a | Tipo |
|---|---|---|---|
| Previsión de salud | `urn:minsal:prevision` | Patient | Coding |
| Origen de derivación | `urn:hodom-hsc:origen-derivacion` | EpisodeOfCare | Coding |
| Motivo de egreso | `urn:hodom-hsc:motivo-egreso` | EpisodeOfCare | code |
| Domicilio del episodio | `urn:hodom-hsc:domicilio-episodio` | EpisodeOfCare | Reference(Location) |
| Calidad geocoding | `urn:hodom-hsc:geocode-quality` | Location | code |
| Posición GPS aprendida | `urn:hodom-hsc:gps-learned-position` | Location | string |
| Macro-zona | `urn:hodom-hsc:macro-zona` | Location | code |
| Distancia a base | `urn:hodom-hsc:distancia-base-km` | Location | decimal |
| Evaluación domicilio | `urn:hodom-hsc:evaluacion-domicilio` | Location | Reference(QR) |
| Hora programada | `urn:hodom-hsc:hora-programada` | Encounter | time |
| Bloque de ruta | `urn:hodom-hsc:bloque-ruta` | Encounter | string |
| Vehículo asignado | `urn:hodom-hsc:vehiculo` | Encounter | Reference(Device) |
| Match GPS | `urn:hodom-hsc:gps-match` | Encounter | complex |
| Km límite diario | `urn:hodom-hsc:km-limite-diario` | Device | integer |
| Disponibilidad | `urn:hodom-hsc:disponibilidad` | Device | code |
| Líder de bloque | `urn:hodom-hsc:lider-bloque` | Schedule | string |

---

## 4. ValueSets Propios

### 4.1 Prestaciones HODOM (`urn:hodom-hsc:prestaciones`)

| Código | Display | Profesión | Categoría |
|---|---|---|---|
| KTM | Kinesiterapia motora | kinesiologo | rehabilitacion |
| KTR | Kinesiterapia respiratoria | kinesiologo | rehabilitacion |
| TTO-EV | Tratamiento endovenoso | enfermera | tratamiento |
| CA | Curación avanzada | enfermera | procedimiento |
| CS | Curación simple | enfermera | procedimiento |
| NTP | Nutrición parenteral total | enfermera | tratamiento |
| FONO | Fonoaudiología | fonoaudiologo | rehabilitacion |
| VM-ING | Visita médica de ingreso | medico | evaluacion |
| VM-EGR | Visita médica de egreso | medico | evaluacion |
| VM-EV | Visita médica de evaluación | medico | evaluacion |
| ING-ENF | Ingreso de enfermería | enfermera | evaluacion |
| ING-KINE | Ingreso kinesiología | kinesiologo | evaluacion |
| ING-FONO | Ingreso fonoaudiología | fonoaudiologo | evaluacion |
| EXAM | Toma de exámenes | enfermera/tens | procedimiento |
| SF | Sonda Foley (instalación/retiro) | enfermera | procedimiento |
| SC | Subcutáneo (tratamiento) | enfermera | tratamiento |

### 4.2 Macro-zona (`urn:hodom-hsc:macro-zona`)

| Código | Display | Criterio |
|---|---|---|
| urbano | Urbano San Carlos | <3 km de base |
| periurbano | Periurbano | 3-10 km |
| rural_cerca | Rural cercano | 10-18 km |
| rural_lejos | Rural lejano | >18 km |

### 4.3 Origen derivación (`urn:hodom-hsc:origen-derivacion`)

| Código | Display | % legacy |
|---|---|---|
| medicina | Servicio de Medicina | 42.7% |
| urgencia | Servicio de Urgencia | 32.0% |
| traumatologia | Traumatología | 9.4% |
| cirugia | Cirugía | 7.6% |
| otro | Otro servicio | 8.3% |

### 4.4 Match GPS confianza (`urn:hodom-hsc:gps-match-confianza`)

| Código | Display | Criterio |
|---|---|---|
| alta | Alta confianza | <200m |
| media | Media confianza | 200-600m |
| baja | Baja confianza | 600-2500m |
| tentativa | Tentativa | <5km, mejor candidato |
| learned | GPS aprendido | Centroide de visitas previas |
| sin_match | Sin match | Sin parada GPS compatible |

---

## 5. Diagrama de Recursos FHIR

```
                    ┌──────────────┐
                    │   Patient    │
                    │  (PAC-087)   │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
       ┌────────────┐ ┌──────────┐ ┌──────────────┐
       │  Location   │ │ Consent  │ │EpisodeOfCare │
       │ (Domicilio) │ │          │ │  (Episodio)  │
       │  DOM-0042   │ │          │ │  EP-2026-142 │
       └──────┬──────┘ └──────────┘ └──────┬───────┘
              │                             │
              │         ┌───────────────────┼──────────────┐
              │         │                   │              │
              │         ▼                   ▼              ▼
              │  ┌────────────┐     ┌────────────┐  ┌──────────┐
              │  │  CarePlan   │     │  CareTeam   │  │Condition │
              │  │(Plan cuid.) │     │  (Equipo)   │  │(Dx CIE10)│
              │  └──────┬─────┘     └────────────┘  └──────────┘
              │         │
              │         ▼ (activities → ServiceRequest)
              │  ┌────────────────┐
              └─▸│   Encounter    │◂── Appointment (programación)
                 │ class="HH"    │
                 │(Visita domic.) │
                 └──────┬────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
           ▼            ▼            ▼
    ┌────────────┐ ┌──────────┐ ┌──────────┐
    │ Procedure   │ │Procedure │ │Procedure │
    │ (KTM)      │ │(TTO EV)  │ │ (FONO)   │
    └──────┬─────┘ └────┬─────┘ └────┬─────┘
           │            │            │
           ▼            ▼            ▼
    ┌────────────┐ ┌──────────┐ ┌──────────┐
    │Practitioner│ │Practition│ │Practition│
    │ (BRAYAN)   │ │ (LAURA)  │ │(M.JOSÉ)  │
    └────────────┘ └──────────┘ └──────────┘

    ┌────────────┐      ┌────────────┐
    │   Device   │─────▸│  Schedule  │──▸ Slot ──▸ Appointment
    │(VEH-PFFF57)│      │(Ruta diaria)│
    └────────────┘      └────────────┘
```

---

## 6. Mapeo Operación Actual → FHIR

| Hoy (planilla Excel) | FHIR R4 |
|---|---|
| Fila de planilla con "BRAYAN, KTM, 08:00, LUIS PINCHEIRA" | Appointment + ServiceRequest |
| Visita realizada (GPS confirma parada) | Encounter (status=`finished`) + Procedure |
| Columna "ANDRES" con lista de pacientes | Schedule (actor=Device+Practitioners) |
| Hoja "31.01" del Excel | Conjunto de Appointments para ese día |
| Consolidado "enfermero: 6, kine: 9" | Agregación de Procedures por profesión |
| Consentimiento firmado en papel | Consent (status=`active`, scope=`treatment`) |
| Epicrisis PDF | DocumentReference (type=`discharge-summary`) |
| GPS stop matcheado | Encounter.extension[gps-match] |

---

## 7. Beneficios del Modelo FHIR

1. **Interoperabilidad nativa** con SIDRA, SIGGES, RCE y cualquier sistema MINSAL que adopte FHIR
2. **Separación Encounter/Procedure** resuelve el problema de "1 visita = N prestaciones"
3. **EpisodeOfCare** como eje longitudinal resuelve la falta de ID de episodio
4. **Location con coordenadas** y extensión GPS-learned resuelve el geocoding rural
5. **Device para vehículos** permite vincular telemetría GPS directamente al modelo clínico
6. **Schedule/Appointment** reemplaza la planilla Excel con un modelo programable y auditable
7. **ValueSets normalizados** reemplazan las >120 variantes de texto libre de tipo_visita

---

*Modelo de dominio FHIR R4 construido a partir de 7.586 eventos GPS, 1.573 visitas, 2.029 atenciones + normativa HD vigente.*
*kora/salubrista-hah — 2026-03-25*
