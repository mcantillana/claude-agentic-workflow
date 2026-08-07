---
name: init
description: Inicializa el flujo agéntico (worktrees + sesiones de Claude) en un proyecto. Crea el contrato local docs/AGENTIC_WORKFLOW.md y la plantilla docs/features/TEMPLATE.md a partir de las respuestas del usuario. /init update migra un contrato existente a la versión vigente del template (agrega secciones nuevas sin pisar personalizaciones). Se corre desde la raíz del repo.
argument-hint: (sin argumentos) | update
---

# /init — inicializar el flujo agéntico en este proyecto

Siembra la **capa local** que las demás skills del plugin (`/feature`,
`/hotfix`, `/issue`) leen como contrato: `docs/AGENTIC_WORKFLOW.md` y
`docs/features/TEMPLATE.md`. Sin esta capa, esas skills se detienen y piden
correr `/init` primero.

Las plantillas viven en `${CLAUDE_PLUGIN_ROOT}/templates/` (si esa variable no
está disponible, es el directorio `templates/` dos niveles arriba del
directorio base de esta skill).

## Pasos

1. **Verifica el terreno:**
   - Estás en la raíz de un repo git (`git rev-parse --show-toplevel` coincide
     con el cwd). Si no es repo, detente y ofrece `git init` primero.
   - No estás dentro de un worktree secundario (`git rev-parse --git-common-dir`
     debe ser `.git`).
   - Si `docs/AGENTIC_WORKFLOW.md` ya existe, NO sobreescribas: el proyecto ya
     está inicializado. Ofrece `/init update` (ver abajo) para migrarlo a la
     versión vigente del template, o revisarlo a mano.

2. **Detecta el branch principal:** `git symbolic-ref --short refs/remotes/origin/HEAD`
   (quita el prefijo `origin/`). Si no hay remote, usa el branch actual.
   Confírmalo con el usuario si hay ambigüedad (ej. existen `main` y `master`).

3. **Reúne el contrato preguntando lo mínimo** (usa AskUserQuestion; no
   interrogues por lo que puedas deducir del repo — mira antes `README`,
   `package.json`, `docker-compose*.yml`, `Makefile`):
   - **Entorno por worktree:** ¿cómo se corre este proyecto en desarrollo y
     cómo debería correrse dentro de un worktree sin chocar con la copia
     principal? (ej: `npm run dev` con otro puerto; `docker compose` con
     `COMPOSE_PROJECT_NAME`/puerto propio; o "no aplica"). Si el proyecto usa
     puertos, define la convención de asignación (ej: incrementales desde un
     puerto base) y déjala escrita.
   - **Archivos de entorno no versionados** que cada worktree necesita
     (ej: `.env`, `.env.local`). Propón los que veas en el repo que estén en
     `.gitignore`.
   - **Tests:** comando para correr la suite (o "no hay").
   - **Deploy:** cómo se despliega a producción, si aplica (lo usa
     `/hotfix close` para recordar el paso; puede ser "n/a").

4. **Crea los archivos:**
   - Copia `templates/AGENTIC_WORKFLOW.template.md` a `docs/AGENTIC_WORKFLOW.md`
     reemplazando los placeholders: `{{REPO_DIR}}` (ruta de la raíz),
     `{{MAIN_BRANCH}}`, `{{WORKTREES_DIR}}` (convención:
     `../<nombre-del-directorio-del-repo>-wt`), `{{ENV_FILES}}`,
     `{{ENV_INSTRUCTIONS}}`, `{{TEST_INSTRUCTIONS}}`, `{{DEPLOY_INSTRUCTIONS}}`,
     `{{PROJECT_NOTES}}` (lo que el usuario quiera dejar anotado; si nada,
     "—"). No dejes ningún `{{...}}` sin resolver.
   - Copia `templates/feature-TEMPLATE.md` a `docs/features/TEMPLATE.md` tal
     cual (crea el directorio `docs/features/`).

5. **Muestra el resumen** (branch principal, directorio de worktrees, entorno,
   archivos a copiar) y **commitea** los dos archivos con mensaje
   `docs: init agentic workflow` — pide confirmación antes del commit.

6. **Cierra indicando el siguiente paso:** `/feature <slug>` para la primera
   feature, y recuerda las dos reglas que más cuesta internalizar: merges solo
   desde la sala de control, y la memoria entre sesiones vive en
   `docs/features/<slug>.md`.

## `/init update` — migrar el contrato a la versión vigente

Actualiza un `docs/AGENTIC_WORKFLOW.md` creado con una versión anterior del
template, **sin pisar las personalizaciones del proyecto**. El mecanismo:

1. **Determina las dos versiones:**
   - La del template: comentario `<!-- contrato agentic-workflow vN ... -->`
     en `templates/AGENTIC_WORKFLOW.template.md`.
   - La del contrato local: mismo comentario en `docs/AGENTIC_WORKFLOW.md`.
     **Si no existe el comentario, el contrato es v1.**
   - Si ya están iguales: dilo y termina (no hay nada que migrar).
   - Si el contrato local NO nació de esta plantilla (estructura ajena,
     escrito a mano): no lo toques — muestra qué secciones del template le
     faltarían y deja que el usuario decida a mano.

2. **Lee `templates/CONTRACT_CHANGELOG.md`** y recorre las versiones desde la
   del contrato + 1 hasta la del template, acumulando:
   - Secciones **agregadas** → se copian tal cual desde el template, en la
     posición que indica el changelog. Si el proyecto ya tiene una sección
     con ese mismo título (la agregó a mano), no la dupliques ni la pises:
     repórtala como "ya presente, revisar diferencias a mano".
   - Secciones **cambiadas** → nunca se reemplazan en silencio: muestra la
     versión nueva junto a la local y pregunta con AskUserQuestion
     (reemplazar / conservar la local / decidir después).

3. **Aplica los cambios** en `docs/AGENTIC_WORKFLOW.md` y actualiza (o
   inserta, si era v1) el comentario de versión a la del template.

4. **Muestra el diff completo** (`git diff docs/AGENTIC_WORKFLOW.md`) y
   commitea con `docs: update agentic workflow contract to vN` — pide
   confirmación antes del commit.

5. Si el template de features (`docs/features/TEMPLATE.md`) también cambió en
   alguna versión del changelog, aplica el mismo criterio (agregar sin pisar).

Notas del modo update:

- Es **aditivo por diseño**: la fuente de verdad de lo local sigue siendo el
  proyecto. El changelog del contrato debe mantenerse **append-only** y cada
  versión nueva del template debe registrar ahí qué agrega/cambia — sin esa
  entrada, `/init update` no sabe migrar.
- Tras actualizar el plugin (`/plugin update` o pull del marketplace), correr
  `/init update` en cada proyecto es el paso que propaga el contrato. La skill
  puede sugerirlo, no automatizarlo: el contrato es del proyecto.

## Notas

- Esta skill NO crea worktrees ni toca código: solo deja el contrato.
- En proyectos donde ya existe un flujo propio con estos mismos archivos
  (ej: un `AGENTIC_WORKFLOW.md` escrito a mano), no lo pises: detente y
  pregunta. Las demás skills del plugin leen cualquier
  `docs/AGENTIC_WORKFLOW.md` válido, venga o no de esta plantilla.
