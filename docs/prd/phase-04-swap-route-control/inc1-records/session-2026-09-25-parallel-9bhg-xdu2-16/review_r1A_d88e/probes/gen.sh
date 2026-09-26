#!/bin/bash
# gen.sh name... : src/<name>.c (+ src/<name>.lib.c if present, llvm-linked) -> p/<name>.s1.ll
L=/usr/local/opt/llvm@19/bin
I=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440/include
A="$(cd "$(dirname "$0")" && pwd)"
for b in "$@"; do
  b="${b%.c}"
  src="$A/src/$b.c"; lib="$A/src/$b.lib.c"; out="$A/p/$b.s1.ll"
  rm -f "$out"
  if [ -f "$lib" ]; then
    "$L/clang" -O1 -emit-llvm -S "$lib" -o "$A/p/$b.lib.ll" || { echo "GENFAIL $b lib"; continue; }
    "$L/clang" "-I$I" -include CQ.h -O1 -emit-llvm -S "$src" -o "$A/p/$b.caller.ll" || { echo "GENFAIL $b"; continue; }
    "$L/llvm-link" -S "$A/p/$b.caller.ll" "$A/p/$b.lib.ll" -o "$out" || { echo "GENFAIL $b link"; continue; }
  else
    "$L/clang" "-I$I" -include CQ.h -O1 -emit-llvm -S "$src" -o "$out" || { echo "GENFAIL $b"; continue; }
  fi
  n=$(wc -c < "$out"); [ "$n" -lt 300 ] && echo "WARN $b s1 tiny ($n bytes)"
  grep -q '@cq_theta\|@cq_measure' "$out" || echo "WARN $b s1 has no cq_ intrinsic"
done
exit 0
