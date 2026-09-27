#!/bin/bash
# Build r2B's FA_F80 (+ twin FAT_F80) and R6 (+ twin R6T) as 2-TU modules.
set -e
cd "$(dirname "$0")"
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r2B_9bhg/probes/src
for pair in "FA_F80 libf" "FAT_F80 libf" "R6 lib" "R6T lib"; do
  set -- $pair
  cp -f "$R/$1.c" "$1.c"; cp -f "$R/$2.c" "$1.lib.c"
  "$L/clang" -O1 -emit-llvm -S -Wno-everything "$1.lib.c" -o "$1.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything "$1.c" -o "$1.caller.ll"
  "$L/llvm-link" -S "$1.caller.ll" "$1.lib.ll" -o "$1.s1.ll"
done
ls -la *.s1.ll
