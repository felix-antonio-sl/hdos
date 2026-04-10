# Modelo OPM Normativo — Hospitalización Domiciliaria (HODOM) Chile

Modelo conceptual en Object-Process Language (OPL-ES) conforme a ISO/PAS 19450.
Fuentes exclusivas: DS 1/2022 (Reglamento), Decreto Exento 31/2024, Norma Técnica HODOM 2024.

---

## Metadatos del Modelo

| Propiedad | Valor |
|-----------|-------|
| Sistema | Hospitalización Domiciliaria (HODOM) |
| Clasificación | Socio-técnico |
| Esencia primaria | Física |
| Idioma OPL | Español (OPL-ES) |
| Norma de referencia | ISO/PAS 19450 |
| Fuentes normativas | DS 1/2022, Decreto Exento 31/2024, Norma Técnica 2024 |
| Fecha | 2026-04-10 |

---

## SD — System Diagram: Hospitalización Domiciliaria

### SD.1 Clasificación del sistema

Tipo: **socio-técnico**. HODOM es un sistema de salud con componentes humanos (equipo clínico, paciente, familia), tecnológicos (equipamiento médico, sistemas informáticos), organizacionales (protocolos, manuales) y normativos (regulación MINSAL). Se modela con los 5 componentes completos del SD: propósito, función, habilitadores, entorno y ocurrencia del problema.

### SD.2 Propósito

Cambiar **Condición Clínica** de **Paciente** de `agudo o crónico reagudizado` a `recuperado`, proporcionando cuidados equivalentes a los de atención cerrada en el domicilio del paciente.

### SD.3 Función principal (Function-as-a-Seed)

La función del sistema es *Hospitalizar en Domicilio*.

### SD.4 Beneficiario

**Paciente** — persona con patología aguda o crónica reagudizada, clínicamente estable, que recibe cuidados hospitalarios en su domicilio.

### SD.5 Valor funcional

**Paciente** exhibe **Condición Clínica**.
**Condición Clínica** de **Paciente** puede estar `agudo o crónico reagudizado` o `recuperado`.
*Hospitalizar en Domicilio* cambia **Condición Clínica** de **Paciente** de `agudo o crónico reagudizado` a `recuperado`.

### SD.6 Sistema

**Sistema de Hospitalización Domiciliaria** es físico.
**Sistema de Hospitalización Domiciliaria** exhibe *Hospitalizar en Domicilio*.

### SD.7 Ocurrencia del problema

*Enfermar* es físico y ambiental.
*Enfermar* cambia **Condición Clínica** de **Paciente** de `sano` a `agudo o crónico reagudizado`.

---

## SD — Párrafo OPL-ES Completo

### Declaración del sistema

**Sistema de Hospitalización Domiciliaria** es físico.
**Sistema de Hospitalización Domiciliaria** exhibe *Hospitalizar en Domicilio*.

### Objetos — Declaración de esencia y afiliación

**Paciente** es físico.
**Cuidador** es físico.
**Grupo Familiar** es físico.
**Consentimiento Informado** es informático.
**Ficha Clínica** es informática.
**Plan Terapéutico** es informático.
**Plan de Cuidados de Enfermería** es informático.
**Epicrisis** es informática.
**Resumen Clínico en Domicilio** es informático.
**Indicación Médica** es informática.
**Receta** es informática.
**Interconsulta** es informática.
**Informe Social** es informático.
**Encuesta de Satisfacción Usuaria** es informática.
**Formulario de Ingreso** es informático.
**Carta de Derechos y Deberes** es informática.
**Manual de Normas y Procedimientos** es informático.
**Manual de Organización Interna** es informático.
**Protocolo Clínico** es informático.
**Manual de Procedimientos** es informático.
**Plan de Capacitación Anual** es informático.
**Programa de Prevención de IAAS** es informático.
**Programa de Mantención Preventiva** es informático.
**Autorización Sanitaria** es informática.
**Convenio** es informático.
**Registro de Llamadas** es informático.
**Domicilio** es físico.
**Dependencia Administrativa** es física.
**Bodega de Insumos** es física.
**Farmacia o Botiquín** es física.
**Vehículo de Transporte** es físico.
**Equipamiento Médico** es físico.
**Dispositivo de Uso Médico** es físico.
**Insumo Clínico** es físico.
**Medicamento** es físico.
**Residuo Especial** es físico.
**Elemento de Protección Personal** es físico.
**Sistema Telefónico** es físico.
**Soporte Informático** es informático.

### Objetos ambientales

**SEREMI** es física y ambiental.
**Establecimiento de Atención Cerrada** es físico y ambiental.
**Superintendencia de Salud** es informática y ambiental.
**MINSAL** es físico y ambiental.
**Servicio de Salud** es físico y ambiental.
**Institución Derivadora** es física y ambiental.
**Médico Tratante** es físico y ambiental.

### Objetos — Declaración de estados

**Paciente** puede estar `sano`, `agudo o crónico reagudizado`, `estable`, `ingresado`, `en tratamiento`, `recuperado`, `reinternado`, `fallecido` o `egresado`.
**Condición Clínica** de **Paciente** puede estar `agudo o crónico reagudizado` o `recuperado`.
Estado `agudo o crónico reagudizado` de **Condición Clínica** es inicial.
Estado `recuperado` de **Condición Clínica** es final.

**Consentimiento Informado** puede estar `pendiente` o `firmado`.
**Ficha Clínica** puede estar `abierta` o `cerrada`.
**Autorización Sanitaria** puede estar `solicitada`, `otorgada`, `vigente`, `vencida` o `sin efecto`.
**Plan Terapéutico** puede estar `formulado`, `en ejecución` o `cumplido`.
**Plan de Cuidados de Enfermería** puede estar `formulado`, `en ejecución` o `cumplido`.
**Domicilio** puede estar `evaluado como apto` o `evaluado como no apto`.
**Equipamiento Médico** puede estar `operativo`, `en mantención` o `fuera de servicio`.
**Medicamento** puede estar `disponible`, `administrado` o `agotado`.
**Vehículo de Transporte** puede estar `disponible`, `en ruta` o `en mantención`.
**Encuesta de Satisfacción Usuaria** puede estar `pendiente` o `completada`.
**Informe Social** puede estar `pendiente` o `elaborado`.
**Residuo Especial** puede estar `generado`, `almacenado transitoriamente` o `retirado`.

### Relaciones estructurales — Aggregation-Participation

**Sistema de Hospitalización Domiciliaria** consta de **Dependencia Administrativa**, **Equipamiento Médico**, **Conjunto de Vehículos de Transporte**, **Farmacia o Botiquín**, **Bodega de Insumos**, **Conjunto de Protocolos Clínicos** y **Sistema Telefónico**.

**Dependencia Administrativa** consta de **Sistema Telefónico**, **Soporte Informático**, **Bodega de Insumos**, **Farmacia o Botiquín**, **Área de Archivos**, **Área de Residuos**, **Área de Aseo**, **Servicios Higiénicos** y **Estacionamiento**.

**Equipamiento Médico** consta de **Monitor de Presión Arterial**, **Monitor de Frecuencia Cardíaca**, **Oxímetro de Pulso**, **Desfibrilador** y al menos otro rasgo.

**Ficha Clínica** consta de **Formulario de Ingreso**, **Evolución Clínica**, **Indicación Médica**, **Plan Terapéutico**, **Plan de Cuidados de Enfermería** y **Epicrisis**.

**Manual de Organización Interna** consta de **Organigrama**, **Definición de Roles**, **Horario de Funcionamiento** y **Reglamento de Higiene**.

### Relaciones estructurales — Exhibition-Characterization

**Paciente** exhibe **Condición Clínica** así como **Diagnóstico**.
**Sistema de Hospitalización Domiciliaria** exhibe *Hospitalizar en Domicilio* así como **Listado de Prestaciones**.
**Domicilio** exhibe **Condición Sanitaria**, **Servicios Básicos**, **Telefonía** y **Accesibilidad Vial**.
**Autorización Sanitaria** exhibe **Vigencia** y **Cobertura Territorial**.
**Vigencia** de **Autorización Sanitaria** varía de 0 a 3 años.

### Relaciones estructurales — Generalization-Specialization

