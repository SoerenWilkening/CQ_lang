#!/bin/bash
# mkgold.sh <cq-opt> <cq.c> <lib.c|-> <out.trace>
#   The run_slice(_multi).sh stages verbatim (clang -O1 -include CQ.h for the CQ TU, the lib
#   TU without it, llvm-link, ONE cq-lowering, stage 2b STRICT, link templates-before-runtime at
#   -O0, run with NO arguments as ctest does) — writes the trace; prints the opt/2b/run status.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
L=/usr/local/opt/llvm@19/bin
B=$1; CQ=$2; LIB=$3; OUTF=$4
T=$(mktemp -d); rm -f "$OUTF"
$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S "$CQ" -o $T/cq.ll || exit 1
if [ "$LIB" != "-" ]; then
  $L/clang -I$W/include -O1 -emit-llvm -S "$LIB" -o $T/lib.ll || exit 1
  $L/llvm-link -S $T/cq.ll $T/lib.ll -o $T/c.ll || exit 1
else
  cp -f $T/cq.ll $T/c.ll
fi
"$B" -passes=cq-lowering -S $T/c.ll -o $T/s2.ll 2> $T/err; rc=$?
if [ $rc -ne 0 ]; then echo "opt=$rc $(grep -o 'error: .*' $T/err | head -1)"; rm -rf $T; exit 0; fi
pb=$(python3 $W/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -2 | tr '\n' ' ')
$L/clang $T/s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o $T/a 2>/dev/null || { echo LINKFAIL; exit 1; }
$T/a > "$OUTF"; r=$?
echo "opt=0 warn=$(grep -c warning $T/err) 2b[$pb] run=$r lines=$(wc -l < "$OUTF" | tr -d ' ')"
rm -rf $T
