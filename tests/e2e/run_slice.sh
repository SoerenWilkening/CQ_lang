#!/usr/bin/env bash
# run_slice.sh — Phase 2 end-to-end vertical slice (PRD §2.11 layer 2, §3.10).
# The 4-stage pipeline: clang -O1 -emit-llvm | opt cq-lowering | clang link |
# run, then byte-diff the runtime trace against the golden.
#
# Link order is templates THEN runtime: cq_template_add_i32_hl (in
# libcq_templates) calls cqrt_alloc_handle (in libcq_runtime), so templates
# must precede runtime for single-pass GNU ld.
set -euo pipefail
CLANG=$1 OPT=$2 PASS=$3 INC=$4 SRC=$5 RT=$6 TPL=$7 GOLDEN=$8
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
"$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$TMP/s1.ll"                # Stage 1
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$TMP/s1.ll" -o "$TMP/s2.ll"   # Stage 2
# Stage 3 (link) — deliberately NO -O flag (clang default -O0): the lowered IR
# is the verified artifact; an optimized stage 3 could const-fold/reorder the
# classical remainder (e.g. the volatile-const-fold literals) and desynchronize
# the trace from the golden. Do not add -O here (bd szpr pin).
"$CLANG" "$TMP/s2.ll" "$TPL" "$RT" -o "$TMP/slice"
"$TMP/slice" | diff -u - "$GOLDEN"                                                     # Stage 4 (run + diff)
