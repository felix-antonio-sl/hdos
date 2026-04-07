# `graphic-design` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `graphic-design` skill that designs visual identities as coherent categorical systems, producing brand specs, executable design tokens, and SVG assets.

**Architecture:** Single `SKILL.md` file under `~/.claude/skills/own/graphic-design/` with optional `examples/` and `resources/` dirs. The skill defines 4 modes (create, audit, adapt, tokenize), 7 visual operators, and a categorical reasoning framework governed by the aesthetic axiom `Belleza = max(información / simpleza)`. Symlinked from `~/.claude/skills/graphic-design`.

**Tech Stack:** Markdown (SKILL.md), YAML frontmatter, Claude Code skill system, symlinks.

**Spec:** `docs/superpowers/specs/2026-04-06-graphic-design-skill-design.md`

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create dir | `~/.claude/skills/own/graphic-design/` | Skill root |
| Create | `~/.claude/skills/own/graphic-design/SKILL.md` | Main skill file — all logic, modes, operators, guardrails |
| Create dir | `~/.claude/skills/own/graphic-design/examples/` | Future: example brand specs, token files |
| Create dir | `~/.claude/skills/own/graphic-design/resources/` | Future: templates for brand specs, token schemas |
| Create symlink | `~/.claude/skills/graphic-design -> own/graphic-design` | Resolver shortcut (matches existing pattern) |

---

### Task 1: Create directory structure

**Files:**
- Create dir: `~/.claude/skills/own/graphic-design/`
- Create dir: `~/.claude/skills/own/graphic-design/examples/`
- Create dir: `~/.claude/skills/own/graphic-design/resources/`

- [ ] **Step 1: Create skill directories**

```bash
mkdir -p ~/.claude/skills/own/graphic-design/examples
mkdir -p ~/.claude/skills/own/graphic-design/resources
```

- [ ] **Step 2: Verify structure**

```bash
ls -la ~/.claude/skills/own/graphic-design/
```

Expected: directories `examples/` and `resources/` exist.

---

### Task 2: Write SKILL.md

**Files:**
- Create: `~/.claude/skills/own/graphic-design/SKILL.md`

- [ ] **Step 1: Write the complete SKILL.md file**

Write the following content to `~/.claude/skills/own/graphic-design/SKILL.md`:

````markdown
---
name: graphic-design
description: Disena identidades visuales como sistemas coherentes y transformables. Define operadores visuales (color, tipografia, grilla, forma, espaciado, iconografia, marca) y reglas de composicion que garantizan consistencia y escalabilidad. Produce brand specs, design tokens ejecutables (JSON + CSS + Tailwind) y assets SVG. Usar al crear marcas, definir paletas, disenar sistemas visuales, generar design tokens o adaptar identidades entre soportes.
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# Graphic Design — Identidad Visual Sistémica

Skill para diseñar identidades visuales como sistemas coherentes, transformables y trazables. Opera con un fundamento categórico interno que garantiza consistencia, pero entrega artefactos prácticos: specs, tokens ejecutables y assets SVG.

## Axioma Estético

> **Belleza = max(información / simpleza)**

Cada decisión de diseño se evalúa contra esta razón. Un elemento se justifica solo si la información que aporta es mayor que la complejidad que introduce. El diseño óptimo es la presentación más compacta del sistema visual: mínimos generadores, máxima estructura preservada.

## Cuándo usar esta skill

- Al crear identidades visuales o marcas desde cero
- Al definir paletas de color, tipografía, grillas o sistemas de espaciado
- Al generar design tokens (JSON, CSS custom properties, Tailwind config)
- Al adaptar una identidad visual a un nuevo soporte (web → print → mobile → señalética)
- Al auditar la coherencia de un sistema visual existente
- Cuando el usuario dice "crear identidad visual", "diseñar marca", "design tokens", "sistema visual", "crear brand", "adaptar identidad"

## Distinción con otras skills

| Esta skill (graphic-design) | frontend-design | ux-design |
|----------------------------|-----------------|-----------|
| QUÉ se ve (sistema) | CÓMO se implementa | CÓMO se usa |
| Identidad, operadores, tokens | Componentes, código, motion | Flujos, heurísticas, accesibilidad |
| Produce los tokens | Consume los tokens | Evalúa la experiencia |

`graphic-design` es **upstream** de `frontend-design`: primero se diseña la identidad, luego se implementa en componentes.

