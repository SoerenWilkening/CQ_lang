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
#
# Stage 3b (bd 8txa) mirrors run_slice.sh: the Rule-6 free-pairing check over
# the same lowered IR this slice links and traces, because the golden cannot
# witness "freed at |0>" — no label can say a rail was ACTUALLY |0> at the free,
# at any ABI. See run_slice.sh for the full rationale, including what bd 8txa's
# compare-flag-strip fix did and did not close.
set -euo pipefail
CLANG=$1 OPT=$2 LLVMLINK=$3 PASS=$4 INC=$5 CQSRC=$6 LIBSRCS=$7 RT=$8 TPL=$9 GOLDEN=${10}
FREECHECK_FLAGS=${11:-}
PY=${CQ_PYTHON:-python3}
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Stage 1 per TU, through the SAME content-addressed helper run_slice.sh uses
# (`cq_s1_compile`, tests/e2e/stage_cache.sh; bd test_C_libtooling-2dfk, re-keyed
# by bd test_C_libtooling-ffm0). Each TU's key carries the LITERAL flag array it
# is compiled with — the CQ TU's `CQ_FLAGS`, the lib TUs' `LIB_FLAGS` (no
# `-include CQ.h`, C18) — never a tag standing in for them: the first version
# keyed the lib TUs by a constant tag, so adding `-include CQ.h` to the lib line
# (the C18 tripwire below) passed WARM in 31 of the 33 entries it breaks.
# shellcheck source=stage_cache.sh
. "$HERE/stage_cache.sh"
cq_cache_init
# Absolute `-include` (bd dbjh, r2 F-r2-4): a relative one is resolved from the
# working directory first, and the working directory is in no key.
CQ_FLAGS=(-I"$INC" -include "$INC/CQ.h" -O1 -emit-llvm -S)
LIB_FLAGS=(-I"$INC" -O1 -emit-llvm -S)

# Stage 1a — the CQ TU: -include CQ.h, -O1 (never -O0/-O2/-O3).
cq_s1_compile "$TMP/cq.ll" "$CQSRC" "${CQ_FLAGS[@]}"

# Stage 1b — classical libs: NO -include CQ.h, -O1. $LIBSRCS is a single
# space-separated string, word-split here; empty means zero lib modules. `set -f`
# brackets the split so $LIBSRCS is word-split but NOT pathname-glob-expanded (a
# lib path containing * ? [ would otherwise glob against cwd); restored after.
linkin=("$TMP/cq.ll")
i=0
set -f
for lib in $LIBSRCS; do
    set +f
    cq_s1_compile "$TMP/lib_$i.ll" "$lib" "${LIB_FLAGS[@]}"
    linkin+=("$TMP/lib_$i.ll")
    i=$((i + 1))
    set -f
done
set +f

# Stage 2 — llvm-link the per-TU IR into one module the specializer sees across.
"$LLVMLINK" -S "${linkin[@]}" -o "$TMP/combined.ll"

# Stage 3 — the single cq-lowering pass over the combined module.
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$TMP/combined.ll" -o "$TMP/s2.ll"

# Stages 3b / 4 / 5 — the Rule-6 free-pairing check (bd 8txa), the link
# (templates BEFORE runtime, load-bearing, C18; deliberately -O0, bd szpr) and
# the run + golden byte-diff, through the SAME content-addressed helper
# run_slice.sh uses (bd test_C_libtooling-2dfk; see that file and
# tools/cq_stage_cache.py). The pass above and the diff always run.
FPC="$HERE/../../tools/free_pairing_check.py"
cq_cache_keys "$FPC" "$FREECHECK_FLAGS"
cq_stage_2b "$FPC" "$FREECHECK_FLAGS"                    # Stage 3b
cq_stage_34_diff "$CLANG" "$GOLDEN"                      # Stages 4, 5
