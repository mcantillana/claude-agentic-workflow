# agentic-workflow — plugin de Claude Code

Flujo agéntico de desarrollo empaquetado como plugin:

> **1 feature = 1 worktree = 1 branch = 1 sesión de Claude.**

Cada trabajo vive aislado en su propio git worktree, con su branch y su
sesión de agente dedicada. Un directorio fijo (la **sala de control**, la
raíz del repo en el branch principal) concentra kickoffs, merges y
operación. La memoria entre sesiones vive en `docs/features/<slug>.md`,
committeada — no en la memoria del agente, que está anclada al directorio.

## Comandos

| Comando | Qué hace |
|---|---|
| `/init` · `update` | Inicializa el flujo en un proyecto (contrato local `docs/AGENTIC_WORKFLOW.md` + `docs/features/TEMPLATE.md`, preguntando lo mínimo); `update` migra un contrato existente a la versión vigente del template — agrega las secciones nuevas sin pisar personalizaciones (versionado en `templates/CONTRACT_CHANGELOG.md`) |
| `/feature <slug>` · `list` · `close <slug>` | Ciclo de vida de una feature: kickoff (worktree + branch + doc), estado de las activas, cierre con merge `--no-ff` y limpieza |
| `/hotfix <slug>` · `close <slug>` | Bug de producción con ceremonia mínima: worktree propio, fix mínimo + test obligatorio, merge primero y deploy después, post-mortem al cerrar |
| `/issue new` · `list` · `take <N>` | Backlog → flujo con dos roles: el **DL** redacta el issue y crea la tarea de ClickUp linkeada (`new`); el **DEV** toma uno (`take`), lo mueve a *En progreso* y arranca `/feature` o `/hotfix` con `Closes #N` cableado (requiere `gh`; ClickUp opcional) |
| `/commit [scope]` | Crea un Conventional Commit en inglés (subject imperativo ≤ 72 chars, body con bullets), sin atribución de IA |
| `/push [branch]` | Pushea los commits al branch indicado (o al actual), con `-u` si no hay upstream; nunca hace force-push |

En un proyecto sin conflicto de nombres los comandos funcionan con el nombre
corto (`/feature x`); el nombre canónico es `/agentic-workflow:feature`.

## Instalación

Desde GitHub (requiere acceso al repo):

```
/plugin marketplace add mcantillana/claude-agentic-workflow
/plugin install agentic-workflow@mcantillana
```

Para desarrollo local (itera sin pushear):

```
/plugin marketplace add ~/docker/claude-agentic-workflow
```

Luego, en cada proyecto donde quieras el flujo: `/init` (una sola vez).

## Roles: DL y DEV

El flujo se opera entre dos roles, definidos en el contrato local:

- **DL (Delivery Lead)** — desde Claude Desktop → Claude Code, con todos los
  repos del cliente clonados (una carpeta por cliente). Refina la tarea y corre
  `/issue new`: crea el issue de GitHub **y** la tarea de ClickUp linkeadas, en
  estado *Priorizadas*.
- **DEV** — en el repo. `/issue take` (mueve la tarea a *En progreso*) →
  desarrolla en su worktree → `/commit` + `/push` → code review → `/feature
  close` (mergea, cierra el issue, mueve la tarea a *Deploy/Completadas* y avisa
  al DL con un comentario en la tarea).

En un escenario multi-repo el DL tiene `~/<cliente>/<repo>/` y cada repo se
inicializa con `/init` por separado.

## ClickUp (opcional)

Si el proyecto rastrea tareas en ClickUp, `/init` guarda en el contrato la
folder, la list, el custom field que linkea la tarea con el issue de GitHub, el
handle del DL a avisar y el mapa de estados. Las skills sincronizan estado y
avisos vía el MCP de ClickUp; si el MCP no está conectado, siguen el flujo de
GitHub y avisan qué quedó pendiente. Sin ClickUp, la sección del contrato dice
`No aplica` y todo funciona igual solo con GitHub.

## Diseño: núcleo genérico + contrato local

Las skills no asumen ningún stack. Todo lo específico del proyecto vive en
`docs/AGENTIC_WORKFLOW.md` (creado por `/init`), que las skills leen como
**contrato**: branch principal, directorio de worktrees, archivos de entorno
a copiar, cómo dejar un worktree ejecutable, cómo correr tests, cómo se
despliega. Si el contrato contradice una skill, gana el contrato.

Requisitos: `git ≥ 2.5`, Claude Code, y opcionalmente `gh` (para `/issue`), el
MCP de ClickUp (para la sincronización de tareas, si el proyecto la usa) y el
runtime del proyecto (Docker, node, etc.) para los entornos por worktree.

## Convivencia con flujos existentes

Las skills de proyecto (`.claude/skills/` del repo) **ganan el nombre
corto**: si un repo ya tiene su propia skill `feature`, `/feature` sigue
ejecutando la local y la del plugin solo responde con prefijo. Instalar este
plugin no altera flujos existentes.

## Barriers

No todo trabajo calza en `1 feature = 1 worktree`. Un **barrier** es un issue
que vive fuera del repo (DNS, proxies, servicios externos), reescribe el
terreno de los demás (reorganizaciones estructurales), no se puede
mergear/deployar atómicamente, o es un spike sin alcance cerrado. Para esos,
`/issue take` **no crea worktree**: redirige al camino de barriers — sesión de
planificación que produce un runbook en `docs/plans/<slug>.md`, descomposición
en fases normales deployadas *en oscuro*, y un flip final desde la sala de
control con cero worktrees activos. La definición completa queda en el
contrato local que crea `/init` (`docs/AGENTIC_WORKFLOW.md`).

## Roadmap

- `/issue plan` y `/issue dispatch` (scoping paralelo y kickoff en lote)
- Reglas de colindancia específicas para proyectos con migraciones de BD
- Hook opcional de verificación en `feature close` (tests antes del merge)
