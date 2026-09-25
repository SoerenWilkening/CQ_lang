#!/bin/bash
# Build 2-TU probes: <name>.c (caller, -include CQ.h) llvm-linked with lib.c
# (or <name>.lib.c if present). Usage: bash gen.sh rt1.c rt2.c ...
set -e
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd "$(dirname "$0")"
for c in "$@"; do
  b=${c%.c}
  lib=lib.c
  if [ -f "$b.lib.c" ]; then lib="$b.lib.c"; fi
  "$L/clang" -O1 -emit-llvm -S "$lib" -o "$b.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$c" -o "$b.caller.ll"
  "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll"
done
