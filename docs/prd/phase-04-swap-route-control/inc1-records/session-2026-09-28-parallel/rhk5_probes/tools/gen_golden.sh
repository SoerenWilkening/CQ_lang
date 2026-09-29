#!/bin/bash
# gen_golden.sh BIN SLICE.c [LIB.c] : mirror run_slice[_multi].sh stages 1-5 with the
# given cq-opt binary and PRINT the trace (stdout). Stage 2b runs STRICT and its
# census goes to stderr. The golden is written only by the caller, deliberately.
set -euo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
L=/usr/local/opt/llvm@19/bin
BIN=$1; SRC=$2; LIB=${3:-}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$T/cq.ll"
if [ -n "$LIB" ]; then
  "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$LIB" -o "$T/lib.ll"
  "$L/llvm-link" -S "$T/cq.ll" "$T/lib.ll" -o "$T/s1.ll"
else
  cp -f "$T/cq.ll" "$T/s1.ll"
fi
"$BIN" -load-pass-plugin "$W/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2> "$T/err"
if [ -s "$T/err" ]; then echo "STDERR:" >&2; cat "$T/err" >&2; fi
python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" >&2
"$L/clang" -c "$T/s2.ll" -o "$T/s2.o"
"$W/build/tests/e2e/cq_link.sh" -o "$T/slice" "$T/s2.o" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a"
"$T/slice"
