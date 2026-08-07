# Changelog del contrato (`docs/AGENTIC_WORKFLOW.md`)

Registro de versiones del **contrato local** que `/init` siembra desde
`AGENTIC_WORKFLOW.template.md`. Lo lee `/init update` para saber qué le falta
al contrato de un proyecto inicializado con una versión anterior.

Reglas del changelog:

- Cada versión lista las secciones que **agrega** (se insertan tal cual desde
  el template, en la posición indicada) y las que **cambia** (nunca se pisan
  automáticamente: `/init update` muestra la versión nueva y pregunta, porque
  el proyecto puede haberlas personalizado).
- La versión vigente del template está en el comentario
  `<!-- contrato agentic-workflow vN ... -->` bajo el H1.
- Un contrato **sin** comentario de versión se trata como **v1**.

## v2 (2026-08-06)

- **Agrega** la sección `## Barriers (trabajos que NO se toman como feature
  normal)` — definición, señales de detección y camino de ejecución en 3
  fases (runbook en `docs/plans/` → fases normales en oscuro → flip con la
  mesa congelada). Posición: antes de `## Notas del proyecto`.
- **Agrega** el comentario de versión bajo el H1 (los contratos v1 no lo
  tienen; `/init update` lo inserta al actualizar).

## v1 (2026-07-22)

Versión inicial: El modelo, Reglas duras, Archivos de entorno, Entorno por
worktree, Cómo correr los tests, Deploy, Ciclo de vida, Notas del proyecto.
