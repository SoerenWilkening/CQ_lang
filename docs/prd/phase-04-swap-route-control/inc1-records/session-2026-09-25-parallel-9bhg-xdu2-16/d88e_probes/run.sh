#!/bin/bash
# run.sh "tags" name... : run each p/<name>.s1.ll through the tagged binaries.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
cd "$S/d88e/p" || exit 1
TAGS="$1"; shift
for m in "$@"; do
  m="${m%.c}"
  f="$m.s1.ll"
  [ -s "$f" ] || { echo "$m MISSING/EMPTY"; continue; }
  for t in $TAGS; do
    case "$t" in
      ora) b="$S/frozen/cq-opt.main_e846" ;;
      new) b="$W/build/ir-pass/cq-opt" ;;
      comp) b="$S/frozen/cq-opt.comp_9bhg_d88e" ;;
      c9) b="$S/frozen/cq-opt.9bhg_only" ;;
      *) echo "unknown tag $t" >&2; exit 2 ;;
    esac
    "$b" -passes=cq-lowering -S "$f" -o "$m.$t.s2.ll" > "$m.$t.err" 2>&1
    rc=$?
    err=$(grep -o 'error: .*' "$m.$t.err" | head -1 | sed 's/^error: [^:]*:[0-9:]* //')
    if [ -z "$err" ]; then err=$(grep -v '^$' "$m.$t.err" | grep -iv warning | head -1 | cut -c1-120); fi
    meas=""
    if [ "$rc" = 0 ]; then meas="measure=$(grep -c 'call .*@cqrt_measure' "$m.$t.s2.ll")"; fi
    printf '%-10s %-4s rc=%-3s %-12s %s\n' "$m" "$t" "$rc" "$meas" "$err"
  done
done
exit 0