**Profesional de Salud**, **Técnico de Salud** y **Auxiliar de Salud** son **Personal de Salud**.
**Director Técnico**, **Coordinador**, **Médico de Atención Directa**, **Médico Regulador**, **Enfermero Clínico**, **Kinesiólogo** y **Trabajador Social** son **Profesional de Salud**.
**Auxiliar Paramédico de Enfermería**, **Técnico de Nivel Medio de Enfermería** y **Técnico de Nivel Superior de Enfermería** son **Técnico de Salud**.
**Paciente Agudo** y **Paciente Crónico Reagudizado** son **Paciente**.
**Prestador Público** y **Prestador Privado** son **Prestador de Hospitalización Domiciliaria**.
**Alta Médica**, **Alta por Cumplimiento de Plan**, **Reingreso Hospitalario**, **Fallecimiento**, **Renuncia Voluntaria** y **Alta Disciplinaria** son **Causal de Egreso**.

### Relaciones estructurales — Tagged Structural Links

**Prestador de Hospitalización Domiciliaria** requiere convenio con **Establecimiento de Atención Cerrada**.
**Sistema de Hospitalización Domiciliaria** es fiscalizado por **SEREMI**.
**Autorización Sanitaria** es otorgada por **SEREMI**.
**Personal de Salud** es habilitado por **Superintendencia de Salud**.
**Director Técnico** representa a **Sistema de Hospitalización Domiciliaria** ante **SEREMI**.
**Institución Derivadora** deriva a **Paciente**.
**Cuidador** es responsable de **Paciente**.

---

## SD — Agentes (humanos exclusivamente)

**Director Técnico** maneja *Hospitalizar en Domicilio*.
**Coordinador** maneja *Hospitalizar en Domicilio*.
**Médico de Atención Directa** maneja *Hospitalizar en Domicilio*.
**Enfermero Clínico** maneja *Hospitalizar en Domicilio*.

### SD — Instrumentos

*Hospitalizar en Domicilio* requiere **Sistema de Hospitalización Domiciliaria**.
*Hospitalizar en Domicilio* requiere **Equipamiento Médico**.
*Hospitalizar en Domicilio* requiere **Ficha Clínica**.
*Hospitalizar en Domicilio* requiere **Protocolo Clínico**.
*Hospitalizar en Domicilio* requiere **Sistema Telefónico**.
*Hospitalizar en Domicilio* requiere **Vehículo de Transporte**.

### SD — Transformaciones

*Hospitalizar en Domicilio* cambia **Condición Clínica** de **Paciente** de `agudo o crónico reagudizado` a `recuperado`.
*Hospitalizar en Domicilio* consume **Insumo Clínico**.
*Hospitalizar en Domicilio* consume **Medicamento**.
*Hospitalizar en Domicilio* genera **Ficha Clínica**.
*Hospitalizar en Domicilio* genera **Epicrisis**.
*Hospitalizar en Domicilio* genera **Encuesta de Satisfacción Usuaria**.
*Hospitalizar en Domicilio* genera **Residuo Especial**.

### SD — Entorno

*Enfermar* es físico y ambiental.
*Enfermar* cambia **Condición Clínica** de **Paciente** de `sano` a `agudo o crónico reagudizado`.
**Establecimiento de Atención Cerrada** es físico y ambiental.
**SEREMI** es física y ambiental.
**Institución Derivadora** es física y ambiental.
**Médico Tratante** es físico y ambiental.

---

## SD1 — Descomposición de *Hospitalizar en Domicilio*

*Hospitalizar en Domicilio* se descompone en *Autorizar Establecimiento*, *Evaluar Elegibilidad*, *Ingresar Paciente*, *Tratar en Domicilio*, *Egresar Paciente* y *Fiscalizar Establecimiento*, en esa secuencia.

Nota: *Fiscalizar Establecimiento* ocurre en paralelo con el flujo principal *Evaluar Elegibilidad* a *Egresar Paciente*. *Autorizar Establecimiento* precede a todos.

---

### SD1.1 *Autorizar Establecimiento*

#### Declaración

*Autorizar Establecimiento* cambia **Autorización Sanitaria** de `solicitada` a `otorgada`.

#### Agentes

**SEREMI** maneja *Autorizar Establecimiento*.

#### Instrumentos

*Autorizar Establecimiento* requiere **Solicitud de Autorización**.

#### Objetos consumidos

*Autorizar Establecimiento* consume **Solicitud de Autorización**.

#### Objetos generados

*Autorizar Establecimiento* genera **Autorización Sanitaria** en `otorgada`.

#### Condición

*Autorizar Establecimiento* ocurre si **Solicitud de Autorización** existe, en cuyo caso **Solicitud de Autorización** se consume, de lo contrario *Autorizar Establecimiento* se omite.

#### Antecedentes de la solicitud (objetos consumidos por *Autorizar Establecimiento*)

**Solicitud de Autorización** consta de **Identificación del Establecimiento**, **Documento de Dominio de Inmueble**, **Certificado Municipal**, **Escritura de Constitución**, **Individualización de Director Técnico**, **Nómina de Personal Habilitado**, **Plano de Planta Física**, **Certificado de Instalaciones**, **Listado de Equipos**, **Programa de Mantención Preventiva**, **Listado de Elementos de Protección Personal**, **Horario de Funcionamiento**, **Manual de Normas y Procedimientos**, **Reglamento Interno**, **Autorización de Botiquín**, **Listado de Prestaciones** y **Protocolo de Manejo de Residuos**.

#### Vigencia

**Autorización Sanitaria** exhibe **Vigencia**.
**Vigencia** de **Autorización Sanitaria** varía de 0 a 3 años.

#### Prórroga

*Prorrogar Autorización* cambia **Autorización Sanitaria** de `vigente` a `vigente`.
*Prorrogar Autorización* ocurre si **Autorización Sanitaria** está en `vigente`, en cuyo caso *Prorrogar Autorización* cambia **Autorización Sanitaria** de `vigente` a `vigente`, de lo contrario *Prorrogar Autorización* se omite.

---

### SD1.2 *Evaluar Elegibilidad*

#### Declaración

*Evaluar Elegibilidad* cambia **Paciente** de `agudo o crónico reagudizado` a `estable`.

#### Agentes

**Médico de Atención Directa** maneja *Evaluar Elegibilidad*.
**Enfermero Clínico** maneja *Evaluar Elegibilidad*.
**Trabajador Social** maneja *Evaluar Elegibilidad*.

#### Instrumentos

*Evaluar Elegibilidad* requiere **Ficha Clínica**.

#### Transformaciones

*Evaluar Elegibilidad* afecta **Domicilio**.
*Evaluar Elegibilidad* genera **Informe Social**.

#### Condiciones de elegibilidad

*Evaluar Elegibilidad* ocurre si **Paciente** está en `agudo o crónico reagudizado`, en cuyo caso *Evaluar Elegibilidad* cambia **Paciente** de `agudo o crónico reagudizado` a `estable`, de lo contrario *Evaluar Elegibilidad* se omite.

#### SD1.2.a Descomposición de *Evaluar Elegibilidad*

*Evaluar Elegibilidad* se descompone en *Evaluar Condición Clínica*, *Evaluar Domicilio*, *Evaluar Red de Apoyo* y *Verificar Consentimiento*, en esa secuencia.

##### *Evaluar Condición Clínica*

*Evaluar Condición Clínica* afecta **Paciente**.
**Médico de Atención Directa** maneja *Evaluar Condición Clínica*.

Criterios (de la normativa):
- Patología aguda o crónica reagudizada.
- Clínicamente estable.
- Susceptible de tratamiento en domicilio o adecuación del esfuerzo terapéutico.
- NO: inestabilidad clínica o ausencia de diagnóstico establecido.
- NO: patología de salud mental descompensada.

##### *Evaluar Domicilio*

*Evaluar Domicilio* cambia **Domicilio** de `no evaluado` a `evaluado como apto`.
**Trabajador Social** maneja *Evaluar Domicilio*.

Criterios (de la normativa):
- Condiciones sanitarias mínimas.
- Servicios básicos (agua, electricidad).
- Telefonía.
- Dentro del radio de cobertura.

*Evaluar Domicilio* genera **Informe Social**.
**Informe Social** cambia de `pendiente` a `elaborado`.

##### *Evaluar Red de Apoyo*

*Evaluar Red de Apoyo* afecta **Cuidador**.
**Trabajador Social** maneja *Evaluar Red de Apoyo*.

