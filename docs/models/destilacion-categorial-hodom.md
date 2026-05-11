# Destilación categorial de HODOM

> **Objeto destilado:** `db/hodom-integrado-pg-v4.sql` (10 784 líneas, 131 tablas, 9 schemas, 251 FKs, 172 CHECKs, 28 funciones PL/pgSQL).
> **Anclaje doctrinal:** corpus ICAS-BoK (`urn:fxsl:kb:icas-*`).
> **Hipótesis de fidelidad:** la signatura categorial de §2 + las cláusulas de §3 a §7 reconstruyen el schema PostgreSQL salvo nombres físicos, índices y elecciones de tipo escalar. Lo que se pierde está declarado en §8.

---

## 0. Síntesis ejecutiva — qué ES esta base

> **HODOM es una categoría finitamente presentada** **C_HODOM** (schema-categoría en el sentido de Spivak: objetos = sorts, morfismos generadores = FKs, ecuaciones = path equations) **fibrada sobre territorio × tiempo** y **estructurada como Mealy automaton de dos niveles** (estadía y visita), cuyas instancias son funtores `I: C_HODOM → Set` y cuyos reportes REM son las **imágenes Σ del funtor de proyección al espacio (periodo × establecimiento × eje_componente)**. Encima, un **functor parcial** `Φ: C_HODOM → C_FHIR_R4` ancla el dominio a HL7-FHIR R4 — fiel sobre el núcleo Patient/Encounter/Procedure/Observation/MedicationRequest/Location/Practitioner, pero ni full ni esencialmente sobreyectivo.

En una frase: **HODOM es una schema-categoría chilena de hospitalización domiciliaria, fibrada por establecimiento y tiempo, con autómatas de estado clínico-operacional y con un functor de anclaje débil hacia FHIR-R4**.

El SQL ya **se reconoce** como categoría: hay comentarios literales `Morph pi: Dom -> (Pac x Loc)` (línea 1360), `Obj Loc — punto geografico paciente-level. Coordenadas obligatorias (PE3)` (línea 2454), `Path equation: visita.localizacion_id = domicilio.localizacion_id` (línea 3545), y `NON-FUNCTORIAL: TEXT libre, debería ser FK` (línea 2740). Esta destilación **revela** la estructura ya escrita, no la impone.

---

## 1. La categoría base **C_HODOM** — presentación finita

`C_HODOM` se presenta por generadores y relaciones (Spivak, *Functorial Data Migration*; ICAS-BoK `urn:fxsl:kb:icas-preservacion`). Una **instancia** es un funtor `I: C_HODOM → Set` que asigna conjunto a cada objeto y función a cada generador, respetando todas las ecuaciones — **es exactamente lo que PostgreSQL hace al cumplir las constraints**.

### 1.1. Objetos centrales (sorts)

Listados por **centralidad medida en in-degree de FK** sobre el SQL:

| Objeto | Tabla SQL | In-degree | Rol categorial |
|---|---|---:|---|
| **Pac** | `clinical.paciente` | 52 | objeto raíz del fragmento clínico |
| **Stay** | `clinical.estadia` | 50 | episodio → estado de un autómata |
| **Prv** | `operational.profesional` | 38 | objeto raíz del fragmento operacional |
| **Vis** | `operational.visita` | 16 | morfismo materializado (encuentro) → estado |
| **Doc** | `clinical.documentacion` | 8 | sub-categoría documental |
| **Est** | `territorial.establecimiento` | 6 | base de fibración tenant |
| **Zon** | `territorial.zona` | 5 | territorio operacional |
| **Loc** | `territorial.localizacion` | 2 | punto geográfico (georef) |
| **Dom** | `clinical.domicilio` | — | binding paciente×localización con vigencia |
| **Ord** | `operational.orden_servicio` | 4 | orden agregada |
| **Rou** | `operational.ruta` | 4 | secuencia diaria de visitas |
| **Pln** | `clinical.plan_cuidado` | 3 | plan terapéutico |
| **Cat** | `reference.catalogo_prestacion` | 3 | catálogo cerrado (objeto codiscreto) |
| **Eqp** | `clinical.equipo_medico` | 2 | dispositivo prestable |
| **Veh** | `operational.vehiculo` | 3 | recurso de transporte |

(Más unas ~60 tablas satélite que aportan morfismos hacia los objetos centrales: `condicion`, `procedimiento`, `observacion`, `indicacion_medica`, `dispensacion`, `evaluacion_funcional`, `evaluacion_paliativa`, `seguimiento_herida`, etc. Cada una es un objeto cuyo único rol categorial relevante es ser **dominio** de morfismos hacia `Pac`/`Stay`/`Vis`.)

