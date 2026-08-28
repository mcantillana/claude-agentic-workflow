---
name: execute
description: Ejecuta un plan de implementación despachando un subagente fresco por tarea, con review de spec y calidad después de cada una y un review amplio del branch al final. Se corre DENTRO del worktree de la feature, después de /plan. Mantiene un ledger que sobrevive a la compactación. Requiere proyecto inicializado con /init.
argument-hint: (sin argumentos) | <ruta del plan>
---

# /execute — ejecutar el plan por subagentes

Un subagente fresco por tarea, review de spec + calidad después de cada una,
y un review amplio de todo el branch al final.

**Por qué subagentes:** delegas cada tarea a un agente con contexto aislado.
Construyéndole las instrucciones con precisión, se mantiene enfocado. Nunca
hereda tu historial: tú armas exactamente lo que necesita. Además preservas
tu propio contexto para coordinar.

**Principio:** subagente fresco por tarea + review por tarea (spec + calidad)
+ review amplio final = calidad alta con iteración rápida.

**Narración:** entre tool calls, a lo sumo una línea corta. El ledger y los
resultados llevan el registro.

## Dónde corre

**Dentro del worktree de la feature**, después de `/plan`. Si
`git rev-parse --git-common-dir` es `.git` estás en la sala de control:
detente y di en qué worktree hay que correrlo.

El worktree ya existe (lo creó `/feature`): no crees ninguno. Nunca empieces
a implementar sobre `MAIN`.

## Contrato local

Lee `docs/AGENTIC_WORKFLOW.md`: directorio de planes (`PLANS_DIR`), comando
de tests, branch principal. Sin plan no hay nada que ejecutar — si no existe
`PLANS_DIR/<slug>.md`, corre `/plan` primero.

## Ejecución continua

No pares a preguntar entre tareas. Ejecuta todas las del plan sin frenar.
"¿Sigo?" y los resúmenes de avance le hacen perder el tiempo al usuario: te
pidió ejecutar el plan, ejecútalo.

**Fallos, no bloqueos.** Un plan corriendo no espera a un humano. Conflictos,
ambigüedades, defectos del plan, un tope que hubieras querido exceder:
decídelos. El doc de la feature es la autoridad, el plan es su argumento, y
tu criterio resuelve lo que ninguno de los dos contesta. Registra cada
decisión en el ledger como `Fallo: <qué decidiste> — <por qué> — <qué cuesta
si te equivocas>`, y sigue. Un fallo equivocado cuesta retrabajo que el
usuario ve y revierte; una sesión detenida en una pregunta le cuesta el día
y no compra nada.

**Cuatro cosas te detienen, y solo estas:** una operación destructiva o
irreversible; una acción sensible en seguridad; un efecto fuera de este
worktree que por norma se pregunta antes (un merge, un push a branch
compartido, un deploy); y un plan tan roto que todo camino es adivinanza.

## Setup

La memoria de la conversación no sobrevive a la compactación. En sesiones
reales, controladores que perdieron el hilo re-despacharon secuencias enteras
de tareas ya completas — el fallo más caro observado. Lleva el progreso en un
**ledger en archivo**, no solo en todos.

- Cada plan tiene su workspace: corre `scripts/workspace PLAN_FILE` (de esta
  skill) — imprime el directorio git-ignored del plan
  (`<raíz-del-worktree>/.agentic/<slug>/`), donde viven todos los artefactos
  de ESTE plan: ledger, briefs, reportes, paquetes de review. El directorio
  de otro plan nunca es tuyo.
- Busca el ledger en `<workspace>/progress.md`. Si su primera línea nombra tu
  plan, las tareas con línea `Tarea <N>: completa` están HECHAS — no las
  re-despaches; retoma en la primera que no la tenga. Una tarea cuya última
  línea es una ronda de fix está a mitad del loop: retoma en la ronda
  siguiente. Un ledger cuya primera línea nombra otro plan es progreso ajeno:
  déjalo donde está y empieza el tuyo, fresco.
