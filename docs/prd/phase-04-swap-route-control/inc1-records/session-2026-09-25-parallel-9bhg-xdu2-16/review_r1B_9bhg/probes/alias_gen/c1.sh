#!/bin/bash
L=/usr/local/opt/llvm@19/bin; W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
b=$(basename "$1" .c); cd "$(dirname "$1")"
$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S $b.c -o $b.caller.ll 2>/dev/null && $L/llvm-link -S $b.caller.ll lib.ll -o $b.s1.ll
