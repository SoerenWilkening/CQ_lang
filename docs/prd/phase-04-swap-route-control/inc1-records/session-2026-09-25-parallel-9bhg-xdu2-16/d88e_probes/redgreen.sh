#!/bin/bash
# redgreen.sh BIN fixture... : emulate each fixture's single RUN line against BIN.
# A fixture whose RUN starts with `not` passes iff BIN exits non-zero AND FileCheck
# passes on its stderr; otherwise iff BIN exits 0 AND FileCheck passes on stdout.
FC=/usr/local/opt/llvm@19/bin/FileCheck
BIN="$1"; shift
n=0; pass=0
for f in "$@"; do
  n=$((n+1))
  out=$(mktemp); "$BIN" -passes=cq-lowering -S "$f" > "$out.o" 2> "$out.e"; rc=$?
  if grep -q '^; RUN: not ' "$f"; then
    if [ "$rc" != 0 ] && "$FC" "$f" < "$out.e" > /dev/null 2>&1; then v=PASS; else v=FAIL; fi
  else
    if [ "$rc" = 0 ] && "$FC" "$f" < "$out.o" > /dev/null 2>&1; then v=PASS; else v=FAIL; fi
  fi
  [ "$v" = PASS ] && pass=$((pass+1))
  printf '%-4s rc=%-3s %s\n' "$v" "$rc" "$(basename "$f")"
  rm -f "$out" "$out.o" "$out.e"
done
echo "denominator: $n fixtures, $pass pass"
