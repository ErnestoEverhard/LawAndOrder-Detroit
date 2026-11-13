#!/bin/sh
# Tile the pictures in a folder into contact sheets (sheet_0.jpg, ...) for quick review. Needs ffmpeg.
#   tools/sheet.sh <dir> [pattern]
d="$1"; pat="${2:-*.png}"
ffmpeg -loglevel error -y -pattern_type glob -i "$d/$pat" -vf "scale=660:-1,tile=2x3:margin=4:padding=4" "$d/sheet_%d.jpg"
ls "$d" | grep sheet
