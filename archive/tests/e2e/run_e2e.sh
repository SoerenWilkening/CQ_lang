#!/usr/bin/env bash
# tests/e2e/run_e2e.sh — Phase 1 end-to-end harness.
#
# For each fixture under $FIXTURES/*/, compile input.c with $CQC, run the
# resulting binary, and diff its stdout against expected.log. Skips with
# PASS when cqc is not yet built — the cqc shell driver lives in a separate
# bd issue (-rm8) and may not exist when this harness is first wired up.
#
# Usage: run_e2e.sh [<cqc-path>] [<fixtures-dir>] [extra cqc args ...]
#
# Any args after the first two are forwarded verbatim to each cqc
# invocation. Used by tests/e2e/CMakeLists.txt to pass --opt= and
# --clang= pointing at the cmake-discovered LLVM tools so the harness
# doesn't depend on PATH ordering (matters on macOS where Homebrew's
# llvm@19 ships clang/opt without a -19 suffix).

set -euo pipefail

CQC="${1:-./tools/cqc}"
FIXTURES="${2:-$(dirname "$0")/fixtures}"
shift 2 || true
CQC_EXTRA_ARGS=("$@")

if [[ ! -x "$CQC" ]]; then
    echo "e2e: cqc not built yet ($CQC) — skipping (PASS)"
    exit 0
fi

fail=0
# Discover fixtures by their `input.c` so the directory layout can nest
# arbitrarily. Phase 2 M18 adds 14 per-type fixtures under
# `$FIXTURES/types/<sfx>/`, which the original single-level glob
# (`$FIXTURES/*/`) misses; `find` here walks both the legacy top-level
# fixtures and the new subtree without further changes. The `-print0 |
# sort -z` pair gives stable ordering across filesystems so flake-on-rerun
# can't hide here.
while IFS= read -r -d '' input_c; do
    d="$(dirname "$input_c")"
    # Use the path relative to $FIXTURES so nested fixtures get
    # distinguishable names (e.g. "types/si32" vs a hypothetical top-level
    # "si32"). Strips the FIXTURES prefix + leading slash; falls back to
    # basename if realpath happens to be absent.
    if name=$(realpath --relative-to="$FIXTURES" "$d" 2>/dev/null); then :; else
        name=$(basename "$d")
    fi
    bin=$(mktemp)
    if ! "$CQC" "$d/input.c" -o "$bin" "${CQC_EXTRA_ARGS[@]}" 2>"$bin.compile.log"; then
        echo "BUILD FAIL: $name"; cat "$bin.compile.log"; fail=1; continue
    fi
    if ! diff -u "$d/expected.log" <("$bin"); then
        echo "TRACE FAIL: $name"; fail=1
    else
        echo "OK: $name"
    fi
done < <(find "$FIXTURES" -mindepth 2 -type f -name input.c -print0 | sort -z)
exit "$fail"
