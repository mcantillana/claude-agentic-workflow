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

## v4 (2026-08-28)

<!-- Numerada v4 y no v3 porque la rama `feat/dl-dev-clickup-workflow` de
     upstream ya reclama v3 (Roles DL/DEV + ClickUp). Dos v3 distintos
     romperían /init update. -->

- **Agrega** la sección `## Rutas de trabajo (cuánto diseño antes de codear)`
  — las tres rutas (`spike` / `bounded` / `architectural`), qué hace cada una
  en el worktree y las cuatro reglas. Posición: entre `## Ciclo de vida` y
  `## Barriers`.
- **Agrega** el bullet `Directorio de planes y runbooks: {{PLANS_DIR}}/` en la
  lista de `## El modelo` (default `docs/plans`; ya era el directorio de los
  runbooks de barriers, ahora también el de los planes de features).
- **Cambia** `## Ciclo de vida`: nuevo paso 2 (**Plan**, solo ruta
  `architectural`) y renumeración de los siguientes; el paso de desarrollo
  nombra `/execute` como ejecutor del plan.
- **Cambia** `## Barriers`: `docs/plans/` pasa a `{{PLANS_DIR}}/` (mismo valor
  por defecto; solo se parametriza).
- **Cambia** `docs/features/TEMPLATE.md`: agrega los campos `Ruta` y `Plan` al
  encabezado y la sección `## Próximo paso` antes de `## Objetivo`.

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
