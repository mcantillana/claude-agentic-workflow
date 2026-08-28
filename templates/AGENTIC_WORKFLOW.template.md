# Flujo de trabajo agéntico: worktrees + sesiones

<!-- contrato agentic-workflow v4 — NO borrar esta línea: /init update la usa
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
- Directorio de planes y runbooks: `{{PLANS_DIR}}/`
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
2. **Plan** (solo ruta `architectural`) — en la sesión del worktree: `/plan`
   escribe `{{PLANS_DIR}}/<slug>.md` y lo commitea en el branch de la feature.
3. **Desarrollo** — sesión dedicada en el worktree. Con plan, `/execute` lo
   ejecuta por subagentes (review por tarea + review final del branch); sin
   plan, TDD directo. Doc de la feature al día.
4. **Sincronización** — rebase contra `{{MAIN_BRANCH}}` al menos semanal y
   siempre antes del review: `git fetch origin && git rebase origin/{{MAIN_BRANCH}}`.
5. **Review** — desde la sala de control, sobre el branch pusheado.
6. **Cierre** — sala de control: `/feature close <slug>`. Merge `--no-ff`,
   limpieza de worktree/branch/entorno. El doc queda como registro.

## Rutas de trabajo (cuánto diseño antes de codear)

Cada trabajo entra por una de tres rutas. `/issue new` la clasifica y la deja
escrita en el cuerpo del issue (línea `**Ruta:**`); `/issue take` la traslada
a `docs/features/<slug>.md`; la sesión del worktree la obedece.

| Ruta | Qué es | En el worktree |
|---|---|---|
| **spike** | Pregunta de factibilidad. El entregable es **una respuesta**, no código que se conserva. | Probar lo más barato posible. Sin plan. El código queda marcado como descartable. |
| **bounded** | Cambio acotado sobre un flujo que **ya existe en este repo**. Un flag, un endpoint chico, un fix. | Implementar directo con TDD. **Sin documento de plan** — sería papeleo. |
| **architectural** | Subsistema nuevo, o cambio que reorganiza cómo encajan las piezas o altera interfaces de las que otros dependen. | `/plan` **antes** de escribir código (va a `{{PLANS_DIR}}/<slug>.md`), después `/execute`. |

Reglas:

1. **Bounded mide el repo, no tu familiaridad.** Si el flujo que vas a cambiar
   no está acá para leerlo, no es bounded.
2. **Ante la duda entre dos rutas, la más pesada.** El trinquete va en un solo
   sentido: la complejidad escondida sube la ruta a mitad de camino; nada baja.
3. **El gate de aprobación no escala con la ruta.** Hasta un spike se propone
   y se aprueba antes de ejecutarse. Lo que escala es el artefacto.
4. **La ruta y el barrier son ejes independientes.** Un subsistema nuevo puede
   ser `architectural` y caber perfecto en un worktree; un cambio de DNS puede
   ser trivial de diseñar y aun así ser barrier.

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
   entregable es un **runbook committeado** en `{{PLANS_DIR}}/<slug>.md`:
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

El runbook en `{{PLANS_DIR}}/` es el documento vivo del barrier (checklist con
estado real); al terminar, el resultado se registra como en un deploy grande.

## Notas del proyecto

{{PROJECT_NOTES}}
