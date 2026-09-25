#!/bin/bash
# Mirror run_slice_multi.sh for spec_classical_return with a given cq-opt ($1),
# printing the stage-2b line and the trace.
set -euo pipefail
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
OPT=$1
T=$(mktemp -d)
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/spec_classical_return_caller.c" -o "$T/cq.ll"
"$L/clang" -I"$W/include" -O1 -emit-llvm -S "$W/tests/e2e/spec_classical_return_lib.c" -o "$T/lib.ll"
"$L/llvm-link" -S "$T/cq.ll" "$T/lib.ll" -o "$T/combined.ll"
set +e
"$OPT" -passes=cq-lowering -S "$T/combined.ll" -o "$T/s2.ll" 2> "$T/err"
rc=$?
set -e
echo "opt rc=$rc"; cat "$T/err"
[ $rc -eq 0 ] || exit 0
python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" | tail -1
"$L/clang" "$T/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$T/slice" 2>/dev/null
echo "--- trace"
"$T/slice"
echo "--- main"
awk '/^define i32 @main/,/^}/' "$T/s2.ll"