## Modos de Operación

### 1. `create` — Identidad nueva

Flujo completo para diseñar una identidad desde un brief:

```
1. BRIEFING        → Capturar contexto, restricciones, audiencia, soportes destino
2. AUDITORÍA       → Si existe identidad previa: evaluar ratio info/simpleza actual
3. OPERADORES      → Definir cada operador atómico (ver sección Operadores)
4. COMPOSICIÓN     → Reglas de combinación: jerarquías, contrastes, ritmos
5. INVARIANTES     → Restricciones que deben sobrevivir toda transformación
6. TOKENS          → Materializar como design tokens (JSON + CSS + Tailwind)
7. ASSETS          → Generar SVGs (logo, patrones, iconografía)
8. GUÍA            → Documento de identidad con uso correcto/incorrecto
9. VERIFICACIÓN    → Validar ratio info/simpleza del sistema completo
```

**Entregables**: Brand Spec (MD) + Design Tokens (JSON + CSS) + Tailwind Config snippet + SVGs (logo, patrones, iconos) + Guía de Transformación (MD)

### 2. `audit` — Evaluar identidad existente

Evaluar un sistema visual contra el axioma estético. Identificar redundancias, inconsistencias y oportunidades de compresión.

**Entregables**: Informe de Auditoría (MD) con score info/simpleza, hallazgos por operador, recomendaciones priorizadas.

### 3. `adapt` — Transformar a nuevo soporte

Adaptar una identidad a un soporte destino (ej: web → print). Preservar invariantes, declarar pérdidas.

**Entregables**: Tokens adaptados (JSON + CSS) + Functor Information Loss report (MD).

### 4. `tokenize` — Extraer tokens de identidad conceptual

Tomar una identidad conceptual (descripción, referencia visual, brand existente) y materializar sus operadores como design tokens ejecutables.

**Entregables**: Design Tokens (JSON + CSS + Tailwind).

---

## Operadores Visuales

Cada identidad se define como un conjunto finito de operadores atómicos. Para cada par de operadores, definir cómo interactúan.

### Color

Definir paleta en espacio **OKLCH** (perceptualmente uniforme):
- **Primarios**: 1-3 colores de marca
- **Secundarios**: Complementarios funcionales
- **Semánticos**: Éxito, error, advertencia, información
- **Neutros**: Escala de grises con tinte de marca

Artefacto: Tokens `--color-*` con escala de luminancia (50-950).

Regla: Contraste WCAG AA mínimo (4.5:1 texto normal, 3:1 texto grande). Verificar con `oklch()` antes de emitir hex.

### Tipo (Tipografía)

Máximo 3 familias con roles claros:
- **Display**: Títulos, hero text (personalidad)
- **Body**: Texto corrido, labels (legibilidad)
- **Mono**: Código, datos tabulares (alineación)

Escala modular basada en ratio (ej: 1.25 Major Third). Definir pesos usados (no todos).

Artefacto: Tokens `--font-*`, `--text-*`, CSS `@font-face`.

### Grilla

Sistema de columnas con:
- Columnas (4/8/12 según breakpoint)
- Gutters (fijo o relativo)
- Márgenes (escalan con viewport)
- Breakpoints (mobile-first)

Artefacto: Tokens `--grid-*`, Tailwind grid config.

### Forma

Geometría base que define la personalidad:
- **Radii**: Escala de bordes redondeados (none/sm/md/lg/full)
- **Sombras**: Escala de elevación (sm/md/lg/xl)
- **Geometría**: Angular vs orgánica (informa todos los demás operadores)

Artefacto: Tokens `--radius-*`, `--shadow-*`.

### Espaciado

Escala base coherente:
- Base: 4px u 8px
- Escala: Progresión geométrica o Fibonacci truncado
- Ritmo vertical: Basado en line-height del body
- Densidad: Compacto / Normal / Relajado

Artefacto: Tokens `--space-*`, Tailwind spacing extend.

### Iconografía

Conjunto mínimo con estilo coherente:
- Estilo: Outline / Filled / Duotone (elegir uno)
- Peso de trazo: Coherente con peso tipográfico del body
- Grid de construcción: Tamaño base (24px), padding óptico
- Tamaños: sm(16) / md(24) / lg(32)

Artefacto: SVGs optimizados + guía de estilo.

### Marca (Logo)

