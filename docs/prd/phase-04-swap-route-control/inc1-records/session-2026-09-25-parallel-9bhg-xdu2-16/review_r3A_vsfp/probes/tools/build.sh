#!/bin/bash
# build.sh NAME : NAME.c [+ NAME.lib.c] -> NAME.s1.ll (llvm-link, like run_slice_multi.sh)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
n=$1; shift
CQ="$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $*"
if [ -f $n.lib.c ]; then
  $CQ $n.c -o $n.caller.ll && $L/clang -O1 -emit-llvm -S -Wno-everything $* $n.lib.c -o $n.lib.ll && $L/llvm-link -S $n.caller.ll $n.lib.ll -o $n.s1.ll && rm -f $n.caller.ll $n.lib.ll
else
  $CQ $n.c -o $n.s1.ll
fi
[ -s $n.s1.ll ] || echo "EMPTY $n"
