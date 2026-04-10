# Entrega Final — HODOM HSC
## Paquete completo para primera reunión DT + handoff desarrollo
### 26 de marzo de 2026

---

## Estructura del paquete

### 📊 `presentacion/` — Para la reunión con el equipo
| Archivo | Contenido |
|---|---|
| `presentacion-marp-dt-hodom-hsc.md` | **18 slides en formato Marp** — listo para renderizar |
| `guion-presentacion-dt-hodom-hsc.md` | **Guión completo slide por slide** — qué decir, cuándo, cómo |
| `consolidado-estrategico-dt-hodom-hsc-2026-03-25.md` | Documento madre: diagnóstico, 3 horizontes, decisiones |
| `marco-rol-dt-hodom-hsc.md` | Marco de autoridad y responsabilidades del DT |

**Para renderizar las slides:**
```bash
# Instalar Marp CLI
npm install -g @marp-team/marp-cli

# Generar HTML
marp presentacion-marp-dt-hodom-hsc.md --html

# Generar PDF
marp presentacion-marp-dt-hodom-hsc.md --pdf

# Generar PPTX
marp presentacion-marp-dt-hodom-hsc.md --pptx
```

### 💻 `desarrollo/` — Handoff para el equipo de desarrollo
| Archivo | Contenido |
|---|---|
| `handoff-equipo-desarrollo-hodom-hsc.md` | **⭐ EMPEZAR AQUÍ** — contexto, decisiones, módulos, sprints, wireframes |
| `hodom-os-v1.md` | Sistema operativo HODOM refactorizado |
| `specs-sistema-web-hodom-hsc.md` | Specs completas: 9 módulos, 17 roles, stack |
| `specs-teleatencion-hodom-hsc.md` | Módulo de telecontrol detallado |
| `historias-usuario-hodom-hsc.md` | 147 historias de usuario en 15 épicas |
| `criterios-aceptacion-hodom-hsc.md` | Criterios de aceptación por HU |
| `backlog-producto-hodom-hsc.md` | Backlog priorizado |
| `modelo-dominio-hodom-hsc.md` | Entidades y relaciones del dominio |
| `modelo-dominio-fhir-hodom-hsc.md` | Mapeo FHIR R4 |
| `snomed-ct-mapping-hodom.md` | Codificación SNOMED-CT |

### 🔧 `operacional/` — Guías y herramientas operativas
| Archivo | Contenido |
|---|---|
| `plan-90-dias-dt.md` | Plan primeros 90 días del DT |
| `formato-briefing-matinal.md` | Formato de coordinación diaria |
| `guia-escalamiento-terreno.md` | Escalamiento clínico NEWS2 / semáforo |
| `plan-capacitacion-hodom-hsc.md` | 5 módulos, 34 hrs, 20 sesiones |
| `inventario-e-insights-hodom-hsc.md` | Inventario documental + insights |

### 🏥 `clinico/` — Protocolos y modelo clínico
| Archivo | Contenido |
|---|---|
| `protocolos-clinicos-por-patologia.md` | 8 protocolos base |
| `propuesta-hodom-hsc-ideal.md` | Modelo HODOM ideal dimensionado |

### ✅ `normativo/` — Cumplimiento
| Archivo | Contenido |
|---|---|
| `checklist-normativo-hodom-hsc.md` | 75 requisitos normativos mapeados |

### 📈 `analisis/` — Datos y evidencia
| Archivo | Contenido |
|---|---|
| `informe-definitivo-telemetria-hodom-hsc.md` | Análisis GPS × programación × atenciones |
| `analisis-datos-legacy-hodom-hsc.md` | 1.795 registros de pacientes analizados |

---

## Total: 22 documentos · ~350 KB de contenido estructurado

## Orden de lectura sugerido

### Para la reunión:
1. `guion-presentacion-dt-hodom-hsc.md` (el guión)
2. `presentacion-marp-dt-hodom-hsc.md` (las slides)

### Para el equipo de desarrollo:
1. `handoff-equipo-desarrollo-hodom-hsc.md` ⭐ (empezar aquí)
2. `hodom-os-v1.md` (visión completa)
3. `specs-sistema-web-hodom-hsc.md` (specs detalladas)

---

*Preparado por: Copiloto técnico Salubrista-HaH · 26 marzo 2026*
