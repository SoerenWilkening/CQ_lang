#!/bin/bash
# build.sh — stage-1 of the e2e k65 probe, exactly as run_slice_multi.sh does it.
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
D=$(cd "$(dirname "$0")" && pwd)
cd "$D"
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S caller.c -o cq.ll
"$L/clang" -I"$W/include" -O1 -emit-llvm -S lib.c -o lib_0.ll
"$L/llvm-link" -S cq.ll lib_0.ll -o combined.ll
echo "built combined.ll ($(wc -l < combined.ll) lines)"
