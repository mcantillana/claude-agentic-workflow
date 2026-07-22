# Flujo de trabajo agéntico: worktrees + sesiones

> Este archivo es el **contrato local** del flujo agéntico en este proyecto.
> Lo crean y lo leen las skills del plugin `agentic-workflow` (`/feature`,
> `/hotfix`, `/issue`). Ajusta las secciones marcadas a la realidad del
> proyecto; las skills obedecen lo que diga aquí.

## El modelo

**1 feature = 1 worktree = 1 branch = 1 sesión de Claude.**

| Rol | Dónde | Qué hace |
|---|---|---|
| Sala de control | `{{REPO_DIR}}` (branch `{{MAIN_BRANCH}}`) | Kickoffs, merges, hotfixes, operación |
| Sesión de feature | `{{WORKTREES_DIR}}/<slug>` | Todo el desarrollo de esa feature |

- Branch principal: `{{MAIN_BRANCH}}`
- Directorio de worktrees: `{{WORKTREES_DIR}}/`
- Convención de branches: `feature/<slug>` y `hotfix/<slug>`

## Reglas duras

1. **Una sesión de Claude por worktree.** Nunca dos sesiones sobre el mismo
   directorio a la vez.
2. **Entorno completo o nada.** Un worktree usa el entorno compartido *o*
   levanta el suyo completo. Jamás mezclar componentes de dos entornos.
3. **Merges a `{{MAIN_BRANCH}}` solo desde la sala de control.** Las sesiones
   de feature pushean su branch; no mergean.
4. **La memoria entre sesiones vive en `docs/features/<slug>.md`,** no en la
   memoria del agente (que está anclada al directorio y a la sesión).
5. **El review lo hace una sesión que no es la autora** (normalmente la sala
   de control, sobre el branch pusheado).

## Archivos de entorno (no versionados)

Archivos que el kickoff debe copiar desde la sala de control a cada worktree
nuevo (déjalo vacío si no aplica):

{{ENV_FILES}}

## Entorno por worktree

Cómo dejar un worktree **ejecutable** (no solo testeable). El kickoff y la
sesión siguen estas instrucciones:

{{ENV_INSTRUCTIONS}}

## Cómo correr los tests

{{TEST_INSTRUCTIONS}}

## Deploy (usado por /hotfix close)

{{DEPLOY_INSTRUCTIONS}}

## Ciclo de vida

1. **Kickoff** — sala de control: `/feature <slug>`. Crea worktree + branch,
   copia archivos de entorno, crea `docs/features/<slug>.md`.
2. **Desarrollo** — sesión dedicada en el worktree. Doc de la feature al día.
3. **Sincronización** — rebase contra `{{MAIN_BRANCH}}` al menos semanal y
   siempre antes del review: `git fetch origin && git rebase origin/{{MAIN_BRANCH}}`.
4. **Review** — desde la sala de control, sobre el branch pusheado.
5. **Cierre** — sala de control: `/feature close <slug>`. Merge `--no-ff`,
   limpieza de worktree/branch/entorno. El doc queda como registro.

## Notas del proyecto

{{PROJECT_NOTES}}