- Crea el ledger con su identidad en la primera línea:
  `# Ledger — plan: <ruta del plan>`.
- El ledger es tu mapa de recuperación: los commits que nombra existen en git
  aunque tu contexto ya no recuerde haberlos creado. Después de compactar,
  confía en el ledger y en `git log` antes que en tu memoria.
- `git clean -fdx` destruye el workspace (es scratch git-ignored); si pasa,
  recupera desde `git log`.

Lee el plan **una vez**, anota su contexto y sus Restricciones globales, y
crea un todo por tarea. Lee también `docs/features/<slug>.md`: es la
autoridad de la que el plan argumenta, y los conflictos dentro del plan se
resuelven contra él.

Antes de despachar la Tarea 1, escanea el plan buscando conflictos, y anota
qué chequeaste mientras lo haces:

- tareas que se contradicen entre sí o contra las Restricciones globales
- cualquier cosa que el plan mande explícitamente y que la rúbrica de review
  trate como defecto (un test que no afirma nada, duplicación literal de un
  bloque de lógica)

**La salida del escaneo es una tabla, no un veredicto.** Una fila por cada
par de tareas que comparta archivo o interfaz: las dos tareas, qué produce
una contra qué consume la otra, y qué encontraste. Una fila por cada tarea:
si su propio texto es coherente consigo mismo — los tests que especifica
contra el código que especifica, los archivos que crea contra los que después
toca. "El escaneo está limpio" sin esas filas no es un escaneo que corriste.

Escribe la tabla en el ledger. Falla sobre todo lo que encuentres antes de
empezar, y registra cada fallo. Si está limpio, sigue sin comentarios.

## Selección de modelo

Usa el modelo menos potente que resuelva cada rol, para ahorrar costo y ganar
velocidad.

- **Implementación mecánica** (funciones aisladas, spec claro, 1-2 archivos):
  modelo rápido y barato. La mayoría de las tareas son mecánicas cuando el
  plan está bien especificado.
- **Integración y criterio** (coordinación multi-archivo, debugging): modelo
  estándar.
- **Arquitectura y diseño:** el más capaz disponible. El review final de todo
  el branch es uno de estos.
- **Reviews:** mismo criterio, escalado al tamaño, complejidad y riesgo del
  diff. Un diff chico y mecánico no necesita el modelo más capaz; un cambio
  sutil de concurrencia sí. Los re-reviews acotados de fixes chicos van en
  gama barata o media.
- **Escalada del fix loop (rondas 4-5):** un escalón por encima del
  implementador que se trabó.

**Especifica siempre el modelo al despachar.** Omitirlo hereda el de tu
sesión — normalmente el más capaz y más caro — y anula esta sección en
silencio.

**El número de turnos pesa más que el precio por token.** El costo de reloj y
de contexto escala con cuántos turnos toma un subagente, y los modelos más
baratos suelen tomar 2-3× los turnos en trabajo multi-paso, saliendo más caro
en total. Usa gama media como piso para revisores y para implementadores que
trabajan desde descripciones en prosa. Cuando el texto de la tarea ya trae el
código completo a escribir, implementar es transcribir y testear: ahí sí, la
gama más barata. Los fixes mecánicos de un solo archivo también.

## El loop de tareas

**Agrupa trabajo chico de la misma forma.** Cuando el plan lista varias
tareas que son cada una una edición chica e independiente del mismo tipo (el
mismo fix de una línea, el mismo campo agregado en varios archivos), no
despaches un subagente por tarea. Compón UN brief que liste cada archivo y
su cambio, manda el lote a un solo subagente, y revisa su diff como una
unidad. Reserva un-despacho-por-tarea para trabajo que necesita criterio
propio, tests propios o superficie de review propia.

Todo lo que pegas en un prompt de despacho — y todo lo que un subagente te
imprime de vuelta — queda residente en tu contexto por el resto de la sesión
y se re-lee en cada turno posterior. **Pasa los artefactos como archivos.**

