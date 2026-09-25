#!/bin/bash
# gen.sh name... : build p/<name>.s1.ll from p/<name>.c (+ p/<name>.lib.c if present)
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rB_d88e
cd "$R/p" || exit 1
for b in "$@"; do
  b="${b%.c}"
  if [ -f "$b.lib.c" ]; then
    "$L/clang" -O1 -emit-llvm -S "$b.lib.c" -o "$b.lib.ll" || { echo "GENFAIL $b lib"; continue; }
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.caller.ll" || { echo "GENFAIL $b"; continue; }
    "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll" || { echo "GENFAIL $b link"; continue; }
  else
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.s1.ll" || { echo "GENFAIL $b"; continue; }
  fi
  n=$(wc -c < "$b.s1.ll"); [ "$n" -lt 200 ] && echo "WARN $b s1 tiny ($n bytes)"
done
exit 0
