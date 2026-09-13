#!/bin/zsh
# Track L probe runner — READ-ONLY against the frozen ORACLE (PROTOCOL.md).
# Usage:  cd <repo root> && zsh docs/.../trackL/probes/run.sh
# Every row: <probe> | exit | first cq diagnostic   — or, for an accept,
# <probe> | exit=0 ACCEPT | lowered-IR lines / trace lines | STRICT stage 2b line.
set -u
REPO=${REPO:-$PWD}
LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
BUILD=${BUILD:-$REPO/build}
HERE=${0:A:h}
OUT=${OUT:-$(mktemp -d)}
echo "# ORACLE: $(shasum -a 256 $BUILD/ir-pass/cq-opt | cut -c1-16)  (expect fbbe0820ef4b176a)"
echo "# out: $OUT"
cd $REPO
for p in $HERE/*.c; do
  n=${p:t:r}
  "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S $p -o $OUT/$n.s1.ll 2>/dev/null || { echo "$n | CLANG-FAIL"; continue; }
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
      -S $OUT/$n.s1.ll -o $OUT/$n.s2.ll >/dev/null 2>$OUT/$n.err
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "$n | exit=$rc | $(grep -m1 -E 'error:' $OUT/$n.err | sed 's|.*error: ||')"
  else
    "$LLVM/clang" $OUT/$n.s2.ll $BUILD/runtime/libcq_templates.a $BUILD/runtime/libcq_runtime.a \
        -o $OUT/$n.exe 2>/dev/null && $OUT/$n.exe > $OUT/$n.trace
    echo "$n | exit=0 ACCEPT | ir=$(wc -l<$OUT/$n.s2.ll|tr -d ' ') trace=$(wc -l<$OUT/$n.trace|tr -d ' ') | 2b: $(python3 tools/free_pairing_check.py $OUT/$n.s2.ll 2>&1|tail -1)"
  fi
done
# the decline ANCHOR (which instruction the fence fired on):
#   CQ_CTRL_DBG=1 $BUILD/ir-pass/cq-opt -load-pass-plugin $BUILD/ir-pass/libCQPass.so \
#       -passes=cq-lowering -S $OUT/<probe>.s1.ll -o /dev/null 2>&1 | grep CQ_CTRL_DBG
# K-INDEPENDENCE is measured WITHOUT -g (debug metadata inflates the count):
#   clang -Iinclude -include CQ.h -O1 -emit-llvm -S p2.c      -> cq-opt -> wc -l  == 50
#   clang -Iinclude -include CQ.h -O1 -emit-llvm -S p2k1000.c -> cq-opt -> wc -l  == 50
