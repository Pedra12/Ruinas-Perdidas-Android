#!/usr/bin/env bash
# Valida o projeto completo com os autoloads e recursos do project.godot ativos.
# Uso: GODOT=/caminho/godot ./tools/validar.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "== 1/3 Importando recursos do projeto"
"$GODOT" --headless --editor --path . --import --quit 2>&1 | tee "$LOG"

echo "== 2/3 Validando a cena do menu"
"$GODOT" --headless --path . --quit-after 60 res://scenes/main_menu.tscn 2>&1 | tee -a "$LOG"

echo "== 3/3 Teste de fumaça do nível principal"
"$GODOT" --headless --path . --quit-after 180 res://scenes/main.tscn 2>&1 | tee -a "$LOG"

if grep -E "ERROR:|SCRIPT ERROR:|Parse Error:" "$LOG"; then
  echo "FALHA: foram encontrados erros no projeto."
  exit 1
fi

echo "OK: importação, menu e nível principal carregaram sem erros."
