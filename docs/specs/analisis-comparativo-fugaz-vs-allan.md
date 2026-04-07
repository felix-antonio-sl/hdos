# Análisis Comparativo — Paquetes de Diseño HODOM HSC

Fecha: 2026-04-07
Autor: Fugaz (análisis técnico)
Fuentes: Paquete Fugaz (8 docs, 160 KB) + Paquete Allan Kelly (5 docs, 128 KB)

---

## 1. Resumen de cobertura

| Dimensión | Fugaz | Allan Kelly | Veredicto |
|-----------|-------|-------------|-----------|
| **Usuarios identificados** | 19 (14 roles + 5 externos) | 17 (bien categorizados en 5 grupos) | Convergentes. Allan incluye SEREMI y Gestión de Camas como usuarios separados — es correcto y Fugaz los omitió |
| **Historias de usuario** | ~25 historias implícitas en backlog | 31 HU formales con CA, FHIR y normativa | **Allan es superior.** HU formales con criterios de aceptación, mapeo FHIR y referencia normativa. Fugaz tiene backlog operacional pero sin CA formales |
| **Módulos del sistema** | 7 | 11 | Allan desagrega más: Prescripción, Interconsultas y Portal Paciente como módulos separados. Es más preciso |
| **Modelo de datos** | 14 tablas MVP + DDL ejecutable | Referencia al ERD integrado de 43 tablas | **Complementarios.** Allan referencia el modelo completo; Fugaz recortó un MVP ejecutable |
| **Wireframes** | 5 pantallas + 1 formulario | 16 pantallas P0 detalladas | **Allan es superior en wireframes.** 16 pantallas vs 5, más flujos de navegación completos |
| **Arquitectura** | Recomendación modular monolith + fases | Arquitectura de información con mapeo FHIR detallado, permisos, integraciones, triggers | **Allan es más completo.** Incluye integraciones externas, triggers, path equations implementables |
| **Priorización** | MoSCoW 3 fases | P0/P1/P2 por HU | Equivalentes en enfoque. Allan ata prioridad a cada HU individual |
| **SQL ejecutable** | Sí (DDL PostgreSQL completo) | No (referencia al ERD existente) | **Fugaz aporta algo que Allan no tiene** |
| **Resumen ejecutivo** | Sí (para dirección) | Sí (en índice) | Equivalentes |
| **Métricas de éxito** | Sí (6 métricas concretas) | No explícitas | **Fugaz aporta algo que Allan no tiene** |
| **Contraste con legacy real** | Sí (planillas, rutas, llamadas, datos reales) | Referencial (cita fuentes pero no contrasta operación real) | **Fugaz aporta más contraste operativo** |

---

## 2. Lo que Allan tiene y Fugaz no

### 2.1 Historias de usuario formales (ALTO VALOR — ABSORBER)
Allan tiene 31 HU con:
- formato "Como [usuario], necesito [acción] para [beneficio]"
- criterios de aceptación específicos
- recurso FHIR R4 asociado
- artículo normativo que respalda
- prioridad P0/P1/P2

**Esto es directamente accionable para desarrollo. El backlog de Fugaz debería incorporar las HU de Allan como especificación formal de cada capacidad.**

### 2.2 Módulos adicionales (ABSORBER)
Allan identifica 3 módulos que Fugaz subsumió:
- **Prescripción y tratamiento** (Fugaz lo metió dentro de Gestión Clínica)
- **Interconsultas y solicitudes** (Fugaz no lo modeló explícito)
- **Portal paciente/cuidador** (Fugaz lo mencionó como futuro, Allan lo formaliza)

Recomendación: mantener los 11 módulos de Allan como estructura canónica.

### 2.3 Mapeo FHIR detallado (ABSORBER)
Allan mapea 25 recursos FHIR R4 a entidades del ERD. Fugaz no hizo mapeo FHIR (el modelo integrado existente sí lo tiene, pero el MVP de Fugaz lo omitió).

