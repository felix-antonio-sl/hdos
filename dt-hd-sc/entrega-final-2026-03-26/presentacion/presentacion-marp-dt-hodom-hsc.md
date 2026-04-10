---
marp: true
theme: default
paginate: true
backgroundColor: #fff
style: |
  section {
    font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    font-size: 24px;
  }
  h1 {
    color: #1a5276;
    font-size: 36px;
  }
  h2 {
    color: #2471a3;
    font-size: 30px;
  }
  h3 {
    color: #5d6d7e;
  }
  table {
    font-size: 18px;
    width: 100%;
  }
  th {
    background-color: #1a5276;
    color: white;
  }
  blockquote {
    border-left: 4px solid #2471a3;
    padding: 10px 20px;
    background: #eaf2f8;
    font-style: italic;
  }
  .red { color: #e74c3c; font-weight: bold; }
  .green { color: #27ae60; font-weight: bold; }
  .orange { color: #e67e22; font-weight: bold; }
  .blue { color: #2471a3; font-weight: bold; }
  .small { font-size: 16px; }
  .center { text-align: center; }
  .highlight {
    background: #fdebd0;
    padding: 15px;
    border-radius: 8px;
    border-left: 5px solid #e67e22;
  }
  .metric-box {
    display: inline-block;
    background: #eaf2f8;
    padding: 10px 20px;
    border-radius: 8px;
    margin: 5px;
    text-align: center;
    font-weight: bold;
  }
---

<!-- _class: center -->
<!-- _paginate: false -->

# HODOM HSC

## Consolidar lo que funciona · Cerrar brechas · Proyectar el siguiente nivel

### Primera reunión de trabajo con el equipo
**Dirección Técnica · Hospital de San Carlos**
**Marzo 2026**

---

# Para qué estamos reunidos hoy

- **Reconocer** lo que el equipo ya ha logrado
- **Mostrar** cómo está funcionando hoy la unidad, con honestidad
- **Ordenar** las brechas más relevantes
- **Alinear** prioridades inmediatas
- **Abrir** una conversación de mejora *con* ustedes

---

# Lo que este equipo ya ha conseguido

<div class="center">

| | 2023 | 2024 | 2025 | **Total** |
|---|:---:|:---:|:---:|:---:|
| **Personas atendidas** | 307 | 1.077 | 751 | **2.135** |
| **Días persona** | 4.037 | 6.508 | 5.480 | **16.025** |
| **Visitas domiciliarias** | 5.148 | 11.562 | 9.428 | **26.138** |
| **Fallecidos no esperados** | 0 | 0 | 0 | **0** |
| **Reingresos** | 16 | 28 | 28 | 72 |

</div>

> **Esto no es una idea en el papel. Es una unidad que ya demostró valor clínico y humano.**

---

# Por qué HODOM importa para el hospital

## Oportunidad de hospitalización ≤12h adulto

<div class="center">

| 2019 | 2022 | 2023 | 2024 | 2025 |
|:---:|:---:|:---:|:---:|:---:|
| <span class="green">96,8%</span> | 69,5% | 61,0% | 54,9% | <span class="red">40,6%</span> |

</div>

## Índice ocupacional 2025

| Medicina | Cirugía | Traumatología | Área quirúrgica | Hospital |
|:---:|:---:|:---:|:---:|:---:|
| **97,5** | **96,0** | **97,9** | **98,1** | 86,6 |

> **HODOM no es un accesorio. Es parte de la respuesta hospitalaria.**

---

# Quiénes son nuestros pacientes

<div class="center">

| Variable | Valor |
|---|---|
| Edad promedio | **70,1 años** |
| ≥ 80 años | **35%** |
| Mujeres | 54,4% |
| FONASA A+B | **87,6%** |

</div>

**Diagnósticos dominantes:** ITU/IVU (12,2%) · Neumonía/BNM (11,0%) · ACV (3,5%)
**Origen:** Medicina 42,7% · Urgencia 32,0% · Traumatología 9,4% · Cirugía 7,6%
**Core operativo:** tratamiento EV (~45%) · kinesiología (~40%) · curaciones (~10%)

> Hospitalización domiciliaria geriátrica de facto, con población vulnerable y de bajos ingresos.

---

# Estado actual: valor demostrado + brechas reales

## ✅ Lo que funciona
- Equipo multidisciplinario con experiencia real
- Cartera clínica operativa y resultados demostrables
- Derivación funcional desde medicina, urgencia, cirugía y trauma
- Enlace piloto con APS / Programa Postrados

## ⚠️ Lo que necesita cerrarse
- Protocolo desactualizado para unidad permanente
- Registros dispersos: papel + Excel + Drive
- Sin sistema de información compartido
- Gobernanza clínica informal
- Capacidad operativa subutilizada

> **Hoy funciona por compromiso del equipo. Necesitamos que además funcione por diseño.**

---

# Hallazgos de telemetría: la operación real

**7.586 eventos GPS × 1.573 visitas × 2.029 atenciones · Ene–Mar 2026**

<div class="center">

| Indicador | Valor |
|---|---|
| **Match programación ↔ GPS** | **87,0%** |
| Jornada formal HODOM | 08:00 – 20:00 (12h) |
| Ventana operativa real | ~08:30 – 17:30 (**9h**) |
| <span class="red">Jornada no operada</span> | <span class="red">~2,5 h/día</span> |
| % productivo sobre 12h | **39,2%** |
| Visitas/día/móvil | **8,1** |
| Km/día promedio | **73,2 km** |
| <span class="red">Capacidad ociosa trimestre</span> | <span class="red">**1.818 horas**</span> |

</div>

---

# Telemetría: distribución del tiempo

## Sobre jornada formal de 12 horas

```
   En Base (25,2%)    Terreno (23,1%)    Movimiento (16,1%)    No operado (35,6%)
   ████████████        █████████████       ██████████            ██████████████████
```

## Perfil horario

| Franja | Actividad |
|---|---|
| 08:00–09:00 | 🟡 Arranque tardío (~08:30) |
| 09:00–12:00 | 🟢 **Bloque AM activo — mejor rendimiento** |
| 12:00–14:00 | 🔴 Valle: retorno masivo + almuerzo (23%) |
| 14:00–17:30 | 🟢 Bloque PM activo |
| 17:30–20:00 | ⬛ **Sin operación de ruta** |

> **2,5 horas diarias de jornada formal sin uso = ~7,5 horas/día flota ociosa.**

---

# Telemetría: perfil de la flota

| Indicador | PFFF57 | RGHB14 | SUV TZXS94 |
|---|:---:|:---:|:---:|
| Límite km/día | 100 | 100 | 80 |
| Disponibilidad | **L-D** | **L-D** | **L-V** |
| Km/día real | 73,9 | 81,2 | 63,2 |
| **% uso km** | 73,9% | 81,2% | 79,0% |
| Visitas/día | 9,3 | 8,8 | 5,6 |
| Km/visita | 7,9 | 9,0 | 11,1 |
| Retornos base/día | 3,8 | 3,8 | 3,8 |
| % tiempo en base | 36,0% | 38,3% | 42,0% |

**⚠️ Seguridad vial:** velocidades >100 kph frecuentes en rutas rurales.
**⚠️ Fin de semana:** solo 2 móviles (sin SUV).

---

# Productividad médica: recálculo L-V

## Los médicos trabajan de lunes a viernes (a diferencia del equipo en cuarto turno)

<div class="center">

| Parámetro | Cálculo |
|---|---|
| Días operativos del trimestre | 83 días |
| Días laborables L-V (ene-mar) | **~59 días** |
| Dotación médica | 1 JC + 1 MJ = **1,5 FTE** |
| Atenciones con componente médico (~15-18% del total) | **~305-365** |
| **Atenciones médicas/día laborable** | **~5,2 – 6,2** |
| **Atenciones/día/FTE médico** | **~3,5 – 4,1** |

</div>

### Comparación con potencial

| Escenario | Atenciones/día/FTE |
|---|---|
| Actual estimado | 3,5 – 4,1 |
| **Viable con regulación + telecontrol** | **6 – 8** |
| Diferencia | **+70-95%** capacidad recuperable |

> La productividad médica sube si se combina presencialidad con regulación clínica y telecontrol.

---

# Telemetría: capacidad recuperable

## Sin recursos adicionales

| Mejora | Impacto | Visitas extra/día |
|---|---|:---:|
| 🔴 Activar bloque 17:30-19:30 | +120 min/día × 3 móviles | **+6-8** |
| 🔴 Reducir tiempo en base | Almuerzo escalonado + registros en terreno | **+3** |
| 🟡 Salida protocolizada ≤08:00 | +30 min/día | **+1** |
| 🟡 Asignación territorial | -15% km redundantes | **+1-2** |
| | | |
| **Total L-V** | ~320 min/día recuperados | **+12-16** |

<div class="highlight">

**La flota podría pasar de ~24 a ~36-40 visitas/día (+50-67%) sin vehículos ni personal adicional.**

La holgura es de **tiempo** (horas no operadas), no de km.

</div>

---

# Tres horizontes de desarrollo

## Horizonte 1 — Mejor rendimiento con lo que tenemos
- Más visitas, menos tiempos muertos
- Regulación clínica / revisión de casos
- Mejor registro, coordinación y comunicación
- Reactivar sueroterapia y oxigenoterapia (3 concentradores disponibles)

## Horizonte 2 — Cumplimiento normativo y consolidación
- DS 1/2022 + Norma Técnica HD 2024
- Protocolos mínimos · Registros auditables · Indicadores
- Seguridad del paciente · Gobernanza

## Horizonte 3 — Máxima expresión del potencial
- Tecnología, IA, automatización, digitalización
- Gestión del conocimiento · Capacitación continua
- Calidad, seguridad e innovación como práctica

---

# Horizonte 1: lo concreto y lo inmediato

## Acciones que empiezan esta semana

| Acción | Para qué |
|---|---|
| **Briefing diario** | Alinear el día, revisar casos, asignar prioridades |
| **Regulación clínica de casos** | Ingreso-seguimiento-alta con criterio compartido |
| **Registro mínimo homogéneo** | Una captura digital simple, desde el celular |
| **Escalamiento clínico** | Regla única: semáforo + NEWS2 |
| **Evaluación domicilio/cuidador** | Formulario estandarizado |
| **Reactivar O₂ domiciliario** | 3 concentradores listos |

## Criterio rector

> **Todo lo que implementemos debe disminuir carga cognitiva, no aumentarla.**

---

# Cómo lo vamos a hacer

## Principios de implementación

- Avanzar por **capas**, no con cambios masivos
- Partir por lo más **útil** para el trabajo real
- Formalizar **lo justo**, en formatos simples
- Herramientas **breves, claras y absorbibles**
- No duplicar trabajo ni agregar **burocracia**
- Mostrar **resultados tempranos**
- Ajustar con **retroalimentación del equipo**

## Fórmulas clave

> "Ordenar sin rigidizar · Formalizar sin burocratizar · Mejorar sin sobrecargar"

---

# Capa operativa digital: lo que ya estamos construyendo

| Prototipo | Qué resuelve |
|---|---|
| **Panel general** | Censo, cupos, alertas, ingresos/altas, móviles, pendientes |
| **Registro móvil** | Formulario breve por disciplina, desde el celular |
| **Regulación clínica** | Casos nuevos, alertas, egresos, rescates, decisión |
| **Georreferenciación** | Mapa de pacientes, macrozonas, rutas por móvil |
| **Alta/contrarreferencia** | Resumen, indicaciones, continuidad APS |
| **Telecontrol** | Voz/video/chat desde navegador, sin app |

### Todo mobile-first · Simple · Sin duplicar trabajo · Imprimible si se necesita

---

# Lo que les pido a ustedes

- **Honestidad** para mostrar lo que funciona y lo que no
- **Ayuda** para distinguir protocolo escrito vs. práctica real
- **Participación** en actualización de flujos y criterios
- **Compromiso** con registro, capacitación y mejora
- **Franqueza** para señalar ideas inviables o peligrosas
- **Disposición** a construir una unidad más ordenada y más fuerte

> Una dirección técnica sin inteligencia de terreno no sirve. Necesito conversación honesta, criterio y construcción compartida.

---

# Mi compromiso como Director Técnico

- Cuidar la **seguridad clínica**
- Defender el **valor del equipo** ante la institución
- **No romantizar** la precariedad
- **Ordenar antes** de exigir expansión
- Hacer visibles con **datos** los logros y las brechas
- Empujar una evolución **realista, útil y sostenible**

> Mi lectura: ustedes ya demostraron que HODOM tiene valor. Ahora nos toca convertir ese valor en una unidad más ordenada, más defendible, más trazable y más proyectable. Primero cumpliendo lo que debemos. Después construyendo lo que podemos llegar a ser.

**Y eso solo se puede hacer bien con ustedes, no sobre ustedes.**

---

<!-- _class: center -->

# Conversación abierta

### Preguntas para el equipo

- ¿Qué parte de esta lectura sienten que representa mejor la realidad?
- ¿Qué brecha les pesa más en el día a día?
- ¿Qué no deberíamos perder al ordenar y crecer?
- ¿Qué quick win sienten más urgente?

---

<!-- _class: center -->
<!-- _paginate: false -->

# HODOM HSC
## Consolidar · Cerrar brechas · Proyectar

**Dirección Técnica · Hospital de San Carlos · 2026**

<div class="small">

*"No vengo a partir de cero. Vengo a reconocer una unidad que ya demostró valor, ordenar lo que hoy depende de esfuerzo informal, y ayudarnos a pasar de un modelo que funciona por compromiso a uno que funcione además por diseño, trazabilidad y proyección."*

</div>
