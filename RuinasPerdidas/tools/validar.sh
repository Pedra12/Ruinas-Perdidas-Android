#!/usr/bin/env bash
# Valida o projeto completo com o renderer Mobile e os autoloads ativos.
# Uso: GODOT=/caminho/godot ./tools/validar.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

if command -v xvfb-run >/dev/null 2>&1; then
  RUN=(xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 "$GODOT")
else
  RUN=("$GODOT")
fi

echo "== 1/3 Importando recursos com renderer Mobile/Vulkan"
"${RUN[@]}" --editor --path . --import --rendering-method mobile --rendering-driver vulkan --quit 2>&1 | tee "$LOG"

echo "== 2/3 Validando a cena do menu"
"${RUN[@]}" --path . --quit-after 60 --rendering-method mobile --rendering-driver vulkan res://scenes/main_menu.tscn 2>&1 | tee -a "$LOG"

echo "== 3/3 Teste de fumaça do nível principal"
"${RUN[@]}" --path . --quit-after 180 --rendering-method mobile --rendering-driver vulkan res://scenes/main.tscn 2>&1 | tee -a "$LOG"

if grep -E "ERROR:|SCRIPT ERROR:|Parse Error:" "$LOG"; then
  echo "FALHA: foram encontrados erros no projeto."
  exit 1
fi

echo "OK: importação, menu e nível principal carregaram sem erros no renderer Mobile."
