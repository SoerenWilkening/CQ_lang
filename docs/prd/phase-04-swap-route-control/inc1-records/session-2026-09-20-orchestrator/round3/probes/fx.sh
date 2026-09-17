#!/bin/bash
# fx.sh <fixture-basename ...> — 4-way verdict on a shipped ir-pass/test fixture
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad
for f in "$@"; do
  printf '%-58s' "$f"
  for TAG in BASE MAIN TU9QONLY COMPOSED; do
    out=$("$S/bins/cq-opt.$TAG" -load-pass-plugin "$S/bins/libCQPass.$TAG.so" \
          -passes=cq-lowering -S "$W/ir-pass/test/$f" -o /dev/null 2>&1)
    rc=$?
    if [ $rc -eq 0 ]; then m="ACCEPT"; else m=$(echo "$out" | sed -n 's/.*: cq \(.*\)$/\1/p' | head -1 | cut -c1-40); fi
    [ -z "$m" ] && m="EXIT$rc"
    printf ' | %-42s' "$m"
  done
  echo
done
