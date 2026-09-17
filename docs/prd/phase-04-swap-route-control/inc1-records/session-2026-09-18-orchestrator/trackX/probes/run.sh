#!/bin/zsh
# Track X probe runner (session 2026-09-18). Adapted from trackL/probes/run.sh.
# Usage: cd <repo root> && BUILD=<build dir> zsh <this>/run.sh ['<glob>']
# Every row: <probe> | exit | first cq diagnostic   — or, for an accept,
# <probe> | exit=0 ACCEPT | lowered-IR lines / trace lines | STRICT stage 2b line.
set -u
REPO=${REPO:-$PWD}
LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
BUILD=${BUILD:-$REPO/build}
HERE=${0:A:h}
OUT=${OUT:-$(mktemp -d)}
GLOB=${1:-'*.c'}
echo "# BINARY: $(shasum -a 256 $BUILD/ir-pass/cq-opt | cut -c1-16)"
echo "# out: $OUT"
cd $REPO
for p in $HERE/${~GLOB}; do
  n=${p:t:r}
  [ -f "$p" ] || continue
  case "$p" in
    *.ll) cp $p $OUT/$n.s1.ll ;;
    *) "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S $p -o $OUT/$n.s1.ll 2>/dev/null || { echo "$n | CLANG-FAIL"; continue; } ;;
  esac
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
      -S $OUT/$n.s1.ll -o $OUT/$n.s2.ll >/dev/null 2>$OUT/$n.err
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "$n | exit=$rc | $(grep -m1 -E 'error:' $OUT/$n.err | sed 's|.*error: ||')"
  else
    "$LLVM/clang" $OUT/$n.s2.ll $BUILD/runtime/libcq_templates.a $BUILD/runtime/libcq_runtime.a \
        -o $OUT/$n.exe 2>/dev/null && $OUT/$n.exe > $OUT/$n.trace 2>/dev/null
    echo "$n | exit=0 ACCEPT | ir=$(wc -l<$OUT/$n.s2.ll|tr -d ' ') trace=$(wc -l<$OUT/$n.trace 2>/dev/null|tr -d ' ') | 2b: $(python3 tools/free_pairing_check.py $OUT/$n.s2.ll 2>&1|tail -1)"
  fi
done
echo "# keep: $OUT"