**Esperando subagentes:** nunca hagas polling con timeouts cortos, ni te
sientes en una espera silenciosa e indefinida. Mientras tengas trabajo local
— actualizar el ledger, armar el próximo paquete de review, leer reportes —
sigue trabajando; los resultados llegan solos. Cuando estés genuinamente
ocioso, espera en tramos acotados, y entre tramos publica una línea de estado
y reconcilia los hijos vivos: enuméralos y persigue a los que terminaron sin
reportar.

### 1. Despachar al implementador

Registra BASE (`git rev-parse HEAD`) antes de despachar — el paquete de
review y los diffs de las rondas de fix lo necesitan.

- **Brief de la tarea:** corre `scripts/task-brief PLAN_FILE N` — extrae el
  texto completo de la tarea a un archivo e imprime la ruta. Compón el
  despacho de modo que el brief siga siendo la única fuente de requisitos.
  Tu despacho lleva: (1) una línea sobre dónde encaja esta tarea en el
  proyecto; (2) la ruta del brief, presentada como "lee esto primero — son
  tus requisitos, con los valores exactos a usar tal cual"; (3) interfaces y
  decisiones de tareas anteriores que el brief no puede conocer; (4) tu
  resolución de cualquier ambigüedad que hayas notado en el brief; (5) la
  ruta del archivo de reporte y el contrato de reporte. Los valores exactos
  (números, strings mágicos, firmas, casos de test) aparecen **solo** en el
  brief. Nunca le hagas leer el plan entero a un subagente.
- **Archivo de reporte:** nómbralo según el brief (`…/tarea-N-brief.md` →
  `…/tarea-N-reporte.md`) y ponlo en el prompt. El implementador escribe el
  reporte completo ahí y devuelve solo estado, commits, un resumen de tests
  de una línea y sus dudas.
