#!/bin/bash
# Corpus A/B of the FINAL subject (cq-opt.final, bfb441d3) vs main aee8f4f8
# (cq-opt.main_aee8, 69250fea) over every ir-pass/test/*.ll, the run_slice_multi.sh
# modules and the standalone tests/e2e/*.c modules. ab_sweep.py --null runs BOTH
# binaries twice over each full list first and refuses to report if either differs.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
ls /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/ir-pass/test/*.ll > "$S/merge9/corpus_final.lst"
for L in corpus_final.lst; do
  echo "### lit corpus"
  python3 "$S/p9/ab_sweep.py" "$S/frozen/cq-opt.main_aee8" "$S/frozen/cq-opt.final" "$S/merge9/$L" --null
done
echo "### run_slice_multi.sh modules"
python3 "$S/p9/ab_sweep.py" "$S/frozen/cq-opt.main_aee8" "$S/frozen/cq-opt.final" "$S/p9/multi.lst" --null
echo "### standalone tests/e2e/*.c modules"
python3 "$S/p9/ab_sweep.py" "$S/frozen/cq-opt.main_aee8" "$S/frozen/cq-opt.final" "$S/p9/single.lst" --null
