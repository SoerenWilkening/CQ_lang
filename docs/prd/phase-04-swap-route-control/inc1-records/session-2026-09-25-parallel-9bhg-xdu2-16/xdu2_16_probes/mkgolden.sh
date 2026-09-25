#!/bin/bash
# mkgolden.sh NAME [OPT] — build tests/e2e/NAME.c through stages 1..4, STRICT 2b,
# write the trace to tests/e2e/NAME.expected.log. Fails loudly at any stage.
set -euo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin
OPT=${2:-$W/build/ir-pass/cq-opt}
N=$1
T=$(mktemp -d)
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/$N.c" -o "$T/s1.ll"
"$OPT" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll"
python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" | tail -1
"$L/clang" "$T/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$T/slice" 2>/dev/null
"$T/slice" > "$W/tests/e2e/$N.expected.log"
echo "$N: $(wc -l < "$W/tests/e2e/$N.expected.log") trace lines, $(grep -c . "$T/s2.ll") lowered lines"
rm -rf "$T"
