-- HODOM — Funciones normativas de respaldo operativo desde INGRESOS 2026
-- Centraliza la logica de fallback edad/diagnostico usada en /censo y /ficha.
-- Uso: llamar desde cualquier pantalla o reporting que necesite valores operativos
-- cuando el core clinico tiene datos insuficientes o implausibles.
--
-- Reglas:
--   1. edad_operativa: core valido (1..120) prevalece; si no, busca en INGRESOS ACTIVO mas reciente.
--   2. diagnostico_operativo: core no vacio prevalece; si vacio, busca en INGRESOS ACTIVO mas reciente.
--   3. Ambas funciones son STABLE (mismo resultado dentro de una transaccion).
--   4. No dependen de staging.hodom_ingreso_2026 directamente los callers;
--      el acoplamiento queda encapsulado aqui.

BEGIN;

-- ============================================================================
-- Funcion: operational.fn_edad_operativa(p_rut text, p_core_edad integer)
-- Retorna edad con respaldo INGRESOS cuando el core falta o es implausible.
-- NULL si no hay fuente confiable (core invalido + sin INGRESOS o INGRESOS invalido).
-- ============================================================================

CREATE OR REPLACE FUNCTION operational.fn_edad_operativa(
    p_rut text,
    p_core_edad integer
) RETURNS integer
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(
        CASE WHEN p_core_edad BETWEEN 1 AND 120 THEN p_core_edad END,
        (SELECT hi.edad
         FROM staging.hodom_ingreso_2026 hi
         WHERE hi.rut_normalizado = p_rut
           AND hi.estado = 'ACTIVO'
           AND hi.edad BETWEEN 1 AND 120
         ORDER BY hi.fecha_ingreso DESC NULLS LAST, hi.source_row_number DESC
         LIMIT 1)
    );
$$;

COMMENT ON FUNCTION operational.fn_edad_operativa IS
'Edad operativa con fallback a INGRESOS 2026 por RUT.
 Usa edad core si es valida (1-120); si no, toma la edad de la fila ACTIVO mas reciente
 en staging.hodom_ingreso_2026 cuyo valor este en rango valido.
 Retorna NULL si ninguna fuente tiene un valor valido.
 Usar en lugar de EXTRACT(YEAR FROM age(fecha_nacimiento)) en pantallas censo/ficha.';

-- ============================================================================
-- Funcion: operational.fn_diagnostico_operativo(p_rut text, p_core_diagnostico text)
-- ============================================================================

CREATE OR REPLACE FUNCTION operational.fn_diagnostico_operativo(
    p_rut text,
    p_core_diagnostico text
) RETURNS text
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(
        NULLIF(btrim(p_core_diagnostico), ''),
        (SELECT NULLIF(btrim(hi.diagnostico_egreso), '')
         FROM staging.hodom_ingreso_2026 hi
         WHERE hi.rut_normalizado = p_rut
           AND hi.estado = 'ACTIVO'
         ORDER BY hi.fecha_ingreso DESC NULLS LAST, hi.source_row_number DESC
         LIMIT 1)
    );
$$;

COMMENT ON FUNCTION operational.fn_diagnostico_operativo IS
'Diagnostico operativo con fallback a INGRESOS 2026 por RUT.
 Usa diagnostico_principal core si no esta vacio; si esta vacio, toma diagnostico_egreso
 de la fila ACTIVO mas reciente en staging.hodom_ingreso_2026.
 Retorna NULL si ninguna fuente tiene valor.';

-- ============================================================================
-- Funcion: operational.fn_respaldo_operativo(p_rut text, p_core_edad integer, p_core_diagnostico text)
-- Conveniencia: retorna ambos valores y un booleano indicando si se uso fallback.
-- ============================================================================

CREATE OR REPLACE FUNCTION operational.fn_respaldo_operativo(
    p_rut text,
    p_core_edad integer,
    p_core_diagnostico text
) RETURNS TABLE(
    edad_operativa integer,
    diagnostico_operativo text,
    usa_fallback boolean
)
LANGUAGE sql STABLE
AS $$
    WITH ingreso_fallback AS (
        SELECT hi.edad, NULLIF(btrim(hi.diagnostico_egreso), '') AS diagnostico_egreso
        FROM staging.hodom_ingreso_2026 hi
        WHERE hi.rut_normalizado = p_rut
          AND hi.estado = 'ACTIVO'
        ORDER BY hi.fecha_ingreso DESC NULLS LAST, hi.source_row_number DESC
        LIMIT 1
    ),
    computed AS (
        SELECT
            COALESCE(
                CASE WHEN p_core_edad BETWEEN 1 AND 120 THEN p_core_edad END,
                (SELECT edad FROM ingreso_fallback WHERE edad BETWEEN 1 AND 120)
            ) AS edad_op,
            COALESCE(
                NULLIF(btrim(p_core_diagnostico), ''),
                (SELECT diagnostico_egreso FROM ingreso_fallback)
            ) AS diag_op
    )
    SELECT
        c.edad_op,
        c.diag_op,
        (
            (p_core_edad IS NULL OR NOT (p_core_edad BETWEEN 1 AND 120))
            AND c.edad_op IS NOT NULL
            AND c.edad_op IS DISTINCT FROM p_core_edad
        ) OR (
            (p_core_diagnostico IS NULL OR btrim(p_core_diagnostico) = '')
            AND c.diag_op IS NOT NULL
        ) AS usa_fallback
    FROM computed c;
$$;

COMMENT ON FUNCTION operational.fn_respaldo_operativo IS
'Respaldo operativo completo: edad y diagnostico con fallback a INGRESOS 2026.
 Retorna (edad_operativa, diagnostico_operativo, usa_fallback).
 usa_fallback = TRUE cuando al menos uno de los campos se completo desde INGRESOS.
 Usar en pantallas de censo, ficha y reporting donde se necesite marcar con * los datos
 de respaldo.';

-- ============================================================================
-- Verificacion rapida (ejecutar fuera de la transaccion si se desea)
-- ============================================================================
-- SELECT r.rut, r.edad AS core_edad,
--        op.edad_operativa, op.diagnostico_operativo, op.usa_fallback
-- FROM operational.v_tablero_coordinacion r
-- CROSS JOIN LATERAL operational.fn_respaldo_operativo(r.rut, r.edad, r.diagnostico_principal) op
-- WHERE r.rut IN ('6888648-1','12145608-7','11444532-0','6646308-7');

COMMIT;