Criterios (de la normativa):
- Red de apoyo familiar, social o tutor responsable.
- Disponibilidad de cuidador o tutor legal.
- Evaluación de situación económica del grupo familiar.

##### *Verificar Consentimiento*

*Verificar Consentimiento* cambia **Consentimiento Informado** de `pendiente` a `firmado`.
**Enfermero Clínico** maneja *Verificar Consentimiento*.

Criterios (de la normativa):
- Aceptación escrita e informada del paciente, tutor o familiar.
- Entrega de la carta de derechos y deberes.

*Verificar Consentimiento* genera **Consentimiento Informado** en `firmado`.

#### Exclusiones (criterios negativos — condiciones de omisión)

*Evaluar Elegibilidad* se omite si **Paciente** presenta:
- Inestabilidad clínica o ausencia de diagnóstico establecido.
- Patología de salud mental descompensada.
- Necesidad de prestación no incluida en el listado del establecimiento.
- Condición de alta disciplinaria previa.

---

### SD1.3 *Ingresar Paciente*

#### Declaración

*Ingresar Paciente* cambia **Paciente** de `estable` a `ingresado`.

#### Agentes

**Médico de Atención Directa** maneja *Ingresar Paciente*.
**Enfermero Clínico** maneja *Ingresar Paciente*.

#### Instrumentos

*Ingresar Paciente* requiere **Consentimiento Informado** en `firmado`.
*Ingresar Paciente* requiere **Domicilio** en `evaluado como apto`.

#### Objetos generados

*Ingresar Paciente* genera **Formulario de Ingreso**.
*Ingresar Paciente* genera **Plan Terapéutico** en `formulado`.
*Ingresar Paciente* genera **Plan de Cuidados de Enfermería** en `formulado`.
*Ingresar Paciente* genera **Resumen Clínico en Domicilio**.

#### Condición

*Ingresar Paciente* ocurre si **Consentimiento Informado** está en `firmado`, en cuyo caso *Ingresar Paciente* cambia **Paciente** de `estable` a `ingresado`, de lo contrario *Ingresar Paciente* se omite.

#### SD1.3.a Descomposición de *Ingresar Paciente*

*Ingresar Paciente* se descompone en *Formular Plan Terapéutico*, *Formular Plan de Cuidados*, *Registrar Ingreso* y *Entregar Resumen Clínico*, en esa secuencia.

##### *Formular Plan Terapéutico*

*Formular Plan Terapéutico* genera **Plan Terapéutico** en `formulado`.
**Médico de Atención Directa** maneja *Formular Plan Terapéutico*.

##### *Formular Plan de Cuidados*

*Formular Plan de Cuidados* genera **Plan de Cuidados de Enfermería** en `formulado`.
**Enfermero Clínico** maneja *Formular Plan de Cuidados*.

##### *Registrar Ingreso*

*Registrar Ingreso* genera **Formulario de Ingreso**.
*Registrar Ingreso* afecta **Ficha Clínica**.
**Enfermero Clínico** maneja *Registrar Ingreso*.

##### *Entregar Resumen Clínico*

*Entregar Resumen Clínico* genera **Resumen Clínico en Domicilio**.
**Enfermero Clínico** maneja *Entregar Resumen Clínico*.

---

### SD1.4 *Tratar en Domicilio*

#### Declaración

*Tratar en Domicilio* cambia **Paciente** de `ingresado` a `en tratamiento`.
*Tratar en Domicilio* cambia **Plan Terapéutico** de `formulado` a `en ejecución`.
*Tratar en Domicilio* cambia **Plan de Cuidados de Enfermería** de `formulado` a `en ejecución`.

#### Agentes

**Médico de Atención Directa** maneja *Tratar en Domicilio*.
**Enfermero Clínico** maneja *Tratar en Domicilio*.
**Kinesiólogo** maneja *Tratar en Domicilio*.

#### Instrumentos

*Tratar en Domicilio* requiere **Equipamiento Médico** en `operativo`.
*Tratar en Domicilio* requiere **Vehículo de Transporte** en `disponible`.
*Tratar en Domicilio* requiere **Protocolo Clínico**.
*Tratar en Domicilio* requiere **Sistema Telefónico**.
*Tratar en Domicilio* requiere **Ficha Clínica**.

#### Consumos

*Tratar en Domicilio* consume **Insumo Clínico**.
*Tratar en Domicilio* consume **Medicamento**.

#### Resultados

*Tratar en Domicilio* genera **Evolución Clínica**.
*Tratar en Domicilio* genera **Residuo Especial**.

#### SD1.4.a Descomposición de *Tratar en Domicilio*

*Tratar en Domicilio* se descompone en *Programar Visita Domiciliaria*, *Ejecutar Visita Domiciliaria*, *Evaluar Evolución*, *Administrar Tratamiento*, *Gestionar Cuidados de Enfermería*, *Otorgar Terapia Kinesiológica*, *Educar Paciente y Familia*, *Regular a Distancia* y *Registrar Evolución Clínica*, en esa secuencia.

Nota: *Regular a Distancia* ocurre en paralelo con *Ejecutar Visita Domiciliaria*.

##### *Programar Visita Domiciliaria*

*Programar Visita Domiciliaria* genera **Programación de Ruta**.
**Coordinador** maneja *Programar Visita Domiciliaria*.
*Programar Visita Domiciliaria* requiere **Vehículo de Transporte** en `disponible`.

##### *Ejecutar Visita Domiciliaria*

*Ejecutar Visita Domiciliaria* afecta **Paciente**.
**Médico de Atención Directa** maneja *Ejecutar Visita Domiciliaria*.
**Enfermero Clínico** maneja *Ejecutar Visita Domiciliaria*.
*Ejecutar Visita Domiciliaria* requiere **Vehículo de Transporte**.
*Ejecutar Visita Domiciliaria* requiere **Equipamiento Médico** en `operativo`.
*Ejecutar Visita Domiciliaria* requiere **Domicilio** en `evaluado como apto`.

##### *Evaluar Evolución*

*Evaluar Evolución* afecta **Paciente**.
**Enfermero Clínico** maneja *Evaluar Evolución*.
*Evaluar Evolución* requiere **Ficha Clínica**.

##### *Administrar Tratamiento*

*Administrar Tratamiento* consume **Medicamento**.
*Administrar Tratamiento* consume **Insumo Clínico**.
*Administrar Tratamiento* afecta **Paciente**.
**Médico de Atención Directa** maneja *Administrar Tratamiento*.
*Administrar Tratamiento* requiere **Indicación Médica**.
*Administrar Tratamiento* genera **Residuo Especial**.

##### *Gestionar Cuidados de Enfermería*

*Gestionar Cuidados de Enfermería* cambia **Plan de Cuidados de Enfermería** de `formulado` a `en ejecución`.
**Enfermero Clínico** maneja *Gestionar Cuidados de Enfermería*.

##### *Otorgar Terapia Kinesiológica*

*Otorgar Terapia Kinesiológica* afecta **Paciente**.
**Kinesiólogo** maneja *Otorgar Terapia Kinesiológica*.
*Otorgar Terapia Kinesiológica* ocurre si **Indicación Médica** existe, de lo contrario *Otorgar Terapia Kinesiológica* se omite.

##### *Educar Paciente y Familia*

*Educar Paciente y Familia* afecta **Cuidador**.
*Educar Paciente y Familia* afecta **Grupo Familiar**.
**Enfermero Clínico** maneja *Educar Paciente y Familia*.

##### *Regular a Distancia*

*Regular a Distancia* afecta **Paciente**.
**Médico Regulador** maneja *Regular a Distancia*.
*Regular a Distancia* requiere **Sistema Telefónico**.
*Regular a Distancia* requiere **Soporte Informático**.

##### *Registrar Evolución Clínica*

*Registrar Evolución Clínica* genera **Evolución Clínica**.
*Registrar Evolución Clínica* afecta **Ficha Clínica**.
**Enfermero Clínico** maneja *Registrar Evolución Clínica*.
**Médico de Atención Directa** maneja *Registrar Evolución Clínica*.

---

### SD1.5 *Egresar Paciente*

#### Declaración

*Egresar Paciente* cambia **Paciente** de `en tratamiento` a `egresado`.
*Egresar Paciente* cambia **Plan Terapéutico** de `en ejecución` a `cumplido`.

