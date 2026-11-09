# Tarefas para o ChatGPT — Ruínas Perdidas

## Situação atual
O projeto foi escrito sem ter sido executado numa engine (o ambiente onde foi criado não tinha Godot). Portanto:
**o código é uma base completa e coerente, mas pode ter erros de sintaxe/API a corrigir.** O primeiro objetivo é fazê-lo abrir e rodar sem nenhum erro.

O que já existe: menu principal, nível completo gerado por código (floresta, ruínas, pátio do templo com portão, chefe e baú), jogador com 5 estados, inimigos com IA simples, coletáveis, HUD, pausa/vitória/derrota, controles de toque, qualidade gráfica (3 níveis), áudio (16 efeitos + 3 músicas gerados), salvar configurações.

## Fase 0 — Preparar (obrigatório)
1. Garanta que `assets/` esteja assim (use `tools/organizar_assets.sh` se partir dos zips originais):
   - `assets/characters/UAL1_Standard.glb`
   - `assets/enemies/Skely.glb`, `SkelyDraugr.glb`, `SkelyPoison.glb`
   - `assets/ruins/` com `Accessories/ Blocks/ Fences/ Moss/ Pillars/ Stairs/ Walls/`
   - `assets/nature/` com os `.gltf`, `.bin` e `.png`
2. `pip install pillow && python3 tools/reduzir_texturas.py` (reduz texturas do Nature Kit para 1024 px).
3. Instale Godot 4.3+ (com export templates Android), JDK 17 e Android SDK; configure `GODOT` e as variáveis do SDK.

## Fase 1 — Zero erros (prioridade máxima)
1. `./tools/validar.sh` e corrija TUDO que aparecer (erros de parse, tipos, nomes de API). Repita até sair "OK".
2. Mantenha a arquitetura. Se precisar mudar uma API, mude em todos os pontos de uso.
3. Confirme que `class_name` globais foram registrados (rode `--import` duas vezes se necessário).

## Fase 2 — Conferir os assets de verdade (verificação visual/numérica)
Estes pontos foram assumidos a partir da leitura dos arquivos e precisam ser confirmados:
- Escala/altura: jogador 1,8 m (`Utils.fit_height`), esqueleto 1,9 m, chefe 4,4 m. O Skely vem do Mixamo (cm). Se algo sair gigante/minúsculo, corrija a escala.
- Orientação: modelos devem olhar para +Z. Se o esqueleto olhar para trás, ajuste `MODEL_YAW_OFFSET` em `scripts/enemies/enemy.gd`.
- Nomes de animação: Jogador `Idle_Loop, Walk_Loop, Jog_Fwd_Loop, Sprint_Loop, Jump_Start, Jump_Loop, Roll, Sword_Attack, Hit_Chest, Death01`. Esqueleto `Idle, Run, Attack, Hit, Death, Scream`. Imprima `AnimationPlayer.get_animation_list()` e confirme que os nomes batem (o Godot pode prefixar com nome de biblioteca).
- Loops: `Utils.force_loops` marca como loop os nomes terminados em `_Loop` e `Idle`/`Run` dos esqueletos.
- Colisões: paredes/pilares usam caixa (AABB). `Walls/Gate.glb` está sem colisão própria (a barreira é `scripts/world/gate.gd`). Se a abertura do portão tiver largura diferente de 6,6 m, ajuste `Gate.WIDTH` e o modelo.
- Baú: a tampa (`ChestCover`) sobe e gira ao abrir; ajuste o pivô se ficar estranho.
- Materiais: confirme que folhas das árvores usam recorte (alpha scissor) e não ficam pretas; texturas com normal map devem importar como "Normal Map".
- Câmera: conferir que a SpringArm não "pula" dentro dos muros do pátio; ajuste `spring_length`/`margin`.

## Fase 3 — Jogabilidade e qualidade
- Jogar o loop completo: coletar 3 gemas → portão abre → chefe → baú → vitória; e testar derrota e reiniciar.
- Ajustar equilíbrio: vida do jogador 100, dano dos inimigos 10–22, chefe 14 de vida, ataque causa 1 de dano.
- Inimigos usam perseguição direta. Melhorar com `NavigationRegion3D`/`NavigationAgent3D` (bake em runtime ou navmesh simples) se travarem em paredes.
- Adicionar uma espada na mão do jogador (BoneAttachment3D) — opcional; não há modelo de espada nos assets, pode ser uma malha simples.
- Partículas leves (poeira, brilho das gemas) com `GPUParticles3D` de poucos pontos.
- Salvar progresso: melhor tempo já é salvo em `user://settings.cfg`.

## Fase 4 — Desempenho (mobile)
- Medir draw calls/triângulos com o Monitor de vídeo do Godot. Meta: ≤150 draw calls, ≤300k triângulos, 60 FPS estáveis.
- Se passar do orçamento: reduzir `VEGETATION` em `scripts/world/level.gd`, aumentar o tamanho da célula do MultiMesh, reduzir `vis_end`, desligar sombras na qualidade Baixa (já feito), usar LOD nos modelos grandes.
- Rodar 10 minutos e conferir ausência de vazamento de memória (número de nós/recursos estável).
- Confirmar import de texturas como VRAM Compressed (ASTC/ETC2) e `import_etc2_astc=true` já está no `project.godot`.

## Fase 5 — Android
1. Edite `export_presets.cfg` (já tem um preset "Android" de partida): nome do pacote, ícones, `arm64-v8a`.
2. Configure no Godot: Editor Settings → Export → Android (caminhos do SDK, JDK e keystore de debug).
3. `godot --headless --path . --export-debug "Android" build/RuinasPerdidas.apk`.
4. Para a Google Play: gere AAB (use build Gradle), crie keystore de release e guarde-a fora do repositório.
5. Teste no aparelho: toques simultâneos (joystick + botões + câmera), notch/área segura, botão voltar (abre pausa), rotação paisagem.

## Critérios de aceite (todos obrigatórios)
- [ ] `./tools/validar.sh` termina com "OK".
- [ ] Console do Godot sem erros nem warnings ao jogar do menu até a vitória.
- [ ] Loop completo jogável, com derrota e reinício funcionando.
- [ ] 60 FPS no preset Médio num celular intermediário (ou relatar a medição real).
- [ ] APK debug exportado e instalado.
- [ ] Relatório final honesto (testado × não testado).

## Backlog opcional
Mais fases, inimigos à distância, itens de cura, minimapa, tradução, mapa de Springfield como fase extra (veja `docs/SPRINGFIELD.md`).
