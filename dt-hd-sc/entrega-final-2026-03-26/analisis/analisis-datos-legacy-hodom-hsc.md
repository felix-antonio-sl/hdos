# Análisis de Datos Legacy — HODOM HSC
## 5.186 archivos procesados | Paquete documental del Director Técnico saliente
### Fecha de análisis: 24 marzo 2026

---

## 1. INVENTARIO DEL PAQUETE

| Carpeta | Archivos | Contenido |
|---------|----------|-----------|
| **Formulario sin título / DAU-Epicrisis** | 1.942 | PDFs de epicrisis individuales por paciente (nombrados por nombre del paciente) |
| **Epicrisis Enfermería** | 288 | Epicrisis de enfermería (PDF/DOCX) |
| **Entrega Turno** | 92 | Informes de entrega de turno (DOCX) — Ago 2025 a Mar 2026 |
| **Registro Diario Pacientes** | 82 | Registros diarios de pacientes activos |
| **Epicrisis Antiguas** | 47 | Epicrisis previas (2023-2024) |
| **Rutas** | 27 | Planillas de visitas mensuales (XLSX) — 2024 |
| **Educaciones** | 20 | Material educativo para pacientes (PDF folletos) |
| **Estadísticas por profesional** | 19 | Planillas individuales por enfermera/TENS — Jun-Sep 2023 |
| **Curaciones** | 17 | Registros fotográficos de curaciones avanzadas |
| **HODOM 2023** | 15 | Documentación campaña 2023 |
| **Fonoaudiología** | 3 | Registros fonoaudiológicos |
| **Archivos raíz (Excel)** | 12 | Formularios de ingreso, programación, satisfacción |
| **Total** | **2.572** (sin __MACOSX) | |

### Base de datos principal: `2025 FORMULARIO HODOM.xlsx`
- **1.795 registros de pacientes** (después de limpieza de filas vacías)
- **26 columnas**: datos demográficos, diagnóstico, servicio origen, CESFAM, prestaciones, COVID, aislamiento, gestor responsable
- **Período cubierto**: 2023-2025 (acumulado)

---

## 2. PERFIL EPIDEMIOLÓGICO DE LA POBLACIÓN HODOM

### 2.1 Demografía

| Variable | Valor |
|----------|-------|
| N total registros | 1.795 |
| Edad promedio | **70.1 años** |
| Mujeres | 977 (54.4%) |
| Hombres | 808 (45.0%) |
| Otros | 2 (0.1%) |
| Sin dato | 8 (0.4%) |

**Distribución etaria:**

| Grupo | N | % | Insight |
|-------|---|---|---------|
| <40 años | 125 | 7.0% | Pacientes jóvenes con patología aguda simple |
| 40-59 | 283 | 15.8% | Adultos con comorbilidades incipientes |
| 60-69 | 326 | 18.2% | Adultos mayores jóvenes |
| **70-79** | **433** | **24.2%** | **Grupo más grande por década** |
| **80-89** | **480** | **26.8%** | **Mayor grupo — fragilidad alta** |
| ≥90 | 143 | 8.0% | Nonagenarios — máxima fragilidad |

**Insight clave:** El 59% de los pacientes tiene ≥70 años y el 35% tiene ≥80. Esta es exactamente la población que más se beneficia del modelo HaH según la evidencia (Shepperd 2022: reducción de delirium 62%, reducción de institucionalización 42% en ≥65 años).

### 2.2 Previsión

| Previsión | N | % |
|-----------|---|---|
| FONASA B | 1.408 | 78.4% |
| FONASA A | 166 | 9.2% |
| FONASA C | 92 | 5.1% |
| FONASA D | 80 | 4.5% |
| PRAIS | 40 | 2.2% |
| Sin dato | 9 | 0.5% |

**Insight:** 87.6% FONASA A+B → población predominantemente de bajos ingresos. Esto tiene implicancias para: acceso a medicamentos, condiciones de vivienda, disponibilidad de cuidador, alfabetización digital. Cualquier sistema web debe considerar esta realidad socioeconómica.

### 2.3 CESFAM de origen

