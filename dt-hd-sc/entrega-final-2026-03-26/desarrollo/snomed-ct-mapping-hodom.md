# Integración SNOMED CT al Modelo FHIR HODOM HSC

**Sistema:** `http://snomed.info/sct`
**Licencia Chile:** Disponible vía MINSAL (miembro SNOMED International)

---

## 1. Dónde Aplica SNOMED CT en el Modelo

| Recurso FHIR | Atributo | Sistema terminológico |
|---|---|---|
| **Condition** | `code` | SNOMED CT (diagnósticos) |
| **Procedure** | `code` | SNOMED CT (procedimientos/prestaciones) |
| **Encounter** | `type`, `reasonCode` | SNOMED CT |
| **Observation** | `code` | SNOMED CT + LOINC (signos vitales) |
| **ServiceRequest** | `code` | SNOMED CT (prestación solicitada) |
| **CarePlan.activity** | `detail.code` | SNOMED CT (actividad planificada) |
| **AllergyIntolerance** | `code` | SNOMED CT |
| **Location** | `type` | SNOMED CT (tipo de lugar) |
| **Encounter** | `class` | v3-ActCode (`HH`) — no SNOMED |
| **Patient** | identifiers, demographics | No aplica SNOMED |

---

## 2. Catálogo de Prestaciones HODOM → SNOMED CT

### 2.1 Procedimientos de Rehabilitación

| Código local | Prestación | SNOMED CT Code | SNOMED CT Display | Jerarquía |
|---|---|---|---|---|
| KTM | Kinesiterapia motora | **229070002** | Joint mobility exercise (procedure) | Procedure → Physical therapy |
| KTR | Kinesiterapia respiratoria | **34431008** | Physiotherapy chest therapy (procedure) | Procedure → Respiratory therapy |
| FONO | Fonoaudiología | **311555007** | Speech and language therapy (regime/therapy) | Procedure → Speech therapy |
| ING-KINE | Ingreso kinesiología | **410155007** | Occupational therapy assessment (procedure) | — adaptado para kine |
| ING-FONO | Ingreso fonoaudiología | **386053000** | Evaluation procedure (procedure) | Con qualifier FONO |

### 2.2 Procedimientos de Enfermería / Tratamiento

| Código local | Prestación | SNOMED CT Code | SNOMED CT Display |
|---|---|---|---|
| TTO-EV | Tratamiento endovenoso | **18629005** | Administration of drug or medicament (procedure) + **255560000** (intravenous) |
| CA | Curación avanzada | **225358003** | Wound care (procedure) |
| CS | Curación simple | **225358003** | Wound care (procedure) + qualifier simple |
| NTP | Nutrición parenteral | **25156005** | Parenteral nutrition (procedure) |
| EXAM | Toma de exámenes | **15220000** | Laboratory test (procedure) |
| SF | Sonda Foley | **45253006** | Insertion of urinary catheter (procedure) |
| SC | Subcutáneo (tratamiento) | **18629005** | Administration of drug or medicament + **263887005** (subcutaneous) |
| ING-ENF | Ingreso enfermería | **386053000** | Evaluation procedure (procedure) |

### 2.3 Procedimientos Médicos

| Código local | Prestación | SNOMED CT Code | SNOMED CT Display |
|---|---|---|---|
| VM-ING | Visita médica ingreso | **439708006** | Home visit (procedure) + **32485007** (admission) |
| VM-EGR | Visita médica egreso | **439708006** | Home visit (procedure) + **58000006** (discharge) |
| VM-EV | Visita médica evaluación | **439708006** | Home visit (procedure) + **386053000** (evaluation) |

### 2.4 Contexto de Atención Domiciliaria

| Concepto | SNOMED CT Code | Display |
|---|---|---|
| Hospitalización domiciliaria | **305336008** | Admission to hospital-at-home (procedure) |
| Alta de HD | **306206005** | Referral to hospital-at-home service (procedure) |
| Visita domiciliaria | **439708006** | Home visit (procedure) |
| Atención en domicilio | **385767004** | Home health care (regime/therapy) |
| Domicilio del paciente | **264362003** | Home (environment) |
| Cuidador informal | **133932002** | Caregiver (person) |

---

## 3. Diagnósticos Frecuentes → SNOMED CT + CIE-10

Mapeados desde los hallazgos legacy (1.795 registros):

| Diagnóstico HODOM | CIE-10 | SNOMED CT Code | SNOMED CT Display |
|---|---|---|---|
| ITU / IVU | N39.0 | **68566005** | Urinary tract infectious disease |
| Neumonía | J18.9 | **233604007** | Pneumonia |
| Bronconeumonía | J18.0 | **396286009** | Bronchopneumonia |
| ACV / Infarto cerebral | I63.9 | **230690007** | Cerebrovascular accident |
| Celulitis | L03.9 | **128045006** | Cellulitis |
| Fractura de cadera | S72.0 | **5913000** | Fracture of neck of femur |
| EPOC reagudizada | J44.1 | **195951007** | Acute exacerbation of COPD |
| ICC descompensada | I50.9 | **42343007** | Congestive heart failure |
| Pie diabético | E11.5 | **280137006** | Diabetic foot |
| Herida quirúrgica | T81.0 | **225552003** | Wound care after surgery |