### 2.4 Integraciones externas (ABSORBER)
Allan identifica 5 integraciones:
- REM → DEIS/MINSAL
- APS / CESFAM (bidireccional)
- Gestión centralizada de camas
- DAU/SGH (sistemas clínicos hospitalarios)
- Laboratorio

Fugaz mencionó las primeras 3 pero no formalizó las interfaces.

### 2.5 Lifecycle de visita con 13 estados (EVALUAR)
Allan modela 13 estados de visita:
```
PROGRAMADA → ASIGNADA → EN_RUTA → EN_DOMICILIO → EN_ATENCION → ATENCION_COMPLETADA → DOCUMENTADA → REPORTADA_REM
```
Fugaz usó 5 estados: `programada, en_curso, realizada, fallida, cancelada`.

**Recomendación:** para MVP, los 5 estados de Fugaz son suficientes. Los 13 de Allan son correctos para el sistema completo pero agregan complejidad que no se necesita en Fase 1. Incorporar en Fase 2.

### 2.6 Wide pullback de elegibilidad (ABSORBER)
Allan formaliza 8 condiciones simultáneas de elegibilidad como un "wide pullback":
1. Condición clínica estable
2. Cuidador disponible
3. Domicilio adecuado
4. Consentimiento firmado
5. Sin condición de exclusión
6. Previsión Fonasa/PRAIS
7. Radio ≤ 20km
8. Edad ≥ 18

Fugaz captura esto en el diseño pero no lo formaliza como checklist cerrado. **Absorber como checklist obligatorio de admisión.**

### 2.7 Observaciones de diseño valiosas (ABSORBER)
- Brecha entre las 12 variables reales de ciclo vital y las 4 del modelo OPM
- Usuarios con doble rol (coordinadora = enfermera clínica)
- Restricciones de DAU/SGH (800 caracteres, borrado por reemplazo)
- Estadía promedio real (13.1 días) vs declarada (6-8 días) — el sistema debe alertar
- Cobertura temporal asimétrica (L-D enfermería vs L-V médico)

### 2.8 16 wireframes P0 vs 5 de Fugaz (ABSORBER selectivo)
Allan tiene wireframes para:
- Censo, Postulación (5 pantallas del flujo), Ficha clínica, Ingreso enfermería, Signos vitales, Narrativa enfermería, Prescripción, Programación visitas, Decisión continuidad/egreso, Egreso formal, Epicrisis, REM

Las pantallas de Allan son más granulares en el flujo de admisión (5 pantallas paso a paso) y en ficha clínica (tabs separados para cada formulario). **Absorber los wireframes de admisión y ficha clínica de Allan, que son más detallados.**

---

## 3. Lo que Fugaz tiene y Allan no

### 3.1 DDL PostgreSQL ejecutable (CONSERVAR)
Fugaz generó un modelo de datos funcional con DDL completo: 14 tablas, ENUMs, constraints, índices, vistas y funciones REM ejecutables en PostgreSQL. Allan referencia el ERD de 43 tablas pero no genera DDL MVP.

**Esto es directamente utilizable para empezar a construir.**

### 3.2 Funciones REM ejecutables (CONSERVAR)
Fugaz tiene 3 funciones PL/pgSQL que generan REM A21 C.1.1, C.1.2 y origen de derivación. Allan describe la lógica de derivación pero no la implementa.

### 3.3 Métricas de éxito concretas (CONSERVAR)
Fugaz define 6 métricas con línea base y meta:
- Tiempo REM: 2-3 días → < 1 hora
- Registros en papel: 80% → < 20%
- Planillas Excel: 8-10 → 0
- etc.

Allan no incluye métricas de éxito.

### 3.4 Contraste con operación real (CONSERVAR)
Fugaz revisó directamente las planillas de programación, rutas, llamadas, entregas de turno, canasta y formularios legacy. Allan los referencia como fuente pero no los contrasta contra el diseño.

