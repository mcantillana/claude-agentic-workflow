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
| `/init` | Inicializa el flujo en un proyecto: crea el contrato local `docs/AGENTIC_WORKFLOW.md` y `docs/features/TEMPLATE.md` preguntando lo mínimo (entorno, tests, deploy) |
| `/feature <slug>` · `list` · `close <slug>` | Ciclo de vida de una feature: kickoff (worktree + branch + doc), estado de las activas, cierre con merge `--no-ff` y limpieza |
| `/hotfix <slug>` · `close <slug>` | Bug de producción con ceremonia mínima: worktree propio, fix mínimo + test obligatorio, merge primero y deploy después, post-mortem al cerrar |
| `/issue new` · `list` · `take <N>` | Backlog de GitHub → flujo: redacta issues bien formados, lista con ruta sugerida, toma uno y arranca `/feature` o `/hotfix` con `Closes #N` cableado (requiere `gh`) |
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

## Roadmap

- `/issue plan` y `/issue dispatch` (scoping paralelo y kickoff en lote)
- Reglas de colindancia específicas para proyectos con migraciones de BD
- Hook opcional de verificación en `feature close` (tests antes del merge)
