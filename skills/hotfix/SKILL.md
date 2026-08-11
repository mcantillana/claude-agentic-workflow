---
name: hotfix
description: Arregla un bug de producción con ceremonia mínima, en su propio worktree (la sala de control queda libre). Kickoff (/hotfix <slug>) crea el worktree + branch y guía reproducción + fix + test; cierre (/hotfix close <slug>) mergea al branch principal, recuerda el deploy y exige post-mortem. Se invoca desde la sala de control. Requiere proyecto inicializado con /init.
argument-hint: <slug> | close <slug>
---

# /hotfix — arreglo de producción con ceremonia mínima

Un hotfix usa **su propio worktree** (como una feature) para que la **sala de
control quede libre** y puedas paralelizar mientras lo arreglas. Pero es
**más liviano que `/feature`**: sin doc en `docs/features/`, sin review por
sesión ajena. A cambio, dos obligaciones: **test que falla antes y pasa
después**, y **post-mortem** al cerrar.

## Contrato local

Lee `docs/AGENTIC_WORKFLOW.md` del proyecto (branch principal `MAIN`,
directorio de worktrees `WT_DIR`, archivos de entorno, tests, deploy). Si no
existe, detente e indica correr `/init`.

**Modelo de deploy asumido: `MAIN` = producción, sin drift** (lo desplegado
se reconstruye desde `MAIN`). Por eso el hotfix sale de `MAIN` y vuelve a
`MAIN`. Si el proyecto no funciona así (hay drift entre `MAIN` y lo
desplegado, o no hay producción), detente y acuerda con el usuario si esta
ceremonia aplica o si el bug va mejor por `/feature`.

## Precondición

Sala de control: raíz del repo principal, branch `MAIN`. **La sala de
control se mantiene en `MAIN` durante todo el hotfix** — el trabajo vive en
el worktree; nunca se hace checkout del branch del hotfix en la sala de
control.

## `/hotfix <slug>` — kickoff

Slug kebab-case que describa el incidente (ej: `login-timeout`). Si el
usuario dio una descripción, propón slug y confirma.

1. **Estado limpio y al día:** `git status` limpio; `git fetch origin &&
   git pull --ff-only` (para salir de producción real); verifica que no
   existan `WT_DIR/hotfix-<slug>` ni el branch `hotfix/<slug>`.

2. **Crea el worktree del hotfix:**
   ```bash
   mkdir -p WT_DIR
   git worktree add WT_DIR/hotfix-<slug> -b hotfix/<slug> MAIN
   ```
   Copia los archivos de entorno del contrato. El resto del trabajo ocurre
   dentro del worktree (en esta sesión con `cd`, o en una sesión nueva para
   paralelizar de verdad).

3. **Reproduce el bug antes de tocar nada.** Si no puedes reproducirlo, el
   fix es a ciegas: díselo al usuario y decidan si seguir.

4. **Fix mínimo.** Solo lo necesario para apagar el incendio. **Nada de
   refactors, limpieza ni mejoras de paso** — cada línea de más es riesgo en
   producción; lo demás es deuda para una feature.

5. **Test que prueba el fix.** Escribe (o ajusta) un test que falle ANTES del
   fix y pase DESPUÉS, y corre la suite relevante (comando del contrato). Es
   la única red de seguridad del hotfix: obligatorio salvo que el usuario lo
   exima explícitamente.

6. **Commit** en el worktree: `fix(scope): ...`, un solo commit acotado
   cuando se pueda (fácil de revertir de un golpe). Si cierra un issue,
   incluye `Closes #N` en el cuerpo.

7. Recuerda el cierre: `/hotfix close <slug>` desde la sala de control
   cuando el fix esté probado.

## `/hotfix close <slug>` — merge + deploy + post-mortem

1. **Verificaciones (no mergees si fallan):**
   - El worktree está limpio y el fix commiteado.
   - Pregunta si el test pasó y si el bug se reprodujo/verificó.
   - `git fetch origin && git rev-list --count hotfix/<slug>..origin/MAIN`
     debe ser 0; si `MAIN` avanzó, pide rebasar el branch desde el worktree
     antes de mergear.

2. **Merge a `MAIN`:**
   ```bash
   git merge --no-ff hotfix/<slug>
   git push origin MAIN
   ```
   El orden es deliberado: **primero `MAIN`, después deploy** — nunca se
   despliega algo que no esté en `MAIN`.

3. **Deploy a producción.** No lo ejecuta esta skill: recuérdale al usuario
   el procedimiento según la sección "Deploy" del contrato, y que **verifique
   en producción que el incendio se apagó** antes de cantar victoria.

4. **Limpieza:**
   ```bash
   git worktree remove WT_DIR/hotfix-<slug>
   git branch -d hotfix/<slug>
   ```
   Sin `--force` salvo confirmación explícita. Apaga el entorno del worktree
   si levantó uno.

5. **Post-mortem (obligatorio).** Un hotfix sin post-mortem se repite.
   Regístralo con: qué se rompió y desde cuándo, causa raíz, el fix (SHA del
   merge), alcance (datos/usuarios afectados) y pendientes (limpieza,
   monitoreo, fix de fondo si esto fue un parche). Dónde: en la memoria
   persistente del agente y, si el proyecto tiene `docs/postmortems/` (o el
   contrato indica otro lugar), también como archivo committeado.

6. **Tarea de ClickUp + aviso al DL** (si el contrato tiene ClickUp y el hotfix
   nació de un issue): ubica la tarea vinculada (comentario `ClickUp: <url>` del
   issue, o el custom field = #N), pásala con `clickup_update_task` al estado de
   cierre (`DEPLOY A PRODUCCION` mientras se despliega; `COMPLETADAS` una vez
   verificado en prod) y `clickup_create_comment` mencionando al DL con el SHA
   del merge y el estado. Si el MCP no está, deja anotado el movimiento
   pendiente.

7. Confirma al usuario: mergeado, worktree y branch eliminados, deploy
   pendiente/hecho y verificado, tarea de ClickUp movida + DL avisado,
   post-mortem guardado.