#### Agentes

**Médico de Atención Directa** maneja *Egresar Paciente*.
**Enfermero Clínico** maneja *Egresar Paciente*.

#### Instrumentos

*Egresar Paciente* requiere **Ficha Clínica**.

#### Resultados

*Egresar Paciente* genera **Epicrisis**.
*Egresar Paciente* genera **Encuesta de Satisfacción Usuaria**.
*Egresar Paciente* cambia **Ficha Clínica** de `abierta` a `cerrada`.

#### Causales de egreso (XOR — exactamente una)

*Egresar Paciente* ocurre por exactamente uno de:

1. *Dar Alta Médica* — alta médica por recuperación del cuadro clínico.
2. *Dar Alta por Cumplimiento* — cumplimiento del plan terapéutico y de cuidados.
3. *Reingresar a Hospital* — reingreso hospitalario programado por inestabilidad o complicaciones.
4. *Registrar Fallecimiento* — fallecimiento del paciente.
5. *Registrar Renuncia Voluntaria* — renuncia voluntaria del paciente o representante.
6. *Dar Alta Disciplinaria* — determinada por Dirección Técnica.

#### SD1.5.a Descomposición de *Egresar Paciente*

*Egresar Paciente* se descompone en *Determinar Causal de Egreso*, *Elaborar Epicrisis*, *Aplicar Encuesta de Satisfacción* y *Cerrar Ficha Clínica*, en esa secuencia.

##### *Determinar Causal de Egreso*

*Determinar Causal de Egreso* genera **Causal de Egreso**.
**Médico de Atención Directa** maneja *Determinar Causal de Egreso*.

##### *Elaborar Epicrisis*

*Elaborar Epicrisis* genera **Epicrisis**.
**Médico de Atención Directa** maneja *Elaborar Epicrisis*.

##### *Aplicar Encuesta de Satisfacción*

*Aplicar Encuesta de Satisfacción* cambia **Encuesta de Satisfacción Usuaria** de `pendiente` a `completada`.
**Enfermero Clínico** maneja *Aplicar Encuesta de Satisfacción*.

##### *Cerrar Ficha Clínica*

*Cerrar Ficha Clínica* cambia **Ficha Clínica** de `abierta` a `cerrada`.
**Enfermero Clínico** maneja *Cerrar Ficha Clínica*.

---

### SD1.5.b *Dar Alta Disciplinaria* — Condiciones (OR)

*Dar Alta Disciplinaria* ocurre si al menos uno de:
- **Paciente** presenta no adherencia al tratamiento o indicaciones.
- **Cuidador** presenta conductas irrespetuosas hacia **Personal de Salud**.
- **Paciente** presenta falta de respuesta o rechazo a visitas domiciliarias.

**Director Técnico** maneja *Dar Alta Disciplinaria*.

---

### SD1.5.c *Reingresar a Hospital*

*Reingresar a Hospital* cambia **Paciente** de `en tratamiento` a `reinternado`.
**Médico de Atención Directa** maneja *Reingresar a Hospital*.
*Reingresar a Hospital* requiere **Vehículo de Transporte** en `disponible`.
*Reingresar a Hospital* requiere **Establecimiento de Atención Cerrada**.

---

### SD1.6 *Fiscalizar Establecimiento*

#### Declaración

*Fiscalizar Establecimiento* afecta **Sistema de Hospitalización Domiciliaria**.

#### Agentes

**SEREMI** maneja *Fiscalizar Establecimiento*.

#### Instrumentos

*Fiscalizar Establecimiento* requiere **Autorización Sanitaria** en `otorgada`.

#### Nota

*Fiscalizar Establecimiento* es un proceso paralelo que ocurre independientemente del flujo clínico principal. Las contravenciones se sancionan según el Libro X del Código Sanitario.

---

## SD2 — Descomposición de *Autorizar Establecimiento*

*Autorizar Establecimiento* se descompone en *Presentar Solicitud*, *Evaluar Antecedentes*, *Otorgar Autorización* y *Renovar Autorización*, en esa secuencia.

### *Presentar Solicitud*

*Presentar Solicitud* genera **Solicitud de Autorización**.
**Director Técnico** maneja *Presentar Solicitud*.
*Presentar Solicitud* consume **Identificación del Establecimiento**.
*Presentar Solicitud* consume **Documento de Dominio de Inmueble**.
*Presentar Solicitud* consume **Certificado Municipal**.
*Presentar Solicitud* consume **Escritura de Constitución**.
*Presentar Solicitud* consume **Individualización de Director Técnico**.
*Presentar Solicitud* consume **Nómina de Personal Habilitado**.
*Presentar Solicitud* consume **Plano de Planta Física**.
*Presentar Solicitud* consume **Certificado de Instalaciones**.
*Presentar Solicitud* consume **Listado de Equipos**.
*Presentar Solicitud* consume **Programa de Mantención Preventiva**.
*Presentar Solicitud* consume **Listado de Elementos de Protección Personal**.
*Presentar Solicitud* consume **Horario de Funcionamiento**.
*Presentar Solicitud* consume **Manual de Normas y Procedimientos**.
*Presentar Solicitud* consume **Reglamento Interno**.
*Presentar Solicitud* consume **Listado de Prestaciones**.
*Presentar Solicitud* consume **Protocolo de Manejo de Residuos**.

### *Evaluar Antecedentes*

*Evaluar Antecedentes* consume **Solicitud de Autorización**.
**SEREMI** maneja *Evaluar Antecedentes*.

### *Otorgar Autorización*

*Otorgar Autorización* genera **Autorización Sanitaria** en `otorgada`.
**SEREMI** maneja *Otorgar Autorización*.

### *Renovar Autorización*

*Renovar Autorización* cambia **Autorización Sanitaria** de `vigente` a `vigente`.
*Renovar Autorización* se invoca a sí mismo.
**SEREMI** maneja *Renovar Autorización*.

---

## SD3 — Gestión de Dirección Técnica

### Declaración del proceso

*Dirigir Técnicamente* afecta **Sistema de Hospitalización Domiciliaria**.
**Director Técnico** maneja *Dirigir Técnicamente*.

### Requisitos del Director Técnico

**Director Técnico** es físico.
**Director Técnico** exhibe **Habilitación Profesional**, **Experiencia Clínica** y **Jornada Semanal**.
**Experiencia Clínica** de **Director Técnico** varía de 2 a 99 años.
**Jornada Semanal** de **Director Técnico** varía de 22 a 45 horas.

### Descomposición de *Dirigir Técnicamente*

*Dirigir Técnicamente* se descompone en *Aprobar Manuales*, *Aprobar Turnos*, *Mantener Stock*, *Verificar Mantención de Equipos*, *Supervisar IAAS*, *Gestionar Calidad*, *Gestionar Capacitación*, *Coordinar con Derivadores* y *Asegurar Traslado Oportuno*, en esa secuencia.

#### *Aprobar Manuales*

*Aprobar Manuales* afecta **Manual de Normas y Procedimientos**.
*Aprobar Manuales* afecta **Manual de Organización Interna**.
*Aprobar Manuales* afecta **Protocolo Clínico**.
**Director Técnico** maneja *Aprobar Manuales*.

#### *Aprobar Turnos*

*Aprobar Turnos* afecta **Horario de Funcionamiento**.
**Director Técnico** maneja *Aprobar Turnos*.

#### *Mantener Stock*

*Mantener Stock* afecta **Medicamento**.
*Mantener Stock* afecta **Insumo Clínico**.
**Director Técnico** maneja *Mantener Stock*.
*Mantener Stock* requiere **Farmacia o Botiquín**.
*Mantener Stock* requiere **Bodega de Insumos**.

#### *Verificar Mantención de Equipos*

*Verificar Mantención de Equipos* afecta **Equipamiento Médico**.
*Verificar Mantención de Equipos* afecta **Vehículo de Transporte**.
**Director Técnico** maneja *Verificar Mantención de Equipos*.
*Verificar Mantención de Equipos* requiere **Programa de Mantención Preventiva**.

#### *Supervisar IAAS*

*Supervisar IAAS* afecta **Programa de Prevención de IAAS**.
**Director Técnico** maneja *Supervisar IAAS*.

#### *Gestionar Calidad*

*Gestionar Calidad* afecta **Sistema de Hospitalización Domiciliaria**.
**Director Técnico** maneja *Gestionar Calidad*.

