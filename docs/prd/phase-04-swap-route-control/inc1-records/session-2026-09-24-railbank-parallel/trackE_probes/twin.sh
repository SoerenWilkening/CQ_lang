#!/bin/bash
# twin.sh CASE_A CASE_B args... — build both matrix cases, run, diff traces (scratch)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8
L=/usr/local/opt/llvm@19/bin
OPT=${OPT:-$W/build/ir-pass/cq-opt}
SRC=${SRC:-$W/tests/e2e/condtree_classical_leaf_matrix.c}
cd "$W/te_scratch"
A=$1; B=$2; shift 2
for c in $A $B; do
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -DCASE=$c $SRC -o mx$c.s1.ll || exit 9
  $OPT -passes=cq-lowering -S mx$c.s1.ll -o mx$c.s2.ll || exit 8
  python3 $W/tools/free_pairing_check.py mx$c.s2.ll | tail -1
  $L/clang mx$c.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o mx$c.exe 2>/dev/null || exit 7
  ./mx$c.exe "$@" > mx$c.trace
  wc -l < mx$c.trace
done
diff mx$A.trace mx$B.trace && echo IDENTICAL