### 3.5 Vista profesional móvil (CONSERVAR)
Fugaz diseñó una vista móvil offline-first para el profesional en terreno con:
- mi agenda de hoy
- botón navegar (Google Maps)
- registro de visita offline
- sincronización diferida

Allan no incluye vista móvil.

### 3.6 Recomendación arquitectónica explícita (CONSERVAR)
Fugaz recomienda monolito modular con trade-offs explícitos. Allan no hace recomendación de stack.

### 3.7 Resumen ejecutivo para dirección (CONSERVAR)
Documento de 1 página con cifras clave para presentar a dirección hospitalaria.

---

## 4. Donde divergen

### 4.1 Granularidad de módulos
- Fugaz: 7 módulos
- Allan: 11 módulos

**Resolución:** adoptar los 11 de Allan como estructura canónica. Los 4 adicionales (Prescripción, Interconsultas, Portal paciente, Gestión de recursos) son necesarios.

### 4.2 Profundidad del modelo de datos
- Fugaz: 14 tablas MVP ejecutables
- Allan: referencia 43 tablas del ERD completo

**Resolución:** son complementarios. El MVP arranca con las 14 tablas de Fugaz y escala hacia las 43 del ERD integrado.

### 4.3 Estados de visita
- Fugaz: 5 estados
- Allan: 13 estados

**Resolución:** MVP con 5; sistema completo con 13.

### 4.4 Número de pantallas
- Fugaz: 5 + 1 formulario
- Allan: 16

**Resolución:** absorber las 16 de Allan como diseño completo; las 5 de Fugaz como subset MVP.

---

## 5. Veredicto final

### ¿Desechar algo?
**No.** Ninguno de los dos paquetes debe desecharse. Son complementarios.

### ¿Qué absorber de Allan?
1. **31 HU formales** → reemplazan las historias implícitas del backlog de Fugaz
2. **11 módulos** → reemplazan los 7 de Fugaz como estructura canónica
3. **Wide pullback de elegibilidad** → checklist formal de admisión
4. **Mapeo FHIR** → trazabilidad de interoperabilidad
5. **Integraciones externas** → 5 interfaces que Fugaz no formalizó
6. **16 wireframes P0** → complementan y superan los 5 de Fugaz en admisión y ficha clínica
7. **Observaciones de diseño** → alertas de estadía, doble rol, cobertura temporal

### ¿Qué conservar de Fugaz?
1. **DDL ejecutable** → Allan no lo tiene
2. **Funciones REM** → Allan no las implementa
3. **Métricas de éxito** → Allan no las incluye
4. **Vista móvil offline** → Allan no la diseña
5. **Contraste con legacy real** → Allan no lo hace
6. **Recomendación arquitectónica** → Allan no la incluye
7. **Resumen ejecutivo** → complementa

### Recomendación de integración

Producir un **paquete consolidado** que use:
- la **estructura de módulos y HU de Allan** como esqueleto,
- el **DDL, funciones REM, métricas y recomendación arquitectónica de Fugaz** como implementación,
- los **wireframes de Allan** como diseño de pantallas (complementados con la vista móvil de Fugaz),
- las **observaciones y path equations de Allan** como restricciones del sistema.

Esto produciría un paquete de ~250 KB que es **especificación completa + implementable**.

---

## 6. Brechas que ninguno cubre

| Brecha | Impacto | Recomendación |
|--------|---------|---------------|
| Diseño de API / endpoints | Alto para implementación | Definir en Fase 1 |
| Estrategia de autenticación concreta | Alto | Decidir: LDAP institucional vs local vs OAuth |
| Plan de testing | Medio | Definir casos de prueba desde CA de Allan |
| Estrategia de migración de datos legacy | Alto | Pipeline ya existe parcialmente en `hdos/` |
| Diseño de notificaciones y alertas | Medio | Reglas de negocio existen en ambos pero sin diseño de UX |
| Accesibilidad (WCAG) | Medio | No mencionado en ninguno |
| Plan de capacitación al equipo | Alto para adopción | Crítico y no cubierto |