| CESFAM | N | % |
|--------|---|---|
| Teresa Baldecchi (San Carlos) | 556 | 31.0% |
| Otros / fuera de red | 527 | 29.4% |
| José Durán Trujillo (San Carlos) | 273 | 15.2% |
| Ñiquén | 167 | 9.3% |
| San Nicolás | 89 | 5.0% |
| Sin dato / irregulares | ~183 | 10.2% |

**Insights:**
- **46.2% proviene de los 2 CESFAM de San Carlos** → Focalizar enlace APS aquí primero
- **29.4% marcado como "Otro"** → Pacientes de comunas fuera de la red que consultan en UEA HSC (Maule, Chillán, comunas costeras). Confirma lo reportado en el proyecto BIP.
- **Ñiquén y San Nicolás** juntos = 14.3% → Cobertura territorial funcional fuera de San Carlos urbano
- **10% con dato irregular** → Problema de calidad de registro

---

## 3. PERFIL CLÍNICO

### 3.1 Diagnósticos principales (top 20)

| Diagnóstico | N | % |
|-------------|---|---|
| **ITU / Infección urinaria** | 219 (ITU+IVU+PNA) | **12.2%** |
| **Neumonía / BNM** | 198 (NAC+BNM+NAC bacteriana) | **11.0%** |
| **ACV / Infarto cerebral** | 62 (ACV+AVE+infarto cerebral) | **3.5%** |
| Insuficiencia respiratoria aguda | 34 | 1.9% |
| Fractura cuello fémur / pertrocanteriana | 28 | 1.6% |
| Celulitis | 9 | 0.5% |
| Insuficiencia cardíaca | 10 | 0.6% |
| DM con complicación circulatoria periférica | 9 | 0.5% |
| Bronquitis aguda | 11 | 0.6% |

**Insights:**
- **ITU + Neumonía = 23.2% de todos los ingresos** → Son las 2 patologías dominantes, ambas con protocolo de ATB EV c/12-24h. Alta estandarización posible.
- **ACV es el 3er diagnóstico** → Rehabilitación motora/deglutoria intensiva domiciliaria. Requiere kinesiología + fonoaudiología diaria.
- **Fracturas de fémur** representan un volumen significativo → Son post-quirúrgicos que requieren rehabilitación motora. 
- **Insuficiencia respiratoria aguda aparece como diagnóstico** — esto requiere revisión: ¿son pacientes que realmente se manejan en domicilio con IRA? ¿O es el diagnóstico de ingreso hospitalario y luego se estabilizan?
- **La cartera real es más amplia que la protocolar** — el protocolo PRO-002 lista 7-8 patologías, pero los datos muestran >50 diagnósticos distintos

### 3.2 Servicio de origen de la solicitud

| Servicio | N | % |
|----------|---|---|
| **Medicina** | 766 | **42.7%** |
| **Urgencia (UE)** | 574 | **32.0%** |
| Traumatología | 168 | 9.4% |
| Cirugía | 137 | 7.6% |
| UTI | 41 | 2.3% |
| Ginecología | 21 | 1.2% |
| CMI | 17 | 0.9% |
| CAE | 17 | 0.9% |
| Pediatría | 12 | 0.7% |
| UCI | 6 | 0.3% |
| Otros | 36 | 2.0% |

**Insights:**
- **Medicina + UE = 74.7%** de todas las derivaciones → Estos 2 servicios son el motor de HODOM
- **Urgencia como segundo mayor derivador (32%)** confirma que HODOM está sirviendo como válvula de descompresión de la UEA
- **Traumatología 9.4%** → Fracturados estables con rehabilitación domiciliaria, un volumen no despreciable
- **UTI/UCI derivan 2.6%** → Pacientes de mayor complejidad que egresan a HODOM como step-down. Esto no está en el protocolo PRO-002 actual
- **12 pacientes pediátricos** registrados → El protocolo dice "adultos de 15 años y en casos especiales pediátricos" — hay uso real pediátrico

### 3.3 Prestaciones solicitadas (top 10)

