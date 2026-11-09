#!/usr/bin/env bash
# Valida o projeto completo com autoloads ativos. O dummy renderer do headless
# emite um erro conhecido ao consultar texturas durante import de GLB; o filtro
# abaixo ignora somente essa mensagem interna, nunca erros de script ou cena.
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "== 1/3 Importando recursos do projeto"
timeout 180 "$GODOT" --headless --path . --import 2>&1 | tee "$LOG"

echo "== 2/3 Validando a cena do menu"
timeout 120 "$GODOT" --headless --path . --quit-after 60 res://scenes/main_menu.tscn 2>&1 | tee -a "$LOG"

echo "== 3/3 Teste de fumaça do nível principal"
timeout 120 "$GODOT" --headless --path . --quit-after 180 res://scenes/main.tscn 2>&1 | tee -a "$LOG"

python3 - "$LOG" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
errors = []
dummy_texture_errors = 0
i = 0
while i < len(lines):
    line = lines[i]
    if 'ERROR: Parameter "t" is null.' in line and i + 1 < len(lines) and "texture_2d_get (servers/rendering/dummy/storage/texture_storage.h" in lines[i + 1]:
        dummy_texture_errors += 1
        i += 2
        continue
    if "ERROR: 1 resources still in use at exit" in line and dummy_texture_errors:
        i += 1
        continue
    if "ERROR:" in line or "SCRIPT ERROR:" in line or "Parse Error:" in line:
        errors.append(line)
    i += 1
if errors:
    print("\n".join(errors))
    raise SystemExit("FALHA: foram encontrados erros reais no projeto.")
print(f"OK: menu e nível principal carregaram. Mensagens internas do renderer dummy ignoradas: {dummy_texture_errors}.")
PY
