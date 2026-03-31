# REM_A21_C1_Especificacion_Estructura_Datos_Hospitalizacion_Domiciliaria 

1. Dominio

Entidad raíz: REM_A21_Seccion_C
Ámbito: Hospitalización domiciliaria y atención ventilatoria en domicilio
Subdominio modelado: C.1 Hospitalización Domiciliaria

⸻

1. Estructura jerárquica

REM_A21_Seccion_C:
  C_1_Hospitalizacion_Domiciliaria:
    C_1_1_Personas_Atendidas:
    C_1_2_Visitas_Realizadas:
    C_1_3_Cupos_Disponibles:

⸻

1. Especificación de componentes

3.1 C.1.1 Personas Atendidas

3.1.1 Entidad

PersonasAtendidas:
  componentes:
    - ingresos
    - personas_atendidas
    - dias_persona
    - altas
    - fallecidos_esperados
    - fallecidos_no_esperados
    - reingresos_hospitalizacion

⸻

3.1.2 Dimensiones

dimensiones:
  rango_etario:
    - <15
    - 15_19
    - 20_59
    - >=60

  origen_derivacion:
    - APS
    - urgencia
    - hospitalizacion
    - ambulatorio
    - ley_urgencia
    - UGCC

  sexo:
    - masculino
    - femenino

  total: agregado global

⸻

3.1.3 Estructura de dato

RegistroPersonasAtendidas:
  componente: enum
  total: int

  desagregaciones:
    rango_etario:
      <15: int
      15_19: int
      20_59: int
      >=60: int

    origen_derivacion:
      APS: int
      urgencia: int
      hospitalizacion: int
      ambulatorio: int
      ley_urgencia: int
      UGCC: int

    sexo:
      masculino: int
      femenino: int

⸻

3.1.4 Invariantes

- total >= 0
- total ≥ suma(sexo) (puede no cuadrar si hay registros incompletos → no asumir igualdad estricta)
- dimensiones son ortogonales (no cruzadas explícitamente)
- unidad de medida depende del componente:
- ingresos / altas / fallecidos / reingresos → conteo de eventos
- personas_atendidas → conteo de personas
- dias_persona → acumulado temporal

⸻

3.2 C.1.2 Visitas Realizadas

3.2.1 Entidad

VisitasRealizadas:
  profesionales:
    - medico
    - enfermera
    - tecnico_enfermeria
    - matrona
    - kinesiologo
    - psicologo
    - fonoaudiologo
    - trabajador_social
    - terapeuta_ocupacional

⸻

3.2.2 Estructura de dato

RegistroVisitas:
  profesional: enum
  total_visitas: int

⸻

3.2.3 Invariantes

- total_visitas >= 0
- no hay desagregación por sexo, edad ni origen
- unidad: número de visitas realizadas

⸻

3.3 C.1.3 Cupos Disponibles

3.3.1 Entidad

CuposDisponibles:
  componentes:
    - cupos_programados
    - cupos_utilizados
    - cupos_disponibles

⸻

3.3.2 Dimensiones

dimensiones:
  total: int

  distribucion_cupos:
    total_cupos: int
    cupos_campana_invierno_adicionales: int
    cupos_campana_invierno: int
    cupos_pediatricos: int
    cupos_adultos: int
    cupos_salud_mental: int

⸻

3.3.3 Estructura de dato

RegistroCupos:
  componente: enum
  total: int

  detalle:
    total_cupos: int
    campana_invierno_adicionales: int
    campana_invierno: int
    pediatricos: int
    adultos: int
    salud_mental: int

⸻

3.3.4 Invariantes

- total >= 0
- total_cupos ≥ sum(subcategorias) (no necesariamente exacto si hay solapamientos)
- separación conceptual:
- programados → capacidad planificada
- utilizados → ocupación efectiva
- disponibles → capacidad residual

⸻

1. Modelo normalizado (síntesis)

HospitalizacionDomiciliaria:
  personas_atendidas: [RegistroPersonasAtendidas]
  visitas_realizadas: [RegistroVisitas]
  cupos: [RegistroCupos]

⸻

1. Observaciones estructurales críticas

- Modelo es multidimensional no cruzado → limita análisis (no permite, por ejemplo, edad × sexo)
- Ambigüedad en:
- definición operativa de “personas atendidas” vs “ingresos”
- distinción entre “cupos campaña invierno” y “adicionales”
- Falta eje temporal explícito → implícitamente mensual
- No hay identificador de unidad organizacional (establecimiento)

⸻
