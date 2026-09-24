#!/bin/bash
# usage: run.sh file.c [cq-opt]   (scratch, never committed)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8
L=/usr/local/opt/llvm@19/bin
OPT=${2:-$W/build/ir-pass/cq-opt}
b=${1%.c}
$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S $1 -o $b.s1.ll || exit 9
$OPT -load-pass-plugin x -passes=cq-lowering -S $b.s1.ll -o $b.s2.ll 2> $b.err; rc=$?
echo "$b rc=$rc $(grep -m2 -E 'error|warning' $b.err | cut -c1-220)"
