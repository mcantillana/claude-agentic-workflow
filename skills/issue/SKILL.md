---
name: issue
description: Conecta el backlog de GitHub con el flujo agéntico. /issue new <descripción> explora la idea en diálogo (spike/bounded/architectural), la redacta y crea el issue; /issue list muestra los abiertos con ruta sugerida; /issue take <N> toma uno (asigna, propone slug y arranca /feature o /hotfix con el contexto y la ruta de trabajo ya resueltos). Requiere GitHub CLI (gh) autenticado y proyecto inicializado con /init. Se usa desde la sala de control.
argument-hint: new <descripción> | list | take <N>
---

# /issue — del issue de GitHub al worktree

Orquestador delgado sobre `/feature` y `/hotfix` (las skills de este plugin):
NO reemplaza su lógica — explora la idea, decide la ruta y arranca la skill
correcta con el slug y el contexto ya resueltos.

**El issue es el puente entre sesiones.** `/issue new` corre en la sala de
control y `/plan` corre después en el worktree, en otra sesión que todavía no
existe. Nada las conecta salvo lo que quede escrito: el cuerpo del issue
primero, y `docs/features/<slug>.md` después. Por eso `/issue new` guarda su
clasificación en el issue en vez de dejarla en la conversación.

## Precondición (todos los subcomandos)

- Sala de control: raíz del repo principal, branch principal (según
  `docs/AGENTIC_WORKFLOW.md`; si no existe, indica correr `/init`).
- `gh auth status` OK y el repo tiene remote en GitHub. Si no, detente y
  dilo (el resto del plugin funciona sin `gh`; esta skill no).

## Dos ejes independientes (no los confundas)

| Eje | Pregunta | Dónde vive |
|---|---|---|
| **Ruta de trabajo** | ¿cuánto diseño necesita antes de codear? | `**Ruta:**` en el cuerpo del issue |
| **Barrier** | ¿cabe en `1 feature = 1 worktree`? | señales al leer el issue |

Son ortogonales: un subsistema nuevo puede ser `architectural` y **no** ser
barrier (se construye entero en un worktree). Un cambio de DNS puede ser
trivial de diseñar y **sí** ser barrier.

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
| **Ruta `spike`** (del cuerpo)  | —                | NO asumir worktree (ver abajo) |

**Detección de barriers.** Independiente de la etiqueta, un issue es *barrier*
si al leerlo aparece una de estas señales: el trabajo no vive (solo) en el repo
(DNS, proxies, config de servicios externos, datos de prod); reescribe rutas o
archivos de todo el repo (mata el paralelismo de worktrees); no se puede
mergear/deployar atómicamente (ventana de transición, rollback por etapa); o es
un spike sin alcance cerrado. La definición completa y el camino de ejecución
en 3 fases (runbook en `docs/plans/` → fases normales deployadas en oscuro →
flip con la mesa congelada) están en la sección **Barriers** de
`docs/AGENTIC_WORKFLOW.md` — el contrato local manda.

## `/issue new <descripción>` — explorar, redactar y crear

Convierte una idea cruda en un issue **bien formado** que `/issue take` pueda
usar para sembrar el doc de la feature. NO crea worktree ni branch.

<HARD-GATE>
No crees el issue, no escribas código, no crees worktrees ni branches hasta
haberle mostrado al usuario el borrador y que lo apruebe. Vale para las tres
rutas: la ceremonia escala con la tarea, el gate de aprobación nunca.
</HARD-GATE>

### Paso 1 — clasifica la ruta, en voz alta

Antes de la primera pregunta, di qué ruta ves y por qué, para que el
usuario pueda corregirte:

- **spike** — una pregunta de factibilidad ("¿se puede...?", "¿es posible...?",
  "rápido y sucio está bien") cuyo entregable es **una respuesta, no código
  que se conserva**. Plantea la pregunta y cómo la responderías en 2-3 frases.
  Sin diseño largo.
- **bounded** — un cambio bien acotado sobre código **que ya existe en este
  repo**: un flag nuevo, un endpoint chico, un fix de un archivo. Entender de
  qué tipo de app se trata NO alcanza: bounded significa que el flujo que vas
  a cambiar **ya está aquí para leerlo**. Si no hay flujo existente que
  modificar, no es bounded.
- **architectural** — proyectos nuevos, subsistemas nuevos, cambios que
  reorganizan cómo encajan las piezas o alteran interfaces de las que otros
  dependen.

**Ante la duda entre dos rutas, toma la más pesada.** El trinquete va en un
solo sentido: si aparece complejidad escondida a mitad de camino, subes de
ruta — dilo y sube. Nada baja de ruta a mitad de camino.

Escribir un plan de más cuesta una tarde. Descubrir que hacía falta uno,
cuesta la feature.

### Paso 2 — explora y pregunta

Revisa primero el repo (archivos, docs, commits recientes) para no preguntar lo
que puedes deducir. Después:

- **Una pregunta por mensaje.** Si un tema necesita más, divídelo en varias.
- Prefiere opción múltiple (AskUserQuestion) cuando se pueda.
- Apunta a: propósito, restricciones, criterio de éxito.
- Si la idea abarca **varios subsistemas independientes**, dilo de entrada
  en vez de gastar preguntas refinando algo que primero hay que descomponer:
  propón partirlo en issues separados, cada uno con software funcionando por
  sí solo, y sigue con el primero.
- **YAGNI sin piedad:** saca de la propuesta todo lo que no se necesita ahora.

Cuánto preguntar según la ruta: *spike* casi nada (la pregunta ya es el
alcance) · *bounded* las que importan y nada más · *architectural* propósito,
restricciones, criterio de éxito, y 2-3 enfoques con sus trade-offs y tu
recomendación al frente.