- Un prompt de despacho describe **una tarea**, no la historia de la sesión.
  No pegues resúmenes acumulados de tareas previas ("estado tras las Tareas
  1-3"): un despacho real llegó a 42k caracteres de los cuales 99% era
  historia pegada. Un subagente fresco necesita su tarea, las interfaces que
  toca y las restricciones globales. Nada más.
- El despacho lleva el contrato de no-subagentes (está en la plantilla): el
  implementador nunca despacha subagentes — ni ayudantes, y menos un revisor.
  El review llega de tú, después del reporte. En sesiones reales, cada
  revisor que un worker generó duplicó el review que el controlador despachó
  igual: un asiento de review extra por tarea.
- Si una tarea anterior dejó un hallazgo aparcado en el área que esta toca,
  lleva un puntero a esa entrada del ledger en el despacho.
- Registra la identidad del agente implementador: las rondas 1-3 del fix loop
  lo retoman a él.
- **Nunca despaches implementadores en paralelo** (conflictos).

Plantilla: [implementer-prompt.md](implementer-prompt.md)

### 2. Manejar el reporte

Cuatro estados posibles:

**DONE:** arma el paquete de review (`scripts/review-package PLAN_FILE BASE
HEAD` — imprime la ruta única que escribió; BASE es el commit que registraste
antes de despachar, **nunca `HEAD~1`**, que descarta en silencio todos los
commits menos el último de una tarea multi-commit) y despacha al revisor con
esa ruta.

**DONE_WITH_CONCERNS:** completó pero con dudas. Leelas antes de seguir. Si
son sobre corrección o alcance, resuélvelas antes del review. Si son
observaciones ("este archivo está creciendo"), anótalas y sigue al review.

**NEEDS_CONTEXT:** le falta información que no le diste. Dásela y re-despacha.

**BLOCKED:** no puede completar. Evalúa el bloqueo:
1. Si es problema de contexto, dale más y re-despacha con el mismo modelo.
2. Si necesita más razonamiento, re-despacha con un modelo más capaz.
3. Si la tarea es muy grande, divídela.
4. Si el plan está mal, falla sobre la corrección, regístrala y re-despacha
   llevando el fallo en el despacho.

**Nunca** ignores una escalada ni fuerces al mismo modelo a reintentar sin
cambios. Si dijo que está trabado, algo tiene que cambiar.

Si el implementador hace preguntas — antes de empezar o a mitad — contesta
clara y completamente, dale contexto adicional si hace falta, y no lo apures.

### 3. Revisar la tarea

Los reviews por tarea son compuertas con alcance de tarea. El review amplio
pasa una sola vez, al final. Nunca saltes el review de tarea, y nunca
aceptes un reporte al que le falte alguno de los dos veredictos: cumplimiento
de spec **y** calidad. El auto-review del implementador no reemplaza al
review de tarea; hacen falta los dos.

- Pasale el diff **como archivo**: corre `scripts/review-package PLAN_FILE
  BASE HEAD` y dale la ruta que imprime. La salida nunca entra en tu
  contexto, y el revisor ve lista de commits, resumen y diff completo con
  contexto en una sola lectura. Usa el BASE que registraste. Nunca despaches
  un revisor sin archivo de diff.
- **Entradas del revisor:** el mismo brief, el archivo de reporte y el
  paquete de review, más las restricciones globales que atan a la tarea.
- El bloque de restricciones globales es su lente de atención: copia los
  requisitos vinculantes **literalmente** del plan o del doc de la feature —
  valores exactos, formatos exactos, y las relaciones declaradas entre
  componentes ("mismo layout que X"). La plantilla del revisor ya trae las
  reglas de proceso; el bloque es para lo que ESTE proyecto exige.
- No agregues directivas abiertas ("chequea todos los usos") sin una razón
  concreta y específica de la tarea.
- No le pidas re-correr tests que el implementador ya corrió sobre el mismo
  código — su reporte es la evidencia.
- **No pre-juzgues hallazgos.** Nunca instruyas a un revisor a ignorar o no
  marcar algo. Si crees que sería un falso positivo, deja que lo levante y
  adjudícalo en el loop. Si el prompt que estás escribiendo contiene "no
  marques", "no trates X como defecto", "a lo sumo Menor" o "el plan lo
  eligió" — detente: estás pre-juzgando, casi siempre para ahorrarte un loop.

El revisor puede reportar ítems "⚠️ No verificable desde el diff" —
requisitos que viven en código sin cambiar o que cruzan tareas. No bloquean
el resto del review, pero **tienes que resolver cada uno tú** antes de marcar
la tarea completa: tú tienes el plan y el contexto entre tareas que al
revisor le falta. Si confirmas que es una brecha real, es un review de spec
fallado: entra al fix loop con los demás hallazgos.

Plantilla: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. El fix loop

Se dispara cuando el review reporta spec ❌, cualquier hallazgo Crítico o
Importante, o un ⚠️ que confirmaste como brecha real.

Antes de que arranque, dos rutas lo evitan de entrada:

- Registra los hallazgos **Menores** en el ledger a medida que salen
  (`Tarea <N>: menor (diferido): <una línea>`), y apunta el review final a
  esa lista para que triage cuáles hay que arreglar antes del merge. Un
  resumen que nadie lee es un descarte silencioso. Los menores nunca entran
  al loop.
- Un hallazgo etiquetado **mandado-por-el-plan** — o cualquiera que
  contradiga lo que el texto del plan exige — es tuyo para fallar: pesa el
  hallazgo contra el texto del plan, decide con el doc de la feature como
  autoridad vinculante, y registra el fallo antes de actuar. No descartes el
  hallazgo porque el plan lo manda, y no despaches un fix que contradiga el
  plan sin fallo registrado.

Todo lo demás entra al loop. Una ronda es **un despacho de fix más un
re-review acotado**. Máximo **cinco rondas por tarea**:

**Rondas 1-3 — retoma al implementador original.** Mandale los hallazgos
abiertos literales. Su contexto está intacto: conoce la tarea, el código y
sus propias decisiones. Si tu harness no puede mandarle otro mensaje a un
subagente vivo, despacha uno fresco llevando la ruta del brief, la del
reporte y los hallazgos — el archivo de reporte es la memoria persistente en
cualquiera de los dos casos.

**Rondas 4-5 — implementador fresco en un modelo más capaz**, con la ruta del
brief, la del reporte, los hallazgos abiertos y este encuadre: "un
implementador anterior intentó esta tarea [N] veces; ahora es tuya. Lee el
archivo de reporte para ver qué se probó". Un loop que sobrevive tres
retomadas suele significar que el implementador no puede ver su propio
problema: ojos frescos y un salto de capacidad en un solo movimiento.

**Cada ronda, en cualquiera de los dos casos:** el implementador arregla,
re-corre los tests que cubren el código modificado, agrega su reporte de fix
al mismo archivo, y devuelve el contrato corto. Antes de re-despachar al
revisor, confirma que el reporte de fix trae los tests que cubren, el comando
corrido y su salida; recién ahí despacha el re-review. Nombra los archivos de
test que cubren en el mensaje de fix — un fix de una línea no necesita la
suite entera.

**El re-review es acotado.** Corre `scripts/review-package PLAN_FILE FIX_BASE
HEAD` donde FIX_BASE es el head que vio el review anterior, y despacha
[re-review-prompt.md](re-review-prompt.md) con la lista de hallazgos, el
brief, el archivo de reporte y la ruta del diff. El re-revisor veredicta cada
hallazgo ATENDIDO o NO ATENDIDO y marca roturas nuevas **solo en el diff del
fix**. Roturas nuevas Críticas/Importantes en ese diff se suman a los
hallazgos abiertos. Las observaciones fuera de alcance van al ledger como
menores diferidos: nunca extienden el loop.

**Después de cada ronda,** agrega al ledger:
`Tarea <N>: fix ronda <R>/5 (<X> atendidos, <Y> abiertos — <una línea cada
uno>; commits <a7>..<b7>)`

**Nunca arregles tú los hallazgos en la sesión controladora** — tu contexto
queda limpio para coordinar, y los fixes del controlador se saltan el review.

**El breaker.** Cuando el re-review de la ronda 5 todavía deja hallazgos
abiertos, deja de despachar. Adjudica cada hallazgo abierto tú, que tienes el
plan y el contexto entre tareas que al revisor le falta:

- **El revisor se equivoca, o el punto es discutible:** apárcalo —
  `Tarea <N>: aparcado — <hallazgo> — Fallo: <por qué el código queda>`. El
  review final ve las dos versiones.
- **Real, pero nada aguas abajo se apoya en eso:** apárcalo igual, con un
  fallo que diga que es real y está diferido.
- **Real y estructural** — una tarea posterior se apoya en eso, o revela un
  defecto del plan: falla sobre el cambio más chico que desbloquee el trabajo
  dependiente, regístralo como `Tarea <N>: Fallo: <hallazgo> — <qué decidiste
  y por qué>`, y llévalo al despacho de la tarea siguiente. Aparcar un fallo
  estructural en silencio hace que cada tarea dependiente se construya encima.
  Detente solo cuando el defecto deja todo camino como adivinanza.

**Adjudica solo en el tope.** Adjudicar antes para cortar un loop es
pre-juzgar con otro nombre. Cada adjudicación es una entrada del ledger: un
descarte silencioso está prohibido.

### 5. Completar la tarea

Cuando el review vuelve limpio — o cada hallazgo abierto quedó aparcado con
fallo en el tope — agrega la línea de completitud al ledger:

- `Tarea <N>: completa (commits <base7>..<head7>, review limpio)`
- `Tarea <N>: completa (commits <base7>..<head7>, <K> aparcados)` si saltó el
  breaker

Marca el todo como completo y sigue. Nunca pases a la tarea siguiente con
hallazgos Críticos/Importantes que no estén ni arreglados ni aparcados con
fallo en el tope.

## Review final

También lleva paquete: corre `scripts/review-package PLAN_FILE MERGE_BASE
HEAD` (MERGE_BASE = el commit del que salió el branch, `git merge-base MAIN
HEAD`) e incluye la ruta impresa en el despacho, para que el revisor final lea
un archivo en vez de re-derivar el diff del branch con comandos git.
Despachalo en **el modelo más capaz disponible**. Apuntalo a las líneas de
menores diferidos y aparcados del ledger para que triage cuáles hay que
arreglar antes del merge.

Plantilla: [final-reviewer-prompt.md](final-reviewer-prompt.md)

Si el review final devuelve hallazgos, despacha **UN** subagente de fix con
la lista completa — no uno por hallazgo. Los fixers por hallazgo reconstruyen
contexto y re-corren suites cada uno; en una sesión real, la ola de fixes del
review final costó más que todas las tareas juntas. Después corre
**exactamente un** re-review acotado de la ola de fixes. Adjudica los
residuales como en el breaker: aparcados con fallo, o falla sobre los
estructurales y registra qué decidiste. Solo las cuatro clases de arriba te
detienen aquí. **No hay segunda ola de fixes:** los hallazgos estructurales
residuales le llegan al usuario en el cierre.

## Cierre

**Antes de borrar nada**, junta cada línea del ledger que contenga `Fallo:` —
las del escaneo previo, los aparcados, las adjudicaciones del breaker, todas
— y haz dos cosas con esa lista:

1. **Escribila en `docs/features/<slug>.md`**, en Decisiones, con fecha. El
   workspace es git-ignored y se borra; el doc de la feature es la memoria que
   se commitea y sobrevive al merge. Un fallo que muere con el workspace fue
   una decisión tomada en secreto.
2. **Mostrala en tu mensaje final** bajo "Fallos que tomé", en el orden en que
   los tomaste, cada uno con qué cuesta si está mal. Es el único lugar donde
   las decisiones que tomaste en nombre del usuario le llegan.

Con el review final limpio y sus fixes integrados, borra el workspace de este
plan (`rm -rf <workspace>`) — el historial de git es el registro ahora. Los
directorios hermanos son de otros planes: no los toques.

**El cierre lo hace la sala de control, no tú.** Actualiza
`docs/features/<slug>.md` (Estado, Bitácora), commitea, pushea el branch, y
dile al usuario que corra `/feature close <slug>` desde la sala de control.
**Nunca mergees a `MAIN` desde el worktree** — es una de las cuatro cosas que
te detienen, y una regla dura del contrato.

## Señales de que te estás autoengañando

| Excusa | Realidad |
|---|---|
| "el spec está bastante cumplido" | El revisor encontró brechas = no está hecho. Arreglar o llegar al tope y adjudicar: son las dos únicas salidas. |
| "lo arreglo yo, despachar es overhead" | Los fixes del controlador contaminan tu contexto y se saltan el review. Retoma al implementador. |
| "una ronda más y converge" | Pasado el tope, las rondas no convergen: el fallo es estructural. Adjudica y rutea. |
| "el revisor va a encontrar algo nuevo igual" | Los re-reviews acotados verifican fixes, no pueden pasear. Lo nuevo sobre código intacto va al ledger, no al loop. |
| "este hallazgo está obviamente mal, lo descarto" | Adjudicas solo en el tope, y cada fallo es una entrada del ledger. Los descartes silenciosos están prohibidos. |
| "el fix era chico, salto el re-review" | Los fixes sin revisar son cómo aterrizan las regresiones. Cada ronda termina en un re-review acotado. |
| "los reviews frenan el loop" | El loop sin reviews es batido sin verificar. Los reviews son el freno y la dirección. |
| "el ledger es burocracia" | El ledger es lo que sobrevive a la compactación. Controladores sin uno re-despacharon secuencias enteras ya completas. |
| "el implementador generó su propio revisor, assurance gratis" | Es un asiento duplicado sobre el mismo diff. El review de tarea es la compuerta; un revisor generado por el worker es un defecto para marcar, no rigor. |
| "ya está todo verde, mergeo y listo" | El merge es de la sala de control. Pushea y avisa: `/feature close <slug>`. |
