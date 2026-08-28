---
name: plan
description: Escribe el plan de implementación de la feature en la que estás trabajando, antes de tocar código. Se corre DENTRO del worktree de la feature (no en la sala de control) y no necesita argumentos - deduce la feature del branch actual. Produce un plan con tareas bite-sized y ciclo TDD, lo commitea y actualiza el doc de la feature. Requiere proyecto inicializado con /init.
argument-hint: (sin argumentos) | <slug>
---

# /plan — plan de implementación de la feature

Escribe el plan **asumiendo que quien lo ejecuta no conoce este codebase**:
qué archivos toca cada tarea, con qué código, cómo se testea, en qué orden.
Tareas bite-sized. DRY. YAGNI. TDD. Commits frecuentes.

## Dónde corre

**Dentro del worktree de la feature**, no en la sala de control. La sala de
control no escribe planes: entrega el worktree y termina su turno.

Si `git rev-parse --git-common-dir` es `.git` estás en la sala de control:
detente y di en qué worktree hay que correrlo.

## Contrato local

Lee `docs/AGENTIC_WORKFLOW.md`: de ahí sale el **directorio de planes**
(`PLANS_DIR`, por defecto `docs/plans/`) y el comando de tests. Si no existe,
detente e indica correr `/init`.

## Paso 0 — de dónde sale el contexto

El worktree es autodescriptivo; no hace falta pasarle argumentos:

```bash
git branch --show-current          # feature/<slug>  →  slug
cat docs/features/<slug>.md        # objetivo, ruta, alcance, issue de origen
```

De ese doc salen el **Objetivo**, el **Alcance** y el campo **Ruta**:

- `Ruta: architectural` → este es el caso para el que existe esta skill.
- `Ruta: bounded` → **el plan no corresponde.** Un cambio acotado se
  implementa directo con TDD; un plan formal es papeleo. Dilo y detente,
  salvo que el usuario insista explícitamente.
- `Ruta: spike` → tampoco. Un spike entrega una respuesta, no código que se
  conserva. Dilo y detente.

Si el doc de la feature no existe (worktree creado a mano, sin `/feature`),
pregunta objetivo y alcance antes de seguir.

## Paso 1 — mapa de archivos

Antes de definir tareas, lista qué archivos se crean o modifican y de qué es
responsable cada uno. Acá se fijan las decisiones de descomposición:

- Cada archivo, una responsabilidad clara y una interfaz definida.
- Lo que cambia junto, vive junto. Separa por responsabilidad, no por capa
  técnica.
- Archivos chicos y enfocados: se razonan mejor y se editan con menos error.
- En un codebase existente, **sigue los patrones que ya están**. No
  reestructures por tu cuenta; si un archivo que igual vas a tocar ya creció
  demasiado, incluir su división en el plan sí es razonable.

## Paso 2 — tamaño de las tareas

Una tarea es la **unidad más chica que carga su propio ciclo de test** y
merece el visto bueno de un revisor fresco. Plegá setup, configuración,
scaffolding y documentación dentro de la tarea cuyo entregable los necesita.
Separá solo donde un revisor podría rechazar una tarea y aprobar la vecina.
Cada tarea termina en un entregable testeable por sí solo.

Dentro de la tarea, **cada paso es una acción de 2-5 minutos**: escribir el
test que falla · correrlo y verlo fallar · implementar lo mínimo · correr y
verlo pasar · commitear.

## Paso 3 — escribir el plan

Va a `PLANS_DIR/<slug>.md` (mismo directorio donde viven los runbooks de
barriers: un solo lugar para planes). Encabezado obligatorio:

```markdown
# Plan: <slug>

- **Feature:** `docs/features/<slug>.md`
- **Branch:** `feature/<slug>`
- **Origen:** <issue #N | conversación>
- **Fecha:** <AAAA-MM-DD>

**Objetivo:** <una frase: qué construye esto>

**Enfoque:** <2-3 frases sobre la arquitectura>

**Restricciones globales:** <requisitos que aplican a todas las tareas —
versiones mínimas, convenciones de nombres, límites de dependencias — una
línea cada uno, con los valores exactos. Si no hay, "—">

---
```

Y cada tarea:

````markdown
### Tarea N: <nombre>

**Archivos:**
- Crear: `ruta/exacta/archivo.py`
- Modificar: `ruta/exacta/existente.py:123-145`
- Test: `tests/ruta/test_archivo.py`

**Interfaces:**
- Consume: <qué usa de tareas anteriores — firmas exactas>
- Produce: <qué nombres y tipos exactos van a usar las tareas siguientes>