#### *Gestionar Capacitación*

*Gestionar Capacitación* afecta **Personal de Salud**.
*Gestionar Capacitación* requiere **Plan de Capacitación Anual**.
**Director Técnico** maneja *Gestionar Capacitación*.

#### *Coordinar con Derivadores*

*Coordinar con Derivadores* afecta **Paciente**.
**Director Técnico** maneja *Coordinar con Derivadores*.
*Coordinar con Derivadores* requiere **Institución Derivadora**.
*Coordinar con Derivadores* requiere **Médico Tratante**.

#### *Asegurar Traslado Oportuno*

*Asegurar Traslado Oportuno* afecta **Paciente**.
**Director Técnico** maneja *Asegurar Traslado Oportuno*.
*Asegurar Traslado Oportuno* requiere **Vehículo de Transporte** en `disponible`.
*Asegurar Traslado Oportuno* requiere **Establecimiento de Atención Cerrada**.

---

## SD4 — Gestión de Coordinación

### Declaración

*Coordinar Operaciones* afecta **Sistema de Hospitalización Domiciliaria**.
**Coordinador** maneja *Coordinar Operaciones*.

### Requisitos del Coordinador

**Coordinador** es físico.
**Coordinador** exhibe **Experiencia Clínica**, **Formación en Gestión** y **Capacitación IAAS**.
**Experiencia Clínica** de **Coordinador** varía de 5 a 99 años.

### Descomposición de *Coordinar Operaciones*

*Coordinar Operaciones* se descompone en *Supervisar Manuales*, *Supervisar Procesos Clínicos*, *Gestionar Personal*, *Supervisar Calidad de Cuidados*, *Gestionar Insumos Operacionales* y *Coordinar Continuidad Asistencial*, en esa secuencia.

#### *Supervisar Manuales*

*Supervisar Manuales* afecta **Manual de Organización Interna**.
**Coordinador** maneja *Supervisar Manuales*.

#### *Supervisar Procesos Clínicos*

*Supervisar Procesos Clínicos* afecta **Ficha Clínica**.
**Coordinador** maneja *Supervisar Procesos Clínicos*.

#### *Gestionar Personal*

*Gestionar Personal* afecta **Personal de Salud**.
**Coordinador** maneja *Gestionar Personal*.

#### *Supervisar Calidad de Cuidados*

*Supervisar Calidad de Cuidados* afecta **Plan de Cuidados de Enfermería**.
**Coordinador** maneja *Supervisar Calidad de Cuidados*.

#### *Gestionar Insumos Operacionales*

*Gestionar Insumos Operacionales* afecta **Equipamiento Médico**.
*Gestionar Insumos Operacionales* afecta **Insumo Clínico**.
**Coordinador** maneja *Gestionar Insumos Operacionales*.
*Gestionar Insumos Operacionales* requiere **Programa de Mantención Preventiva**.

#### *Coordinar Continuidad Asistencial*

*Coordinar Continuidad Asistencial* afecta **Paciente**.
**Coordinador** maneja *Coordinar Continuidad Asistencial*.
*Coordinar Continuidad Asistencial* requiere **Institución Derivadora**.
*Coordinar Continuidad Asistencial* requiere **Establecimiento de Atención Cerrada**.

---

## SD5 — Gestión de Registros y Protocolos

### Declaración

*Gestionar Registros* afecta **Ficha Clínica**.
*Gestionar Registros* genera **Registro de Llamadas**.

### Descomposición de *Gestionar Registros*

*Gestionar Registros* se descompone en *Mantener Ficha Clínica*, *Registrar Consentimiento*, *Mantener Resumen Clínico*, *Registrar Llamadas* y *Resguardar Confidencialidad*, en esa secuencia.

#### *Mantener Ficha Clínica*

*Mantener Ficha Clínica* afecta **Ficha Clínica**.
**Ficha Clínica** puede estar `física` o `electrónica`.
*Mantener Ficha Clínica* requiere **Soporte Informático**.
**Enfermero Clínico** maneja *Mantener Ficha Clínica*.
**Médico de Atención Directa** maneja *Mantener Ficha Clínica*.

#### *Registrar Consentimiento*

*Registrar Consentimiento* genera **Consentimiento Informado** en `firmado`.
*Registrar Consentimiento* afecta **Carta de Derechos y Deberes**.
**Enfermero Clínico** maneja *Registrar Consentimiento*.

#### *Mantener Resumen Clínico*

*Mantener Resumen Clínico* afecta **Resumen Clínico en Domicilio**.
**Enfermero Clínico** maneja *Mantener Resumen Clínico*.

#### *Registrar Llamadas*

*Registrar Llamadas* genera **Registro de Llamadas**.
*Registrar Llamadas* requiere **Sistema Telefónico**.
**Registro de Llamadas** exhibe **Fecha**, **Hora**, **Emisor**, **Receptor** y **Derivación**.

#### *Resguardar Confidencialidad*

*Resguardar Confidencialidad* afecta **Ficha Clínica**.
**Director Técnico** maneja *Resguardar Confidencialidad*.

---

## SD6 — Gestión de Capacitación e Inducción

### Declaración

*Capacitar Personal* afecta **Personal de Salud**.
**Director Técnico** maneja *Capacitar Personal*.
*Capacitar Personal* requiere **Plan de Capacitación Anual**.

### Descomposición de *Capacitar Personal*

*Capacitar Personal* se descompone en *Inducir Personal Nuevo*, *Capacitar en IAAS*, *Capacitar en RCP*, *Certificar Uso de Desfibrilador* y *Capacitar en Humanización del Cuidado*, en esa secuencia.

#### *Inducir Personal Nuevo*

*Inducir Personal Nuevo* afecta **Personal de Salud**.
**Coordinador** maneja *Inducir Personal Nuevo*.

Parámetro normativo: duración mínima 44 horas, carácter teórico-práctico. Registro obligatorio en hoja de vida.

#### *Capacitar en IAAS*

*Capacitar en IAAS* afecta **Personal de Salud**.
*Capacitar en IAAS* requiere **Programa de Prevención de IAAS**.

Parámetro normativo: curso de al menos 80 horas.

#### *Capacitar en RCP*

*Capacitar en RCP* afecta **Personal de Salud**.

Parámetro normativo: curso de 3 horas. Vigencia 5 años.

#### *Certificar Uso de Desfibrilador*

*Certificar Uso de Desfibrilador* afecta **Personal de Salud**.
*Certificar Uso de Desfibrilador* requiere **Desfibrilador**.

#### *Capacitar en Humanización del Cuidado*

*Capacitar en Humanización del Cuidado* afecta **Personal de Salud**.

---

## SD7 — Gestión de Manejo de Residuos

### Declaración

*Gestionar Residuos* cambia **Residuo Especial** de `generado` a `retirado`.

### Descomposición de *Gestionar Residuos*

*Gestionar Residuos* se descompone en *Almacenar Transitoriamente*, *Retirar Residuos* y *Eliminar Residuos*, en esa secuencia.

#### *Almacenar Transitoriamente*

*Almacenar Transitoriamente* cambia **Residuo Especial** de `generado` a `almacenado transitoriamente`.
*Almacenar Transitoriamente* requiere **Área de Residuos**.

#### *Retirar Residuos*

*Retirar Residuos* cambia **Residuo Especial** de `almacenado transitoriamente` a `retirado`.

#### *Eliminar Residuos*

*Eliminar Residuos* consume **Residuo Especial** en `retirado`.

---

## SD8 — Gestión de Mantención de Equipos y Vehículos

### Declaración

*Mantener Equipos* cambia **Equipamiento Médico** de `fuera de servicio` a `operativo`.
*Mantener Equipos* cambia **Vehículo de Transporte** de `en mantención` a `disponible`.

### Descomposición de *Mantener Equipos*

*Mantener Equipos* se descompone en *Ejecutar Mantención Preventiva* y *Reparar Equipo*, en esa secuencia.

#### *Ejecutar Mantención Preventiva*

*Ejecutar Mantención Preventiva* afecta **Equipamiento Médico**.
*Ejecutar Mantención Preventiva* afecta **Vehículo de Transporte**.
*Ejecutar Mantención Preventiva* requiere **Programa de Mantención Preventiva**.

#### *Reparar Equipo*

