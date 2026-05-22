#!/usr/bin/env bash
# Phase 4 smoke test: validates that cq_when_* region handling works on
# stock LLVM. Inside the region, cqrt_template_add_i32 should be replaced
# with its _controlled variant (control handle prepended). Outside the
# region, the same template call should be left alone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOTYPE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROTOTYPE_DIR/build}"
PASS_SO="$BUILD_DIR/libcq_pass.so"
INPUT="$SCRIPT_DIR/input_phase4.ll"
OUTPUT="$SCRIPT_DIR/output_phase4.ll"

OPT="${OPT:-opt-19}"

if [[ ! -f "$PASS_SO" ]]; then
  echo "FAIL: pass plugin not built at $PASS_SO"
  exit 1
fi

echo "==> Running cq-control pass"
"$OPT" -load-pass-plugin "$PASS_SO" \
       -passes='cq-control' \
       -S "$INPUT" -o "$OUTPUT"

echo "==> Verifying output IR"
"$OPT" -passes=verify -disable-output "$OUTPUT"

echo "==> Checking region handling"

check_present() {
  if grep -q "$1" "$OUTPUT"; then echo "  OK: present: $1"
  else echo "  FAIL: missing: $1"; exit 1; fi
}
check_absent() {
  if grep -q "$1" "$OUTPUT"; then echo "  FAIL: unexpected: $1"; exit 1
  else echo "  OK: absent:  $1"; fi
}

# 1. Inside-region call substituted with _controlled variant.
check_present "call void @cqrt_template_add_i32_controlled(i32 %h_cond, i32 %h_a, i32 %h_b, i32 %h_sum)"

# 2. Outside-region call preserved unmodified.
check_present "call void @cqrt_template_add_i32(i32 %h_a, i32 %h_b, i32 %h_pre)"

# 3. Bracket calls erased.
check_absent  "@cq_when_begin"
check_absent  "@cq_when_end"

# 4. Exactly one controlled call site (counted at call-sites only, not the
#    function declaration line).
n_controlled=$(grep -c "^[[:space:]]*call void @cqrt_template_add_i32_controlled" "$OUTPUT" || true)
if [[ "$n_controlled" -eq 1 ]]; then
  echo "  OK: exactly 1 controlled call site emitted"
else
  echo "  FAIL: expected 1 controlled call site, found $n_controlled"
  exit 1
fi

# 5. Original non-controlled template call still appears exactly once
#    (the outside-region one — also counted at call sites only).
n_plain_calls=$(grep -c "^[[:space:]]*call void @cqrt_template_add_i32(" "$OUTPUT" || true)
if [[ "$n_plain_calls" -eq 1 ]]; then
  echo "  OK: exactly 1 non-controlled cqrt_template_add_i32 call site remains"
else
  echo "  FAIL: expected 1 non-controlled call site, found $n_plain_calls"
  exit 1
fi

echo
echo "All Phase 4 checks passed."
echo "Output IR: $OUTPUT"
