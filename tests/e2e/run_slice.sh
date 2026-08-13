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
# |0>" — no trace label can say whether a rail was ACTUALLY |0> at the free, at
# any ABI. (bd 8txa did close the compare flag-strip half: the strip moved off
# the fresh-minting `_inv`, which named no rail, onto the void out-first
# `cq_template_..._unc(rail, operands...)`, so a strip now names the rail the
# next line frees. Stage 2b still owns the whole-DAG spine's data `_unc` chains
# and the loop reverse-play write history.) Stage 2b reads the rail identities
# the trace cannot speak for. The two gates are complementary — the trace sees
# the angles, stage 2b sees the rails — so BOTH run, and neither is redundant.
set -euo pipefail
CLANG=$1 OPT=$2 PASS=$3 INC=$4 SRC=$5 RT=$6 TPL=$7 GOLDEN=$8
FREECHECK_FLAGS=${9:-}
PY=${CQ_PYTHON:-python3}
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
# Stage 1 — frontend. CONTENT-ADDRESSED CACHE (bd dgn5 follow-on): stage 1 is a
# pure function of (this clang, its flags, the .c source, the headers in $INC)
# and is INDEPENDENT OF THE PASS PLUGIN — which is the thing that actually
# changes between runs. So the plugin can be rebuilt all day and stage 1 is
# still a hit. MEASURED 0.428s of CPU per slice, ~104s across the layer.
# The key hashes the clang IDENTITY AND ITS BINARY, every header in $INC, the
# source, and the literal flag string; a miss is a normal compile that then
# populates the cache. A stale hit would need a SHA-256 collision, not a
# timestamp accident. Cache lives under the build dir, so `rm -rf build` is a
# full reset; CQ_S1CACHE unset (by-hand invocation) disables it entirely.
# $CQ_S1_BASE is the toolchain half of the key (clang bytes + version + every
# header in $INC + the flag string), computed ONCE by CMake via
# tools/s1_cache_key.py -- hashing the compiler 220 times would cost more than
# it saves. Here we add only the source bytes: one `openssl dgst` over one small
# .c, MEASURED 0.006s CPU against the 0.428s of stage 1 it replaces.
s1="$TMP/s1.ll"
if [ -n "${CQ_S1CACHE:-}" ] && [ -n "${CQ_S1_BASE:-}" ]; then
    # The PATH is keyed as well as the content: clang bakes the source path into
    # `ModuleID`/`source_filename`, so two byte-identical slices at different
    # paths do NOT produce byte-identical IR and must not share an entry.
    key=$({ printf '%s\0%s\0' "$CQ_S1_BASE" "$SRC"; cat "$SRC"; } \
          | /usr/bin/openssl dgst -sha256 | awk '{print $NF}')
    hit="$CQ_S1CACHE/$key.ll"
    if [ -f "$hit" ]; then
        s1="$hit"
    else
        "$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$TMP/s1.ll"
        mkdir -p "$CQ_S1CACHE"
        # Atomic publish. Under -j many slices populate this dir at once, and a
        # sibling must never observe a half-written .ll -- rename(2) within one
        # filesystem is atomic, a plain `cp` into place is not. $$ keeps two
        # concurrent misses on the SAME key from sharing a temp name.
        cp -f "$TMP/s1.ll" "$hit.$$.tmp" && mv -f "$hit.$$.tmp" "$hit"
    fi
else
    "$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$TMP/s1.ll"
fi
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$s1" -o "$TMP/s2.ll"          # Stage 2
# shellcheck disable=SC2086  # $FREECHECK_FLAGS is an intentional word-split
"$PY" "$HERE/../../tools/free_pairing_check.py" -q $FREECHECK_FLAGS "$TMP/s2.ll"       # Stage 2b
# Stage 3 (link) — deliberately NO -O flag (clang default -O0): the lowered IR
# is the verified artifact; an optimized stage 3 could const-fold/reorder the
# classical remainder (e.g. the volatile-const-fold literals) and desynchronize
# the trace from the golden. Do not add -O here (bd szpr pin).
#
# $CQ_LD (bd dgn5) is a linker wrapper CMake DERIVED from this same clang via
# `clang -###`, minus the `-lto_library` that makes ld dlopen libLTO->libLLVM
# (140MB) on every slice for an -O0 link that never uses LTO. Splitting codegen
# from the link MEASURED 0.74-0.94s -> 0.35-0.44s per slice. Unset (by-hand
# invocation, or a platform CMake could not derive a line for) -> the original
# single driver command, which is exactly equivalent and only slower.
if [ -n "${CQ_LD:-}" ] && [ -x "${CQ_LD}" ]; then
    "$CLANG" -c "$TMP/s2.ll" -o "$TMP/s2.o"
    "$CQ_LD" -o "$TMP/slice" "$TMP/s2.o" "$TPL" "$RT"
else
    "$CLANG" "$TMP/s2.ll" "$TPL" "$RT" -o "$TMP/slice"
fi
"$TMP/slice" | diff -u - "$GOLDEN"                                                     # Stage 4 (run + diff)
