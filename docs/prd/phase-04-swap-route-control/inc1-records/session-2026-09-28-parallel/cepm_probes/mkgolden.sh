#!/bin/bash
# mkgolden.sh OPT CQSRC "LIBSRC..." OUT : the run_slice_multi.sh stages (CQ TU with
# -include CQ.h, libs plain, llvm-link, cq-lowering with OPT, stage 2b STRICT, link at
# -O0, run with NO arguments) writing the trace to OUT. Prints the 2b line.
set -euo pipefail
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
OPT=$1 CQSRC=$2 LIBSRCS=$3 OUT=$4
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$CQSRC" -o "$TMP/cq.ll"
parts=("$TMP/cq.ll"); i=0
for lib in $LIBSRCS; do
  "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$lib" -o "$TMP/lib_$i.ll"
  parts+=("$TMP/lib_$i.ll"); i=$((i+1))
done
"$L/llvm-link" -S "${parts[@]}" -o "$TMP/combined.ll"
"$OPT" -passes=cq-lowering -S "$TMP/combined.ll" -o "$TMP/s2.ll"
python3 "$W/tools/free_pairing_check.py" "$TMP/s2.ll" | tail -1
"$L/clang" "$TMP/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$TMP/slice" 2>/dev/null
"$TMP/slice" > "$OUT"
