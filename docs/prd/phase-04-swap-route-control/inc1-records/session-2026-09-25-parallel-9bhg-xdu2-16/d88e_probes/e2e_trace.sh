#!/bin/bash
# e2e_trace.sh OPTBIN OUTDIR CQSRC [LIBSRC] : the run_slice_multi.sh pipeline by hand,
# printing stage-2b's verdict and writing OUTDIR/trace.log.
set -euo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
L=/usr/local/opt/llvm@19/bin
OPTB="$1"; OUT="$2"; CQ="$3"; LIB="${4:-}"
mkdir -p "$OUT"
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$CQ" -o "$OUT/cq.ll"
ins=("$OUT/cq.ll")
if [ -n "$LIB" ]; then
  "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$LIB" -o "$OUT/lib.ll"
  ins+=("$OUT/lib.ll")
fi
"$L/llvm-link" -S "${ins[@]}" -o "$OUT/combined.ll"
"$OPTB" -passes=cq-lowering -S "$OUT/combined.ll" -o "$OUT/s2.ll"
python3 "$W/tools/free_pairing_check.py" "$OUT/s2.ll"
"$L/clang" "$OUT/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$OUT/slice" 2>/dev/null
"$OUT/slice" > "$OUT/trace.log"
cat "$OUT/trace.log"
