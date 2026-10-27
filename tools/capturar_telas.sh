#!/usr/bin/env bash
# Roda tools/capturar_telas.gd com backup e restauração do save do PC.
# Uso: bash tools/capturar_telas.sh <pasta_saida> [tela1,tela2]
set -u
SAVE="$APPDATA/Godot/app_userdata/SketchBlade/save_data.json"
cp "$SAVE" "$SAVE.bak-telas"
"/d/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" --path . -s tools/capturar_telas.gd -- "$@" 2>&1 | grep -E "capturar_telas|SCRIPT ERROR|Parse Error|at: " | grep -v leaked
cp "$SAVE.bak-telas" "$SAVE" && rm "$SAVE.bak-telas"