### 1.2. Morfismos generadores (las FKs canónicas)

Notación: `f: A -> B` lee "para cada `A` hay un único `B` referenciado". Las flechas ortogonales codifican **dependencias funcionales** (functorial dependencies en sentido de Fagin).

```
                                   ┌──────► Est ──► Comuna  (territorial)
                                   │
        Pac ◄── pac ── Stay ── est ┤
         ▲              │
         │              ├── pln_stay ──► Pln
         │              │
         │              ├── pac_stay ──► Pac          (path-eq: pac_stay = pac)
         │              │
        dom_pac         ▼
         │             Vis ──── prv ──► Prv ─── prv_zone ──► Zon
         │              │ │ │
        Dom             │ │ └── prest ──► Cat
         │ │            │ │
         │ └── dom_loc ─┼─┼─► Loc
         │              │ │
         │              │ └── vis_dom ─► Dom
         │              │
         │              └─── ruta ────► Rou ── ruta_prv ──► Prv
         │                                ↘ ruta_veh ──► Veh
         └── dom_loc ──► Loc
```

**Generadores explícitos** (denoto `dom(f)` y `cod(f)`):

| Generador | Dominio → Codominio | Origen SQL |
|---|---|---|
| `pac` | `Stay → Pac` | `estadia.patient_id` |
| `est_stay` | `Stay → Est` | `estadia.establecimiento_id` |
| `pln_stay` | `Pln → Stay` | `plan_cuidado.stay_id` |
| `stay_v` | `Vis → Stay` | `visita.stay_id` |
| `pac_v` | `Vis → Pac` | `visita.patient_id` (redundante; ver §3) |
| `prv` | `Vis → Prv` | `visita.provider_id` |
| `dom_v` | `Vis → Dom` | `visita.domicilio_id` |
| `loc_v` | `Vis → Loc` | `visita.localizacion_id` (redundante; ver §3) |
| `cat_v` | `Vis → Cat` | `visita.prestacion_id` |
| `ruta_v` | `Vis → Rou` | `visita.route_id` |
| `pac_dom` | `Dom → Pac` | `domicilio.patient_id` |
| `loc_dom` | `Dom → Loc` | `domicilio.localizacion_id` |
| `prv_ruta` | `Rou → Prv` | `ruta.provider_id` |
| `est_loc` | `Loc → Est` (vía Comuna) | `localizacion.comuna` (parcial) |

(Y unas ~30 FK menores, todas paralelas: `condicion → Pac`, `condicion → Stay`, `procedimiento → Vis`, etc. Todas se factorizan a través de los caminos canónicos: ver §3.)

### 1.3. Ecuaciones (path equations)

El SQL **declara explícitamente** seis path equations bajo el rótulo `PE_n`. La signatura es **fiel** sólo si éstas se imponen como ecuaciones en `C_HODOM`:

| Etiqueta | Ecuación | Verificada por |
|---|---|---|
| **PE1** | `loc_v = loc_dom ∘ dom_v` (en Vis) | `clinical.check_visita_domicilio_coherence()`, líneas 102–134, falla con "PE1 violation" |
| **PE2** | `pac_dom ∘ dom_v = pac ∘ stay_v` (en Vis) | mismo trigger, "PE2 violation" |
| **PE3** | `Loc.lat ≠ NULL ∧ Loc.lng ≠ NULL` (totalidad de coords) | `CONSTRAINT localizacion_precision_geo_check`, línea 2445 + comentario línea 2454 |
| **PE4** | `Dom` es exclusión temporal sobre `Pac` (a lo más un domicilio principal vigente por paciente y fecha) | comentario línea 1360 + extensión `btree_gist`, índice GIST |
| **PE5** (`check_documentacion_coherencia`) | `pac ∘ stay_doc = pac_doc` | función línea 221 |
| **PE7** (`check_encuesta_pe7`) | `encuesta` requiere `Stay.tipo_egreso ≠ NULL` (subobjeto de stays con egreso documentado) | función línea 250 |

Una instancia `I` es válida iff todos estos diagramas conmutan en `Set`. El sistema de triggers PL/pgSQL es **el verificador composicional** de las ecuaciones.