**Doble codificación:** FHIR permite `coding` múltiple. Cada Condition lleva CIE-10 (requerido por DEIS) + SNOMED CT (semántica clínica rica):

```json
{
  "resourceType": "Condition",
  "code": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "68566005",
        "display": "Urinary tract infectious disease"
      },
      {
        "system": "http://hl7.org/fhir/sid/icd-10",
        "code": "N39.0",
        "display": "Infección de vías urinarias, sitio no especificado"
      }
    ],
    "text": "ITU complicada"
  }
}
```

---

## 4. Observaciones Clínicas → SNOMED CT + LOINC

| Observación | LOINC Code | SNOMED CT Code | Unidad |
|---|---|---|---|
| Presión arterial sistólica | 8480-6 | **271649006** | mmHg |
| Presión arterial diastólica | 8462-4 | **271650006** | mmHg |
| Frecuencia cardíaca | 8867-4 | **364075005** | /min |
| Frecuencia respiratoria | 9279-1 | **86290005** | /min |
| Temperatura | 8310-5 | **386725007** | °C |
| Saturación O2 | 2708-6 | **431314004** | % |
| NEWS2 Score | — | **1104051000000101** | score |
| Glasgow | 9269-2 | **248241002** | score |
| EVA Dolor | 38208-5 | **225908003** | 0-10 |
| Peso | 29463-7 | **27113001** | kg |
| Glicemia capilar | 2339-0 | **33747003** | mg/dL |

**FHIR usa LOINC para observaciones cuantitativas y SNOMED CT para hallazgos clínicos.** Ambos coexisten.

---

## 5. Encuentro Domiciliario Enriquecido con SNOMED CT

```json
{
  "resourceType": "Encounter",
  "class": {"code": "HH", "display": "home health"},
  "type": [{
    "coding": [{
      "system": "http://snomed.info/sct",
      "code": "439708006",
      "display": "Home visit"
    }]
  }],
  "reasonCode": [{
    "coding": [{
      "system": "http://snomed.info/sct",
      "code": "385767004",
      "display": "Home health care"
    }]
  }],
  "location": [{
    "location": {"reference": "Location/DOM-0042"},
    "physicalType": {
      "coding": [{
        "system": "http://snomed.info/sct",
        "code": "264362003",
        "display": "Home environment"
      }]
    }
  }]
}
```

---

## 6. Procedure Enriquecido con SNOMED CT

```json
{
  "resourceType": "Procedure",
  "code": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "225358003",
        "display": "Wound care"
      },
      {
        "system": "urn:hodom-hsc:prestaciones",
        "code": "CA",
        "display": "Curación avanzada"
      }
    ]
  },
  "category": {
    "coding": [{
      "system": "http://snomed.info/sct",
      "code": "387713003",
      "display": "Surgical procedure"
    }]
  },
  "bodySite": [{
    "coding": [{
      "system": "http://snomed.info/sct",
      "code": "61685007",
      "display": "Lower limb structure"
    }]
  }]
}
```

**Ventaja SNOMED CT:** permite registrar **sitio corporal** (`bodySite`), lo que el texto libre "CA pierna izquierda" no puede hacer de forma estructurada.

---

## 7. Beneficios de SNOMED CT para HODOM

| Dimensión | Sin SNOMED | Con SNOMED |
|---|---|---|
| **Diagnósticos** | Texto libre ("ITU complicada") | Código unívoco + jerarquía clínica |
| **Prestaciones** | >120 variantes texto | 16 códigos locales + SNOMED para interoperabilidad |
| **Búsqueda clínica** | Por texto | Por concepto (todos los "wound care" = 1 query) |
| **Sitio corporal** | No registrado | `bodySite` codificado |
| **Severidad** | No registrada | Qualifiers SNOMED |
| **Agregación** | Manual | Automática por jerarquía SNOMED |
| **Interoperabilidad** | Solo local | Internacional (>50 países) |
| **Reportes DEIS** | CIE-10 manual | SNOMED → CIE-10 automático (mapa oficial) |
| **Investigación** | Imposible | Cohortes por concepto clínico |

---

## 8. Estrategia de Implementación

### Fase 1 — Inmediata (sin SNOMED)
- Usar códigos locales (`urn:hodom-hsc:prestaciones`) + CIE-10 para diagnósticos
- El sistema funciona sin SNOMED

### Fase 2 — Corto plazo
- Agregar SNOMED CT como `coding` adicional en Procedure y Condition
- Doble codificación: local + SNOMED conviven
- El equipo no necesita saber códigos SNOMED — el sistema los asigna

### Fase 3 — Madurez
- SNOMED CT como terminología primaria
- Mapeo automático SNOMED → CIE-10 para reportes DEIS
- `bodySite`, severidad, lateralidad como datos estructurados
- Búsquedas y dashboards por jerarquía SNOMED

**El equipo clínico nunca escribe un código SNOMED.** El sistema traduce automáticamente la selección de prestación/diagnóstico al código SNOMED correspondiente.

---

*Mapeo SNOMED CT construido para las prestaciones, diagnósticos y observaciones reales del HODOM HSC (evidencia operacional Ene-Mar 2026).*
*kora/salubrista-hah — 2026-03-25*
