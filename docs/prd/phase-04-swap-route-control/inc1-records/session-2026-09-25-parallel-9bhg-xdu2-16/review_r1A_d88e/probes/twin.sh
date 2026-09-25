#!/bin/bash
# twin.sh TAG base... : compare <base>C vs <base>T on bin/TAG. Both decline -> stderr cmp;
# both accept -> link + run with "5 7" and "2 9" and diff traces + exit codes.
A="$(cd "$(dirname "$0")" && pwd)"; L=/usr/local/opt/llvm@19/bin
TAG="$1"; shift; B="$A/bin/$TAG"; n=0; same=0
for b in "$@"; do
  c="$A/p/${b}C"; t="$A/p/${b}T"
  [ -s "$c.s1.ll" ] && [ -s "$t.s1.ll" ] || { echo "$b MISSING"; continue; }
  n=$((n+1))
  "$B" -passes=cq-lowering -S "$c.s1.ll" -o "$c.tw.$TAG.ll" 2> "$c.tw.$TAG.err"; rc1=$?
  "$B" -passes=cq-lowering -S "$t.s1.ll" -o "$t.tw.$TAG.ll" 2> "$t.tw.$TAG.err"; rc2=$?
  if [ "$rc1" != 0 ] && [ "$rc2" != 0 ]; then
    if cmp -s "$c.tw.$TAG.err" "$t.tw.$TAG.err"; then v=DECL-SAME; same=$((same+1)); else v=DECL-DIFF; fi
  elif [ "$rc1" = 0 ] && [ "$rc2" = 0 ]; then
    "$L/clang" "$c.tw.$TAG.ll" "$A/bin/libcq_templates.a" "$A/bin/libcq_runtime.a" -o "$c.tw.$TAG.exe" 2>/dev/null
    "$L/clang" "$t.tw.$TAG.ll" "$A/bin/libcq_templates.a" "$A/bin/libcq_runtime.a" -o "$t.tw.$TAG.exe" 2>/dev/null
    v=ACC-SAME
    for args in "5 7" "2 9"; do
      "$c.tw.$TAG.exe" $args > "$c.tw.$TAG.trace" 2>&1; e1=$?
      "$t.tw.$TAG.exe" $args > "$t.tw.$TAG.trace" 2>&1; e2=$?
      if ! cmp -s "$c.tw.$TAG.trace" "$t.tw.$TAG.trace" || [ "$e1" != "$e2" ]; then v=ACC-DIFF; fi
    done
    [ "$v" = ACC-SAME ] && same=$((same+1))
  else
    v="VERDICT-DIFF(C rc=$rc1, T rc=$rc2)"
  fi
  printf '%-6s %-5s %s\n' "$b" "$TAG" "$v"
done
echo "denominator: $n pairs, $same twin-identical"
