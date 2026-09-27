#!/bin/bash
# build.sh <dir/name> : <name>.c [+ <name>.lib.c] -> <name>.s1.ll (clang -O1, llvm-link like run_slice_multi.sh)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8; L=/usr/local/opt/llvm@19/bin
n=$1; shift
if [ -f $n.lib.c ]; then
  $L/clang -O1 -emit-llvm -S -Wno-everything "$@" $n.lib.c -o $n.lib.ll || exit 1
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$@" $n.c -o $n.caller.ll || exit 1
  $L/llvm-link -S $n.caller.ll $n.lib.ll -o $n.s1.ll || exit 1
else
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$@" $n.c -o $n.s1.ll || exit 1
fi
[ -s $n.s1.ll ] || { echo EMPTY; exit 1; }
