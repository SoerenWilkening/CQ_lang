#!/bin/bash
# trace1.sh <cq-opt> <src.c> <args...> : stage 1 -> stage 2 -> 2b -> link -> run(args); prints verdict + trace.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
OPT=$1; SRC=$2; shift 2
T=$(mktemp -d)
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$T/s1.ll" || exit 1
if ! "$OPT" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2> "$T/err"; then
  echo "DECLINE: $(grep -m1 -o 'lowering: .*' "$T/err")"; rm -rf "$T"; exit 0
fi
python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" 2>&1 | tail -1
"$L/clang" "$T/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$T/exe" 2>/dev/null
"$T/exe" "$@"
rm -rf "$T"