| Prestación | N | % |
|-----------|---|---|
| Administración tratamiento EV | 340 | 18.9% |
| Tratamiento EV + KTR | 170 | 9.5% |
| Exámenes sangre + tratamiento EV | 118 | 6.6% |
| KTM + evaluación fonoaudióloga | 83 | 4.6% |
| Curación simple + KTM | 80 | 4.5% |
| KTM sola | 64 | 3.6% |
| Evaluación médica + exámenes + tto EV | 62 | 3.5% |
| KTR sola | 58 | 3.2% |
| Curación avanzada | 55 | 3.1% |
| Curación avanzada + KTM | 52 | 2.9% |

**Insights:**
- **Tratamiento EV es la prestación dominante** (presente en ~45% de las solicitudes en alguna combinación) → Es el core operativo de HODOM
- **Kinesiología (motora + respiratoria)** aparece en ~40% de las prestaciones → Confirma que los kinesiólogos son esenciales, no complementarios
- **Fonoaudiología** aparece frecuentemente asociada a KTM → Pacientes post-ACV con doble necesidad rehabilitadora
- **Curaciones avanzadas** = ~10% → Requiere enfermería especializada y stock de insumos de curación

---

## 4. GESTIÓN OPERATIVA

### 4.1 Gestoras (quién ingresa pacientes al sistema)

| Gestora | N | % |
|---------|---|---|
| Melissa Sepúlveda | 348 | 19.4% |
| Doris González | 242 | 13.5% |
| Helen López | 208 | 11.6% |
| Pía Vásquez M | 226 | 12.6% |
| Melissa Rivera | 255 | 14.2% |
| Camila Bustamante | 195 | 10.9% |
| Otras | ~321 | 17.9% |

**Insight:** 6 gestoras concentran el 82% de los ingresos. Son las enfermeras operativas que hacen screening, evaluación y registro. Melissa Sepúlveda (coordinadora) es la gestora más activa.

### 4.2 COVID-19 y aislamiento

| COVID | N | % |
|-------|---|---|
| No | 1.274 | 71.0% |
| Sin examen | 497 | 27.7% |
| Sí | 17 | 0.9% |

| Aislamiento | N | Principales |
|-------------|---|------------|
| No | 1.691 | 94.2% |
| Sí (diversos) | ~100 | Contacto, protector, Influenza, Clostridium, COVID, BLEE |

**Insight:** COVID ya es marginal (0.9%). Los aislamientos relevantes son por microorganismos multirresistentes (Clostridium, BLEE, Klebsiella) y virus respiratorios estacionales (Influenza). Esto refuerza la necesidad de protocolos de IAAS domiciliaria.

### 4.3 Documentación de entrega de turno

- **92 documentos de entrega de turno** (Ago 2025 a Mar 2026)
- Formato: DOCX con lista de pacientes activos, estado, indicaciones pendientes
- **Frecuencia:** cada 2 días (cuarto turno largo-largo-libre-libre) → consistente con el modelo

### 4.4 Planillas de rutas (2024)

- **12 archivos mensuales** (Ene-Dic 2024) con programación de visitas por día
- Formato: XLSX con columnas fecha, hora, médico, fono, kine, enfermera, TENS, paciente
- **Insight de febrero 2026:** Planillas diarias con 15-25 pacientes/día, rutas de 3 móviles, asignación de profesionales por visita

---

## 5. CALIDAD DEL REGISTRO — PROBLEMAS DETECTADOS

| Problema | Evidencia | Impacto | Recomendación |
|----------|-----------|---------|---------------|
| **Nombres de archivos inconsistentes** | PDFs de epicrisis nombrados manualmente, algunos con fecha, otros sin | Difícil búsqueda retrospectiva | Sistema web con nomenclatura automática |
| **Datos faltantes en formularios** | 10% CESFAM vacío, edades con formato variable, RUT con/sin puntos | Indicadores imprecisos | Validación en formulario digital |
| **Campo "Origen solicitud" vacío** en versiones antiguas | 1.795 registros con "ND" en versión anterior | Pérdida de trazabilidad | Campo obligatorio en sistema web |
| **Duplicación de bases de datos** | `2025 FORMULARIO HODOM.xlsx` (1.795 reg) vs `Copia de FORMULARIO HODOM HSC.xlsx` (1.225 reg) vs `resp antiguo.xlsx` (48 reg) → Versiones superpuestas | Riesgo de inconsistencia | Base de datos única (sistema web) |
| **Sin identificador único de episodio** | No hay ID de ingreso/egreso. Un paciente puede tener múltiples registros | No se puede calcular reingresos con precisión | ID de episodio en sistema web |
| **Diagnósticos sin codificación estándar** | Texto libre: "ITU", "INFECCION DE VIAS URINARIAS", "IVU" son el mismo diagnóstico | Indicadores diagnósticos imprecisos | Codificación CIE-10 en sistema web |
| **Archivos sueltos en carpetas** | 1.942 PDFs de epicrisis como archivos individuales sin estructura de carpetas por fecha/paciente | Repositorio caótico | Repositorio digital con estructura automática |

