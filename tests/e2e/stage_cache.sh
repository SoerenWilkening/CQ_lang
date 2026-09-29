# tests/e2e/stage_cache.sh — sourced by run_slice.sh and run_slice_multi.sh.
#
# The bash spelling of tools/cq_stage_cache.py (bd test_C_libtooling-2dfk; read
# that file's docstring for WHY caching these stages is not a weaker test). In
# one sentence: stages 1 (clang -O1), 2b (free_pairing_check), 3 (link) and 4
# (run) are PURE functions of their inputs AND OF THE COMMAND APPLIED TO THEM, so
# their result is keyed on exactly those bytes and replayed on a hit; stage 2 —
# the pass under test — runs every time, and the trace-vs-golden diff runs every
# time.
#
# ⚠ THE COMMAND IS PART OF EVERY KEY (bd test_C_libtooling-ffm0, Rule-13 r1
# F-r1-1, P1). The first version keyed each stage's INPUTS but not the command
# the harness ran on them, so an edit to a runner — `-include CQ.h` on a lib TU
# (the C18 tripwire), `-O2` on the stage-3 `clang -c` (the bd szpr pin) — was
# REPLAYED as the old pass on a warm cache: measured 31 multi-TU entries and 5
# slices that must fail, passing warm. Every key now carries:
#   CQ_HD    the HARNESS DIGEST: the bytes of run_slice.sh, run_slice_multi.sh,
#            this file and tools/cq_stage_cache.py — any edit to any of them
#            invalidates the whole cache (the conservative, correct behaviour);
#   the LITERAL flag arrays each stage runs with (stage 1 CQ TU / lib TU, stage 3
#            `clang -c`), NUL-separated and count-prefixed;
#   CQ_CLANG_ID  the bytes of the clang this runner was handed;
#   CQ_ENVD  the values of the environment variables that steer clang, ld,
#            dyld or python (CQ_KEY_ENV_VARS; unset and set-to-empty differ).
# free_pairing_check.py is keyed by its own bytes in the 2b key (the only stage
# whose result depends on it) and deliberately NOT in CQ_HD — a second copy of
# the same component would make a key that forgot the first one undetectable.
#
# Contract with the sourcing runner: it has set CLANG, HERE (this directory), PY,
# TMP, and — before cq_cache_keys — TPL, RT and (optionally) CQ_LD; $TMP/s2.ll is
# the lowered module. `cq_cache_init` runs once; everything is OFF (every stage
# runs, exactly as before the cache) unless the cache is configured (CQ_S1CACHE +
# CQ_S1_BASE for stage 1; CQ_RUNCACHE + CQ_RUN_BASE + CQ_LD for 2b/3/4, exported
# by tests/e2e/CMakeLists.txt) and not disabled (CQ_E2E_NO_CACHE).
#
# ⚠ THE KEY TEXTS ARE SHARED WITH tools/cq_stage_cache.py (run_manifest,
# harness_digest, env_digest) — the two spellings must stay byte-identical, and
# tools/cq_stage_cache_test.py checks that they are (row I).

CQ_HD=""
CQ_CLANG_ID=""
CQ_ENVD=""
CQ_PB2_KEY=""
CQ_RUN_KEY=""
# The ONE spelling of the stage-3 compile flags; the command below and the run
# key both read this array (bd szpr: deliberately NO -O — stage 3 is -O0).
CQ_S3_CC_FLAGS=(-c)
# Environment that can change what clang / ld / dyld / python do. SORTED, and
# identical to cq_stage_cache.py's KEY_ENV_VARS. ⚠ macOS SIP strips every DYLD_*
# variable before a protected binary such as /bin/bash starts (measured), so in
# THIS spelling they always read as unset — which is the truth for everything a
# bash runner launches; the python spelling sees them, and so do its programs.
CQ_KEY_ENV_VARS="CCC_OVERRIDE_OPTIONS COMPILER_PATH CPATH CPLUS_INCLUDE_PATH C_INCLUDE_PATH DEVELOPER_DIR DYLD_FALLBACK_LIBRARY_PATH DYLD_INSERT_LIBRARIES DYLD_LIBRARY_PATH LIBRARY_PATH MACOSX_DEPLOYMENT_TARGET OBJCPLUS_INCLUDE_PATH OBJC_INCLUDE_PATH PYTHONHOME PYTHONPATH SDKROOT SOURCE_DATE_EPOCH"

_cq_sha() { /usr/bin/openssl dgst -sha256 | awk '{print $NF}'; }

# Atomic publish: copy to a sibling temp name, then rename(2) into place, so a
# concurrent reader never observes half an entry. $$ keeps two concurrent
# misses on the same key from sharing a temp name. A SIGKILL between the two
# leaves a `<key>.<pid>.tmp` that nothing ever reads (measured 1 in 40 kills,
# 0 torn entries); there is no eviction — `rm -rf build/tests/e2e/.s1cache
# build/tests/e2e/.runcache` is the reset (tests/README.md).
_cq_publish() {  # <src-file> <final-path>
    mkdir -p "$(dirname "$2")"
    cp -f "$1" "$2.$$.tmp" && mv -f "$2.$$.tmp" "$2"
}