> **Lectura categorial estricta** (`urn:fxsl:kb:icas-preservacion`, §"path equivalences"): las path equations son las ecuaciones que distinguen una **schema-categoría** de su grafo libre subyacente. Sin ellas, `C_HODOM` sería sólo el grafo `G_HODOM`. Con ellas, es la categoría **libre presentada por (G_HODOM, PE)**.

---

## 2. Diagrama central conmutativo (corazón del sistema)

El núcleo clínico-operacional es el siguiente diagrama. Las flechas son los generadores; las celdas conmutan por las ecuaciones de §1.3.

```
                       cat_v
              Vis ───────────────► Cat (catálogo cerrado)
              │ │
        prv_v │ │ stay_v
              ▼ ▼
        Prv   Stay ──── pac ─────► Pac
         │     │                    ▲
         │     │ est_stay            │
   prv_ruta    │                    │ pac_dom
         │     ▼                    │
         │    Est                  Dom ──── loc_dom ──► Loc
         │                          ▲                    ▲
         │                          │ dom_v              │ loc_v
         │                          │                    │
         └─── Rou ◄──── ruta_v ──── Vis ─────────────────┘
                          (PE1: loc_v = loc_dom ∘ dom_v)
                          (PE2: pac_dom ∘ dom_v = pac ∘ stay_v)
```

El diagrama codifica el **invariante esencial del sistema**: una visita `v ∈ I(Vis)` está en el mismo paciente y mismo lugar que su estadía y su domicilio. Cualquier instancia que viole esto es rechazada.

> **Yoneda en acción** (`urn:fxsl:kb:icas-identidad-es-relacion`): `Pac` se entiende plenamente por su **patrón de morfismos entrantes** — un paciente *es* la familia coherente de sus estadías, domicilios, condiciones, observaciones, evaluaciones. El SQL hace esto manifiesto: 52 tablas tienen FK a `paciente`, y *eso es* lo que es un paciente en la base.

---

## 3. Redundancias materializadas y factorización forzada

El SQL contiene **morfismos redundantes** que coexisten con caminos derivables. Categorialmente esto **viola minimidad** pero **preserva fidelidad performante**:

| FK redundante | Camino canónico | Comentario SQL | Lectura |
|---|---|---|---|
| `visita.localizacion_id` | `loc_dom ∘ dom_v` | "Path equation: visita.localizacion_id = domicilio.localizacion_id" (l. 3545) | redundancia controlada |
| `visita.patient_id` | `pac ∘ stay_v` | (validada por PE2) | denormalización JOIN-ahorro |
| `visita.location_id` (legacy) | (no poblado) | "NO POBLADO (0/7594). Mantenido por compatibilidad" (l. 3538) | morfismo zombie — declarado como gap funcional |
| `visita.gps_lat/lng` | (NULL principalmente) | "176/7594 poblado via matching Haversine <150m" (l. 3524) | morfismo parcial sobre Vis |

Todas estas son consecuencia de **PostgreSQL no tener path navigation declarativa**: Spivak (CQL) lo da gratis, SQL no. La presencia de redundancia no rompe la categoría — la fortalece operacionalmente y se neutraliza con triggers que **fuerzan la conmutatividad**.

> **Adjunción libre/olvido** (`urn:fxsl:kb:icas-adjunciones`, §"free/forgetful"): el SQL es la imagen del functor olvidadizo `U: PgSchema → Cat` aplicado a la presentación categorial; reintroducir las redundancias y triggers es el lado libre que `U` no captura. Esto **no es una adjunción literal demostrada**, es lectura estructural.

---

## 4. Fibración por establecimiento y tiempo

La presencia ubicua de `establecimiento_id` y de `created_at`/`fecha_*` no es decoración. Es la base de una **fibración** (Grothendieck construction; `urn:fxsl:kb:icas-extension`).

### 4.1. Fibración tenant `p_est: C_HODOM → Est`

Sobre la categoría discreta `Est = territorial.establecimiento`, hay un functor **proyección**:

```
p_est : C_HODOM ──► Est
```

que envía cada objeto al `establecimiento_id` mediante el camino canónico (vía `Stay → Est`, `Loc → Est`, `Vis → Stay → Est`, etc.). La **fibra** sobre un establecimiento `e ∈ Est` es la sub-categoría `(C_HODOM)_e` con sólo registros de ese tenant.

- Las claves primarias compuestas de `reporting.rem_*` (`PRIMARY KEY (periodo, establecimiento_id, ...)`, líneas 4438–4475) **son la materialización de las fibras** en cada periodo.
- La función `reporting.fn_rem_personas_atendidas(p_periodo)` ejecuta la **proyección Δ_periodo** seguida de la suma Σ_componente.

