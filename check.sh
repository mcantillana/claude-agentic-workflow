#!/usr/bin/env bash
# Chequeos del plugin. Sin frameworks: si algo falla, el plugin no carga
# o /init deja un placeholder sin resolver en el contrato del proyecto.
set -euo pipefail
cd "$(dirname "$0")"
fail=0
err() { echo "FAIL: $*"; fail=1; }

# 1. Cada skill/<dir>/SKILL.md existe y su `name:` coincide con el directorio.
for d in skills/*/; do
  slug=$(basename "$d")
  [ -f "$d/SKILL.md" ] || { err "$d sin SKILL.md"; continue; }
  name=$(sed -n 's/^name: *//p' "$d/SKILL.md" | head -1)
  [ "$name" = "$slug" ] || err "$d: name '$name' != directorio '$slug'"
done

# 2. Cada {{PLACEHOLDER}} de las plantillas está nombrado en /init,
#    que es quien los reemplaza. Si falta, el contrato queda con {{...}}.
for ph in $(grep -oh '{{[A-Z_]*}}' templates/*.md | sort -u); do
  grep -qF "$ph" skills/init/SKILL.md || err "$ph no está en skills/init/SKILL.md"
done

# 3. La versión del contrato coincide con la última entrada del changelog.
tpl=$(sed -n 's/.*contrato agentic-workflow v\([0-9]*\).*/\1/p' templates/AGENTIC_WORKFLOW.template.md | head -1)
log=$(sed -n 's/^## v\([0-9]*\) .*/\1/p' templates/CONTRACT_CHANGELOG.md | head -1)
[ "$tpl" = "$log" ] || err "contrato v$tpl pero el changelog encabeza en v$log"

[ $fail -eq 0 ] && echo "OK: $(ls -d skills/*/ | wc -l | tr -d ' ') skills, contrato v$tpl"
exit $fail
