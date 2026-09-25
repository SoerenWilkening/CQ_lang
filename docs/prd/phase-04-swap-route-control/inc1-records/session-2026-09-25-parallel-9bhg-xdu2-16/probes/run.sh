#!/bin/bash
# Run each named probe module (<name>.s1.ll) through the binaries named by tag
# (pre = aad63450 preE, ora = main 983f9361 frozen, new = worktree build) and
# print exit code + first diagnostic. Lowered IR goes to <name>.<tag>.s2.ll.
# Usage: bash run.sh "pre ora new" rt1 rt2 ...
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd "$S/p9"
TAGS=$1; shift
for m in "$@"; do
  for t in $TAGS; do
    case $t in
      pre) b=$S/frozen/cq-opt.preE ;;
      ora) b=$S/frozen/cq-opt.main983 ;;
      new) b=$W/build/ir-pass/cq-opt ;;
      new1) b=$S/frozen/cq-opt.new1 ;;
      new2) b=$S/frozen/cq-opt.new2 ;;
      new3) b=$S/frozen/cq-opt.new3 ;;
      *) echo "unknown tag $t" >&2; exit 2 ;;
    esac
    out=$("$b" -passes=cq-lowering -S "$m.s1.ll" -o "$m.$t.s2.ll" 2>&1)
    rc=$?
    err=$(printf '%s\n' "$out" | grep -o 'error: .*' | head -1 | sed 's/^error: [^:]*:[0-9:]* //')
    printf '%-12s %-4s rc=%-3s %s\n' "$m" "$t" "$rc" "$err"
  done
done