*Reparar Equipo* cambia **Equipamiento Médico** de `fuera de servicio` a `operativo`.

---

## SD9 — Gestión de Medicamentos e Insumos

### Declaración

*Abastecer Farmacia* cambia **Medicamento** de `agotado` a `disponible`.
*Abastecer Farmacia* afecta **Insumo Clínico**.

### Descomposición de *Abastecer Farmacia*

*Abastecer Farmacia* se descompone en *Controlar Stock*, *Adquirir Medicamentos*, *Almacenar con Cadena de Frío* y *Dispensar en Domicilio*, en esa secuencia.

#### *Controlar Stock*

*Controlar Stock* afecta **Medicamento**.
*Controlar Stock* afecta **Insumo Clínico**.
**Director Técnico** maneja *Controlar Stock*.

#### *Adquirir Medicamentos*

*Adquirir Medicamentos* genera **Medicamento** en `disponible`.
*Adquirir Medicamentos* requiere **Convenio**.

#### *Almacenar con Cadena de Frío*

*Almacenar con Cadena de Frío* afecta **Medicamento**.
*Almacenar con Cadena de Frío* requiere **Bodega de Insumos**.
*Almacenar con Cadena de Frío* requiere **Farmacia o Botiquín**.

#### *Dispensar en Domicilio*

*Dispensar en Domicilio* consume **Medicamento** en `disponible`.
*Dispensar en Domicilio* afecta **Paciente**.
*Dispensar en Domicilio* requiere **Receta**.

---

## SD10 — Gestión de Emergencias y Agudización

### Declaración

*Manejar Emergencia* cambia **Paciente** de `en tratamiento` a `reinternado`.

### Descomposición de *Manejar Emergencia*

*Manejar Emergencia* se descompone en *Detectar Agudización*, *Coordinar Reingreso* y *Trasladar Paciente*, en esa secuencia.

#### *Detectar Agudización*

*Detectar Agudización* afecta **Paciente**.
**Médico de Atención Directa** maneja *Detectar Agudización*.
**Médico Regulador** maneja *Detectar Agudización*.
*Detectar Agudización* requiere **Sistema Telefónico**.

#### *Coordinar Reingreso*

*Coordinar Reingreso* afecta **Paciente**.
**Médico de Atención Directa** maneja *Coordinar Reingreso*.
*Coordinar Reingreso* requiere **Médico Tratante**.
*Coordinar Reingreso* requiere **Establecimiento de Atención Cerrada**.

#### *Trasladar Paciente*

*Trasladar Paciente* cambia **Paciente** de `en tratamiento` a `reinternado`.
*Trasladar Paciente* requiere **Vehículo de Transporte** en `disponible`.
**Director Técnico** maneja *Trasladar Paciente*.

---

## SD11 — Procedimientos Clínicos Específicos (Norma Técnica)

### Declaración

Los protocolos clínicos obligatorios definen procedimientos específicos que forman parte de *Tratar en Domicilio*.

### Procesos de procedimiento

*Manejar Vía Venosa Periférica* afecta **Paciente**.
**Enfermero Clínico** maneja *Manejar Vía Venosa Periférica*.
*Manejar Vía Venosa Periférica* consume **Insumo Clínico**.
*Manejar Vía Venosa Periférica* requiere **Manual de Procedimientos**.

*Manejar Vía Venosa Central* afecta **Paciente**.
**Enfermero Clínico** maneja *Manejar Vía Venosa Central*.
*Manejar Vía Venosa Central* consume **Insumo Clínico**.
*Manejar Vía Venosa Central* requiere **Manual de Procedimientos**.

*Manejar Catéter Urinario* afecta **Paciente**.
**Enfermero Clínico** maneja *Manejar Catéter Urinario*.
*Manejar Catéter Urinario* consume **Insumo Clínico**.

*Manejar Traqueostomía* afecta **Paciente**.
**Enfermero Clínico** maneja *Manejar Traqueostomía*.
**Kinesiólogo** maneja *Manejar Traqueostomía*.
*Manejar Traqueostomía* consume **Insumo Clínico**.

*Tomar Muestras* afecta **Paciente**.
*Tomar Muestras* genera **Muestra Clínica**.
**Enfermero Clínico** maneja *Tomar Muestras*.

*Aplicar Precauciones de Aislamiento* afecta **Paciente**.
**Enfermero Clínico** maneja *Aplicar Precauciones de Aislamiento*.
*Aplicar Precauciones de Aislamiento* requiere **Elemento de Protección Personal**.
*Aplicar Precauciones de Aislamiento* requiere **Protocolo Clínico**.

---

## SD12 — Uso de Tecnologías de Información y Comunicación

### Declaración (DS 1/2022 Art. 12)

*Atender con TIC* afecta **Paciente**.
**Médico de Atención Directa** maneja *Atender con TIC*.
**Médico Regulador** maneja *Atender con TIC*.
*Atender con TIC* requiere **Soporte Informático**.
*Atender con TIC* requiere **Sistema Telefónico**.

Alcance clínico: diagnóstico, tratamiento, prevención y rehabilitación. Otros profesionales designados por Dirección Técnica también pueden utilizar TIC.

---

## Tablas Consolidadas

### Tabla de Objetos

| Objeto | Esencia | Afiliación | Estados |
|--------|---------|------------|---------|
| **Paciente** | Física | Sistémica | `sano`, `agudo o crónico reagudizado`, `estable`, `ingresado`, `en tratamiento`, `recuperado`, `reinternado`, `fallecido`, `egresado` |
| **Condición Clínica** | Informática | Sistémica | `agudo o crónico reagudizado`, `recuperado` |
| **Cuidador** | Física | Sistémica | — |
| **Grupo Familiar** | Física | Sistémica | — |
| **Consentimiento Informado** | Informática | Sistémica | `pendiente`, `firmado` |
| **Ficha Clínica** | Informática | Sistémica | `abierta`, `cerrada` |
| **Plan Terapéutico** | Informática | Sistémica | `formulado`, `en ejecución`, `cumplido` |
| **Plan de Cuidados de Enfermería** | Informática | Sistémica | `formulado`, `en ejecución`, `cumplido` |
| **Epicrisis** | Informática | Sistémica | — |
| **Resumen Clínico en Domicilio** | Informática | Sistémica | — |
| **Indicación Médica** | Informática | Sistémica | — |
| **Receta** | Informática | Sistémica | — |
| **Interconsulta** | Informática | Sistémica | — |
| **Informe Social** | Informática | Sistémica | `pendiente`, `elaborado` |
| **Encuesta de Satisfacción Usuaria** | Informática | Sistémica | `pendiente`, `completada` |
| **Formulario de Ingreso** | Informática | Sistémica | — |
| **Carta de Derechos y Deberes** | Informática | Sistémica | — |
| **Manual de Normas y Procedimientos** | Informática | Sistémica | — |
| **Manual de Organización Interna** | Informática | Sistémica | — |
| **Protocolo Clínico** | Informática | Sistémica | — |
| **Manual de Procedimientos** | Informática | Sistémica | — |
| **Plan de Capacitación Anual** | Informática | Sistémica | — |
| **Programa de Prevención de IAAS** | Informática | Sistémica | — |
| **Programa de Mantención Preventiva** | Informática | Sistémica | — |
| **Autorización Sanitaria** | Informática | Sistémica | `solicitada`, `otorgada`, `vigente`, `vencida`, `sin efecto` |
| **Convenio** | Informática | Sistémica | — |
| **Registro de Llamadas** | Informática | Sistémica | — |
| **Domicilio** | Física | Sistémica | `no evaluado`, `evaluado como apto`, `evaluado como no apto` |
| **Dependencia Administrativa** | Física | Sistémica | — |
| **Bodega de Insumos** | Física | Sistémica | — |
| **Farmacia o Botiquín** | Física | Sistémica | — |
| **Vehículo de Transporte** | Física | Sistémica | `disponible`, `en ruta`, `en mantención` |
| **Equipamiento Médico** | Física | Sistémica | `operativo`, `en mantención`, `fuera de servicio` |
| **Dispositivo de Uso Médico** | Física | Sistémica | — |
| **Insumo Clínico** | Física | Sistémica | — |
| **Medicamento** | Física | Sistémica | `disponible`, `administrado`, `agotado` |
| **Residuo Especial** | Física | Sistémica | `generado`, `almacenado transitoriamente`, `retirado` |
| **Elemento de Protección Personal** | Física | Sistémica | — |
| **Sistema Telefónico** | Física | Sistémica | — |
| **Soporte Informático** | Informática | Sistémica | — |
| **Evolución Clínica** | Informática | Sistémica | — |
| **Programación de Ruta** | Informática | Sistémica | — |
| **Causal de Egreso** | Informática | Sistémica | — |
| **Solicitud de Autorización** | Informática | Sistémica | — |
| **Muestra Clínica** | Física | Sistémica | — |
| **SEREMI** | Física | Ambiental | — |
| **Establecimiento de Atención Cerrada** | Física | Ambiental | — |
| **Superintendencia de Salud** | Informática | Ambiental | — |
| **MINSAL** | Física | Ambiental | — |
| **Servicio de Salud** | Física | Ambiental | — |
| **Institución Derivadora** | Física | Ambiental | — |
| **Médico Tratante** | Física | Ambiental | — |

