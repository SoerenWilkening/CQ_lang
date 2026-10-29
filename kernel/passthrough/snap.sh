#!/bin/bash
# snap.sh [SRC]: pin a plugin build for a full kernel run (cq-ls7l). A shared checkout's plugin (main's
# build/pass/libCQLower.so) is rebuilt on every merge, often more than once during the 2852 TUs, and a
# result is only valid under one hash. snap.sh copies SRC (default: main's plugin) to
# $KSRC/check/plugin/<sha256>/libCQLower.so and writes libCQLower.so.origin next to it (source path,
# sha256, source mtime, HEAD of the source checkout at copy time). Prints the copy's path: pass it as
# PLUGIN to check.sh and report.py. The copy is byte-identical to SRC (its sha256 names the directory).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
src=${1:-$WT/../CQ_lang2/build/pass/libCQLower.so}
src=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
sha=$(shasum -a 256 "$src" | cut -d' ' -f1)
d=$KSRC/check/plugin/$sha; mkdir -p "$d"
cp "$src" "$d/libCQLower.so.tmp"
[ "$(shasum -a 256 "$d/libCQLower.so.tmp" | cut -d' ' -f1)" = "$sha" ] || { echo "snap: $src changed while copying" >&2; exit 1; }
mv "$d/libCQLower.so.tmp" "$d/libCQLower.so"
co=$(cd "$(dirname "$src")/../.." && pwd)
printf 'source  %s\nsha256  %s\nmtime   %s\ncommit  %s (HEAD of %s when copied)\n' "$src" "$sha" \
  "$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%S%z' "$src")" "$(git -C "$co" rev-parse HEAD)" "$co" > "$d/libCQLower.so.origin"
echo "$d/libCQLower.so"
