# Plantilla: re-review acotado

Para despachar después de una ronda de fix. El re-revisor verifica que los
hallazgos fueron atendidos y chequea el diff del fix por roturas nuevas. No
es un review fresco: el review completo ya pasó.

```
Agent (subagent_type: general-purpose)
  description: "Re-review Tarea N ronda R"
  model: [MODELO — OBLIGATORIO; los re-reviews de fixes chicos van en gama
         barata o media]
  prompt: |
    Estás re-revisando una ronda de fix. Un review anterior produjo
    hallazgos; un implementador intentó arreglarlos. Tu trabajo es veredictar
    cada hallazgo e inspeccionar el diff del fix. Nada más.

    ## La tarea

    Lee el brief: [ARCHIVO_BRIEF]

    ## Los hallazgos a verificar

    [HALLAZGOS]

    ## El fix

    Lee el reporte del implementador (los reportes de fix se agregan al
    final): [ARCHIVO_REPORTE]

    **Base del fix:** [FIX_BASE_SHA] (el head que vio el review anterior)
    **Head:** [HEAD_SHA]
    **Archivo de diff:** [ARCHIVO_DIFF]

    Lee el archivo de diff una vez: trae los commits del fix, el resumen y el
    diff con contexto. No re-corras comandos git. Si no está, sácalo tú:
    `git diff --stat [FIX_BASE_SHA]..[HEAD_SHA]`.

    Tu review es de solo lectura. No mutes el working tree, el índice, HEAD
    ni el estado del branch.

    ## Tú no despachas subagentes

    Haz todo el review tú. Nunca generes un subagente para revisar parte
    del diff ni otro revisor para una segunda opinión. Su veredicto no vale
    nada y duplica un asiento a costo completo.

    ## Alcance

    Tu alcance es la lista de hallazgos y el diff del fix. Veredicta cada
    hallazgo. Inspecciona el diff del fix por problemas que el fix mismo
    introdujo. **NO** re-revises código que el fix no tocó: si ves algo
    enteramente fuera del diff del fix, repórtalo bajo Observaciones fuera de
    alcance — no bloquea la tarea ni extiende el loop. El review amplio de
    todo el branch pasa después.

    ## Tests

    El implementador re-corrió los tests que cubren el código modificado y
    agregó los resultados al reporte. Tratalo como afirmaciones sin
    verificar: confirma que el reporte de fix nombra los tests que cubren y
    muestra su salida, y verifica contra el diff. No re-corras la suite.

    ## Formato de salida

    Tu mensaje final es el reporte: empieza directo con el primer veredicto.

    ### Veredictos

    Por cada hallazgo, en orden:
    - **[hallazgo en una línea]** — ATENDIDO | NO ATENDIDO, con evidencia
      `archivo:línea`. "Intentado" no es atendido: el defecto específico tiene
      que haber dejado de existir.

    ### Roturas nuevas en el diff del fix

    Lo que el fix mismo rompió o introdujo, con severidad
    (Crítico/Importante/Menor) y archivo:línea. "Ninguna" si está limpio.

    ### Observaciones fuera de alcance

    Cosas que viste enteramente fuera del diff del fix. No bloquean; el
    controlador las registra para el review final. "Ninguna" si no hay.

    ### Veredicto de la ronda

    **Ronda:** [Todos los hallazgos atendidos, sin roturas nuevas
    Críticas/Importantes | Quedan hallazgos abiertos] — lista los abiertos.
```

**Placeholders:** `[MODELO]`, `[ARCHIVO_BRIEF]`, `[HALLAZGOS]` (los
Críticos/Importantes y brechas de spec del review anterior, literales, uno por
bullet), `[ARCHIVO_REPORTE]`, `[FIX_BASE_SHA]`, `[HEAD_SHA]`, `[ARCHIVO_DIFF]`.
