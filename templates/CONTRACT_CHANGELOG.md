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

## v3 (2026-08-11)

- **Agrega** la sección `## Roles: DL (Delivery Lead) y DEV` — tabla de roles,
  la regla de que el DEV cierra de punta a punta, y el layout multi-repo (una
  carpeta por cliente). Posición: después de `## El modelo`, antes de
  `## Reglas duras`.
- **Agrega** la sección `## ClickUp (tareas)` — integración opcional con
  ClickUp: bloque de config (`{{CLICKUP_CONFIG}}`) con folder/list/custom
  field/handle del DL y mapa de estados (crear → tomar → cerrar). Posición:
  después de `## Deploy (usado por /hotfix close)`, antes de `## Ciclo de vida`.
  En proyectos sin ClickUp la sección dice `No aplica`.

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