### 4.2. Fibración temporal `p_t: C_HODOM → IR` (heurística)

Las columnas `fecha_ingreso`, `fecha_egreso`, `vigente_desde`, `vigente_hasta`, `timestamp` definen una proyección hacia el dominio de intervalos. Una `Stay` con `[fecha_ingreso, fecha_egreso]` es una **sección sobre un intervalo**.

Esto **sugiere** la lectura de behavior types como sheaves sobre `IR/▷` (`urn:fxsl:kb:icas-tiempo`, §"Behavior types como sheaves"). Pero sólo se realiza plenamente si imponemos la condición de pegado (sheafhood), lo cual **el SQL no hace explícitamente**: hay restricciones puntuales (CHECK `fecha_egreso >= fecha_ingreso`) pero no condición de gluing universal. Mejor declararlo así: el modelo es un **presheaf temporal** (una asignación de datos a intervalos con restricción), no un sheaf — la sheafification queda como deuda de modelo y se materializa parcialmente en `clinical.v_domicilio_vigente` (l. 2461, vista que selecciona la sección vigente).

> **Heurístico, no formal.** Llamarlo "sheaf temporal" requeriría especificar un site sobre `IR/▷` con coverage explícita y verificar gluing — no presente en el SQL.

---

## 5. Autómatas como Mealy machines categoriales

El SQL contiene **dos autómatas explícitos** con tablas de evento separadas:

### 5.1. Autómata de estadía

```
Estados Q_stay = {pendiente_evaluacion, elegible, admitido, activo, egresado, fallecido}
Etiquetas Σ_stay = {eligibility_evaluating, patient_admitting, care_planning,
                    therapeutic_plan_executing, clinical_evolution_monitoring,
                    patient_discharging, post_discharge_following}
                    (CHECK constraint línea 3089)
Tabla de transiciones: operational.evento_estadia
                       (event_id, stay_id, ts, estado_previo, estado_nuevo, proceso_opm, detalle)
Función de transición: clinical.transition_estadia(stay_id, new_estado, proceso_opm, detalle)
                       (línea 155, RETURNS event_id)
```

Esto es **exactamente** una **coalgebra** `δ: Stay → (Σ × Stay)^Q_stay` (`urn:fxsl:kb:icas-efectos`, §"coalgebras y bisimulación"), donde `evento_estadia` materializa la traza del autómata.

Las etiquetas `Σ_stay` **son los procesos OPM ISO 19450** del modelo conceptual. La base **traza el modelo OPM**: cada `proceso_opm` registrado es un morfismo del modelo OPM ejecutado sobre la estadía concreta.

### 5.2. Autómata de visita (más rico)

```
Estados Q_vis = {PROGRAMADA, ASIGNADA, DESPACHADA, EN_RUTA, LLEGADA,
                 EN_ATENCION, COMPLETA, PARCIAL, NO_REALIZADA,
                 DOCUMENTADA, VERIFICADA, REPORTADA_REM, CANCELADA}
                 (CHECK constraint línea 3515 — 13 estados)
Tabla de transiciones: operational.evento_visita
                       (event_id, visit_id, ts, estado_previo, estado_nuevo, lat, lng, origen, detalle)
Función: operational.transition_visita
```

La presencia de `lat, lng` en `evento_visita` significa que la coalgebra está **enriquecida sobre el espacio métrico de coordenadas** — cada transición lleva georef. Esto **sugiere** un sistema dinámico (lente `Stay → Poly`, `urn:fxsl:kb:icas-interaccion`) pero verificarlo exigiría tipear los puertos como polinomios. Heurístico.

> **Lectura categorial limpia** (`urn:fxsl:kb:icas-efectos`): la tabla de eventos *es* la categoría libre `F(Q, Σ)` sobre el grafo del autómata — los pares `(estado_previo, estado_nuevo)` son los morfismos generadores, y la composición de eventos consecutivos es la composición categórica. La existencia del `event_id` da identidad a cada flecha (no sólo a cada estado).

---

## 6. Reportes REM como adjunciones Σ

Los **reportes REM A21** (Resumen Estadístico Mensual, MINSAL) tienen forma categorial precisa y esencial.

### 6.1. La tripleta Σ-Δ-Π de Spivak

`urn:fxsl:kb:icas-adjunciones` (§"triple adjunción Σ-Δ-Π" + §"adjunciones generan límites"): un functor entre schemas `F: S → T` induce automáticamente:

```
Σ_F ⊣ Δ_F ⊣ Π_F
```

donde `Δ_F` es pullback (proyección) y `Σ_F` es pushforward (suma sobre la fibra).

### 6.2. El functor de proyección REM

Sea `S_REM` la schema-categoría con tres objetos `Periodo × Est × Eje` (donde `Eje ∈ {componente, profesion_rem, origen_derivacion}`). Hay un functor:

```
F_REM: C_HODOM ──► S_REM
```

que envía `Stay`/`Vis` a su tripleta `(periodo, establecimiento_id, eje)`. Su **left adjoint** `Σ_F_REM` cuenta filas en cada fibra:

| Función SQL | Adjunción categorial |
|---|---|
| `fn_rem_personas_atendidas` (l. 925) | `Σ_F_REM` con desglose por `(componente, edad_band, sexo)` |
| `fn_rem_visitas` (l. 1022) | `Σ_F_REM` con desglose por `profesion_rem`, restringido al subobjeto Vis donde `rem_reportable = TRUE ∧ estado ∈ {COMPLETA, …, REPORTADA_REM}` |
| `fn_rem_origen_derivacion` (l. 893) | `Σ_F_REM` por `origen_derivacion` |
| `fn_ocupacion_dia` (l. 857) | `Σ_F_REM` con cociente (numerador `Stay activas`, denominador `cupos`) |

Las tablas `reporting.rem_cupos`, `reporting.rem_personas_atendidas`, `reporting.rem_visitas` (líneas 4437–4477) son la **materialización** del pushforward — `PRIMARY KEY (periodo, establecimiento_id, componente)` codifica exactamente la fibra.

> **Por qué esto importa**: REM A21 es **regulación normativa MINSAL**, no negociable. Categorialmente, eso es **una propiedad universal**: la mejor agregación es única salvo isomorfismo. Si algún día Felix migra a otro RDBMS o a un data warehouse, las funciones `fn_rem_*` se preservan automáticamente porque son adjunciones — no SQL ad hoc.

### 6.3. Lo que las funciones REM **NO** son

- **No son sheafification**: no fuerzan condición de pegado entre fibras.
- **No son Π_F (right adjoint)**: el right adjoint daría productos de fibras, lo cual no se usa en REM (REM agrega, no diversifica).
- Heurístico: la garantía de coherencia entre `rem_personas_atendidas.total_egresos` y `Stay.tipo_egreso` se mantiene por **path equation** (PE5/PE7), no por la adjunción misma.

---

## 7. El functor de anclaje a FHIR R4

`docs/models/FHIR_R4_Resource_References.md` cataloga 37 recursos FHIR. Existe un functor parcial:

```
Φ : C_HODOM ─────► C_FHIR_R4
```

con la siguiente correspondencia núcleo (mapeo on-objects):

| `C_HODOM` | `C_FHIR_R4` | Notas |
|---|---|---|
| `Pac` | `Patient` | Φ es full sobre identificadores; pierde `prevision` (FONASA-A/B/C/D), `cesfam`, `comuna` chilenos (no nativos en FHIR-R4 base) |
| `Stay` | `EpisodeOfCare` (más cercano que `Encounter`) | Φ pierde `origen_derivacion ∈ {APS, urgencia, hospitalizacion, ambulatorio, ley_urgencia, UGCC}` que es vocabulario chileno |
| `Vis` | `Encounter` (clase home) ∘ `Procedure` (cuando se realiza prestación) | Φ es **multi-valuado** — una visita FHIR es 1+ recurso FHIR. Esto **no es functorial sin extensiones**. |
| `Prv` | `Practitioner` + `PractitionerRole` | Φ es full sobre `profesion`; `profesion_rem` es atributo MINSAL no nativo |
| `Pln` | `CarePlan` | razonablemente faithful |
| `Cat` | `ServiceRequest` (catálogo) o `ChargeItemDefinition` | el catálogo MAI/EPH chileno mapea débilmente |
| `Loc` + `Dom` | `Location` + `Address` (dentro de Patient) | Φ debe descomponer Dom en address temporal — pérdida de `vigente_desde/hasta` salvo extensión |
| `Eqp` (`equipo_medico`) | `Device` + `DeviceRequest` | razonablemente faithful |
| `Doc` (`documentacion`) | `DocumentReference` | faithful sobre metadatos, opaco sobre contenido |

### 7.1. Propiedades de Φ (categorialmente, `urn:fxsl:kb:icas-preservacion`)