Construcción geométrica del logotipo:
- **Logotipo**: Nombre completo
- **Isotipo**: Símbolo/ícono
- **Variantes**: Color / Monocromo / Invertido / Compacto
- **Zonas de exclusión**: Espacio mínimo alrededor
- **Tamaño mínimo**: Legibilidad garantizada

Artefacto: SVGs con `viewBox` explícito, paths optimizados, sin metadatos de editor.

---

## Reglas de Composición

Para cada par de operadores, la regla que gobierna su interacción:

| Par | Regla |
|-----|-------|
| Color × Tipo | Contraste WCAG AA mínimo. Pesos tipográficos livianos requieren mayor contraste |
| Color × Forma | Sombras heredan tinte del color de superficie. Bordes usan color al 20% opacidad |
| Tipo × Espaciado | Line-height del body define el ritmo vertical. Margins/paddings son múltiplos |
| Grilla × Espaciado | Gutters son múltiplos de la escala base de espaciado |
| Forma × Iconografía | Radio de iconos = radio general del sistema. Peso de trazo = peso body |
| Marca × Color | El logo debe funcionar en monocromo. Los colores de marca no son los únicos primarios |
| Grilla × Marca | Zonas de exclusión se definen en unidades de grilla, no pixels absolutos |

---

## Formato de Artefactos

### Design Tokens (JSON)

```json
{
  "$schema": "https://design-tokens.org/draft",
  "brand": {
    "color": {
      "primary": { "$value": "oklch(0.55 0.15 250)", "$type": "color" },
      "primary-50": { "$value": "oklch(0.97 0.02 250)", "$type": "color" },
      "primary-950": { "$value": "oklch(0.15 0.08 250)", "$type": "color" }
    },
    "font": {
      "display": { "$value": "Plus Jakarta Sans", "$type": "fontFamily" },
      "body": { "$value": "Inter", "$type": "fontFamily" },
      "mono": { "$value": "JetBrains Mono", "$type": "fontFamily" }
    },
    "space": {
      "base": { "$value": "4px", "$type": "dimension" },
      "scale": { "$value": [0, 4, 8, 12, 16, 24, 32, 48, 64, 96], "$type": "dimension" }
    },
    "radius": {
      "sm": { "$value": "4px", "$type": "dimension" },
      "md": { "$value": "8px", "$type": "dimension" },
      "lg": { "$value": "16px", "$type": "dimension" },
      "full": { "$value": "9999px", "$type": "dimension" }
    }
  }
}
```

### Design Tokens (CSS Custom Properties)

```css
:root {
  /* Color */
  --brand-color-primary: oklch(0.55 0.15 250);
  --brand-color-primary-50: oklch(0.97 0.02 250);
  --brand-color-primary-950: oklch(0.15 0.08 250);

  /* Typography */
  --brand-font-display: 'Plus Jakarta Sans', sans-serif;
  --brand-font-body: 'Inter', sans-serif;
  --brand-font-mono: 'JetBrains Mono', monospace;

  /* Spacing */
  --brand-space-1: 4px;
  --brand-space-2: 8px;
  --brand-space-3: 12px;
  /* ... */

  /* Radius */
  --brand-radius-sm: 4px;
  --brand-radius-md: 8px;
  --brand-radius-lg: 16px;
  --brand-radius-full: 9999px;
}
```

### Tailwind Config Snippet

```typescript
// tailwind.config.ts — extend block
{
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: 'oklch(0.55 0.15 250)',
          50: 'oklch(0.97 0.02 250)',
          // ... escala completa
          950: 'oklch(0.15 0.08 250)',
        },
      },
      fontFamily: {
        display: ['Plus Jakarta Sans', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      borderRadius: {
        sm: '4px',
        md: '8px',
        lg: '16px',
      },
    },
  },
}
```

### SVG Standards

Todo SVG generado debe cumplir:
- `viewBox` explícito (nunca width/height fijos sin viewBox)
- Paths optimizados (sin puntos redundantes)
- Sin metadatos de editor (Illustrator, Figma, etc.)
- Sin IDs aleatorios (usar IDs semánticos si es necesario)
- Sin raster embebido (todo vectorial)
- `fill="currentColor"` para iconos monocromáticos
- Comentarios solo para separar variantes en archivos multi-ícono

---

## Modelo Categórico (Referencia Interna)

> Esta sección gobierna cómo el agente RAZONA sobre el diseño. No exponerla al usuario salvo que la solicite explícitamente.

