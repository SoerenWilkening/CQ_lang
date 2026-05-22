#!/usr/bin/env bash
# Smoke test for the cq-lowering pass plugin.
#
# Runs opt-19 with the pass plugin against test/input.ll, verifies the output,
# and greps for the expected substitutions / absence of pre-lowering constructs.
#
# Exit 0 on success, non-zero on any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOTYPE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROTOTYPE_DIR/build}"
PASS_SO="$BUILD_DIR/libcq_pass.so"
INPUT="$SCRIPT_DIR/input.ll"
OUTPUT="$SCRIPT_DIR/output.ll"

OPT="${OPT:-opt-19}"

if [[ ! -f "$PASS_SO" ]]; then
  echo "FAIL: pass plugin not built at $PASS_SO"
  echo "Hint: cmake -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm -B $BUILD_DIR $PROTOTYPE_DIR && cmake --build $BUILD_DIR"
  exit 1
fi

echo "==> Running pass plugin"
"$OPT" -load-pass-plugin "$PASS_SO" -passes=cq-lowering -S "$INPUT" -o "$OUTPUT"

echo "==> Verifying output IR"
"$OPT" -passes=verify -disable-output "$OUTPUT"

echo "==> Checking expected substitutions"

check_present() {
  if grep -q "$1" "$OUTPUT"; then
    echo "  OK: present: $1"
  else
    echo "  FAIL: missing: $1"
    exit 1
  fi
}

check_absent() {
  if grep -q "$1" "$OUTPUT"; then
    echo "  FAIL: unexpected: $1"
    exit 1
  else
    echo "  OK: absent:  $1"
  fi
}

check_present "call i32 @cqrt_alloc_classical_i32(i32 3)"
check_present "call i32 @cqrt_alloc_classical_i32(i32 5)"
check_present "call i32 @cqrt_alloc_i32()"
check_present "call void @cqrt_template_add_i32"
check_present "call i64 @cqrt_measure"

check_absent  "@cq_init_i32"
check_absent  "call i64 @cq_measure("
check_absent  "extractvalue"
check_absent  "insertvalue"
# The only `add` left should be incidental (none in this test).
check_absent  "add i32"

echo
echo "All checks passed."
echo "Output IR: $OUTPUT"