### Tabla de Procesos

| Proceso | Nivel SD | Transformees |
|---------|----------|-------------|
| *Hospitalizar en Domicilio* | SD | **Condición Clínica**, **Insumo Clínico**, **Medicamento** |
| *Enfermar* | SD (ambiental) | **Condición Clínica** |
| *Autorizar Establecimiento* | SD1 | **Autorización Sanitaria** |
| *Evaluar Elegibilidad* | SD1 | **Paciente**, **Domicilio** |
| *Ingresar Paciente* | SD1 | **Paciente** |
| *Tratar en Domicilio* | SD1 | **Paciente**, **Plan Terapéutico**, **Plan de Cuidados de Enfermería** |
| *Egresar Paciente* | SD1 | **Paciente**, **Plan Terapéutico**, **Ficha Clínica** |
| *Fiscalizar Establecimiento* | SD1 | **Sistema de Hospitalización Domiciliaria** |
| *Evaluar Condición Clínica* | SD1.2.a | **Paciente** |
| *Evaluar Domicilio* | SD1.2.a | **Domicilio** |
| *Evaluar Red de Apoyo* | SD1.2.a | **Cuidador** |
| *Verificar Consentimiento* | SD1.2.a | **Consentimiento Informado** |
| *Formular Plan Terapéutico* | SD1.3.a | **Plan Terapéutico** |
| *Formular Plan de Cuidados* | SD1.3.a | **Plan de Cuidados de Enfermería** |
| *Registrar Ingreso* | SD1.3.a | **Ficha Clínica** |
| *Entregar Resumen Clínico* | SD1.3.a | **Resumen Clínico en Domicilio** |
| *Programar Visita Domiciliaria* | SD1.4.a | **Programación de Ruta** |
| *Ejecutar Visita Domiciliaria* | SD1.4.a | **Paciente** |
| *Evaluar Evolución* | SD1.4.a | **Paciente** |
| *Administrar Tratamiento* | SD1.4.a | **Paciente**, **Medicamento**, **Insumo Clínico** |
| *Gestionar Cuidados de Enfermería* | SD1.4.a | **Plan de Cuidados de Enfermería** |
| *Otorgar Terapia Kinesiológica* | SD1.4.a | **Paciente** |
| *Educar Paciente y Familia* | SD1.4.a | **Cuidador**, **Grupo Familiar** |
| *Regular a Distancia* | SD1.4.a | **Paciente** |
| *Registrar Evolución Clínica* | SD1.4.a | **Ficha Clínica** |
| *Determinar Causal de Egreso* | SD1.5.a | **Causal de Egreso** |
| *Elaborar Epicrisis* | SD1.5.a | **Epicrisis** |
| *Aplicar Encuesta de Satisfacción* | SD1.5.a | **Encuesta de Satisfacción Usuaria** |
| *Cerrar Ficha Clínica* | SD1.5.a | **Ficha Clínica** |
| *Dar Alta Médica* | SD1.5.b | **Paciente** |
| *Dar Alta por Cumplimiento* | SD1.5.b | **Paciente** |
| *Reingresar a Hospital* | SD1.5.c | **Paciente** |
| *Registrar Fallecimiento* | SD1.5.b | **Paciente** |
| *Registrar Renuncia Voluntaria* | SD1.5.b | **Paciente** |
| *Dar Alta Disciplinaria* | SD1.5.b | **Paciente** |
| *Presentar Solicitud* | SD2 | **Solicitud de Autorización** |
| *Evaluar Antecedentes* | SD2 | **Solicitud de Autorización** |
| *Otorgar Autorización* | SD2 | **Autorización Sanitaria** |
| *Renovar Autorización* | SD2 | **Autorización Sanitaria** |
| *Dirigir Técnicamente* | SD3 | **Sistema de Hospitalización Domiciliaria** |
| *Aprobar Manuales* | SD3 | **Manual de Normas y Procedimientos**, **Manual de Organización Interna**, **Protocolo Clínico** |
| *Aprobar Turnos* | SD3 | **Horario de Funcionamiento** |
| *Mantener Stock* | SD3 | **Medicamento**, **Insumo Clínico** |
| *Verificar Mantención de Equipos* | SD3 | **Equipamiento Médico**, **Vehículo de Transporte** |
| *Supervisar IAAS* | SD3 | **Programa de Prevención de IAAS** |
| *Gestionar Calidad* | SD3 | **Sistema de Hospitalización Domiciliaria** |
| *Gestionar Capacitación* | SD3 | **Personal de Salud** |
| *Coordinar con Derivadores* | SD3 | **Paciente** |
| *Asegurar Traslado Oportuno* | SD3 | **Paciente** |
| *Coordinar Operaciones* | SD4 | **Sistema de Hospitalización Domiciliaria** |
| *Supervisar Manuales* | SD4 | **Manual de Organización Interna** |
| *Supervisar Procesos Clínicos* | SD4 | **Ficha Clínica** |
| *Gestionar Personal* | SD4 | **Personal de Salud** |
| *Supervisar Calidad de Cuidados* | SD4 | **Plan de Cuidados de Enfermería** |
| *Gestionar Insumos Operacionales* | SD4 | **Equipamiento Médico**, **Insumo Clínico** |
| *Coordinar Continuidad Asistencial* | SD4 | **Paciente** |
| *Gestionar Registros* | SD5 | **Ficha Clínica** |
| *Mantener Ficha Clínica* | SD5 | **Ficha Clínica** |
| *Registrar Consentimiento* | SD5 | **Consentimiento Informado** |
| *Mantener Resumen Clínico* | SD5 | **Resumen Clínico en Domicilio** |
| *Registrar Llamadas* | SD5 | **Registro de Llamadas** |
| *Resguardar Confidencialidad* | SD5 | **Ficha Clínica** |
| *Capacitar Personal* | SD6 | **Personal de Salud** |
| *Inducir Personal Nuevo* | SD6 | **Personal de Salud** |
| *Capacitar en IAAS* | SD6 | **Personal de Salud** |
| *Capacitar en RCP* | SD6 | **Personal de Salud** |
| *Certificar Uso de Desfibrilador* | SD6 | **Personal de Salud** |
| *Capacitar en Humanización del Cuidado* | SD6 | **Personal de Salud** |
| *Gestionar Residuos* | SD7 | **Residuo Especial** |
| *Almacenar Transitoriamente* | SD7 | **Residuo Especial** |
| *Retirar Residuos* | SD7 | **Residuo Especial** |
| *Eliminar Residuos* | SD7 | **Residuo Especial** |
| *Mantener Equipos* | SD8 | **Equipamiento Médico**, **Vehículo de Transporte** |
| *Ejecutar Mantención Preventiva* | SD8 | **Equipamiento Médico**, **Vehículo de Transporte** |
| *Reparar Equipo* | SD8 | **Equipamiento Médico** |
| *Abastecer Farmacia* | SD9 | **Medicamento**, **Insumo Clínico** |
| *Controlar Stock* | SD9 | **Medicamento**, **Insumo Clínico** |
| *Adquirir Medicamentos* | SD9 | **Medicamento** |
| *Almacenar con Cadena de Frío* | SD9 | **Medicamento** |
| *Dispensar en Domicilio* | SD9 | **Medicamento**, **Paciente** |
| *Manejar Emergencia* | SD10 | **Paciente** |
| *Detectar Agudización* | SD10 | **Paciente** |
| *Coordinar Reingreso* | SD10 | **Paciente** |
| *Trasladar Paciente* | SD10 | **Paciente** |
| *Manejar Vía Venosa Periférica* | SD11 | **Paciente** |
| *Manejar Vía Venosa Central* | SD11 | **Paciente** |
| *Manejar Catéter Urinario* | SD11 | **Paciente** |
| *Manejar Traqueostomía* | SD11 | **Paciente** |
| *Tomar Muestras* | SD11 | **Paciente** |
| *Aplicar Precauciones de Aislamiento* | SD11 | **Paciente** |
| *Atender con TIC* | SD12 | **Paciente** |

