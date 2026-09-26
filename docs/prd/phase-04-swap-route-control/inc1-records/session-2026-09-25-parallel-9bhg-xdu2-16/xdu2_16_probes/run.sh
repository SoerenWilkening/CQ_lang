#!/bin/bash
# run.sh file.c [clang args...] — stage1 + stage2 + 2b.  OPT env overrides cq-opt.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin
OPT=${OPT:-$W/build/ir-pass/cq-opt}
f=$1; b=${f%.c}
shift
"$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$@" "$f" -o "$b.s1.ll" || exit 9
"$OPT" -passes=cq-lowering -S "$b.s1.ll" -o "$b.s2.ll" 2> "$b.err"; rc=$?
echo "rc=$rc"; head -c 800 "$b.err"
if [ "$rc" = 0 ]; then python3 "$W/tools/free_pairing_check.py" "$b.s2.ll" | tail -2; fi
