---
name: issue
description: Conecta el backlog de GitHub con el flujo agéntico. /issue new <descripción> redacta y crea un issue bien formado; /issue list muestra los abiertos con ruta sugerida; /issue take <N> toma uno (asigna, propone slug y arranca /feature o /hotfix con el contexto del issue). Requiere GitHub CLI (gh) autenticado y proyecto inicializado con /init. Se usa desde la sala de control.
argument-hint: new <descripción> | list | take <N>
---

# /issue — del issue de GitHub al worktree

Orquestador delgado sobre `/feature` y `/hotfix` (las skills de este plugin):
NO reemplaza su lógica — lee el issue, decide la ruta y arranca la skill
correcta con el slug y el contexto ya resueltos.

## Roles

`/issue new` es el paso del **DL** (refina y crea la tarea); `/issue take` es
el paso del **DEV** (la toma y arranca a desarrollar). Ver la sección
`## Roles: DL y DEV` del contrato.

## Precondición (todos los subcomandos)

- Sala de control: raíz del repo principal, branch principal (según
  `docs/AGENTIC_WORKFLOW.md`; si no existe, indica correr `/init`).
- `gh auth status` OK y el repo tiene remote en GitHub. Si no, detente y
  dilo (el resto del plugin funciona sin `gh`; esta skill no).

## ClickUp (si el contrato lo tiene)

Lee la sección `## ClickUp (tareas)` del contrato. Si dice `No aplica`, omite
todos los pasos de ClickUp de esta skill y trabaja solo con GitHub. Si tiene
config (folder/list/custom field/handle del DL/mapa de estados), sincroniza
según se indica en cada subcomando, usando las tools del MCP de ClickUp
(`clickup_create_task`, `clickup_update_task`, `clickup_create_comment`,
`clickup_search`/`clickup_filter_tasks`). **Degradá con gracia:** si el MCP no
está conectado, seguí el flujo de GitHub, avisá que la parte de ClickUp quedó
pendiente y anotá qué faltó hacer a mano.

## Mapa de ruteo (etiqueta del issue → skill)

La etiqueta da el **default**, pero NUNCA rutees un `bug` a `/hotfix` sin
confirmar: `/hotfix` es ceremonia de **incidente de producción** (post-mortem
obligatorio, deploy urgente). Un bug menor no la necesita.

| Etiqueta(s)                    | Ruta por defecto | Acción                       |
|--------------------------------|------------------|------------------------------|
| `feature` / `enhancement`      | `/feature`       | Directo                      |
| `bug` + urgente / afecta prod  | `/hotfix`        | Confirmar urgencia antes     |
| `bug` no urgente               | `/feature`       | Branch normal, sin ceremonia |
| sin etiqueta / mixta / dudosa  | —                | Preguntar al usuario         |
| **barrier** (por señales, no etiqueta) | camino de barriers | NO crear worktree (ver abajo) |

**Detección de barriers.** Independiente de la etiqueta, un issue es *barrier*
si al leerlo aparece una de estas señales: el trabajo no vive (solo) en el repo
(DNS, proxies, config de servicios externos, datos de prod); reescribe rutas o
archivos de todo el repo (mata el paralelismo de worktrees); no se puede
mergear/deployar atómicamente (ventana de transición, rollback por etapa); o es
un spike sin alcance cerrado. La definición completa y el camino de ejecución
en 3 fases (runbook en `docs/plans/` → fases normales deployadas en oscuro →
flip con la mesa congelada) están en la sección **Barriers** de
`docs/AGENTIC_WORKFLOW.md` — el contrato local manda.

## `/issue new <descripción>` — redactar y crear

Convierte una idea cruda en un issue **bien formado** que `/issue take`
pueda usar para sembrar el doc de la feature. NO crea worktree ni branch.

1. Entiende la idea; si es ambigua en alcance, pregunta 1-2 cosas mínimas.
2. Decide la etiqueta (capacidad nueva → `feature`/`enhancement`; algo roto
   → `bug`) y confírmala si no es obvia. Usa las etiquetas que existan en el
   repo (`gh label list`).
