#!/bin/bash
# comp.sh member... : ROUND 3 composition check. Regenerate sources, build the named members, then
# twincmp on the frozen MAIN ba4fdad4 (rhk5 + z0re, no cepm) and on the frozen MERGED binary
# (cepm + rhk5 + z0re). For every member that is ACC-DIFF on the merged binary, also run
# tools/trace_twin_equiv.py on its two traces (argv 5 7 and 2 9).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
D="$(cd "$(dirname "$0")" && pwd)"
cd "$D" || exit 1
python3 "$D/mkprobes.py" > /dev/null
args=()
for b in "$@"; do args+=("${b}C" "${b}T"); done
bash "$D/gen.sh" "${args[@]}"
bash "$D/twincmp.sh" "$S/frozen/cq-opt.main_ba4fdad4" "$@" 2>&1 | cut -c1-230
bash "$D/twincmp.sh" "$S/cepm/cq-opt.merged" "$@" 2>&1 | cut -c1-230
cd "$S/cepm/p" || exit 1
for b in "$@"; do
  for a in "5 7" "2 9"; do
    c="${b}C.tw.cq-opt.merged.exe"; t="${b}T.tw.cq-opt.merged.exe"
    [ -x "$c" ] && [ -x "$t" ] || continue
    "./$c" $a > "$b.eq.C" 2>&1; "./$t" $a > "$b.eq.T" 2>&1
    printf "%s argv[%s] " "$b" "$a"
    python3 "$W/tools/trace_twin_equiv.py" --quiet-controls "$b.eq.C" "$b.eq.T" | tail -1
  done
done
