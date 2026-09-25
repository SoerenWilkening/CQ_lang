#!/bin/bash
# gen.sh name... : build p/<name>.s1.ll from <name>.c (+ lib: <name>.lib.c if present;
# else for a *C / *Q name, libC.c / libQ.c; *T twins are single TU).
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
cd "$(dirname "$0")/p" || exit 1
for b in "$@"; do
  b="${b%.c}"
  lib=""
  if [ -f "$b.lib.c" ]; then lib="$b.lib.c"; fi
  if [ -n "$lib" ]; then
    "$L/clang" -O1 -emit-llvm -S "$lib" -o "$b.lib.ll" 2>/dev/null || { echo "GENFAIL $b lib"; continue; }
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.caller.ll" 2>/dev/null || { echo "GENFAIL $b"; continue; }
    "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll" || { echo "GENFAIL $b link"; continue; }
  else
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.s1.ll" 2>/dev/null || { echo "GENFAIL $b"; continue; }
  fi
  n=$(wc -c < "$b.s1.ll"); [ "$n" -lt 200 ] && echo "WARN $b s1 tiny ($n bytes)"
done
exit 0
