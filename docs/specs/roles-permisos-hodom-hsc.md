# Roles y Permisos — Sistema Operativo HODOM HSC

Fecha: 2026-04-07
Estado: borrador v1
Dependencia: `diseno-sistema-operativo-hodom-hsc.md`

---

## 1. Principios de acceso

1. **Mínimo privilegio**: cada rol accede solo a lo que necesita para operar.
2. **Episodio como perímetro**: los permisos clínicos se aplican sobre episodios asignados o en su ámbito de atención.
3. **Auditoría total**: toda acción sobre datos clínicos queda trazada (quién, cuándo, qué).
4. **Confidencialidad por defecto**: DS 41 y Ley 19.628 obligan resguardo de datos sensibles.
5. **Separación clínico-administrativa**: un administrativo no ve notas clínicas; un clínico no modifica configuración institucional.

---

## 2. Matriz de roles

### Nomenclatura de permisos

| Símbolo | Significado |
|---------|-------------|
| C | Crear |
| R | Leer |
| U | Actualizar |
| D | Eliminar (soft delete / anular) |
| X | Ejecutar acción (ej: egresar, derivar, aprobar) |
| — | Sin acceso |

---

### 2.1 Módulo M1: Admisión y Elegibilidad

| Capacidad | Médico derivador | Coordinación | Médico HODOM | Enfermera clínica | Trabajo social | Administrativo | Dir. Técnica |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Crear postulación | C | C | C | C | — | C | — |
| Ver postulaciones | R | R | R | R | R | R | R |
| Evaluar elegibilidad clínica | — | X | X | X | — | — | R |
| Evaluar elegibilidad social | — | R | R | R | X | — | R |
| Aceptar/rechazar postulación | — | X | X | — | — | — | R |
| Registrar consentimiento | — | — | — | X | — | X | — |
| Abrir episodio | — | X | X | — | — | — | — |
| Asignar equipo | — | X | — | — | — | — | — |

### 2.2 Módulo M2: Gestión Clínica

| Capacidad | Médico HODOM | Médico regulador | Enfermera clínica | TENS | Kinesiólogo | Fonoaudiólogo | Trabajo social | Psicólogo/TO/Matrona | Coordinación | Dir. Técnica |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Ver ficha clínica del episodio | R | R | R | R (resumen) | R | R | R (social) | R | R | R |
| Crear/editar plan terapéutico | CU | — | R | — | — | — | — | — | R | R |
| Crear/editar plan enfermería | R | — | CU | — | — | — | — | — | R | R |
| Registrar visita clínica | CU | — | CU | CU | CU | CU | CU | CU | R | R |
| Registrar signos vitales | CU | — | CU | CU | CU | — | — | — | R | R |
| Registrar procedimientos | CU | — | CU | CU | CU | CU | — | CU | R | R |
| Registrar medicación | CU | CU | CU | CU | — | — | — | — | R | R |
| Registrar educación | — | — | CU | CU | CU | CU | CU | CU | R | R |
| Categorizar paciente | CU | — | CU | — | — | — | — | — | R | R |
| Crear alerta clínica | CU | CU | CU | CU | CU | CU | CU | CU | R | R |
| Decidir egreso | X | — | — | — | — | — | — | — | R | R |
| Generar epicrisis | CU | — | — | — | — | — | — | — | R | R |

### 2.3 Módulo M3: Programación, Agenda y Rutas

| Capacidad | Coordinación | Gestor rutas | Profesional clínico | TENS | Conductor | Administrativo | Dir. Técnica |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Ver agenda global | R | R | — | — | — | R | R |
| Ver mi agenda del día | — | — | R | R | R | — | — |
| Programar visitas | CU | CU | — | — | — | — | R |
| Asignar profesional a visita | CU | CU | — | — | — | — | — |
| Asignar móvil/ruta | CU | CU | — | — | R | — | — |
| Reprogramar por contingencia | CU | CU | — | — | — | — | R |
| Marcar visita realizada | — | — | X | X | — | — | — |
| Marcar visita fallida/rechazada | — | — | X | X | — | — | — |
| Ver mapa y secuencia | R | R | R | R | R | — | — |

### 2.4 Módulo M4: Teleatención, Llamadas y Regulación

