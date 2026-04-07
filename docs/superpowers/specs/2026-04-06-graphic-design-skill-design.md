# Spec: Skill `graphic-design`

**Fecha**: 2026-04-06
**Autor**: Felix + Claude
**Estado**: Draft → Revisión

## Resumen

Skill independiente para diseñar identidades visuales como sistemas coherentes y transformables. Fundamento categórico interno (objetos = operadores visuales, morfismos = composición, funtores = adaptación entre soportes) con interfaz práctica que produce specs, design tokens ejecutables y assets SVG.

## Axioma Estético

> **Belleza = max(información / simpleza)**

Cada decisión de diseño se evalúa contra esta razón. Un elemento se justifica si la información que aporta es mayor que la complejidad que introduce. El diseño óptimo es la presentación más compacta de la categoría visual: mínimos generadores, máxima estructura preservada.

## Identidad de la Skill

- **Nombre**: `graphic-design`
- **Namespace**: `own/` (skill personal)
- **Ruta**: `~/.claude/skills/own/graphic-design/SKILL.md`
- **Allowed tools**: `Read, Write, Edit, Grep, Glob, Bash, Agent`

### Disparadores

- "crear identidad visual", "diseñar marca", "crear brand"
- "definir paleta", "diseñar tipografía", "crear grilla"
- "design tokens", "sistema visual"
- "adaptar identidad a [soporte]"

### Relación con otras skills

| Skill | Relación |
|-------|----------|
| `frontend-design` | **Downstream**: consume los tokens y reglas que `graphic-design` produce |
| `ux-design` | **Paralela**: UX define cómo se USA, graphic-design define cómo se VE a nivel sistémico |
| `arquitecto-categorico` | **Independiente**: vocabulario categórico propio adaptado al dominio visual |

## Modelo Categórico Interno

El agente razona internamente con esta estructura. No la expone al usuario salvo que la pida explícitamente.

**Categoría Visual (VisId)**:
- **Objetos**: Operadores visuales atómicos — Color, Tipo, Grilla, Forma, Espaciado, Iconografía, Marca
- **Morfismos**: Reglas de composición entre operadores — cómo un Color se combina con un Tipo para producir una jerarquía visual consistente
- **Funtores de soporte**: Transformaciones `F: VisId → Soporte` donde `Soporte ∈ {Web, Print, Mobile, Señalética}`. Cada funtor preserva las relaciones entre operadores pero adapta valores concretos (ej: OKLCH→CMYK, rem→mm)
- **Invariantes (path equations)**: Restricciones que deben cumplirse en toda transformación — ej: el ratio de contraste entre fondo y texto debe preservarse independientemente del soporte
- **Identidades**: Cada operador tiene un estado neutro/default que no altera la composición

**Traducción práctica**:
1. Toda identidad se define como un conjunto de operadores + sus reglas de composición
2. Toda adaptación a un soporte se verifica contra los invariantes
3. Si una transformación pierde información, se declara explícitamente (Functor Information Loss)

## Operadores Visuales

| Operador | Qué define | Artefacto |
|----------|-----------|-----------|
| **Color** | Paleta primaria, secundaria, semántica, neutros. Espacio OKLCH preferido | Tokens `--color-*`, escala de luminancia |
| **Tipo** | Familias (display, body, mono), escala modular, pesos | Tokens `--font-*`, `--text-*`, CSS `@font-face` |
| **Grilla** | Columnas, gutters, márgenes, breakpoints | Tokens `--grid-*`, Tailwind grid config |
| **Forma** | Radii, bordes, sombras, geometría base | Tokens `--radius-*`, `--shadow-*` |
| **Espaciado** | Escala base (4px/8px), ritmo vertical, densidad | Tokens `--space-*`, Tailwind spacing |
| **Iconografía** | Estilo (outline/filled/duotone), peso trazo, tamaños, grid | SVGs + guía de estilo |
| **Marca** | Logotipo, isotipo, construcción geométrica, zonas exclusión, variantes | SVGs + guía de uso |

**Regla de composición**: Para cada par de operadores, la skill define cómo interactúan (ej: contraste mínimo Color×Tipo, alineación Grilla×Espaciado).

## Flujo de Trabajo

