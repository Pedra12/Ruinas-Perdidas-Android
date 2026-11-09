# AGENTS.md — regras para o agente (ChatGPT/Codex)

## Projeto
Ruínas Perdidas: jogo 3D em terceira pessoa, Godot 4.3+ (renderer Mobile), GDScript tipado, alvo Android arm64, paisagem, controles de toque.

## Regras
1. Não reescreva do zero. Faça mudanças pequenas, execute e valide a cada passo.
2. Valide sempre com `./tools/validar.sh` (variável GODOT aponta para o executável). Não afirme "sem erros" sem ter rodado e lido a saída.
3. Todo caminho de asset fica em `scripts/core/asset_paths.gd`. Se a estrutura de pastas do repositório for diferente, ajuste lá ou mova os arquivos com `tools/organizar_assets.sh`.
4. Use apenas `.glb`/`.gltf`. Ignore `.fbx` e `.blend`.
5. Orçamento mobile: ~150 draw calls, ~300 mil triângulos visíveis, 1 luz direcional com sombra, MultiMesh para vegetação, texturas ≤ 1024 px (Nature Kit: rode `tools/reduzir_texturas.py`), compressão VRAM (ETC2/ASTC).
6. Não adicione dependências externas nem plugins. Não use C#.
7. Código: GDScript com tipos, funções curtas, sinais em vez de acoplamento direto, sem `get_node` por caminho frágil.
8. Sem segredos no repositório: nada de keystore, senhas ou chaves (já estão no .gitignore).
9. Commits pequenos e descritivos a cada marco.
10. Seja honesto no relatório final: separe "testado por mim" de "precisa testar em aparelho real".

## Comandos úteis
- Importar: `godot --headless --path . --import`
- Checar um script: `godot --headless --path . --check-only --script res://scripts/player/player.gd`
- Fumaça: `godot --headless --path . --quit-after 180 res://scenes/main.tscn`
- Exportar APK debug: `godot --headless --path . --export-debug "Android" build/RuinasPerdidas.apk`
- Regerar sons: `python3 tools/gerar_sons.py`