- **Φ es FAITHFUL** sobre el núcleo Pac/Stay/Prv/Eqp/Loc: morfismos distintos en `C_HODOM` se mapean a morfismos distintos en `C_FHIR_R4`. Demostración: cada FK clínica tiene contraparte explícita en FHIR (Encounter.subject → Patient, etc.).
- **Φ NO es FULL**: hay morfismos en `C_FHIR_R4` sin pre-imagen en `C_HODOM` — p.ej. `Encounter.basedOn → ServiceRequest`, `Encounter.partOf → Encounter` (jerarquía padre-hijo de encuentros), `Patient.link → Patient` (merge/fusion). HODOM no modela estos.
- **Φ NO es esencialmente sobreyectivo**: muchos recursos FHIR no tienen objeto correspondiente en HODOM (`Slot`, `Appointment.cancellation*`, `Coverage`, `Claim`, `MessageHeader`, `Provenance` — aunque `migration.provenance` cubre parcialmente).
- **Lo que Φ pierde estructuralmente**: terminología chilena (FONASA, REM, MAI, UGCC, GES, prevision, profesion_rem). Φ debe componerse con un **functor de localización chilena** `Loc_CL: C_FHIR_R4 → C_FHIR_R4_CL` que añade extensiones (Φ_CL = Loc_CL ∘ Φ).

### 7.2. Observación útil

La existencia de `migration.provenance` (líneas 2853–2862, con campos `target_table, target_pk, source_type, source_file, source_key, phase, field_name`) **es la categoría de origen de Φ**: cada fila documenta de qué morfismo del mundo legacy proviene cada flecha de `C_HODOM`. Esto **es** el FHIR `Provenance` resource avant la lettre.

---

## 8. Lo que esta destilación NO captura (gaps declarados explícitamente)

| Aspecto del SQL | Por qué no entra en la signatura | Estado |
|---|---|---|
| Tipos físicos (`text` vs `varchar(N)`, `real` vs `double precision`, `integer` vs `bigint`) | No son estructura categorial | Decisión de implementación |
| Índices (B-tree, GIST, btree_gist) | Performance, no semántica | Decisión de implementación |
| Default values (`DEFAULT now()`, `DEFAULT 'borrador'`) | Decoración instancial | Decisión de implementación |
| `created_at` / `updated_at` automáticos | Audit metadata, no estructura | Decisión de implementación |
| 5 schemas operacionales (`portal`, `telemetry`, `migration`, `strict`, `reference`) cuyas tablas tienen rol marginal | Anexo, no núcleo. La signatura de §1 cubre sólo el núcleo clínico-operacional. | **Gap consciente** — extender la signatura con sub-categorías por schema si se necesita |
| Las funciones de **guardas de transición** (`guard_estadia_estado`, etc., líneas 679–747) | Implementan la sub-coalgebra alcanzable: no toda transición sintácticamente válida es semánticamente permitida. Pertenecen a la **safety logic** del topos, no a la signatura base. | **Gap formal** — modelable como subobject classifier en topos, fuera del alcance de la destilación mínima |
| **Sheafhood temporal real** | El SQL impone restricciones puntuales sobre intervalos, no condición de pegado universal | **Gap declarado** (§4.2) |
| **Naturalidad del functor Φ a FHIR** | Φ se verifica como mapeo on-objects/morfismos faithful, pero la naturalidad de las transformaciones FHIR↔HODOM en escenarios de actualización (write-back) **no está demostrada**. | **Gap formal** — requiere especificación de la categoría destino con sus propios morfismos de actualización |
| **2-cells / lazos de revisión** (epicrisis con tipo_egreso ↔ estadía sincronizada vía `check_epicrisis_sync_estadia`, l. 295) | Captura una transformación natural entre dos vistas del mismo egreso | **Heurístico declarado** — las funciones de sync son 2-celdas en la 2-categoría de schemas con triggers, pero la formalización 2-categorial está fuera del alcance pragmático |
| **kb_articulo / kb_documento** (knowledge base operacional, líneas 3133+) | Sub-categoría de documentación interna, ortogonal al núcleo clínico | **Sub-categoría no cubierta** — sería un objeto adicional en la signatura, sin morfismos al núcleo salvo `created_by → Prv` |
| **Telemetría GPS** (`telemetry.gps_posicion`, `telemetria_dispositivo`) | Stream temporal de alta cardinalidad, modelable como behavior type (sheaf temporal) | **Sub-categoría con lectura sheaf-temporal** — no incluida en la signatura central; tratamiento natural en `urn:fxsl:kb:icas-tiempo` |
| **Multi-tenancy real** | El SQL tiene `establecimiento_id` por todas partes pero **no hay row-level security ni roles por tenant** declarados en el dump. La fibración de §4.1 es **estructural** pero **no se materializa como aislamiento ejecutable**. | **Gap operacional** declarado |

