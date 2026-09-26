#!/bin/bash
# ab_r2.sh <tag> <cq-opt binary> <outdir> <modules...>
# Runs the pass on every module (no pipes: rc is cq-opt's own), keeping
# stdout (lowered IR), stderr and rc per module. Refuses 0-byte inputs
# (the empty-module ACCEPT trap). Compare two runs with ab_cmp_r2.py.
TAG=$1; BIN=$2; OUT=$3; shift 3
mkdir -p "$OUT"
for f in "$@"; do [ -s "$f" ] || { echo "EMPTY INPUT $f" >&2; exit 3; }; done
run1() {
  local f=$1 b; b=$(basename "$f")
  "$BIN" -passes=cq-lowering -S "$f" -o "$OUT/$b.out" 2> "$OUT/$b.err"
  echo $? > "$OUT/$b.rc"
}
export -f run1; export BIN OUT
printf '%s\n' "$@" | xargs -P6 -I{} bash -c 'run1 "$1"' _ {}
echo "$TAG: $(ls "$OUT"/*.rc | wc -l) modules -> $OUT"
