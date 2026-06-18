#!/usr/bin/env bash
# run_slice_multi.sh — Phase 6 MULTI-FILE end-to-end vertical slice (DD-6, §7.1).
#
# Sidecar to run_slice.sh; run_slice.sh stays the untouched single-TU baseline
# for the existing goldens (C18). This is the multi-file pipeline that hands the
# call-graph specializer a VISIBLE, UN-INLINED callee body: each .c is compiled
# to IR independently at -O1 (so there is no cross-TU inlining before opt — the
# structural satisfaction of the opt-before-inlining constraint, Rule 9),
# llvm-link merges them into one module, then ONE cq-lowering pass runs over the
# combined module, links, runs, and byte-diffs the trace against the golden.
#
# Two C18 traps encoded structurally here:
#   * -include CQ.h is applied to the CQ translation unit ONLY ($CQSRC); the
#     classical libs are plain C and must NOT see the intrinsic surface (else
#     their stock arithmetic would taint-lower spuriously).
#   * Stage-4 link order is templates THEN runtime: cq_template_*_hl bodies call
#     cqrt_*, so $TPL must precede $RT for single-pass GNU ld.
# Empty $LIBSRCS is valid and exercised by the zero-lib fixture: llvm-link of
# just cq.ll (an identity on the trace), proving the harness itself before the
# specializer's real 2-file golden lands.
set -euo pipefail
CLANG=$1 OPT=$2 LLVMLINK=$3 PASS=$4 INC=$5 CQSRC=$6 LIBSRCS=$7 RT=$8 TPL=$9 GOLDEN=${10}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Stage 1a — the CQ TU: -include CQ.h, -O1 (never -O0/-O2/-O3).
"$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$CQSRC" -o "$TMP/cq.ll"

# Stage 1b — classical libs: NO -include CQ.h, -O1. $LIBSRCS is a single
# space-separated string, word-split here; empty means zero lib modules. `set -f`
# brackets the split so $LIBSRCS is word-split but NOT pathname-glob-expanded (a
# lib path containing * ? [ would otherwise glob against cwd); restored after.
linkin=("$TMP/cq.ll")
i=0
set -f
for lib in $LIBSRCS; do
    set +f
    "$CLANG" -I"$INC" -O1 -emit-llvm -S "$lib" -o "$TMP/lib_$i.ll"
    linkin+=("$TMP/lib_$i.ll")
    i=$((i + 1))
    set -f
done
set +f

# Stage 2 — llvm-link the per-TU IR into one module the specializer sees across.
"$LLVMLINK" -S "${linkin[@]}" -o "$TMP/combined.ll"

# Stage 3 — the single cq-lowering pass over the combined module.
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$TMP/combined.ll" -o "$TMP/s2.ll"

# Stage 4 — link: templates BEFORE runtime (load-bearing, C18).
"$CLANG" "$TMP/s2.ll" "$TPL" "$RT" -o "$TMP/slice"

# Stage 5 — run + byte-diff the trace against the golden.
"$TMP/slice" | diff -u - "$GOLDEN"
