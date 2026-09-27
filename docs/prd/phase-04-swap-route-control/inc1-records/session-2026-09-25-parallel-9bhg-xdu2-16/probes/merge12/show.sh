#!/bin/bash
# show.sh FIXTURE: diff the pre-merge subject bfb441d3 on the PRE-re-spell fixture
# (HEAD) against the merged binary on the re-spelled fixture (functions only).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
f=$1
"$W/build/ir-pass/cq-opt" -passes=cq-lowering -S "$W/ir-pass/test/$f.ll" -o "$S/merge12/$f.new.ll" 2>/dev/null
"$S/frozen/cq-opt.final" -passes=cq-lowering -S "$S/merge12/old/ir-pass/test/$f.ll" -o "$S/merge12/$f.old.ll" 2>/dev/null
strip() { grep -v '^attributes\|^!\|^;\|^$\|^source\|^target\|^declare' "$1"; }
diff <(strip "$S/merge12/$f.old.ll") <(strip "$S/merge12/$f.new.ll")
