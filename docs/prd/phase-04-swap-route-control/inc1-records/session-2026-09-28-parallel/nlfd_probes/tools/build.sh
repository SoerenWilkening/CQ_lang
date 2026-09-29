#!/bin/bash
# build.sh <dir/name> : <name>.c [+ <name>.lib.c] -> <name>.s1.ll
# The run_slice_multi.sh recipe: the CQ TU with -include CQ.h, the lib TU WITHOUT it,
# both clang -O1, llvm-link. A <name>.ll that already exists (an IR-only probe) is
# copied to <name>.s1.ll untouched.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
L=/usr/local/opt/llvm@19/bin
n=$1; shift
if [ -f "$n.ll" ] && [ ! -f "$n.c" ]; then
  cp -f "$n.ll" "$n.s1.ll"
elif [ -f "$n.lib.c" ]; then
  $L/clang -I$W/include -O1 -emit-llvm -S -Wno-everything "$@" "$n.lib.c" -o "$n.lib.ll" || exit 1
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$@" "$n.c" -o "$n.caller.ll" || exit 1
  $L/llvm-link -S "$n.caller.ll" "$n.lib.ll" -o "$n.s1.ll" || exit 1
  rm -f "$n.lib.ll" "$n.caller.ll"
else
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything "$@" "$n.c" -o "$n.s1.ll" || exit 1
fi
[ -s "$n.s1.ll" ] || { echo EMPTY; exit 1; }
