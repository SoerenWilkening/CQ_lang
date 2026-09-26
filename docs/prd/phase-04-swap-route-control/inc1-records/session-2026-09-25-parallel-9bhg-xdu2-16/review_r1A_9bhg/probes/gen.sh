#!/bin/bash
# gen.sh name... : build <name>.s1.ll from <name>.c (+ <name>.lib.c if present, else single TU)
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd "$(dirname "$0")/p"
for b in "$@"; do
  b=${b%.c}
  if [ -f "$b.lib.c" ]; then
    "$L/clang" -O1 -emit-llvm -S "$b.lib.c" -o "$b.lib.ll" || { echo "GENFAIL $b lib"; continue; }
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.caller.ll" || { echo "GENFAIL $b"; continue; }
    "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll" || { echo "GENFAIL $b link"; continue; }
  else
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.s1.ll" || { echo "GENFAIL $b"; continue; }
  fi
  n=$(wc -c < "$b.s1.ll"); [ "$n" -lt 200 ] && echo "WARN $b s1 tiny ($n bytes)"
done