### Tabla de Agentes

| Agente | Procesos que maneja |
|--------|-------------------|
| **Director Técnico** | *Hospitalizar en Domicilio*, *Dirigir Técnicamente*, *Aprobar Manuales*, *Aprobar Turnos*, *Mantener Stock*, *Verificar Mantención de Equipos*, *Supervisar IAAS*, *Gestionar Calidad*, *Gestionar Capacitación*, *Coordinar con Derivadores*, *Asegurar Traslado Oportuno*, *Dar Alta Disciplinaria*, *Trasladar Paciente*, *Capacitar Personal*, *Controlar Stock*, *Resguardar Confidencialidad* |
| **Coordinador** | *Hospitalizar en Domicilio*, *Coordinar Operaciones*, *Supervisar Manuales*, *Supervisar Procesos Clínicos*, *Gestionar Personal*, *Supervisar Calidad de Cuidados*, *Gestionar Insumos Operacionales*, *Coordinar Continuidad Asistencial*, *Programar Visita Domiciliaria*, *Inducir Personal Nuevo* |
| **Médico de Atención Directa** | *Hospitalizar en Domicilio*, *Evaluar Elegibilidad*, *Evaluar Condición Clínica*, *Ingresar Paciente*, *Tratar en Domicilio*, *Ejecutar Visita Domiciliaria*, *Administrar Tratamiento*, *Egresar Paciente*, *Determinar Causal de Egreso*, *Elaborar Epicrisis*, *Reingresar a Hospital*, *Detectar Agudización*, *Coordinar Reingreso*, *Registrar Evolución Clínica*, *Mantener Ficha Clínica*, *Formular Plan Terapéutico*, *Atender con TIC* |
| **Médico Regulador** | *Regular a Distancia*, *Detectar Agudización*, *Atender con TIC* |
| **Enfermero Clínico** | *Hospitalizar en Domicilio*, *Evaluar Elegibilidad*, *Verificar Consentimiento*, *Ingresar Paciente*, *Tratar en Domicilio*, *Evaluar Evolución*, *Gestionar Cuidados de Enfermería*, *Educar Paciente y Familia*, *Egresar Paciente*, *Aplicar Encuesta de Satisfacción*, *Cerrar Ficha Clínica*, *Ejecutar Visita Domiciliaria*, *Registrar Evolución Clínica*, *Mantener Ficha Clínica*, *Registrar Consentimiento*, *Mantener Resumen Clínico*, *Formular Plan de Cuidados*, *Registrar Ingreso*, *Entregar Resumen Clínico*, *Manejar Vía Venosa Periférica*, *Manejar Vía Venosa Central*, *Manejar Catéter Urinario*, *Manejar Traqueostomía*, *Tomar Muestras*, *Aplicar Precauciones de Aislamiento* |
| **Kinesiólogo** | *Tratar en Domicilio*, *Otorgar Terapia Kinesiológica*, *Manejar Traqueostomía* |
| **Trabajador Social** | *Evaluar Elegibilidad*, *Evaluar Domicilio*, *Evaluar Red de Apoyo* |
| **SEREMI** | *Autorizar Establecimiento*, *Evaluar Antecedentes*, *Otorgar Autorización*, *Renovar Autorización*, *Fiscalizar Establecimiento* |

---

## Verificación del SD

| Verificación | Condición | Resultado |
|-------------|-----------|-----------|
| Sistema clasificado | Socio-técnico | PASS |
| Propósito definido | **Paciente** + **Condición Clínica** + `agudo o crónico reagudizado` a `recuperado` | PASS |
| Función definida | *Hospitalizar en Domicilio* + **Condición Clínica** | PASS |
| Habilitadores presentes | 8 agentes + 6 instrumentos en SD | PASS |
| Entorno identificado | **SEREMI**, **Establecimiento de Atención Cerrada**, **Institución Derivadora**, **Médico Tratante**, **MINSAL**, **Servicio de Salud**, **Superintendencia de Salud** | PASS |
| Ocurrencia del problema | *Enfermar* cambia **Condición Clínica** de `sano` a `agudo o crónico reagudizado` | PASS |
| OPL legible | Sentencias OPL-ES correctas con tipografía canónica | PASS |
| Nombres conformes | Procesos en infinitivo, objetos en singular, plurales con Grupo/Conjunto | PASS |
| Exhibición del sistema | **Sistema de Hospitalización Domiciliaria** exhibe *Hospitalizar en Domicilio* | PASS |
| Agentes = humanos | Todos los agentes son profesionales humanos de salud o SEREMI (autoridad humana) | PASS |

## Verificación del SD1

| Verificación | Condición | Resultado |
|-------------|-----------|-----------|
| Subprocesos transforman | Cada subproceso tiene al menos 1 transformee | PASS |
| Tipo de refinamiento correcto | In-zooming (secuencia temporal definida) | PASS |
| Links distribuidos | Consumo/resultado no están en contorno externo | PASS |
| Estados expresados | Estados relevantes visibles en cada transición | PASS |
| Sin redundancia | Sin duplicación innecesaria | PASS |

---

## Trazabilidad Normativa

| Fuente | Secciones modeladas |
|--------|-------------------|
| DS 1/2022 Arts. 1-3 | SD: concepto, ámbito, función principal |
| DS 1/2022 Arts. 4-6 | SD2: autorización sanitaria, antecedentes |
| DS 1/2022 Arts. 7-10 | SD3: dirección técnica |
| DS 1/2022 Art. 11 | SD4: coordinación |
| DS 1/2022 Arts. 12-14 | SD: agentes, generalización de personal |
| DS 1/2022 Arts. 15-17 | SD1.2, SD1.5: elegibilidad, egreso, exclusiones |
| DS 1/2022 Arts. 18-25 | SD5, SD7, SD8: registros, residuos, equipamiento, fiscalización |
| Decreto Exento 31/2024 | SD: marco jurídico, publicación |
| Norma Técnica 2024 — Personal | SD6: capacitación, inducción, requisitos por cargo |
| Norma Técnica 2024 — Infraestructura | SD: agregación de dependencia administrativa |
| Norma Técnica 2024 — Equipamiento | SD8, SD: equipamiento mínimo |
| Norma Técnica 2024 — Registros | SD5: ficha clínica, consentimiento, resumen clínico |
| Norma Técnica 2024 — Protocolos | SD11: procedimientos clínicos específicos |
| Norma Técnica 2024 — PAC | SD6: plan de capacitación anual |

---

## Jerarquía de OPDs

```
SD — Hospitalización Domiciliaria (función + propósito + entorno + problema)
├── SD1 — Descomposición de *Hospitalizar en Domicilio*
│   ├── SD1.2.a — Descomposición de *Evaluar Elegibilidad*
│   ├── SD1.3.a — Descomposición de *Ingresar Paciente*
│   ├── SD1.4.a — Descomposición de *Tratar en Domicilio*
│   ├── SD1.5.a — Descomposición de *Egresar Paciente*
│   ├── SD1.5.b — Causales de egreso (XOR)
│   └── SD1.5.c — *Reingresar a Hospital*
├── SD2 — Descomposición de *Autorizar Establecimiento*
├── SD3 — Gestión de Dirección Técnica
├── SD4 — Gestión de Coordinación
├── SD5 — Gestión de Registros y Protocolos
├── SD6 — Gestión de Capacitación e Inducción
├── SD7 — Gestión de Manejo de Residuos
├── SD8 — Gestión de Mantención de Equipos y Vehículos
├── SD9 — Gestión de Medicamentos e Insumos
├── SD10 — Gestión de Emergencias y Agudización
├── SD11 — Procedimientos Clínicos Específicos
└── SD12 — Uso de TIC
```
