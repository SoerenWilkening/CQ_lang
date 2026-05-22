#!/usr/bin/env bash
# Phase 7 smoke test: validate that call-graph specialization works on stock LLVM.
#
# The cq-specialize pass identifies call sites with qint_mid_t-typed args,
# clones the callee via stock CloneFunction, renames it with __cq_q_<f>_q1
# mangling, and retargets the call site to the clone. Validates the
# function-cloning + call-site-retargeting mechanism.
#
# Scope: minimal — signature preserved (no handle ABI rewriting), no Bennett
# wrap-around. The point is to confirm the LLVM API surface works.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOTYPE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROTOTYPE_DIR/build}"
PASS_SO="$BUILD_DIR/libcq_pass.so"
INPUT="$SCRIPT_DIR/input_phase7.ll"
OUTPUT="$SCRIPT_DIR/output_phase7.ll"

OPT="${OPT:-opt-19}"

if [[ ! -f "$PASS_SO" ]]; then
  echo "FAIL: pass plugin not built at $PASS_SO"
  exit 1
fi

echo "==> Running cq-specialize pass"
"$OPT" -load-pass-plugin "$PASS_SO" \
       -passes='cq-specialize' \
       -S "$INPUT" -o "$OUTPUT"

echo "==> Verifying output IR"
"$OPT" -passes=verify -disable-output "$OUTPUT"

echo "==> Checking specialization"

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

# 1. The clone exists with the mangled name.
check_present 'define internal .* @__cq_q_double_it_q1'

# 2. The original function still exists (we don't delete it; DCE is downstream).
check_present 'define %qint_mid_t @double_it'

# 3. The call site in @example refers to the clone, not the original.
check_present 'call %qint_mid_t @__cq_q_double_it_q1'

# 4. There is no longer a call to the original @double_it from @example.
#    (Original @double_it itself still defines; only the call site is retargeted.)
n_orig_calls=$(grep -c 'call %qint_mid_t @double_it(' "$OUTPUT" || true)
if [[ "$n_orig_calls" -eq 0 ]]; then
  echo "  OK: zero remaining calls to original @double_it"
else
  echo "  FAIL: still $n_orig_calls call(s) to original @double_it"
  exit 1
fi

# 5. The clone's body has the same shape as the original (cloning fidelity).
#    Specifically: extractvalue, add, insertvalue, ret all present in the clone.
python3 - "$OUTPUT" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'define internal %qint_mid_t @__cq_q_double_it_q1.*?(?=\ndefine|\Z)', text, re.S)
if not m:
    print("  FAIL: could not isolate clone body")
    sys.exit(1)
body = m.group(0)
needed = ['extractvalue', 'add i32', 'insertvalue', 'ret %qint_mid_t']
missing = [t for t in needed if t not in body]
if missing:
    print(f"  FAIL: clone missing: {missing}")
    sys.exit(1)
print("  OK: clone body has expected shape (extractvalue + add + insertvalue + ret)")
PY

echo
echo "All Phase 7 checks passed."
echo "Output IR: $OUTPUT"
