#!/bin/bash
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r3rev
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
L=/usr/local/opt/llvm@19/bin
set -o pipefail
K=$W/ir-pass/test/spec_scrub_dangling_key_clone_classical_mul.ll
U=$W/ir-pass/test/lowering_reject_break_uncollected_clone.ll
O=$R/pins_out; mkdir -p $O
k65() { # $1 = label, $2 = lifo-cmd prefix binary, $3 env for lifo, $4 nofree env, $5 sys binary
  local ok=1
  env $3 $2 -passes=cq-lowering -S $K > $O/lifo.ll 2>/dev/null || ok=0
  env $4 $2 -passes=cq-lowering -S $K > $O/nofree.ll 2>/dev/null || ok=0
  $5 -passes=cq-lowering -S $K > $O/sys.ll 2>/dev/null || ok=0
  $L/FileCheck $K --implicit-check-not=cq_template_mul < $O/lifo.ll > /dev/null 2>&1 || ok=0
  diff -q $O/lifo.ll $O/nofree.ll > /dev/null || ok=0
  diff -q $O/lifo.ll $O/sys.ll > /dev/null || ok=0
  [ -s $O/lifo.ll ] || ok=0
  echo "k65 $1 $([ $ok = 1 ] && echo PASS || echo FAIL)"
}
for i in 1 2 3 4 5; do k65 head-run$i $R/bin/cq-opt-debugalloc.head CQ_OPT_DEBUG_ALLOC=lifo CQ_OPT_DEBUG_ALLOC=nofree $R/bin/cq-opt.head; done
for i in 1 2 3; do k65 ba80+rb8-run$i $R/bin/cq-opt.ba80 "DYLD_INSERT_LIBRARIES=$T/rb8_interpose.dylib RB8_ALLOC=lifo" "DYLD_INSERT_LIBRARIES=$T/rb8_interpose.dylib RB8_ALLOC=nofree" $R/bin/cq-opt.ba80; done
for i in 1 2 3 4 5; do
  CQ_OPT_DEBUG_ALLOC=nofree $L/not $R/bin/cq-opt-debugalloc.head -passes=cq-lowering -S $U 2>&1 | $L/FileCheck $U > /dev/null 2>&1
  rc=$?; echo "um24 break_uncollected_clone nofree head run$i rc=$rc $([ $rc = 0 ] && echo PASS || echo FAIL)"
done
for i in 1 2 3; do
  DYLD_INSERT_LIBRARIES=$T/rb8_interpose.dylib RB8_ALLOC=nofree $L/not $R/bin/cq-opt.ba80 -passes=cq-lowering -S $U 2>&1 | $L/FileCheck $U > /dev/null 2>&1
  rc=$?; echo "um24 break_uncollected_clone nofree ba80+rb8 run$i rc=$rc $([ $rc = 0 ] && echo PASS || echo FAIL)"
done
