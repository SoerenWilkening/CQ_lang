#!/bin/bash
# Corpus A/B of the merged binary vs 9bhg-alone (30529716) and vs main (ba80bda1),
# over every ir-pass/test/*.ll, with the fixed --null (both binaries run twice).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
ls /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/ir-pass/test/*.ll > "$S/merge9/corpus_merged.lst"
echo "### merged vs sub (30529716, cq-opt 8b837d1f)"
python3 "$S/p9/ab_sweep.py" "$S/frozen/cq-opt.new3" "$S/frozen/cq-opt.merged" "$S/merge9/corpus_merged.lst" --null
echo "### merged vs main (ba80bda1, cq-opt e587c191)"
python3 "$S/p9/ab_sweep.py" "$S/frozen/cq-opt.main_ba80" "$S/frozen/cq-opt.merged" "$S/merge9/corpus_merged.lst" --null
