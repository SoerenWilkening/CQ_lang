#!/usr/bin/env bash
# End-to-end runner: for every fixture under fixtures/, run the
# transpiler against input.c and diff the captured stdout against
# expected.c. Exit non-zero if any fixture diff fails.
#
# Usage:
#   run_e2e.sh [TRANSPILER_BIN] [FIXTURES_DIR]
#
# Default TRANSPILER_BIN: ./quantum_transpiler (relative to ctest's cwd).
# Default FIXTURES_DIR:   <script-dir>/fixtures.
#
# We pass `-std=c11` after the `--` so libtooling sees the input as
# C11; the input file itself `#define`s `quantum` so the AnnotateAttr
# is visible without any extra `-D` flags.
set -euo pipefail

TRANSPILER="${1:-./quantum_transpiler}"
FIXTURES_DIR="${2:-$(dirname "$0")/fixtures}"

fail_count=0
for dir in "$FIXTURES_DIR"/*/; do
    name="$(basename "$dir")"
    # The transpiler's output passes the input buffer through verbatim
    # except for the rewritten DeclStmt(s), so the trailing newline of
    # input.c survives into the output. expected.c also ends in a
    # newline, so we use `printf '%s\n'` to add one back: command
    # substitution `$(...)` strips trailing newlines, and printf
    # without the `\n` would leave a "No newline at end of file"
    # diff hit.
    if ! diff -u "$dir/expected.c" <(printf '%s\n' "$("$TRANSPILER" "$dir/input.c" -- -std=c11)"); then
        echo "FIXTURE FAIL: $name" >&2
        fail_count=$((fail_count + 1))
    else
        echo "FIXTURE OK:   $name"
    fi
done

if [ "$fail_count" -ne 0 ]; then
    echo "$fail_count fixture(s) failed" >&2
    exit 1
fi
