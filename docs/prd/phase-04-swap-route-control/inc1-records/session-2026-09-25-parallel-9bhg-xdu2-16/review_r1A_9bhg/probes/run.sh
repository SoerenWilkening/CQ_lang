#!/bin/bash
# run.sh "tags" name... : run each <name>.s1.ll (or .ll given) through binaries
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd "$S/rev9A/p"
TAGS=$1; shift
for m in "$@"; do
  m=${m%.c}
  f=$m.s1.ll; [ -f "$f" ] || f=$m.ll
  [ -s "$f" ] || { echo "$m MISSING/EMPTY"; continue; }
  for t in $TAGS; do
    case $t in
      pre) b=$S/frozen/cq-opt.preE ;;
      ora) b=$S/frozen/cq-opt.main983 ;;
      new) b=$W/build/ir-pass/cq-opt ;;
      mut) b=$S/rev9A_wt/build/ir-pass/cq-opt ;;
      *) echo "unknown tag $t" >&2; exit 2 ;;
    esac
    "$b" -passes=cq-lowering -S "$f" -o "$m.$t.s2.ll" > "$m.$t.err" 2>&1
    rc=$?
    err=$(grep -o 'error: .*' "$m.$t.err" | head -1 | sed 's/^error: [^:]*:[0-9:]* //')
    [ -z "$err" ] && err=$(grep -v '^$' "$m.$t.err" | grep -iv warning | head -1 | cut -c1-120)
    printf '%-14s %-4s rc=%-3s %s\n' "$m" "$t" "$rc" "$err"
  done
done
