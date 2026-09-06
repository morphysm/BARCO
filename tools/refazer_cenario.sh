#!/usr/bin/env bash
# Refaz tudo o que sai do `assentamento_cenario`: o video, o gif e o
# executavel. O Godot nao escreve video — so grava imagens — entao sao
# quatro passos, e correr so o de filmar deixa o resto como estava.
#
#   tools/refazer_cenario.sh
#
# GRAVA A CENA NO EDITOR PRIMEIRO. Isto le o ficheiro em disco; o editor
# mostra o que tem em memoria, e enquanto nao gravares sao coisas
# diferentes.
set -euo pipefail

cd "$(dirname "$0")/.."
RAIZ=$PWD
SAIDA=build/assentamento
QUADROS=capturas/filme

command -v ffmpeg >/dev/null || { echo "falta o ffmpeg"; exit 1; }
mkdir -p "$SAIDA"

CENA=client/scenes/assentamento_cenario.tscn
echo "cena gravada em: $(date -r "$CENA" '+%Y-%m-%d %H:%M:%S')"
echo

echo "1/4  a filmar 12 s..."
rm -f "$QUADROS"/*.png
godot --path client --script res://tools/filmar_assentamento.gd \
      --resolution 720x900 --fixed-fps 30 >/dev/null

echo "2/4  mp4..."
ffmpeg -y -v error -framerate 30 -i "$QUADROS/%04d.png" \
       -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart \
       "$SAIDA/assentamento.mp4"

echo "3/4  gif..."
ffmpeg -y -v error -i "$SAIDA/assentamento.mp4" \
       -vf "fps=15,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" \
       "$SAIDA/assentamento.gif"

echo "4/4  executavel..."
godot --headless --path client --export-release "Assentamento (Linux)" >/dev/null

echo
ls -lh "$SAIDA"
