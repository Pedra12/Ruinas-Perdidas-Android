#!/usr/bin/env bash
# Uso (na raiz do projeto): ./tools/organizar_assets.sh /caminho/dos/zips
# Se os arquivos já estiverem extraídos no repositório, apenas copie-os para a
# estrutura abaixo (ou ajuste scripts/core/asset_paths.gd).
set -e
SRC="${1:-.}"; OUT="assets"; T=$(mktemp -d)
mkdir -p $OUT/{characters,enemies,ruins,nature,kaykit,springfield}
unzip -oq "$SRC/RuinsGLB.zip" -d "$T/r" && cp -r "$T"/r/RuinsGLB/* $OUT/ruins/
mv $OUT/ruins/Skely/*.glb $OUT/enemies/ && rm -rf $OUT/ruins/Skely
unzip -oq "$SRC/Universal_Animation_Library_Standard_.zip" -d "$T/u"
cp "$T"/u/*/Unreal-Godot/UAL1_Standard.glb $OUT/characters/
unzip -oq "$SRC/Stylized_Nature_MegaKit_Standard_.zip" 'glTF/*' -d "$T/n" && cp -r "$T"/n/glTF/* $OUT/nature/
unzip -oq "$SRC/KayKit_Character_Animations_1_1.zip" '*Rig_Medium_*.glb' '*Mannequin_Medium.glb' -d "$T/k"
find "$T/k" -name '*.glb' -exec cp {} $OUT/kaykit/ \;
unzip -oq "$SRC/mapa-springfield.zip" -d $OUT/springfield
rm -rf "$T"; find $OUT -type f | wc -l; du -sh $OUT
