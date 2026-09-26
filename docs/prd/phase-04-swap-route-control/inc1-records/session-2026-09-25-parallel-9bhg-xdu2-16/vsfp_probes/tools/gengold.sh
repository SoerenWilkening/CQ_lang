#!/bin/bash
# gengold.sh BIN CQSRC GOLDEN_OUT [LIBSRC...] : the run_slice(_multi).sh stages, trace -> GOLDEN_OUT
set -euo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
BIN=$1; CQSRC=$2; OUTG=$3; shift 3
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$CQSRC" -o "$TMP/cq.ll"
linkin=("$TMP/cq.ll"); i=0
for lib in "$@"; do
  "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$lib" -o "$TMP/lib_$i.ll"
  linkin+=("$TMP/lib_$i.ll"); i=$((i + 1))
done
if [ "$i" -gt 0 ]; then "$L/llvm-link" -S "${linkin[@]}" -o "$TMP/combined.ll"; else cp "$TMP/cq.ll" "$TMP/combined.ll"; fi
"$BIN" -passes=cq-lowering -S "$TMP/combined.ll" -o "$TMP/s2.ll"
python3 "$W/tools/free_pairing_check.py" "$TMP/s2.ll"
"$L/clang" "$TMP/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$TMP/slice" 2>/dev/null
"$TMP/slice" > "$OUTG"
echo "wrote $OUTG ($(wc -l < "$OUTG") lines)"
