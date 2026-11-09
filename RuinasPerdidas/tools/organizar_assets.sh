#!/usr/bin/env bash
# Extrai os assets compatíveis com o projeto usando os nomes reais dos pacotes.
# Uso: ./tools/organizar_assets.sh [pasta-com-os-zips]
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$(cd "${1:-$PROJECT_DIR/..}" && pwd)"
OUT="$PROJECT_DIR/assets"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

need_file() {
  if [[ ! -f "$1" ]]; then
    echo "ERRO: pacote obrigatório não encontrado: $1" >&2
    exit 1
  fi
}

need_file "$SRC/RuinsGLB.zip"
need_file "$SRC/Universal Animation Library[Standard].zip"
need_file "$SRC/KayKit_Character_Animations_1.1.zip"
need_file "$SRC/mapa-springfield.zip"
need_file "$SRC/Stylized.Nature.MegaKit.Standard.zip"

mkdir -p "$OUT"/{characters,enemies,ruins,nature,kaykit,springfield}
mkdir -p "$PROJECT_DIR/docs/source/springfield"

# Ruínas, acessórios, peças arquitetônicas e inimigos esqueléticos.
unzip -oq "$SRC/RuinsGLB.zip" -d "$TMP/ruins"
cp -a "$TMP/ruins/RuinsGLB/." "$OUT/ruins/"
if [[ -d "$OUT/ruins/Skely" ]]; then
  find "$OUT/ruins/Skely" -maxdepth 1 -type f -iname '*.glb' -exec cp -f {} "$OUT/enemies/" \;
fi

# Personagem e animações principais no formato glTF nativo para Godot.
unzip -oq "$SRC/Universal Animation Library[Standard].zip" -d "$TMP/ual"
UAL="$(find "$TMP/ual" -type f -path '*/Unreal-Godot/UAL1_Standard.glb' -print -quit)"
if [[ -z "$UAL" ]]; then
  echo "ERRO: UAL1_Standard.glb não encontrado no pacote Universal Animation Library." >&2
  exit 1
fi
cp -f "$UAL" "$OUT/characters/UAL1_Standard.glb"

# Nature Kit: manter juntos glTF, BIN e texturas, pois os modelos usam caminhos relativos.
unzip -oq "$SRC/Stylized.Nature.MegaKit.Standard.zip" 'glTF/*' -d "$TMP/nature"
if [[ ! -d "$TMP/nature/glTF" ]]; then
  echo "ERRO: pasta glTF não encontrada no pacote Stylized Nature." >&2
  exit 1
fi
cp -a "$TMP/nature/glTF/." "$OUT/nature/"

# Manter modelos e animações KayKit em pasta própria, sem misturar rigs diferentes.
unzip -oq "$SRC/KayKit_Character_Animations_1.1.zip" -d "$TMP/kaykit"
find "$TMP/kaykit" -type f -iname '*.glb' -print0 | while IFS= read -r -d '' file; do
  cp -f "$file" "$OUT/kaykit/$(basename "$file")"
done

# Springfield é conteúdo-fonte OBJ. Preservar separado para conversão posterior,
# sem forçar o importador Godot a carregar o OBJ pesado na fase principal.
unzip -oq "$SRC/mapa-springfield.zip" -d "$TMP/springfield"
while IFS= read -r -d '' inner; do
  dest="${inner%.zip}"
  mkdir -p "$dest"
  unzip -oq "$inner" -d "$dest"
done < <(find "$TMP/springfield" -type f -iname '*.zip' -print0)
if command -v 7z >/dev/null 2>&1; then
  while IFS= read -r -d '' archive; do
    dest="$TMP/springfield/rar_extracted/$(basename "${archive%.*}")"
    mkdir -p "$dest"
    7z x -y "-o$dest" "$archive" >/dev/null
  done < <(find "$TMP/springfield" -type f -iname '*.rar' -print0)
fi
touch "$PROJECT_DIR/docs/source/springfield/.gdignore"
if [[ -d "$TMP/springfield/rar_extracted" ]]; then
  cp -a "$TMP/springfield/rar_extracted/." "$PROJECT_DIR/docs/source/springfield/"
fi

# Reduzir texturas gigantes do Nature Kit para respeitar o orçamento mobile.
if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' >/dev/null 2>&1; then
  python3 "$PROJECT_DIR/tools/reduzir_texturas.py" "$OUT/nature" 1024
else
  echo "AVISO: Pillow não instalado; texturas mantidas originais."
fi

echo "Assets extraídos:"
find "$OUT" -type f | sort
echo
echo "Arquivos: $(find "$OUT" -type f | wc -l)"
du -sh "$OUT"
