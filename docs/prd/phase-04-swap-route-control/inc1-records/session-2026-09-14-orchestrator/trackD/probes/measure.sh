#!/bin/bash
# Track D probe harness — ORACLE vs SUBJECT on one stage-1 file per probe.
#
#   measure.sh <tag> <build-dir> [probe.c ...]
#
# Stage 1 is produced ONCE per probe (into probes/s1/) and BOTH binaries are run
# on the SAME .ll, per PROTOCOL.md's per-probe pipeline. A row is
#   <probe> | exit=<n> | <first diagnostic line, or -> for an accept> | <trace lines>
# Lowered-IR md5s are deliberately NOT compared across sweeps (PROTOCOL S3).
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../../../../.." && pwd)"
TAG="$1"; BUILD="$2"; shift 2
OUT="$HERE/$TAG"; mkdir -p "$OUT" "$HERE/s1"
for c in "$@"; do
  n=$(basename "$c" .c)
  s1="$HERE/s1/$n.ll"
  if [ ! -f "$s1" ]; then
    "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$c" -o "$s1" \
      2> "$HERE/s1/$n.cc.err" || { echo "$n | STAGE1-FAIL"; continue; }
  fi
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$s1" -o "$OUT/$n.s2.ll" 2> "$OUT/$n.err"
  e=$?
  if [ $e -ne 0 ]; then
    d=$(grep -o "cq[^']*" "$OUT/$n.err" | head -1)
    [ -z "$d" ] && d=$(head -2 "$OUT/$n.err" | tr '\n' ' ')
    echo "$n | exit=$e | D: $d | -"
  else
    python3 "$ROOT/tools/free_pairing_check.py" "$OUT/$n.s2.ll" > "$OUT/$n.2b" 2>&1
    fp=$?
    "$LLVM/clang" "$OUT/$n.s2.ll" "$BUILD/runtime/libcq_templates.a" \
        "$BUILD/runtime/libcq_runtime.a" -o "$OUT/$n.exe" 2>> "$OUT/$n.err" \
      && "$OUT/$n.exe" > "$OUT/$n.trace" 2>&1
    t=$(grep -c . "$OUT/$n.trace" 2>/dev/null || echo 0)
    echo "$n | exit=0 | A (2b=$fp) | trace=$t"
  fi
done