- [ ] **Paso 1: escribir el test que falla**

```python
def test_comportamiento():
    assert funcion(entrada) == esperado
```

- [ ] **Paso 2: correr el test y verificar que falla**

Comando: `<comando de tests del contrato>`
Esperado: FAIL — "funcion is not defined"

- [ ] **Paso 3: implementación mínima**

```python
def funcion(entrada):
    return esperado
```

- [ ] **Paso 4: correr el test y verificar que pasa**

- [ ] **Paso 5: commit**

```bash
git add tests/ruta/test_archivo.py src/ruta/archivo.py
git commit -m "feat: add specific behavior"
```
````

## Sin placeholders

Cada paso lleva el contenido real. Esto son **fallas del plan**, no atajos:

- "TBD", "TODO", "completar después"
- "agregar manejo de errores apropiado" / "cubrir edge cases"
- "escribir tests para lo anterior" sin el código del test
- "igual que la Tarea N" — repetí el código: se leen fuera de orden
- pasos que dicen *qué* hacer sin mostrar *cómo* (los pasos de código llevan
  bloque de código)
- referencias a tipos o funciones que ninguna tarea define

## Paso 4 — auto-revisión

Con ojos frescos, contra el doc de la feature:

1. **Cobertura del alcance:** ¿cada punto del Alcance tiene una tarea que lo
   implementa? Si falta, agregá la tarea.
2. **Barrido de placeholders:** buscá los patrones de arriba y arreglalos.
3. **Consistencia de tipos:** ¿las firmas y nombres que usás en la Tarea 7
   son los que definiste en la Tarea 3? `clearLayers()` en una y
   `clearFullLayers()` en otra es un bug.

Arreglá inline y seguí. No re-revises.

## Paso 5 — commitear y enlazar

```bash
git add PLANS_DIR/<slug>.md docs/features/<slug>.md
git commit -m "docs(<slug>): implementation plan"
```

En `docs/features/<slug>.md`: completá `**Plan:**` con la ruta, cambiá
"Próximo paso" por "Ejecutar el plan" y agregá la entrada a la Bitácora con
fecha absoluta.

**Nunca commitees en `MAIN`.** El plan vive en el branch de la feature y
llega a `MAIN` con el merge de `/feature close`.

## Paso 6 — elegir cómo se ejecuta

Con el plan guardado, ofrecé la elección; no la asumas:

> Plan guardado en `PLANS_DIR/<slug>.md`, con N tareas. Dos formas de
> ejecutarlo:
>
> **1. Por subagentes (recomendado si las tareas son independientes)** — un
> subagente fresco por tarea, revisión entre tareas, iteración rápida.
>
> **2. En esta sesión** — ejecuto las tareas acá, con checkpoints para que
> revises.
>
> ¿Cuál?

### Si elige subagentes

Un subagente por tarea, y **le construís el contexto a mano**: nunca hereda
el historial de esta sesión. Le pasás la tarea completa del plan (archivos,
interfaces, pasos), el objetivo del doc de la feature y las restricciones
globales — nada más. Así se mantiene enfocado y vos conservás tu contexto
para coordinar.

Después de cada tarea, un subagente **revisor distinto del que implementó**
verifica dos cosas: que cumpla lo que la tarea pedía, y la calidad del
código. Al terminar todas, una revisión final sobre el branch completo.

Esto es la regla dura del contrato — *el review lo hace una sesión que no es
la autora* — aplicada dentro del worktree.

**Ejecutá de corrido: no pares a preguntar "¿sigo?" entre tareas.** Ante un
conflicto, una ambigüedad o un defecto del plan, **decidí** y anotá la
decisión en la bitácora del doc de la feature (`Decisión: <qué> — <por qué> —
<qué cuesta si me equivoco>`). Solo cuatro cosas te detienen: una operación
destructiva o irreversible, algo sensible en seguridad, un efecto fuera de
este worktree (un merge, un push a branch compartido, un deploy), y un plan
tan roto que todo camino es adivinanza.

### Si elige esta sesión

Tarea por tarea, marcando los `- [ ]` a medida que pasan, con checkpoint al
final de cada tarea para que el usuario revise.

### En cualquiera de las dos

Si el plan resulta estar mal a mitad de camino, corregí el plan y commiteá la
corrección — es un documento vivo, no un contrato con vos mismo.

## Reglas duras

Solo en el worktree · nunca en `MAIN` · sin placeholders · una tarea = un
ciclo de test · si la ruta es `bounded`, no hay plan · quien revisa no es
quien implementó.
