#!/usr/bin/env bash
# run_slice.sh — Phase 2 end-to-end vertical slice (PRD §2.11 layer 2, §3.10).
# The 4-stage pipeline: clang -O1 -emit-llvm | opt cq-lowering | clang link |
# run, then byte-diff the runtime trace against the golden.
#
# Link order is templates THEN runtime: cq_template_add_i32_hl (in
# libcq_templates) calls cqrt_alloc_handle (in libcq_runtime), so templates
# must precede runtime for single-pass GNU ld.
#
# Stage 2b (bd 8txa) is the Rule-6 free-pairing check over the SAME lowered IR
# this slice links and traces. The golden byte-diff cannot witness "freed at
# |0>": a generated `cq_template_..._inv` prints its forward operands and a
# fresh return handle but NEVER the rail it restores, so a golden stays stable
# across a reversal re-paired to the wrong rail or a free whose uncompute never
# ran. Stage 2b reads the rail identities the trace has lost. The two gates are
# complementary — the trace sees the angles and not the rails, stage 2b sees the
# rails and not the angles — so BOTH run, and neither is redundant.
set -euo pipefail
CLANG=$1 OPT=$2 PASS=$3 INC=$4 SRC=$5 RT=$6 TPL=$7 GOLDEN=$8
FREECHECK_FLAGS=${9:-}
PY=${CQ_PYTHON:-python3}
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
"$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$TMP/s1.ll"                # Stage 1
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$TMP/s1.ll" -o "$TMP/s2.ll"   # Stage 2
# shellcheck disable=SC2086  # $FREECHECK_FLAGS is an intentional word-split
"$PY" "$HERE/../../tools/free_pairing_check.py" -q $FREECHECK_FLAGS "$TMP/s2.ll"       # Stage 2b
# Stage 3 (link) — deliberately NO -O flag (clang default -O0): the lowered IR
# is the verified artifact; an optimized stage 3 could const-fold/reorder the
# classical remainder (e.g. the volatile-const-fold literals) and desynchronize
# the trace from the golden. Do not add -O here (bd szpr pin).
"$CLANG" "$TMP/s2.ll" "$TPL" "$RT" -o "$TMP/slice"
"$TMP/slice" | diff -u - "$GOLDEN"                                                     # Stage 4 (run + diff)
