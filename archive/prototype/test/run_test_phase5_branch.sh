#!/usr/bin/env bash
# Phase 5 multi-BB smoke test: validates PostDominatorTree-based last-use
# computation on non-trivial control flow.
#
# Input has a handle used in both arms of an if; cqrt_free should be emitted
# exactly once, in the merge block (post-dominator of the arms), not
# duplicated into either arm.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOTYPE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROTOTYPE_DIR/build}"
PASS_SO="$BUILD_DIR/libcq_pass.so"
INPUT="$SCRIPT_DIR/input_phase5_branch.ll"
OUTPUT="$SCRIPT_DIR/output_phase5_branch.ll"

OPT="${OPT:-opt-19}"

if [[ ! -f "$PASS_SO" ]]; then
  echo "FAIL: pass plugin not built at $PASS_SO"
  exit 1
fi

echo "==> Running cq-lowering + cq-uncompute on branched input"
"$OPT" -load-pass-plugin "$PASS_SO" \
       -passes='cq-lowering,cq-uncompute' \
       -S "$INPUT" -o "$OUTPUT"

echo "==> Verifying output IR"
"$OPT" -passes=verify -disable-output "$OUTPUT"

echo "==> Checking cqrt_free placement (must be in merge, not in arms)"

python3 - "$OUTPUT" <<'PY'
import re, sys

text = open(sys.argv[1]).read()

# Slice out each labeled block in @example_branch.
fn = re.search(r'define i64 @example_branch.*?^\}', text, re.M | re.S)
if not fn:
    print("  FAIL: could not locate @example_branch body")
    sys.exit(1)
body = fn.group(0)

# Match each labeled basic block. The label line may have a trailing
# "; preds = %..." comment that LLVM adds; consume to end of line.
blocks = {}
for m in re.finditer(r'^(\w+):[^\n]*\n((?:(?!^\w+:[^\n]*\n).)*)', body, re.M | re.S):
    blocks[m.group(1)] = m.group(2)

for name in ('entry', 'then', 'else', 'merge'):
    if name not in blocks:
        print(f"  FAIL: block {name!r} missing from output")
        sys.exit(1)

free_calls = re.findall(r'call void @cqrt_free', body)
if len(free_calls) != 1:
    print(f"  FAIL: expected exactly 1 cqrt_free, found {len(free_calls)}")
    sys.exit(1)
print(f"  OK: exactly 1 cqrt_free emitted (no duplication into arms)")

if 'cqrt_free' not in blocks['merge']:
    print("  FAIL: cqrt_free not in merge block")
    sys.exit(1)
print("  OK: cqrt_free placed in merge block (post-dominator)")

for arm in ('then', 'else'):
    if 'cqrt_free' in blocks[arm]:
        print(f"  FAIL: cqrt_free found in {arm} block (should only be in merge)")
        sys.exit(1)
print("  OK: cqrt_free not in then/else (arms unmodified)")
PY

echo
echo "All Phase 5 multi-BB checks passed."
echo "Output IR: $OUTPUT"
