#!/bin/bash
# run1.sh TAG FILE... : run cq-opt.TAG on each .ll, print rc, first error/warning, 2b summary.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
TAG=$1; shift
if [ "$TAG" = main ]; then BIN=$S/frozen/cq-opt.main_aee8; else BIN=$S/vsfp/bin/cq-opt.$TAG; fi
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
for f in "$@"; do
  out="${f%.ll}.$TAG.out.ll"
  "$BIN" -passes=cq-lowering -S "$f" -o "$out" 2> "$out.err"
  rc=$?
  msg=$(grep -m1 -E "error|warning" "$out.err" | sed 's/.*\(error\|warning\): //')
  twob=""
  if [ "$rc" = 0 ]; then twob=$(python3 "$W/tools/free_pairing_check.py" "$out" 2>&1 | tail -1 | cut -c1-140); fi
  echo "[$TAG] $(basename "$f") rc=$rc | $msg | $twob"
done
