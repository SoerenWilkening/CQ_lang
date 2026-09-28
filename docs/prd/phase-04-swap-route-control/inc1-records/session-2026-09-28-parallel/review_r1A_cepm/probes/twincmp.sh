#!/bin/bash
# twincmp.sh TAG base... : for each base with <base>C.s1.ll and <base>T.s1.ll (gen.sh),
# run binary TAG on both and compare with the hand-inlined twin T:
#   both decline  -> first `error:` line identical?    (DECL-SAME / DECL-DIFF)
#   both accept   -> stage 2b STRICT on both, link, run with args "5 7" and "2 9",
#                    traces byte-identical?              (ACC-SAME / ACC-DIFF)
#   otherwise     -> VERDICT-DIFF
# The C-side first error line is printed so a decline's OWNER is visible.
# Prints the denominator at the end.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
cd "$S/r1A_cepm/p" || exit 1
TAG="$1"; shift
case "$TAG" in
  ora) B="$S/frozen/cq-opt.main_9a230646" ;;
  new) B="$W/build/ir-pass/cq-opt" ;;
  *) B="$TAG"; TAG=$(basename "$B") ;;
esac
n=0; same=0
for b in "$@"; do
  c="${b}C"; t="${b}T"
  [ -s "$c.s1.ll" ] && [ -s "$t.s1.ll" ] || { echo "$b MISSING"; continue; }
  n=$((n+1))
  "$B" -passes=cq-lowering -S "$c.s1.ll" -o "$c.tw.$TAG.ll" 2> "$c.tw.$TAG.err"; rc1=$?
  "$B" -passes=cq-lowering -S "$t.s1.ll" -o "$t.tw.$TAG.ll" 2> "$t.tw.$TAG.err"; rc2=$?
  e1=$(grep -m1 'error:' "$c.tw.$TAG.err" | sed 's/^[^ ]*error: //')
  e2=$(grep -m1 'error:' "$t.tw.$TAG.err" | sed 's/^[^ ]*error: //')
  extra=""
  if [ "$rc1" != 0 ] && [ "$rc2" != 0 ]; then
    if [ "$e1" = "$e2" ]; then v=DECL-SAME; same=$((same+1)); else v=DECL-DIFF; extra="T: $e2"; fi
  elif [ "$rc1" = 0 ] && [ "$rc2" = 0 ]; then
    v=ACC-SAME
    python3 "$W/tools/free_pairing_check.py" "$c.tw.$TAG.ll" > "$c.tw.$TAG.2b" 2>&1 || v="ACC-2B-FAIL(C)"
    python3 "$W/tools/free_pairing_check.py" "$t.tw.$TAG.ll" > "$t.tw.$TAG.2b" 2>&1 || v="ACC-2B-FAIL(T)"
    "$L/clang" "$c.tw.$TAG.ll" "$TPL" "$RT" -o "$c.tw.$TAG.exe" 2>/dev/null || v="LINKFAIL(C)"
    "$L/clang" "$t.tw.$TAG.ll" "$TPL" "$RT" -o "$t.tw.$TAG.exe" 2>/dev/null || v="LINKFAIL(T)"
    if [ "$v" = ACC-SAME ]; then
      for args in "5 7" "2 9"; do
        # shellcheck disable=SC2086
        "./$c.tw.$TAG.exe" $args > "$c.tw.$TAG.trace" 2>&1; x1=$?
        # shellcheck disable=SC2086
        "./$t.tw.$TAG.exe" $args > "$t.tw.$TAG.trace" 2>&1; x2=$?
        if ! cmp -s "$c.tw.$TAG.trace" "$t.tw.$TAG.trace" || [ "$x1" != "$x2" ]; then v=ACC-DIFF; fi
      done
      [ "$v" = ACC-SAME ] && same=$((same+1))
      extra="lines=$(wc -l < "$c.tw.$TAG.trace" | tr -d ' ') 2b: $(tail -1 "$c.tw.$TAG.2b")"
    fi
  else
    v="VERDICT-DIFF(C rc=$rc1, T rc=$rc2)"; extra="T: ${e2:-accept}"
  fi
  printf '%-8s %-5s %-28s C: %s | %s\n' "$b" "$TAG" "$v" "${e1:-accept}" "$extra"
done
echo "denominator: $n pairs, $same twin-identical"
