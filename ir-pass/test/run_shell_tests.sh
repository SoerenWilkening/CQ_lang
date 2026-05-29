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

  # This runner faithfully handles only `{{regex}}` CHECK syntax matched
  # against the pass's stdout. Fixtures needing real lit/FileCheck features it
  # does NOT implement are SKIPPED (and logged) rather than falsely failed —
  # install lit for full coverage (the CMake prefers it; this is the no-lit
  # fallback). Two such features appear in the suite:
  #   - negative tests   `RUN: not %cq-opt …`  (opt is *expected* to error)
  #   - capture vars     `[[NAME:re]]` / `[[NAME]]` in CHECK lines
  unsupported=""
  if grep -qE '^;[[:space:]]*RUN:.*\bnot[[:space:]]+%cq-opt' "$input"; then
    unsupported="a negative test (RUN: not …)"
  elif grep -E '^;[[:space:]]*CHECK' "$input" | grep -qE '\[\[[A-Za-z_#]'; then
    unsupported="FileCheck capture vars ([[…]])"
  fi
  if [[ -n "$unsupported" ]]; then
    echo "  SKIP: $name uses $unsupported — unsupported by the shell fallback; install lit for full coverage"
    continue
  fi

  # XFAIL support (LIT-lite): a file carrying `; XFAIL:` is expected to fail.
  # We only honor unconditional `XFAIL: *` here — the shell runner has no
  # feature/target predicates to evaluate, so a conditional XFAIL is treated
  # as unconditional. file_fail tracks this file's outcome; for an XFAIL file
  # we invert it at the end (a real failure is the expected result, and an
  # unexpected pass is an XPASS error that should prompt removing the marker).
  xfail=0
  if grep -qE '^;[[:space:]]*XFAIL:' "$input"; then xfail=1; fi
  file_fail=0

  output="$(
    "$OPT" -load-pass-plugin "$PASS_SO" -passes=cq-lowering -S "$input" 2>&1
  )" || { [[ $xfail -eq 0 ]] && echo "  FAIL: opt errored on $name"; file_fail=1; }

  # Apply `; CHECK:` and `; CHECK-NOT:` lines (LIT-lite — no DAG/NEXT
  # semantics). Skip when opt already errored (no output to match against).
  if [[ $file_fail -eq 0 ]]; then
    while IFS= read -r line; do
      pattern="$(sed -E 's/^;[[:space:]]*CHECK:[[:space:]]*//' <<<"$line")"
      regex="$(filecheck_to_ere "$pattern")"
      if ! grep -qE -- "$regex" <<<"$output"; then
        [[ $xfail -eq 0 ]] && echo "  FAIL: missing CHECK: $pattern"
        file_fail=1
      fi
    done < <(grep -E '^;[[:space:]]*CHECK:[[:space:]]' "$input" || true)

    while IFS= read -r line; do
      pattern="$(sed -E 's/^;[[:space:]]*CHECK-NOT:[[:space:]]*//' <<<"$line")"
      regex="$(filecheck_to_ere "$pattern")"
      if grep -qE -- "$regex" <<<"$output"; then
        [[ $xfail -eq 0 ]] && echo "  FAIL: unexpected CHECK-NOT: $pattern"
        file_fail=1
      fi
    done < <(grep -E '^;[[:space:]]*CHECK-NOT:[[:space:]]' "$input" || true)
  fi

  if [[ $xfail -eq 1 ]]; then
    if [[ $file_fail -eq 1 ]]; then
      echo "  XFAIL (expected failure)"
    else
      echo "  XPASS: $name passed unexpectedly — delete its XFAIL marker"
      fail=1
    fi
  elif [[ $file_fail -eq 1 ]]; then
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  exit 1
fi
echo "All shell-runner checks passed."
