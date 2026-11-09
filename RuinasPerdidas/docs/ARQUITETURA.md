# Arquitetura

```
project.godot          renderer Mobile, paisagem, autoloads Game e AudioManager
scenes/
  main_menu.tscn       só carrega scripts/ui/main_menu.gd (UI criada por código)
  main.tscn            só carrega scripts/world/level.gd (mundo criado por código)
scripts/
  autoload/
    game.gd            estado da partida (gemas, moedas, tempo), configurações, qualidade gráfica, sinais globais
    audio_manager.gd   pool de 10 players de SFX + música com loop; ignora arquivos ausentes
  core/
    asset_paths.gd     TODOS os caminhos de assets
    utils.gd           carregar modelo (com placeholder), AABB, fit_height, loops de animação
  player/
    player.gd          CharacterBody3D; estados MOVE/ATTACK/ROLL/HURT/DEAD; stamina; hurt()/heal()
    player_camera.gd   câmera terceira pessoa com SpringArm3D; yaw/pitch por toque
  enemies/
    enemy.gd           esqueletos e chefe; estados IDLE/CHASE/ATTACK/HURT/DEAD; take_damage()
  world/
    level.gd           monta tudo: ambiente, chão, pátio, ruínas, vegetação (MultiMesh), spawns
    pickup.gd          moedas e gemas (Area3D)
    gate.gd            barreira mágica do portão; abre com 3 gemas
    chest.gd           baú final; abre após o chefe morrer; dispara vitória
  ui/
    touch_controls.gd  joystick + 3 botões + arrastar câmera, multitoque por índice de dedo
    hud.gd             barras, contadores, mensagens, barra do chefe, botão de pausa
    overlay_menu.gd    pausa, vitória, derrota
    main_menu.gd       menu inicial
    ui_style.gd        estilos reutilizáveis (botões grandes para toque)
audio/sfx, audio/music WAVs gerados por tools/gerar_sons.py
tools/                 organizar_assets.sh, reduzir_texturas.py, gerar_sons.py, validar.sh
```

## Fluxo de dados
- Player/inimigos/itens falam com a UI **somente** por sinais de `Game` (`health_changed`, `gems_changed`, `message`...).
- Inimigo chama `target.hurt(dano, origem)`; jogador chama `enemy.take_damage(1, origem)`. A comunicação entre eles usa `call()` (sem referência cruzada de classes).
- `Game.finish(win)` emite `victory`/`game_over`; `Level` mostra `OverlayMenu`.

## Camadas de colisão
1 = mundo (chão, paredes, árvores, barreiras) · 2 = jogador · 4 = inimigos.

## Qualidade gráfica (Game.apply_quality)
Baixa: escala 3D 0.6 + FSR + FXAA, sem sombras. Média: 0.8 + FSR + MSAA 2x, sombras 40 m. Alta: 1.0 + MSAA 2x, sombras 60 m. FPS 30/60 configurável.

## Como estender
- Novo inimigo: adicione uma entrada em `ENEMY_KINDS` e `ENEMY_SPAWNS` (level.gd).
- Novo prop de ruína: adicione em `RUIN_PIECES`.
- Nova vegetação: adicione em `VEGETATION`.
- Novo som: ponha `nome.wav` em `audio/sfx` e chame `AudioManager.play_sfx("nome")`.