3. Redacta el cuerpo estructurado (en el idioma del usuario): **Objetivo**,
   **Contexto**, **Alcance propuesto** (idealmente un MVP acotado),
   **Preguntas abiertas** (no las inventes), **Criterios de aceptación**.
4. **Muestra el borrador y confirma** antes de crear (es una acción de cara
   al repo).
5. Crea: `gh issue create --title "..." --label <etiqueta> --body "..."` y
   reporta número y URL.
6. **Crea la tarea de ClickUp** (si el contrato tiene ClickUp). Es el cableado
   que hace del DL el dueño de la creación:
   - `clickup_create_task` en la **List ID** del contrato, con el título del
     issue, una descripción corta (objetivo + link al issue) y **status =
     estado de creación** del mapa (`PRIORIZADAS` por defecto).
   - Setea el **custom field** del contrato (link al issue) con el número/URL
     del issue.
   - Comenta en el issue de GitHub la URL de la tarea de ClickUp
     (`gh issue comment <N> --body "ClickUp: <url>"`), para que `/issue take` y
     los `close` reencuentren la tarea leyendo el issue.
   - Reporta el ID/URL de la tarea creada. Si el MCP no está: dilo y deja anotado
     "crear tarea de ClickUp a mano en <list>, status PRIORIZADAS, campo link = #N".
7. Ofrece el siguiente paso, no lo asumas: pasar la tarea a un DEV (queda en
   `PRIORIZADAS`, lista para `/issue take <N>`), o dejarla en el backlog.

## `/issue list` — abiertos con ruta sugerida

1. `gh issue list --state open --json number,title,labels,assignees,url`
2. Deriva la ruta sugerida según el mapa (marca los `bug` como "hotfix? —
   confirmar urgencia", los sin etiqueta como "preguntar", y los que por
   título/cuerpo huelan a barrier como "⚠️ barrier — no como feature normal").
3. Tabla: `#` | título | etiqueta(s) | asignado | ruta sugerida. Recuerda que
   se toma uno con `/issue take <N>`.

## `/issue take <N>` — tomar y arrancar

1. **Lee el issue a fondo:**
   ```bash
   gh issue view <N> --json number,title,body,labels,assignees,state,url --comments
   ```
   Si está cerrado, detente. Si tiene otro asignado, adviértelo y pregunta.
2. **Decide la ruta** según el mapa (con confirmación en los casos que la
   piden). **Si el issue es un barrier** (ver Detección de barriers): NO crees
   worktree — explica por qué y ofrece el camino de barriers (sesión de
   planificación → runbook en `docs/plans/<slug>.md`). Solo si el usuario
   insiste explícitamente se sigue por `/feature`, dejando constancia.
3. **Propón un slug** kebab-case corto derivado del título y confírmalo.
4. **Asigna el issue:** `gh issue edit <N> --add-assignee @me`.
4b. **Mueve la tarea de ClickUp** (si el contrato tiene ClickUp): ubica la tarea
   vinculada — leé el comentario `ClickUp: <url>` del issue, o buscala por el
   custom field = #N (`clickup_search`/`clickup_filter_tasks`). Con
   `clickup_update_task` pásala al **estado de "tomada"** del mapa (`EN PROGRESO`
   por defecto) y asignala al DEV (`clickup_resolve_assignees` / el member que
   corre esto). Si el MCP no está o no encontrás la tarea: avisá y seguí.
5. **Arranca la skill destino** (`feature` o `hotfix` de este plugin) con el
   slug confirmado, pasándole como contexto el objetivo del issue para que el
   doc de la feature (o la descripción del hotfix) lo refleje.
6. **Cablea el cierre automático:** la referencia `Closes #<N>` debe quedar
   en el historial del branch (el kickoff de `/feature` la pone en el commit
   inicial y en el doc; en `/hotfix` va en el commit del fix). Así GitHub
   cierra el issue solo al mergear al branch principal — esta skill no cierra
   issues a mano: una sola fuente de verdad, el merge.

## Notas

- Para solo mirar un issue no hace falta esta skill: `gh issue view <N>`.
- Roadmap (no implementado en esta versión): `plan` (scoping de varios issues
  en paralelo) y `dispatch` (creación en lote de worktrees).
