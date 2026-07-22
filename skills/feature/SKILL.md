---
name: feature
description: Gestiona el ciclo de vida de features con worktrees + sesiones de Claude. Kickoff de una feature nueva (/feature <slug>), estado de las activas (/feature list) y cierre con merge y limpieza (/feature close <slug>). Se usa solo desde la sala de control (raíz del repo, en el branch principal). Requiere que el proyecto esté inicializado con /init.
argument-hint: <slug> | list | close <slug>
---

# /feature — ciclo de vida de features (worktree + sesión)

Modelo: **1 feature = 1 worktree = 1 branch = 1 sesión de Claude**.

## Contrato local (leer SIEMPRE primero)

Lee `docs/AGENTIC_WORKFLOW.md` del proyecto. De ahí salen: el **branch
principal** (`MAIN`), el **directorio de worktrees** (`WT_DIR`), los
**archivos de entorno** a copiar, las **instrucciones de entorno por
worktree** y las de tests. Obedece lo que diga ese archivo; si contradice
algo de esta skill, gana el archivo del proyecto.

Si `docs/AGENTIC_WORKFLOW.md` no existe, detente: el proyecto no está
inicializado. Indica correr `/init` primero.

## Precondición (todos los subcomandos)

Estás en la **sala de control**: la raíz del repo principal (no un worktree:
`git rev-parse --git-common-dir` == `.git`) y el branch actual es `MAIN`.
Si no, detente y dile al usuario dónde se corre esto.

## `/feature <slug>` — kickoff

Slug kebab-case corto (ej: `refunds`, `dark-mode`). Si el usuario dio una
descripción, propón un slug y confirma.

1. **Estado limpio y al día:** `git status` limpio (si no, detente y
   repórtalo); `git fetch origin && git pull --ff-only` (si hay remote);
   verifica que no existan ya `WT_DIR/<slug>` ni el branch `feature/<slug>`.

2. **Colindancias:** lee los `docs/features/*.md` con Estado distinto de
   "Mergeada" y compara las áreas del código que la nueva feature tocará
   (pregunta al usuario cuáles serán, sugiriendo según el objetivo). Si hay
   solapamiento con una feature activa, adviértelo: riesgo de conflictos de
   merge (y de migraciones, si el proyecto las usa).

3. **Decide el entorno** según la sección "Entorno por worktree" del
   contrato. El objetivo es que el worktree quede **ejecutable de verdad**
   (recorrible en un navegador/CLI), no solo testeable — ten presente que el
   entorno compartido, si existe, corre el código de `MAIN`, no el del
   worktree. Pregunta con AskUserQuestion lo que el contrato deje abierto
   (ej: entorno compartido vs propio, estrategia de datos). Si el contrato
   dice "no aplica", omite este paso.

4. **Crea el worktree:**
   ```bash
   mkdir -p WT_DIR
   git worktree add WT_DIR/<slug> -b feature/<slug> MAIN
   ```
   Copia al worktree los archivos de entorno listados en el contrato y
   aplica las asignaciones que este pida (ej: puerto propio, nombre de
   proyecto compose). Elige valores que no choquen con otros worktrees
   activos (revisa sus archivos de entorno) y regístralos en el doc del
   paso 5. No levantes el entorno tú: lo hace la sesión de la feature.

5. **Documentación persistente:** copia `docs/features/TEMPLATE.md` a
   `docs/features/<slug>.md` **dentro del worktree** y complétalo: objetivo,
   entorno y puertos, alcance, colindancias detectadas, bitácora con fecha
   de kickoff (fechas absolutas, no relativas).

6. **Commit inicial en el worktree** (nunca en `MAIN`):
   ```bash
   cd WT_DIR/<slug> && git add docs/features/<slug>.md && git commit -m "docs(<slug>): feature kickoff"
   ```
   Si la feature nace de un issue (#N), incluye `Closes #N` en el cuerpo del
   commit y anota "Origen: issue #N" en el doc.

7. **Cierre del kickoff** — entrega al usuario un bloque final con:
   - `cd WT_DIR/<slug>` y abrir una sesión de Claude ahí (sugerir
     `/rename <slug>`).
   - Primera instrucción para esa sesión: "lee `docs/features/<slug>.md` y
     `docs/AGENTIC_WORKFLOW.md` antes de partir".
   - Cómo dejar el entorno ejecutable, según el contrato (comandos
     concretos, con los valores asignados en el paso 4).

## `/feature list` — estado

1. `git worktree list`.
2. Por cada feature activa: lee su `docs/features/<slug>.md` (Estado, última
   actualización) y calcula divergencia:
   `git rev-list --count MAIN..feature/<slug>` (delante) y
   `git rev-list --count feature/<slug>..MAIN` (detrás).
3. Presenta una tabla: feature | estado | delante/detrás | entorno | última
   actualización del doc. Marca las que necesitan rebase (muy detrás de
   `MAIN`) o tienen el doc desactualizado.

## `/feature close <slug>` — cierre

1. **Verificaciones (no mergees si fallan):**
   - `feature/<slug>` está pusheado (si hay remote) y rebasado sobre `MAIN`
     (`git rev-list --count feature/<slug>..MAIN` == 0). Si no, pide que la
     sesión de la feature rebasee — no lo hagas tú sobre el worktree ajeno.
   - `docs/features/<slug>.md` existe en el branch y su Estado refleja el
     cierre (si falta, actualízalo como último commit del branch).
   - Pregunta si los tests pasaron en la sesión de la feature (comando según
     el contrato).

2. **Merge en la sala de control** (merge commit explícito):
   ```bash
   git merge --no-ff feature/<slug>
   git push origin MAIN
   ```

3. **Limpieza:**
   ```bash
   git worktree remove WT_DIR/<slug>
   git branch -d feature/<slug>
   ```
   Si el worktree tiene cambios sin commitear, `git worktree remove` fallará:
   repórtalo y NO uses `--force` sin confirmación explícita.

4. **Apaga el entorno del worktree** según el contrato (si aplica) y confirma
   al usuario: mergeado, worktree y branch eliminados, entorno apagado, doc
   en `MAIN` como registro.

## Reglas duras (recordatorio)

Una sesión por worktree · entorno completo o nada · merges a `MAIN` solo
desde la sala de control · la memoria vive en `docs/features/<slug>.md` ·
el review lo hace una sesión que no es la autora.
