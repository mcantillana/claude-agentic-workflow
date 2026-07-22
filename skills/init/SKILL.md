---
name: init
description: Inicializa el flujo agéntico (worktrees + sesiones de Claude) en un proyecto. Crea el contrato local docs/AGENTIC_WORKFLOW.md y la plantilla docs/features/TEMPLATE.md a partir de las respuestas del usuario. Correr una sola vez por proyecto, desde la raíz del repo.
argument-hint: (sin argumentos)
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
   - Si `docs/AGENTIC_WORKFLOW.md` ya existe, detente: el proyecto ya está
     inicializado. Ofrece revisarlo/actualizarlo en vez de sobreescribir.

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

## Notas

- Esta skill NO crea worktrees ni toca código: solo deja el contrato.
- En proyectos donde ya existe un flujo propio con estos mismos archivos
  (ej: un `AGENTIC_WORKFLOW.md` escrito a mano), no lo pises: detente y
  pregunta. Las demás skills del plugin leen cualquier
  `docs/AGENTIC_WORKFLOW.md` válido, venga o no de esta plantilla.