```
1. BRIEFING        → Capturar contexto, restricciones, audiencia, soportes destino
2. AUDITORÍA       → Si existe identidad previa: evaluar ratio información/simpleza actual
3. OPERADORES      → Definir cada operador atómico
4. COMPOSICIÓN     → Reglas de combinación: jerarquías, contrastes, ritmos
5. INVARIANTES     → Restricciones cross-soporte
6. TOKENS          → Materializar como design tokens (JSON + CSS + Tailwind)
7. ASSETS          → Generar SVGs (logo, patrones, iconografía)
8. GUÍA            → Documento de identidad con uso correcto/incorrecto
9. VERIFICACIÓN    → Validar ratio información/simpleza del sistema completo
```

## Modos de Operación

| Modo | Entrada | Salida |
|------|---------|--------|
| `create` | Brief de identidad | Brand Spec + Design Tokens + SVGs + Tailwind Config + Guía de Transformación |
| `audit` | Identidad existente | Informe: score info/simpleza, redundancias, inconsistencias, recomendaciones |
| `adapt` | Identidad + soporte destino | Tokens adaptados + Functor Information Loss report |
| `tokenize` | Identidad conceptual | Design Tokens JSON + CSS + Tailwind extraídos |

## Artefactos de Salida

### Modo `create` (completo)

| Artefacto | Formato | Contenido |
|-----------|---------|-----------|
| Brand Spec | Markdown | Axioma estético, operadores, composición, invariantes, uso correcto/incorrecto |
| Design Tokens | JSON + CSS | Custom properties, escalas, paleta, tipografía, espaciado |
| Tailwind Config | `tailwind.config.ts` snippet | Extensiones de tema que codifican la identidad |
| Logo / Marca | SVG | Logotipo, isotipo, variantes (monocromo, invertido, compacto) |
| Patrones / Texturas | SVG | Elementos gráficos repetibles, backgrounds, decorativos |
| Iconografía base | SVG | Set mínimo de iconos custom si la identidad lo requiere |
| Guía de Transformación | Markdown | Reglas por soporte con pérdidas declaradas |

### Modo `audit`

| Artefacto | Formato | Contenido |
|-----------|---------|-----------|
| Informe de Auditoría | Markdown | Score información/simpleza, redundancias, inconsistencias, recomendaciones |

### Modo `adapt`

| Artefacto | Formato | Contenido |
|-----------|---------|-----------|
| Tokens adaptados | JSON + CSS | Valores transformados al soporte destino |
| Functor Info Loss | Markdown | Qué se perdió en la transformación y por qué |

### Modo `tokenize`

| Artefacto | Formato | Contenido |
|-----------|---------|-----------|
| Design Tokens | JSON + CSS + Tailwind | Extracción de tokens desde identidad conceptual |

## Guardrails

- Toda decisión de diseño debe justificarse contra el axioma **información/simpleza**
- No generar assets decorativos sin función comunicativa
- Declarar `Functor Information Loss` cuando una adaptación de soporte pierda información visual
- Los tokens generados deben ser consumibles por `frontend-design` sin transformación manual
- SVGs limpios: sin metadatos de editor, sin IDs aleatorios, viewBox explícito, paths optimizados
- Escribir en español técnico; términos categóricos en inglés cuando sean más precisos

## Anti-patrones

| NO hacer | SÍ hacer |
|----------|---------|
| Paleta de 20+ colores sin jerarquía | Paleta mínima con escala de luminancia OKLCH |
| Tipografía de 4+ familias | Máximo 3 familias con roles claros (display, body, mono) |
| Grilla arbitraria por soporte | Grilla base + reglas de adaptación explícitas |
| Logo como raster embebido | Logo SVG con construcción geométrica documentada |
| Tokens sin namespace | Tokens con prefijo semántico (`--brand-*`, `--color-*`) |
| Estilo que solo funciona en web | Invariantes cross-soporte verificados |
| Complejidad visual sin información | Cada elemento justifica su ratio info/simpleza |

## Self-check

```
[ ] Cada operador tiene tokens materializados?
[ ] Las reglas de composición entre operadores son explícitas?
[ ] Los SVGs pasan validación (viewBox, no-raster, paths optimizados)?
[ ] El sistema completo se puede describir con menos generadores?
[ ] Los invariantes cross-soporte están declarados?
[ ] El ratio información/simpleza es óptimo (nada se puede quitar sin perder info)?
```
