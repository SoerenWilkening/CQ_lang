#!/usr/bin/env bash
# acceptance.sh — PRD criteria 2-4 in one script.
#
# 1. Transpiles example_v1.c and diffs the captured stdout against
#    example_v1.expected.c (criterion 2: patterns are rewritten
#    correctly).
# 2. Compiles the rewritten output with `cc -std=c11` so the rewritten
#    file's `#include "qint.h"` resolves and the stub backend's
#    static-inline definitions link in (criterion 3).
# 3. Runs the resulting binary and diffs its stdout against
#    example_v1.expected.log (criterion 4: the stub-debug lines come
#    out in the expected order).
#
# Usage:
#   acceptance.sh [TRANSPILER_BIN] [REPO_ROOT]
#
# Defaults:
#   TRANSPILER_BIN = ./quantum_transpiler  (relative to ctest's cwd)
#   REPO_ROOT      = the repo root computed from this script's location
set -euo pipefail

TRANSPILER="${1:-./quantum_transpiler}"
REPO_ROOT="${2:-$(cd "$(dirname "$0")/../../.." && pwd)}"

INPUT="$REPO_ROOT/example_v1.c"
EXPECTED_C="$REPO_ROOT/example_v1.expected.c"
EXPECTED_LOG="$REPO_ROOT/example_v1.expected.log"
QINT_H_DIR="$REPO_ROOT"     # qint.h lives at the repo root

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ACTUAL_C="$WORK/example_v1.actual.c"
ACTUAL_LOG="$WORK/example_v1.actual.log"
BIN="$WORK/example_v1.out"

# Criterion 2: transpile and diff against the golden rewrite.
# The transpiler's stdout preserves the input buffer's trailing
# newline verbatim, so writing it directly into a file matches the
# golden expected.c byte-for-byte (no `printf '%s\n'` shim needed).
"$TRANSPILER" "$INPUT" -- -std=c11 > "$ACTUAL_C"
diff -u "$EXPECTED_C" "$ACTUAL_C"

# Criterion 3: the rewritten output compiles with a plain C compiler.
# The rewritten file `#include "qint.h"`s the stub header itself, so
# we just need to point the compiler at the directory where qint.h
# lives.
cc -std=c11 -I "$QINT_H_DIR" "$ACTUAL_C" -o "$BIN"

# Criterion 4: running the binary prints the expected stub-debug lines.
"$BIN" > "$ACTUAL_LOG"
diff -u "$EXPECTED_LOG" "$ACTUAL_LOG"

echo "ACCEPTANCE OK"
