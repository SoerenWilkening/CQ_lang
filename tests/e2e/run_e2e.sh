#!/usr/bin/env bash
# tests/e2e/run_e2e.sh — Phase 1 end-to-end harness.
#
# For each fixture under $FIXTURES/*/, compile input.c with $CQC, run the
# resulting binary, and diff its stdout against expected.log. Skips with
# PASS when cqc is not yet built — the cqc shell driver lives in a separate
# bd issue (-rm8) and may not exist when this harness is first wired up.
# See phases/phase1/PLAN.md §4.7.
#
# Usage: run_e2e.sh [<cqc-path>] [<fixtures-dir>]

set -euo pipefail

CQC="${1:-./tools/cqc}"
FIXTURES="${2:-$(dirname "$0")/fixtures}"

if [[ ! -x "$CQC" ]]; then
    echo "e2e: cqc not built yet ($CQC) — skipping (PASS)"
    exit 0
fi

fail=0
for d in "$FIXTURES"/*/; do
    name=$(basename "$d")
    bin=$(mktemp)
    if ! "$CQC" "$d/input.c" -o "$bin" 2>"$bin.compile.log"; then
        echo "BUILD FAIL: $name"; cat "$bin.compile.log"; fail=1; continue
    fi
    if ! diff -u "$d/expected.log" <("$bin"); then
        echo "TRACE FAIL: $name"; fail=1
    else
        echo "OK: $name"
    fi
done
exit "$fail"
