#!/bin/bash
# build.sh NAME : NAME.c [+ NAME.lib.c] -> NAME.s1.ll (llvm-link, like run_slice_multi.sh). Run from probes/.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
L=/usr/local/opt/llvm@19/bin
n=$1; shift
CQ="$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $*"
if [ -f $n.lib.c ]; then
  $CQ $n.c -o out/$n.caller.ll && $L/clang -I$W/include -O1 -emit-llvm -S -Wno-everything $* $n.lib.c -o out/$n.lib.ll && $L/llvm-link -S out/$n.caller.ll out/$n.lib.ll -o $n.s1.ll && rm -f out/$n.caller.ll out/$n.lib.ll
else
  $CQ $n.c -o $n.s1.ll
fi
[ -s $n.s1.ll ] || echo "EMPTY $n"
