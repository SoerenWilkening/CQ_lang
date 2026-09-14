#!/bin/bash
# The ROUND-1 probe population (trackD/probes/src, 27 modules: the 14 reproducers
# + the must-not-move table) measured on an EXPLICIT binary root, so the BEFORE
# column comes from the REAL B12 binary (saved aside across the rebuild) rather
# than from a cited row about a different binary.
#   usage: m27.sh <TAG> <build-root>
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=/Users/sorenwilkening/Desktop/CQ_3d8q
SRC="$ROOT/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/probes/src"
TAG="$1"; B="$2"
mkdir -p "$HERE/$TAG" "$HERE/s1"
for f in "$SRC"/*.c; do
  n=$(basename "$f" .c); s1="$HERE/s1/p27_$n.ll"
  if [ ! -s "$s1" ]; then
    "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$s1" 2>/dev/null \
      || { echo "$n | STAGE1-FAIL"; continue; }
  fi
  [ -s "$s1" ] || { echo "$n | ZERO-BYTE-S1 (VACUOUS)"; continue; }
  "$B/ir-pass/cq-opt" -passes=cq-lowering -S "$s1" -o "$HERE/$TAG/p27_$n.s2.ll" 2> "$HERE/$TAG/p27_$n.err"
  if [ $? -ne 0 ]; then
    d=$(grep -o "cq [a-z/ -]*lowering:[^\"]*" "$HERE/$TAG/p27_$n.err" | head -1)
    [ -z "$d" ] && d=$(grep -o "cq [a-z]*:[^\"]*" "$HERE/$TAG/p27_$n.err" | head -1)
    [ -z "$d" ] && d=$(head -1 "$HERE/$TAG/p27_$n.err")
    echo "$n | D[$d]"
  else
    [ -s "$HERE/$TAG/p27_$n.s2.ll" ] || { echo "$n | ZERO-BYTE-S2 (VACUOUS)"; continue; }
    "$LLVM/clang" "$HERE/$TAG/p27_$n.s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" \
        -o "$HERE/$TAG/p27_$n.exe" 2>>"$HERE/$TAG/p27_$n.err" \
      && "$HERE/$TAG/p27_$n.exe" > "$HERE/$TAG/p27_$n.trace" 2>&1
    echo "$n | A[trace=$(grep -c . "$HERE/$TAG/p27_$n.trace" 2>/dev/null || echo 0)]"
  fi
done
