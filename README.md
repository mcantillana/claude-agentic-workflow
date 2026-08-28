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
| `/issue new` · `list` · `take <N>` | Backlog de GitHub → flujo: explora la idea en diálogo y la clasifica (`spike` / `bounded` / `architectural`), redacta el issue, lista con ruta sugerida, toma uno y arranca `/feature` o `/hotfix` con `Closes #N` cableado (requiere `gh`) |
| `/plan` | Escribe el plan de implementación de la feature **dentro del worktree**, antes de codear: mapa de archivos, tareas bite-sized con ciclo TDD, sin placeholders. Solo para la ruta `architectural` |
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

## Rutas de trabajo: del issue al plan

El diseño no se hace dos veces. `/issue new` explora la idea en diálogo y la
clasifica en una de tres rutas, que deja escrita en el cuerpo del issue:

| Ruta | Qué es | Qué pasa en el worktree |
|---|---|---|
| `spike` | pregunta de factibilidad; el entregable es una respuesta | probar barato, código descartable |
| `bounded` | cambio acotado sobre un flujo que ya existe en el repo | TDD directo, **sin plan** |
| `architectural` | subsistema nuevo o cambio que reorganiza las piezas | `/plan` antes de codear |

La gracia está en cómo viaja esa decisión. `/issue take` **no escribe planes
ni código**: prepara el worktree y termina. La sesión que va a escribir el
plan todavía no existe, así que no hay nada que invocar — lo único que cruza
el límite entre sesiones son los archivos committeados. Por eso la ruta se
copia del issue a `docs/features/<slug>.md`, en una sección **Próximo paso**
que la sesión nueva lee y ejecuta.

```
/issue new ──▶ issue #42 (**Ruta:** architectural)
                    │
/issue take 42 ──▶ worktree + docs/features/<slug>.md ("Próximo paso: /plan")
                    │
              sesión del worktree ──▶ /plan ──▶ docs/plans/<slug>.md ──▶ TDD
```

`/plan` no necesita argumentos: `git branch --show-current` da el slug, el
slug da el doc, y el doc da objetivo, ruta y issue de origen.

## Diseño: núcleo genérico + contrato local

Las skills no asumen ningún stack. Todo lo específico del proyecto vive en
`docs/AGENTIC_WORKFLOW.md` (creado por `/init`), que las skills leen como
**contrato**: branch principal, directorio de worktrees, archivos de entorno
a copiar, cómo dejar un worktree ejecutable, cómo correr tests, cómo se
despliega. Si el contrato contradice una skill, gana el contrato.

Requisitos: `git ≥ 2.5`, Claude Code, y opcionalmente `gh` (solo `/issue`)
y el runtime del proyecto (Docker, node, etc.) para los entornos por
worktree.

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
