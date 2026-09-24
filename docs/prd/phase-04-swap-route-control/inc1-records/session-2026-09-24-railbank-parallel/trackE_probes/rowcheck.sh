#!/bin/bash
# rowcheck.sh CASE... — count literal-template calls per matrix accept row (scratch)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8
L=/usr/local/opt/llvm@19/bin
cd "$W/te_scratch"
for c in "$@"; do
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -DCASE=$c $W/tests/e2e/condtree_classical_leaf_matrix.c -o rc$c.s1.ll
  $W/build/ir-pass/cq-opt -passes=cq-lowering -S rc$c.s1.ll -o rc$c.s2.ll 2>/dev/null; rc=$?
  n=$(grep -c "call i32 @cq_template_\(and\|or\)_i1_hl(" rc$c.s2.ll)
  u=$(grep -c "call void @cq_template_\(and\|or\)_i1_hl_unc(" rc$c.s2.ll)
  fp=$(python3 $W/tools/free_pairing_check.py rc$c.s2.ll 2>&1 | tail -1 | sed 's/.*site(s): //')
  echo "CASE $c rc=$rc fwd=$n unc=$u 2b: $fp"
done
