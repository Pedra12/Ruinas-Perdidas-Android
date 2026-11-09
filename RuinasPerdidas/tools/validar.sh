#!/usr/bin/env bash
# Valida o projeto sem abrir o editor. Uso: GODOT=/caminho/godot ./tools/validar.sh
# Falha (exit 1) se houver qualquer ERROR / SCRIPT ERROR / Parse Error.
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG=$(mktemp)
status=0

echo "== 1/3 Importando recursos (pode rodar 2x na primeira vez)"
"$GODOT" --headless --path . --import >"$LOG" 2>&1
"$GODOT" --headless --path . --import >>"$LOG" 2>&1

echo "== 2/3 Checando sintaxe de cada script"
for f in $(find scripts -name '*.gd'); do
  out=$("$GODOT" --headless --path . --check-only --script "res://$f" 2>&1)
  if echo "$out" | grep -qE "ERROR|Parse Error|SCRIPT ERROR"; then
    echo "FALHA em $f"; echo "$out" | grep -E "ERROR|Parse Error|SCRIPT ERROR" | head -5; status=1
  fi
done

echo "== 3/3 Teste de fumaça: carrega o jogo por 180 quadros"
"$GODOT" --headless --path . --quit-after 180 res://scenes/main.tscn >>"$LOG" 2>&1
if grep -E "ERROR|SCRIPT ERROR|Parse Error" "$LOG" | grep -v "ERROR: .*\.glb.*unused" ; then
  status=1
fi

if [ "$status" -eq 0 ]; then echo "OK: nenhum erro encontrado."; else echo "ERROS encontrados (log: $LOG)"; fi
exit $status
