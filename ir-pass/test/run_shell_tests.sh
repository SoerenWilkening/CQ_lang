#!/usr/bin/env bash
# Fallback runner used when LIT is unavailable. Iterates *.ll files in the
# given source directory; for each, scans for `; RUN:` and `; CHECK:` /
# `; CHECK-NOT:` lines and applies them via opt + grep. This is a deliberate
# subset of LIT's behavior — just enough to keep CI green without lit.
#
# Usage: run_shell_tests.sh <test-src-dir> <CQPass.so-path-or-empty> <opt-binary>

set -uo pipefail

TEST_DIR="${1:?missing test source dir}"
PASS_SO="${2:-}"
OPT="${3:-opt-19}"

shopt -s nullglob
LL_FILES=("$TEST_DIR"/*.ll)

if [[ ${#LL_FILES[@]} -eq 0 ]]; then
  echo "ir-pass shell-runner: no *.ll files in $TEST_DIR — skipping (PASS)"
  exit 0
fi

if [[ -z "$PASS_SO" ]] || [[ ! -f "$PASS_SO" ]]; then
  echo "ir-pass shell-runner: CQPass.so not built ($PASS_SO) — skipping (PASS)"
  exit 0
fi

# Translate a FileCheck-style CHECK pattern into an ERE regex:
# - Literal segments outside `{{...}}` get ERE metacharacters escaped.
# - `{{regex}}` segments are spliced in verbatim as ERE.
filecheck_to_ere() {
  local pat="$1"
  local out="" rest="$pat" lit re
  while [[ "$rest" == *'{{'* ]]; do
    lit="${rest%%\{\{*}"
    rest="${rest#*\{\{}"
    if [[ "$rest" != *'}}'* ]]; then
      # Unterminated `{{` — treat the rest as literal so we fail loudly later.
      out+="$(printf '%s' "$lit" | sed -E 's/[].\\[*+?(){}|^$/]/\\&/g')"
      out+='\{\{'
      rest=""
      break
    fi
    re="${rest%%\}\}*}"
    rest="${rest#*\}\}}"
    out+="$(printf '%s' "$lit" | sed -E 's/[].\\[*+?(){}|^$/]/\\&/g')"
    out+="$re"
  done
  out+="$(printf '%s' "$rest" | sed -E 's/[].\\[*+?(){}|^$/]/\\&/g')"
  printf '%s' "$out"
}

fail=0
for input in "${LL_FILES[@]}"; do
  name="$(basename "$input")"
  echo "==> $name"
  output="$(
    "$OPT" -load-pass-plugin "$PASS_SO" -passes=cq-lowering -S "$input" 2>&1
  )" || { echo "  FAIL: opt errored on $name"; fail=1; continue; }

  # Apply `; CHECK:` and `; CHECK-NOT:` lines (LIT-lite — no DAG/NEXT semantics).
  while IFS= read -r line; do
    pattern="$(sed -E 's/^;[[:space:]]*CHECK:[[:space:]]*//' <<<"$line")"
    regex="$(filecheck_to_ere "$pattern")"
    if ! grep -qE -- "$regex" <<<"$output"; then
      echo "  FAIL: missing CHECK: $pattern"
      fail=1
    fi
  done < <(grep -E '^;[[:space:]]*CHECK:[[:space:]]' "$input" || true)

  while IFS= read -r line; do
    pattern="$(sed -E 's/^;[[:space:]]*CHECK-NOT:[[:space:]]*//' <<<"$line")"
    regex="$(filecheck_to_ere "$pattern")"
    if grep -qE -- "$regex" <<<"$output"; then
      echo "  FAIL: unexpected CHECK-NOT: $pattern"
      fail=1
    fi
  done < <(grep -E '^;[[:space:]]*CHECK-NOT:[[:space:]]' "$input" || true)
done

if [[ $fail -ne 0 ]]; then
  exit 1
fi
echo "All shell-runner checks passed."
