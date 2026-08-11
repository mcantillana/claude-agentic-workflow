# Flujo de trabajo agéntico: worktrees + sesiones

<!-- contrato agentic-workflow v3 — NO borrar esta línea: /init update la usa
     para saber qué secciones nuevas faltan en este proyecto -->

> Este archivo es el **contrato local** del flujo agéntico en este proyecto.
> Lo crean y lo leen las skills del plugin `agentic-workflow` (`/feature`,
> `/hotfix`, `/issue`). Ajusta las secciones marcadas a la realidad del
> proyecto; las skills obedecen lo que diga aquí. Cuando el plugin traiga una
> versión de contrato más nueva, `/init update` agrega lo que falte sin tocar
> tus personalizaciones.

## El modelo

**1 feature = 1 worktree = 1 branch = 1 sesión de Claude.**

| Rol | Dónde | Qué hace |
|---|---|---|
| Sala de control | `{{REPO_DIR}}` (branch `{{MAIN_BRANCH}}`) | Kickoffs, merges, hotfixes, operación |
| Sesión de feature | `{{WORKTREES_DIR}}/<slug>` | Todo el desarrollo de esa feature |

- Branch principal: `{{MAIN_BRANCH}}`
- Directorio de worktrees: `{{WORKTREES_DIR}}/`
- Convención de branches: `feature/<slug>` y `hotfix/<slug>`

## Roles: DL (Delivery Lead) y DEV

Este flujo se opera entre dos roles. Un mismo repo los cruza; la diferencia es
qué skill corre cada uno y en qué estado deja la tarea.

| Rol | Herramientas | Hace |
|---|---|---|
| **DL** (Delivery Lead) | Claude Desktop → Claude Code, con todos los repos del cliente clonados | Refina la tarea, `/issue new` (crea el issue de GitHub + la tarea de ClickUp linkeadas), prioriza |
| **DEV** | Claude Code en el repo | `/issue take` → desarrolla en su worktree → `/commit` + `/push` → code review → `/feature close` (mergea, cierra el issue, mueve la tarea en ClickUp y avisa al DL) |

En este flujo **el DEV cierra de punta a punta** (mergea desde su propia sala de
control): la regla 5 de abajo ("review por sesión ajena") se cumple con el code
review antes del cierre, no con un merge hecho por otra persona.

**Layout multi-repo (una carpeta por cliente).** El DL mantiene una carpeta por
cliente y, dentro, todos los repos de ese cliente clonados:

    ~/<cliente>/
      <repo-a>/   ← /init acá
      <repo-b>/   ← /init acá

Cada repo se inicializa con `/init` por separado. Si varios repos del mismo
cliente comparten tablero de ClickUp, apuntan a la misma folder/list.

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

## ClickUp (tareas)

Integración **opcional**. Si este proyecto rastrea tareas en ClickUp, las skills
`/issue`, `/feature` y `/hotfix` sincronizan estado y avisos usando las tools
del MCP de ClickUp (`clickup_create_task`, `clickup_update_task`,
`clickup_create_comment`, etc.) — se referencian por su nombre, sin importar el
ID del server. Si el MCP no está conectado, las skills **degradan con gracia**:
siguen el flujo de GitHub y avisan que la parte de ClickUp quedó pendiente.

Si el proyecto **no** usa ClickUp, esta sección dice `No aplica` y las skills la
omiten por completo.

{{CLICKUP_CONFIG}}

## Ciclo de vida

1. **Kickoff** — sala de control: `/feature <slug>`. Crea worktree + branch,
   copia archivos de entorno, crea `docs/features/<slug>.md`.
2. **Desarrollo** — sesión dedicada en el worktree. Doc de la feature al día.
3. **Sincronización** — rebase contra `{{MAIN_BRANCH}}` al menos semanal y
   siempre antes del review: `git fetch origin && git rebase origin/{{MAIN_BRANCH}}`.
4. **Review** — desde la sala de control, sobre el branch pusheado.
5. **Cierre** — sala de control: `/feature close <slug>`. Merge `--no-ff`,
   limpieza de worktree/branch/entorno. El doc queda como registro.

## Barriers (trabajos que NO se toman como feature normal)

Un **barrier** es un trabajo al que el modelo `1 feature = 1 worktree = 1
branch` le queda chico. Señales (basta una):

- **El trabajo no vive (solo) en el repo**: DNS, proxies/vhosts del host,
  config de servicios externos, datos de producción. Un worktree capturaría
  una fracción del cambio.
- **Reescribe el terreno de los demás**: reorganización estructural que mueve
  rutas/archivos de todo el repo — cualquier feature paralela muere en
  conflictos.
- **No se mergea/deploya atómicamente**: necesita ventana de transición,
  verificación por etapas y rollback por paso (upgrades de plataforma o BD,
  migraciones de datos en caliente).
- **Spike sin alcance cerrado**: primero investigar, después decidir qué
  construir.

Regla dura: **`/issue take` no crea worktree para un barrier**; si el usuario
insiste, es una decisión explícita.

Cómo se ejecuta (3 fases):

1. **Planificar antes de tocar nada.** Sesión dedicada (plan mode) cuyo
   entregable es un **runbook committeado** en `docs/plans/<slug>.md`:
   secuencia de pasos a nivel de comandos, verificación tras cada paso,
   criterio seguir/abortar y rollback por etapa. El issue define el *qué*;
   el runbook baja al *cómo*.
2. **Descomponer en fases donde cada una SÍ sea normal.**
   - *Fases de repo* → worktrees chicos vía `/feature`, mergeados y
     deployados **en oscuro** (el código llega a producción sin cambiar nada
     visible hasta el flip).
   - *Fases de infra* → operaciones de la sala de control, como un deploy:
     paso a paso contra el runbook, verificando entre pasos.
   - *El flip* → sala de control, en ventana elegida, con el rollback a mano.
3. **Congelar la mesa.** El flip se ejecuta con **cero worktrees activos**:
   nada mergeando en paralelo mientras la infra está a medio camino.

El runbook en `docs/plans/` es el documento vivo del barrier (checklist con
estado real); al terminar, el resultado se registra como en un deploy grande.

## Notas del proyecto

{{PROJECT_NOTES}}
