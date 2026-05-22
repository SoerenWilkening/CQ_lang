#!/usr/bin/env bash
# Phase 5 smoke test: validate that auto-uncomputation works on stock LLVM.
#
# Pipeline: cq-lowering produces handles; cq-uncompute inserts cqrt_free
# at the post-dominating last use of each handle via stock PostDominatorTree.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOTYPE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROTOTYPE_DIR/build}"
PASS_SO="$BUILD_DIR/libcq_pass.so"
INPUT="$SCRIPT_DIR/input.ll"
OUTPUT="$SCRIPT_DIR/output_phase5.ll"

OPT="${OPT:-opt-19}"

if [[ ! -f "$PASS_SO" ]]; then
  echo "FAIL: pass plugin not built at $PASS_SO"
  exit 1
fi

echo "==> Running cq-lowering + cq-uncompute pipeline"
"$OPT" -load-pass-plugin "$PASS_SO" \
       -passes='cq-lowering,cq-uncompute' \
       -S "$INPUT" -o "$OUTPUT"

echo "==> Verifying output IR"
"$OPT" -passes=verify -disable-output "$OUTPUT"

echo "==> Checking uncomputation insertions"

# Each of the 3 handles produced by cq-lowering should have a cqrt_free emitted.
free_count=$(grep -c '^[[:space:]]*call void @cqrt_free' "$OUTPUT" || true)
if [[ "$free_count" -eq 3 ]]; then
  echo "  OK: 3 cqrt_free calls emitted (one per handle)"
else
  echo "  FAIL: expected 3 cqrt_free calls, found $free_count"
  exit 1
fi

# Each individual handle (%h, %h1, %h_sum or their renamed equivalents) appears
# at least once in a cqrt_free argument. We check via "every handle SSA value
# defined by a cqrt_alloc_* call appears in a cqrt_free arg".
python3 - "$OUTPUT" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
defs = re.findall(r'^\s*(%\S+)\s*=\s*call i32 @cqrt_alloc_(?:classical_i32|i32)', text, re.M)
frees = set(re.findall(r'call void @cqrt_free\(i32 (%\S+)\)', text))
missing = [d for d in defs if d not in frees]
if missing:
    print(f"  FAIL: handles without cqrt_free: {missing}")
    sys.exit(1)
print(f"  OK: all {len(defs)} handles have a corresponding cqrt_free")
PY

echo
echo "All Phase 5 checks passed."
echo "Output IR: $OUTPUT"
