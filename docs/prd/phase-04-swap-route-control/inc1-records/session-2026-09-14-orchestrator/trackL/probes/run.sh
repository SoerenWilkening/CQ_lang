#!/bin/zsh
# Track L, session 2026-09-14. READ-ONLY probe driver on the FROZEN ORACLE.
# ORACLE: build/ir-pass/cq-opt f7b65d8c… / libCQPass.so f9e898ba… (built from 59ac5b7).
# usage: run.sh <probe.c> [--dbg]   (from the repo root)
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
P=$1; B=${P:t:r}
T=$(mktemp -d)
"$LLVM/clang" -I$ROOT/include -include CQ.h -O1 -g -emit-llvm -S "$P" -o $T/s1.ll 2>$T/c1.err || { echo "STAGE1 FAIL"; cat $T/c1.err; exit 1; }
"$ROOT/build/ir-pass/cq-opt" -load-pass-plugin "$ROOT/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
E=$?
echo "== $B : opt exit=$E"
if [ $E -ne 0 ]; then head -4 $T/o.err; else
  echo "   lowered lines: $(wc -l < $T/s2.ll)"
  python3 $ROOT/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -2
  "$LLVM/clang" $T/s2.ll $ROOT/build/runtime/libcq_templates.a $ROOT/build/runtime/libcq_runtime.a -o $T/a 2>/dev/null && $T/a > $T/trace; echo "   trace lines: $(wc -l < $T/trace)"; cp -f $T/trace $(dirname $P)/$B.trace
fi
echo "$T" > /tmp/last_trackL_tmp
echo "   tmp: $T"