| Capacidad | Médico regulador | Médico HODOM | Enfermera clínica | Coordinación | Administrativo | Paciente/Cuidador |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| Registrar llamada | CU | CU | CU | CU | CU | — |
| Recibir alerta remota | R | R | R | R | R | — |
| Realizar teleorientación | X | X | X | — | — | — |
| Registrar telemonitoreo | CU | CU | CU | — | — | — |
| Indicar escalamiento | X | X | X | X | — | — |
| Reportar síntoma o evento | — | — | — | — | — | X |
| Ver indicaciones | — | — | — | — | — | R |

### 2.5 Módulo M5: Logística y Abastecimiento

| Capacidad | Coordinación | Farmacia/Bodega | Conductor | Profesional clínico | Dir. Técnica |
|-----------|:---:|:---:|:---:|:---:|:---:|
| Ver stock | R | R | — | R | R |
| Gestionar stock (entrada/salida) | — | CUD | — | — | R |
| Preparar despacho por paciente | — | CU | — | — | — |
| Confirmar entrega en terreno | — | — | X | X | — |
| Registrar consumo | — | CU | — | CU | R |
| Registrar devolución | — | CU | — | CU | — |
| Gestionar equipos/dispositivos | CU | CU | — | — | R |
| Coordinar retiro residuos | CU | CU | X | — | R |

### 2.6 Módulo M6: Documentos Clínico-Legales

| Capacidad | Médico HODOM | Enfermera clínica | Administrativo | Coordinación | Dir. Técnica | APS/CESFAM |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| Generar consentimiento | — | CU | CU | — | — | — |
| Generar epicrisis | CU | — | — | R | R | R |
| Generar contrarreferencia | CU | CU | — | R | R | R |
| Ver documentos del episodio | R | R | R | R | R | R (limitado) |
| Firmar/validar documento | X | X | — | X | X | — |
| Auditar completitud | — | — | — | R | R | — |

### 2.7 Módulo M7: Analítica, REM y Auditoría

| Capacidad | Estadístico | Coordinación | Dir. Técnica | Gestión hospitalaria |
|-----------|:---:|:---:|:---:|:---:|
| Ver tablero operacional | R | R | R | R |
| Generar REM A21 | X | R | R | R |
| Validar consistencia REM | X | X | R | — |
| Ver productividad por disciplina | R | R | R | R |
| Ver ocupación y cupos | R | R | R | R |
| Auditar documentación | R | R | R | — |
| Exportar datos | X | — | X | X |

---

## 3. Reglas transversales

### 3.1 Acceso por episodio asignado
Los profesionales clínicos (TENS, kine, fono, TO, psicólogo, matrona) ven solo episodios donde están asignados como parte del equipo o tienen visita programada. Médicos HODOM y enfermera clínica ven todos los episodios activos del programa.

### 3.2 Acceso del médico derivador
Solo puede crear postulaciones y ver el estado de sus propias postulaciones. No accede al episodio clínico una vez abierto.

### 3.3 Acceso APS/CESFAM
Recibe contrarreferencia y epicrisis. No accede a la historia clínica del episodio HODOM.

### 3.4 Acceso paciente/cuidador
Accede a: indicaciones, próximas visitas, canal de reporte de eventos. No accede a: notas clínicas, planes internos, datos de otros pacientes.

### 3.5 Dirección Técnica
Acceso de lectura global para auditoría y cumplimiento normativo. No edita registros clínicos directamente.

### 3.6 Superadmin / configuración
Rol técnico separado para configuración del sistema, gestión de usuarios, catálogos y parámetros. No confundir con Dir. Técnica.

---

## 4. Segregación de datos sensibles

| Dato | Quién accede | Restricción |
|------|-------------|-------------|
| Notas clínicas | Equipo clínico asignado + coordinación + Dir. Técnica | No visible para administrativos ni derivadores |
| Diagnóstico | Equipo clínico + coordinación + estadístico (anonimizado para REM) | — |
| RUT paciente | Todos los que interactúan con el episodio | Enmascarado en reportes agregados |
| Datos del cuidador | Equipo clínico + trabajo social + administrativo | — |
| Dirección domicilio | Equipo clínico + logística + conductor | No visible en reportes REM |
| Registro de llamadas | Equipo clínico + coordinación + administrativo | Trazabilidad obligatoria |
| Documentos legales | Según §2.6 | Firma requerida para validez |

---

## 5. Siguiente paso

Con esta matriz, el sistema puede implementar RBAC (Role-Based Access Control) con:
- 14 roles base,
- 7 módulos,
- permisos CRUD+X por capacidad,
- filtro por episodio asignado.
