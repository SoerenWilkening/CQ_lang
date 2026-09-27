#!/bin/bash
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
for f in "$@"; do
  echo "######## $f"
  bash "$S/merge12/show.sh" "$f"
  echo "---- CHECK lines"
  grep -n "CHECK" "$W/ir-pass/test/$f.ll"
  echo "---- new output"
  grep -v '^attributes\|^!\|^;\|^$\|^source\|^target\|^declare' "$S/merge12/$f.new.ll" | awk '/^define (i32 @(f|main)|internal)/,/^}/'
done