### Paso 3 — redacta el cuerpo

En el idioma del usuario, con estas secciones:

```markdown
**Ruta:** architectural   <!-- spike | bounded | architectural -->

## Objetivo
## Contexto
## Alcance propuesto   <!-- idealmente un MVP acotado -->
## Preguntas abiertas  <!-- solo las reales; no las inventes -->
## Criterios de aceptación
```

La línea `**Ruta:**` es la que lee `/issue take`: **va siempre, primera, y
con ese formato exacto.**

En la ruta *architectural*, el cuerpo del issue **es** el documento de
diseño: enfoque elegido, alternativas descartadas y por qué. No escribas un
spec aparte — la sala de control no commitea en `MAIN`, y el plan detallado
se escribe después con `/plan`, en el worktree.

### Paso 4 — etiqueta

Capacidad nueva → `feature`/`enhancement`; algo roto → `bug`. Confirmala si
no es obvia y usa las que ya existan en el repo (`gh label list`). **La ruta
no lleva etiqueta**: vive en el cuerpo, así no hay que crear labels nuevos.

### Paso 5 — muestra el borrador y espera el sí

Es una acción de cara al repo. Mostralo completo y espera aprobación
explícita. Presentar el borrador y crear el issue en el mismo turno es
saltarse el gate.

### Paso 6 — crea y ofrece el siguiente paso

```bash
gh issue create --title "..." --label <etiqueta> --body "..."
```

Reporta número y URL. Ofrece `/issue take <N>` como siguiente paso; no lo
asumas.

### Señales de que te estás autoengañando

| Pensamiento | Realidad |
|---|---|
| "esto es muy simple para necesitar diseño" | Simple significa diseño corto, no cero diseño. Dos frases y aprobación. |
| "le pongo bounded y me salto el diseño" | Buscar la etiqueta que evita trabajo **es** la duda. Toma la ruta pesada. |
| "es bounded y el diseño es obvio, arranco mientras lo lee" | El gate es la aprobación, no el largo del diseño. Presenta y detente. |
| "conozco este tipo de app, es bounded" | Bounded mide el repo, no tu familiaridad. Si el flujo no está aquí, no es bounded. |
| "creció, pero ya casi termino, no reclasifico" | La complejidad escondida sube la ruta a mitad de camino. Detente y dilo. |
| "el spike funcionó, me quedo con el código" | El entregable de un spike es una respuesta. Conservar el código es un pedido nuevo: clasifícalo. |

## `/issue list` — abiertos con ruta sugerida

1. `gh issue list --state open --json number,title,labels,assignees,url,body`
2. De cada `body`, extrae la línea `**Ruta:**` (si no está, muestra `—`).
3. Deriva la ruta de skill según el mapa (marca los `bug` como "hotfix? —
   confirmar urgencia", los sin etiqueta como "preguntar", y los que por
   título/cuerpo huelan a barrier como "⚠️ barrier — no como feature normal").
4. Tabla: `#` | título | etiqueta(s) | **ruta** | asignado | skill sugerida.
   Recuerda que se toma uno con `/issue take <N>`.

## `/issue take <N>` — tomar y arrancar

Esta skill **no escribe planes ni código**: prepara el worktree y termina.
El plan lo escribe `/plan` después, en la sesión del worktree.

1. **Lee el issue a fondo:**
   ```bash
   gh issue view <N> --json number,title,body,labels,assignees,state,url --comments
   ```
   Si está cerrado, detente. Si tiene otro asignado, adviértelo y pregunta.

2. **Resuelve la ruta de trabajo** desde la línea `**Ruta:**` del cuerpo.
   - **Si no está** (issue creado a mano o por otra persona): clasifícalo
     ahora con los criterios del Paso 1 de `/issue new`, confírmalo con el
     usuario, y escríbelo al issue para que quede:
     `gh issue edit <N> --body "..."`.
   - **Si es `spike`:** no asumas worktree. Un spike entrega una respuesta;
     explica eso y pregunta si igual quiere un worktree descartable (que se
     cierra con `git worktree remove` + `git branch -D`, sin merge) o si lo
     resuelves en la sala de control.

3. **Chequea si es barrier** (ver Detección de barriers). Si lo es: NO crees
   worktree — explica por qué y ofrece el camino de barriers (sesión de
   planificación → runbook en `docs/plans/<slug>.md`). Solo si el usuario
   insiste explícitamente se sigue por `/feature`, dejando constancia.

4. **Decide la skill destino** (`feature` o `hotfix`) según el mapa, con
   confirmación en los casos que la piden.

5. **Propón un slug** kebab-case corto derivado del título y confírmalo.

6. **Asigna el issue:** `gh issue edit <N> --add-assignee @me`.

7. **Arranca la skill destino** pasándole **el slug, el objetivo del issue y
   la ruta de trabajo**. `/feature` escribe los tres en
   `docs/features/<slug>.md` — ese doc es lo único que cruza a la sesión del
   worktree, así que la ruta tiene que llegar ahí o se pierde.

8. **Cablea el cierre automático:** la referencia `Closes #<N>` debe quedar
   en el historial del branch (el kickoff de `/feature` la pone en el commit
   inicial y en el doc; en `/hotfix` va en el commit del fix). Así GitHub
   cierra el issue solo al mergear al branch principal — esta skill no cierra
   issues a mano: una sola fuente de verdad, el merge.

## Notas

- Para solo mirar un issue no hace falta esta skill: `gh issue view <N>`.
- Roadmap (no implementado en esta versión): `plan` (scoping de varios issues
  en paralelo) y `dispatch` (creación en lote de worktrees).
