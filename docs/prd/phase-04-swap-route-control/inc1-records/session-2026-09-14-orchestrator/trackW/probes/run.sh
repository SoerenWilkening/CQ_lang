#!/bin/zsh
# Track W, session 2026-09-14. Probe driver.
#   usage: run.sh <probe.c> [oracle|subject] [--keep]
# oracle  = /Users/sorenwilkening/Desktop/CQ_lang/build   (FROZEN, read-only)
# subject = /Users/sorenwilkening/Desktop/CQ_wx8g/build   (this worktree)
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
ORA=/Users/sorenwilkening/Desktop/CQ_lang
P=$1; W=${2:-subject}; B=${P:t:r}
if [ "$W" = "oracle" ]; then BUILD=$ORA/build; else BUILD=$SUB/build; fi
T=$(mktemp -d)
"$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$P" -o $T/s1.ll 2>$T/c1.err || { echo "STAGE1 FAIL"; cat $T/c1.err; exit 1; }
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
E=$?
echo "== $B [$W] : opt exit=$E"
if [ $E -ne 0 ]; then head -4 $T/o.err; else
  echo "   lowered lines: $(wc -l < $T/s2.ll)"
  python3 $SUB/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -2
  "$LLVM/clang" $T/s2.ll $BUILD/runtime/libcq_templates.a $BUILD/runtime/libcq_runtime.a -o $T/a 2>/dev/null && $T/a > $T/trace && echo "   trace lines: $(wc -l < $T/trace)" && cp -f $T/trace $(dirname $P)/$B.$W.trace
  cp -f $T/s2.ll $(dirname $P)/$B.$W.s2.ll
fi
echo "   tmp: $T"