_cq_is_hex64() { case "$1" in ''|*[!0-9a-f]*) return 1 ;; esac; [ ${#1} -eq 64 ]; }

# Computes CQ_HD, CQ_CLANG_ID and CQ_ENVD. On ANY failure they stay empty and
# every cache is off for this run (loudly: one line on stderr).
cq_cache_init() {
    [ -z "${CQ_E2E_NO_CACHE:-}" ] || return 0
    [ -n "${CQ_S1CACHE:-}${CQ_RUNCACHE:-}" ] || return 0
    local d1 d2 d3 d4 v isset val
    d1=$(_cq_sha < "$HERE/run_slice.sh") || d1=""
    d2=$(_cq_sha < "$HERE/run_slice_multi.sh") || d2=""
    d3=$(_cq_sha < "$HERE/stage_cache.sh") || d3=""
    d4=$(_cq_sha < "$HERE/../../tools/cq_stage_cache.py") || d4=""
    CQ_CLANG_ID=$(_cq_sha < "$CLANG") || CQ_CLANG_ID=""
    if ! { _cq_is_hex64 "$d1" && _cq_is_hex64 "$d2" && _cq_is_hex64 "$d3" \
           && _cq_is_hex64 "$d4" && _cq_is_hex64 "$CQ_CLANG_ID"; }; then
        echo "stage_cache: a harness/clang digest failed; running uncached" >&2
        CQ_CLANG_ID=""
        return 0
    fi
    CQ_HD=$(printf 'cq-hd-v1\0run_slice.sh\0%s\0run_slice_multi.sh\0%s\0stage_cache.sh\0%s\0cq_stage_cache.py\0%s\0' \
            "$d1" "$d2" "$d3" "$d4" | _cq_sha)
    CQ_ENVD=$( { printf 'cq-env-v1\0'
                 for v in $CQ_KEY_ENV_VARS; do
                     eval "isset=\${$v+x}"
                     if [ -n "$isset" ]; then
                         eval "val=\${$v}"
                         printf '%s=%s\0' "$v" "$val"
                     fi
                 done; } | _cq_sha)
    _cq_is_hex64 "$CQ_HD" && _cq_is_hex64 "$CQ_ENVD" || {
        echo "stage_cache: key digest failed; running uncached" >&2
        CQ_HD=""; CQ_ENVD=""; CQ_CLANG_ID=""; }
}

# Stage 1, cached. `cq_s1_compile <out> <src> <clang flags...>` leaves the IR at
# <out> (a hit is COPIED there, so the consumer sees the same path either way).
# Key: CQ_HD, CQ_S1_BASE (clang bytes + version + headers + sysroot, configure
# time), CQ_CLANG_ID, CQ_ENVD, the literal flags (count-prefixed), the source
# PATH (clang bakes it into `source_filename`) and the source BYTES.
cq_s1_compile() {
    local out=$1 src=$2 key hit sd
    shift 2
    if [ -n "$CQ_HD" ] && [ -n "${CQ_S1CACHE:-}" ] && [ -n "${CQ_S1_BASE:-}" ]; then
        sd=$(_cq_sha < "$src")
        key=$( { printf 'cq-s1-v2\0%s\0%s\0%s\0%s\0flags\0%s\0' \
                   "$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"
                 printf '%s\0' "$@"
                 printf 'src\0%s\0%s\0' "$src" "$sd"; } | _cq_sha)
        if _cq_is_hex64 "$sd" && _cq_is_hex64 "$key"; then
            hit="$CQ_S1CACHE/$key.ll"
            if [ -f "$hit" ]; then
                cp -f "$hit" "$out"
                return 0
            fi
            "$CLANG" "$@" "$src" -o "$out"
            _cq_publish "$out" "$hit"
            return 0
        fi
    fi
    "$CLANG" "$@" "$src" -o "$out"
}

# The 2b and run keys, over the lowered module MINUS its leading
# `; ModuleID = '<temp path>'` comment (the only line that names this run's
# mktemp dir; see cq_stage_cache.py). A first line containing a CR is NOT
# stripped (LLVM ends a `;` comment at CR too, so text after it would be IR —
# bd ffm0 F-r1-3): such a module is hashed whole and simply never hits.
cq_cache_keys() {  # <freecheck-script> <freecheck-flags>
    [ -n "$CQ_HD" ] || return 0
    [ -n "${CQ_RUNCACHE:-}" ] && [ -n "${CQ_RUN_BASE:-}" ] || return 0
    [ -n "${CQ_LD:-}" ] && [ -x "${CQ_LD}" ] || return 0
    local first s2d fpd tpld rtd ldd
    IFS= read -r first < "$TMP/s2.ll" || true
    case "$first" in
        *$'\r'*)          s2d=$(_cq_sha < "$TMP/s2.ll") ;;
        "; ModuleID = "*) s2d=$(tail -n +2 "$TMP/s2.ll" | _cq_sha) ;;
        *)                s2d=$(_cq_sha < "$TMP/s2.ll") ;;
    esac
    fpd=$(_cq_sha < "$1")
    tpld=$(_cq_sha < "$TPL")
    rtd=$(_cq_sha < "$RT")
    ldd=$(_cq_sha < "$CQ_LD")
    _cq_is_hex64 "$s2d" && _cq_is_hex64 "$fpd" && _cq_is_hex64 "$tpld" \
        && _cq_is_hex64 "$rtd" && _cq_is_hex64 "$ldd" || {
        echo "stage_cache: a digest failed; running uncached" >&2; return 0; }
    CQ_RUN_KEY=$( { printf 'cq-run-v2\0%s\0%s\0%s\0s3cc\0%s\0' \
                      "$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"
                    printf '%s\0' "${CQ_S3_CC_FLAGS[@]}"
                    printf '%s\0%s\0%s\0%s\0%s\0argc\0%s\0' \
                      "$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0; } | _cq_sha)
    CQ_PB2_KEY=$(printf 'cq-2b-v2\0%s\0%s\0%s\0%s\0%s\0%s\0' \
                 "$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY" | _cq_sha)
}

# Stage 2b, cached. Runs the checker unless THIS module passed THIS checker with
# THESE flags before; a pass is recorded only when the checker exited 0 AND
# printed nothing (so an `--allow-unproven` run that reports findings is never
# replayed silently — it always re-runs and re-prints).
cq_stage_2b() {  # <freecheck-script> <freecheck-flags>
    if [ -n "$CQ_PB2_KEY" ] && [ -f "$CQ_RUNCACHE/2b/$CQ_PB2_KEY.ok" ]; then
        return 0
    fi
    local out rc
    set +e
    # shellcheck disable=SC2086  # $2 is an intentional word-split
    out=$("$PY" "$1" -q $2 "$TMP/s2.ll" 2>&1)
    rc=$?
    set -e
    [ -z "$out" ] || printf '%s\n' "$out"
    [ "$rc" -eq 0 ] || exit "$rc"
    if [ -n "$CQ_PB2_KEY" ] && [ -z "$out" ]; then
        : > "$TMP/2b.ok"
        _cq_publish "$TMP/2b.ok" "$CQ_RUNCACHE/2b/$CQ_PB2_KEY.ok"
    fi
}

# Stages 3 + 4, cached, then the golden diff (NEVER cached). On a hit the trace
# is the one a previous run of this exact module, with this exact harness,
# against these exact archives and toolchain printed; only a run that exited 0
# is ever recorded.
cq_stage_34_diff() {  # <clang> <golden>
    if [ -n "$CQ_RUN_KEY" ] && [ -f "$CQ_RUNCACHE/run/$CQ_RUN_KEY.out" ]; then
        diff -u - "$2" < "$CQ_RUNCACHE/run/$CQ_RUN_KEY.out"
        return 0
    fi
    # Stage 3 (link) — deliberately NO -O flag (clang default -O0): the lowered IR
    # is the verified artifact; an optimized stage 3 could const-fold/reorder the
    # classical remainder and desynchronize the trace from the golden (bd szpr).
    # $CQ_LD (bd dgn5) is the derived linker wrapper; unset -> the driver,
    # exactly equivalent, only slower (and then no cache key exists).
    if [ -n "${CQ_LD:-}" ] && [ -x "${CQ_LD}" ]; then
        "$1" "${CQ_S3_CC_FLAGS[@]}" "$TMP/s2.ll" -o "$TMP/s2.o"
        "$CQ_LD" -o "$TMP/slice" "$TMP/s2.o" "$TPL" "$RT"
    else
        "$1" "$TMP/s2.ll" "$TPL" "$RT" -o "$TMP/slice"
    fi
    # Stage 4 (run). The trace goes to a file rather than straight into diff so
    # that a clean run can be recorded; the exit status is kept and re-raised
    # after the diff, exactly as `slice | diff` under pipefail did.
    local rc
    set +e
    "$TMP/slice" > "$TMP/trace"
    rc=$?
    set -e
    if [ "$rc" -eq 0 ] && [ -n "$CQ_RUN_KEY" ]; then
        _cq_publish "$TMP/trace" "$CQ_RUNCACHE/run/$CQ_RUN_KEY.out"
    fi
    diff -u - "$2" < "$TMP/trace"
    [ "$rc" -eq 0 ] || exit "$rc"
}