**Categoría VisId**:
- **Objetos**: Los 7 operadores visuales (Color, Tipo, Grilla, Forma, Espaciado, Iconografía, Marca)
- **Morfismos**: Las reglas de composición entre pares de operadores
- **Funtores de soporte**: `F: VisId → Soporte` donde Soporte ∈ {Web, Print, Mobile, Señalética}. Cada funtor preserva morfismos pero adapta valores (OKLCH→CMYK, rem→mm)
- **Invariantes (path equations)**: Restricciones que deben conmutar: si Color×Tipo→Contraste y Tipo×Espaciado→Ritmo, entonces la adaptación a Print debe preservar ambos
- **Identidades**: Estado neutro de cada operador (default del sistema)

**Functor Information Loss**: Cuando una transformación de soporte no puede preservar un morfismo (ej: OKLCH gamut → CMYK gamut), declarar explícitamente qué se pierde y por qué. Formato:

```markdown
### Functor Information Loss: [Soporte Origen] → [Soporte Destino]

| Operador | Pérdida | Mitigación |
|----------|---------|------------|
| Color | Gamut OKLCH excede CMYK en primario-400 | Remap a closest in-gamut con delta E < 2 |
```

---

## Guardrails

- Toda decisión de diseño debe justificarse contra el axioma **información/simpleza**
- No generar assets decorativos sin función comunicativa — cada elemento aporta información
- Declarar **Functor Information Loss** cuando una adaptación de soporte pierda información
- Los tokens generados deben ser consumibles por `frontend-design` sin transformación manual
- SVGs limpios: sin metadatos, sin IDs aleatorios, viewBox explícito, paths optimizados
- Escribir en español técnico; términos categóricos en inglés cuando sean más precisos
- Máximo 3 familias tipográficas, paleta mínima con escala OKLCH, grilla con reglas explícitas

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
| Decoración sin función | Cada SVG comunica algo; si no, eliminarlo |

## Self-check

Antes de entregar cualquier artefacto, verificar:

```
[ ] Cada operador tiene tokens materializados?
[ ] Las reglas de composición entre operadores son explícitas?
[ ] Los SVGs pasan validación (viewBox, no-raster, paths optimizados)?
[ ] El sistema se puede describir con menos generadores? (si sí, comprimir)
[ ] Los invariantes cross-soporte están declarados?
[ ] El ratio información/simpleza es óptimo (nada se puede quitar sin perder info)?
[ ] Los tokens usan prefijo `--brand-*` y son consumibles por frontend-design?
[ ] Functor Information Loss declarado donde aplique?
```
````

- [ ] **Step 2: Verify file was written**

```bash
head -5 ~/.claude/skills/own/graphic-design/SKILL.md
```

Expected: YAML frontmatter with `name: graphic-design`.

- [ ] **Step 3: Commit**

```bash
cd ~/.claude/skills && git add own/graphic-design/SKILL.md && git commit -m "feat: add graphic-design skill — visual identity as categorical system"
```

Note: If `~/.claude/skills/` is not a git repo, skip this step.

---

### Task 3: Create symlink

**Files:**
- Create symlink: `~/.claude/skills/graphic-design -> own/graphic-design`

- [ ] **Step 1: Create the symlink**

```bash
cd ~/.claude/skills && ln -s own/graphic-design graphic-design
```

- [ ] **Step 2: Verify symlink**

```bash
ls -la ~/.claude/skills/graphic-design
```

Expected: `graphic-design -> own/graphic-design`

- [ ] **Step 3: Verify SKILL.md is reachable through symlink**

```bash
head -3 ~/.claude/skills/graphic-design/SKILL.md
```

Expected: `---`, `name: graphic-design`, `description: ...`

---

### Task 4: Verify skill loads in Claude Code

- [ ] **Step 1: Check skill appears in available skills list**

Start a new Claude Code session or check the skills list. The skill `graphic-design` should appear with description matching: "Disena identidades visuales como sistemas coherentes y transformables..."

- [ ] **Step 2: Test invocation**

In Claude Code, type a trigger phrase like "crear identidad visual" or invoke directly. Verify the skill content loads correctly.

- [ ] **Step 3: Final commit (plan repo)**

```bash
cd /Users/felixsanhueza/Developer/_workspaces/hdos
git add docs/superpowers/plans/2026-04-06-graphic-design-skill.md
git commit -m "docs: implementation plan for graphic-design skill"
```
