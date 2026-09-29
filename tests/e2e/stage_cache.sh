# tests/e2e/stage_cache.sh — sourced by run_slice.sh and run_slice_multi.sh.
#
# The bash spelling of tools/cq_stage_cache.py (bd test_C_libtooling-2dfk; read
# that file's docstring for WHY caching these stages is not a weaker test). In
# one sentence: stages 2b (free_pairing_check), 3 (link) and 4 (run) are PURE
# functions of the lowered module and the toolchain, so their result is keyed on
# exactly those bytes and replayed on a hit; stage 2 — the pass under test —
# runs every time, and the trace-vs-golden diff runs every time.
#
# Contract with the sourcing runner: it has set TMP, PY, TPL, RT and (optionally)
# CQ_LD, and $TMP/s2.ll is the lowered module. After `cq_cache_keys`:
#   CQ_PB2_KEY  non-empty => stage-2b cache usable     (marker $CQ_RUNCACHE/2b/<key>.ok)
#   CQ_RUN_KEY  non-empty => stage-3/4 cache usable    (trace  $CQ_RUNCACHE/run/<key>.out)
# Both stay EMPTY (=> every stage runs, exactly as before) unless the cache is
# configured (CQ_RUNCACHE + CQ_RUN_BASE, exported by tests/e2e/CMakeLists.txt),
# not disabled (CQ_E2E_NO_CACHE), and the split link (CQ_LD) is in use.
#
# ⚠ THE KEY TEXT IS SHARED WITH tools/cq_stage_cache.py::run_manifest — the two
# spellings must stay byte-identical (tools/cq_stage_cache_test.py checks it).

CQ_PB2_KEY=""
CQ_RUN_KEY=""

_cq_sha() { /usr/bin/openssl dgst -sha256 | awk '{print $NF}'; }

# Atomic publish: copy to a sibling temp name, then rename(2) into place, so a
# concurrent reader never observes half an entry. $$ keeps two concurrent
# misses on the same key from sharing a temp name.
_cq_publish() {  # <src-file> <final-path>
    mkdir -p "$(dirname "$2")"
    cp -f "$1" "$2.$$.tmp" && mv -f "$2.$$.tmp" "$2"
}

cq_cache_keys() {  # <freecheck-script> <freecheck-flags>
    [ -z "${CQ_E2E_NO_CACHE:-}" ] || return 0
    [ -n "${CQ_RUNCACHE:-}" ] && [ -n "${CQ_RUN_BASE:-}" ] || return 0
    [ -n "${CQ_LD:-}" ] && [ -x "${CQ_LD}" ] || return 0
    local first s2d fpd tpld rtd ldd
    # The lowered module MINUS its leading `; ModuleID = '<temp path>'` comment:
    # the only line that names this run's mktemp dir (see cq_stage_cache.py).
    IFS= read -r first < "$TMP/s2.ll" || true
    case "$first" in
        "; ModuleID = "*) s2d=$(tail -n +2 "$TMP/s2.ll" | _cq_sha) ;;
        *)                s2d=$(_cq_sha < "$TMP/s2.ll") ;;
    esac
    fpd=$(_cq_sha < "$1")
    tpld=$(_cq_sha < "$TPL")
    rtd=$(_cq_sha < "$RT")
    ldd=$(_cq_sha < "$CQ_LD")
    [ ${#s2d} -eq 64 ] && [ ${#fpd} -eq 64 ] && [ ${#tpld} -eq 64 ] \
        && [ ${#rtd} -eq 64 ] && [ ${#ldd} -eq 64 ] || {
        echo "stage_cache: a digest failed; running uncached" >&2; return 0; }
    CQ_RUN_KEY=$(printf 'cq-run-v1\n%s\n%s\n%s\n%s\n%s\n' \
                 "$CQ_RUN_BASE" "$s2d" "$tpld" "$rtd" "$ldd" | _cq_sha)
    CQ_PB2_KEY=$(printf 'cq-2b-v1\n%s\n%s\n%s\n%s\n' \
                 "$s2d" "$fpd" "$2" "$PY" | _cq_sha)
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
# is the one a previous run of this exact module against these exact archives
# and toolchain printed; only a run that exited 0 is ever recorded.
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
        "$1" -c "$TMP/s2.ll" -o "$TMP/s2.o"
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