### 8.1. Sobre el "se pierde nada" de la pregunta original

**La signatura `(G_HODOM, PE)` de §1 más las cláusulas estructurales de §4–§7 reconstruyen el schema lógico**. Lo que **sí** se pierde:

- decisiones de implementación (índices, tipos físicos, defaults)
- las 5 sub-categorías marginales (declaradas como gap en §8)
- el cableado HTTP/API que consume la base (fuera de scope del SQL)

Lo que **NO** se pierde:

- objetos clínico-operacionales centrales y todos sus morfismos
- las 6 path equations declaradas (PE1–PE5, PE7)
- los dos autómatas con sus alfabetos completos
- la fibración por establecimiento
- la receta categorial de los reportes REM
- la presencia y forma del anclaje FHIR

---

## 9. Tabla maestra de URNs aplicadas

| URN del corpus ICAS-BoK | Sección donde se aplica | Naturaleza |
|---|---|---|
| `urn:fxsl:kb:icas-preservacion` | §1 (schema = categoría finitamente presentada), §7 (Φ faithful/full/eso) | **formal** — Spivak, Functorial Data Migration |
| `urn:fxsl:kb:icas-universales` | §3 (factorización de morfismos redundantes), §6 (REM como propiedad universal) | **formal** sobre §6, **heurístico** sobre §3 |
| `urn:fxsl:kb:icas-adjunciones` | §6 (Σ-Δ-Π para REM), §3 (libre/olvido SQL ↔ presentación categorial) | **formal** sobre §6.1; **heurístico** sobre §3 (lectura libre/olvido sin verificación de leyes triangulares) |
| `urn:fxsl:kb:icas-identidad-es-relacion` | §2 (Yoneda: Pac es su patrón de morfismos entrantes) | **heurístico** — Yoneda es teorema, su aplicación práctica aquí es ilustrativa |
| `urn:fxsl:kb:icas-extension` | §4.1 (fibración de Grothendieck por establecimiento) | **formal** sobre §4.1 (fibración discreta sobre `Est`) |
| `urn:fxsl:kb:icas-efectos` | §5 (autómatas como coalgebras), §5.2 (eventos como categoría libre `F(Q,Σ)`) | **formal** sobre coalgebra; **heurístico** sobre lectura como sistema dinámico polinomial |
| `urn:fxsl:kb:icas-tiempo` | §4.2 (presheaf temporal, no sheaf), §8 (telemetría como behavior type) | **heurístico declarado** — sheafhood no verificada |
| `urn:fxsl:kb:icas-topoi` | §8 (guardas de transición como subobject classifier interno) | **heurístico** — gap declarado, no implementado |
| `urn:fxsl:kb:icas-interaccion` | §5.2 (lente potencial `Stay → Poly` para visita con georef) | **heurístico** — sugerido, no demostrado |
| `urn:fxsl:kb:icas-composicion` | §1 (composición de morfismos = JOIN encadenado) | **formal** — base de la presentación |
| `urn:fxsl:kb:icas-comparacion` | §8 (sync triggers como 2-cells / transformaciones naturales entre vistas) | **heurístico** — gap declarado |

URNs **no aplicadas** y por qué:

- `icas-enriquecimiento` (Cost-categories): podría aplicar a `matriz_distancia` (categoría enriquecida sobre Cost) pero no central. Gap consciente.
- `icas-protocolos`: relevante para flujos clínicos cross-actor (paciente-cuidador-equipo), pero la base sólo registra resultados, no protocolos in-flight. No aplica al SQL.
- `icas-agencia`, `icas-infraestructura-autonoma`: no hay agentes ni IA en el schema.
- `icas-escala` (operads, double categories), `icas-higher-categories`: la base no requiere lenguaje 2-categorial salvo en §8 (sync triggers, declarado como gap).
- `icas-procesos`, `icas-lifecycle`, `icas-calidad-riesgo`, `icas-patrones`, `icas-safety-alignment`: orientadas al ciclo de ingeniería, no al artefacto base.

---

## 10. Distinción **formal** / **heurístico** por afirmación principal

