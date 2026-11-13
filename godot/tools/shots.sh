#!/bin/sh
# Render every camera shot of one or more arrangements into a folder, for checking the look.
#   tools/shots.sh <out-dir> precinct:harlan precinct:booking ...
cd "$(dirname "$0")/.." || exit 1
out="$1"; shift
mkdir -p "$out"
for st in "$@"; do
	timeout 120 godot --path . -- --stage "$st" --shots "$out" 2>&1 | grep -iE "error|at: " | grep -vE "resources still|cleanup|clear \(core"
done
ls "$out"
