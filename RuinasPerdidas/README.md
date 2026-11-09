# Ruínas Perdidas

Jogo 3D de ação e exploração para Android (Godot 4.3+, GDScript).

**Objetivo:** encontre 3 gemas, abra o portão do templo, derrote o guardião e abra o baú dourado.

**Controles (toque):** joystick à esquerda · ATQ / ROLAR / PULAR à direita · arraste o lado direito para girar a câmera.
**Teclado (testes no PC):** WASD mover, J atacar, K rolar, Espaço pular, Q/E câmera.

## Começando
1. Coloque os assets em `assets/` (veja `tools/organizar_assets.sh` e `TAREFAS_PARA_CHATGPT.md`).
2. `./tools/validar.sh` (precisa do Godot 4.3+ no PATH ou na variável `GODOT`).
3. Abra no Godot e execute (F5), ou exporte o APK (veja a Fase 5 em `TAREFAS_PARA_CHATGPT.md`).

## Créditos dos assets
Quaternius (Universal Animation Library, Stylized Nature MegaKit), KayKit, pacote Ruins/Skely e Human Basic Motions: confira as licenças originais incluídas em cada pacote antes de publicar. Sons e músicas foram gerados por código (`tools/gerar_sons.py`).