---

## 6. INSIGHTS ESTRATÉGICOS PARA EL NUEVO DIRECTOR TÉCNICO

### 🔴 Hallazgos críticos

1. **La unidad atiende una población significativamente más frágil de lo que sugiere el protocolo.** Edad promedio 70.1 años, 35% ≥80 años, 87.6% FONASA A+B. Esto es hospitalización domiciliaria geriátrica de facto.

2. **La cartera real excede la cartera protocolar.** Se atienden >50 diagnósticos diferentes, incluyendo pacientes post-UTI/UCI, fracturas, IRA, y 12 pediátricos — ninguno de estos está formalmente protocolizado.

3. **El 29.4% de pacientes viene de "Otro" CESFAM** — son pacientes de fuera de la red que consultan espontáneamente en la UEA. HODOM los atiende pero no tiene articulación formal con sus redes de origen para el seguimiento post-alta.

4. **No existe base de datos unificada.** Hay al menos 3 versiones del formulario Excel superpuestas, 1.942 PDFs de epicrisis sin estructura, y documentos de entrega de turno en DOCX individuales. La información existe pero es frágil y difícil de consultar.

### 🟡 Hallazgos importantes

5. **Medicina (42.7%) y Urgencia (32%) son los motores de HODOM.** La estrategia de captación debe focalizarse en estos 2 servicios. La relación con los jefes de servicio de Medicina y UEA es crítica.

6. **Tratamiento EV es el procedimiento core (45% de prestaciones).** La logística de insumos EV (antibióticos, soluciones, bajadas, catéteres) debe ser impecable.

7. **La rehabilitación (KTM+KTR+Fono) está en ~40% de las prestaciones.** Los kinesiólogos y la fonoaudióloga no son "complemento" — son co-core del modelo. El plan de capacitación debe incluirlos como protagonistas.

8. **6 gestoras concentran 82% de los ingresos.** El conocimiento operativo está en estas personas. El DT debe proteger su continuidad y formalizar su expertise en protocolos.

### 🟢 Oportunidades

9. **El enlace APS está maduro para expandirse.** 46.2% de pacientes viene de los 2 CESFAM de San Carlos. Si se formaliza la derivación directa (admission avoidance), el volumen puede crecer y la presión sobre la UEA disminuir.

10. **Los datos existen para fundamentar todo.** Aunque están dispersos, los 1.795 registros permiten construir una línea base robusta de indicadores. El primer informe del DT puede ser demoledor en evidencia.

---

## 7. ACCIONES INMEDIATAS RECOMENDADAS

| Acción | Plazo | Fundamento |
|--------|-------|------------|
| Consolidar las 3 bases Excel en una sola base limpia | Semana 1-2 | Eliminar duplicados, estandarizar diagnósticos, calcular indicadores reales |
| Calcular indicadores 2025 con datos reales | Semana 2 | Tasa de reingresos precisa, estada promedio, índice ocupacional |
| Cruzar diagnósticos reales vs cartera protocolar | Semana 2 | Identificar patologías atendidas sin protocolo formal |
| Mapear los 29.4% de "Otro CESFAM" | Mes 1 | Entender de dónde vienen y qué pasa con su seguimiento |
| Estandarizar nomenclatura de archivos | Mes 1 | Antes de que crezca más el caos |
| Migrar a sistema web | Mes 2-3 | Todo lo anterior se resuelve con el sistema |
