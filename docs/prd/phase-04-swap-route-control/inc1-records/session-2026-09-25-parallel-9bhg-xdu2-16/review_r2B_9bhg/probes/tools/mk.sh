#!/bin/bash
# mk.sh NAME [LIBFILE] : builds $P/NAME.s1.ll from $P/NAME.c (+ lib, default $P/lib.c) via llvm-link
set -e
L=/usr/local/opt/llvm@19/bin
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9/p
INC=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/include
N=$1; LIB=${2:-$P/lib.c}
$L/clang -I$INC -include CQ.h -O1 -emit-llvm -S $P/$N.c -o $P/$N.cq.ll
$L/clang -I$INC -O1 -emit-llvm -S $LIB -o $P/$N.lib.ll
$L/llvm-link -S $P/$N.cq.ll $P/$N.lib.ll -o $P/$N.s1.ll
