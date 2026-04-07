# Auditoría: Redundancia `patient_id` en schema clínico

**Fecha**: 2026-04-07  
**Tipo**: Auditoría categorial de integridad estructural  
**Estado**: Documentada — sin acción correctiva inmediata

## Hallazgo

33 tablas en el schema `clinical` tienen FK simultáneas a `paciente` (vía `patient_id`) y a `estadia` (vía `stay_id`), cuando `estadia` ya contiene `patient_id NOT NULL`.

## Análisis categorial

El diagrama:

```
                    π_stay
  T ──────────────────────→ Estadia
  │                              │
  │  π_patient (REDUNDANTE)      │ σ_patient
  │                              │
  ▼                              ▼
              Paciente
```

**Path equation**: `σ_patient ∘ π_stay = π_patient`

El morfismo `T.patient_id → Paciente` es computable como composición de `T.stay_id → Estadia` y `Estadia.patient_id → Paciente`. Es la diagonal de un triángulo conmutativo — redundante por definición.

**Verificación empírica**: 0 violaciones en todas las tablas pobladas (2,350 notas, 126 epicrisis, etc.).

## Tablas afectadas

```
alerta, botiquin_domiciliario, condicion, consentimiento, derivacion,
dispensacion, documentacion, educacion_paciente, encuesta_satisfaccion,
epicrisis, evaluacion_funcional, evaluacion_paliativa, evento_adverso,
garantia_ges, herida, indicacion_medica, informe_social, interconsulta,
lista_espera, nota_evolucion, notificacion_obligatoria, observacion,
oxigenoterapia_domiciliaria, portal_mensaje, prestamo_equipo,
procedimiento, protocolo_fallecimiento, receta, sesion_rehabilitacion,
solicitud_examen, teleconsulta, valoracion_ingreso, voluntad_anticipada
```

## Mecanismo de protección actual

El trigger `check_stay_coherence` (en `reference` schema) valida la path equation en cada INSERT/UPDATE:

```sql
-- Pseudocódigo del trigger
IF NEW.patient_id != (SELECT patient_id FROM clinical.estadia WHERE stay_id = NEW.stay_id) THEN
    RAISE EXCEPTION 'stay_coherence violation';
END IF;
```

## Consecuencias

| Aspecto | Impacto |
|---------|---------|
| **Anomalía de actualización** | Si `estadia.patient_id` cambiara, 33 tablas necesitarían propagación manual. Mitigado: `patient_id` en estadia es inmutable en la práctica. |
| **Espacio** | 33 columnas TEXT + 33 índices adicionales. Despreciable a esta escala. |
| **Complejidad de escritura** | Cada INSERT debe proveer `patient_id` además de `stay_id`. Cada script de migración lo hace explícitamente. |
| **Trigger overhead** | `check_stay_coherence` ejecuta un SELECT por cada INSERT/UPDATE en las 33 tablas. Impacto real: ~ms por operación. |

## Decisión

**Mantener** la redundancia. Razones:

1. Refactor de 33 tablas + queries downstream tiene blast radius alto
2. El trigger protege la invariante — no hay riesgo de inconsistencia
3. El volumen de datos es bajo (~30K registros totales)

**Regla para futuro**: tablas nuevas con `stay_id NOT NULL` **no deben** incluir `patient_id` directo. Derivar vía JOIN.

## Verificación

```sql
-- Ejecutar periódicamente para confirmar que la path equation sigue conmutando
SELECT count(*) AS violaciones
FROM clinical.nota_evolucion n
JOIN clinical.estadia e ON e.stay_id = n.stay_id
WHERE n.patient_id != e.patient_id;
-- Esperado: 0
```
