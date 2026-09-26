#!/bin/bash
# twincmp.sh TAG base... : for each base with p/<base>C.s1.ll and p/<base>T.s1.ll,
# run binary TAG on both and compare against the hand-inlined twin:
#   both decline  -> stderr byte-identical?          (DECL-SAME / DECL-DIFF)
#   both accept   -> link, run with args 5 7 and 2 9, trace byte-identical?
#                    (ACC-SAME / ACC-DIFF)
#   otherwise     -> VERDICT-DIFF
# Prints the denominator at the end.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
cd "$S/d88e/p" || exit 1
TAG="$1"; shift
case "$TAG" in
  ora) B="$S/frozen/cq-opt.main_e846" ;;
  new) B="$W/build/ir-pass/cq-opt" ;;
  comp) B="$S/frozen/cq-opt.comp_9bhg_d88e" ;;
  *) echo "bad tag" >&2; exit 2 ;;
esac
n=0; same=0
for b in "$@"; do
  c="${b}C"; t="${b}T"
  [ -s "$c.s1.ll" ] && [ -s "$t.s1.ll" ] || { echo "$b MISSING"; continue; }
  n=$((n+1))
  "$B" -passes=cq-lowering -S "$c.s1.ll" -o "$c.tw.$TAG.ll" 2> "$c.tw.$TAG.err"; rc1=$?
  "$B" -passes=cq-lowering -S "$t.s1.ll" -o "$t.tw.$TAG.ll" 2> "$t.tw.$TAG.err"; rc2=$?
  if [ "$rc1" != 0 ] && [ "$rc2" != 0 ]; then
    if cmp -s "$c.tw.$TAG.err" "$t.tw.$TAG.err"; then v=DECL-SAME; same=$((same+1)); else v=DECL-DIFF; fi
  elif [ "$rc1" = 0 ] && [ "$rc2" = 0 ]; then
    "$L/clang" "$c.tw.$TAG.ll" "$TPL" "$RT" -o "$c.tw.$TAG.exe" 2>/dev/null
    "$L/clang" "$t.tw.$TAG.ll" "$TPL" "$RT" -o "$t.tw.$TAG.exe" 2>/dev/null
    v=ACC-SAME
    for args in "5 7" "2 9"; do
      # shellcheck disable=SC2086
      "./$c.tw.$TAG.exe" $args > "$c.tw.$TAG.trace" 2>&1; e1=$?
      # shellcheck disable=SC2086
      "./$t.tw.$TAG.exe" $args > "$t.tw.$TAG.trace" 2>&1; e2=$?
      if ! cmp -s "$c.tw.$TAG.trace" "$t.tw.$TAG.trace" || [ "$e1" != "$e2" ]; then v=ACC-DIFF; fi
    done
    [ "$v" = ACC-SAME ] && same=$((same+1))
  else
    v="VERDICT-DIFF(C rc=$rc1, T rc=$rc2)"
  fi
  printf '%-6s %-4s %s\n' "$b" "$TAG" "$v"
done
echo "denominator: $n pairs, $same twin-identical"