| Afirmación | Estado | Justificación |
|---|---|---|
| HODOM es schema-categoría finitamente presentada | **formal** | Generadores explícitos en §1.2, ecuaciones explícitas en §1.3, instancia = funtor a Set verificable |
| Las 6 path equations son ecuaciones categoriales | **formal** | Implementadas como triggers, falsificables |
| `evento_estadia` materializa la coalgebra del autómata | **formal** | Función `transition_estadia` produce flecha; tabla almacena traza |
| Reportes REM son Σ-pushforward sobre `(periodo × est × eje)` | **formal** sobre la mecánica; **operacionalmente correcto** sobre las funciones específicas listadas en §6.2 |
| Existe fibración tenant `p_est: C_HODOM → Est` | **formal** sobre la proyección; la fibración es discreta sobre `Est` |
| Φ a FHIR es faithful no full no eso-sob | **formal** sobre identificación de morfismos; **declaración de pérdida** sobre los recursos no cubiertos |
| Behavior types temporales / sheafhood | **heurístico declarado** | El SQL no implementa condición de pegado |
| Lectura "libre/olvido" SQL ↔ presentación | **heurístico** | No se verifican identidades triangulares de adjunción |
| Lente sistema dinámico para visita | **heurístico** | Sugerido por presencia de georef en eventos, no formalizado |
| Yoneda como justificación de "Pac es su patrón de morfismos" | **heurístico aplicado** | El teorema es formal; su aplicación práctica aquí es ilustrativa |
| Guardas de transición como topos lógico interno | **heurístico no implementado** | Gap declarado §8 |
| 2-cells de sync (epicrisis ↔ estadía) | **heurístico declarado** | Modelable, no modelado |

---

## 11. Cómo reconstruir el schema desde esta destilación

Procedimiento:

1. **Leer §1.1** → crear tabla por cada objeto. Asignar PK a partir de los campos centrales del comentario (id natural).
2. **Leer §1.2** → para cada generador, agregar columna FK en `dom(f)` apuntando a `cod(f)`.
3. **Leer §1.3** → implementar cada path equation como trigger PL/pgSQL (modelo: §SQL líneas 102–134).
4. **Leer §3** → decidir cuáles redundancias materializar. Mínimamente: ninguna (signatura pura). Operacionalmente: las cuatro listadas en §3.
5. **Leer §4.1** → asegurar que `establecimiento_id` está presente en todas las tablas que pertenecen al fragmento clínico-operacional (vía path canónico o columna directa).
6. **Leer §5** → instalar tablas `evento_estadia` y `evento_visita` con sus alfabetos exactos como CHECK. Implementar funciones `transition_*`.
7. **Leer §6** → implementar funciones REM como Σ sobre las fibras correctas. Los DDL de `reporting.rem_*` son materializaciones cacheadas; reconstruibles desde las funciones.
8. **Leer §7** → si se quiere expone API FHIR, escribir adapter Φ con las correspondencias listadas.

Lo que NO se reconstruye con esto: índices, decisiones de tipo escalar (todo `text` vs `varchar`/`integer`), políticas de RLS futuras, cron jobs externos. Esos son ortogonales a la estructura categorial.

---

## 12. Cierre — qué hace esta destilación útil

Esta destilación es el **objeto Yoneda** de la base: una representación que la determina salvo isomorfismo y que cualquier ingeniero o agente puede consumir para entender estructura sin leer 10 784 líneas de DDL.

Tres usos directos:

1. **Migración a otro motor** (CockroachDB, Spanner, ClickHouse para reporting): la signatura es invariante, sólo cambia el target del functor `U: PgSchema → ?`.
2. **Generación de capa FHIR**: §7 define Φ; el adapter es derivable.
3. **Validación de cambios al schema**: cualquier ALTER TABLE debe preservar las path equations §1.3 o explícitamente romper una y reescribirla. Sin esta destilación, los cambios son ad hoc.

Lo que **no** hace, por diseño:

- no dicta clínicamente qué es un paciente o una visita
- no resuelve disputas sobre normativa REM (las hereda)
- no garantiza que el FHIR adapter compile (sólo que existe la correspondencia)

> **Decisión de cierre**: el formato es schema-categoría finita + cláusulas estructurales sobre la base. Esto es lo más **simple** que **no pierde** la signatura ni los autómatas ni los rollups REM ni el anclaje FHIR. Diagramas conmutativos auxiliares en §2; las URNs justifican cada movimiento estructural; los gaps están declarados.
